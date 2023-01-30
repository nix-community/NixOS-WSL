BeforeAll {
  . $PSScriptRoot/../lib/lib.ps1
}

Describe "Login Shell" {
  BeforeAll {
    $distro = Install-Distro
  }

  It "should be possible to change the username" {
    $distro.Launch("whoami") | Select-Object -Last 1 | Should -BeExactly "nixos"
    $distro.InstallConfig("$PSScriptRoot/username-change.nix")
    $distro.Launch("whoami") | Select-Object -Last 1 | Should -BeExactly "different-name"
  }

  AfterAll {
    $distro.Uninstall()
  }
}
