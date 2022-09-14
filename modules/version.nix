{ lib, pkgs, config, ... }:
with builtins; with lib;
{

  options = with types; {
    wsl.version = mkOption {
      type = str;
      default = removeSuffix "\n" (readFile ../VERSION);
    };
  };

  config = mkIf config.wsl.enable {

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "nixos-wsl-version" ''
        echo ${config.wsl.version}
      '')
    ];

  };

}
