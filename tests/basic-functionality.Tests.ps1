BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Basic Functionality" {
  BeforeAll {
    $distro = Install-Distro
  }

  It "is possible to run a command initially" {
    $distro.Launch("nixos-version")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a second command" {
    $distro.Launch("true")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command through sudo" {
    $distro.Launch("sudo whoami") | Select-Object -Last 1 | Should -BeExactly "root"
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command after restarting the container" {
    $distro.Shutdown()
    $distro.Launch("true")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to use nixos-rebuild" {
    $temp = New-TemporaryFile
    @"
      { pkgs, config, ... }:
      {
      imports = [ ./base.nix ];

      environment.systemPackages = with pkgs; [ hello ];
      }
"@ >  $temp
    $distro.InstallConfig($temp)
    Remove-Item $temp
    $distro.Launch("sudo nixos-rebuild switch")
    $LASTEXITCODE | Should -Be 0
  }

  It "should have created a new generation" {
    $distro.Launch("test -L /nix/var/nix/profiles/system-2-link")
    $LASTEXITCODE | Should -Be 0
  }

  It "should be possible to run a command installed with the rebuild" {
    $distro.Launch("hello")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command through nix-shell" {
    $distro.Launch("nix-shell -p neofetch --command neofetch")
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command through nix run" {
    $distro.Launch("nix run nixpkgs#neofetch")
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    $distro.Uninstall()
  }
}
