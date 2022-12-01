BeforeAll {
  . $PSScriptRoot/../lib/lib.ps1
}

Describe "Docker (native)" {
  BeforeAll {
    $distro = Install-Distro
    try {
      $distro.InstallConfig("$PSScriptRoot/docker-native.nix")
    }
    catch {
      $distro.Launch("sudo journalctl --no-pager -u docker.service")
      throw $_
    }
  }

  It "should be possible to run a docker container" {
    $distro.Launch("docker run --rm -it hello-world")
    $LASTEXITCODE | Should -Be 0
  }

  It "should still be possible to run a docker container after a restart" {
    $distro.Shutdown()
    $distro.Launch("docker run --rm -it hello-world")
    $LASTEXITCODE | Should -Be 0
  }

  It "should be possible to connect to the internet from a container" {
    $distro.Launch("docker run --rm -it alpine wget -qO- http://www.msftconnecttest.com/connecttest.txt") | Select-Object -Last 1 | Should -BeExactly "Microsoft Connect Test"
    # docker exec -it $distro.id /nix/nixos-wsl/entrypoint -c "docker run --rm -it alpine wget -qO- http://www.msftconnecttest.com/connecttest.txt" | Select-Object -Last 1 | Should -BeExactly "Microsoft Connect Test"
    $LASTEXITCODE | Should -Be 0
  }

  It "should be possible to mount a volume from the host" {
    $teststring = [guid]::NewGuid().ToString()

    $testdir = $distro.Launch("mktemp -d") | Select-Object -Last 1
    $testfilename = "testfile"
    $testfile = "${testdir}/${testfilename}"
    $distro.Launch("echo $teststring > $testfile")
    $distro.Launch("docker run --rm -it -v ${testdir}:/mnt alpine cat /mnt/${testfilename}") | Select-Object -Last 1 | Should -BeExactly $teststring
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    $distro.Uninstall()
  }
}
