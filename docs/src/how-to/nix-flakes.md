# How to configure NixOS-WSL with flakes

[Flakes](https://wiki.nixos.org/wiki/Flakes) are an alternative, optional way
to manage your NixOS configuration. They aren't required to use NixOS-WSL, but
if you're already familiar with them, or want to use flake-only tooling, they
work fine here too. If you're new to NixOS, it's fine to skip this page and
stick with the plain `configuration.nix` setup from the rest of the docs.

To switch to a flake-based configuration, create a new `/etc/nixos/flake.nix`
(don't add this to `/etc/nixos/configuration.nix`: that will error, since
`configuration.nix` is plain NixOS module syntax, not a flake). The flake below
imports your existing `configuration.nix` as a module, so you can keep editing
it as before.

One change to `configuration.nix` is needed first. The one NixOS-WSL generates
imports the NixOS-WSL modules from a channel:

```nix
  imports = [
    # include NixOS-WSL modules
    <nixos-wsl/modules>
  ];
```

Remove that import. The flake provides the same modules through
`nixos-wsl.nixosModules.default`, and keeping both fails: flakes evaluate in
pure mode, where `<nixos-wsl/modules>` can't be looked up, and if it could, the
modules would be declared twice.

Below is a minimal `flake.nix` for you to get started:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs = { self, nixpkgs, nixos-wsl, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          ./configuration.nix
        ];
      };
    };
  };
}
```

The generated `configuration.nix` already sets `wsl.enable = true` and
`system.stateVersion`, so the flake doesn't need to set them again. If you wrote
your own `configuration.nix` instead, make sure it sets both.
