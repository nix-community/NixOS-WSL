{ config, pkgs, lib, ... }:
let
  ver = with lib; substring 0 5 version;
in
{
  imports = [
    ./base.nix
    "${builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-${ver}.tar.gz"}/nixos"
  ];

  home-manager.users.nixos = { ... }: {
    home = {
      stateVersion = ver;
      packages = [ pkgs.vim ];
      sessionVariables = {
        EDITOR = "vim";
        TEST_VARIABLE = "THISISATESTSTRING";
      };
    };
    programs.bash.enable = true;
  };
}
