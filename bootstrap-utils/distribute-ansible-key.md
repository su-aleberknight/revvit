# distribute-ansible-key.sh

Generates an ed25519 SSH key named `susecon-ssh` on the local machine and distributes the public key to a single RKE2 node. You will be prompted for the root password of the target node.

## Usage

```bash
./distribute-ansible-key.sh <ip-address>
```

## Example

```bash
./distribute-ansible-key.sh 192.168.1.201
```

Run once per node to distribute the key to all nodes:

```bash
./distribute-ansible-key.sh 192.168.1.200
./distribute-ansible-key.sh 192.168.1.201
./distribute-ansible-key.sh 192.168.1.202
```

## What it does

1. Generates `~/.ssh/susecon-ssh` and `~/.ssh/susecon-ssh.pub` if they don't already exist
2. SSHes into the specified node as root and prompts for the root password
3. Appends the public key to `/root/.ssh/authorized_keys` on the node

## Notes

- Run this script before running any Ansible playbooks against the RKE2 nodes
- After running, you can connect to the node without a password using:
  ```bash
  ssh -i ~/.ssh/susecon-ssh root@<node-ip>
  ```
