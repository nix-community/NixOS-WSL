BeforeAll {
  . $PSScriptRoot/lib/lib.ps1
}

Describe "Extra Files" {
  BeforeAll {
    $distro = [Distro]::new()
    $tmpdir = New-TemporaryFile
    Remove-Item $tmpdir
    $tmpdir = New-Item -ItemType Directory -Path $tmpdir.FullName
    $tarball = "$tmpdir/nixos.wsl"
    $Global:distroWithExtras = $null
  }

  It "should be possible to build a tarball with extra files" {
    $distro.Launch("nix-build -A config.system.build.tarballBuilder '<nixpkgs/nixos>'")

    $distro.Launch("mkdir -p extra-files/root")
    $distro.Launch("mkdir -p extra-files/home/nixos")
    $distro.Launch("echo 'extra' > extra-files/root/extra-file")
    $distro.Launch("echo 'extra' > extra-files/home/nixos/extra-file")

    $distro.Launch("sudo ./result/bin/nixos-wsl-tarball-builder --extra-files extra-files --chown /home/nixos/extra-file 1000:100 $($distro.GetPath($tarball))")

    $tarball | Should -Exist
  }

  It "should be possible to import the tarball" {
    $tarball | Should -Exist
    Write-Host $tarball
    $Global:distroWithExtras = [Distro]::new($tarball)
  }

  It "should be possible to read the extra files in the new installation" {
    $Global:distroWithExtras.Launch("cat /home/nixos/extra-file") | Select-Object -Last 1 | Should -BeExactly "extra"

    $Global:distroWithExtras.Launch("cat /root/extra-file")
    $LASTEXITCODE | Should -Not -Be 0
    $Global:distroWithExtras.Launch("sudo cat /root/extra-file") | Select-Object -Last 1 | Should -BeExactly "extra"
  }

  AfterAll {
    $distro.Uninstall()
    if (Test-Path $tmpdir) {
      Remove-Item -Recurse $tmpdir
    }
    if ($Global:distroWithExtras -ne $null) {
      $Global:distroWithExtras.Uninstall()
    }
  }
}
