# GPU Node Setup

Two installation modes are supported depending on whether the NVIDIA driver is managed
by the OS or by the GPU Operator:

| Mode | Driver managed by | Use when |
|------|------------------|----------|
| **os-mode** (user-managed) | OS — installed via zypper directly on the node | You want full control over the driver version |
| **container-mode** (operator-managed) | GPU Operator — pulled as a SUSE BCI container | You want the operator to manage the full driver stack |

Add your GPU nodes to the `[gpu_nodes]` inventory group before running either path.

**Prerequisite:** Run `rke2-ha.yml` or `rke2-singlenode.yml` before running any GPU node plays.

---

## Path A — os-mode (User-Managed Driver)

Orchestrated by `gpu-nodes.yml` — runs all four plays below in order:

```bash
ansible-playbook -i inventory gpu-nodes.yml
```

Or run each play individually:

### 1. `gpu-node-plays/gpu-node-nvidia-secrets.yml`
**Hosts:** `rke2_bootstrap`

Creates the NVIDIA NGC pull secret in the `gpu-operator` namespace. Required before
deploying the GPU operator. For os-mode, only the NGC secret is needed — the AppCo
secret is optional and only required for container-mode.

**Vars file:**
```bash
cp gpu-node-plays/vars/gpu-node-nvidia-secrets.yml.example gpu-node-plays/vars/gpu-node-nvidia-secrets.yml
```

| Variable | Description |
|----------|-------------|
| `nvidia_registry.username` | Always `$oauthtoken` |
| `nvidia_registry.password` | NGC API key from `ngc.nvidia.com` |
| `nvidia_registry.secret_name` | Name for the NGC secret (e.g. `nvidia-registry-secret`) |
| `nvidia_registry.namespace` | Namespace for the secret (e.g. `gpu-operator`) |

```bash
ansible-playbook -i inventory gpu-node-plays/gpu-node-nvidia-secrets.yml
```

---

### 2. `gpu-node-plays/gpu-node-nvidia-user-managed-preboot.yml`
**Hosts:** `gpu_nodes`

Adds the NVIDIA CUDA zypper repository, installs the signed open NVIDIA driver
(`nv-prefer-signed-open-driver`), NVIDIA compute utilities, and persistenced directly
on the GPU node OS. **Reboots the node** after installation so the kernel module loads.

No vars file required.

```bash
ansible-playbook -i inventory gpu-node-plays/gpu-node-nvidia-user-managed-preboot.yml
```

Wait for the node to come back online before proceeding to step 3.

---

### 3. `gpu-node-plays/gpu-node-nvidia-user-managed-postboot.yml`
**Hosts:** `gpu_nodes`

Installs the NVIDIA Container Toolkit and configures containerd to use the NVIDIA
runtime (`nvidia-ctk runtime configure`). Restarts `rke2-server` to apply the
containerd configuration.

Must run after the node has rebooted with the NVIDIA driver loaded.

**Vars file:**
```bash
cp gpu-node-plays/vars/gpu-node-nvidia-user-managed-postboot.yml.example gpu-node-plays/vars/gpu-node-nvidia-user-managed-postboot.yml
```

| Variable | Description |
|----------|-------------|
| `nvidia_container_toolkit_version` | Container Toolkit version (e.g. `1.18.2-1`) |

```bash
ansible-playbook -i inventory gpu-node-plays/gpu-node-nvidia-user-managed-postboot.yml
```

---

### 4. `gpu-node-plays/generate-nvidia-gpu-operator.yml`
**Hosts:** `rke2_bootstrap`

Renders and applies a `HelmChart` CRD manifest for the GPU operator. Deploys with
`driver.enabled: false` since the NVIDIA driver is already installed on the OS.
The operator manages only the device plugin, container toolkit, and other components.

Waits for the GPU operator pods to become ready before completing.

**Vars file:**
```bash
cp gpu-node-plays/vars/generate-nvidia-gpu-operator.yml.example gpu-node-plays/vars/generate-nvidia-gpu-operator.yml
```

