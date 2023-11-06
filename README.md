<h1 align=center>
  NixOS on WSL<br />
  <a href="https://matrix.to/#/#wsl:nixos.org"><img src="https://img.shields.io/matrix/wsl:nixos.org?server_fqdn=matrix.org&logo=matrix" alt="Matrix Chat" /></a>
  <a href="https://github.com/NixOS/nixpkgs/tree/nixos-23.05"><img src="https://img.shields.io/badge/nixpkgs-23.05-brightgreen" alt="nixpkgs 23.05" /></a>
  <a href="https://github.com/nix-community/NixOS-WSL/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/nix-community/NixOS-WSL/total"></a>
</h1>

A minimal root filesystem for running NixOS on WSL. It can be used with
[DistroLauncher](https://github.com/microsoft/WSL-DistroLauncher) as
`install.tar.gz` or as input to `wsl --import --version 2`.

## System requirements

NixOS-WSL is tested with the Windows Store version of WSL 2, which is now available on all supported Windows releases (both 10 and 11).
Support for older "inbox" versions is best-effort.

## Quick start

First, [download the latest release](https://github.com/nix-community/NixOS-WSL/releases/latest).

Then open up a Terminal, PowerShell or Command Prompt and run:

```sh
wsl --import NixOS .\NixOS\ nixos-wsl.tar.gz --version 2
```

This sets up a new WSL distribution `NixOS` that is installed under
`.\NixOS`. `nixos-wsl.tar.gz` is the path to the file you
downloaded earlier. You might need to change this path or change to the download directory first.

You can now run NixOS:

```sh
wsl -d NixOS
```

If you want to make NixOS your default distribution, you can do so with

```sh
wsl -s NixOS
```

## Troubleshooting

A recovery shell can be started with

```sh
wsl -d NixOS --system --user root -- /mnt/wslg/distro/bin/nixos-wsl-recovery
```

This will load the WSL "system" distribution, activate your configuration,
then chroot into your NixOS system, similar to what `nixos-enter` would do
on a normal NixOS install.

You can choose an older generation to load with

```sh
wsl -d NixOS --system --user root -- /mnt/wslg/distro/bin/nixos-wsl-recovery --system /nix/var/nix/profiles/system-42-link
```

(note that the path is relative to the new root)

## Building your own system tarball

This requires access to a system that already has Nix installed. Please refer to the [Nix installation guide](https://nixos.org/guides/install-nix.html) if that\'s not the case.

If you have a flakes-enabled Nix, you can use the following command to
build your own tarball instead of relying on a prebuilt one:

```cmd
sudo nix run github:nix-community/NixOS-WSL#nixosConfigurations.modern.config.system.build.tarballBuilder
```

Or, if you want to build with local changes, run inside your checkout:

```cmd
sudo nix run .#nixosConfigurations.your-hostname.config.system.build.tarballBuilder
```

Without a flakes-enabled Nix, you can build a tarball using:

```cmd
nix-build -A nixosConfigurations.mysystem.config.system.build.tarballBuilder && sudo ./result/bin/nixos-wsl-tarball-builder

```

The resulting tarball can then be found under `nixos-wsl.tar.gz`.

## Design

Getting NixOS to run under WSL requires some workarounds:

- instead of directly loading systemd, we use a small shim that runs the NixOS activation scripts first
- some additional binaries required by WSL's internal tooling are symlinked to FHS paths on activation

Running on older WSL versions also requires a workaround to spawn systemd by hijacking the root shell and
spawning a container with systemd inside. This method of running things is deprecated and not recommended,
however still available as `nixos-wsl-legacy.tar.gz` or via `wsl.nativeSystemd = false`.

## License

Apache License, Version 2.0. See `LICENSE` or <http://www.apache.org/licenses/LICENSE-2.0.html> for details.

## Further links

- [DistroLauncher](https://github.com/microsoft/WSL-DistroLauncher)
- [A quick way into a systemd \"bottle\" for WSL](https://github.com/arkane-systems/genie)
- [NixOS in Windows Store for Windows Subsystem for Linux](https://github.com/NixOS/nixpkgs/issues/30391)
- [wsl2-hacks](https://github.com/shayne/wsl2-hacks)
