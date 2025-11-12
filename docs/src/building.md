# Building your own system tarball

This requires access to a system that already has Nix installed. Please refer to the [Nix installation guide](https://nixos.org/guides/install-nix.html) if that\'s not the case.

If you have a flakes-enabled Nix, you can use the following command to build your own tarball instead of relying on a prebuilt one:

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

## Copying files to the new installation

The tarball builder supports copying in extra files and fixing up ownership before the tarball is packed.

### `--extra-files <path>`

The `--extra-files <path>` option allows copying files into the target root after installation.

The contents of `<path>` are recursively copied and overwrite the target\'s root (`/`). The structure and permissions of `<path>` should already match how you want them on the target.

For example, if you want to copy your SSH host key, you can prepare a directory structure like this:

```sh
root=$(mktemp -d)
sudo mkdir -p $root/etc/ssh
sudo cp /etc/ssh/ssh_host_ed25519_key $root/etc/ssh
```

Then run:

```sh
sudo nix run github:nix-community/NixOS-WSL#nixosConfigurations.default.config.system.build.tarballBuilder -- --extra-files $root
```

By default, everything ends up owned by root.

### `--chown <path> <uid:gid>`

The `--chown` option allows adjusting ownership of directories or files inside the tarball after they\'re copied.

For example:

```sh
sudo nix run github:nix-community/NixOS-WSL#nixosConfigurations.default.config.system.build.tarballBuilder -- \
  --extra-files ./extra \
  --chown /home/myuser 1000:100
```

This is equivalent to running inside the tarball root:

```sh
chown -R 1000:100 /home/myuser
```

The `--chown` option can be used multiple times to set ownership for different paths. Only use this when you can guarantee what the UID/GID will be on the target system.