| Variable | Description |
|----------|-------------|
| `gpu_operator_version` | GPU operator Helm chart version (e.g. `v25.3.4`) |

```bash
ansible-playbook -i inventory gpu-node-plays/generate-nvidia-gpu-operator.yml
```

---

---

## Path B — container-mode (Operator-Managed Driver)

Run the plays individually in this order:

### 1. `gpu-node-plays/gpu-node-nvidia-secrets.yml`
**Hosts:** `rke2_bootstrap`

Creates both the NVIDIA NGC secret **and** the SUSE AppCo secret. The AppCo secret
is required in container-mode so the GPU operator can pull the SUSE BCI NVIDIA driver
image from `registry.suse.com`.

Uncomment the `suse_appco` section in the vars file before running.

**Vars file:**
```bash
cp gpu-node-plays/vars/gpu-node-nvidia-secrets.yml.example gpu-node-plays/vars/gpu-node-nvidia-secrets.yml
```

| Variable | Description |
|----------|-------------|
| `nvidia_registry.username` | Always `$oauthtoken` |
| `nvidia_registry.password` | NGC API key from `ngc.nvidia.com` |
| `nvidia_registry.secret_name` | Name for the NGC secret |
| `nvidia_registry.namespace` | Namespace (e.g. `gpu-operator`) |
| `suse_appco.username` | SUSE AppCo account email |
| `suse_appco.password` | SUSE AppCo account token (from profile → Account Token) |
| `suse_appco.secret_name` | Name for the AppCo secret (e.g. `suse-appco-secret`) |
| `suse_appco.namespace` | Namespace (e.g. `gpu-operator`) |

```bash
ansible-playbook -i inventory gpu-node-plays/gpu-node-nvidia-secrets.yml
```

---

### 2. `gpu-node-plays/gpu-node-nvidia-operator-managed.yml`
**Hosts:** `rke2_bootstrap`

Renders and applies a `HelmChart` CRD manifest for the GPU operator with
`driver.enabled: true`. The operator pulls and manages the SUSE BCI NVIDIA driver
image — no OS-level driver installation is needed on the GPU nodes.

The SUSE BCI image (`registry.suse.com/third-party/nvidia/driver`) is built specifically
for RKE2/SLES and handles the containerd socket and OS integration automatically.
The image tag must match your SLES version (e.g. `580.82.07-sles15.6` for SP6,
`580.82.07-sles15.7` for SP7).

Waits for the GPU operator pods to become ready before completing.

**Prerequisites:**
- cert-manager must be installed (`rancher-manager-plays/install-cert-manager.yml`) — required by the GPU operator
- `gpu-node-nvidia-secrets.yml` must have been run with `suse_appco` defined

**Vars file:**
```bash
cp gpu-node-plays/vars/gpu-node-nvidia-operator-managed.yml.example gpu-node-plays/vars/gpu-node-nvidia-operator-managed.yml
```

| Variable | Description |
|----------|-------------|
| `gpu_operator_version` | GPU operator Helm chart version (e.g. `v25.3.4`) |
| `nvidia_driver_image_version` | SUSE BCI driver image tag — must match your SLES version |
| `appco_secret_name` | Name of the AppCo secret created in step 1 |

```bash
ansible-playbook -i inventory gpu-node-plays/gpu-node-nvidia-operator-managed.yml
```

---

## Inventory

GPU nodes must be added to the `[gpu_nodes]` group in the inventory file:

```ini
[gpu_nodes]
node3 ansible_host=192.168.1.203 ansible_user=root
```

## Verifying GPU access after install

```bash
# Check GPU operator pods are running
kubectl get pods -n gpu-operator

# Verify NVIDIA device plugin is reporting GPUs
kubectl describe nodes | grep nvidia.com/gpu

# Run a quick GPU test pod
kubectl run gpu-test --image=nvcr.io/nvidia/cuda:12.4.0-base-ubuntu22.04 \
  --restart=Never --rm -it -- nvidia-smi
```
