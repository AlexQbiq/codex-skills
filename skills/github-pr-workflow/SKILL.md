---
name: github-pr-workflow
description: "Use when the user wants a repeatable GitHub pull request workflow for the current repository: commit changes, push the branch, create or reuse a PR, request Copilot review, wait for review feedback, optionally schedule a heartbeat follow-up when review is delayed, address accepted comments, push follow-up commits, respond on the PR, close PR conversations, assign the configured final reviewer, and optionally end the Codex thread after reporting the result. Default the PR target branch to CODEX_PR_BASE_BRANCH or staging unless the user provides a different target branch."
---

# GitHub PR Workflow

This skill turns "ship this" into a deliberate GitHub workflow. It is intended for day-to-day engineering work where Codex should commit the current change, open or reuse a PR, request review, and handle review feedback without sweeping in unrelated local edits.

## Requirements

- `git`
- GitHub CLI authenticated with `gh auth login`
- PowerShell 7+ (`pwsh`) for helper scripts on Windows, macOS, and Linux

Windows PowerShell can run the scripts too, but `pwsh` is the portable default.

## Configuration

Prefer environment variables over editing the skill.

| Variable | Default | Purpose |
| --- | --- | --- |
| `CODEX_PR_BASE_BRANCH` | `staging` | Default PR target branch |
| `CODEX_FINAL_REVIEWER` | `qbiq-jonyfridja` | Human reviewer assigned at the end |
| `CODEX_COPILOT_WAIT_SECONDS` | `1800` | Copilot review polling timeout |
| `CODEX_COPILOT_POLL_SECONDS` | `30` | Copilot review polling interval |

User instructions always win. For example, "target `main`" overrides `CODEX_PR_BASE_BRANCH`.

## When To Use

Use this skill when the user asks for a PR workflow such as:

- "commit, push, create PR"
- "open a PR and ask Copilot to review it"
- "wait for review, apply fixes, push again"
- "respond to review comments and wrap this up"

The workflow applies to the repository in the current workspace.

When the user provides a Jira issue key and title:

- format the PR title as `QBIQ-10094 Jira title here`
- include the Jira issue key in the PR body as a standalone tag like `[QBIQ-10094]`

## Guardrails

- Never include unrelated user changes in a commit.
- Never amend or force-push unless the user explicitly asks.
- Do not auto-accept every review comment. Classify comments into:
  - apply
  - reject with explanation
  - needs user decision
- If review feedback is delayed, create a heartbeat follow-up for this thread by default instead of stopping with "ask me later", unless the user explicitly asks not to wait/resume.
- Heartbeat resumes must be self-limiting: if the run cannot safely make progress because required PR/thread context is missing or insufficient, notify the user once with the blocker, delete the heartbeat automation, and do not create a replacement heartbeat.
- Run relevant validation before each push when the repo supports it.
- Only archive or close the Codex conversation if the user explicitly asks in that run.

## Quick Start

1. Inspect repo state with `git status --short`, `git branch --show-current`, and `git remote -v`.
2. Review the diff before committing.
3. Create a focused commit with a clear message.
4. Run [`scripts/create-pr.ps1`](./scripts/create-pr.ps1) with `pwsh` to push the branch and create or reuse the PR.
5. Run [`scripts/request-copilot-review.ps1`](./scripts/request-copilot-review.ps1) to request Copilot review.
6. Run [`scripts/wait-copilot-review.ps1`](./scripts/wait-copilot-review.ps1) to poll for Copilot feedback.
7. If review is not ready before the run should end, create a heartbeat follow-up for this same thread by default, scheduled soon enough to resume review processing without another user prompt.
8. Summarize feedback, then apply comments you agree with.
9. Re-run validation, commit follow-up changes, and push again.
10. Respond on the PR for comments you addressed or rejected.
11. Close resolved PR conversations.
12. Run [`scripts/assign-final-reviewer.ps1`](./scripts/assign-final-reviewer.ps1) to assign the configured final reviewer.
13. Report the final state to the user. If they explicitly asked to close the conversation, return `::archive{reason="Workflow complete at user request"}` after the final summary.

## Standard Workflow

### 1. Prepare The Branch

- Confirm the current branch is not detached.
- If there are no local changes and no existing PR work to continue, stop and report that there is nothing to ship.
- If the working tree includes unrelated files, exclude them instead of sweeping them into the PR.

### 2. Commit Current Work

- Review the diff before writing the commit message.
- Prefer one focused commit for the current logical change set.
- If the user asked for a narrower scope, honor it instead of bundling everything currently modified.

### 3. Create Or Reuse The PR

Use [`scripts/create-pr.ps1`](./scripts/create-pr.ps1).

Preferred behavior:

- reuse an existing PR for the current branch when one already exists
- otherwise create a new PR against the requested target branch
- accept an optional target branch from the user
- default target branch resolution:
  - user-provided branch
  - `CODEX_PR_BASE_BRANCH`
  - `staging`
