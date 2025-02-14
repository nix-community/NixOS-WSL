# Building your own system tarball

This requires access to a system that already has Nix installed. Please refer to the [Nix installation guide](https://nixos.org/guides/install-nix.html) if that\'s not the case.

If you have a flakes-enabled Nix, you can use the following command to
build your own tarball instead of relying on a prebuilt one:

```sh
sudo nix run github:nix-community/NixOS-WSL#nixosConfigurations.default.config.system.build.tarballBuilder
```

Or, if you want to build with local changes, run inside your checkout:

```sh
sudo nix run .#nixosConfigurations.your-hostname.config.system.build.tarballBuilder
```

Without a flakes-enabled Nix, you can build a tarball using:

```sh
nix-build -A nixosConfigurations.default.config.system.build.tarballBuilder && sudo ./result/bin/nixos-wsl-tarball-builder

```

The resulting tarball can then be found under `nixos.wsl`.
