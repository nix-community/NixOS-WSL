{ lib, config, pkgs, ... }:
{
  options.wsl.vscodeRemoteWslExtensionWorkaround = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Workaround for VSCode's Remote WSL extension";
    };
    nix-ld-rs = lib.mkOption {
      type = lib.types.raw;
      description = "The flake input to use for `nix-ld-rs`";
    };
  };

  config =
    let
      cfg = config.wsl.vscodeRemoteWslExtensionWorkaround;
    in
    lib.mkIf cfg.enable {
      wsl.extraBin = [
        # Required by VS Code's Remote WSL extension
        { src = "${pkgs.coreutils}/bin/dirname"; }
        { src = "${pkgs.coreutils}/bin/readlink"; }
        { src = "${pkgs.coreutils}/bin/uname"; }
      ];
      programs.nix-ld = {
        enable = true;
        libraries = [
          # Required by NodeJS installed by VS Code's Remote WSL extension
          pkgs.stdenv.cc.cc
        ];

        # Use `nix-ld-rs` instead of `nix-ld`, because VS Code's Remote WSL extension launches a non-login non-interactive shell, which is not supported by `nix-ld`, while `nix-ld-rs` works in non-login non-interactive shells.
        package = cfg.nix-ld-rs.packages.${pkgs.system}.nix-ld-rs;
      };
    };
}
