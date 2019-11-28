{ lib, pkgs, config, ... }:

let
  nixpkgs = import <nixpkgs> {};

  inherit (nixpkgs) daemonize;
in
pkgs.substituteAll {
  name = "syschdemd";
  src = ./syschdemd.sh;
  dir = "bin";
  isExecutable = true;

  buildInputs = [ daemonize ];

  inherit daemonize;
  inherit (config.security) wrapperDir;
  fsPackagesPath = lib.makeBinPath config.system.fsPackages;
}
