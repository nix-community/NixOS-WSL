{ runCommand
, shfmt
, ...
}:
runCommand "check-shfmt" { nativeBuildInputs = [ shfmt ]; } ''
  shfmt -i 2 -d $(find ${./..} -name '*.sh')
  touch $out
''
