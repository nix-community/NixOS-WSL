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

      warnings = [
        ''
          The old method of running systemd in a container (syschdemd) is deprecated.
          Legacy WSL support is untested and is scheduled to be removed entirely with the 24.11 release.
          Please migrate to native systemd by removing `wsl.nativeSystemd = false;` from your configuration.
        ''
      ];

    };

}
