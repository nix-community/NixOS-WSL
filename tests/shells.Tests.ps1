BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Shells" {
  BeforeAll {
    $distro = [Distro]::new()

    function Add-ShellTest([string]$package, [string]$executable, [string]$command) {
      $temp = New-TemporaryFile
      @"
        { pkgs, lib, config, options, ... }:
        with lib; {
          imports = [
            <nixos-wsl/modules>
          ];

          config = mkMerge [
            {
              wsl.enable = true;
              users.users.nixos.shell = pkgs.$package;
            }
            (optionalAttrs (hasAttrByPath ["programs" "$package" "enable"] options) {
              programs.$package.enable = true;
            })
          ];
        }
"@ >  $temp
      $distro.InstallConfig($temp, "switch")
      Remove-Item $temp
      $distro.Launch($command) | Select-Object -Last 1 | Should -BeExactly "/run/current-system/sw/bin/$executable"
      $LASTEXITCODE | Should -Be 0
    }
  }

  It "should be possible to use bash" {
    Add-ShellTest "bashInteractive" "bash" "echo `$SHELL"
  }
  It "should be possible to use zsh" {
    Add-ShellTest "zsh" "zsh" "echo `$SHELL"
  }
  It "should be possible to use dash" {
    Add-ShellTest "dash" "dash" "echo `$SHELL"
  }
  It "should be possible to use ksh" {
    Add-ShellTest "ksh" "ksh" "echo `$SHELL"
  }
  It "should be possible to use mksh" {
    Add-ShellTest "mksh" "mksh" "echo `$SHELL"
  }
  It "should be possible to use yash" {
    Add-ShellTest "yash" "yash" "echo `$SHELL"
  }
  It "should be possible to use fish" {
    Add-ShellTest "fish" "fish" "echo `$SHELL"
  }
  It "should be possible to use PowerShell" {
    Add-ShellTest "powershell" "pwsh" "Write-Output `$env:SHELL"
  }
  It "should be possible to use nushell" {
    Add-ShellTest "nushell" "nu" "echo `$env.SHELL"
  }
  It "should be possible to use xonsh" {
    Add-ShellTest "xonsh" "xonsh" "echo `$SHELL"
  }
  # Do bash again so every shell was used to run InstallConfig
  It "should be possible to go back to bash" {
    Add-ShellTest "bashInteractive" "bash" "echo `$SHELL"
  }

  AfterAll {
    $distro.Uninstall()
  }
}
