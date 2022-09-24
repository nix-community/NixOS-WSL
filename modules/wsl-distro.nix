{ lib, pkgs, config, ... }:

with builtins; with lib;
{
  options.wsl = with types;
    let
      coercedToStr = coercedTo (oneOf [ bool path int ]) (toString) str;
    in
    {
      enable = mkEnableOption "support for running NixOS as a WSL distribution";
      automountPath = mkOption {
        type = str;
        default = "/mnt";
        description = "The path where windows drives are mounted (e.g. /mnt/c)";
      };
      automountOptions = mkOption {
        type = str;
        default = "metadata,uid=1000,gid=100";
        description = "Options to use when mounting windows drives";
      };
      defaultUser = mkOption {
        type = str;
        default = "nixos";
        description = "The name of the default user";
      };
      startMenuLaunchers = mkEnableOption "shortcuts for GUI applications in the windows start menu";
      wslConf = mkOption {
        type = attrsOf (attrsOf (oneOf [ string int bool ]));
        description = "Entries that are added to /etc/wsl.conf";
      };
    };

  config =
    let
      cfg = config.wsl;
      syschdemd = pkgs.callPackage ../scripts/syschdemd.nix { inherit (cfg) automountPath defaultUser; };
    in
    mkIf cfg.enable {

      wsl.wslConf = {
        automount = {
          enabled = true;
          mountFsTab = true;
          root = "${cfg.automountPath}/";
          options = cfg.automountOptions;
        };
        boot = {
          systemd = true;
          command = "/bin/sh -c 'mount --bind -o ro /nix/store /nix/store; export LANG=\"C.UTF-8\"; /nix/var/nix/profiles/system/activate;'";
        };
        network = {
          hostname = config.networking.hostName;
          generateResolvConf = mkDefault true;
          generateHosts = mkDefault true;
        };
        user.default = cfg.defaultUser;
      };

      # WSL is closer to a container than anything else
      boot.isContainer = true;

      environment.noXlibs = lib.mkForce false; # override xlibs not being installed (due to isContainer) to enable the use of GUI apps
      hardware.opengl.enable = true; # Enable GPU acceleration

      environment.etc = {
        "wsl.conf".text = generators.toINI { } cfg.wslConf;

        # Hostname gets overwritten by WSL and thus modify Nix derivations
        hostname.enable = false;

        # DNS settings are managed by WSL
        hosts.enable = !config.wsl.wslConf.network.generateHosts;
        "resolv.conf".enable = !config.wsl.wslConf.network.generateResolvConf;
      };

      networking.dhcpcd.enable = false;

      users.users.${cfg.defaultUser} = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "wheel" ]; # Allow the default user to use sudo
      };

      # Otherwise WSL fails to login as root with "initgroups failed 5"
      users.users.root.extraGroups = [ "root" ];

      # The default user will not have a password by default
      security.sudo.wheelNeedsPassword = mkDefault false; 

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
        populateWslEnvironment = stringAfter [ ] ''
          echo "synchronizing /bin..."
          ln -sf /init /bin/wslpath
          ln -sf ${pkgs.bashInteractive}/bin/bash /bin/sh
          ln -sf ${pkgs.util-linux}/bin/mount /bin/mount

          echo "synchronizing /lib/systemd/systemd..."
          mkdir -p /lib/systemd
          ln -sf ${pkgs.systemd}/lib/systemd/systemd /lib/systemd/systemd
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

      warnings = (optional (config.systemd.services.systemd-resolved.enable && config.wsl.wslConf.network.generateResolvConf) "systemd-resolved is enabled, but resolv.conf is managed by WSL");
    };
}
