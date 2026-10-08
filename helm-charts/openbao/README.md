# OpenBao Guide

This repository contains the configuration and operational procedures for Openbao, an open-source credentials manager forked from Hashicorp Vault.

In our infrastructure, Openbao serves credentials used by Jenkins.

* **Access URL:** [https://ci-vault.lsst.cloud](https://ci-vault.lsst.cloud)

---

## Login

Administrative credentials and recovery keys are stored securely in the prompt-proto project in Google Secrets Manager.

* **Secret Name:** `vault-creds`
* **Contents:**
    * **Token:** Current login token for administrative access.
    * **Unseal Keys:** Required to unseal the vault - the vault will become sealed after every google cloud node upgrade.

---
## Upgrade Helm Procedure

We use the official Openbao Helm chart for deployments.

Chart Source: [Openbao](https://artifacthub.io/packages/helm/openbao/openbao)

Namespace: `vault-openbao`

### Add the official repository
```bash
helm repo add openbao https://openbao.github.io/openbao-helm
helm repo update
```

### Upgrade the release
Use the values file listed in this repo.
```bash
helm upgrade openbao openbao/openbao -n vault-openbao -f values-openbao.yaml --force-conflicts
```

---

## Auto-Unsealing the Vault
Google KMS has been configured to auto-unseal the vault in the event of a restart of the pod. Since enabled, manual unsealing should not be required. The auto-unseal is configured in the openbao helm chart, and on google cloud a keyring and crypto key have been set up. 

## Manuall Unsealing the Vault

If the Openbao pod is in a `Running` state but shows `0/1` ready, it is likely sealed. While sealed, the vault is encrypted and cannot serve requests to Jenkins, breaking Jenkins runs. The macs will also be unable to connect to Jenkins.

### 1. Check Sealed Status
Exec into the pod to verify the current status:
```bash
kubectl exec -it <openbao-pod-name> -n vault-openbao -- sh
bao status
``` 
This will show if the pod is initialized but sealed.
### 2. Unseal the Vault
Unseal the vault:
```bash
bao operator unseal
```
Use the unseal keys listed in `vault-creds` in GSM when prompted, you will have to do the command three times for the three keys. Do `bao status` at the end to check if vault is now unsealed. The pod should now be in a `Running` `1/1` state.



