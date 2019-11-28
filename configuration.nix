{ lib, pkgs, config, ... }:

with lib;

let
  syschdemd = import ./syschdemd.nix { inherit lib pkgs config; };
in
{
  imports = [
    <nixpkgs/nixos/modules/profiles/minimal.nix>
  ];

  # WSL is closer to a container than anything else
  boot.isContainer = true;

  environment.etc.hosts.enable = false;
  environment.etc."resolv.conf".enable = false;

  networking.dhcpcd.enable = false;

  users.users.andy = {
    isNormalUser = true;
    shell = "${syschdemd}/bin/syschdemd";
    extraGroups = [ "wheel" ];
  };

  # Described as "it should not be overwritten" in NixOS documentation,
  # but it's on /run per default and WSL mounts /run as a tmpfs, hence
  # hiding the wrappers.
  security.wrapperDir = "/wrappers";

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
}
