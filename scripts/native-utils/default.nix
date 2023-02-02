{ rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "nixos-wsl-utils";
  version = "1.0.0";

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
