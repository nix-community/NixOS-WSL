{ runCommand
, cargo
, rustfmt
, ...
}:
runCommand "check-rustfmt" { nativeBuildInputs = [ cargo rustfmt ]; } ''
  cargo fmt --manifest-path=${./../utils}/Cargo.toml --check
  touch $out
''
