. $PSScriptRoot/lib/lib.ps1

Describe "Basic Functionality" {
  BeforeAll {
    $id = WSL-Install
  }

  It "is possible to run a command through the installer" {
    WSL-Launch $id "nixos-version"
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a second command" {
    WSL-Launch $id "true"
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command after restarting the container" {
    WSL-Shutdown $id
    WSL-Launch $id "true"
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to use nixos-rebuild" {
    WSL-Launch $id "sudo nixos-rebuild switch"
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command through nix-shell" {
    WSL-Launch $id "nix-shell -p neofetch --command neofetch"
    $LASTEXITCODE | Should -Be 0
  }

  It "is possible to run a command through nix run" {
    WSL-Launch $id "nix run nixpkgs#neofetch"
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    WSL-Uninstall $id
  }
}
