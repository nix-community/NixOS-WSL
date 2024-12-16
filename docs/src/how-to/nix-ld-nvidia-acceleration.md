# How to use NVIDIA acceleration with nix-ld

By default, the NixOS WSL configuration provides a symlink farm from
/usr/lib/wsl/lib to the OpenGL packages. However, if you want to use the GPU
with a non-NixOS compiled program via nix-ld (e.g. nvidia-smi), you also need to
add the symlinks to the to the nix-ld libraries.

```nix
let
  wsl-lib = pkgs.runCommand "wsl-lib" { } ''
    mkdir -p "$out/lib"
    # # We can't just symlink the lib directory, because it will break merging with other drivers that provide the same directory
    ln -s /usr/lib/wsl/lib/libcudadebugger.so.1 "$out/lib"
    ln -s /usr/lib/wsl/lib/libcuda.so "$out/lib
    ln -s /usr/lib/wsl/lib/libcuda.so.1 "$out/lib
    ln -s /usr/lib/wsl/lib/libcuda.so.1.1 "$out/lib
    ln -s /usr/lib/wsl/lib/libd3d12core.so "$out/lib
    ln -s /usr/lib/wsl/lib/libd3d12.so "$out/lib
    ln -s /usr/lib/wsl/lib/libdxcore.so "$out/lib
    ln -s /usr/lib/wsl/lib/libnvcuvid.so "$out/lib
    ln -s /usr/lib/wsl/lib/libnvcuvid.so.1 "$out/lib
    ln -s /usr/lib/wsl/lib/libnvdxdlkernels.so "$out/lib
    ln -s /usr/lib/wsl/lib/libnvidia-encode.so "$out/lib
    ln -s /usr/lib/wsl/lib/libnvidia-encode.so.1 "$out/lib
    ln -s /usr/lib/wsl/lib/libnvidia-ml.so.1 "$out/lib
    ln -s /usr/lib/wsl/lib/libnvidia-opticalflow.so "$out/lib
    ln -s /usr/lib/wsl/lib/libnvidia-opticalflow.so.1 "$out/lib
    ln -s /usr/lib/wsl/lib/libnvoptix.so.1 "$out/lib
    ln -s /usr/lib/wsl/lib/libnvwgf2umx.so "$out/lib
    ln -s /usr/lib/wsl/lib/nvidia-smi "$out/lib
  '';
in
{
  programs.nix-ld = {
    enable = true;
    libraries = [ wsl-lib ];
  };
}
```

Test the installation by running the following command:

```shell
/usr/lib/wsl/lib/nvidia-smi
```
