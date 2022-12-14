{ runCommand
, shfmt
, ...
}:
runCommand "check-shfmt" { nativeBuildInputs = [ shfmt ]; } ''
  shfmt -i 2 -d ${./../scripts}/*.sh
  touch $out
''
