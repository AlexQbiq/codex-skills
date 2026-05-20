param(
  [string]$PullRequest = '',
  [string]$Reviewer = ''
)

$ErrorActionPreference = 'Stop'

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

function Resolve-PullRequestNumber {
  param([string]$InputValue)

  if ($InputValue) {
    return $InputValue
  }

  $prJson = Invoke-CommandChecked gh @('pr', 'view', '--json', 'number')
  return (($prJson | ConvertFrom-Json).number).ToString()
}

if (-not $Reviewer) {
  $Reviewer = if ($env:CODEX_FINAL_REVIEWER) { $env:CODEX_FINAL_REVIEWER } else { 'qbiq-jonyfridja' }
}

if (-not $Reviewer) {
  throw 'Reviewer could not be determined. Pass -Reviewer or set CODEX_FINAL_REVIEWER.'
}

$prNumber = Resolve-PullRequestNumber -InputValue $PullRequest
$repoJson = Invoke-CommandChecked gh @('repo', 'view', '--json', 'nameWithOwner')
$repo = ($repoJson | ConvertFrom-Json).nameWithOwner

& gh api "repos/$repo/pulls/$prNumber/requested_reviewers" -X POST --raw-field "reviewers[]=$Reviewer" | Out-Null

if ($LASTEXITCODE -ne 0) {
  throw "Failed to request reviewer $Reviewer on PR #$prNumber."
}

[pscustomobject]@{
  pullRequest = $prNumber
  repository = $repo
  requestedReviewer = $Reviewer
} | ConvertTo-Json -Depth 8
