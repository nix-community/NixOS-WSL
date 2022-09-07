{ config, lib, pkgs, ... }:
with builtins; with lib; {

  imports = [
    (mkRenamedOptionModule [ "wsl" "docker" ] [ "wsl" "docker-desktop" ])
  ];

  options.wsl.docker-desktop = with types; {
    enable = mkEnableOption "Docker Desktop integration";
  };

  config =
    let
      cfg = config.wsl.docker-desktop;
    in
    mkIf (config.wsl.enable && cfg.enable) {

      environment.systemPackages = with pkgs; [
        docker
        docker-compose
      ];

      systemd.services.docker-desktop-proxy = {
        description = "Docker Desktop proxy";
        script = ''
          ${config.wsl.automountPath}/wsl/docker-desktop/docker-desktop-user-distro proxy --docker-desktop-root ${config.wsl.automountPath}/wsl/docker-desktop
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
