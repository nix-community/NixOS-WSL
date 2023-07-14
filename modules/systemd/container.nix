{ config, lib, pkgs, ... }:
with lib; {

  config =
    let
      cfg = config.wsl;
    in
    mkIf (cfg.enable && (!cfg.nativeSystemd)) {

      users.users.root.shell = "${pkgs.nixos-wsl-utils}/bin/systemd-container";

      wsl.wslConf.user.default = "root";

      wsl.tarball.entrypoint = "${pkgs.nixos-wsl-utils}/bin/systemd-container";

      systemd.services.system-ready = rec {
        wantedBy = [ "multi-user.target" ];
        wants = [ "basic.target" "systemd-logind.service" ]; # logind is needed for user-sessions
        after = config.systemd.services.system-ready.wants;
        serviceConfig.Type = "oneshot";
        serviceConfig.ExecStart = pkgs.writeShellScript "system-ready" ''
          ${pkgs.coreutils}/bin/mkdir -p /run/nixos-wsl
          ${pkgs.coreutils}/bin/touch /run/nixos-wsl/system-ready
        '';
      };

      # Start a systemd user session when starting a command through runuser
      security.pam.services.runuser.startSession = true;

      # Include Windows %PATH% in Linux $PATH.
      environment.extraInit = mkIf cfg.interop.includePath ''PATH="$PATH:$WSLPATH"'';

    };

}
