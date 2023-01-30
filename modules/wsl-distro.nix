{ lib, pkgs, config, options, ... }:

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
        automountPath = cfg.wslConf.automount.root;
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

            # Only set the options if the files are managed by WSL
            etc = mkMerge [
              (mkIf config.wsl.wslConf.network.generateHosts {
                hosts.enable = false;
              })
              (mkIf config.wsl.wslConf.network.generateResolvConf {
                "resolv.conf".enable = false;
              })
            ];

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

          powerManagement.enable = false;

          security.sudo.wheelNeedsPassword = mkDefault false; # The default user will not have a password by default

          system.activationScripts = {
            copy-launchers = mkIf cfg.startMenuLaunchers (
              stringAfter [ ] ''
                for x in applications icons; do
                  echo "setting up /usr/share/''${x}..."
                  if [[ -d $systemConfig/sw/share/$x ]]; then
                    mkdir -p /usr/share/$x
                    ${pkgs.rsync}/bin/rsync -ar --delete $systemConfig/sw/share/$x/. /usr/share/$x
                  else
                    rm -rf /usr/share/$x
                  fi
                done
              ''
            );
            populateBin = stringAfter [ ] ''
              echo "setting up /bin..."
              ln -sf /init /bin/wslpath
              ln -sf ${bash}/bin/sh /bin/sh
              ln -sf ${pkgs.util-linux}/bin/mount /bin/mount
            '';
            update-entrypoint.text = ''
              mkdir -p /nix/nixos-wsl
              rm -f /nix/nixos-wsl/entrypoint
              ln -sf ${config.users.users.root.shell} /nix/nixos-wsl/entrypoint
            '';
          };

          systemd = {
            # Disable systemd units that don't make sense on WSL
            services = {
              # no virtual console to switch to
              "serial-getty@ttyS0".enable = false;
              "serial-getty@hvc0".enable = false;
              "getty@tty1".enable = false;
              "autovt@".enable = false;
              firewall.enable = false;
              systemd-resolved.enable = false;
              # system clock cannot be changed
              systemd-timesyncd.enable = false;
              # no udev devices can be attached
              systemd-udevd.enable = false;
            };

            # Don't allow emergency mode, because we don't have a console.
            enableEmergencyMode = false;

            # Link the X11 socket into place. This is a no-op on a normal setup,
            # but helps if /tmp is a tmpfs or mounted from some other location.
            tmpfiles.rules = [ "L /tmp/.X11-unix - - - - ${cfg.wslConf.automount.root}/wslg/.X11-unix" ];
          };

          # Start a systemd user session when starting a command through runuser
          security.pam.services.runuser.startSession = true;

          warnings = flatten [
            (optional (config.services.resolved.enable && config.wsl.wslConf.network.generateResolvConf)
              "systemd-resolved is enabled, but resolv.conf is managed by WSL (wsl.wslConf.network.generateResolvConf)"
            )
            (optional ((length config.networking.nameservers) > 0 && config.wsl.wslConf.network.generateResolvConf)
              "custom nameservers are set (networking.nameservers), but resolv.conf is managed by WSL (wsl.wslConf.network.generateResolvConf)"
            )
            (optional ((length config.networking.nameservers) == 0 && !config.services.resolved.enable && !config.wsl.wslConf.network.generateResolvConf)
              "resolv.conf generation is turned off (wsl.wslConf.network.generateResolvConf), but no other nameservers are configured (networking.nameservers)"
            )
          ];
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
            user.default = config.users.users.${cfg.defaultUser}.name;
            boot.systemd = true;
          };

          system.activationScripts = {
            shimSystemd = stringAfter [ ] ''
              echo "setting up /sbin/init shim..."
              mkdir -p /sbin
              ln -sf ${shim}/bin/nixos-wsl-native-systemd-shim /sbin/init
            '';
            setupLogin = stringAfter [ ] ''
              echo "setting up /bin/login..."
              mkdir -p /bin
              ln -sf ${pkgs.shadow}/bin/login /bin/login
            '';
          };

          environment = {
            # preserve $PATH from parent
            variables.PATH = [ "$PATH" ];
            extraInit = ''
              export WSLPATH=$(echo "$PATH" | tr ':' '\0' | command grep -a "^${cfg.wslConf.automount.root}" | tr '\0' ':')
              ${if cfg.interop.includePath then "" else ''
                export PATH=$(echo "$PATH" | tr ':' '\0' | command grep -av "^${cfg.wslConf.automount.root}" | tr '\0' ':')
              ''}
            '';
          };
        })
        # this option doesn't exist on older NixOS, so hack.
        (lib.optionalAttrs (builtins.hasAttr "oomd" options.systemd) {
          # systemd-oomd requires cgroup pressure info which WSL doesn't have
          systemd.oomd.enable = false;
        })
      ]);
}
