{ config, lib, ... }:
{

  config =
    lib.mkIf
      (
        config.wsl.enable &&
        (config.wsl.docker-desktop.enable ||
        config.virtualisation.podman.enable ||
        (config.virtualisation.docker.enable &&
        (lib.versionAtLeast config.virtualisation.docker.package.version "25")))
      )
      {

        # Related issues:
        #   - https://github.com/nix-community/NixOS-WSL/issues/433
        #   - https://github.com/NVIDIA/nvidia-container-toolkit/issues/452
        #
        # By setting `useWindowsDriver` to true, the Nvidia libraries are properly
        # mounted on the container from the host.
        wsl.useWindowsDriver = lib.mkIf config.hardware.nvidia-container-toolkit.enable true;

      };
}
