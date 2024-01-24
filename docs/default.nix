{ stdenv
, lib
, path
, system
, runCommand
, mdbook
, gnused
, nixosOptionsDoc
}:

with lib;
let
  eval = import (path + "/nixos/lib/eval-config.nix") {
    inherit system;
    modules = [
      ../modules
    ];
  };
in
stdenv.mkDerivation rec {
  name = "nixos-wsl-docs";

  src = ../.;

  nativeBuildInputs = [ mdbook ];

  configurePhase = ''
    cd docs
    cp ${passthru.optionsMD} src/options.md
  '';

  buildPhase = ''
    mdbook build
  '';

  installPhase = ''
    mv book $out
  '';

  passthru = {
    optionsDoc = nixosOptionsDoc {
      options = eval.options.wsl;
    };
    optionsMD = runCommand "options.md" { } ''
      set -euo pipefail
      cat ${passthru.optionsDoc.optionsCommonMark} \
      | ${gnused}/bin/sed 's|\[${toString (../.)}|\[\&lt\;nixos-wsl\&gt\;|;s|file://${toString (../.)}|https://github.com/nix-community/NixOS-WSL/blob/main|' \
      > $out
    '';
  };
}
