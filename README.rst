============
NixOS on WSL
============

A minimal root filesystem for running NixOS on WSL. It can be used with
DistroLauncher_ as ``install.tar.gz`` or as input to ``wsl --import --version
2``.


Quick start
===========

First, `download the latest release's system tarball
<https://github.com/Trundle/NixOS-WSL/releases/latest/download/nixos-system-x86_64-linux.tar.gz>`_.

Then open up a Terminal, PowerShell or Command Prompt and run::

   wsl --import NixOS .\NixOS\ nixos-system-x86_64-linux.tar.gz --version 2

This sets up a new WSL distribution ``NixOS`` that is installed under
``.\NixOS``. ``nixos-system-x86_64-linux.tar.gz`` is the path to the file you
downloaded earlier. You might need to change this path or change to the download
directory first.

You can now run NixOS::

   wsl -d NixOS

You will be dropped into a very primitive ``sh`` shell. From here you need to
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


Build your own system tarball
=============================

This requires access to a system that already has Nix installed. Please refer to
the `Nix installation guide <https://nixos.org/guides/install-nix.html>`_ if
that's not the case.

If you have a flakes-enabled Nix, you can use the following command to build your
own tarball instead of relying on a prebuilt one::

   nix build github:Trundle/NixOS-WSL#nixosConfigurations.mysystem.config.system.build.tarball

Or, if you want to build with local changes, run inside your checkout::

   nix build .#nixosConfigurations.mysystem.config.system.build.tarball

Without a flakes-enabled Nix, you can build a tarball using::

   nix-build -A system -A config.system.build.tarball ./nixos.nix

The resulting mini rootfs can then be found under
``./result-2/tarball/nixos-system-x86_64-linux.tar.gz``.


License
=======

Apache License, Version 2.0. See ``LICENSE`` or
http://www.apache.org/licenses/LICENSE-2.0.html for details.


Further links
=============

* DistroLauncher_
* `A quick way into a systemd "bottle" for WSL <https://github.com/arkane-systems/genie>`_
* `NixOS in Windows Store for Windows Subsystem for Linux <https://github.com/NixOS/nixpkgs/issues/30391>`_
* `wsl2-hacks <https://github.com/shayne/wsl2-hacks>`_


.. _DistroLauncher: https://github.com/microsoft/WSL-DistroLauncher
