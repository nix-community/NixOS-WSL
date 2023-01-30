{ pkgs, lib, ... }:
{
  imports = [ ./base.nix ];

  wsl.defaultUser = lib.mkForce "different-name";
}
