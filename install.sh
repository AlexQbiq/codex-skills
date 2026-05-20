#!/usr/bin/env bash
set -euo pipefail

mode="symlink"
codex_skills_dir="${HOME}/.codex/skills"
force="false"
skills=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="$2"
      shift 2
      ;;
    --codex-skills-dir)
      codex_skills_dir="$2"
      shift 2
      ;;
    --skill)
      skills+=("$2")
      shift 2
      ;;
    --force)
      force="true"
      shift
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: ./install.sh [--mode copy|symlink] [--codex-skills-dir PATH] [--skill NAME] [--force]

Installs skills from ./skills into the Codex skills directory.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "$mode" != "copy" && "$mode" != "symlink" ]]; then
  echo "--mode must be copy or symlink" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_root="${repo_root}/skills"

if [[ ! -d "$source_root" ]]; then
  echo "Skills source directory not found: $source_root" >&2
  exit 1
fi

mkdir -p "$codex_skills_dir"

install_skill() {
  local name="$1"
  local source="${source_root}/${name}"
  local target="${codex_skills_dir}/${name}"

  if [[ ! -f "${source}/SKILL.md" ]]; then
    echo "Unknown skill: ${name}" >&2
    exit 1
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ "$force" != "true" ]]; then
      echo "Skipping ${name}; target already exists: ${target}"
      return
    fi

    rm -rf "$target"
  fi

  if [[ "$mode" == "symlink" ]]; then
    ln -s "$source" "$target"
  else
    cp -R "$source" "$target"
  fi

  echo "Installed ${name} -> ${target} (${mode})"
}

if [[ ${#skills[@]} -gt 0 ]]; then
  for skill in "${skills[@]}"; do
    install_skill "$skill"
  done
else
  while IFS= read -r skill_path; do
    install_skill "$(basename "$skill_path")"
  done < <(find "$source_root" -mindepth 1 -maxdepth 1 -type d | sort)
fi
