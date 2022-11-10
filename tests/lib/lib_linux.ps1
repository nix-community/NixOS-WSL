function WSL-Install() {
  $id = [guid]::NewGuid().ToString()

  # Build docker image from the provided tarball
  $tmpdir = $(mktemp -d)
  Copy-Item $PSScriptRoot/Dockerfile $tmpdir
  Copy-Item nixos-wsl-installer.tar.gz $tmpdir
  docker build -t nixos-wsl:$id $tmpdir | Write-Host
  Remove-Item $tmpdir -Recurse -Force

  # Spawn a new docker container
  docker run -di --privileged --init --name $id nixos-wsl:$id /bin/sh | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to launch container"
  }

  return $id
}

function WSL-Launch([string]$id, [string]$command) {
  docker exec -t $id /nix/nixos-wsl/entrypoint -c "$command"
}

# TODO: WSL-CopyFile

function WSL-Shutdown([string]$id) {
  docker restart $id # Restart instead of stop so that exec can still be used
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to stop container"
  }
}

function WSL-Uninstall([string]$id) {
  docker rm -f $id
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to remove container"
  }
  docker rmi nixos-wsl:$id
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to remove image"
  }
}
