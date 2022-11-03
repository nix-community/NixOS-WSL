{ lib, pkgs, config, ... }:

with lib; {

  options.wsl = with types; {
    enable = mkEnableOption "support for running NixOS as a WSL distribution";
    nativeSystemd = mkOption {
      type = bool;
      default = false;
      description = "Use native WSL systemd support";
    };
    defaultUser = mkOption {
      type = str;
      default = "nixos";
      description = "The name of the default user";
    };
    startMenuLaunchers = mkEnableOption "shortcuts for GUI applications in the windows start menu";
  };

  config =
    let
      cfg = config.wsl;

      syschdemd = pkgs.callPackage ../scripts/syschdemd.nix {
        inherit (cfg) automountPath;
        defaultUser = config.users.users.${cfg.defaultUser};
      };

      shim = pkgs.callPackage ../scripts/native-systemd-shim/shim.nix { };

      bashWrapper = pkgs.runCommand "nixos-wsl-bash-wrapper" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        makeWrapper ${pkgs.bashInteractive}/bin/sh $out/bin/sh --prefix PATH ':' ${lib.makeBinPath [pkgs.systemd pkgs.gnugrep]}
      '';

      bash = if cfg.nativeSystemd then bashWrapper else pkgs.bashInteractive;
    in
    mkIf cfg.enable (
      mkMerge [
        {
          # We don't need a boot loader
          boot.loader.grub.enable = false;
          system.build.installBootLoader = "${pkgs.coreutils}/bin/true";
          boot.initrd.enable = false;
          system.build.initialRamdisk = pkgs.runCommand "fake-initrd" { } ''
            mkdir $out
            touch $out/${config.system.boot.loader.initrdFile}
          '';
          system.build.initialRamdiskSecretAppender = pkgs.writeShellScriptBin "append-initrd-secrets" "";

          hardware.opengl.enable = true; # Enable GPU acceleration

          environment = {

            etc = {
              # DNS settings are managed by WSL
              hosts.enable = !config.wsl.wslConf.network.generateHosts;
              "resolv.conf".enable = !config.wsl.wslConf.network.generateResolvConf;
            };

            systemPackages = [
              (pkgs.runCommand "wslpath" { } ''
                mkdir -p $out/bin
                ln -s /init $out/bin/wslpath
              '')
            ];
          };

          networking.dhcpcd.enable = false;

          users.users.${cfg.defaultUser} = {
            isNormalUser = true;
            uid = 1000;
            extraGroups = [ "wheel" ]; # Allow the default user to use sudo
          };

          # Otherwise WSL fails to login as root with "initgroups failed 5"
          users.users.root.extraGroups = [ "root" ];

          security.sudo.wheelNeedsPassword = mkDefault false; # The default user will not have a password by default

          system.activationScripts = {
            copy-launchers = mkIf cfg.startMenuLaunchers (
              stringAfter [ ] ''
                for x in applications icons; do
                  echo "Copying /usr/share/$x"
                  mkdir -p /usr/share/$x
                  ${pkgs.rsync}/bin/rsync -ar --delete $systemConfig/sw/share/$x/. /usr/share/$x
                done
              ''
            );
            populateBin = stringAfter [ ] ''
              echo "setting up /bin..."
              ln -sf /init /bin/wslpath
              ln -sf ${bash}/bin/sh /bin/sh
              ln -sf ${pkgs.util-linux}/bin/mount /bin/mount
            '';
          };

          systemd = {
            # Disable systemd units that don't make sense on WSL
            services = {
              "serial-getty@ttyS0".enable = false;
              "serial-getty@hvc0".enable = false;
              "getty@tty1".enable = false;
              "autovt@".enable = false;
              firewall.enable = false;
              systemd-resolved.enable = false;
              systemd-udevd.enable = false;
            };

            tmpfiles.rules = [
              # Don't remove the X11 socket
              "d /tmp/.X11-unix 1777 root root"
            ];

            # Don't allow emergency mode, because we don't have a console.
            enableEmergencyMode = false;
          };

          warnings = (optional (config.systemd.services.systemd-resolved.enable && config.wsl.wslConf.network.generateResolvConf)
            "systemd-resolved is enabled, but resolv.conf is managed by WSL"
          );
        }
        (mkIf (!cfg.nativeSystemd) {
          users.users.root.shell = "${syschdemd}/bin/syschdemd";
          security.sudo.extraConfig = ''
            Defaults env_keep+=INSIDE_NAMESPACE
          '';
          wsl.wslConf.user.default = "root";

          # Include Windows %PATH% in Linux $PATH.
          environment.extraInit = mkIf cfg.interop.includePath ''PATH="$PATH:$WSLPATH"'';
        })
        (mkIf cfg.nativeSystemd {
          wsl.wslConf = {
            user.default = cfg.defaultUser;
            boot.systemd = true;
          };

          system.activationScripts = {
            shimSystemd = stringAfter [ ] ''
              echo "setting up /sbin/init shim..."
              mkdir -p /sbin
              ln -sf ${shim}/bin/nixos-wsl-native-systemd-shim /sbin/init
            '';
          };

          environment = {
            # preserve $PATH from parent
            variables.PATH = [ "$PATH" ];
            extraInit = ''
              export WSLPATH=$(echo "$PATH" | tr ':' '\n' | grep -E "^${cfg.automountPath}" | tr '\n' ':')
              ${if cfg.interop.includePath then "" else ''
                export PATH=$(echo "$PATH" | tr ':' '\n' | grep -vE "^${cfg.automountPath}" | tr '\n' ':')
              ''}
            '';
          };
        })
      ]);
}
