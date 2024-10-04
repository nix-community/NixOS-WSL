{ pkgs, lib, config, ... }:

with lib; {
  imports = [
    (mkRenamedOptionModule [ "wsl" "automountPath" ] [ "wsl" "wslConf" "automount" "root" ])
    (mkRenamedOptionModule [ "wsl" "automountOptions" ] [ "wsl" "wslConf" "automount" "options" ])
  ];

  options.wsl.wslConf =
    let
      settingsFormat = pkgs.formats.ini { };
    in
    mkOption {
      description = ''
        Configuration values for /etc/wsl.conf.
        See <https://learn.microsoft.com/en-us/windows/wsl/wsl-config#configuration-settings-for-wslconf> for all options supported by WSL.
      '';

      default = { };

      type = types.submodule {
        freeformType = settingsFormat.type;

        options = {
          automount = {
            enabled = mkOption {
              type = types.bool;
              default = true;
              description = "Automatically mount windows drives under ${config.wsl.wslConf.automount.root}";
            };
            ldconfig = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Wether to modify `/etc/ld.so.conf.d/ld.wsl.conf` to load OpenGL drivers provided by the Windows host in `/usr/lib/wsl/lib` with `/sbin/ldconfig`.
                This way of providing OpenGL drivers does not work with NixOS and `wsl.useWindowsDriver` should be used instead.
              '';
            };
            mountFsTab = mkOption {
              type = types.bool;
              default = false;
              description = "Mount entries from /etc/fstab through WSL. You should probably leave this on false, because systemd will mount those for you.";
            };
            root = mkOption {
              type = types.strMatching "^/.*[^/]$";
              default = "/mnt";
              description = "The directory under which to mount windows drives.";
            };
            options = mkOption {
              type = types.commas; # comma-separated strings
              default = "metadata,uid=1000,gid=100";
              description = "Comma-separated list of mount options that should be used for mounting windows drives.";
            };
          };
          boot = {
            command = mkOption {
              type = types.str;
              default = "";
              description = "A command to run when the distro is started.";
            };
            systemd = mkOption {
              type = types.bool;
              default = false;
              description = "Use systemd as init. There's no need to enable this manually, use the wsl.nativeSystemd option instead";
            };
          };
          interop = {
            enabled = mkOption {
              type = types.bool;
              default = true;
              description = "Support running Windows binaries from the linux shell.";
            };
            appendWindowsPath = mkOption {
              type = types.bool;
              default = true;
              description = "Include the Windows PATH in the PATH variable";
            };
          };
          network = {
            generateHosts = mkOption {
              type = types.bool;
              default = true;
              description = "Generate /etc/hosts through WSL";
            };
            generateResolvConf = mkOption {
              type = types.bool;
              default = true;
              description = "Generate /etc/resolv.conf through WSL";
            };
            hostname = mkOption {
              type = types.str;
              default = config.networking.hostName;
              defaultText = "config.networking.hostName";
              description = "The hostname of the WSL instance";
            };
          };
          user = {
            default = mkOption {
              type = types.str;
              default = "root";
              description = "Which user to start commands in this WSL distro as";
            };
          };
        };
      };
    };

  config = mkIf config.wsl.enable {

    environment.etc."wsl.conf".text = generators.toINI { } config.wsl.wslConf;

    warnings = optional (config.wsl.wslConf.boot.systemd && !config.wsl.nativeSystemd)
      "systemd is enabled in wsl.conf, but wsl.nativeSystemd is not enabled. Unless you did this on purpose, this WILL make your system UNBOOTABLE!"
    ++ optional (config.wsl.wslConf.network.generateHosts && config.networking.extraHosts != "")
      "networking.extraHosts has no effect if wsl.wslConf.network.generateHosts is true.";

  };

}
