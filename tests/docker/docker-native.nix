{ pkgs, ... }:
{
  imports = [
    <nixos-wsl/modules>
  ];

  wsl.enable = true;

  users.users.nixos.extraGroups = [ "docker" ];

  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
  };
}
