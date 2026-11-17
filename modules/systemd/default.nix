{ config, lib, ... }:

{
  imports = [
    ./native

    (lib.mkRemovedOptionModule [ "wsl" "nativeSystemd" ] "Native systemd is now always enabled as support for syschdemd has been removed")
  ];

  config = lib.mkIf config.wsl.enable {
    # useful for usbip but adds a dependency on various firmwares which are combined over 300 MB big
    services.udev.enable = lib.mkDefault false;

    systemd = {
      # systemd-oomd requires cgroup pressure info (PSI). Older WSL2 kernels
      # lacked CONFIG_PSI, but modern kernels (6.1+) support it.
      oomd.enable = lib.mkDefault false;
      # Disable systemd units that don't make sense on WSL
      services.firewall.enable = false;

      # Don't allow emergency mode, because we don't have a console.
      enableEmergencyMode = false;
    };

    # Newer WSL kernels protect WSL interop by bind-mounting a read-only
    # file over /proc/sys/fs/binfmt_misc/status (microsoft/WSL#40621,
    # fixing microsoft/WSL#41226). systemd-binfmt's startup flush of
    # /status (the "-1" write) then fails with EROFS; systemd-binfmt logs
    # it as "ignoring" and still applies the registrations, but exits with
    # status 1 — which makes `nixos-rebuild switch` report the unit as
    # failed and abort the activation (seen as exit status 4 in #1109).
    #
    # The surgical fix is to invoke systemd-binfmt with the NixOS binfmt
    # configuration file as an argument instead of with no arguments.
    # Upstream systemd skips the /status flush entirely in that mode and
    # applies each rule by name (delete + re-register, both of which work
    # on the WSL-locked kernel); the exit code then reflects registration
    # honestly. This keeps the WSL cross-distro interop protection fully
    # intact (unlike `wsl.wslConf.boot.protectBinfmt = false`), registers
    # the rules instead of ignoring the error (unlike SuccessExitStatus),
    # and masks no real failure.
    #
    # The empty ExecStart= line is required to reset the upstream command
    # list before adding ours (see systemd.service(5)); the drop-in only
    # exists when boot.binfmt.registrations is non-empty (the only case in
    # which the upstream unit is enabled at all), so configurations
    # without registrations are unaffected.
    systemd.services.systemd-binfmt = lib.mkIf (config.boot.binfmt.registrations != { }) {
      serviceConfig.ExecStart = [
        ""
        "${config.systemd.package}/lib/systemd/systemd-binfmt /etc/binfmt.d/nixos.conf"
      ];
    };
  };
}
