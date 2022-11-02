{
  description = "NixOS WSL";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.05";
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
          ./modules/docker-desktop.nix
          ./modules/docker-native.nix
          ./modules/installer.nix
          ./modules/interop.nix
          ./modules/wsl-conf.nix
          ./modules/wsl-distro.nix
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
      [ "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          checks = {
            check-format = pkgs.runCommand "check-format" { nativeBuildInputs = with pkgs; [ nixpkgs-fmt shfmt ]; } ''
              nixpkgs-fmt --check ${./.}
              shfmt -i 2 -d ${./scripts}/*.sh
              mkdir $out # success
            '';
          };

          devShell = pkgs.mkShell {
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

            nativeBuildInputs = with pkgs; [
              nixpkgs-fmt
              shfmt
              rustc
              cargo
              rustfmt
              clippy
            ];
          };
        }
      );
}
