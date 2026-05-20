# Codex Skills

Shared Codex skills for Qbiq Studio development workflows.

This repository keeps high-value, repeatable Codex workflows out of one local machine and makes them installable for both Windows and macOS developers. The current focus is Studio Editor debugging and a disciplined GitHub PR workflow.

## Included Skills

### `github-pr-workflow`

Runs a repeatable PR workflow from the current repository:

- inspect local changes
- commit the intended work only
- push the branch
- create or reuse a GitHub pull request
- request Copilot review when available
- wait for review feedback
- apply/reject review comments deliberately
- push follow-up commits
- assign the final human reviewer

The workflow is designed for repos that use `git` and the GitHub CLI.

### `studio-editor-memory-workflow`

Bootstraps Studio Editor bug work with shared local context:

- reads the repo working agreement
- reads the Studio Editor memory note
- focuses the thread on the new ticket or repro delta
- updates durable memory only when a new root cause, repro, or architectural constraint is confirmed

This is especially useful for recurring Studio issues around `Circulation`, room `stretch`, shared geometry updates, and similar geometry-heavy debugging threads.

## Requirements

- Codex Desktop or Codex CLI with local skill support
- Git
- GitHub CLI, authenticated with `gh auth login`
- PowerShell 7+ (`pwsh`) for the PR helper scripts

Install PowerShell 7:

```bash
brew install --cask powershell
```

```powershell
winget install --id Microsoft.PowerShell --source winget
```

## Install

Clone the repo:

```bash
git clone https://github.com/AlexQbiq/codex-skills.git
cd codex-skills
```

macOS or Linux:

```bash
./install.sh --mode symlink
```

Windows PowerShell:

```powershell
.\install.ps1 -Mode Copy
```

The installers copy or symlink everything under `skills/` into your Codex skills directory.

Default destinations:

- macOS/Linux: `~/.codex/skills`
- Windows: `%USERPROFILE%\.codex\skills`

Use a custom destination when needed:

```bash
./install.sh --codex-skills-dir "$HOME/.codex/skills" --mode symlink
```

```powershell
.\install.ps1 -CodexSkillsDir "$env:USERPROFILE\.codex\skills" -Mode Copy
```

## Copy vs Symlink

Use `symlink` when you want updates from this repo to immediately affect your local Codex skills.

Use `copy` when you want a stable snapshot in `~/.codex/skills`.

Recommended setup:

- macOS: `symlink`
- Windows: `copy`, unless Developer Mode is enabled and symlink creation is allowed

## Studio Configuration

The Studio skill is intentionally portable. It does not require the Studio repo to live at one hardcoded path.

Set `CODEX_STUDIO_REPO` when your Studio repo is not the current workspace:

macOS/Linux:

```bash
export CODEX_STUDIO_REPO="$HOME/Code/ui"
```

Windows PowerShell:

```powershell
$env:CODEX_STUDIO_REPO = "C:\Qbiq\ui"
```

The skill looks for these files in the Studio repo root:

- `.codex-working-agreement.md`
- `.codex-studio-editor-memory.md`
- `.codex-collaboration-suggestions.md` when present
- `.codex-qbiq-9901-notes.md` when present

If the memory file is missing, Codex should recreate it with stable section names instead of relying on hidden thread state.

See [docs/studio-developer-guide.md](docs/studio-developer-guide.md) for the recommended Studio team workflow.

This repository includes the rich shared Studio context in [templates/studio](templates/studio). Copy those files into a Studio UI checkout on each machine. See [docs/studio-context-migration.md](docs/studio-context-migration.md).

For easier browsing in GitHub, the full Studio memory is also mirrored as [docs/studio-editor-memory.md](docs/studio-editor-memory.md). The `Editor Architecture` section starts there.

Install the Studio context files:

```bash
./scripts/install-studio-context.sh --studio-repo "$CODEX_STUDIO_REPO"
```

```powershell
.\scripts\install-studio-context.ps1 -StudioRepo $env:CODEX_STUDIO_REPO
```

## PR Workflow Configuration

The PR skill supports environment variables so teams can tune defaults without editing the skill.

| Variable | Default | Purpose |
| --- | --- | --- |
| `CODEX_PR_BASE_BRANCH` | `staging` | Default PR target branch |
| `CODEX_FINAL_REVIEWER` | `qbiq-jonyfridja` | Human reviewer assigned at the end |
| `CODEX_COPILOT_WAIT_SECONDS` | `1800` | Review polling timeout |
| `CODEX_COPILOT_POLL_SECONDS` | `30` | Review polling interval |

For this repository, create PRs to `main` explicitly:

```powershell
pwsh -NoProfile -File skills/github-pr-workflow/scripts/create-pr.ps1 -Base main
```

## Usage

After installing, invoke a skill by name in Codex.

Studio task:

```text
Use $studio-editor-memory-workflow for this Studio Editor task.

Task: QBIQ-12345 Circulation handle breaks after stretch
Context delta: design id, snapshot id, or repro notes
Expected result: handles remain joined after stretch
Scope: minimal local fix only
Validation: unit and live verification
```

PR workflow:

```text
Use $github-pr-workflow targeting main.
```

## Repository Layout

```text
.
|-- install.ps1
|-- install.sh
|-- templates
|   `-- studio
|-- scripts
|   |-- install-studio-context.ps1
|   `-- install-studio-context.sh
|-- skills
|   |-- github-pr-workflow
|   `-- studio-editor-memory-workflow
`-- README.md
```

## Maintenance Guidelines

- Keep skills portable across Windows and macOS.
- Prefer environment variables over machine-specific paths.
- Keep durable Studio debugging knowledge in the Studio repo memory file, not hidden local state.
- Keep helper scripts small and easy to inspect.
- Do not commit secrets, auth files, local Codex session data, or machine-specific caches.
