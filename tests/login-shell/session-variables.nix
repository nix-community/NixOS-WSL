{ config, pkgs, lib, ... }:
{
  imports = [
    ./base.nix
    "${builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-${config.system.nixos.version}.tar.gz"}/nixos"
  ];

  home-manager.users.nixos = { ... }: {
    home = {
      stateVersion = config.system.nixos.version;
      packages = [ pkgs.vim ];
      sessionVariables = {
        EDITOR = "vim";
        TEST_VARIABLE = "THISISATESTSTRING";
      };
    };
    programs.bash.enable = true;
  };
}
