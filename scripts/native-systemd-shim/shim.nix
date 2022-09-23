{ rustPlatform }:
rustPlatform.buildRustPackage {
  name = "nixos-wsl-native-systemd-shim";
  version = "1.0.0";

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
