{ pkgs, ... }:
let
  wl-copy = pkgs.writeShellScriptBin "wl-copy" ''
    printf '%s' "$(cat)" | ${pkgs.dos2unix}/bin/unix2dos | /mnt/c/windows/system32/clip.exe
  '';

  wl-paste = pkgs.writeShellScriptBin "wl-paste" ''
    /mnt/c/windows/system32/windowspowershell/v1.0/powershell.exe -command Get-Clipboard | ${pkgs.dos2unix}/bin/dos2unix
  '';
in
pkgs.symlinkJoin {
  name = "wl-clipboard-wsl";
  paths = [
    wl-copy
    wl-paste
  ];
}
