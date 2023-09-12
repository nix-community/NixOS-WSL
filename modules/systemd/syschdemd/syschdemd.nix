{ runCommand
, makeWrapper
, lib
, coreutils
, daemonize
, getent
, gnugrep
, systemd
, util-linux
, which
, defaultUser
, automountPath
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

  wrapper = mkWrappedScript {
    name = "nixos-wsl-systemd-wrapper";
    src = ./wrapper.sh;
    path = lib.makeSearchPath "" [
      "/run/wrappers/bin" # mount
      "${gnugrep}/bin" # grep
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
    getent
    gnugrep
    systemd # machinectl
    util-linux # nsenter, runuser
    which
    wrapper
  ];
  username = defaultUser.name;
  inherit automountPath;
}
