{ pkgs, lib, ... }:
let
  ver = with lib; substring 0 5 version;
  hmBranch =
    let
      # Use the nix parser conveniently built into nix
      flake = import <nixos-wsl/flake.nix>;
      url = flake.inputs.nixpkgs.url;
      version = lib.removePrefix "github:NixOS/nixpkgs/nixos-" url;
    in
    if version == "unstable"
    then "master"
    else "release-" + version;
in
{
  imports = [
    <nixos-wsl/modules>
    "${builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/${hmBranch}.tar.gz"}/nixos"
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
