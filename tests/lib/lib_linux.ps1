function WSL-Install() {
    # Build docker image from the provided tarball
    $tmpdir = $(mktemp -d)
    Copy-Item $PSScriptRoot/Dockerfile $tmpdir
    Copy-Item nixos-wsl-installer.tar.gz $tmpdir
    docker build -t local:nixos-wsl $tmpdir | Write-Host
    Remove-Item $tmpdir -Recurse -Force

    # Spawn a new docker container
    $id = docker run -di --privileged --init local:nixos-wsl /bin/sh
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to launch docker container"
    }

    return $id
}

function WSL-Launch([string]$id, [string]$command) {
    docker exec -t $id /nix/nixos-wsl/entrypoint -c "$command"
}

function WSL-Uninstall([string]$id) {
    docker rm -f $id
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to remove docker container"
    }
}
