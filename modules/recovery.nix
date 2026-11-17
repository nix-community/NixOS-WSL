{ config, pkgs, ... }:
let
  nixos-enter = pkgs.nixos-enter or config.system.build.nixos-enter;

  recovery = pkgs.writeScriptBin "nixos-wsl-recovery" ''
    #! /bin/sh
    if [ -f /etc/NIXOS ]; then
      echo "nixos-wsl-recovery should only be run from the WSL system distribution."
      echo "Example:"
      echo "    wsl --system --distribution NixOS --user root -- /mnt/wslg/distro/bin/nixos-wsl-recovery"
      exit 1
    fi
    if [ ! -d /mnt/wslg/distro/nix/store ]; then
      echo "nixos-wsl-recovery: /mnt/wslg/distro does not look like a NixOS installation." >&2
      exit 1
    fi
    # Make the Nix store of the NixOS system being repaired available at /nix.
    # The shebang of nixos-enter points at a /nix/store interpreter of that
    # store, which does not exist in the WSL system distribution otherwise.
    mkdir -p /nix
    mount --bind /mnt/wslg/distro/nix /nix
    mount -o remount,rw /mnt/wslg/distro
    exec /mnt/wslg/distro/${nixos-enter}/bin/nixos-enter --root /mnt/wslg/distro "$@"
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
