{ pkgs
, c ? "/mnt/c"
, ...
}:
let
  wl-copy = pkgs.writeShellScriptBin "wl-copy" ''
    printf '%s' "$(cat)" | ${pkgs.dos2unix}/bin/unix2dos | ${c}/windows/system32/clip.exe
  '';

  wl-paste = pkgs.writeShellScriptBin "wl-paste" ''
    ${c}/windows/system32/windowspowershell/v1.0/powershell.exe -NoProfile -Command Get-Clipboard | ${pkgs.dos2unix}/bin/dos2unix
  '';
in
pkgs.symlinkJoin {
  name = "wl-clipboard-wsl";
  paths = [
    wl-copy
    wl-paste
  ];
}
