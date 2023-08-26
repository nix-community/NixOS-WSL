{ lib, config, ... }:

with builtins; with lib;
{
  options.wsl.interop = with types; {
    register = mkOption {
      type = bool;
      default = false; # Use the existing registration by default
      description = "Explicitly register the binfmt_misc handler for Windows executables";
    };

    includePath = mkOption {
      type = bool;
      default = true;
      description = "Include Windows PATH in WSL PATH";
    };
  };

  config =
    let
      cfg = config.wsl.interop;
    in
    mkIf config.wsl.enable {

      boot.binfmt.registrations = mkIf cfg.register {
        WSLInterop = {
          magicOrExtension = "MZ";
          fixBinary = true;
          wrapInterpreterInShell = false;
          interpreter = "/init";
          preserveArgvZero = true;
        };
      };

      warnings =
        let
          registrations = config.boot.binfmt.registrations;
        in
        optional (!(registrations ? WSLInterop) && (length (attrNames config.boot.binfmt.registrations)) != 0) "Having any binfmt registrations without re-registering WSLInterop (wsl.interop.register) will break running .exe files from WSL2";
    };


}