- default the title to `JIRA-KEY Jira title` when a Jira issue and title are provided
- otherwise default the title to the latest commit subject
- prefix the PR body with the Jira issue key in square brackets when a Jira issue is provided

Example:

```powershell
pwsh -NoProfile -File scripts/create-pr.ps1 -Base main
```

With Jira context:

```powershell
pwsh -NoProfile -File scripts/create-pr.ps1 -Base staging -JiraIssue QBIQ-10094 -JiraTitle "Circulation - handles break after stretch"
```

After creation, report:

- PR number
- PR URL
- base branch
- head branch

### 4. Request Copilot Review

Use [`scripts/request-copilot-review.ps1`](./scripts/request-copilot-review.ps1).

```powershell
pwsh -NoProfile -File scripts/request-copilot-review.ps1
```

Notes:

- GitHub Copilot reviewer identity can vary by org or rollout.
- The script tries several common reviewer bot names.
- If automatic request fails, tell the user exactly that and continue once review appears, rather than pretending it succeeded.

### 5. Wait For Review

Use [`scripts/wait-copilot-review.ps1`](./scripts/wait-copilot-review.ps1).

```powershell
pwsh -NoProfile -File scripts/wait-copilot-review.ps1
```

Treat these as Copilot feedback sources:

- pull request reviews
- pull request review comments
- issue comments on the PR

When feedback arrives:

- summarize it before editing code
- keep the user aware of what you plan to accept or reject

If feedback does not arrive before the current run should end:

- Create a heartbeat follow-up attached to the current thread, usually for about 30 minutes later, unless the user explicitly asks not to wait/resume.
- The heartbeat prompt must be self-contained: include the PR URL/number, branch, base branch, Jira issue, latest commit, validation already run, and explicit permission to apply clearly correct review suggestions, reject incorrect/out-of-scope suggestions with PR replies, push follow-up commits, close resolved conversations, assign the configured final reviewer, and report the final state.
- The heartbeat prompt must include this stop condition: if required PR/thread context is missing or insufficient to continue safely, notify the user once, delete this automation, and do not schedule a replacement heartbeat.
- Do not ask the user again on heartbeat resume unless a review comment is materially ambiguous, risky, or outside the original requested scope.

### 6. Address Feedback

For each finding:

- apply it when technically correct and aligned with the user request
- reject it when it is incorrect, out of scope, or harmful
- ask the user only when the tradeoff is material and ambiguous

After code changes:

- run focused validation
- create a new commit
- push the branch

### 7. Respond On The PR

Respond to review threads or comments after follow-up changes are pushed.

Response style:

- short
- factual
- mention the follow-up commit or the reason for declining
- when replying to a human reviewer, start the response with their GitHub mention
- do not add mentions for bot/Copilot review comments unless a human was also part of that conversation

If GitHub CLI support for threaded replies is not available in the environment, state that clearly and leave the user with the exact manual step still needed.

### 8. Close PR Conversations

After responding on the PR, close conversations that are actually resolved.

Rules:

- only close conversations when the code change and reply are already in place
- do not close threads you intentionally rejected without a clear explanation
- leave threads open when the environment cannot post or close them cleanly

### 9. Assign Final Reviewer

After the PR conversations are closed, use [`scripts/assign-final-reviewer.ps1`](./scripts/assign-final-reviewer.ps1). It assigns `CODEX_FINAL_REVIEWER` when set, otherwise `qbiq-jonyfridja`.

```powershell
pwsh -NoProfile -File scripts/assign-final-reviewer.ps1
```

Rules:

- do this after the main review follow-up is complete
- avoid removing existing reviewers unless the user explicitly asks
- if the reviewer is already assigned, leave the assignment unchanged

### 10. Finish The Run

Report:

- what was committed
- PR URL
- whether Copilot review was requested successfully
- what feedback was applied
- what feedback was rejected or left pending
- any remaining manual GitHub steps

Only close the Codex thread when the user explicitly asked to end the conversation in that run.

## Scripts

### `scripts/create-pr.ps1`

Pushes the current branch and creates or reuses a PR.

### `scripts/request-copilot-review.ps1`

Attempts to request Copilot review using common bot reviewer names.

### `scripts/wait-copilot-review.ps1`

Polls GitHub until Copilot feedback appears or the timeout is reached.

### `scripts/assign-final-reviewer.ps1`

Assigns the configured human reviewer after review follow-up is complete.

## Automatic Completion Prompt

The workflow creates a heartbeat by default when review is delayed. This shorter prompt is enough for the full flow:

```text
Use $github-pr-workflow.
```

If the user wants a shorter run without automatic delayed review handling, they must say so explicitly, for example: `Use $github-pr-workflow, but do not create a heartbeat or wait for delayed review.`
