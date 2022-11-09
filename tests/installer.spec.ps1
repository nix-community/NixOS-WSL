# Import lib
. $PSScriptRoot/lib/lib.ps1

$id = WSL-Install

WSL-Launch $id "nixos-version"

WSL-Uninstall($id)

