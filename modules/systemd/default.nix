{ config, lib, ... }:

{
  imports = [
    ./native

    (lib.mkRemovedOptionModule [ "wsl" "nativeSystemd" ] "Native systemd is now always enabled as support for syschdemd has been removed")
  ];

  config = lib.mkIf config.wsl.enable {
    # useful for usbip but adds a dependency on various firmwares which are combined over 300 MB big
    services.udev.enable = lib.mkDefault false;

    systemd = {
      # systemd-oomd requires cgroup pressure info (PSI). Older WSL2 kernels
      # lacked CONFIG_PSI, but modern kernels (6.1+) support it.
      oomd.enable = lib.mkDefault false;
      # Disable systemd units that don't make sense on WSL
      services.firewall.enable = false;

      # Don't allow emergency mode, because we don't have a console.
      enableEmergencyMode = false;
    };
  };
}
