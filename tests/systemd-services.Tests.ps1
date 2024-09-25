BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Systemd Services" {
  BeforeAll {
    $distro = [Distro]::new()
  }

  It "should boot" {
    $output = $distro.Launch("systemctl is-system-running") | Remove-Escapes
    $LASTEXITCODE | Should -Be 0
    $output | Should -BeExactly "running"
  }

  It "should not have any failed unit" {
    $output = $distro.Launch("sudo systemctl list-units --failed") | Remove-Escapes
    $LASTEXITCODE | Should -Be 0
    $output | Where-Object { $_.trim() -ne "" } | Select-Object -Last 1 | Should -BeExactly "0 loaded units listed."
  }

  It "should not have any systemd-analyze verify warnings" {
    $output = $distro.Launch("sudo systemd-analyze verify multi-user.target --no-pager 2>&1") | Remove-Escapes
    $LASTEXITCODE | Should -Be 0
    $output | Should -BeExactly ""
  }

  AfterAll {
    $distro.Uninstall()
  }
}
