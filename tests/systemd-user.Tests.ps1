BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Systemd User Daemon" {
  BeforeAll {
    $distro = Install-Distro
  }

  It "should be possible to connect to the user daemon" {
    $distro.Launch("systemctl --user status --no-pager")
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    $distro.Uninstall()
  }
}
