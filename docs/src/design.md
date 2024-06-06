# Design

Getting NixOS to run under WSL requires some workarounds:

- instead of directly loading systemd, we use a small shim that runs the NixOS activation scripts first
- some additional binaries required by WSL's internal tooling are symlinked to FHS paths on activation

Running on older WSL versions also requires a workaround to spawn systemd by hijacking the root shell and
spawning a container with systemd inside. This method of running things is deprecated and will be removed
with the 24.11 release.
