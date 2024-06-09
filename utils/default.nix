{ rustPlatform, bash, coreutils }:
rustPlatform.buildRustPackage {
  pname = "nixos-wsl-utils";
  version = "1.0.0";

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  env = {
    NIXOS_WSL_SH = "${bash}/bin/sh";
    NIXOS_WSL_ENV = "${coreutils}/bin/env";
  };
}
