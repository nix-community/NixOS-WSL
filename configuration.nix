{ lib, pkgs, config, modulesPath, ... }:

with lib;
let
  defaultUser = "nixos";
  automountPath = "/mnt";
  syschdemd = import ./syschdemd.nix { inherit lib pkgs config defaultUser; };
in
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];

  # WSL is closer to a container than anything else
  boot.isContainer = true;

  environment.etc.hosts.enable = false;
  environment.etc."resolv.conf".enable = false;

  networking.dhcpcd.enable = false;

  users.users.${defaultUser} = {
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


  # WSLg support
  environment.variables = {
    DISPLAY = ":0";
    WAYLAND_DISPLAY = "wayland-0";

    PULSE_SERVER = "${automountPath}/wslg/PulseServer";
    XDG_RUNTIME_DIR = "${automountPath}/wslg/runtime-dir";
    WSL_INTEROP = "/run/WSL/1_interop";
  };

  environment.etc."wsl.conf".text = ''
    [automount]
    enabled=true
    mountFsTab=true
    root=${automountPath}/
    options=metadata,uid=1000,gid=100
  '';

  system.activationScripts.copy-launchers.text = ''
    for x in applications icons; do
      echo "Copying /usr/share/$x"
      rm -rf /usr/share/$x
      cp -r $systemConfig/sw/share/$x/. /usr/share/$x
    done
  '';
}
