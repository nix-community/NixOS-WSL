{
  description = "NixOS WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
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
          checks =
            let
              args = { inherit inputs; };
            in
            {
              nixpkgs-fmt = pkgs.callPackage ./checks/nixpkgs-fmt.nix args;
              shfmt = pkgs.callPackage ./checks/shfmt.nix args;
              side-effects = pkgs.callPackage ./checks/side-effects.nix args;
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
