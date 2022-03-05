{ lib, pkgs, config, modulesPath, ... }:
let
  cfg = config.wsl;
  syschdemd = import ./syschdemd.nix {
    inherit lib pkgs config;
    inherit (cfg) defaultUser;
  };
in
{
  options.wsl = {
    enable = lib.mkEnableOption "wsl";
    defaultUser = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
    };
  };
  config = lib.mkIf cfg.enable {
    # WSL is closer to a container than anything else
    boot.isContainer = true;

    environment.etc.hosts.enable = false;
    environment.etc."resolv.conf".enable = false;

    networking.dhcpcd.enable = false;

    users.users.${cfg.defaultUser} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

    users.users.root = {
      shell = "${syschdemd}/bin/syschdemd";
      # Otherwise WSL fails to login as root with "initgroups failed 5"
      extraGroups = [ "root" ];
    };

    security.sudo.wheelNeedsPassword = false;

    # Disable systemd units that don't make sense on WSL
    systemd.services."serial-getty@ttyS0".enable = false;
    systemd.services."serial-getty@hvc0".enable = false;
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@".enable = false;

    systemd.services.firewall.enable = false;
    systemd.services.systemd-resolved.enable = false;
    systemd.services.systemd-udevd.enable = false;

    # Don't allow emergency mode, because we don't have a console.
    systemd.enableEmergencyMode = false;
  };
}
