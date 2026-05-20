param(
  [string]$PullRequest = '',
  [int]$TimeoutSeconds = 0,
  [int]$PollSeconds = 0,
  [string[]]$ReviewerLogins = @(
    'copilot-pull-request-reviewer[bot]',
    'github-copilot[bot]',
    'copilot[bot]'
  )
)

$ErrorActionPreference = 'Stop'

if ($TimeoutSeconds -le 0) {
  $TimeoutSeconds = if ($env:CODEX_COPILOT_WAIT_SECONDS) { [int]$env:CODEX_COPILOT_WAIT_SECONDS } else { 1800 }
}

if ($PollSeconds -le 0) {
  $PollSeconds = if ($env:CODEX_COPILOT_POLL_SECONDS) { [int]$env:CODEX_COPILOT_POLL_SECONDS } else { 30 }
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

function Resolve-PullRequestNumber {
  param([string]$InputValue)

  if ($InputValue) {
    return $InputValue
  }

  $prJson = Invoke-CommandChecked gh @('pr', 'view', '--json', 'number')
  return (($prJson | ConvertFrom-Json).number).ToString()
}

function Get-ReviewState {
  param(
    [string]$Repository,
    [string]$PullRequestNumber,
    [string[]]$CandidateLogins
  )

  $reviews = Invoke-CommandChecked gh @('api', "repos/$Repository/pulls/$PullRequestNumber/reviews") | ConvertFrom-Json
  $reviewComments = Invoke-CommandChecked gh @('api', "repos/$Repository/pulls/$PullRequestNumber/comments") | ConvertFrom-Json
  $issueComments = Invoke-CommandChecked gh @('api', "repos/$Repository/issues/$PullRequestNumber/comments") | ConvertFrom-Json
  $requestedReviewers = Invoke-CommandChecked gh @('api', "repos/$Repository/pulls/$PullRequestNumber/requested_reviewers") | ConvertFrom-Json

  $copilotReviews = @($reviews | Where-Object { $CandidateLogins -contains $_.user.login })
  $copilotReviewComments = @($reviewComments | Where-Object { $CandidateLogins -contains $_.user.login })
  $copilotIssueComments = @($issueComments | Where-Object { $CandidateLogins -contains $_.user.login })
  $activeRequests = @($requestedReviewers.users | Where-Object { $CandidateLogins -contains $_.login })

  [pscustomobject]@{
    reviews = $copilotReviews
    reviewComments = $copilotReviewComments
    issueComments = $copilotIssueComments
    requestedReviewers = $activeRequests
    complete = ($copilotReviews.Count + $copilotReviewComments.Count + $copilotIssueComments.Count) -gt 0
  }
}

$prNumber = Resolve-PullRequestNumber -InputValue $PullRequest
$repoJson = Invoke-CommandChecked gh @('repo', 'view', '--json', 'nameWithOwner')
$repo = ($repoJson | ConvertFrom-Json).nameWithOwner
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)

while ((Get-Date) -lt $deadline) {
  $state = Get-ReviewState -Repository $repo -PullRequestNumber $prNumber -CandidateLogins $ReviewerLogins

  if ($state.complete) {
    [pscustomobject]@{
      pullRequest = $prNumber
      repository = $repo
      status = 'completed'
      reviewCount = $state.reviews.Count
      reviewCommentCount = $state.reviewComments.Count
      issueCommentCount = $state.issueComments.Count
      requestedReviewerCount = $state.requestedReviewers.Count
    } | ConvertTo-Json -Depth 8
    exit 0
  }

  Start-Sleep -Seconds $PollSeconds
}

$finalState = Get-ReviewState -Repository $repo -PullRequestNumber $prNumber -CandidateLogins $ReviewerLogins

[pscustomobject]@{
  pullRequest = $prNumber
  repository = $repo
  status = 'timeout'
  reviewCount = $finalState.reviews.Count
  reviewCommentCount = $finalState.reviewComments.Count
  issueCommentCount = $finalState.issueComments.Count
  requestedReviewerCount = $finalState.requestedReviewers.Count
} | ConvertTo-Json -Depth 8
