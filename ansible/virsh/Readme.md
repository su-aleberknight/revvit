# create-vm.yml

Creates one or more SLES KVM virtual machines using `virt-install` for all hosts defined in the inventory file. Supports SUSE, RHEL/Fedora, and Debian-based host systems. VMs are booted with UEFI.

## Requirements

- The host running this playbook must have KVM/libvirt support
- An ISO image available on the host (configured in `vars/create-vm.yml`)
- Inventory file with the hostnames to use as VM names

## Setup

Copy the vars example and set your values before running:

```bash
cp vars/create-vm.yml.example vars/create-vm.yml
```

<<<<<<< HEAD
To check available OS variants on your system:

```bash
osinfo-query os | grep sles
```

## Usage

```bash
ansible-playbook -i inventory create-vm.yml
```

## Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `vm_iso` | Path to the SLES ISO on the host | `/home/aleberkn/isos/SLES-15-SP6.iso` |
| `vm_disk_path` | Directory to store VM disk images | `/var/lib/libvirt/images` |
| `vm_disk_size` | Disk size in GB | `100` |
| `vm_memory_mb` | RAM in MB | `51200` |
| `vm_vcpus` | Number of vCPUs | `20` |
| `vm_os_variant` | OS variant for virt-install | `sles15sp6` |
| `vm_network` | Libvirt network name | `default` |
| `vm_graphics` | Graphics type | `vnc` |
| `vm_group` | Inventory group to create VMs for | `sles-servers` |

## What it does

1. Installs `libvirt`, `virt-install`, `qemu-kvm`, and `ovmf` (UEFI firmware) if not present
2. Starts and enables the `libvirtd` service
3. Checks if each VM already exists — skips creation if it does
4. Creates a qcow2 disk image for each VM
5. Runs `virt-install` for each VM using UEFI boot and the configured ISO
6. Prints status info for all VMs when done

## Notes

- VMs are named after their hostnames in the inventory file
- The ISO is mounted as a virtual CD-ROM — OS installation must be completed manually via VNC
- To connect to a VM console during installation use `scripts/vnc-tunnel.sh`
=======
then run it using: 
ansible-playbook ./create-vm.yml -i inventory
>>>>>>> 03685be (rebase)
