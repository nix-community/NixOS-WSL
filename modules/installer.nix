{ config, lib, pkgs, ... }:
with builtins; with lib; {

  config = mkIf config.wsl.enable (
    let
      mkTarball = pkgs.callPackage "${lib.cleanSource pkgs.path}/nixos/lib/make-system-tarball.nix";

      pkgs2storeContents = map (x: { object = x; symlink = "none"; });

      rootfs = let tarball = config.system.build.tarball; in "${tarball}/tarball/${tarball.fileName}.tar${tarball.extension}";

      installer = pkgs.writeScript "installer.sh" ''
        #!${pkgs.busybox}/bin/sh
        BASEPATH=$PATH
        export PATH=$BASEPATH:${pkgs.busybox}/bin # Add busybox to path

        set -e
        cd /

        echo "Unpacking root file system..."
        ${pkgs.pv}/bin/pv ${rootfs} | tar xz

        echo "Activating nix configuration..."
        /nix/var/nix/profiles/system/activate
        PATH=$BASEPATH:/run/current-system/sw/bin # Use packages from target system

        echo "Cleaning up installer files..."
        nix-collect-garbage
        rm /nix-path-registration

        echo "Optimizing store..."
        nix-store --optimize

        # Don't package the shell here, it's contained in the rootfs
        exec ${builtins.unsafeDiscardStringContext config.users.users.root.shell} "$@"
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
        ];

        contents = [
          { source = config.environment.etc."wsl.conf".source; target = "/etc/wsl.conf"; }
          { source = config.environment.etc."fstab".source; target = "/etc/fstab"; }
          { source = passwd; target = "/etc/passwd"; }
          { source = "${pkgs.busybox}/bin/busybox"; target = "/bin/sh"; }
          { source = "${pkgs.busybox}/bin/busybox"; target = "/bin/mount"; }
        ];

        extraCommands = pkgs.writeShellScript "prepare" ''
          export PATH=$PATH:${pkgs.coreutils}/bin
          mkdir -p bin
          ln -s /init bin/wslpath
        '';
      };

    }
  );

}
