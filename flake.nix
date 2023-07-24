{
  description = "NixOS WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    with nixpkgs.lib;
    {

      nixosModules.wsl = {
        imports = [
          ./modules/build-tarball.nix
          ./modules/docker-desktop.nix
          ./modules/docker-native.nix
          ./modules/installer.nix
          ./modules/interop.nix
          ./modules/version.nix
          ./modules/wsl-conf.nix
          ./modules/wsl-distro.nix

          ({ ... }: {
            wsl.version.rev = mkIf (self ? rev) self.rev;
          })
        ];
      };
      nixosModules.default = self.nixosModules.wsl;

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
          checks =
            let
              args = { inherit inputs; };
            in
            {
              nixpkgs-fmt = pkgs.callPackage ./checks/nixpkgs-fmt.nix args;
              shfmt = pkgs.callPackage ./checks/shfmt.nix args;
              rustfmt = pkgs.callPackage ./checks/rustfmt.nix args;
              side-effects = pkgs.callPackage ./checks/side-effects.nix args;
              username = pkgs.callPackage ./checks/username.nix args;
              test-native-utils = self.packages.${system}.utils;
            };

          packages = {
            utils = pkgs.callPackage ./scripts/native-utils { };
            staticUtils = pkgs.pkgsStatic.callPackage ./scripts/native-utils { };
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
