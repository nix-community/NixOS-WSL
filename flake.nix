{
  description = "NixOS WSL";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    {

      nixosModules.wsl = {
        imports = [
          ./modules/build-tarball.nix
          ./modules/wsl-distro.nix
          ./modules/docker-desktop.nix
          ./modules/installer.nix
        ];
      };

      nixosConfigurations.mysystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
      };

    } //
    flake-utils.lib.eachSystem
      (with flake-utils.lib.system; [ "x86_64-linux" "aarch64-linux" ])
      (system:
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
