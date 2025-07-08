{ runCommand
, gnugrep
, ...
}:
runCommand "check-nixpkgs-input" { } ''
  ${gnugrep}/bin/grep -E 'nixpkgs.url *= *"github:NixOS/nixpkgs/nixos-(unstable|[0-9]+.[0-9]+)";' ${./../flake.nix}
  touch $out
''
