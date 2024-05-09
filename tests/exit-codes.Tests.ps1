BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Exit Codes" {
  BeforeAll {
    $distro = [Distro]::new()
  }

  It "should return 0 when running true" {
    $distro.Launch("true")
    $LASTEXITCODE | Should -Be 0
  }

  It "should return 1 when running false" {
    $distro.Launch("false")
    $LASTEXITCODE | Should -Be 1
  }

  AfterAll {
    $distro.Uninstall()
  }
}
