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
      type = lib.types.either
        (lib.types.enum [
          "!@system"
          "@system"
        ])
        (lib.types.listOf lib.types.str);
      default = "!@system";
      description = ''
        Users to activate the service for. Defaults to all non-system users.
      '';
    };
  };

  config = lib.mkIf (config.wsl.enable && cfg.enable) {
    assertions = [
      {
        assertion = builtins.isList cfg.users -> lib.all (u: lib.hasAttr u config.users.users) cfg.users;
        message = ''
          wsl.ssh-agent.users contains users that do not exist in users.users:
          ${lib.concatStringsSep ", " (lib.filter (u: !lib.hasAttr u config.users.users) cfg.users)}
        '';
      }
    ];

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
