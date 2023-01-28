# Test that including the WSL module in a config does not change anything without enabling it

{ system
, inputs
, emptyFile
, ...
}:
let
  configModule = { config, options, ... }: {
    fileSystems."/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
    boot.loader.grub.device = "nodev";
    system.stateVersion = options.system.stateVersion.default;
  };

  cleanConfig = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      configModule
    ];
  };
  wslModuleConfig = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      configModule
      inputs.self.nixosModules.wsl
    ];
  };
in
# Check that both configs evaluate to the same derivation
if cleanConfig.config.system.build.toplevel.outPath == wslModuleConfig.config.system.build.toplevel.outPath
then emptyFile
else throw "The WSL module introduces a side-effect even when not enabled!"
