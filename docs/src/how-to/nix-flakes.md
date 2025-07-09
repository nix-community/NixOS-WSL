# How to configure NixOS-WSL with flakes

First add a `nixos-wsl` input, then add `nixos-wsl.nixosModules.default` to your nixos configuration.

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
          {
            system.stateVersion = "25.05";
            wsl.enable = true;
          }
        ];
      };
    };
  };
}
```
