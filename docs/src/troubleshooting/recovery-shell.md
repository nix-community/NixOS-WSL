# Recovery Shell

A recovery shell can be started with

```powershell
wsl -d NixOS --system --user root -- /mnt/wslg/distro/bin/nixos-wsl-recovery
```

This will load the WSL "system" distribution, activate your configuration,
then chroot into your NixOS system, similar to what `nixos-enter` would do
on a normal NixOS install.

You can choose an older generation to load with

```powershell
wsl -d NixOS --system --user root -- /mnt/wslg/distro/bin/nixos-wsl-recovery --system /nix/var/nix/profiles/system-42-link
```

(note that the path is relative to the new root)
