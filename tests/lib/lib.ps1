BeforeAll {
  if ($IsWindows) {
    . $PSScriptRoot/init_windows.ps1
  }
  else {
    . $PSScriptRoot/init_linux.ps1
  }

  function WSL-InstallConfig([string]$id, [string]$path) {
    Write-Host "Installing config: $path"
    WSL-Launch $id "sudo mv /etc/nixos/configuration.nix /etc/nixos/base.nix"
    $LASTEXITCODE | Should -Be 0
    WSL-Launch $id "sudo cp $(WSL-Path $id $path) /etc/nixos/configuration.nix"
    $LASTEXITCODE | Should -Be 0
    WSL-Launch $id "sudo nixos-rebuild switch"
    $LASTEXITCODE | Should -Be 0
    Write-Host "Config installed successfully"
    return $result
  }
}
