#! /usr/bin/env pwsh

#Requires -PSEdition Core
#Requires -Version 7

param(
    [Parameter(Mandatory = $false)][switch] $SkipTests,
    [Parameter(Mandatory = $false)][switch] $EnableIntegrationTests
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if ($null -eq $env:MSBUILDTERMINALLOGGER) {
    $env:MSBUILDTERMINALLOGGER = "auto"
}

$solutionPath = $PSScriptRoot
$sdkFile = Join-Path $solutionPath "global.json"

$libraryProjects = @(
    (Join-Path $solutionPath "src" "JustSaying" "JustSaying.csproj"),
    (Join-Path $solutionPath "src" "JustSaying.Models" "JustSaying.Models.csproj"),
    (Join-Path $solutionPath "src" "JustSaying.Extensions.Aws" "JustSaying.Extensions.Aws.csproj"),
    (Join-Path $solutionPath "src" "JustSaying.Extensions.DependencyInjection.Microsoft" "JustSaying.Extensions.DependencyInjection.Microsoft.csproj"),
    (Join-Path $solutionPath "src" "JustSaying.Extensions.DependencyInjection.StructureMap" "JustSaying.Extensions.DependencyInjection.StructureMap.csproj")
)

$testProjects = @(
    (Join-Path $solutionPath "tests" "JustSaying.UnitTests" "JustSaying.UnitTests.csproj"),
    (Join-Path $solutionPath "tests" "JustSaying.Extensions.DependencyInjection.StructureMap.Tests" "JustSaying.Extensions.DependencyInjection.StructureMap.Tests.csproj")
)

if ($EnableIntegrationTests -eq $true) {
    $testProjects += (Join-Path $solutionPath "tests" "JustSaying.IntegrationTests" "JustSaying.IntegrationTests.csproj");
}

$dotnetVersion = (Get-Content $sdkFile | Out-String | ConvertFrom-Json).sdk.version

$installDotNetSdk = $false;

if (($null -eq (Get-Command "dotnet" -ErrorAction SilentlyContinue)) -and ($null -eq (Get-Command "dotnet.exe" -ErrorAction SilentlyContinue))) {
    Write-Host "The .NET SDK is not installed."
    $installDotNetSdk = $true
}
else {
    Try {
        $installedDotNetVersion = (dotnet --version 2>&1 | Out-String).Trim()
    }
    Catch {
        $installedDotNetVersion = "?"
    }

    if ($installedDotNetVersion -ne $dotnetVersion) {
        Write-Host "The required version of the .NET SDK is not installed. Expected $dotnetVersion."
        $installDotNetSdk = $true
    }
}

if ($installDotNetSdk -eq $true) {
    $env:DOTNET_INSTALL_DIR = Join-Path "$(Convert-Path "$PSScriptRoot")" ".dotnetcli"
    $sdkPath = Join-Path $env:DOTNET_INSTALL_DIR "sdk\$dotnetVersion"

    if (!(Test-Path $sdkPath)) {
        if (!(Test-Path $env:DOTNET_INSTALL_DIR)) {
            mkdir $env:DOTNET_INSTALL_DIR | Out-Null
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor "Tls12"

        if (($PSVersionTable.PSVersion.Major -ge 6) -And !$IsWindows) {
            $installScript = Join-Path $env:DOTNET_INSTALL_DIR "install.sh"
            Invoke-WebRequest "https://dot.net/v1/dotnet-install.sh" -OutFile $installScript -UseBasicParsing
            chmod +x $installScript
            & $installScript --jsonfile $sdkFile --install-dir "$env:DOTNET_INSTALL_DIR" --no-path
        }
        else {
            $installScript = Join-Path $env:DOTNET_INSTALL_DIR "install.ps1"
            Invoke-WebRequest "https://dot.net/v1/dotnet-install.ps1" -OutFile $installScript -UseBasicParsing
            & $installScript -JsonFile $sdkFile -InstallDir "$env:DOTNET_INSTALL_DIR" -NoPath
        }
    }
}
else {
    $env:DOTNET_INSTALL_DIR = Split-Path -Path (Get-Command dotnet).Path
}

$dotnet = Join-Path $env:DOTNET_INSTALL_DIR "dotnet"

if (($installDotNetSdk -eq $true) -And ($null -eq $env:TF_BUILD)) {
    $env:PATH = "$env:DOTNET_INSTALL_DIR;$env:PATH"
}

function DotNetPack {
    param([string]$Project)

    & $dotnet pack $Project

    if ($LASTEXITCODE -ne 0) {
        throw "dotnet pack failed with exit code $LASTEXITCODE"
    }
}

function DotNetTest {
    param([string]$Project)

    $additionalArgs = @()

    if (![string]::IsNullOrEmpty($env:GITHUB_SHA)) {
        $additionalArgs += "--logger"
        $additionalArgs += "GitHubActions;report-warnings=false"
    }

    & $dotnet test $Project --configuration "Release" $additionalArgs

    if ($LASTEXITCODE -ne 0) {
        throw "dotnet test failed with exit code $LASTEXITCODE"
    }
}

function Get-ContainerRunnerCommand() {
    $commands = @('docker', 'podman')

    foreach ($command in $commands) {
        if (Get-Command $command -ErrorAction SilentlyContinue) {
            return $command
        }
    }
}

Write-Host "Creating packages..." -ForegroundColor Green

ForEach ($libraryProject in $libraryProjects) {
    DotNetPack $libraryProject
}

if (($null -ne $env:CI) -And ($EnableIntegrationTests -eq $true)) {
    $LocalStackImage = "localstack/localstack:3.5.0"
    $LocalStackPort = "4566"
    $containerRunner = Get-ContainerRunnerCommand
    & $containerRunner pull --quiet $LocalStackImage
    & $containerRunner run --detach --name localstack --publish "${LocalStackPort}:${LocalStackPort}" $LocalStackImage
    $env:AWS_SERVICE_URL = "http://localhost:$LocalStackPort"
}

if (-Not $SkipTests) {
    Write-Host "Running tests..." -ForegroundColor Green
    Remove-Item -Path (Join-Path $solutionPath "artifacts" "coverage" "coverage.json") -Force -ErrorAction SilentlyContinue | Out-Null
    ForEach ($testProject in $testProjects) {
        DotNetTest $testProject
    }
}
