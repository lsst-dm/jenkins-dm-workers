# SonarQube

Deploys SonarQube Community Edition to the `sonarqube` namespace on the `prompt-proto` GKE cluster,
accessible at `https://ci-sonarqube.lsst.cloud`. Uses two Helm charts:

- [`sonarqube/sonarqube`](https://github.com/SonarSource/helm-chart-sonarqube) 2026.x community chart
- [`bitnami/postgresql`](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) — in-cluster database (the 2026.x sonarqube chart no longer bundles a PostgreSQL subchart)

Secrets are stored in OpenBao (`ci-vault.lsst.cloud`) and copied into Kubernetes Secrets manually
with `bao` + `kubectl` (see "Create Kubernetes Secrets from OpenBao" below). The
`externalsecret-sonarqube.yaml` manifest is kept in-tree for a future migration to the External
Secrets Operator but is **not** applied today — the cluster currently has no ESO CRDs installed.

---

## Prerequisites

1. **GCP static IP** — reserve a global static IP named `sonarqube` in `terraform/prod/` before
   deploying (mirrors the `atlantis` IP resource already there). Without this the GCE ingress will
   not obtain a stable external IP.

2. **OpenBao paths populated** — the admin password, DB password, and monitoring passcode must
   exist in OpenBao before the charts are installed (see "Provision secrets" below). The Jenkins
   token path is populated post-deploy.

3. **`bao` CLI authenticated** — you must be logged in to OpenBao (`bao login ...` against
   `ci-vault.lsst.cloud`) with read access to `secret/sonarqube/*` so the `kubectl create secret`
   commands below can resolve the values.

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

## Create Kubernetes Secrets from OpenBao

The chart expects three Kubernetes Secrets to already exist in the `sonarqube` namespace before
it starts (the fourth, `sonarqube-token`, is created post-deploy). Pull each value from OpenBao
and pipe it into `kubectl create secret`:

    # Create the namespace first (idempotent)
    kubectl create namespace sonarqube --dry-run=client -o yaml | kubectl apply -f -

    # Admin password
    kubectl create secret generic sonarqube-admin-password -n sonarqube \
      --from-literal=password="$(bao kv get -field=value secret/sonarqube/admin-password)"

    # DB password
    kubectl create secret generic sonarqube-db-password -n sonarqube \
      --from-literal=password="$(bao kv get -field=value secret/sonarqube/db-password)"

    # Monitoring passcode
    kubectl create secret generic sonarqube-monitoring-passcode -n sonarqube \
      --from-literal=passcode="$(bao kv get -field=value secret/sonarqube/monitoring-passcode)"

Confirm:

    kubectl get secret -n sonarqube

To rotate a value, update it in OpenBao (`bao kv put ...`) and re-run the matching command above
with `kubectl create secret ... --dry-run=client -o yaml | kubectl apply -f -` so the existing
Secret is overwritten in place.

---

## Deploy

    # 1. Add Helm repos
    helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
    helm repo add bitnami   https://charts.bitnami.com/bitnami
    helm repo update

    # 2. Deploy PostgreSQL first — SonarQube needs the DB to be ready on startup
    helm upgrade --install postgresql bitnami/postgresql \
      --namespace sonarqube --create-namespace \
      -f helm-charts/sonarqube/values-postgresql.yaml

    # 3. Deploy SonarQube
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

4. Create the matching Kubernetes Secret:

       kubectl create secret generic sonarqube-token -n sonarqube \
         --from-literal=token="$(bao kv get -field=value secret/sonarqube/jenkins-token)"

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
