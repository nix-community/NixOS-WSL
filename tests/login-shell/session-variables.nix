{ pkgs, lib, ... }:
{
  imports = [
    ./base.nix
    "${builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz"}/nixos"
  ];

  home-manager.users.nixos = { ... }: {
    home = {
      stateVersion = "22.11";
      packages = [ pkgs.vim ];
      sessionVariables = {
        EDITOR = "vim";
        TEST_VARIABLE = "THISISATESTSTRING";
      };
    };
    programs.bash.enable = true;
  };
}
