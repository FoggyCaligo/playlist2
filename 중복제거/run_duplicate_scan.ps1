param(
    [string]$Root = (Join-Path $PSScriptRoot '..\pli'),
    [string]$Output = (Join-Path $PSScriptRoot 'duplicates_report.csv'),
    [double]$Threshold = 0.35,
    [int]$MinShared = 60,
    [double]$DurationRatioMin = 0.80,
    [double]$DurationRatioMax = 1.25,
    [string]$Fpcalc = 'fpcalc',
    [string]$Python = 'py'
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path -LiteralPath $Root).Path
$Output = [IO.Path]::GetFullPath($Output)
$Reporter = Join-Path $PSScriptRoot 'reporter.py'

if (-not (Test-Path -LiteralPath $Reporter -PathType Leaf)) {
    throw "reporter.py를 찾을 수 없습니다: $Reporter"
}
if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    throw "음원 폴더를 찾을 수 없습니다: $Root"
}

$fpcalcCommand = Get-Command $Fpcalc -ErrorAction SilentlyContinue
if (-not $fpcalcCommand) {
    throw "fpcalc를 찾을 수 없습니다. Chromaprint를 설치하거나 -Fpcalc로 fpcalc.exe 경로를 지정하세요."
}

$outputDirectory = Split-Path -Parent $Output
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$arguments = @(
    '-3',
    $Reporter,
    $Root,
    '--out', $Output,
    '--fpcalc', $fpcalcCommand.Source,
    '--threshold', $Threshold.ToString([Globalization.CultureInfo]::InvariantCulture),
    '--min-shared', $MinShared,
    '--dur-ratio-min', $DurationRatioMin.ToString([Globalization.CultureInfo]::InvariantCulture),
    '--dur-ratio-max', $DurationRatioMax.ToString([Globalization.CultureInfo]::InvariantCulture)
)

Write-Host "중복 음원 스캔 시작: $Root"
Write-Host "결과 파일: $Output"
& $Python @arguments
if ($LASTEXITCODE -ne 0) {
    throw "중복 스캔에 실패했습니다. 종료 코드: $LASTEXITCODE"
}

Write-Host '중복 스캔 완료. CSV의 DUPLICATE_CANDIDATE 항목을 확인하세요.'
