{ config, lib, pkgs, ... }:
with lib; {

  config =
    let
      cfg = config.wsl;

      utils = pkgs.callPackage ../../utils { };

      syschdemd = pkgs.callPackage ./syschdemd.nix {
        inherit utils;

        automountPath = cfg.wslConf.automount.root;
        defaultUser = config.users.users.${cfg.defaultUser};
      };
    in
    mkIf (cfg.enable && (!cfg.nativeSystemd)) {

      users.users.root.shell = "${utils}/bin/systemd-container";
      security.sudo.extraConfig = ''
        Defaults env_keep+=INSIDE_NAMESPACE
      '';
      wsl.wslConf.user.default = "root";

      systemd.services.system-ready = rec {
        wantedBy = [ "multi-user.target" ];
        wants = [ "basic.target" "systemd-logind.service" ]; # logind is needed for user-sessions
        after = config.systemd.services.system-ready.wants;
        serviceConfig.Type = "oneshot";
        serviceConfig.ExecStart = "${pkgs.coreutils}/bin/touch /run/nixos-wsl/system-ready";
      };

      # Start a systemd user session when starting a command through runuser
      security.pam.services.runuser.startSession = true;

      # Include Windows %PATH% in Linux $PATH.
      environment.extraInit = mkIf cfg.interop.includePath ''PATH="$PATH:$WSLPATH"'';

    };

}
