{ lib, ... }: {
  # Copied from https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/24.05-compat.nix

  # Backward-compat for 24.05, can be removed after we drop 24.05 support
  imports = lib.optionals (lib.versionOlder lib.version "24.11pre") [
    (lib.mkAliasOptionModule [ "hardware" "graphics" "enable" ] [ "hardware" "opengl" "enable" ])
    (lib.mkAliasOptionModule [ "hardware" "graphics" "extraPackages" ] [ "hardware" "opengl" "extraPackages" ])
  ];
}
