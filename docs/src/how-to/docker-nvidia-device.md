# How to use NVIDIA GPU in Docker

WSL supports NVIDIA-based GPU acceleration, making it ideal for many use cases
including machine learning or general compute acceleration. Since Docker version
25, the use of `virtualisation.docker.enableNvidia` has been deprecated in
favour of a more standard specification called Container Device Interface.

1. Enable the NVIDIA Container Toolkit and disable the mounting of executables,
   as this will cause an problem related to missing libraries.

```nix
hardware.nvidia-container-toolkit = {
  enable = true;
  mount-nvidia-executables = false;
};
```

2. The Docker daemon doesn't have the CDI feature enabled by default.

```nix
virtualisation.docker = {
  enable = true;
  daemon.settings.features.cdi = true;
};
```

3. Test the installation by running the following command.

```shell
docker run --rm --device nvidia.com/gpu=all ubuntu nvidia-smi
```
