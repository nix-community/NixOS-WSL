{ system
, inputs
, runCommand
, ...
}:

let
  baseModule = { ... }: {
    imports = [ ../modules ];
    wsl.enable = true;
    wsl.defaultUser = "nixos";
  };
  changedUsername = { lib, ... }: {
    wsl.defaultUser = lib.mkForce "different";
  };
  changedUserAttr = { config, lib, ... }: {
    wsl.defaultUser = lib.mkForce "userattr";
    users.users.${config.wsl.defaultUser}.name = "username";
  };
  buildConfig = module: (inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [ baseModule module ];
  }).config.system.build.toplevel;
in
runCommand "different=usernames" { } ''
  mkdir -p $out
  ln -s ${buildConfig changedUsername} $out/changedUsername
  ln -s ${buildConfig changedUserAttr} $out/changedUserAttr
''
