{ pkgs, lib, ... }:
{
  imports = [ ./base.nix ];

  wsl.docker-native.enable = true;
  wsl.docker-native.addToDockerGroup = true;

  # Github Actions runners try to use aufs and fail if this is not set explicitly
  virtualisation.docker.daemon.settings = {
    "storage-driver" = "vfs";
  };
}
