# ComputeClasses Guide

These two [custom ComputeClasses](https://cloud.google.com/kubernetes-engine/docs/concepts/about-custom-compute-classes)
are what give worker pods a fallback machine family when the primary one is out of
capacity.

| ComputeClass | Priority 1 | Priority 2 |
|---|---|---|
| `jenkins-workers-x86` | `jenkins-workers-c4d` | `jenkins-workers-c4-fallback` |
| `jenkins-workers-arm` | `jenkins-workers-multiarch-c4a` | `jenkins-workers-n4a-fallback` |

ComputeClasses are cluster-scoped, so one copy serves both the `jenkins-prod` and
`jenkins-dev` namespaces. Requires GKE 1.30.3-gke.1451000 or later.

```bash
kubectl apply -f jenkins-workers-x86.yaml -f jenkins-workers-arm.yaml
kubectl get computeclass
```

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
