{ runCommand
, cargo
, rustfmt
, ...
}:
runCommand "check-rustfmt" { nativeBuildInputs = [ cargo rustfmt ]; } ''
  cargo fmt --manifest-path=${./../scripts/native-utils}/Cargo.toml --check
  touch $out
''
