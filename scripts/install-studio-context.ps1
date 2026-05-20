param(
  [string]$StudioRepo = $env:CODEX_STUDIO_REPO,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not $StudioRepo) {
  throw 'Pass -StudioRepo or set CODEX_STUDIO_REPO.'
}

if (-not (Test-Path -LiteralPath $StudioRepo)) {
  throw "Studio repo path not found: $StudioRepo"
}

$sourceDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'templates\studio'
$files = Get-ChildItem -LiteralPath $sourceDir -Force -File -Filter '.codex-*.md'

foreach ($file in $files) {
  $target = Join-Path $StudioRepo $file.Name

  if ((Test-Path -LiteralPath $target) -and -not $Force) {
    Write-Host "Skipping $($file.Name); target already exists. Use -Force to overwrite."
    continue
  }

  Copy-Item -LiteralPath $file.FullName -Destination $target -Force
  Write-Host "Installed $($file.Name) -> $target"
}
