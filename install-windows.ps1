$ErrorActionPreference = 'Stop'

$Owner = 'VanChapel'
$Repository = 'DiverseAgent-Releases'
$AssetName = 'DiverseAgentSetup.exe'
$ApiUrl = "https://api.github.com/repos/$Owner/$Repository/releases/latest"

Write-Host 'DiverseAgent Windows Installer' -ForegroundColor Cyan
Write-Host '--------------------------------'

try {
    $headers = @{
        'Accept' = 'application/vnd.github+json'
        'User-Agent' = 'DiverseAgent-Windows-Installer'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    Write-Host 'Checking latest DiverseAgent release...'
    $release = Invoke-RestMethod -Uri $ApiUrl -Headers $headers -Method Get

    $asset = $release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
    if (-not $asset) {
        throw "The latest release '$($release.tag_name)' does not contain $AssetName."
    }

    $tempDirectory = Join-Path $env:TEMP 'DiverseAgentInstaller'
    New-Item -ItemType Directory -Path $tempDirectory -Force | Out-Null
    $installerPath = Join-Path $tempDirectory $AssetName

    Write-Host "Downloading $AssetName from release $($release.tag_name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installerPath -UseBasicParsing

    if (-not (Test-Path $installerPath)) {
        throw 'Installer download did not complete successfully.'
    }

    Write-Host 'Starting installer as Administrator...'
    $process = Start-Process -FilePath $installerPath -Verb RunAs -Wait -PassThru

    if ($process.ExitCode -ne 0) {
        throw "Installer exited with code $($process.ExitCode)."
    }

    Write-Host 'DiverseAgent installation completed.' -ForegroundColor Green
}
catch {
    Write-Error "DiverseAgent installation failed: $($_.Exception.Message)"
    exit 1
}
