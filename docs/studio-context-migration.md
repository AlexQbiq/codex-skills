# Studio Context Migration

The `studio-editor-memory-workflow` skill is the loader and maintenance workflow. The valuable Studio debugging context is the set of `.codex-*.md` notes that should live in the Studio UI repository root.

This repository now carries the shared historical Studio context under `templates/studio/` so a new machine can bootstrap the same working memory quickly.

For human browsing, the full Studio memory is mirrored at [studio-editor-memory.md](studio-editor-memory.md). The installable source of truth remains `templates/studio/.codex-studio-editor-memory.md`.

## Included Context Files

Copy these into the Studio UI repo root:

- `.codex-working-agreement.md`
  - team working agreement for Codex tasks
  - task templates
  - escalation and review standards
- `.codex-studio-editor-memory.md`
  - architecture map
  - stretch data flow
  - symptom-to-file triage table
  - fragile patterns
  - known root causes
  - historical resolved issues
  - starter prompt and maintenance rules
- `.codex-collaboration-suggestions.md`
  - collaboration habits that make Studio debugging faster and safer
  - fix-boundary, done-definition, branch-hygiene, and PR shortcut guidance
- `.codex-qbiq-9901-notes.md`
  - concrete repeatable circulation-collapse e2e notes
  - disposable design and snapshot reset flow

## Install Context Into A Studio Repo

From this repository, after `CODEX_STUDIO_REPO` points to the Studio UI checkout:

```bash
./scripts/install-studio-context.sh --studio-repo "$CODEX_STUDIO_REPO"
```

PowerShell:

```powershell
.\scripts\install-studio-context.ps1 -StudioRepo $env:CODEX_STUDIO_REPO
```

If the Studio repo already has newer versions of these notes, merge manually rather than overwriting them.

## Mac Setup

On macOS, set `CODEX_STUDIO_REPO` to the local Studio UI checkout:

```bash
export CODEX_STUDIO_REPO="$HOME/Code/ui"
```

Then install the shared context:

```bash
./scripts/install-studio-context.sh --studio-repo "$CODEX_STUDIO_REPO"
```

After that, ask Codex:

```text
Use $studio-editor-memory-workflow for this Studio Editor task.
```

Codex should resolve the Studio repo and load the working agreement, Studio memory, and any supplemental `.codex-*` notes before starting.

## Maintenance Model

- Keep the full shared Studio context in this repository.
- Copy or sync the files into each local Studio UI checkout.
- When a Studio task produces reusable learning, update the Studio repo note first, then promote the updated note back into this repository.
- Prefer durable codebase lessons over noisy ticket diaries, but keep concrete historical repro data when it materially shortens future debugging.
