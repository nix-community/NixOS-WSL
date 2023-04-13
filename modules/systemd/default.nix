{ config, options, lib, ... }:
with lib; {
  imports = [
    ./native.nix
    ./syschdemd.nix
  ];

  options.wsl = with types; {
    nativeSystemd = mkOption {
      type = bool;
      default = false;
      description = "Use native WSL systemd support";
    };
  };

  config = mkIf config.wsl.enable (mkMerge [

    # this option doesn't exist on older NixOS, so hack.
    (lib.optionalAttrs (builtins.hasAttr "oomd" options.systemd) {
      # systemd-oomd requires cgroup pressure info which WSL doesn't have
      systemd.oomd.enable = false;
    })

  ]);

}
