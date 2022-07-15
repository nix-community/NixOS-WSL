{ lib, pkgs, config, ... }:

with builtins; with lib;
{
  imports = [
    (mkRenamedOptionModule [ "wsl" "compatibility" "interopPreserveArgvZero" ] [ "wsl" "interop" "preserveArgvZero" ])
  ];

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

    preserveArgvZero = mkOption {
      type = nullOr bool;
      default = null;
      description = ''
        Register binfmt interpreter for Windows executables with 'preserves argv[0]' flag.

        Default (null): autodetect, at some performance cost.
        To avoid the performance cost, set this to true for WSL Preview 0.58 and up,
        or to false for any older versions, including pre-Microsoft Store and Windows 10.
      '';
    };
  };

  config =
    let
      cfg = config.wsl.interop;
    in
    mkIf config.wsl.enable {

      boot.binfmt.registrations = mkIf cfg.register {
        WSLInterop =
          let
            compat = cfg.preserveArgvZero;

            # WSL Preview 0.58 and up registers the /init binfmt interp for Windows executable
            # with the "preserve argv[0]" flag, so if you run `./foo.exe`, the interp gets invoked
            # as `/init foo.exe ./foo.exe`.
            #   argv[0] --^        ^-- actual path
            #
            # Older versions expect to be called without the argv[0] bit, simply as `/init ./foo.exe`.
            #
            # We detect that by running `/init /known-not-existing-path.exe` and checking the exit code:
            # the new style interp expects at least two arguments, so exits with exit code 1,
            # presumably meaning "parsing error"; the old style interp attempts to actually run
            # the executable, fails to find it, and exits with 255.
            compatWrapper = pkgs.writeShellScript "nixos-wsl-binfmt-hack" ''
              /init /nixos-wsl-does-not-exist.exe
              [ $? -eq 255 ] && shift
              exec /init "$@"
            '';

            # use the autodetect hack if unset, otherwise call /init directly
            interpreter = if compat == null then compatWrapper else "/init";

            # enable for the wrapper and autodetect hack
            preserveArgvZero = if compat == false then false else true;
          in
          {
            magicOrExtension = "MZ";
            fixBinary = true;
            wrapInterpreterInShell = false;
            inherit interpreter preserveArgvZero;
          };
      };

      # Include Windows %PATH% in Linux $PATH.
      environment.extraInit = mkIf cfg.includePath ''PATH="$PATH:$WSLPATH"'';

      warnings =
        let
          registrations = config.boot.binfmt.registrations;
        in
        optional (!(registrations ? WSLInterop) && (length (attrNames config.boot.binfmt.registrations)) != 0) "Having any binfmt registrations without re-registering WSLInterop (wsl.interop.register) will break running .exe files from WSL2";
    };


}
