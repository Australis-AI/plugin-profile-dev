#!/usr/bin/env bash
# Fixtures for scripts/guard.sh — the PreToolUse hook that blocks commits on the
# default branch and committed secrets.
#
#   bash test/guard.sh [path/to/guard.sh]
#
# Builds a throwaway repository, feeds the hook the JSON Claude Code sends for
# the Bash and PowerShell tools, and checks the exit code of every scenario.
# Exit 0 when every scenario matches, 1 otherwise.

set -u

G="${1:-$(cd "$(dirname "$0")/.." && pwd)/australis-dev/scripts/guard.sh}"
[ -f "$G" ] || { echo "no encuentro $G" >&2; exit 1; }

pass=0; fail=0
T="$(mktemp -d)"
trap 'cd /; rm -rf "$T"' EXIT
cd "$T" || exit 1

git init -q -b main
git config user.email t@example.com
git config user.name test
git config core.autocrlf false
echo hi > a.txt && git add a.txt && git commit -qm init

WIN="$( (pwd -W 2>/dev/null || pwd) | sed 's#/#\\\\\\\\#g')"
payload() { printf '{"session_id":"t","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"command":"%s"}}' "$WIN" "$1" "$2"; }
check() {
  out="$(payload "$1" "$2" | bash "$G" 2>&1)"; rc=$?
  if [ "$rc" -eq "$3" ]; then
    printf '  PASS  %s\n' "$4"; pass=$((pass+1))
  else
    printf '  FAIL  %s (exit %s, esperaba %s) %s\n' "$4" "$rc" "$3" "${out:0:80}"; fail=$((fail+1))
  fi
}

check Bash       "ls -la"                         0 "un comando que no es git pasa"
check Bash       "git log --grep commit"          0 "git log que menciona commit pasa"
check Bash       "git commit -m x"                2 "commit en main se bloquea"
check PowerShell "git commit -m x"                2 "commit en main se bloquea (PowerShell)"
check Bash       "git push"                       2 "push parado en main se bloquea"

git checkout -q -b feat/1-demo
check PowerShell "git commit -m x"                0 "commit limpio en una rama de issue pasa"

echo "SECRET=1" > .env && git add -f .env
check Bash       "git commit -m x"                2 ".env en el commit se bloquea"
git restore --staged .env && rm .env

echo "EXAMPLE=" > .env.example && git add .env.example
check Bash       "git commit -m x"                0 ".env.example pasa"
git commit -qm example

echo "const url = 'sb_publishable_abcdefghijklmnop'" > pub.ts && git add pub.ts
check Bash       "git commit -m x"                0 "clave publishable de Supabase pasa"
git commit -qm pub

echo "const k = 'sb_secret_abcdefghijklmnop123'" > sec.ts && git add sec.ts
check PowerShell "git commit -m x"                2 "clave secret de Supabase se bloquea (PowerShell)"
git restore --staged sec.ts && rm sec.ts

printf -- '-----BEGIN RSA PRIVATE KEY-----\nabc\n' > key.pem && git add key.pem
check Bash       "git commit -m x"                2 "clave privada se bloquea"
git restore --staged key.pem && rm key.pem

check Bash       "git add . && git commit -m x"   2 "add y commit en el mismo comando se bloquea"

echo "token ghp_abcdefghijklmnopqrstuvwxyz0123" >> pub.ts
check Bash       "git commit -am x"               2 "commit -am con un token en un archivo trackeado se bloquea"
git checkout -q pub.ts

check Bash       "git push -u origin HEAD"        0 "push de la rama del issue pasa"
check Bash       "git push origin main"           2 "push a main se bloquea"
check Bash       "git push origin HEAD:main"      2 "push HEAD:main se bloquea"

printf '\n  guard: %s PASS · %s FAIL\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
