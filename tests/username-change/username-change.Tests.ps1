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

    # Install config with new username (boot, not switch!)
    $distro.InstallConfig($config, "boot")

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
