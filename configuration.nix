{ lib, pkgs, config, modulesPath, ... }:

with lib;
let
  defaultUser = "nixos";
  automountPath = "/mnt";
  syschdemd = import ./syschdemd.nix { inherit lib pkgs config defaultUser; };
  nixos-wsl = import ./default.nix;
in
{
  imports = with nixos-wsl.nixosModules; [
    "${modulesPath}/profiles/minimal.nix"

    build-tarball
  ];

  # WSL is closer to a container than anything else
  boot.isContainer = true;

  # Include Windows %PATH% in Linux $PATH.
  environment.extraInit = ''PATH="$PATH:$WSLPATH"'';

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

  security.sudo = {
    extraConfig = ''
      Defaults env_keep+=INSIDE_NAMESPACE
    '';
    wheelNeedsPassword = false;
  };

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

  environment.etc."wsl.conf".text = ''
    [automount]
    enabled=true
    mountFsTab=true
    root=${automountPath}/
    options=metadata,uid=1000,gid=100
  '';

  system.activationScripts = {
    copy-launchers = stringAfter [] ''
      for x in applications icons; do
        echo "Copying /usr/share/$x"
        ${pkgs.rsync}/bin/rsync -ar --delete $systemConfig/sw/share/$x/. /usr/share/$x
      done
    '';
  };
}
