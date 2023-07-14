{ config, pkgs, utils, lib, ... }:
with builtins; with lib;
{

  options.wsl.tarball = {
    includeConfig = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to copy the system configuration into the tarball";
    };

    entrypoint = mkOption {
      type = types.str;
      internal = true;
      default = config.users.users.root.shell;
    };

    extraPrepare = mkOption {
      type = types.lines;
      default = "";
      description = "Extra commands to run when building the tarball";
    };
  };


  config =
    let
      pkgs2storeContents = l: map (x: { object = x; symlink = "none"; }) l;

      nixpkgs = lib.cleanSource pkgs.path;

      channelSources = pkgs.runCommand "nixos-${config.system.nixos.version}"
        { preferLocalBuild = true; }
        ''
          mkdir -p $out
          cp -prd ${nixpkgs.outPath} $out/nixos
          chmod -R u+w $out/nixos
          if [ ! -e $out/nixos/nixpkgs ]; then
            ln -s . $out/nixos/nixpkgs
          fi
          echo -n ${toString config.system.nixos.revision} > $out/nixos/.git-revision
          echo -n ${toString config.system.nixos.versionSuffix} > $out/nixos/.version-suffix
          echo ${toString config.system.nixos.versionSuffix} | sed -e s/pre// > $out/nixos/svn-revision
        '';

      preparer = pkgs.writeShellScriptBin "wsl-prepare" ''
        set -e

        mkdir -p -m 0755 ./bin ./etc
        mkdir -p -m 1777 ./tmp

        # Set system profile
        system=${config.system.build.toplevel}
        ./$system/sw/bin/nix-store --store `pwd` --load-db < ./nix-path-registration
        rm ./nix-path-registration
        ./$system/sw/bin/nix-env --store `pwd` -p ./nix/var/nix/profiles/system --set $system

        # Set channel
        mkdir -p ./nix/var/nix/profiles/per-user/root
        ./$system/sw/bin/nix-env --store `pwd` -p ./nix/var/nix/profiles/per-user/root/channels --set ${channelSources}
        mkdir -m 0700 -p ./root/.nix-defexpr
        ln -s /nix/var/nix/profiles/per-user/root/channels ./root/.nix-defexpr/channels

        # It's now a NixOS!
        touch ./etc/NIXOS

        # Create /bin/wslpath
        ln -s /init ./bin/wslpath

        ${lib.optionalString config.wsl.tarball.includeConfig ''
          # Copy the system configuration
          mkdir -p ./etc/nixos/nixos-wsl
          cp -R ${lib.cleanSource ../.}/. ./etc/nixos/nixos-wsl
          mv ./etc/nixos/nixos-wsl/configuration.nix ./etc/nixos/configuration.nix
          # Patch the import path to avoid having a flake.nix in /etc/nixos
          sed -i 's|import \./default\.nix|import \./nixos-wsl|' ./etc/nixos/configuration.nix
        ''}

        ${config.wsl.tarball.extraPrepare}
      '';

    in
    mkIf config.wsl.enable {
      # These options make no sense without the wsl-distro module anyway

      system.build.tarball =
        pkgs.callPackage "${nixpkgs}/nixos/lib/make-system-tarball.nix" {
          contents = [
            { source = config.environment.etc."wsl.conf".source; target = "/etc/wsl.conf"; }
            { source = config.environment.etc."fstab".source; target = "/etc/fstab"; }
            { source = pkgs.callPackage (import ./passwd.nix) { inherit config; inherit (utils) toShellPath; }; target = "/etc/passwd"; }
            { source = config.users.users.root.shell; target = "/bin/sh"; } # TODO: Replace with bash?
            { source = "${pkgs.util-linux}/bin/mount"; target = "/bin/mount"; }
            { source = config.wsl.tarball.entrypoint; target = "/nix/nixos-wsl/entrypoint"; }
          ];

          fileName = "nixos-wsl-${pkgs.hostPlatform.system}";

          storeContents = pkgs2storeContents [
            config.system.build.toplevel
            channelSources
            preparer
          ];

          extraCommands = "${preparer}/bin/wsl-prepare";

          # Dereference hard links to prevent wsl --import from failing
          extraArgs = "--hard-dereference";

          # Use gzip
          compressCommand = "gzip";
          compressionExtension = ".gz";
        };

    };
}
