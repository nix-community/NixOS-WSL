BeforeAll {
  . $PSScriptRoot/../lib/lib.ps1
}

Describe "Login Shell" {
  BeforeAll {
    $distro = [Distro]::new()
  }

  It "should be possible to change the username" {
    $distro.Launch("whoami") | Select-Object -Last 1 | Should -BeExactly "nixos"
    $config = "$PSScriptRoot/username-change.nix"

    # Copy the new config
    $distro.Launch("sudo cp -v $($distro.GetPath($config)) /etc/nixos/configuration.nix")
    $LASTEXITCODE | Should -Be 0

    # Rebuild (boot not switch!)
    $distro.Launch("sh -c 'sudo nixos-rebuild boot < /dev/null'")
    $LASTEXITCODE | Should -Be 0

    # Shutdown
    $distro.Shutdown()

    # Run the activation scripts once
    wsl -d $distro.id --user root exit
    $distro.Shutdown()

    $distro.Launch("whoami") | Select-Object -Last 1 | Should -BeExactly "different-name"
  }

  AfterAll {
    $distro.Uninstall()
  }
}
