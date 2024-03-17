{
  description = "NixOS WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
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
          ./modules

          (_: {
            wsl.version.rev = mkIf (self ? rev) self.rev;
          })
        ];
      };
      nixosModules.default = self.nixosModules.wsl;

      nixosConfigurations =
        let
          config = { test ? false, legacy ? false }: { config, lib, ... }: {
            wsl.enable = true;
            wsl.nativeSystemd = lib.mkIf legacy false;
            programs.bash.loginShellInit = lib.mkIf (!test) "nixos-wsl-welcome";
            system.stateVersion = config.system.nixos.release;
          };
        in
        {
          modern = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.default
              (config { })
            ];
          };

          legacy = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.default
              (config { legacy = true; })
            ];
          };

          test-windows = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.default
              (config { test = true; })
            ];
          };

          test-docker = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.default
              (config { test = true; legacy = true; })
              ({ config, pkgs, ... }: {
                system.activationScripts.create-test-entrypoint.text =
                  let
                    syschdemdProxy = pkgs.writeShellScript "syschdemd-proxy" ''
                      shell=$(${pkgs.getent}/bin/getent passwd root | ${pkgs.coreutils}/bin/cut -d: -f7)
                      exec $shell $@
                    '';
                  in
                  ''
                    mkdir -p /bin
                    ln -sfn ${syschdemdProxy} /bin/syschdemd
                  '';
              })
            ];
          };
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
              dotnet-format = pkgs.callPackage ./checks/dotnet-format.nix args;
              nixpkgs-fmt = pkgs.callPackage ./checks/nixpkgs-fmt.nix args;
              shfmt = pkgs.callPackage ./checks/shfmt.nix args;
              rustfmt = pkgs.callPackage ./checks/rustfmt.nix args;
              side-effects = pkgs.callPackage ./checks/side-effects.nix args;
              username = pkgs.callPackage ./checks/username.nix args;
              test-native-utils = self.packages.${system}.utils;
            };

          packages = {
            utils = pkgs.callPackage ./utils { };
            staticUtils = pkgs.pkgsStatic.callPackage ./utils { };
            docs = pkgs.callPackage ./docs { };
          };

          devShells.default = pkgs.mkShell {
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

            nativeBuildInputs = with pkgs; [
              cargo
              clippy
              mdbook
              nixpkgs-fmt
              rustc
              rustfmt
              shfmt
            ];
          };
        }
      );
}
