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
    docker-desktop
    wsl-distro
  ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "nixos";
    startMenuLaunchers = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker.enable = true;
  };

  # Enable nix-flakes by default
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
