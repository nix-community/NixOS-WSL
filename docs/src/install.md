# Installation

## System requirements

NixOS-WSL is tested with the Windows Store version of WSL 2, which is now available on all supported Windows releases (both 10 and 11).
Support for older "inbox" versions is best-effort.

## Install NixOS-WSL

First, [download the latest release](https://github.com/nix-community/NixOS-WSL/releases/latest).

Then open up a PowerShell and run:

```powershell
wsl --import NixOS --version 2 $env:USERPROFILE\NixOS\ nixos-wsl.tar.gz
```

Or for Command Prompt:

```cmd
wsl --import NixOS --version 2 %USERPROFILE%\NixOS\ nixos-wsl.tar.gz
```

This sets up a new WSL distribution `NixOS` that is installed in a directory called `NixOS` inside your user directory.
`nixos-wsl.tar.gz` is the path to the file you downloaded earlier.
You can adjust the installation path and distribution name to your liking.

To get a shell in your NixOS environment, use:

```powershell
wsl -d NixOS
```

If you chose a different name for your distro during import, adjust this command accordingly.

## Install certificate for msixbundle

First open launcher properties and view the details of signature `nzbr` from `Digital Signatures` tab.

Then select `View Certificate` which let's you `Install Certificate`.

Install the certificate for either `Current User` or `Local Machine` depending on your preferences. Select the certificate store manually and use `Trusted People`.

You should now be able to use the .msixbundle.

## Post-Install

After the initial installation, you need to update your channels once, to be able to use `nixos-rebuild`:

```sh
sudo nix-channel --update
```

If you want to make NixOS your default distribution, you can do so with

```powershell
wsl -s NixOS
```
