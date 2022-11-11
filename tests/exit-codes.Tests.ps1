. $PSScriptRoot/lib/lib.ps1

Describe "Exit Codes" {
  BeforeAll {
    $id = WSL-Install
  }

  It "should return 0 when running true" {
    WSL-Launch $id "true"
    $LASTEXITCODE | Should -Be 0
  }

  It "should return 1 when running false" {
    WSL-Launch $id "false"
    $LASTEXITCODE | Should -Be 1
  }

  AfterAll {
    WSL-Uninstall $id
  }
}
