param(
  [string]$Base = '',
  [string]$Title = '',
  [string]$Body = '',
  [string]$BodyFile = '',
  [string]$JiraIssue = '',
  [string]$JiraTitle = '',
  [switch]$Draft,
  [switch]$ReuseExisting = $true
)

$ErrorActionPreference = 'Stop'

if (-not $Base) {
  $Base = if ($env:CODEX_PR_BASE_BRANCH) { $env:CODEX_PR_BASE_BRANCH } else { 'staging' }
}

function Invoke-CommandChecked {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [string[]]$ArgumentList
  )

  $output = & $FilePath @ArgumentList
  if ($LASTEXITCODE -ne 0) {
    throw "$FilePath $($ArgumentList -join ' ') failed with exit code $LASTEXITCODE"
  }

  return $output
}

$branch = (Invoke-CommandChecked git @('branch', '--show-current')).Trim()
if (-not $branch) {
  throw 'Current branch could not be determined.'
}

Invoke-CommandChecked git @('push', '-u', 'origin', $branch) | Out-Null

$existingPrJson = Invoke-CommandChecked gh @(
  'pr', 'list',
  '--head', $branch,
  '--json', 'number,url,state,title,isDraft,headRefName,baseRefName',
  '--limit', '1'
)
$existingPr = $existingPrJson | ConvertFrom-Json

if ($ReuseExisting -and $existingPr.Count -gt 0) {
  $existingPr[0] | ConvertTo-Json -Depth 8
  exit 0
}

if ($JiraTitle) {
  $Title = $JiraTitle.Trim()
}

if (-not $Title) {
  $Title = (Invoke-CommandChecked git @('log', '-1', '--pretty=%s')).Trim()
}

if (-not $Title) {
  throw 'PR title could not be determined. Pass -Title explicitly.'
}

if ($JiraIssue) {
  $jiraIssueTrimmed = $JiraIssue.Trim()
  if ($Title -notmatch "^\Q$jiraIssueTrimmed\E(\s|:|-)") {
    $Title = "$jiraIssueTrimmed $Title".Trim()
  }

  $jiraTag = "[$jiraIssueTrimmed]"

  if ($BodyFile) {
    $bodyFromFile = Get-Content -Path $BodyFile -Raw
    if ($bodyFromFile -notmatch [regex]::Escape($jiraTag)) {
      $bodyFromFile = "$jiraTag`r`n`r`n$bodyFromFile".TrimEnd()
      $tempBodyFile = [System.IO.Path]::GetTempFileName()
      Set-Content -Path $tempBodyFile -Value $bodyFromFile
      $BodyFile = $tempBodyFile
    }
  } elseif ($Body) {
    if ($Body -notmatch [regex]::Escape($jiraTag)) {
      $Body = "$jiraTag`r`n`r`n$Body"
    }
  } else {
    $Body = $jiraTag
  }
}

$createArgs = @(
  'pr', 'create',
  '--base', $Base,
  '--head', $branch,
  '--title', $Title
)

if ($BodyFile) {
  $createArgs += @('--body-file', $BodyFile)
} elseif ($Body) {
  $createArgs += @('--body', $Body)
} else {
  $createArgs += @('--body', '')
}

if ($Draft) {
  $createArgs += '--draft'
}

Invoke-CommandChecked gh $createArgs | Out-Null

$createdPrJson = Invoke-CommandChecked gh @(
  'pr', 'view', $branch,
  '--json', 'number,url,state,title,isDraft,headRefName,baseRefName'
)
$createdPr = $createdPrJson | ConvertFrom-Json
$createdPr | ConvertTo-Json -Depth 8
