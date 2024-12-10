BeforeAll {
  . $PSScriptRoot/../lib/lib.ps1
}

Describe "Slow Activation Script" {
  BeforeAll {
    $distro = [Distro]::new()
  }

  It "should not cause starting a shell to fail" {
    $distro.InstallConfig("$PSScriptRoot/delay-activation.nix", "boot")
    $distro.Shutdown()

    $distro.Launch("echo 'TEST'") | Select-Object -Last 1 | Tee-Object -Variable output
    $output | Should -BeExactly "TEST"
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    $distro.Uninstall()
  }
}
