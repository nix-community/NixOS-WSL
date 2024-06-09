{ config, lib, utils, pkgs, modulesPath, ... }:

with lib;

let
  cfg = config.wsl;

  users-groups-module = import "${modulesPath}/config/users-groups.nix" {
    inherit lib utils pkgs;
    config = recursiveUpdate config {
      users.users = mapAttrs
        (n: v: v // {
          shell =
            let
              shellPath = utils.toShellPath v.shell;
              wrapper = pkgs.stdenvNoCC.mkDerivation {
                name = "wrapped-${last (splitString "/" (shellPath))}";
                buildCommand = ''
                  mkdir -p $out
                  cp ${config.system.build.nativeUtils}/bin/shell-wrapper $out/wrapper
                  ln -s ${shellPath} $out/shell
                '';
              };
            in
            wrapper.outPath + "/wrapper";
        })
        config.users.users;
    };
  };
in
{
  config = mkIf (cfg.enable && cfg.nativeSystemd) {
    system.activationScripts.users = users-groups-module.config.system.activationScripts.users;
  };
}
