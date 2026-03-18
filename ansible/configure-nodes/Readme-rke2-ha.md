# RKE2 HA Cluster Installation

This document describes the playbooks required to install a highly available RKE2
cluster and the sequence they must be run in.

## Prerequisites

- All nodes are reachable via SSH
- SSH keys have been distributed to all nodes (see `scripts/distribute-ssh-key.sh`)
- Inventory file is populated with node IPs and hostnames
- All vars files are copied and filled in:

```bash
cp rke2-ha-plays/vars/suseconnect.yml.example rke2-ha-plays/vars/suseconnect.yml
cp rke2-ha-plays/vars/configure-etc-hosts.yml.example rke2-ha-plays/vars/configure-etc-hosts.yml
cp rke2-ha-plays/vars/install-kubevip-static-pod.yml.example rke2-ha-plays/vars/install-kubevip-static-pod.yml
cp rke2-ha-plays/vars/install-rke2-on-leader.yml.example rke2-ha-plays/vars/install-rke2-on-leader.yml
cp rke2-ha-plays/vars/create-control-plane.yml.example rke2-ha-plays/vars/create-control-plane.yml
cp rke2-ha-plays/vars/install-rke2-on-worker-nodes.yml.example rke2-ha-plays/vars/install-rke2-on-worker-nodes.yml
```

## Running the Full Installation

Runs all six plays in the correct order:

```bash
ansible-playbook -i inventory rke2-ha.yml
```

Or run each play individually in the order below.

---

## Play Sequence

### 1. `rke2-ha-plays/suseconnect.yml`
**Hosts:** all nodes

Registers each SLES node with SUSE Customer Center and activates required modules.
Must run first on every node before any SUSE packages can be installed.

**Vars file:** `rke2-ha-plays/vars/suseconnect.yml`

| Variable | Description |
|----------|-------------|
| `suse_email` | SUSE account email address |
| `suse_subscription_number` | SCC registration code |

```bash
ansible-playbook -i inventory rke2-ha-plays/suseconnect.yml
```

---

### 2. `rke2-ha-plays/configure-etc-hosts.yml`
**Hosts:** all nodes

Writes all node IPs and hostnames into `/etc/hosts` on every node using a managed
block. Node entries are derived directly from the inventory — no duplication needed
in vars. Only the VIP IP and hostname need to be defined.

Skip this step if DNS is already resolving all node hostnames.

**Vars file:** `rke2-ha-plays/vars/configure-etc-hosts.yml`

| Variable | Description |
|----------|-------------|
| `rke2_vip_ip` | Virtual IP address claimed by kube-vip |
| `rke2_vip_hostname` | Hostname for the VIP |

```bash
ansible-playbook -i inventory rke2-ha-plays/configure-etc-hosts.yml
```

---

### 3. `rke2-ha-plays/install-kubevip-static-pod.yml`
**Hosts:** `rke2_bootstrap` + `rke2-control-nodes`

Deploys the kube-vip static pod manifest to all server nodes **before** RKE2 starts.
kube-vip provides the virtual IP (VIP) that acts as the HA load balancer for the
Kubernetes API server. The network interface for the VIP is auto-detected per node.

Must run before RKE2 is started on any node.

**Vars file:** `rke2-ha-plays/vars/install-kubevip-static-pod.yml`

| Variable | Description |
|----------|-------------|
| `kube_vip_version` | kube-vip container image version (e.g. `v0.8.9`) |
| `rke2_vip_ip` | Virtual IP address claimed by kube-vip |
| `rke2_vip_hostname` | Hostname for the VIP |

```bash
ansible-playbook -i inventory rke2-ha-plays/install-kubevip-static-pod.yml
```

---

### 4. `rke2-ha-plays/install-rke2-on-leader.yml`
**Hosts:** `rke2_bootstrap` (node1 only)

Bootstraps the first RKE2 server node. This node initializes the etcd cluster and
starts the Kubernetes API server. kube-vip starts alongside RKE2 and immediately
claims the VIP. The play waits on port 9345 until the bootstrap node is ready to
accept joins from secondary nodes.

RKE2 auto-generates a cluster token on first start. `add-cluster-token-to-leader.yml`
reads it back from `/var/lib/rancher/rke2/server/token` and writes it into `config.yaml`.
Control plane and worker nodes read the token from the leader node at join time — no
manual token configuration required.

**Vars file:** `rke2-ha-plays/vars/install-rke2-on-leader.yml`

| Variable | Description |
|----------|-------------|
| `rke2_version` | RKE2 version to install (e.g. `v1.34.3+rke2r3`) |
| `rke2_vip_ip` | Virtual IP address of the kube-vip load balancer |
| `rke2_vip_hostname` | Hostname for the VIP |

```bash
ansible-playbook -i inventory rke2-ha-plays/install-rke2-on-leader.yml
```

---

### 5. `rke2-ha-plays/create-control-plane.yml`
**Hosts:** `rke2-control-nodes` (node2 and node3)

Joins node2 and node3 to the cluster as full server nodes. They connect to the
bootstrap node's real IP on port 9345 — not the VIP — because kube-vip on those
nodes has not started yet at join time. Once all three nodes are up there is no
primary/secondary distinction — all are equal server nodes.

> **Why not the VIP?** The `server:` line in `config.yaml` is only used for the
> initial join handshake. kube-vip on the joining node hasn't started yet, so
> routing through the VIP locally is unreliable at that moment. The bootstrap
> node's kube-vip already holds the VIP and is reachable, but using the real IP
> avoids any timing dependency. Once the cluster is up, etcd handles all
> inter-node communication directly — the `server:` value is no longer used.

Must run only after step 4 completes successfully.

**Vars file:** `rke2-ha-plays/vars/create-control-plane.yml`

| Variable | Description |
|----------|-------------|
| `rke2_version` | RKE2 version — must match the bootstrap node |
| `rke2_vip_ip` | Virtual IP address of the kube-vip load balancer |
| `rke2_vip_hostname` | Hostname for the VIP |

```bash
ansible-playbook -i inventory rke2-ha-plays/create-control-plane.yml
```

---

### 6. `rke2-ha-plays/install-rke2-on-worker-nodes.yml`
**Hosts:** `rke2-worker-nodes`

Joins any worker nodes defined in the `[rke2-worker-nodes]` inventory group. Worker nodes
connect via the VIP so they remain connected even if the bootstrap node goes down.
Exits cleanly if `rke2-worker-nodes` is empty or not defined.

**Vars file:** `rke2-ha-plays/vars/install-rke2-on-worker-nodes.yml`

| Variable | Description |
|----------|-------------|
| `rke2_version` | RKE2 version — must match the server nodes |
| `rke2_vip_ip` | Virtual IP address agents use to join the cluster |

```bash
ansible-playbook -i inventory rke2-ha-plays/install-rke2-on-worker-nodes.yml
```

---

## Inventory Groups Required

| Group | Role |
|-------|------|
| `rke2_bootstrap` | Node 1 only — initializes the etcd cluster |
| `rke2-control-nodes` | All three server nodes including node1 |
| `rke2-worker-nodes` | Worker nodes (optional) |

Example inventory:

```ini
[rke2_bootstrap]
node1 ansible_host=192.168.1.201 ansible_user=root

[rke2-control-nodes]
node1 ansible_host=192.168.1.201 ansible_user=root
node2 ansible_host=192.168.1.202 ansible_user=root
node3 ansible_host=192.168.1.203 ansible_user=root
```
