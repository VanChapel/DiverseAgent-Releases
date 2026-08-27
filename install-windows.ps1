$ErrorActionPreference = 'Stop'

$Owner = 'VanChapel'
$Repository = 'DiverseAgent-Releases'
$AssetName = 'DiverseAgentSetup.exe'
$ApiUrl = "https://api.github.com/repos/$Owner/$Repository/releases/latest"

try {
    $headers = @{
        'Accept' = 'application/vnd.github+json'
        'User-Agent' = 'DiverseAgent-Windows-Installer'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    $release = Invoke-RestMethod -Uri $ApiUrl -Headers $headers -Method Get
    $asset = $release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
    if (-not $asset) {
        throw "The latest release '$($release.tag_name)' does not contain $AssetName."
    }

    $tempDirectory = Join-Path $env:TEMP 'DiverseAgentInstaller'
    New-Item -ItemType Directory -Path $tempDirectory -Force | Out-Null
    $installerPath = Join-Path $tempDirectory $AssetName
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installerPath -UseBasicParsing

    if (-not (Test-Path $installerPath)) {
        throw 'Installer download did not complete successfully.'
    }

    $expectedHash = $null
    if ($asset.digest -and ([string]$asset.digest).StartsWith('sha256:', [System.StringComparison]::OrdinalIgnoreCase)) {
        $expectedHash = ([string]$asset.digest).Substring(7).ToLowerInvariant()
    }
    if (-not $expectedHash) {
        $checksumAsset = $release.assets | Where-Object { $_.name -eq 'checksums.txt' } | Select-Object -First 1
        if ($checksumAsset) {
            $checksumText = (Invoke-WebRequest -Uri $checksumAsset.browser_download_url -UseBasicParsing).Content
            foreach ($line in ($checksumText -split "`r?`n")) {
                if ($line -match '^([0-9a-fA-F]{64})\s+\*?DiverseAgentSetup\.exe$') {
                    $expectedHash = $Matches[1].ToLowerInvariant()
                    break
                }
            }
        }
    }
    if (-not $expectedHash) {
        throw 'No SHA-256 was published for DiverseAgentSetup.exe.'
    }

    $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "SHA-256 verification failed for $AssetName."
    }

    $arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if ($isAdmin) {
        $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait -PassThru
    }
    else {
        $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -Verb RunAs -Wait -PassThru
    }

    if ($process.ExitCode -ne 0) {
        throw "Installer exited with code $($process.ExitCode)."
    }
}
catch {
    Write-Error "DiverseAgent installation failed: $($_.Exception.Message)"
    exit 1
}
