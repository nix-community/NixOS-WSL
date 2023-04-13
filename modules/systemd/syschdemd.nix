{ config, lib, pkgs, ... }:
with lib; {

  config =
    let
      cfg = config.wsl;

      syschdemd = pkgs.callPackage ../../scripts/syschdemd.nix {
        automountPath = cfg.wslConf.automount.root;
        defaultUser = config.users.users.${cfg.defaultUser};
      };
    in
    mkIf (cfg.enable && (!cfg.nativeSystemd)) {

      users.users.root.shell = "${syschdemd}/bin/syschdemd";
      security.sudo.extraConfig = ''
        Defaults env_keep+=INSIDE_NAMESPACE
      '';
      wsl.wslConf.user.default = "root";

      # Include Windows %PATH% in Linux $PATH.
      environment.extraInit = mkIf cfg.interop.includePath ''PATH="$PATH:$WSLPATH"'';

    };

}
