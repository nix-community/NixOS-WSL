{ config, lib, pkgs, ... }:
with builtins; with lib; {

  config = mkIf config.wsl.enable (
    let
      mkTarball = pkgs.callPackage "${lib.cleanSource pkgs.path}/nixos/lib/make-system-tarball.nix";

      pkgs2storeContents = map (x: { object = x; symlink = "none"; });

      busybox = pkgs.pkgsMusl.busybox;
      pv = pkgs.pkgsMusl.pv;

      rootfs = let tarball = config.system.build.tarball; in "${tarball}/tarball/${tarball.fileName}.tar${tarball.extension}";

      installer = pkgs.writeScript "installer.sh" ''
        #!${busybox}/bin/sh
        BASEPATH=$PATH
        export PATH=$BASEPATH:${busybox}/bin # Add busybox to path

        set -e
        cd /

        echo "Unpacking root file system..."
        ${pv}/bin/pv ${rootfs} | tar xz

        echo "Activating nix configuration..."
        /nix/var/nix/profiles/system/activate
        PATH=$BASEPATH:/run/current-system/sw/bin # Use packages from target system

        echo "Cleaning up installer files..."
        nix-collect-garbage
        rm /nix-path-registration
        rm -rf /nix/wsl-installer

        echo "Optimizing store..."
        nix-store --optimize

        # Don't package the shell here, it's contained in the rootfs
        exec ${builtins.unsafeDiscardStringContext config.users.users.root.shell} "$@"
      '';

      updater =
        let
          stage2 = pkgs.writeScript "updater-stage-2.sh" ''
            #!${busybox}/bin/sh
            set -euo pipefail

            # Set PATH to include busybox
            export PATH=${busybox}/bin:$PATH

            # Root check
            if [ `id -u` != "0" ]; then
              echo "This script must be run as root" >&2
              exit 1
            fi


            function prompt_yn {
              while true; do
                read -p "$@ [y/n] " result
                case $result in
                  [Yy]* ) return 0;;
                  [Nn]* ) return 1;;
                  * ) echo "Please answer yes or no.";;
                esac
              done
            }

            #Parse arguments
            GC=true
            REBUILD=false
            for arg in "$@"; do
              case $arg in
                --no-gc)
                  GC=false
                  ;;
                --rebuild)
                  REBUILD=true
                  ;;
                *)
                  echo "Unknown argument: $arg"
                  exit 1
                  ;;
              esac
            done


            # Check if /etc/nixos/nixos-wsl exists
            if ! [ -d /etc/nixos/nixos-wsl ]; then
              echo "/etc/nixos/nixos-wsl was not found! Can not update this system" >&2
              exit 1
            fi

            # Unpack rootfs
            echo "Unpacking..."
            mkdir -p /tmp/nixos-wsl-updater/rootfs
            ${pv}/bin/pv ${rootfs} | tar -C /tmp/nixos-wsl-updater/rootfs -xz

            # Detect flake.nix
            FLAKE=false
            if [ -f /etc/nixos/flake.nix ]; then
              echo "Flake detected!"
              echo "Please update your nixpkgs input to \"github:nixos/nixpkgs/nixos-${config.system.nixos.release}\" and run nixos-rebuild to complete the update"
              echo "Press enter to continue..."
              read
              FLAKE=true
            fi

            # Check that nixos-rebuild builds the current configuration
            EXTERNAL=false
            if ! $FLAKE; then
              dir=$PWD
              cd $(mktemp -d)
              nixos-rebuild build
              if [[ $(readlink /run/current-system) != $(readlink result) ]]; then
                echo "The current configuration does not match what is produced by nixos-rebuild!" >&2
                echo "Please make sure to update your nixos channel or nixpkgs input to NixOS ${config.system.nixos.release}" >&2
                echo "Press enter to continue..."
                read
                EXTERNAL=true
              fi
              cd $dir
            fi

            # Update channels
            if ! $FLAKE && ! $EXTERNAL; then
              echo "Updating channels..."
              nix-channel --add https://nixos.org/channels/nixos-${config.system.nixos.release} nixos
              nix-channel --update -v
            fi

            # Replace config
            echo "Updating configuration..."
            rm -rf /etc/nixos/nixos-wsl.bak
            mv /etc/nixos/nixos-wsl /etc/nixos/nixos-wsl.bak
            cp -r /tmp/nixos-wsl-updater/rootfs/etc/nixos/nixos-wsl /etc/nixos/nixos-wsl
            chmod a-w -R /etc/nixos/nixos-wsl

            # Rebuild
            if ! $FLAKE && ! $EXTERNAL; then
              if $REBUILD || prompt_yn "Run nixos-rebuild switch?"; then
                nixos-rebuild switch
              fi
            fi

            # Clean up
            echo "Cleaning up..."
            rm -rf /tmp/nixos-wsl-updater
            if $GC; then
              exec nix-collect-garbage
            fi
          '';
        in
        pkgs.writeScript "updater-stage-1.sh" ''
          #!/usr/bin/env sh
          set -euo pipefail

          # cd to tarball root
          TAR_ROOT=$(dirname $0)/../../

          # Import derivations
          nix-store -v --store $TAR_ROOT --load-db < $TAR_ROOT/nix-path-registration
          nix --extra-experimental-features "nix-command" copy -v --no-check-sigs --from $TAR_ROOT ${stage2}

          exec ${stage2} "$@"
        '';

      # Set installer.sh as the root shell
      passwd = pkgs.writeText "passwd" ''
        root:x:0:0:System administrator:/root:${installer}
      '';
    in
    {

      system.build.installer = mkTarball {
        fileName = "nixos-wsl-installer";
        compressCommand = "gzip";
        compressionExtension = ".gz";
        extraArgs = "--hard-dereference";

        storeContents = with pkgs; pkgs2storeContents [
          installer
          updater
        ];

        contents = [
          { source = config.environment.etc."wsl.conf".source; target = "/etc/wsl.conf"; }
          { source = config.environment.etc."fstab".source; target = "/etc/fstab"; }
          { source = passwd; target = "/etc/passwd"; }
          { source = "${busybox}/bin/busybox"; target = "/bin/sh"; }
          { source = "${busybox}/bin/busybox"; target = "/bin/mount"; }
          { source = "${installer}"; target = "/nix/nixos-wsl/entrypoint"; }
        ];

        extraCommands = pkgs.writeShellScript "prepare" ''
          export PATH=${busybox}/bin:$PATH
          mkdir -p bin root nix/wsl-installer

          ln -vs /init bin/wslpath
          ln -vs ../..${installer} nix/wsl-installer/installer.sh
          ln -vs ../..${updater} nix/wsl-installer/updater.sh
          ln -vs ../..${rootfs} nix/wsl-installer/rootfs.tar.gz
        '';
      };

    }
  );

}
