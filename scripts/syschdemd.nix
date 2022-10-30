{ runCommand
, makeWrapper
, lib
, coreutils
, daemonize
, glibc
, gnugrep
, systemd
, util-linux
, defaultUser
, automountPath
,
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

  wrapper = mkWrappedScript {
    name = "nixos-wsl-systemd-wrapper";
    src = ./wrapper.sh;
    path = lib.makeSearchPath "" [
      "/run/wrappers/bin" # mount
      "${systemd}/lib/systemd" # systemd
    ];
  };
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
    util-linux # nsenter
    wrapper
  ];
  username = defaultUser.name;
  uid = defaultUser.uid;
  inherit automountPath;
}
