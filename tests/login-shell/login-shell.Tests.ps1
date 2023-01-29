BeforeAll {
  . $PSScriptRoot/../lib/lib.ps1
}

Describe "Login Shell" {
  BeforeAll {
    $distro = Install-Distro
  }

  It "should start commands in a login shell" {
    $distro.Launch("shopt -q login_shell")
    $LASTEXITCODE | Should -Be 0
  }

  It "should be possible to access home manager sessionVariables" {
    $distro.InstallConfig("$PSScriptRoot/session-variables.nix")
    $distro.Launch("echo \`$TEST_VARIABLE") | Select-Object -Last 1 | Should -BeExactly "THISISATESTSTRING"
    $distro.Launch("echo \`$EDITOR") | Select-Object -Last 1 | Should -BeExactly "vim"
  }

  AfterAll {
    $distro.Uninstall()
  }
}
