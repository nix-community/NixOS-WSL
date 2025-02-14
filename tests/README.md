# Tests

This directory contains tests that are executed against a built NixOS-WSL tarball.
The tests are written using the [Pester](https://pester.dev/) testing framework.

## Execute Tests

The tests can only be executed on Windows. Support for running the tests in an emulated WSL environment through docker has been removed.

Make sure that you are able to run a distro in WSL2 before trying to run the tests.
Please note that the tests are not compatible with Windows PowerShell, but require the new [PowerShell Core](https://apps.microsoft.com/store/detail/powershell/9MZ1SNWT0N5D?hl=en-us&gl=us).

### Running the Tests

If you haven't already, [install Pester](https://pester.dev/docs/introduction/installation/).  
The tests require a "default" `nixos.wsl` to be present in the current working directory, which can be built with
`sudo nix run .#nixosConfigurations.default.config.system.build.tarballBuilder -- nixos.wsl`.

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

- `[Distro]::new()`: Creates a new NixOS-WSL instance.
- A Distro object has the following methods:
  - `Launch($command)`: Runs the specified command inside the distro. Returns the command output
  - `GetPath($path)`: Returns the path inside the distro, that points to the specified file on the host.
  - `InstallConfig($path, $operation)`: Installs a nix-file as the systems `configuration.nix`. Operation is one of the supported operations of `nixos-rebuild` 
  - `Shutdown()`: End all processes running in the distro
  - `Uninstall()`: Stop and then delete the distro from the system. This should be called in an AfterEach or AfterAll block, so that the test does not leave it on the system.
