# How-to

## Using packages in nix-shell

`nix-shell` can be used to run a temporary shell or command that uses packages
you don't want to install into your system permanently, or to use other
versions of packages than you have installed.  For example there is a
'cowsay' command that is like echo but with an ascii cow saying the words.
If you type `cowsay Hello, world!`, you will get an error that will tell you
the cowsay command is provided by multiple packages and show you the nix-shell
commands to use them:

```
[nixos@nixos:/mnt/c/t/nix]$ cowsay moo
The program 'cowsay' is not in your PATH. It is provided by several packages.
You can make it available in an ephemeral shell by typing one of the following:
  nix-shell -p cowsay
  nix-shell -p neo-cowsay

[nixos@nixos:/mnt/c/t/nix]$ nix-shell -p cowsay
this path will be fetched (0.01 MiB download, 0.05 MiB unpacked):
  /nix/store/pjaiq8m9rjgj9akjgmbzmz86cvxwsyqm-cowsay-3.7.0
copying path '/nix/store/pjaiq8m9rjgj9akjgmbzmz86cvxwsyqm-cowsay-3.7.0' from 'https://cache.nixos.org'...

[nix-shell:/mnt/c/t/nix]$ cowsay moo
 _____
< moo >
 -----
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

[nix-shell:/mnt/c/t/nix]$ exit
exit

[nixos@nixos:/mnt/c/t/nix]$
```

You can also specify multiple packages and specify a `--run` parameter to run
a single command and exit instead of leaving you in a shell:

```
nix-shell -p cowsay lolcat --run "cowsay Hello, cat! | lolcat"
```


## System Packages

To add packages, edit `/etc/nixos/configuration.nix` using sudo.   You
can use the `nano` editor which comes installed and uses CTRL+S to save
and CTRL+X to exit:

```
sudo nano /etc/nixos/configuration.nix
```

At the bottom you can add system packages to be available in the system:

```
  environment.systemPackages = [ pkgs.cowsay pkgs.lolcat ];
}
```

To switch to the new configuration use this:

```
sudo nixos-rebuild switch
```

Now you can use the commands provided in those packages by default:

```
cowsay Hello, NixOS! | lolcat
```
