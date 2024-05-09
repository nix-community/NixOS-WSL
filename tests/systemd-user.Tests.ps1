BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Systemd User Daemon" {
  BeforeAll {
    $distro = [Distro]::new()
  }

  It "should be possible to connect to the user daemon" {
    # Boot the distro
    $distro.Launch("true")
    Start-Sleep 10 # Give the user daemon time to start

    $distro.Launch("systemctl --user status --no-pager")
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    $distro.Uninstall()
  }
}
