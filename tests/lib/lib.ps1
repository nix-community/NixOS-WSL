BeforeAll {
  if ($IsWindows) {
    . $PSScriptRoot/init_windows.ps1
  }
  else {
    . $PSScriptRoot/init_linux.ps1
  }
}
