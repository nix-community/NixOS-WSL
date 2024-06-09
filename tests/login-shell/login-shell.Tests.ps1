BeforeAll {
  . $PSScriptRoot/../lib/lib.ps1
}

Describe "Login Shell" {
  BeforeAll {
    $distro = [Distro]::new()
  }

  It "should start commands in a login shell" {
    # The echo should eat the \r PowerShell appends to stdin
    Write-Host "> shopt login_shell"
    Write-Output "shopt login_shell`necho " | wsl -d $distro.id | Tee-Object -Variable output | Write-Host
    $output | Select-Object -Index ($output.Length - 2) | Should -Match "login_shell\s*on"
  }

  It "should be possible to access home manager sessionVariables" {
    $distro.InstallConfig("$PSScriptRoot/session-variables.nix")

    # Session variable file should exist
    $distro.Launch("test -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh")
    $LASTEXITCODE | Should -Be 0

    Write-Host "> echo `$TEST_VARIABLE"
    Write-Output "echo `$TEST_VARIABLE" | wsl -d $distro.id | Tee-Object -Variable output | Write-Host
    $output | Select-Object -Last 1 | Should -BeExactly "THISISATESTSTRING"

    Write-Host "> echo `$EDITOR"
    Write-Output "echo `$EDITOR" | wsl -d $distro.id | Tee-Object -Variable output | Write-Host
    $output | Select-Object -Last 1 | Should -BeExactly "vim"
  }

  AfterAll {
    $distro.Uninstall()
  }
}
