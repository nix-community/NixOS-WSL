{ config, lib, pkgs, ... }:
with builtins; with lib; {

  options.wsl.docker-native = with types; {
    enable = mkEnableOption "Native Docker integration in NixOS.";

    addToDockerGroup = mkOption {
      type = bool;
      default = config.security.sudo.wheelNeedsPassword;
      description = ''
        Wether to add the default user to the docker group.

        This is not recommended, if you have a password, because it essentially permits unauthenticated root access.
      '';
    };
  };

  config =
    let
      cfg = config.wsl.docker-native;
    in
    mkIf (config.wsl.enable && cfg.enable) {
      environment.systemPackages = with pkgs; [
        docker-compose
      ];

      virtualisation.docker.package = (pkgs.docker.override { iptables = pkgs.iptables-legacy; });
      virtualisation.docker.enable = true;

      users.groups.docker.members = lib.mkIf cfg.addToDockerGroup [
        config.wsl.defaultUser
      ];
    };
}
