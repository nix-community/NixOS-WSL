{ pkgs ? import <nixpkgs> { }
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib
, dotnet-sdk ? pkgs.dotnet-sdk
, dotnetPackages ? pkgs.dotnetPackages
, fetchurl ? pkgs.fetchurl
, linkFarmFromDrvs ? pkgs.linkFarmFromDrvs
}:

let
  fetchNuGet = { pname, version, hash }: fetchurl {
    name = "${pname}-${version}.nupkg";
    url = "https://www.nuget.org/api/v2/package/${pname}/${version}";
    inherit hash;
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
    { pname = "Microsoft.AspNetCore.App.Runtime.win-x64"; version = "6.0.25"; hash = "sha256-njOrSWL+YJJvnywJ0clMzYdaANYl3rcVaZeZAki1erk="; }
    { pname = "Microsoft.AspNetCore.App.Runtime.win-arm64"; version = "6.0.25"; hash = "sha256-Jnt9WIxGvvejtBW5mjWCXlYmsUj6fxVI4Xs3WWsr8YE="; }
    { pname = "Microsoft.NETCore.App.Host.win-x64"; version = "6.0.25"; hash = "sha256-ATiO6e8xcDPrRngmT9k//7Z2Mx07hJhxgmdwUvMYJA0="; }
    { pname = "Microsoft.NETCore.App.Host.win-arm64"; version = "6.0.25"; hash = "sha256-xvj8CZHY4PyXKroniWj0JIoksKf4pcbberfMf5XZYaE="; }
    { pname = "Microsoft.NETCore.App.Runtime.win-x64"; version = "6.0.25"; hash = "sha256-Lk6cn0cSQVp4QVf6IznE7UnZ9tYxZmRMYrsTIHq9Vg8="; }
    { pname = "Microsoft.NETCore.App.Runtime.win-arm64"; version = "6.0.25"; hash = "sha256-eCoXKCHkrteypFVOUctV3ReQk/lFjJ7cI/CVk2tNrZY="; }
    { pname = "System.CommandLine"; version = "2.0.0-beta3.22114.1"; hash = "sha256-lcqMVesbt2E189e6KfG8HVmJc3hjo2ht48WnH1UaMkY="; }
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

    nuget sources Add -Name nix -Source "$PWD/nix"
    nuget init "$nugetDeps" "$PWD/nix"
    dotnet nuget disable source nuget.org

    mkdir -p $HOME/.nuget/NuGet
    cp $HOME/.config/NuGet/NuGet.Config $HOME/.nuget/NuGet

    dotnet restore --ignore-failed-sources

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    mkdir -p $out

    ${lib.concatStringsSep "\n" (
      map (runtime: ''
        dotnet publish \
        --self-contained \
        -p:ContinuousIntegrationBuild=true \
        -p:Deterministic=true \
        --packages "$HOME/nuget_pkgs" \
        -r ${runtime} \
        -c Release \
        --output $out/${runtime} \
        Launcher
      '') [ "win-x64" "win-arm64" ]
    )}

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
