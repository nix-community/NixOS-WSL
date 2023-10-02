{ lib, pkgs, config, ... }:
let
  welcomeMessage = pkgs.writeText "nixos-wsl-welcome-message" ''
    Welcome to your new NixOS-WSL system!

    Please run `sudo nix-channel --update` and `sudo nixos-rebuild switch` now, to ensure you're running the latest NixOS and NixOS-WSL versions.

    If you run into issues, please report them on our Github page at https://github.com/nix-community/NixOS-WSL or come talk to us on Matrix at #wsl:nixos.org.

    ❄️ Enjoy NixOS-WSL! ❄️

    Note: this message will disappear after you rebuild your system. If you want to see it again, run `nixos-wsl-welcome`.
  '';
  welcome = pkgs.writeShellScriptBin "nixos-wsl-welcome" ''
    cat ${welcomeMessage}
  '';
in
{
  config = lib.mkIf config.wsl.enable {
    environment.systemPackages = [ welcome ];
  };
}
