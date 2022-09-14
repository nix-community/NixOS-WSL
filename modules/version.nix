{ lib, pkgs, config, ... }:
with builtins; with lib;
{

  options = with types; {
    wsl.version = mkOption {
      type = str;
      default =
        let
          env = getEnv "NIXOS_WSL_VERSION";
        in
        if env != null && env != "" then env else "DEV_BUILD";
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
