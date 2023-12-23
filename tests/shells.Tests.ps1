BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Shells" {
  BeforeAll {
    $distro = Install-Distro

    function Add-ShellTest([string]$package, [string]$executable) {
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
              wsl.nativeSystemd = false;
              users.users.nixos.shell = pkgs.$package;
            }
            (optionalAttrs (hasAttrByPath ["programs" "$package" "enable"] options) {
              programs.$package.enable = true;
            })
          ];
        }
"@ >  $temp
      $distro.InstallConfig($temp)
      Remove-Item $temp
      $distro.Launch("echo `$SHELL") | Select-Object -Last 1 | Should -BeExactly "/run/current-system/sw/bin/$executable"
      $LASTEXITCODE | Should -Be 0
    }
  }

  It "should be possible to use bash" {
    Add-ShellTest "bashInteractive" "bash"
  }
  It "should be possible to use zsh" {
    Add-ShellTest "zsh" "zsh"
  }
  It "should be possible to use dash" {
    Add-ShellTest "dash" "dash"
  }
  It "should be possible to use ksh" {
    Add-ShellTest "ksh" "ksh"
  }
  It "should be possible to use mksh" {
    Add-ShellTest "mksh" "mksh"
  }
  It "should be possible to use yash" {
    Add-ShellTest "yash" "yash"
  }
  It "should be possible to use fish" {
    Add-ShellTest "fish" "fish"
  }
  if (!$IsWindows) {
    # Skip on windows, because it just doesn't work for some reason
    It "should be possible to use PowerShell" {
      Add-ShellTest "powershell" "pwsh"
    }
  }
  It "should be possible to use nushell" {
    $distro.Launch("mkdir -p /home/nixos/.config/nushell")
    $LASTEXITCODE | Should -Be 0
    $distro.Launch("touch /home/nixos/.config/nushell/env.nu /home/nixos/.config/nushell/config.nu")
    $LASTEXITCODE | Should -Be 0
    Add-ShellTest "nushell" "nu"
  }
  It "should be possible to use xonsh" {
    Add-ShellTest "xonsh" "xonsh"
  }
  # Do bash last so every shell was used to run InstallConfig
  It "should be possible to go back to bash" {
    Add-ShellTest "bashInteractive" "bash"
  }

  AfterAll {
    $distro.Uninstall()
  }
}
