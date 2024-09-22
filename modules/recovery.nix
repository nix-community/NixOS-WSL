{ config, pkgs, ... }:
let
  nixos-enter = pkgs.nixos-enter or config.system.build.nixos-enter;
  nixos-enter' = nixos-enter.overrideAttrs (_: {
    runtimeShell = "/bin/bash";
  });

  recovery = pkgs.writeScriptBin "nixos-wsl-recovery" ''
    #! /bin/sh
    if [ -f /etc/NIXOS ]; then
      echo "nixos-wsl-recovery should only be run from the WSL system distribution."
      echo "Example:"
      echo "    wsl --system --distribution NixOS --user root -- /nix/var/nix/profiles/system/bin/nixos-wsl-recovery"
      exit 1
    fi
    mount -o remount,rw /mnt/wslg/distro
    exec /mnt/wslg/distro/${nixos-enter'}/bin/nixos-enter --root /mnt/wslg/distro "$@"
  '';

in
{

  config = {
    wsl.extraBin = [
      # needs to be a copy, not a symlink, to be executable from outside
      { src = "${recovery}/bin/nixos-wsl-recovery"; copy = true; }
    ];
  };

}
