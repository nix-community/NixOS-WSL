{ config, pkgs, lib, ... }:
with lib; {

  imports = [
    ./wrap-shell.nix
  ];

  config =
    let
      cfg = config.wsl;

      bashWrapper = pkgs.writeShellScriptBin "sh" ''
        export PATH="$PATH:${lib.makeBinPath [ pkgs.systemd pkgs.gnugrep ]}"
        exec ${pkgs.bashInteractive}/bin/sh "$@"
      '';
    in
    mkIf (cfg.enable) {

      system.build.nativeUtils = pkgs.callPackage ../../../utils { };

      wsl = {
        binShPkg = bashWrapper;
        wslConf = {
          user.default = config.users.users.${cfg.defaultUser}.name;
          boot.systemd = true;
        };
        extraBin = [
          { src = "${pkgs.shadow}/bin/login"; }
        ];
      };

      system.activationScripts = {
        createBootedSystemSymlink = stringAfter [ "specialfs" "users" "groups" ] ''
          echo "setting up /run/booted-system..."
          [[ -e /run/booted-system ]] || ln -sfn "$(readlink -f "$systemConfig")" /run/booted-system
        '';
        createSbin = stringAfter (optional cfg.populateBin "populateBin") (
          if cfg.populateBin
          then ''
            echo "setting up /sbin..."
            if [ ! -L /sbin ]; then
              rm -rf /sbin
              ln -s /bin /sbin
            fi
          ''
          else ''
            echo "setting up /sbin..."
            if [ ! -d /sbin ] || [ -L /sbin ]; then
              rm -rf /sbin
              mkdir -p /sbin
            fi
          ''
        );
        shimSystemd = stringAfter [ "createSbin" ] ''
          echo "setting up /sbin/init shim..."
          ln -sf ${config.system.build.nativeUtils}/bin/systemd-shim /sbin/init
        '';
      };

      environment = lib.mkIf cfg.interop.includePath {
        # Capture Windows interop paths from the PATH set by WSL. Skip paths
        # which don't start with /mnt/c; they are generic defaults (eg.
        # /usr/local/sbin) that don't exist on NixOS.
        variables.INTEROP_PATH = ''
          $(echo -n "$PATH" \
          | ${pkgs.coreutils}/bin/tr ':' '\n' \
          | ${pkgs.gnugrep}/bin/grep '^${cfg.wslConf.automount.root}/' \
          | ${pkgs.coreutils}/bin/paste -sd: -)
        '';

        extraInit = ''
          export PATH="$PATH:$INTEROP_PATH"
          unset INTEROP_PATH
        '';
      };
    };

}
