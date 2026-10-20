# ComputeClasses Guide

These [custom ComputeClasses](https://cloud.google.com/kubernetes-engine/docs/concepts/about-custom-compute-classes)
are what give worker pods a fallback machine family when the primary one is out of
capacity.

| ComputeClass | Priority 1 | Priority 2 | Priority 3 | Priority 4 |
|---|---|---|---|---|
| `jenkins-workers-x86` | `jenkins-workers-c4d` | `jenkins-workers-c4-fallback` | `jenkins-workers-n4-fallback` | |
| `jenkins-workers-arm` | `jenkins-workers-multiarch-c4a` | `jenkins-workers-n4a-fallback` | `jenkins-workers-n4a64-fallback` | |
| `jenkins-workers-arm-reserved` | `jenkins-workers-c4a-reserved` | `jenkins-workers-multiarch-c4a` | `jenkins-workers-n4a-fallback` | `jenkins-workers-n4a64-fallback` |

ComputeClasses are cluster-scoped, so one copy serves both the `jenkins-prod` and
`jenkins-dev` namespaces. Requires GKE 1.30.3-gke.1451000 or later.

```bash
kubectl apply -f jenkins-workers-x86.yaml -f jenkins-workers-arm.yaml \
  -f jenkins-workers-arm-reserved.yaml
kubectl get computeclass
```

## Reserved arm capacity

`jenkins-workers-arm-reserved` exists so the nightly's aarch64 stages can reach the
C4A capacity floor (`google_compute_reservation.jenkins_c4a`) while PR CI cannot.

The separation is enforced by GCP, not by this file: the reservation is
`specific_reservation_required = true`, so it is consumable *only* by
`jenkins-workers-c4a-reserved`, the one pool declaring `SPECIFIC_RESERVATION`
affinity for it. `jenkins-workers-multiarch-c4a` defaults to `ANY_RESERVATION` and
therefore cannot touch it, which is what keeps `stack-os-matrix` PR builds off the
floor.

Jobs opt in per invocation via the `ARM_COMPUTE_CLASS` parameter in
`jenkins-dm-jobs`; empty means `jenkins-workers-arm`. `stack-os-matrix` needs this
per-invocation rather than per-job because the nightly uses that same job to build
its lsstsw cache.

The nightly's `build stack image` stage is **not** opted in and still uses
unreserved capacity. It allocates via `util.nodeWrap(label)`, which resolves to the
static `idf-agent-ldfc-arch` pod template in `seeds/gcp-values/values.yaml`, whose
nodeSelector is fixed at `jenkins-workers-arm`. There is no runtime override point;
changing it needs a second pod template (and a `helm upgrade`) or a rewrite onto
`insideK8sContainer`.

Note `reservations:` cannot be expressed in a priority rule here: the CRD states
`nodepools` "is incompatible with all other fields in `priorities`", so reservation
affinity has to live on the node pool in `terraform/prod/nodepool.tf`.

## activeMigration is deliberately unset everywhere

`optimizeRulePriority` would drain pods off a fallback pool once primary capacity
returned, which in this cluster means killing multi-hour stack builds mid-flight.
Leave it unset in all three classes.

## Why this rather than a second Jenkins pod template

The Jenkins Kubernetes plugin cannot fall back on its own. `KubernetesCloud.provision()`
walks the templates matching a label in declaration order and returns on the first one
that plans a node, so a second template with the same label is never reached. And
`KubernetesLauncher` only waits out `slaveConnectTimeout` before throwing — it never
inspects pod conditions, so a stockout is indistinguishable from a slow boot and the
pipeline gets no signal it could act on. GKE is the only layer that knows a pool is
out of capacity, so the decision has to live there.

## Pods must select the class, not the pool

Worker pods carry `nodeSelector: cloud.google.com/compute-class: <class name>` instead
of `cloud.google.com/gke-nodepool: <pool>`. Pinning a pool defeats the fallback.

The four worker pools are also **tainted** `cloud.google.com/compute-class=<class>:NoSchedule`,
which is what keeps unrelated pods off them now that no pod pins a pool. GKE
auto-injects the matching toleration into any pod that selects the class, so pods
normally need only the nodeSelector — the agent templates spell the toleration out
anyway so the spec stands alone.

**A pod that is still pinned to a worker pool by name needs the toleration added by
hand,** because the auto-injection only fires for pods that select the class. This is
why `snowflake` carries an explicit `jenkins-workers-arm` toleration: it stays pinned
to C4A on purpose (it is a long-lived stateful agent, not something we want migrating
between machine families) and would otherwise go unschedulable the moment the pool was
tainted.

Both the label and the taint have to be set on the pools explicitly, in
`terraform/prod/nodepool.tf` — GKE only applies them automatically to pools it
creates itself, not to manually created ones.

## Changing the fallback family

This is entirely a change in this repo: edit the pool in `nodepool.tf` and the
`priorities` list here. Nothing in `jenkins-dm-jobs` refers to a pool name, only to
the class name, so no Jenkins-side change or `helm upgrade` is needed.
