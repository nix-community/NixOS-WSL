{ config, lib, ... }:
with lib; {

  imports = [
    ./native
    ./syschdemd
  ];

  options.wsl = with types; {
    nativeSystemd = mkOption {
      type = bool;
      default = true;
      description = "Use native WSL systemd support";
    };
  };

  config =
    let
      cfg = config.wsl;
    in
    mkIf (cfg.enable) {

      # systemd-oomd requires cgroup pressure info which WSL doesn't have
      systemd.oomd.enable = false;

      # useful for usbip but adds a dependency on various firmwares which are combined over 300 MB big
      services.udev.enable = lib.mkDefault false;

      systemd = {
        # Disable systemd units that don't make sense on WSL
        services = {
          firewall.enable = false;
          systemd-resolved.enable = lib.mkDefault false;
          # systemd-timesyncd actually works in WSL and without it the clock can drift
          systemd-timesyncd.unitConfig.ConditionVirtualization = "";
        };

        # Don't allow emergency mode, because we don't have a console.
        enableEmergencyMode = false;

        # Link the X11 socket into place. This is a no-op on a normal setup,
        # but helps if /tmp is a tmpfs or mounted from some other location.
        tmpfiles.rules = [ "L /tmp/.X11-unix - - - - ${cfg.wslConf.automount.root}/wslg/.X11-unix" ];
      };

    };

}
