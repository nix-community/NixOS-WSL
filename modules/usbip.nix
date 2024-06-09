{ config, lib, pkgs, ... }:

let
  usbipd-win-auto-attach = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dorssel/usbipd-win/v3.1.0/Usbipd/wsl-scripts/auto-attach.sh";
    hash = "sha256-KJ0tEuY+hDJbBQtJj8nSNk17FHqdpDWTpy9/DLqUFaM=";
  };

  cfg = config.wsl.usbip;
in
{
  options.wsl.usbip = {
    enable = lib.mkEnableOption "USB/IP integration";

    autoAttach = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [ "4-1" ];
      description = "Auto attach devices with provided Bus IDs.";
    };

    snippetIpAddress = lib.mkOption {
      type = lib.types.str;
      default = "$(ip route list | sed -nE 's/(default)? via (.*) dev eth0 proto kernel/\2/p')";
      example = "127.0.0.1";
      description = ''
        This snippet is used to obtain the address of the Windows host where Usbipd is running.
        It can also be a plain IP address in case networkingMode=mirrored or wsl-vpnkit is used.
      '';
    };
  };

  config = lib.mkIf (config.wsl.enable && cfg.enable) {
    environment.systemPackages = [
      pkgs.linuxPackages.usbip
    ];

    services.udev.enable = true;

    systemd = {
      services."usbip-auto-attach@" = {
        description = "Auto attach device having busid %i with usbip";
        after = [ "network.target" ];

        scriptArgs = "%i";
        path = with pkgs; [
          iproute2
          linuxPackages.usbip
        ];

        script = ''
          busid="$1"
          ip="${cfg.snippetIpAddress}"

          echo "Starting auto attach for busid $busid on $ip."
          source ${usbipd-win-auto-attach} "$ip" "$busid"
        '';
      };

      targets.multi-user.wants = map (busid: "usbip-auto-attach@${busid}.service") cfg.autoAttach;
    };
  };
}
