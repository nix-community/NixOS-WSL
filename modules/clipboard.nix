{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.wsl.clipboard;
in
{
  options.wsl.clipboard = {
    enable = lib.mkEnableOption "wl-copy/wl-paste integration via Windows clipboard";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../packages/wl-clipboard-wsl { };
      description = "Package providing wl-copy and wl-paste wrappers for WSL clipboard interop.";
    };
  };

  config = lib.mkIf (config.wsl.enable && cfg.enable) {
    environment.systemPackages = [ cfg.package ];
  };
}
