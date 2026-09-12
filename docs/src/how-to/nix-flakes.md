# How to configure NixOS-WSL with flakes

[Flakes](https://wiki.nixos.org/wiki/Flakes) are an alternative, optional way
to manage your NixOS configuration. They aren't required to use NixOS-WSL, but
if you're already familiar with them, or want to use flake-only tooling, they
work fine here too. If you're new to NixOS, it's fine to skip this page and
stick with the plain `configuration.nix` setup from the rest of the docs.

To switch to a flake-based configuration, create a new `/etc/nixos/flake.nix`
(don't add this to `/etc/nixos/configuration.nix` — that will error, since
`configuration.nix` is plain NixOS module syntax, not a flake). Your existing
`configuration.nix` doesn't need to be rewritten: the flake below imports it
as a module alongside `nixos-wsl.nixosModules.default`, so it keeps working
as-is.

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
          {
            wsl.enable = true;
          }
        ];
      };
    };
  };
}
```

`./configuration.nix` is your existing configuration — keep editing it as
before, it's still plain NixOS module syntax. `flake.nix` just wraps it and
adds `nixos-wsl.nixosModules.default` and `wsl.enable = true`, which is what
actually enables NixOS-WSL. If `configuration.nix` already sets
`system.stateVersion`, you don't need to set it again here.
