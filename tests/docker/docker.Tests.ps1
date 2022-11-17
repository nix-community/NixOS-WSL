. $PSScriptRoot/../lib/lib.ps1

Describe "Docker (native)" {
  BeforeAll {
    $id = WSL-Install
    WSL-InstallConfig $id $PSScriptRoot/docker-native.nix
  }

  It "should be possible to run a docker container" {
    WSL-Launch $id "docker run --rm -it hello-world"
    $LASTEXITCODE | Should -Be 0
  }

  It "should still be possible to run a docker container after a restart" {
    WSL-Shutdown $id
    WSL-Launch $id "docker run --rm -it hello-world"
    $LASTEXITCODE | Should -Be 0
  }

  It "should be possible to connect to the internet from a container" {
    WSL-Launch $id "docker run --rm -it alpine wget -qO- http://www.msftconnecttest.com/connecttest.txt" | Select-Object -Last 1 | Should -BeExactly "Microsoft Connect Test"
    $LASTEXITCODE | Should -Be 0
  }

  It "should be possible to mount a volume from the host" {
    $teststring = [guid]::NewGuid().ToString()

    $testdir = WSL-Launch $id "mktemp -d"
    $testfile = $testdir + "/testfile"
    WSL-Launch $id "echo $teststring > $testfile"
    WSL-Launch $id "docker run --rm -it -v ${testdir}:/mnt alpine cat /mnt/testfile" | Should -BeExactly $teststring
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    WSL-Uninstall $id
  }
}
