{ config, pkgs, lib, ... }:
with builtins; with lib;
let
  pkgs2storeContents = map (x: { object = x; symlink = "none"; });

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

    # Set system profile
    system=${config.system.build.toplevel}
    ./$system/sw/bin/nix-store --store "$PWD" --load-db < ./nix-path-registration
    rm ./nix-path-registration
    ./$system/sw/bin/nix-env --store "$PWD" -p ./nix/var/nix/profiles/system --set $system

    # Set channel
    mkdir -p ./nix/var/nix/profiles/per-user/root
    ./$system/sw/bin/nix-env --store "$PWD" -p ./nix/var/nix/profiles/per-user/root/channels --set ${channelSources}
    mkdir -m 0700 -p ./root/.nix-defexpr
    ln -s /nix/var/nix/profiles/per-user/root/channels ./root/.nix-defexpr/channels

    mkdir -p sbin nix/nixos-wsl/entrypoint
    ln -s ${pkgs.wslNativeUtils}/bin/systemd-shim ./sbin/init

    ${lib.optionalString config.wsl.tarball.includeConfig ''
      # Copy the system configuration
      mkdir -p ./etc/nixos/nixos-wsl
      cp -R ${lib.cleanSource ../.}/. ./etc/nixos/nixos-wsl
      mv ./etc/nixos/nixos-wsl/configuration.nix ./etc/nixos/configuration.nix
      # Patch the import path to avoid having a flake.nix in /etc/nixos
      sed -i 's|import \./default\.nix|import \./nixos-wsl|' ./etc/nixos/configuration.nix
    ''}
  '';
in
{

  config = mkIf config.wsl.enable {
    assertions = [{
      assertion = config.wsl.nativeSystemd;
      message = "config.wsl.nativeSystemd must be true in order to build a systemd-tarball!";
    }];

    system.build.systemd-tarball = pkgs.callPackage "${nixpkgs}/nixos/lib/make-system-tarball.nix" {

      contents = [
        # WSL needs this before first activation
        { inherit (config.environment.etc."wsl.conf") source; target = "/etc/wsl.conf"; }
      ];

      fileName = "nixos-wsl-${pkgs.hostPlatform.system}";

      storeContents = pkgs2storeContents [
        config.system.build.toplevel
        channelSources
        preparer
      ];

      extraCommands = "${preparer}/bin/wsl-prepare";
      extraArgs = "--hard-dereference";

      # Use gzip
      compressCommand = "gzip";
      compressionExtension = ".gz";
    };

  };
}
