{ runCommand
, nixpkgs-fmt
, ...
}:
runCommand "check-nixpkgs-fmt" { nativeBuildInputs = [ nixpkgs-fmt ]; } ''
  nixpkgs-fmt --check ${./..}
  touch $out
''
