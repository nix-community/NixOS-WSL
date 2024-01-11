{ runCommand
, dotnet-sdk
, ...
}:
runCommand "check-dotnet-format" { nativeBuildInputs = [ dotnet-sdk ]; } ''
  cd "${./../Launcher}"
  dotnet format --verbosity detailed --no-restore --verify-no-changes && touch $out
''
