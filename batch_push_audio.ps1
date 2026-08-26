param(
    [Int64]$BatchLimit = 450MB,
    [string]$Remote = 'origin'
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$logFile = Join-Path ([IO.Path]::GetTempPath()) "batch-push-$PID.log"
$gitOutputFile = Join-Path ([IO.Path]::GetTempPath()) "git-output-$PID"

function Invoke-Git {
    param([string[]]$GitArgs)

    $previousErrorActionPreference = $ErrorActionPreference
    $previousConsoleEncoding = [Console]::OutputEncoding
    $previousOutputEncoding = $OutputEncoding
    try {
        $ErrorActionPreference = 'Continue'
        [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
        $OutputEncoding = [Text.UTF8Encoding]::new($false)
        & git -C $repo -c core.quotePath=false @GitArgs 2>&1 | Tee-Object -FilePath $logFile -Append
    }
    finally {
        [Console]::OutputEncoding = $previousConsoleEncoding
        $OutputEncoding = $previousOutputEncoding
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($LASTEXITCODE -ne 0) {
        throw "git failed: $($GitArgs -join ' ')"
    }
}

function Get-GitNullPaths {
    param([string[]]$GitArgs)

    $arguments = $GitArgs -join ' '
    $command = "git -C `"$repo`" -c core.quotePath=false $arguments > `"$gitOutputFile`""
    & cmd.exe /d /c $command
    if ($LASTEXITCODE -ne 0) {
        throw "git failed: $($GitArgs -join ' ')"
    }
    $outputBytes = [IO.File]::ReadAllBytes($gitOutputFile)
    $rawOutput = [Text.UTF8Encoding]::new($false, $true).GetString($outputBytes)
    return @($rawOutput.Split([char]0, [StringSplitOptions]::RemoveEmptyEntries))
}

function Get-ChangedPaths {
    $records = @(Get-GitNullPaths @('status', '--porcelain=v1', '-z'))
    $paths = foreach ($record in $records) {
        if ($record.Length -gt 3) {
            $record.Substring(3)
        }
    }
    return @($paths |
        Sort-Object -Unique |
        Where-Object { -not (Test-Path -LiteralPath (Join-Path $repo $_) -PathType Container) })
}

function Get-PathSize {
    param([string]$Path)

    $fullPath = Join-Path $repo $Path
    if ([IO.File]::Exists($fullPath)) {
        return [Int64][IO.FileInfo]::new($fullPath).Length
    }
    if (Test-Path -LiteralPath $fullPath -PathType Container) {
        return 0L
    }
    return 0L
}

function Add-BatchToIndex {
    param([Collections.Generic.List[string]]$Paths)

    for ($i = 0; $i -lt $Paths.Count; $i++) {
        $path = [string]$Paths[$i]
        Invoke-Git @('add', '--all', '--', $path)
    }
}

if ($BatchLimit -lt 1) {
    throw 'BatchLimit must be greater than zero.'
}

$branch = (& git -C $repo symbolic-ref --quiet --short HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $branch) {
    throw 'A branch must be checked out.'
}

"[$(Get-Date -Format o)] batch upload start" | Set-Content -LiteralPath $logFile -Encoding utf8
$batchNumber = 0

try {
    while ($true) {
        $changedPaths = @(Get-ChangedPaths)
        if ($changedPaths.Count -eq 0) { break }

        $batchPaths = [Collections.Generic.List[string]]::new()
        $batchSize = 0L
        foreach ($path in $changedPaths) {
            $pathSize = Get-PathSize -Path $path
            if ($batchPaths.Count -gt 0 -and $batchSize + $pathSize -gt $BatchLimit) {
                break
            }
            $null = $batchPaths.Add($path)
            $batchSize += $pathSize
        }

        if ($batchPaths.Count -eq 0) {
            $null = $batchPaths.Add($changedPaths[0])
        }

        $batchNumber++
        Add-BatchToIndex -Paths $batchPaths

        & git -C $repo diff --cached --quiet
        if ($LASTEXITCODE -eq 0) {
            throw 'The selected files produced no staged changes.'
        }

        Invoke-Git @('commit', '-m', "batch upload $batchNumber")
        Invoke-Git @('push', $Remote, $branch)
    }
}
finally {
    Remove-Item -LiteralPath $gitOutputFile -Force -ErrorAction SilentlyContinue
}

"[$(Get-Date -Format o)] batch upload complete: $batchNumber batch(es)" | Tee-Object -FilePath $logFile -Append
