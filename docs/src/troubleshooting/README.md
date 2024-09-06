# Troubleshooting

## General Tips

- Try fully restarting WSL by running `wsl --shutdown`. This will close all your terminal windows. Then just restart wsl in your terminal. \
  Please keep in mind that this will also end any process you might have running in other WSL distros.
  If that is currently not an option, you may try `wsl -t nixos`, which will just stop the `nixos` distro.
  (You may need to change that if you imported the distro under some other name). However, some issues will only be resolved after a _full_ restart of WSL.
- Make sure that you are using the [Microsoft Store version](https://www.microsoft.com/store/productId/9P9TQF7MRM4R) of WSL
- Update WSL2 to the latest version
  - To update, run: `wsl --update`
  - To check which version you currently have installed, run `wsl --version`
    - The latest version can be found on the [Microsoft/WSL](https://github.com/microsoft/WSL/releases/latest) repo
    - If this command does not work, you are probably not using the Microsoft Store version of WSL!
- If after booting into WSL and attempting to use the Nix daemon results in the output  
  `error: cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Connection refused`,
  then you most likely need to add the following snippet to your
  [`%USERPROFILE%/.wslconfig`](https://learn.microsoft.com/en-us/windows/wsl/wsl-config) file.
  ```ini
  [wsl2]
  kernelCommandLine = cgroup_no_v1=all
  ```
