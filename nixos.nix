# Build with
#   nix-build -A system -A config.system.build.tarball ./nixos.nix

import <nixpkgs/nixos> {
  configuration = {
    imports = [
      ./configuration.nix
      ./build-tarball.nix
    ];
  };

  system = "x86_64-linux";
}
