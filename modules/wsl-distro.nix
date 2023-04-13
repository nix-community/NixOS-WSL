{ lib, pkgs, config, options, ... }:

with lib;

let
  bashWrapper = pkgs.writeShellScriptBin "sh" ''
    export PATH=/bin:${lib.makeBinPath [ pkgs.systemd pkgs.gnugrep ]}
    . ${config.system.build.etc}/etc/set-environment
    exec ${pkgs.bashInteractive}/bin/sh "$@"
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
            if [[ -d $systemConfig/sw/share/$x ]]; then
              mkdir -p /usr/share/$x
              ${pkgs.rsync}/bin/rsync -ar --delete $systemConfig/sw/share/$x/. /usr/share/$x
            else
              rm -rf /usr/share/$x
            fi
          done
        ''
      );
      populateBin = lib.mkIf cfg.populateBin (stringAfter [ ] ''
        echo "setting up /bin..."
        ln -sf /init /bin/wslpath
        ln -sf ${cfg.binShPkg}/bin/sh /bin/sh
        ln -sf ${pkgs.util-linux}/bin/mount /bin/mount
      '');
      update-entrypoint.text = ''
        mkdir -p /nix/nixos-wsl
        ln -sfn ${config.users.users.root.shell} /nix/nixos-wsl/entrypoint
      '';
    };

    # useful for usbip but adds a dependency on various firmwares which are combined over 300 MB big
    services.udev.enable = lib.mkDefault false;

    systemd = {
      # Disable systemd units that don't make sense on WSL
      services = {
        firewall.enable = false;
        systemd-resolved.enable = lib.mkDefault false;
        # system clock cannot be changed
        systemd-timesyncd.enable = false;
      };

      # Don't allow emergency mode, because we don't have a console.
      enableEmergencyMode = false;

      # Link the X11 socket into place. This is a no-op on a normal setup,
      # but helps if /tmp is a tmpfs or mounted from some other location.
      tmpfiles.rules = [ "L /tmp/.X11-unix - - - - ${cfg.wslConf.automount.root}/wslg/.X11-unix" ];
    };

    # Start a systemd user session when starting a command through runuser
    security.pam.services.runuser.startSession = true;

    # require people to use lib.mkForce to make it harder to brick their installation
    wsl = {
      binShPkg = if cfg.nativeSystemd then bashWrapper else pkgs.bashInteractive;
      populateBin = true;
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
