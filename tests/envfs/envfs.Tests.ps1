BeforeAll {
  . $PSScriptRoot/../lib/lib.ps1
}

Describe "envfs" {
  BeforeAll {
    $distro = [Distro]::new()
  }

  It "should install" {
    $distro.InstallConfig("$PSScriptRoot/envfs.nix", "switch")
  }

  It "should not break the distro" {
    $distro.Launch("true")
    $LASTEXITCODE | Should -Be 0
  }

  It "should allow running scripts with #!/bin/python3 instead of #!/usr/bin/env python3" {
    $distro.Launch("echo '#!/bin/python3' > ~/test.py")
    $LASTEXITCODE | Should -Be 0

    $distro.Launch("echo print(`"hello`") >> ~/test.py")
    $LASTEXITCODE | Should -Be 0

    $distro.Launch("chmod +x ~/test.py")
    $LASTEXITCODE | Should -Be 0

    $output = $distro.Launch("~/test.py") | Select-Object -Last 1
    $output | Should -BeExactly "hello"
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    $distro.Uninstall()
  }
}
