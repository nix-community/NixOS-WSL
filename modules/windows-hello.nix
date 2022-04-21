{ lib, pkgs, config, ... }:

with builtins; with lib;
{

  options.wsl.windowsHello = {
    enable = mkEnableOption "Authentication using Windows Hello";
  };

  config =
    let
      cfg = config.wsl.windowsHello;
    in
    mkIf (config.wsl.enable && cfg.enable) {

      security.sudo.wheelNeedsPassword = true;
      security.sudo.extraConfig = ''
        Defaults rootpw
      '';

      # Hijack the pam_usb module, because NixOS does not allow for adding custom PAM modules at the moment
      security.pam.usb.enable = true;
      nixpkgs.overlays = [
        (self: super: {
          pam_usb =
            let
              authenticator = pkgs.stdenv.mkDerivation {
                name = "WindowsHelloAuthenticator.exe";
                src = pkgs.fetchurl {
                  url = "https://github.com/nzbr/PAM-WindowsHello/releases/download/v1/WindowsHelloAuthenticator.exe";
                  sha256 = "4856a1fefa5c869b78890f9313a560d310e9c11f2a2a212c2868cf292792ff7f";
                };
                dontUnpack = true;
                buildCommand = ''
                  install -m 0755 $src $out
                '';
              };
              wrapper = pkgs.writeShellScript "wrapper" ''
                export PATH=${pkgs.coreutils}/bin # The PAM environment does not include the default PATH
                export WSL_INTEROP="/run/WSL/$(ls -tr /run/WSL | tail -n1)" # Find the correct WSL_INTEROP socket to be able to start the EXE
                exec ${authenticator} [$PAM_SERVICE] $PAM_RUSER wants to authenticate as $PAM_USER
              '';
            in
            "${pkgs.pam}/lib/security/pam_exec.so ${wrapper} \n# ";
        })
      ];

    };

}
