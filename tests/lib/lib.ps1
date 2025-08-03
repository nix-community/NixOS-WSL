if ($PSVersionTable.PSEdition -ne 'Core') {
  throw "The tests are not compatible with Windows PowerShell, please use PowerShell Core instead"
}
if ($IsWindows -eq $false) {
  throw "Support for tests in an emulated WSL environment on Linux has been removed"
}

function Remove-Escapes {
  param(
    [parameter(ValueFromPipeline = $true)]
    [string[]]$InputObject
  )
  process {
    $InputObject | ForEach-Object { $_ -replace '\x1b(\[(\?..|.)|.)', '' }
  }
}

class Distro {
  [string]$id
  [string]$tempdir

  Distro() {
    $tarball = $this.FindTarball()

    $this.id = $(New-Guid).ToString()
    $this.tempdir = Join-Path $([System.IO.Path]::GetTempPath()) $this.id
    New-Item -ItemType Directory $this.tempdir

    & wsl.exe --import $this.id $this.tempdir $tarball --version 2 | Write-Host
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to import distro"
    }
    & wsl.exe --list -q | Should -Contain $this.id
  }

  [Array]Launch([string]$command) {
    Write-Host "> $command"
    $result = @()
    Invoke-Expression "wsl.exe -d $($this.id) --% $command" | Tee-Object -Variable result | Write-Host
    return $result | Remove-Escapes
  }

  [string]GetPath([string]$path) {
    return $this.Launch("wslpath $($path -replace "\\", "/")") | Select-Object -Last 1
  }

  [string]FindTarball() {
    # Check if a fresh tarball exists in result, otherwise try one in the current directory
    $tarball = "./nixos.wsl"
    if (!(Test-Path $tarball)) {
      throw "Could not find the tarball! Run nix build first, or place one in the current directory."
    }
    Write-Host "Using tarball: $tarball"
    return $tarball
  }

  [void]InstallConfig([string]$path, [string]$operation) {
    Write-Host "Installing config: $path"

    # Copy the new config
    $this.Launch("sudo cp -v $($this.GetPath($path)) /etc/nixos/configuration.nix")
    $LASTEXITCODE | Should -Be 0

    # Rebuild
    $this.Launch("sh -c 'sudo nixos-rebuild $operation < /dev/null'")
    $LASTEXITCODE | Should -Be 0

    Write-Host "Config installed successfully"
  }

  [void]Shutdown() {
    Write-Host "> [shutdown]"
    & wsl.exe -t $this.id
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to stop distro"
    }
  }

  [void]Uninstall() {
    & wsl.exe --unregister $this.id | Write-Host
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to unregister distro"
    }
    if (Test-Path $this.tempdir) {
      Remove-Item $this.tempdir -Recurse -Force
    }
  }
}
