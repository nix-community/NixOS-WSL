{
  imports = [
    <nixos-wsl/modules>
  ];

  wsl.enable = true;
  wsl.nativeSystemd = false;
  wsl.defaultUser = "different-name";
}
