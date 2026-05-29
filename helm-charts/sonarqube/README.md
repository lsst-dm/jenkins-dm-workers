# SonarQube

Deploys SonarQube Community Edition to the `sonarqube` namespace on the `prompt-proto` GKE cluster,
accessible at `https://ci-sonarqube.lsst.cloud`. Uses two Helm charts:

- [`sonarqube/sonarqube`](https://github.com/SonarSource/helm-chart-sonarqube) 2026.x community chart
- [`bitnami/postgresql`](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) — in-cluster database (the 2026.x sonarqube chart no longer bundles a PostgreSQL subchart)

Secrets are sourced from OpenBao (`ci-vault.lsst.cloud`) via the External Secrets Operator.

---

## Prerequisites

1. **GCP static IP** — reserve a global static IP named `sonarqube` in `terraform/prod/` before
   deploying (mirrors the `atlantis` IP resource already there). Without this the GCE ingress will
   not obtain a stable external IP.

2. **OpenBao paths populated** — the admin password, DB password, and monitoring passcode must
   exist in OpenBao before the charts are installed (see "Provision secrets" below). The Jenkins
   token path is populated post-deploy.

3. **ESO ClusterSecretStore** — confirm a `ClusterSecretStore` named `openbao` exists in the
   cluster and can reach `ci-vault.lsst.cloud`. If the store uses a different name, update the
   `secretStoreRef.name` field in `externalsecret-sonarqube.yaml`. If secrets fail to sync, check
   whether ESO inserts `/data/` automatically for KV v2 — if so, adjust `remoteRef.key` from
   `secret/data/sonarqube/<name>` to `sonarqube/<name>`.

4. **Jenkins SonarQube plugin** — install the Jenkins SonarQube plugin on the Jenkins controller
   before attempting to use `withSonarQubeEnv` in pipelines.

---

## Provision secrets in OpenBao

Run these commands **before** deploying. Replace `<...>` with strong random values.

    bao kv put secret/sonarqube/admin-password    value=<strong-admin-password>
    bao kv put secret/sonarqube/db-password       value=<strong-db-password>
    bao kv put secret/sonarqube/monitoring-passcode value=<random-string>

The Jenkins token (`secret/sonarqube/jenkins-token`) is populated after SonarQube is running —
see "Post-deploy Jenkins wiring" below.

---

## Deploy

    # 0. Create the namespace first
    kubectl create namespace sonarqube --dry-run=client -o yaml | kubectl apply -f -

    # 1. Apply ExternalSecrets first — K8s Secrets must exist before the chart starts
    kubectl apply -f helm-charts/sonarqube/externalsecret-sonarqube.yaml \
      --namespace sonarqube

    # Confirm admin-password, db-password, and monitoring-passcode synced (token will be NotReady)
    kubectl get externalsecret -n sonarqube

    # 2. Add Helm repos
    helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
    helm repo add bitnami   https://charts.bitnami.com/bitnami
    helm repo update

    # 3. Deploy PostgreSQL first — SonarQube needs the DB to be ready on startup
    helm upgrade --install postgresql bitnami/postgresql \
      --namespace sonarqube --create-namespace \
      -f helm-charts/sonarqube/values-postgresql.yaml

    # 4. Deploy SonarQube
    helm upgrade --install sonarqube sonarqube/sonarqube \
      --namespace sonarqube \
      -f helm-charts/sonarqube/values-sonarqube.yaml

Verify the pods come up:

    kubectl rollout status statefulset/postgresql-primary -n sonarqube
    kubectl rollout status deployment/sonarqube -n sonarqube

---

## Post-deploy Jenkins wiring

Once SonarQube is running at `https://ci-sonarqube.lsst.cloud`:

1. Log in with the admin password you set in OpenBao.
2. Go to **My Account → Security → Generate Token** — create a token of type "User Token".
3. Store the token in OpenBao:

       bao kv put secret/sonarqube/jenkins-token value=<token-from-step-2>

4. Force the ExternalSecret to sync immediately (otherwise it syncs within 1 hour):

       kubectl annotate externalsecret sonarqube-token \
         force-sync=$(date +%s) --overwrite -n sonarqube

5. Confirm the K8s Secret exists:

       kubectl get secret sonarqube-token -n sonarqube

6. In Jenkins, add a credential:
   - Kind: **Secret text**
   - ID: `sonarqube-token`
   - Secret: paste the token value (or configure Jenkins to read from the K8s Secret directly
     if the Kubernetes Credentials Plugin is installed)

7. In Jenkins → **Manage Jenkins → Configure System → SonarQube servers**:
   - Click **Add SonarQube**
   - Name: **`sonarqube`** ← this exact string must match `withSonarQubeEnv('sonarqube')` in pipelines
   - Server URL: `https://ci-sonarqube.lsst.cloud`
   - Server authentication token: select the `sonarqube-token` credential added in step 6
