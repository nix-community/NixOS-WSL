BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Shells" {
  BeforeAll {
    $distro = Install-Distro

    function Add-ShellTest([string]$package, [string]$executable) {
      $temp = New-TemporaryFile
      @"
{ pkgs, config, ... }:
{
imports = [ ./base.nix ];

users.users.`${config.wsl.defaultUser}.shell = pkgs.$package;
}
"@ > $temp
      $distro.InstallConfig($temp)
      Remove-Item $temp
      $distro.Launch("echo `$SHELL") | Select-Object -Last 1 | Should -BeExactly "/run/current-system/sw/bin/$executable"
      $LASTEXITCODE | Should -Be 0
    }
  }

  It "should be possible to use zsh" {
    Add-ShellTest "zsh" "zsh"
  }
  It "should be possible to use fish" {
    Add-ShellTest "fish" "fish"
  }
  It "should be possible to use PowerShell" {
    Add-ShellTest "powershell" "pwsh"
  }
  It "should be possible to use nushell" {
    Add-ShellTest "nushell" "nu"
  }
  It "should be possible to use xonsh" {
    Add-ShellTest "xonsh" "xonsh"
  }
  # Do bash last so every shell was used to run InstallConfig
  It "should be possible to use bash" {
    Add-ShellTest "bashInteractive" "bash"
  }

  AfterAll {
    $distro.Uninstall()
  }
}
