. $PSScriptRoot/lib/lib.ps1

$id = WSL-Install

try {
    WSL-Launch $id "nixos-version"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to run nixos-version inside the container"
    }

    # TODO: WSL-Shutdown
}
finally {
    WSL-Uninstall($id)
}
