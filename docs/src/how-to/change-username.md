# How to change the username

If you want to change the default username to something other than `nixos`, use the `wsl.defaultUser` option.
When building your own tarball, this should be sufficient. A user with the name specified in that option will be created automatically.

Changing the username on an already installed system is possible as well.
Follow these instructions to make sure, the change gets applied correctly:

1. Run `sudo nixos-rebuild edit` to edit your `/etc/nixos/configuration.nix`.
2. Change the `wsl.defaultUser` setting in your configuration to the desired username.
3. Apply the configuration:\
   `sudo nixos-rebuild boot`\
   Do not use `nixos-rebuild switch`! It may lead to the new user account being misconfigured.
4. Exit the WSL shell and stop your NixOS distro:\
   `wsl -t NixOS`.
5. Start a shell inside NixOS and immediately exit it to apply the new generation:\
   `wsl -d NixOS --user root exit`
6. Stop the distro again:\
   `wsl -t NixOS`
7. Open a WSL shell. Your new username should be applied now!
