{
  description = "NixOS WSL";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-20.09";
    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    {
      nixosModules = {
        build-tarball = import ./modules/build-tarball.nix;
        wsl-distro = import ./modules/wsl-distro.nix;
      };

      nixosConfigurations.mysystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
      };

    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        checks.check-format = pkgs.runCommand "check-format"
          {
            buildInputs = with pkgs; [ nixpkgs-fmt ];
          } ''
          nixpkgs-fmt --check ${./.}
          mkdir $out # success
        '';

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ nixpkgs-fmt ];
        };
      }
    );
}
