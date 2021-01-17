============
NixOS on WSL
============

A minimal root filesystem for running NixOS on WSL. It can be used with
DistroLauncher_ as ``install.tar.gz`` or as input to ``wsl --import --version
2``.


Quick start
===========

First, you need to build the rootfs tarball. That can be done in some existing
Nix installation. If you don't have one, `you can install Nix in an existing
Linux installation such as Ubuntu on WSL
<https://nixos.org/download.html#nix-quick-install>`_. Alernatively, you can
also use the `nixos/nix Docker container <https://hub.docker.com/r/nixos/nix>`_.

Run the following commands in your Nix-enabled system:

- ``git clone https://github.com/Trundle/NixOS-WSL``
- ``cd NixOS-WSL``
- ``$EDITOR configuration.nix`` and change the ``defaultUser`` variable to whatever you want
- ``nix-build -A system -A config.system.build.tarball ./nixos.nix``

After that, the rootfs tarball can be found under
``result-2/tarball/nixos-system-x86_64-linux.tar.gz``. Copy the file to your
Windows installation. If you used another WSL distribution to build the tarball,
that can be done with the following commands:

- ``mkdir "/mnt/c/Users/[Windows username]/NixOS"``
- ``cp result-2/tarball/nixos-system-x86_64-linux.tar.gz "/mnt/c/Users/[Windows username]/NixOS/"``

Open up a Command Prompt or PowerShell and run:

- ``wsl --import NixOS .\NixOS\ .\NixOS\nixos-system-x86_64-linux.tar.gz --version 2``
- ``wsl -d NixOS``

You will be dropped into a very primitive ``sh`` shell, from here you need to
run this once::

  /nix/var/nix/profiles/system/activate

A few warnings about locales will pop up. You can safely ignore them.

Exit and restart WSL and you should be greeted with a much fancier bash prompt
inside your fresh NixOS.

If you want to make NixOS your default distribution, you can do so via ``wsl -s
NixOS``.


systemd support
===============

WSL comes with its own (non-substitutable) init system while NixOS uses systemd.
Simply starting systemd later on does not work out of the box, because systemd
as system instance refuses to start if it is not PID 1. This unfortunate
combination is resolved in two ways:

* the user's default shell is replaced by a wrapper script that acts is init
  system and then drops to the actual shell
* systemd is started in its own PID namespace; therefore, it is PID 1. The shell
  wrapper (see above) enters the systemd namespace before dropping to the shell.


How to build
============

::

   $ nix-build -A system -A config.system.build.tarball ./nixos.nix

The resulting mini rootfs can then be found under
``./result-2/tarball/nixos-system-x86_64-linux.tar.gz``.


Further links
=============

* DistroLauncher_
* `A quick way into a systemd "bottle" for WSL <https://github.com/arkane-systems/genie>`_
* `NixOS in Windows Store for Windows Subsystem for Linux <https://github.com/NixOS/nixpkgs/issues/30391>`_
* `wsl2-hacks <https://github.com/shayne/wsl2-hacks>`_


.. _DistroLauncher: https://github.com/microsoft/WSL-DistroLauncher
