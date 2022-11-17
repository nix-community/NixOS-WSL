. $PSScriptRoot/lib/lib.ps1

Describe "Systemd User Daemon" {
  BeforeAll {
    $id = WSL-Install
  }

  It "should be possible to connect to the user daemon" {
    WSL-Launch $id "systemctl --user status --no-pager"
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    WSL-Uninstall $id
  }
}
