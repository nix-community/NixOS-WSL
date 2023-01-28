BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Systemd Services" {
  BeforeAll {
    $distro = Install-Distro
  }

  It "should boot" {
    $distro.Launch("true")
    $LASTEXITCODE | Should -Be 0
  }

  It "should not have any failed unit" {
    $output = $distro.Launch("sudo systemctl list-units --failed") | Remove-Escapes
    $output | Where-Object { $_.trim() -ne "" } | Select-Object -Last 1 | Should -BeExactly "0 loaded units listed."
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    $distro.Uninstall()
  }
}
