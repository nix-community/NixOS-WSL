{ lib, pkgs, config, options, ... }:

with lib;

let
  nixos-enter' = config.system.build.nixos-enter.overrideAttrs (_: {
    runtimeShell = "/bin/bash";
  });

  recovery = pkgs.writeScriptBin "nixos-wsl-recovery" ''
    #! /bin/sh
    if [ -f /etc/NIXOS ]; then
      echo "nixos-wsl-recovery should only be run from the WSL system distribution."
      echo "Example:"
      echo "    wsl --system --distribution NixOS --user root -- /nix/var/nix/profiles/system/bin/nixos-wsl-recovery"
      exit 1
    fi
    mount -o remount,rw /mnt/wslg/distro
    exec /mnt/wslg/distro/${nixos-enter'}/bin/nixos-enter --root /mnt/wslg/distro "$@"
  '';

  cfg = config.wsl;
in
{

  options.wsl = with types; {
    enable = mkEnableOption "support for running NixOS as a WSL distribution";
    binShPkg = mkOption {
      type = lib.types.package;
      internal = true;
      description = "Package to be linked to /bin/sh. Mainly useful to be re-used by other modules like envfs.";
    };
    defaultUser = mkOption {
      type = str;
      default = "nixos";
      description = "The name of the default user";
    };
    populateBin = mkOption {
      type = bool;
      default = true;
      internal = true;
      description = ''
        Dangerous! Things might break. Use with caution!

        Do not populate /bin.

        This is mainfly useful if another module populates /bin like envfs.
      '';
    };
    startMenuLaunchers = mkEnableOption "shortcuts for GUI applications in the windows start menu";
  };

  config = mkIf cfg.enable (
    mkMerge [
      (lib.mkRemovedOptionModule ["wsl" "nativeSystemd"] "Native systemd support is the only supported startup method now.")
      (lib.mkRemovedOptionModule ["wsl" "docker-native"] "WSL-specific workarounds are no longer required for Docker.")
      {
        # WSL uses its own kernel and boot loader
        boot = {
          initrd.enable = false;
          kernel.enable = false;
          loader.grub.enable = false;
          modprobeConfig.enable = false;
        };
        system.build.installBootLoader = "${pkgs.coreutils}/bin/true";

        # WSL does not support virtual consoles
        console.enable = false;

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
        };

        nixpkgs.overlays = [
          (_: prev: {
            wslNativeUtils = prev.callPackage ../native-utils { };
          })
        ];

        # dhcp is handled by windows
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
                targets=()
                if [[ -d "$systemConfig/sw/share/$x" ]]; then
                  targets+=("$systemConfig/sw/share/$x/.")
                fi
                if [[ -d "/etc/profiles/per-user/${cfg.defaultUser}/share/$x" ]]; then
                  targets+=("/etc/profiles/per-user/${cfg.defaultUser}/share/$x/.")
                fi

                if (( ''${#targets[@]} != 0 )); then
                  mkdir -p "/usr/share/$x"
                  ${pkgs.rsync}/bin/rsync -ar --delete-after "''${targets[@]}" "/usr/share/$x"
                else
                  rm -rf "/usr/share/$x"
                fi
              done
            ''
          );
          populateBin = lib.mkIf cfg.populateBin (stringAfter [ ] ''
            echo "setting up /bin..."
            ln -sf /init /bin/wslpath
            ln -sf ${cfg.binShPkg}/bin/sh /bin/sh
            ln -sf ${pkgs.util-linux}/bin/mount /bin/mount

            # needs to be a copy, not a symlink, to be executable from outside
            cp -f ${recovery}/bin/nixos-wsl-recovery /bin/nixos-wsl-recovery
          '');
        };

        # useful for usbip but adds a dependency on various firmwares which are combined over 300 MB big
        services.udev.enable = lib.mkDefault false;

        systemd = {
          # Disable systemd units that don't make sense on WSL
          services = {
            firewall.enable = false;
            systemd-resolved.enable = lib.mkDefault false;
            # systemd-timesyncd actually works in WSL and without it the clock can drift
            systemd-timesyncd.unitConfig.ConditionVirtualization = "";
          };

          # Don't allow emergency mode, because we don't have a console.
          enableEmergencyMode = false;
        };

        # require people to use lib.mkForce to make it harder to brick their installation
        wsl = {
          binShPkg = pkgs.writeShellScriptBin "sh" ''
            export PATH="$PATH:${lib.makeBinPath [ pkgs.systemd pkgs.gnugrep ]}"
            exec ${pkgs.bashInteractive}/bin/sh "$@"
          '';
          populateBin = true;
          wslConf = {
            user.default = config.users.users.${cfg.defaultUser}.name;
            boot.systemd = true;
          };
        };

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

        system.activationScripts = {
          shimSystemd = stringAfter [ ] ''
            echo "setting up /sbin/init shim..."
            mkdir -p /sbin
            ln -sf ${pkgs.wslNativeUtils}/bin/systemd-shim /sbin/init
          '';
          setupLogin = lib.mkIf cfg.populateBin (stringAfter [ ] ''
            echo "setting up /bin/login..."
            mkdir -p /bin
            ln -sf ${pkgs.shadow}/bin/login /bin/login
          '');
        };

        environment = {
          # preserve $PATH from parent
          variables.PATH = [ "$PATH" ];
          extraInit = ''
            eval $(${pkgs.wslNativeUtils}/bin/split-path --automount-root="${cfg.wslConf.automount.root}" ${lib.optionalString cfg.interop.includePath "--include-interop"})
          '';
        };
      }

      # this option doesn't exist on older NixOS, so hack.
      (lib.optionalAttrs (builtins.hasAttr "oomd" options.systemd) {
        # systemd-oomd requires cgroup pressure info which WSL doesn't have
        systemd.oomd.enable = false;
      })
    ]
  );
}
