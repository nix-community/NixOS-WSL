{ runCommand
, cargo
, rustfmt
, ...
}:
runCommand "check-rustfmt" { nativeBuildInputs = [ cargo rustfmt ]; } ''
  cargo fmt --manifest-path=${./../native-utils}/Cargo.toml --check
  touch $out
''
