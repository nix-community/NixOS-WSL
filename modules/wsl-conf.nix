{ lib, config, ... }:

with lib; {
  imports = [
    (mkRenamedOptionModule [ "wsl" "automountPath" ] [ "wsl" "wslConf" "automount" "root" ])
    (mkRenamedOptionModule [ "wsl" "automountOptions" ] [ "wsl" "wslConf" "automount" "options" ])
  ];

  # See https://learn.microsoft.com/en-us/windows/wsl/wsl-config#configuration-settings-for-wslconf for all options
  options.wsl.wslConf = with types; {
    automount = {
      enabled = mkOption {
        type = bool;
        default = true;
        description = "Automatically mount windows drives under ${config.wsl.wslConf.automount.root}";
      };
      mountFsTab = mkOption {
        type = bool;
        default = false;
        description = "Mount entries from /etc/fstab through WSL. You should probably leave this on false, because systemd will mount those for you.";
      };
      root = mkOption {
        type = strMatching "^/.*[^/]$";
        default = "/mnt";
        description = "The directory under which to mount windows drives.";
      };
      options = mkOption {
        type = commas; # comma-separated strings
        default = "metadata,uid=1000,gid=100";
        description = "Comma-separated list of mount options that should be used for mounting windows drives.";
      };
    };
    boot = {
      command = mkOption {
        type = str;
        default = "";
        description = "A command to run when the distro is started.";
      };
      systemd = mkOption {
        type = bool;
        default = false;
        description = "Use systemd as init. There's no need to enable this manually, use the wsl.nativeSystemd option instead";
      };
    };
    interop = {
      enabled = mkOption {
        type = bool;
        default = true;
        description = "Support running Windows binaries from the linux shell.";
      };
      appendWindowsPath = mkOption {
        type = bool;
        default = true;
        description = "Include the Windows PATH in the PATH variable";
      };
    };
    network = {
      generateHosts = mkOption {
        type = bool;
        default = true;
        description = "Generate /etc/hosts through WSL";
      };
      generateResolvConf = mkOption {
        type = bool;
        default = true;
        description = "Generate /etc/resolv.conf through WSL";
      };
      hostname = mkOption {
        type = str;
        default = config.networking.hostName;
        defaultText = "config.networking.hostName";
        description = "The hostname of the WSL instance";
      };
    };
    user = {
      default = mkOption {
        type = str;
        default = "root";
        description = "Which user to start commands in this WSL distro as";
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
