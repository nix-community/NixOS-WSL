{ runCommand
, makeWrapper
, lib
, coreutils
, daemonize
, glibc
, gnugrep
, systemd
, util-linux
, which
, defaultUser
, automountPath
, utils
, ...
}:
let
  mkWrappedScript =
    { name
    , src
    , path
    , ...
    } @ args:
    runCommand name ({ nativeBuildInputs = [ makeWrapper ]; } // args) ''
      install -Dm755 ${src} $out/bin/${name}
      patchShebangs $out/bin/${name}
      substituteAllInPlace $out/bin/${name}
      wrapProgram $out/bin/${name} --prefix PATH ':' ${lib.escapeShellArg path}
    '';
in
mkWrappedScript {
  name = "syschdemd";
  src = ./syschdemd.sh;
  path = lib.makeBinPath [
    "/run/wrappers" # mount
    coreutils
    daemonize
    glibc # getent
    gnugrep
    systemd # machinectl
    util-linux # nsenter, runuser
    which
    utils
  ];
  username = defaultUser.name;
  inherit automountPath;
}
