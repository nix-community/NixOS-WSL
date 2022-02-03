{ config, lib, pkgs, ... }:
with builtins; with lib; {

  config = mkIf config.wsl.enable (
    let
      mkTarball = pkgs.callPackage "${lib.cleanSource pkgs.path}/nixos/lib/make-system-tarball.nix";

      busybox-static = pkgs.busybox.override { enableStatic = true; };

      pkgs2storeContents = map (x: { object = x; symlink = "none"; });

      installerDependencies = mkTarball {
        fileName = "store";
        compressCommand = "cat";
        compressionExtension = "";
        contents = [ ];
        storeContents = with pkgs; pkgs2storeContents [
          pv
        ];
      };

      installer = pkgs.writeScript "installer.sh" ''
        #!/bin/sh
        set -e
        cd /

        echo "Unpacking installer..."
        tar xf /store.tar

        echo "Unpacking root file system..."
        ${pkgs.pv}/bin/pv /rootfs.tar.gz | tar xz

        echo "Cleaning up installer files..."
        rm /rootfs.tar.gz /store.tar /installer.sh

        echo "Activating nix configuration..."
        /nix/var/nix/profiles/system/activate

        echo "Starting systemd..."
        exec ${config.users.users.root.shell}
      '';

      # Set installer.sh as the root shell
      passwd = pkgs.writeText "passwd" ''
        root:x:0:0:System administrator:/root:/installer.sh
      '';
    in
    {

      system.build.installer = mkTarball {
        fileName = "nixos-wsl-installer";
        compressCommand = "gzip";
        compressionExtension = ".gz";

        contents = [
          {
            source = let tarball = config.system.build.tarball; in "${tarball}/tarball/${tarball.fileName}.tar${tarball.extension}";
            target = "/rootfs.tar.gz";
          }
          { source = "${installerDependencies}/tarball/store.tar"; target = "/store.tar"; }
          { source = "${busybox-static}/bin/busybox"; target = "/bin/busybox"; }
          { source = config.environment.etc."wsl.conf".source; target = "/etc/wsl.conf"; }
          { source = passwd; target = "/etc/passwd"; }
          { source = installer; target = "/installer.sh"; }
        ];

        extraCommands =
          let
            # WSL's --import does not like hardlinks, create symlinks instead
            createBusyboxLinks = concatStringsSep "\n" (
              mapAttrsToList
                (applet: type: "ln -s /bin/busybox ./bin/${applet}")
                (filterAttrs
                  (applet: type: applet != "busybox") # don't overwrite the original busybox
                  (readDir "${busybox-static}/bin")
                )
            );
          in
          pkgs.writeShellScript "busybox-setup" ''
            set -e
            ${createBusyboxLinks}
          '';
      };

    }
  );

}
