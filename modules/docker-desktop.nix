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

      wsl.extraBin = with pkgs; [
        # Required unconditionally to check that the WSL environment is conformant.
        { src = "${coreutils}/bin/cat"; }
        { src = "${coreutils}/bin/whoami"; }
        # Required to create the 'docker' group and add the WSL user to it.
        # This group and its user membership are managed by NixOS below but we
        # create those symlinks anyway for robustness.
        { src = "${shadow}/bin/groupadd"; }
        { src = "${shadow}/bin/usermod"; }
      ];

      systemd.services.docker-desktop-proxy = {
        description = "Docker Desktop proxy";
        script = ''
          ${config.wsl.wslConf.automount.root}/wsl/docker-desktop/docker-desktop-user-distro proxy --docker-desktop-root ${config.wsl.wslConf.automount.root}/wsl/docker-desktop
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
