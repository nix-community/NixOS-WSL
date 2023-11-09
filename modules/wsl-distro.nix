{ lib, pkgs, config, ... }:

with builtins; with lib;

let
  cfg = config.wsl;
in
{

  options.wsl = with types; {
    enable = mkEnableOption "support for running NixOS as a WSL distribution";
    binShPkg = mkOption {
      type = package;
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
    extraBin = mkOption {
      type = listOf (submodule ({ config, ... }: {
        options = {
          src = mkOption {
            type = str;
            description = "Path of the file that should be added";
          };
          name = mkOption {
            type = str;
            description = "The name the file should be created as in /bin";
            default = baseNameOf config.src;
          };
          copy = mkOption {
            type = bool;
            default = false;
            description = "Whether or not the file should be copied instead of symlinked";
          };
        };
      }));
      description = "Additional files to be added to /bin";
    };
    startMenuLaunchers = mkEnableOption "shortcuts for GUI applications in the windows start menu";
  };

  config = mkIf cfg.enable {
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
        ${concatStringsSep "\n" (map
          (entry:
            if entry.copy
            then "cp -f ${entry.src} /bin/${entry.name}"
            else "ln -sf ${entry.src} /bin/${entry.name}"
          )
          config.wsl.extraBin
        )}
      '');
    };

    # require people to use lib.mkForce to make it harder to brick their installation
    wsl = {
      populateBin = true;
      extraBin = [
        { src = "/init"; name = "wslpath"; }
        { src = "${cfg.binShPkg}/bin/sh"; name = "sh"; }
        { src = "${pkgs.util-linux}/bin/mount"; }
      ];
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
  };
}
