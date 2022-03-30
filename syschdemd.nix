{ lib, pkgs, config, defaultUser, ... }:

pkgs.substituteAll {
  name = "syschdemd";
  src = ./syschdemd.sh;
  dir = "bin";
  isExecutable = true;

  buildInputs = with pkgs; [ daemonize ];

  inherit (pkgs) daemonize;
  inherit defaultUser;
  inherit (config.security) wrapperDir;
  fsPackagesPath = lib.makeBinPath config.system.fsPackages;

  systemdWrapper = pkgs.writeShellScript "systemd-wrapper.sh" ''
    mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc || true
    exec systemd
  '';
}
