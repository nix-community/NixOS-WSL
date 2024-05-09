{ pkgs, lib, ... }:
let
  ver = with lib; substring 0 5 version;
in
{
  imports = [
    <nixos-wsl/modules>
    "${builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-${ver}.tar.gz"}/nixos"
  ];

  wsl.enable = true;

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
