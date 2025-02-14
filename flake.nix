{
  description = "NixOS WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = function: lib.genAttrs systems (system: function nixpkgs.legacyPackages.${system});
    in
    {
      nixosModules.wsl = {
        imports = [
          ./modules

          (_: {
            wsl.version.rev = lib.mkIf (self ? rev) self.rev;
          })
        ];
      };
      nixosModules.default = self.nixosModules.wsl;

      nixosConfigurations =
        let
          config = { legacy ? false }: { config, lib, pkgs, ... }: {
            wsl.enable = true;
            wsl.nativeSystemd = lib.mkIf legacy false;
            programs.bash.loginShellInit = "nixos-wsl-welcome";

            # When the config is built from a flake, the NIX_PATH entry of nixpkgs is set to its flake version.
            # Per default the resulting systems aren't flake-enabled, so rebuilds would fail.
            # Note: This does not affect the module being imported into your own flake.
            nixpkgs.flake.source = lib.mkForce null;

            systemd.tmpfiles.rules =
              let
                channels = pkgs.runCommand "default-channels" { } ''
                  mkdir -p $out
                  ln -s ${pkgs.path} $out/nixos
                  ln -s ${./.} $out/nixos-wsl
                '';
              in
              [
                "L /nix/var/nix/profiles/per-user/root/channels-1-link - - - - ${channels}"
                "L /nix/var/nix/profiles/per-user/root/channels - - - - channels-1-link"
              ];
            system.stateVersion = config.system.nixos.release;
          };
        in
        {
          default = lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.default
              (config { })
            ];
          };

          modern = lib.warn "nixosConfigurations.modern has been renamed to nixosConfigurations.default" self.nixosConfigurations.default;

          legacy = lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.default
              (config { legacy = true; })
            ];
          };
        };

      checks = forAllSystems (
        pkgs:
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
          test-native-utils = self.packages.${pkgs.stdenv.hostPlatform.system}.utils;
        }
      );

      packages = forAllSystems (pkgs: {
        utils = pkgs.callPackage ./utils { };
        staticUtils = pkgs.pkgsStatic.callPackage ./utils { };
        docs = pkgs.callPackage ./docs { };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

          nativeBuildInputs = with pkgs; [
            cargo
            clippy
            mdbook
            nixpkgs-fmt
            powershell
            rustc
            rustfmt
            shfmt
          ];
        };
      });
    };
}
