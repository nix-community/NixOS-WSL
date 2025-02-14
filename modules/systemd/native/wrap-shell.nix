{ config, lib, utils, pkgs, modulesPath, ... }:

with lib;

let
  cfg = config.wsl;

  wrapShell = shellPath:
    pkgs.stdenvNoCC.mkDerivation {
      name = "wrapped-${last (splitString "/" (shellPath))}";
      buildCommand = ''
        mkdir -p $out
        cp ${config.system.build.nativeUtils}/bin/shell-wrapper $out/wrapper
        ln -s ${shellPath} $out/shell
      '';
    };

  users-groups-module = import "${modulesPath}/config/users-groups.nix" {
    inherit lib utils pkgs;
    config = recursiveUpdate config {
      users.users = mapAttrs
        (n: v: v // {
          shell = (wrapShell (utils.toShellPath v.shell)).outPath + "/wrapper";
        })
        config.users.users;
    };
  };
in
{
  options.wsl.wrapBinSh = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Wrap /bin/sh with a script that sets the correct environment variables (like the user shells). Only takes effect when using native systemd
    '';
  };

  config = mkIf (cfg.enable) {
    system.activationScripts.users = users-groups-module.config.system.activationScripts.users;

    wsl.binShExe = mkIf config.wsl.wrapBinSh ((wrapShell "${config.wsl.binShPkg}/bin/sh").outPath + "/wrapper");
  };
}
