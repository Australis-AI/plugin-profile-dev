#!/usr/bin/env bash
# Australis dev — PreToolUse guard for shell commands (Bash and PowerShell tools).
#
# Enforces two non-negotiables deterministically, whatever the model remembers:
#   1. never commit or push to the repository's default branch;
#   2. never commit a secret (.env files, private keys, service-role or live keys).
#
# Exit 0 lets the command run. Exit 2 blocks it and the stderr message goes to
# Claude, which relays it. On an internal error while checking a commit, block
# (fail closed): a commit nobody could inspect is worse than a retry.
# Windows Git Bash safe: no jq.

set -u

input="$(cat)"

# Only git commit / git push matter. Anything else passes untouched.
git_prefix='git([[:space:]]+-[Cc][[:space:]]+[^[:space:]"]+)*[[:space:]]+'
is_commit=no; is_push=no
printf '%s' "$input" | grep -Eq "${git_prefix}commit([[:space:]]|\"|\\\\|$)" && is_commit=yes
printf '%s' "$input" | grep -Eq "${git_prefix}push([[:space:]]|\"|\\\\|$)" && is_push=yes
[ "$is_commit" = no ] && [ "$is_push" = no ] && exit 0

block() { printf '%s\n' "$1" >&2; exit 2; }

# Work in the directory the command runs in: -C <path> if given, else the hook cwd.
dir="$(printf '%s' "$input" | grep -Eo 'git[[:space:]]+-C[[:space:]]+[^[:space:]"]+' | head -1 | sed -E 's/git[[:space:]]+-C[[:space:]]+//')"
if [ -z "$dir" ]; then
  dir="$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
fi
dir="${dir//\\\\/\\}"
[ -n "$dir" ] && cd "$dir" 2>/dev/null

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

current="$(git branch --show-current 2>/dev/null)"

# origin/HEAD is authoritative. init.defaultBranch counts only if that branch
# exists: Git for Windows ships init.defaultBranch=master system-wide, which is
# wrong for every repo created with main.
default="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
if [ -z "$default" ]; then
  for b in "$(git config --get init.defaultBranch 2>/dev/null)" main master trunk; do
    [ -n "$b" ] && git show-ref --verify --quiet "refs/heads/$b" && { default="$b"; break; }
  done
fi
# Unborn repository (no commits yet): the branch you are on is the default one.
if [ -z "$default" ] && ! git rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
  default="$current"
fi

# --- push ------------------------------------------------------------------------
if [ "$is_push" = yes ] && [ -n "$default" ]; then
  if printf '%s' "$input" | grep -Eq "(:|[[:space:]])(refs/heads/)?${default}([[:space:]]|\"|\\\\|$)"; then
    block "Bloqueado: ese push apunta a '${default}', la rama por defecto. Lo que va a '${default}' entra sólo por un pull request mergeado. Pusheá la rama del cambio (git push -u origin HEAD) y abrí el PR."
  fi
  if [ "$current" = "$default" ] && ! printf '%s' "$input" | grep -Eq 'push[^"]*[[:space:]](origin[[:space:]]+)?(HEAD:)?(feat|fix|chore|docs|refactor|test|perf|style|build|ci|revert)/'; then
    block "Bloqueado: estás en '${default}' y ese push la actualizaría directo. Cambiá a la rama del cambio antes de pushear."
  fi
fi

[ "$is_commit" = no ] && exit 0

# --- commit ------------------------------------------------------------------------
if [ -n "$default" ] && [ "$current" = "$default" ]; then
  block "Bloqueado: no se commitea en '${default}', la rama por defecto. Creá la rama del cambio (feat/<issue>-<slug> o fix/<slug>) y commiteá ahí."
fi

if printf '%s' "$input" | grep -Eq "${git_prefix}add([[:space:]]|\"|$)"; then
  block "Bloqueado: git add y git commit van en dos pasos separados, así puedo revisar lo que se sube antes del commit. Corré primero git add y después el commit."
fi

all_flag=no
printf '%s' "$input" | grep -Eq 'commit[^"]*[[:space:]](-a|--all|-[a-zA-Z]*a[a-zA-Z]*)([[:space:]]|"|$)' && all_flag=yes

names="$(git diff --cached --name-only 2>/dev/null)" || block "Bloqueado: no pude revisar qué incluye el commit. Probá de nuevo."
diff="$(git diff --cached -U0 2>/dev/null)" || block "Bloqueado: no pude revisar qué incluye el commit. Probá de nuevo."
if [ "$all_flag" = yes ]; then
  names="$names
$(git diff --name-only 2>/dev/null)"
  diff="$diff
$(git diff -U0 2>/dev/null)"
fi

envfile="$(printf '%s\n' "$names" | grep -E '(^|/)\.env($|\.)' | grep -v -E '(^|/)\.env\.(example|sample|template)$' | head -1)"
[ -n "$envfile" ] && block "Bloqueado: el commit incluye '${envfile}', que guarda claves. Sacalo del stage (git restore --staged ${envfile}) y asegurate de que .gitignore tenga .env*. Lo que va al repo es .env.example, sin valores reales."

added="$(printf '%s\n' "$diff" | grep -E '^\+' | grep -v -E '^\+\+\+ ')"
secret_patterns='sb_secret_[A-Za-z0-9_-]{10,}|SERVICE_ROLE_KEY[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9._-]{20,}|-----BEGIN[A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk_live_[A-Za-z0-9]{10,}'
hit="$(printf '%s\n' "$added" | grep -Eo "$secret_patterns" | head -1)"
if [ -n "$hit" ]; then
  kind="${hit:0:12}"
  file="$(printf '%s\n' "$diff" | awk -v pat="$secret_patterns" '/^\+\+\+ b\//{f=substr($0,7)} /^\+/ && $0 ~ pat {print f; exit}')"
  block "Bloqueado: el commit trae una clave secreta (${kind}…) en '${file:-un archivo}'. Las claves van en .env.local, que no se sube. Sacala del código, dejá una variable de entorno y volvé a commitear."
fi

exit 0
