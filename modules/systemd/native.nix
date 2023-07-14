{ config, lib, pkgs, ... }:
with lib; {

  config =
    let
      cfg = config.wsl;
    in
    mkIf (cfg.enable && cfg.nativeSystemd) {
      wsl.wslConf = {
        user.default = config.users.users.${cfg.defaultUser}.name;
        boot.systemd = true;
      };

      system.activationScripts = {
        shimSystemd = stringAfter [ ] ''
          echo "setting up /sbin/init shim..."
          mkdir -p /sbin
          ln -sf ${pkgs.nixos-wsl-utils}/bin/systemd-shim /sbin/init
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
          eval $(${pkgs.nixos-wsl-utils}/bin/split-path --automount-root="${cfg.wslConf.automount.root}" ${lib.optionalString cfg.interop.includePath "--include-interop"})
        '';
      };
    };

}
