param(
  [ValidateSet('Copy', 'Symlink')]
  [string]$Mode = 'Copy',

  [string]$CodexSkillsDir = (Join-Path (Join-Path $HOME '.codex') 'skills'),

  [string[]]$Skill = @(),

  [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
$sourceRoot = Join-Path $repoRoot 'skills'

if (-not (Test-Path -LiteralPath $sourceRoot)) {
  throw "Skills source directory not found: $sourceRoot"
}

New-Item -ItemType Directory -Force -Path $CodexSkillsDir | Out-Null

$availableSkills = Get-ChildItem -LiteralPath $sourceRoot -Directory |
  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') }

if ($Skill.Count -gt 0) {
  $selected = $availableSkills | Where-Object { $Skill -contains $_.Name }
  $missing = $Skill | Where-Object { $availableSkills.Name -notcontains $_ }

  if ($missing.Count -gt 0) {
    throw "Unknown skill(s): $($missing -join ', ')"
  }
} else {
  $selected = $availableSkills
}

foreach ($skillDir in $selected) {
  $target = Join-Path $CodexSkillsDir $skillDir.Name

  if (Test-Path -LiteralPath $target) {
    if (-not $Force) {
      Write-Host "Skipping $($skillDir.Name); target already exists: $target"
      continue
    }

    Remove-Item -LiteralPath $target -Recurse -Force
  }

  if ($Mode -eq 'Symlink') {
    New-Item -ItemType SymbolicLink -Path $target -Target $skillDir.FullName | Out-Null
  } else {
    Copy-Item -LiteralPath $skillDir.FullName -Destination $target -Recurse
  }

  Write-Host "Installed $($skillDir.Name) -> $target ($Mode)"
}
