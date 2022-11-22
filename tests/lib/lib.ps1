class Distro {
  [string]$id

  [string]Launch() {
    throw "Not implemented"
  }

  [string]GetPath([string]$path) {
    throw "Not implemented"
  }

  [void]InstallConfig([string]$path) {
    Write-Host "Installing config: $path"

    # Move config out of the way
    $this.Launch("/bin/sh -c 'test -f /etc/nixos/base.nix || sudo mv /etc/nixos/configuration.nix /etc/nixos/base.nix'")
    $LASTEXITCODE | Should -Be 0

    # Copy the new config
    $this.Launch("sudo cp $($this.GetPath($path)) /etc/nixos/configuration.nix")
    $LASTEXITCODE | Should -Be 0

    # Rebuild
    $this.Launch("sudo nixos-rebuild switch")
    $LASTEXITCODE | Should -Be 0

    Write-Host "Config installed successfully"
  }

  [void]Shutdown() {
    throw "Not implemented"
  }

  [void]Uninstall() {
    throw "Not implemented"
  }
}

class DockerDistro : Distro {
  static [string]$hostMount = "/mnt/c"
  static [string]$imageName = "local:nixos-wsl"

  static [bool]$imageCreated = $false
  [string]$id

  DockerDistro() {
    if (!([DockerDistro]::imageCreated)) {
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
      docker build -t $([DockerDistro]::imageName) $tmpdir | Write-Host
      Remove-Item $tmpdir -Recurse -Force

      [DockerDistro]::imageCreated = $true
    }

    $this.id = [guid]::NewGuid().ToString()

    docker run -di --privileged --volume "/:$([DockerDistro]::hostMount)" --name $this.id $([DockerDistro]::imageName) "/bin/sh" | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to launch container"
    }
  }

  [Array]Launch([string]$command) {
    $result = @()
    docker exec -t $this.id /nix/nixos-wsl/entrypoint -c $command | Tee-Object -Variable result | Write-Host
    return $result
  }

  [string]GetPath([string]$path) {
    return [DockerDistro]::hostMount + $(readlink -f $path)
  }

  [void]Shutdown() {
    docker restart $this.id # Restart instead of stop so that exec can still be used
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to stop container"
    }
  }

  [void]Uninstall() {
    docker rm -f $this.id
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to remove container"
    }
  }
}

function Install-Distro() {
  if ($IsWindows) {

  }
  else {
    return [DockerDistro]::new()
  }
}
