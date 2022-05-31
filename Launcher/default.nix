{ pkgs ? import <nixpkgs> { }
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib
, writeText ? pkgs.writeText
, dotnet-sdk ? pkgs.dotnet-sdk
, dotnetPackages ? pkgs.dotnetPackages
, fetchurl ? pkgs.fetchurl
, linkFarmFromDrvs ? pkgs.linkFarmFromDrvs
}:

let
  fetchNuGet = { pname, version, sha256 }: fetchurl {
    name = "${pname}-${version}.nupkg";
    url = "https://www.nuget.org/api/v2/package/${pname}/${version}";
    inherit sha256;
  };
in
stdenv.mkDerivation rec {
  name = "NixOS-WSL-Launcher";

  src = ./.;

  nativeBuildInputs = [
    dotnet-sdk
    dotnetPackages.Nuget
  ];

  nugetDeps = linkFarmFromDrvs "${name}-nuget-deps" (map fetchNuGet [
    { pname = "Microsoft.AspNetCore.App.Runtime.win-x64"; version = "6.0.0"; sha256 = "dacDLzjHNLXHIWdq+cBbXOfPpiqgHsWOp8cwrk+yDMk="; }
    { pname = "Microsoft.NETCore.App.Host.win-x64"; version = "6.0.0"; sha256 = "3c1kDGpCrwlX858lyoE+u0fgmRgRwN692KqRN0ejJoA="; }
    { pname = "Microsoft.NETCore.App.Runtime.win-x64"; version = "6.0.0"; sha256 = "RpVKg/7oiOSbPBNFgn1kt/+a55GRqv5QXtAO/+K0oY8="; }
    { pname = "System.CommandLine"; version = "2.0.0-beta3.22114.1"; sha256 = "lcqMVesbt2E189e6KfG8HVmJc3hjo2ht48WnH1UaMkY="; }
  ]);

  unpackPhase = ''
    cp -r --no-preserve=mode $src/. .
  '';

  configurePhase = ''
    runHook preConfigure

    mkdir .home
    export HOME=$PWD/.home

    export DOTNET_NOLOGO=1
    export DOTNET_CLI_TELEMETRY_OPTOUT=1

    dotnet nuget disable source nuget.org
    nuget sources Add -Name nix -Source "$PWD/nix"
    nuget init "$nugetDeps" "$PWD/nix"

    mkdir -p $HOME/.nuget/NuGet
    cp $HOME/.config/NuGet/NuGet.Config $HOME/.nuget/NuGet

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    mkdir -p $out

    dotnet publish \
      --self-contained \
      -p:ContinuousIntegrationBuild=true \
      -p:Deterministic=true \
      --packages "$HOME/nuget_pkgs" \
      -r win-x64 \
      -c Release \
      --output $out/bin \
      Launcher

    runHook postBuild
  '';

  dontInstall = true;

  dontStrip = true; # strip breaks the assemblies

  meta = with lib; {
    description = "WSL Distribution Launcher for NixOS-WSL";
    homepage = "https://github.com/nix-community/NixOS-WSL";
    license = licenses.asl20;
    maintainers = with maintainers; [ nzbr ];
    platforms = [ "x86_64-linux" "x86_64-windows" ];
  };
}
