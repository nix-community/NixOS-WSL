{ lib, pkgs, ... }:
with lib; {
  imports = [
    <nixos-wsl/modules>
  ];

  config = {
    wsl.enable = true;
    services.envfs.enable = true;

    environment.systemPackages = [
      pkgs.python3
    ];
  };
}
