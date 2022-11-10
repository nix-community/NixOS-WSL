. $PSScriptRoot/lib/lib.ps1

$id = WSL-Install

try {

  # Run command through installer
  WSL-Launch $id "nixos-version"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to run a command through the installer"
  }
  # Run another command after the installer is done
  WSL-Launch $id "true"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to run a second command"
  }

  # Restart the container and run a command
  WSL-Shutdown $id
  WSL-Launch $id "true"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to run command after restart"
  }

  # nixos-rebuild works
  WSL-Launch $id "sudo nixos-rebuild switch"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to run nixos-rebuild"
  }

  # nix-shell works
  WSL-Launch $id "nix-shell -p neofetch --command neofetch"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to run a command through nix-shell"
  }

  # nix run works
  WSL-Launch $id "nix run nixpkgs#neofetch"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to run a command through nix run"
  }

}
finally {
  WSL-Uninstall($id)
}
