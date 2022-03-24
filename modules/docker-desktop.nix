{ config, lib, pkgs, ... }:
with builtins; with lib; {

  options.wsl.docker = with types; {
    enable = mkEnableOption "Docker Desktop integration";
  };

  config =
    let
      cfg = config.wsl.docker;
    in
    mkIf (config.wsl.enable && cfg.enable) {

      environment.systemPackages = with pkgs; [
        docker
        docker-compose
      ];

      systemd.services.docker-desktop-proxy = {
        description = "Docker Desktop proxy";
        script = ''
          ${config.wsl.automountPath}/wsl/docker-desktop/docker-desktop-proxy -docker-desktop-root ${config.wsl.automountPath}/wsl/docker-desktop
        '';
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "30s";
        };
      };

      users.groups.docker.members = [
        config.wsl.defaultUser
      ];

    };

}
