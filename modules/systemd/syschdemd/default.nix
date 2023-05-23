{ config, lib, pkgs, ... }:
with lib; {

  config =
    let
      cfg = config.wsl;

      utils = pkgs.callPackage ../../../utils { };

      syschdemd = pkgs.callPackage ./syschdemd.nix {
        inherit utils;

        automountPath = cfg.wslConf.automount.root;
        defaultUser = config.users.users.${cfg.defaultUser};
      };
    in
    mkIf (cfg.enable && (!cfg.nativeSystemd)) {

      users.users.root.shell = "${syschdemd}/bin/syschdemd";
      security.sudo.extraConfig = ''
        Defaults env_keep+=INSIDE_NAMESPACE
      '';
      wsl.wslConf.user.default = "root";

      # Start a systemd user session when starting a command through runuser
      security.pam.services.runuser.startSession = true;

      # Include Windows %PATH% in Linux $PATH.
      environment.extraInit = mkIf cfg.interop.includePath ''PATH="$PATH:$WSLPATH"'';

    };

}
