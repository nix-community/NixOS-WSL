{ config, lib, pkgs, ... }:

let
  cfg = config.wsl.ssh-agent;
in
{
  options.wsl.ssh-agent = {
    enable = lib.mkEnableOption "ssh-agent passthrough to Windows";
  };

  config = lib.mkIf (config.wsl.enable && cfg.enable) {
    systemd.user.services.wsl2-ssh-agent = {
      description = "WSL2 SSH Agent Bridge";
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];
      unitConfig = {
        ConditionUser = "!root";
      };
      serviceConfig = {
        ExecStart = "${pkgs.wsl2-ssh-agent}/bin/wsl2-ssh-agent --verbose --foreground --socket=%t/wsl2-ssh-agent.sock";
        Restart = "on-failure";
      };
    };

    environment.variables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/wsl2-ssh-agent.sock";
  };
}
