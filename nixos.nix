# Build with
#   nix-build -A system -A config.system.build.tarball ./nixos.nix

import <nixpkgs/nixos> {
  configuration = import ./configuration.nix;

  system = "x86_64-linux";
}
