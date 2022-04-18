{ config, lib, pkgs, ... }:
with builtins; with lib; {

  options.wsl.docker-native = with types; {
    enable = mkEnableOption "Native Docker integration in NixOS.";
  };

  config =
    let
      cfg = config.wsl.docker-native;
    in
    mkIf (config.wsl.enable && cfg.enable) {
      nixpkgs.overlays = [
        (self: super: {
          docker = super.docker.override { iptables = pkgs.iptables-legacy; };
        })
      ];

      environment.systemPackages = with pkgs; [
        docker
        docker-compose
      ];

      virtualisation.docker.enable = true;

      users.groups.docker.members = [
        config.wsl.defaultUser
      ];
    };

}
