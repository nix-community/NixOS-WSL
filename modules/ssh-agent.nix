{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.wsl.ssh-agent;
in
{
  options.wsl.ssh-agent = {
    enable = lib.mkEnableOption "ssh-agent passthrough to Windows";

    package = lib.mkPackageOption pkgs "wsl2-ssh-agent" { };

    users = lib.mkOption {
      type =
        let
          inherit (lib.types) either enum listOf;
          userNames = lib.attrNames config.users.users;
        in
        either
          (enum [
            "!@system"
            "@system"
          ])
          (listOf (enum userNames));
      default = "!@system";
      description = ''
        Users to activate the service for. Defaults to all non-system users.
      '';
    };
  };

  config = lib.mkIf (config.wsl.enable && cfg.enable) {
    systemd.user.services.wsl2-ssh-agent = {
      description = "WSL2 SSH Agent Bridge";
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];
      unitConfig = {
        ConditionUser = lib.join "|" (lib.toList cfg.users);
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/wsl2-ssh-agent --verbose --foreground --socket=%t/wsl2-ssh-agent.sock";
        Restart = "on-failure";
      };
    };

    environment.variables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/wsl2-ssh-agent.sock";
  };
}
