{
  imports = [
    <nixos-wsl/modules>
  ];

  wsl.enable = true;
  wsl.nativeSystemd = false;

  users.users.nixos.extraGroups = [ "docker" ];

  virtualisation.docker = {
    enable = true;
    # Github Actions runners try to use aufs and fail if this is not set explicitly
    daemon.settings."storage-driver" = "vfs";
  };
}
