
{
  description = "NixOS WSL";

 inputs = {
    nixpkgs.url = "nixpkgs/nixos-20.09";
  };
  
  outputs = { nixpkgs, ... }@inputs: {
    nixosConfigurations = {

      mysystem = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import ./configuration.nix)
          (import ./build-tarball.nix)
        ];
        specialArgs = { inherit (inputs) nixpkgs; };
      };
    };
  };
}
