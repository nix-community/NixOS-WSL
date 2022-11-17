$hostMount = "/mnt/c"
$imageName = "local:nixos-wsl"

# Check if a fresh tarball exists in result, otherwise try one in the current directory
$tarball = "./result/tarball/nixos-wsl-installer.tar.gz"
if (!(Test-Path $tarball)) {
  $tarball = "./nixos-wsl-installer.tar.gz"
  if (!(Test-Path $tarball)) {
    throw "Could not find the installer tarball! Run nix build first, or place one in the current directory."
  }
}
Write-Host "Using tarball: $tarball"

# Build docker image from the installer tarball
$tmpdir = $(mktemp -d)
Copy-Item $PSScriptRoot/Dockerfile $tmpdir
Copy-Item $tarball $tmpdir
docker build -t $imageName $tmpdir | Write-Host
Remove-Item $tmpdir -Recurse -Force

function WSL-Install() {
  $id = [guid]::NewGuid().ToString()

  # Spawn a new docker container
  docker run -di --privileged --init --volume /:$hostMount --name $id $imageName /bin/sh | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to launch container"
  }

  return $id
}

function WSL-Launch([string]$id, [string]$command) {
  docker exec -t $id /nix/nixos-wsl/entrypoint -c "$command" | Tee-Object -Variable result | Write-Host
  return $result
}

# $id isn't needed here, but it is on Windows
function WSL-Path([string]$id, [string]$path) {
  return $hostMount + $(readlink -f $path)
}

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
}
