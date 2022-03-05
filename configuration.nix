{ lib, pkgs, config, modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ./module.nix
  ];

  wsl.enable = true;
}
