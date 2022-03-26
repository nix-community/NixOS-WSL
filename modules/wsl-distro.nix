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
        type = attrsOf (attrsOf coercedToStr);
        description = "Entries that are added to /etc/wsl.conf";
      };

      interop = {
        register = mkOption {
          type = bool;
          default = true;
          description = "Explicitly register the binfmt_misc handler for Windows executables";
        };

        includePath = mkOption {
          type = bool;
          default = true;
          description = "Include Windows PATH in WSL PATH";
        };
      };
    };

  config =
    let
      cfg = config.wsl;
      syschdemd = import ../syschdemd.nix { inherit lib pkgs config; defaultUser = cfg.defaultUser; };
    in
    mkIf cfg.enable {

      wsl.wslConf = {
        automount = {
          enabled = true;
          mountFsTab = true;
          root = "${cfg.automountPath}/";
          options = cfg.automountOptions;
        };
      };

      # WSL is closer to a container than anything else
      boot = {
        isContainer = true;

        binfmt.registrations = mkIf cfg.interop.register {
          WSLInterop = {
            magicOrExtension = "MZ";
            interpreter = "/init";
            fixBinary = true;
          };
        };
      };
      environment.noXlibs = lib.mkForce false; # override xlibs not being installed (due to isContainer) to enable the use of GUI apps

      environment = {
        # Include Windows %PATH% in Linux $PATH.
        extraInit = mkIf cfg.interop.includePath ''PATH="$PATH:$WSLPATH"'';

        etc = {
          "wsl.conf".text = generators.toINI { } cfg.wslConf;

          # DNS settings are managed by WSL
          hosts.enable = false;
          "resolv.conf".enable = false;
        };
      };

      networking.dhcpcd.enable = false;

      users.users.${cfg.defaultUser} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # Allow the default user to use sudo
      };

      users.users.root = {
        shell = "${syschdemd}/bin/syschdemd";
        # Otherwise WSL fails to login as root with "initgroups failed 5"
        extraGroups = [ "root" ];
      };

      security.sudo = {
        extraConfig = ''
          Defaults env_keep+=INSIDE_NAMESPACE
        '';
        wheelNeedsPassword = mkDefault false; # The default user will not have a password by default
      };

      system.activationScripts.copy-launchers = mkIf cfg.startMenuLaunchers (
        stringAfter [ ] ''
          for x in applications icons; do
            echo "Copying /usr/share/$x"
            mkdir -p /usr/share/$x
            ${pkgs.rsync}/bin/rsync -ar --delete $systemConfig/sw/share/$x/. /usr/share/$x
          done
        ''
      );

      # Disable systemd units that don't make sense on WSL
      systemd.services."serial-getty@ttyS0".enable = false;
      systemd.services."serial-getty@hvc0".enable = false;
      systemd.services."getty@tty1".enable = false;
      systemd.services."autovt@".enable = false;

      systemd.services.firewall.enable = false;
      systemd.services.systemd-resolved.enable = false;
      systemd.services.systemd-udevd.enable = false;

      # Don't allow emergency mode, because we don't have a console.
      systemd.enableEmergencyMode = false;
    };
}
