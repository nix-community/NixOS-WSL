# Setup VSCode Remote

The VSCode Remote server can not be run as-is on NixOS, because it downloads a nodejs binary that
requires `/lib64/ld-linux-x86-64.so.2` to be present, which isn't the case on NixOS.

There are two options to get the server to run.
Option 1 is more robust but might impact other programs. Option 2 is a little bit more brittle and sometimes breaks on updates but doesn't influence other programs.
Both options require `wget` to be installed:

```nix
environment.systemPackages = [
    pkgs.wget
];
```

## Option 1: Set up nix-ld

[nix-ld](https://github.com/Mic92/nix-ld) is a program that provides `/lib64/ld-linux-x86-64.so.2`,
allowing foreign binaries to run on NixOS.

To set it up, add the following to your configuration:

```nix
programs.nix-ld.enable = true;
```

## Option 2: Patch the server

The other option is to replace the nodejs binary that ships with the vscode server with one from the nodejs nixpkgs package.
[This module will set up everything that is required to get it running](https://github.com/K900/vscode-remote-workaround/blob/main/vscode.nix).  
If you are [using flakes](./nix-flakes.md), you can add that repo as a flake input and include it from there.
Otherwise, copy the file to your configuration and add it to your imports.

Add the following to your configuration to enable the module:

```nix
vscode-remote-workaround.enable = true;
```
