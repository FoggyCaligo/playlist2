param(
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
$packages = @(
    @{ Id = 'yt-dlp.yt-dlp'; Name = 'yt-dlp'; Executable = 'yt-dlp.exe' },
    @{ Id = 'Gyan.FFmpeg'; Name = 'FFmpeg'; Executable = 'ffmpeg.exe' },
    @{ Id = 'DenoLand.Deno'; Name = 'Deno'; Executable = 'deno.exe' }
)

function Install-WingetPackage {
    param([hashtable]$Package)

    Write-Host "Installing or checking $($Package.Name)..."
    & winget install --id $Package.Id --exact --source winget `
        --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "winget returned exit code $LASTEXITCODE for $($Package.Name); executable verification will decide whether to continue."
    }
}

function Find-Executable {
    param([string]$Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $roots = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages')
    ) | Where-Object { Test-Path -LiteralPath $_ }

    $match = Get-ChildItem -LiteralPath $roots -Filter $Name -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($match) {
        return $match.FullName
    }

    return $null
}

function Add-UserPath {
    param([string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_ })
    if (-not ($entries | Where-Object { $_.TrimEnd('\') -ieq $Directory.TrimEnd('\') })) {
        $entries += $Directory
    }
    $newPath = $entries -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = "$Directory;$env:Path"
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is not available. Install App Installer from Microsoft Store first.'
}

if (-not $SkipInstall) {
    foreach ($package in $packages) {
        Install-WingetPackage -Package $package
    }
}

$directories = [Collections.Generic.List[string]]::new()
foreach ($package in $packages) {
    $executable = Find-Executable -Name $package.Executable
    if (-not $executable) {
        throw "$($package.Name) was not found. Open a new PowerShell window and run this script again."
    }

    $directory = Split-Path -Parent $executable
    if (-not ($directories | Where-Object { $_ -ieq $directory })) {
        $directories.Add($directory)
    }
    Write-Host "$($package.Name): $executable"
}

foreach ($directory in $directories) {
    Add-UserPath -Directory $directory
}

Write-Host ''
Write-Host 'Tool setup complete. Open a new terminal to load the permanent PATH.'
Write-Host "yt-dlp: $(& yt-dlp.exe --version)"
Write-Host "ffmpeg: $((& ffmpeg.exe -version 2>&1 | Select-Object -First 1))"
Write-Host "deno: $(& deno.exe --version | Select-Object -First 1)"
