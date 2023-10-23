{ config, pkgs, lib, ... }:
with builtins; with lib;
let
  cfg = config.wsl;

  defaultConfig = pkgs.writeText "default-configuration.nix" ''
    # Edit this configuration file to define what should be installed on
    # your system. Help is available in the configuration.nix(5) man page, on
    # https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

    # NixOS-WSL specific options are documented on the NixOS-WSL repository:
    # https://github.com/nix-community/NixOS-WSL

    { config, lib, pkgs, ... }:

    {
      imports = [
        # include NixOS-WSL modules
        <nixos-wsl/modules>
      ];

      wsl.enable = true;
      wsl.defaultUser = "nixos";
      ${lib.optionalString (!cfg.nativeSystemd) "wsl.nativeSystemd = false;"}

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It's perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "${config.system.nixos.release}"; # Did you read the comment?
    }
  '';
in
{
  # These options make no sense without the wsl-distro module anyway
  config = mkIf cfg.enable {
    system.build.tarballBuilder = pkgs.writeShellApplication {
      name = "nixos-wsl-tarball-builder";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.gnutar
        pkgs.nixos-install-tools
        config.nix.package
      ];

      text = ''
        if ! [ $EUID -eq 0 ]; then
          echo "This script must be run as root!"
          exit 1
        fi

        out=''${1:-nixos-wsl.tar.gz}

        root=$(mktemp -p "''${TMPDIR:-/tmp}" -d nixos-wsl-tarball.XXXXXXXXXX)
        # FIXME: fails in CI for some reason, but we don't really care because it's CI
        trap 'rm -rf "$root" || true' INT TERM EXIT

        chmod o+rx "$root"

        echo "[NixOS-WSL] Installing..."
        nixos-install \
          --root "$root" \
          --no-root-passwd \
          --system ${config.system.build.toplevel} \
          --substituters ""

        echo "[NixOS-WSL] Adding channel..."
        nixos-enter --root "$root" --command 'nix-channel --add https://github.com/nix-community/NixOS-WSL/archive/refs/heads/main.tar.gz nixos-wsl'

        echo "[NixOS-WSL] Adding default config..."
        install -Dm644 ${defaultConfig} "$root/etc/nixos/configuration.nix"

        echo "[NixOS-WSL] Compressing..."
        tar -C "$root" \
          -cz \
          --sort=name \
          --mtime='@1' \
          --owner=0 \
          --group=0 \
          --numeric-owner \
          . \
          > "$out"
      '';
    };
  };
}
