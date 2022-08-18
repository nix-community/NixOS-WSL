{ lib
, pkgs
, config
, automountPath
, defaultUser
, defaultUserHome ? "/home/${defaultUser}"
, ...
}:

pkgs.substituteAll {
  name = "syschdemd";
  src = ./syschdemd.sh;
  dir = "bin";
  isExecutable = true;

  buildInputs = with pkgs; [ daemonize ];

  inherit defaultUser defaultUserHome;
  inherit (pkgs) daemonize;
  inherit (config.security) wrapperDir;
  fsPackagesPath = lib.makeBinPath config.system.fsPackages;

  systemdWrapper = pkgs.writeShellScript "systemd-wrapper.sh" ''
    mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc || true
    mount --make-rshared ${automountPath}
    exec systemd
  '';
}
