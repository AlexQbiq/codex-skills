#!/usr/bin/env bash
set -euo pipefail

studio_repo="${CODEX_STUDIO_REPO:-}"
force="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --studio-repo)
      studio_repo="$2"
      shift 2
      ;;
    --force)
      force="true"
      shift
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: ./scripts/install-studio-context.sh [--studio-repo PATH] [--force]

Copies templates/studio/.codex-*.md into a Studio UI repository.
Defaults to CODEX_STUDIO_REPO when --studio-repo is omitted.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$studio_repo" ]]; then
  echo "Pass --studio-repo or set CODEX_STUDIO_REPO." >&2
  exit 1
fi

if [[ ! -d "$studio_repo" ]]; then
  echo "Studio repo path not found: $studio_repo" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="${repo_root}/templates/studio"

for source in "${source_dir}"/.codex-*.md; do
  name="$(basename "$source")"
  target="${studio_repo}/${name}"

  if [[ -e "$target" && "$force" != "true" ]]; then
    echo "Skipping ${name}; target already exists. Use --force to overwrite."
    continue
  fi

  cp "$source" "$target"
  echo "Installed ${name} -> ${target}"
done
