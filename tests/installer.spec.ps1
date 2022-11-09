. $PSScriptRoot/lib/lib.ps1

$id = WSL-Install

try {
    WSL-Launch $id "nixos-version"
}
finally {
    WSL-Uninstall($id)
}
