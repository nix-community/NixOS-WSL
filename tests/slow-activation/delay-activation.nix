{ pkgs, lib, ... }:

{
  imports = [
    <nixos-wsl/modules>
  ];

  wsl.enable = true;

  system.activationScripts."00-delay" = ''
    echo "Delaying activation for 15 seconds..."
    sleep 15s
  '';
}
