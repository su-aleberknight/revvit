plays are organized based on node type
there is a bootstrap node, server nodes, gpu nodes and agent nodes
there are rancher manager plays.  rancher manager will follow the VIP.
good luck!

## SUSE Module Activation Note

The suseconnect play activates `sle-module-desktop-applications` even though this is a headless
server cluster with no graphical desktop. This is not a mistake — SUSE requires it as a
dependency in the activation chain before `sle-module-development-tools` can be activated.
Development Tools provides compilers (gcc, make, cmake) and build tools needed by RKE2 and the
NVIDIA driver. Desktop Applications is never used directly; it is activated purely to satisfy
SUSE's module dependency requirements.


