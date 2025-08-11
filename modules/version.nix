{ lib, pkgs, options, config, ... }:
with lib;
{

  options = with types; {
    wsl.version =
      let
        versionFile = splitString "\n" (readFile ../VERSION);
      in
      {
        release = mkOption {
          internal = true;
          description = "the NixOS-WSL release";
          type = str;
          default = elemAt versionFile 0;
        };
        rev = mkOption {
          internal = true;
          description = "the NixOS-WSL git revision";
          type = str;
          default = elemAt versionFile 1;
        };
      };
  };

  config = mkIf config.wsl.enable {

    environment.systemPackages = [
      (
        with config.wsl.version;
        let
          opts = options.wsl.version;
          maxlen = foldl (acc: opt: max acc (stringLength opt)) 0 ((attrNames opts) ++ [ "help" "json" ]);
          rightPad = text: "${text}${fixedWidthString (2 + maxlen - (stringLength text)) " " ""}";
        in
        pkgs.writeShellScriptBin "nixos-wsl-version" ''
          for arg in "$@"; do
            case $arg in
              --help)
                echo "Usage: nixos-wsl-version [option]"
                echo "Options:"
                echo -e "  --${rightPad "help"}Show this help message"
                ${concatStringsSep "\n" (
                  mapAttrsToList (option: value: ''
                    echo "  --${rightPad option}Show ${value.description}"
                  '') opts
                )}
                echo -e "  --${rightPad "json"}Show everything in JSON format"
                exit 0
                ;;
              ${concatStringsSep "\n" (
                mapAttrsToList (option: value: ''
                  --${option})
                  echo ${value}
                  exit 0
                  ;;
                '') config.wsl.version
              )}
              --json)
                echo '${generators.toJSON {} config.wsl.version}' | ${pkgs.jq}/bin/jq -M # Use jq to pretty-print the JSON
                exit 0
                ;;
              *)
                echo "Unknown argument: $arg"
                exit 1
                ;;
            esac
          done
          echo NixOS-WSL ${config.wsl.version.release} ${config.wsl.version.rev}
        ''
      )
    ];

  };

}
