# Studio Context Templates

These files are the shared Studio Editor working memory for Codex.

Copy them into the Studio UI repo root on each developer machine:

```bash
./scripts/install-studio-context.sh --studio-repo "$CODEX_STUDIO_REPO"
```

PowerShell:

```powershell
.\scripts\install-studio-context.ps1 -StudioRepo $env:CODEX_STUDIO_REPO
```

## Files

- `.codex-working-agreement.md`: task expectations, prompt templates, escalation rules, and review standards.
- `.codex-studio-editor-memory.md`: rich Studio architecture, triage, root cause, and historical debugging memory.
- `.codex-collaboration-suggestions.md`: habits that make Codex sessions more precise and safer.
- `.codex-qbiq-9901-notes.md`: repeatable e2e notes for a circulation-collapse test design.

Keep this directory synchronized with the Studio repo notes whenever a task produces reusable learning.
