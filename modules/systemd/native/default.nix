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
    mkIf (cfg.enable && cfg.nativeSystemd) {

      system.build.nativeUtils = pkgs.callPackage ../../../utils { };

      wsl = {
        binShPkg = bashWrapper;
        wslConf = {
          user.default = config.users.users.${cfg.defaultUser}.name;
          boot.systemd = true;
        };
      };

      system.activationScripts = {
        createBootedSystemSymlink = stringAfter [ "specialfs" "users" "groups" ] ''
          echo "setting up /run/booted-system..."
          [[ -e /run/booted-system ]] || ln -sfn "$(readlink -f "$systemConfig")" /run/booted-system
        '';
        shimSystemd = stringAfter [ ] ''
          echo "setting up /sbin/init shim..."
          mkdir -p /sbin
          ln -sf ${config.system.build.nativeUtils}/bin/systemd-shim /sbin/init
        '';
        setupLogin = lib.mkIf cfg.populateBin (stringAfter [ ] ''
          echo "setting up /bin/login..."
          mkdir -p /bin
          ln -sf ${pkgs.shadow}/bin/login /bin/login
        '');
      };

      environment = {
        # preserve $PATH from parent
        variables.PATH = [ "$PATH" ];
        extraInit = ''
          eval $(${config.system.build.nativeUtils}/bin/split-path --automount-root="${cfg.wslConf.automount.root}" ${lib.optionalString cfg.interop.includePath "--include-interop"})
        '';
      };
    };

}
