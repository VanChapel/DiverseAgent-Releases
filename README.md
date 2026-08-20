# DiverseAgent Releases

Public binary distribution repository for **DiverseAgent**.

> This repository contains release binaries only. The DiverseAgent source code remains private in `VanChapel/DiverseAgent`.

## Windows installation

The initial Windows installation uses the signed/compiled installer attached to the latest GitHub Release:

- `DiverseAgentSetup.exe`

After installation, **DiverseSupervisor** manages the Agent and checks this repository for OTA updates.

### Normal installation

1. Open the latest release on this repository.
2. Download `DiverseAgentSetup.exe`.
3. Right-click the installer and choose **Run as administrator**.
4. Complete the installation.
5. The installation layout is expected to be:

```text
C:\Program Files\DiverseAgent\
    config\
    logs\
    pending_update\
    temp\

    DiverseAgent\
        DiverseAgent.exe
        _internal\...

    DiverseSupervisor\
        DiverseSupervisor.exe
        _internal\...

    DiverseService.exe
    DiverseService.xml
```

The Windows service is installed through WinSW and the Supervisor starts/monitors the Agent.

## PowerShell installation

Once a release contains `DiverseAgentSetup.exe`, Windows machines can also install from an elevated PowerShell terminal:

```powershell
irm https://raw.githubusercontent.com/VanChapel/DiverseAgent-Releases/main/install-windows.ps1 | iex
```

The script downloads the latest installer from GitHub Releases and starts it elevated.

## OTA update assets

Production releases should use these exact names:

```text
DiverseAgentSetup.exe
DiverseAgent-Windows-x64.zip
DiverseAgent-macOS-x64.zip
DiverseAgent-macOS-arm64.zip
```

For Windows OTA, the Supervisor selects:

```text
DiverseAgent-Windows-x64.zip
```

The ZIP is downloaded, SHA-256 verified, staged in `pending_update`, installed, restarted and rolled back automatically if activation fails.

## Versioning

Use semantic release tags:

```text
v1.0.0
v1.0.1
v1.1.0
v2.0.0
```

`config/version.json` inside the build must correspond to the release version.

Example:

```json
{
  "agent_version": "1.0.1",
  "supervisor_version": "1.0.1"
}
```

## Release procedure

For each production release:

1. Build DiverseAgent on the target operating system.
2. Verify the Agent and Supervisor locally.
3. Generate the Windows installer with Inno Setup.
4. Generate `DiverseAgent-Windows-x64.zip` using the release build process.
5. Create a GitHub Release using the matching version tag.
6. Upload `DiverseAgentSetup.exe` and `DiverseAgent-Windows-x64.zip` as Release assets.
7. Publish the Release as a normal production release — not Draft and not Prerelease.
8. Installed Supervisors will detect the newer version on their next OTA check.

## Important

Do not commit credentials, API keys, client configuration, logs or private source code to this public repository.
