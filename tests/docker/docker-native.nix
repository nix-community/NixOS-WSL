{
  imports = [ ./base.nix ];

  # Github Actions runners try to use aufs and fail if this is not set explicitly
  virtualisation.docker.daemon.settings = {
    "storage-driver" = "vfs";
  };
}
