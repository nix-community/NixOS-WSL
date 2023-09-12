{ config, pkgs, lib, ... }:
with lib; {

  options = { };

  config =
    let
      cfg = config.wsl;

      syschdemd = pkgs.callPackage ./syschdemd.nix {
        automountPath = cfg.wslConf.automount.root;
        defaultUser = config.users.users.${cfg.defaultUser};
      };
    in
    mkIf (cfg.enable && !cfg.nativeSystemd) {

      wsl = {
        binShPkg = pkgs.bashInteractive;
        wslConf.user.default = "root";
      };

      users.users.root.shell = "${syschdemd}/bin/syschdemd";
      security.sudo.extraConfig = ''
        Defaults env_keep+=INSIDE_NAMESPACE
      '';

      # Start a systemd user session when starting a command through runuser
      security.pam.services.runuser.startSession = true;

      # Include Windows %PATH% in Linux $PATH.
      environment.extraInit = mkIf cfg.interop.includePath ''PATH="$PATH:$WSLPATH"'';
      environment.systemPackages = [
        (pkgs.runCommand "wslpath" { } ''
          mkdir -p $out/bin
          ln -s /init $out/bin/wslpath
        '')
      ];

    };

}
