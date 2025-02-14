# Installation

## System requirements

NixOS-WSL is tested with the Windows Store version of WSL 2, which is now available on all supported Windows releases (both 10 and 11).
Support for older "inbox" versions is best-effort.

## Install NixOS-WSL

First, download `nixos.wsl` from [the latest release](https://github.com/nix-community/NixOS-WSL/releases/latest).[^wsl-file]

If you have WSL version 2.4.4 or later installed, you can open (double-click) the .wsl file to install it.
It is also possible to perform the installation from a PowerShell:

```powershell
wsl --install --from-file nixos.wsl
```

`nixos.wsl` must be the path to the file you just downloaded if you're running the command in another directory.

You can use the `--name` and `--location` flags to change the name the distro is registered under (default: `NixOS`) and the location of the disk image (default: `%localappdata%\wsl\{some random GUID}`). For a full list of options, refer to `wsl --help`

To open a shell in your NixOS environment, run `wsl -d NixOS`, select NixOS from the profile dropdown in Windows Terminal or run it from your Start Menu. (Adjust the name accordingly if you changed it)

### Older WSL versions

If you have a WSL version older than 2.4.4, you can install NixOS-WSL like this:

Open up a PowerShell and run:

```powershell
wsl --import NixOS $env:USERPROFILE\NixOS nixos.wsl --version 2
```

Or for Command Prompt:

```cmd
wsl --import NixOS %USERPROFILE%\NixOS nixos.wsl --version 2
```

This sets up a new WSL distribution `NixOS` that is installed in a directory called `NixOS` inside your user directory.
`nixos.wsl` is the path to the file you downloaded earlier.
You can adjust the installation path and distribution name to your liking.

To get a shell in your NixOS environment, use:

```powershell
wsl -d NixOS
```

If you chose a different name for your distro during import, adjust this command accordingly.

## Post-Install

After the initial installation, you need to update your channels once, to be able to use `nixos-rebuild`:

```sh
sudo nix-channel --update
```

If you want to make NixOS your default distribution, you can do so with

```powershell
wsl -s NixOS
```

[^wsl-file]: That file is called `nixos-wsl.tar.gz` in releases prior to 2411.*
