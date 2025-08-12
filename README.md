<h1 align=center>
  <img src="https://raw.githubusercontent.com/nix-community/NixOS-WSL/refs/heads/main/assets/NixOS-WSL.svg" alt="NixOS-WSL" width="500rem" /><br />
  <a href="https://matrix.to/#/#wsl:nixos.org"><img src="https://img.shields.io/matrix/wsl:nixos.org?server_fqdn=matrix.org&logo=matrix" alt="Matrix Chat" /></a>
  <a href="https://github.com/nix-community/NixOS-WSL/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/nix-community/NixOS-WSL/total"></a>
</h1>

Modules for running NixOS on the Windows Subsystem for Linux

[Documentation is available here](https://nix-community.github.io/NixOS-WSL)

## Quick Start

Run the following from powershell:

1. Enable WSL if you haven't done already:

  - ```powershell
    wsl --install --no-distribution
    ```

2. Download `nixos.wsl` from [the latest release](https://github.com/nix-community/NixOS-WSL/releases/latest).

3. Double-click the file you just downloaded (requires WSL >= 2.4.4)

4. You can now run NixOS:

- ```powershell
  wsl -d NixOS
  ```

For more detailed instructions, [refer to the documentation](https://nix-community.github.io/NixOS-WSL/install.html).

## License

Apache License, Version 2.0. See `LICENSE` or <http://www.apache.org/licenses/LICENSE-2.0.html> for details.
