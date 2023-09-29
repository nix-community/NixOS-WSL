# Tests

This directory contains tests that are executed against a built NixOS-WSL "legacy" tarball.
The tests are written using the [Pester](https://pester.dev/) testing framework.

## Execute Tests

The tests can be executed on both Windows or Linux.

### Windows

Make sure that you are able to run a distro in WSL2 before trying to run the tests.
Please note that the tests are not compatible with Windows PowerShell, but require the new [PowerShell Core](https://apps.microsoft.com/store/detail/powershell/9MZ1SNWT0N5D?hl=en-us&gl=us).

### Linux

Running the tests requires Docker and PowerShell to be installed on your system. Make sure that the user you are running the tests as has permissions to run docker containers and that it is possible to access the internet from inside docker containers.

### Running the Tests

If you haven't already, [install Pester](https://pester.dev/docs/introduction/installation/).  
The tests require a "legacy" `nixos-wsl.tar.gz` to be present in the current working directory, which can be built with
`sudo nix run .#nixosConfigurations.legacy.config.system.build.tarballBuilder -- nixos-wsl.tar.gz`.

Once everything is in place, run the test by running the following in PowerShell at the root of this repo:

```powershell
Invoke-Pester -Output Detailed ./tests
```


## Writing Test

Please refer to [the Pester documentation](https://pester.dev/docs/quick-start) on how to write new tests.

Put this snippet at the start of your test file to gain access to the following libray functions:  
(This assumes that your test is at the root of the `tests` directory)

```powershell
BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}
```

- `Install-Distro`: Creates a new NixOS-WSL instance, automatically selecting the appropriate runtime (WSL or Docker) for the host OS. Returns a new `Distro` object
- A Distro object has the following methods:
  - `Launch($command)`: Runs the specified command inside the container. Returns the command output
  - `GetPath($path)`: Returns the path inside the container, that points to the specified file on the host.
  - `InstallConfig($path)`: Installs a nix-file as the systems `configuration.nix`.
  - `Shutdown()`: End all processes running in the container
  - `Uninstall()`: Stop and then delete the container from the system. This should be called in an AfterEach or AfterAll block, so that the test does not leave it on the system.
