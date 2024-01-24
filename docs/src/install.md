# Installation

## System requirements

NixOS-WSL is tested with the Windows Store version of WSL 2, which is now available on all supported Windows releases (both 10 and 11).
Support for older "inbox" versions is best-effort.

## Quick start

First, [download the latest release](https://github.com/nix-community/NixOS-WSL/releases/latest).

Then open up a Terminal, PowerShell or Command Prompt and run:

```powershell
wsl --import NixOS .\NixOS\ nixos-wsl.tar.gz --version 2
```

This sets up a new WSL distribution `NixOS` that is installed under
`.\NixOS`. `nixos-wsl.tar.gz` is the path to the file you
downloaded earlier. You might need to change this path or change to the download directory first.

You can now run NixOS:

```powershell
wsl -d NixOS
```

After the initial installation, you need to update your channels once, to be able to use `nixos-rebuild`:

```sh
nix-channel --update
```

If you want to make NixOS your default distribution, you can do so with

```powershell
wsl -s NixOS
```
