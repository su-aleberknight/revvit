# Rancher Manager Installation

This document describes the playbooks required to install Rancher Manager on an
existing RKE2 cluster and the sequence they must be run in.

**Prerequisite:** Run `rke2-ha.yml` or `run-rke2-singlenode-plays.yml` before running any
Rancher Manager plays.

## Prerequisites

- RKE2 cluster is up and running
- All nodes are reachable via SSH
- Inventory file is populated with node IPs and hostnames
- All vars files are copied and filled in:

```bash
cp rancher-manager-plays/vars/install-cert-manager.yml.example rancher-manager-plays/vars/install-cert-manager.yml
cp rancher-manager-plays/vars/install-rancher.yml.example rancher-manager-plays/vars/install-rancher.yml
cp rancher-manager-plays/vars/install-rancher-secrets.yml.example rancher-manager-plays/vars/install-rancher-secrets.yml
```

## Running the Full Installation

Use the shell script — it validates all vars files exist before running and prints
the play order:

```bash
./preflight-check.sh [-i inventory]
```

The script reads the bootstrap node IP from the `[rke2_bootstrap]` inventory group,
validates all required vars files are present, then runs:

```bash
ansible-playbook run-rancher-manager-plays.yml -i inventory
```

Or invoke the playbook directly:

```bash
ansible-playbook -i inventory run-rancher-manager-plays.yml
```

---

## Play Sequence

### 1. `rancher-manager-plays/install-helm.yml`
**Hosts:** all nodes

Refreshes zypper repositories and installs Helm. Required before cert-manager and
Rancher can be deployed via Helm charts.

No vars file required.

```bash
ansible-playbook -i inventory rancher-manager-plays/install-helm.yml
```

---

### 2. `rancher-manager-plays/install-rancher-secrets.yml`
**Hosts:** `rke2_bootstrap`

Registers the SUSE Application Collections and SUSE Registry OCI repositories in
Rancher Manager's Apps & Marketplace (`catalog.cattle.io/ClusterRepo`). Creates
docker-registry credential secrets in the `cattle-system` namespace for each repo.
Play is idempotent — safe to run multiple times.

**Vars file:** `rancher-manager-plays/vars/install-rancher-secrets.yml`

| Variable | Description |
|----------|-------------|
| `rancher_appco_repo.name` | Display name for the AppCo repo in Rancher |
| `rancher_appco_repo.url` | OCI URL for SUSE Application Collections |
| `rancher_appco_repo.username` | SCC account email |
| `rancher_appco_repo.password` | SCC registration code |
| `rancher_appco_repo.secret_name` | Name for the credential secret |
| `rancher_suse_registry_repo.name` | Display name for the SUSE Registry repo |
| `rancher_suse_registry_repo.url` | OCI URL for the SUSE Registry |
| `rancher_suse_registry_repo.username` | SCC account email |
| `rancher_suse_registry_repo.password` | SCC registration code |
| `rancher_suse_registry_repo.secret_name` | Name for the credential secret |

```bash
ansible-playbook -i inventory rancher-manager-plays/install-rancher-secrets.yml
```

---

### 3. `rancher-manager-plays/install-cert-manager.yml`
**Hosts:** `rke2_bootstrap`

Installs cert-manager using Helm from the Jetstack chart repository. Applies the
cert-manager CRDs first, then deploys the Helm release into the `cert-manager`
namespace. Waits for all cert-manager pods to be ready before completing.

cert-manager is required by Rancher Manager for TLS certificate management.

**Vars file:** `rancher-manager-plays/vars/install-cert-manager.yml`

| Variable | Description |
|----------|-------------|
| `cert_manager_version` | cert-manager Helm chart version (e.g. `v1.14.5`) |

```bash
ansible-playbook -i inventory rancher-manager-plays/install-cert-manager.yml
```

---

### 4. `rancher-manager-plays/install-rancher.yml`
**Hosts:** `rke2_bootstrap`

Installs Rancher Manager using Helm from the Rancher stable chart repository into
the `cattle-system` namespace. Waits for all Rancher pods to be ready before
completing and prints the URL and bootstrap password.

Must run after cert-manager is installed and ready.

**Vars file:** `rancher-manager-plays/vars/install-rancher.yml`

| Variable | Description |
|----------|-------------|
| `rancher_version` | Rancher Manager Helm chart version (e.g. `2.13.2`) |
| `rancher_hostname` | Hostname used to access the Rancher UI — must resolve to the bootstrap node IP or VIP |
| `rancher_manager_password` | Initial admin password set on first login |

```bash
ansible-playbook -i inventory rancher-manager-plays/install-rancher.yml
```

---

## Inventory Group Required

Rancher Manager is installed on the bootstrap node:

```ini
[rke2_bootstrap]
node1 ansible_host=192.168.1.201 ansible_user=root
```

## Accessing Rancher After Install

Once the play completes, open a browser to:

```
https://<rancher_hostname>
```

Log in with the `rancher_manager_password` defined in the vars file. You will be
prompted to set a new password on first login.

If `rancher_hostname` is not in DNS, add it to your local `/etc/hosts`:

```
192.168.1.201  rke2.example.local
```
