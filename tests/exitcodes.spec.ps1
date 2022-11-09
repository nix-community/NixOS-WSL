. $PSScriptRoot/lib/lib.ps1

$id = WSL-Install

try {
    WSL-Launch $id "true"
    if ($LASTEXITCODE -ne 0) {
        throw "Command that should succeed failed"
    }

    WSL-Launch $id "false"
    if ($LASTEXITCODE -eq 0) {
        throw "Command that should fail succeeded"
    }
}
finally {
    WSL-Uninstall($id)
}

