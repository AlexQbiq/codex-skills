param(
  [string]$PullRequest = '',
  [string[]]$ReviewerCandidates = @(
    'copilot-pull-request-reviewer[bot]',
    'github-copilot[bot]',
    'copilot[bot]'
  )
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

$prNumber = Resolve-PullRequestNumber -InputValue $PullRequest
$repoJson = Invoke-CommandChecked gh @('repo', 'view', '--json', 'nameWithOwner')
$repo = ($repoJson | ConvertFrom-Json).nameWithOwner

$errors = New-Object System.Collections.Generic.List[string]

foreach ($candidate in $ReviewerCandidates) {
  try {
    & gh api "repos/$repo/pulls/$prNumber/requested_reviewers" -X POST --raw-field "reviewers[]=$candidate" | Out-Null
    if ($LASTEXITCODE -eq 0) {
      [pscustomobject]@{
        pullRequest = $prNumber
        repository = $repo
        requestedReviewer = $candidate
        manualRequired = $false
      } | ConvertTo-Json -Depth 8
      exit 0
    }
  } catch {
    $errors.Add("[$candidate] $($_.Exception.Message)")
  }
}

[pscustomobject]@{
  pullRequest = $prNumber
  repository = $repo
  requestedReviewer = $null
  manualRequired = $true
  errors = $errors
} | ConvertTo-Json -Depth 8
