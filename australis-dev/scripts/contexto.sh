#!/usr/bin/env bash
# Australis dev — repository and project context for the orchestrator.
#
#   bash contexto.sh
#
# Prints one "key: value" line per fact about the current folder: git and
# GitHub state, the open epic, how the project runs its tests, and the level.
# Read-only. Always exits 0, so a failed probe never aborts a command.
# Windows Git Bash safe: no jq (gh has its own --jq), node used only if present.

set -u
# No `set -e` and no ERR trap on purpose: most probes are expected to fail
# (no remote, no gh, unset config) and must not end the script early.

say() { printf '%s: %s\n' "$1" "${2:-}"; }

# --- tools -------------------------------------------------------------------
GH="$(command -v gh 2>/dev/null)"
[ -z "$GH" ] && [ -x "/c/Program Files/GitHub CLI/gh.exe" ] && GH="/c/Program Files/GitHub CLI/gh.exe"
NODE="$(command -v node 2>/dev/null)"
[ -z "$NODE" ] && [ -x "/c/Program Files/nodejs/node.exe" ] && NODE="/c/Program Files/nodejs/node.exe"

say node "$([ -n "$NODE" ] && "$NODE" --version 2>/dev/null || echo falta)"

# --- level -------------------------------------------------------------------
level="$(head -n 1 "$HOME/.australis/nivel" 2>/dev/null | tr -d '[:space:]')"
case "$level" in aprendiz|dev) ;; *) level="sin definir (aprendiz)" ;; esac
say nivel "$level"

# --- folder ------------------------------------------------------------------
here="$(pwd -W 2>/dev/null || pwd)"
say carpeta "$here"
case "$here" in *OneDrive*) say onedrive si ;; *) say onedrive no ;; esac

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  say repo no
  entries="$(ls -A 2>/dev/null | grep -v -E '^(\.australis|\.git)$' | wc -l | tr -d ' ')"
  say archivos_en_carpeta "$entries"
  exit 0
fi

say repo si
root="$(git rev-parse --show-toplevel 2>/dev/null)"
say raiz "$root"
cd "$root" 2>/dev/null || true

say firma_git "$(git config user.email >/dev/null 2>&1 && echo si || echo falta)"

remote="$(git remote get-url origin 2>/dev/null)"
say remoto "${remote:-ninguno}"

# --- default branch ----------------------------------------------------------
gh_ok=no
login=""
if [ -n "$GH" ] && "$GH" auth status >/dev/null 2>&1; then
  gh_ok=si
  login="$("$GH" api user --jq .login 2>/dev/null)"
fi
say github "$([ "$gh_ok" = si ] && echo "conectado como $login" || echo "sin conectar")"

default=""
nwo=""
case "$remote" in
  *github.com*)
    if [ "$gh_ok" = si ]; then
      nwo="$("$GH" repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)"
      default="$("$GH" repo view --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null)"
    fi
    ;;
esac
[ -z "$default" ] && default="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
if [ -z "$default" ]; then
  # init.defaultBranch counts only if that branch exists (Git for Windows ships "master").
  for b in "$(git config --get init.defaultBranch 2>/dev/null)" main master trunk develop; do
    [ -n "$b" ] && git show-ref --verify --quiet "refs/heads/$b" && { default="$b"; break; }
  done
fi
say repo_github "${nwo:-no}"
say rama_por_defecto "${default:-desconocida}"

current="$(git branch --show-current 2>/dev/null)"
say rama_actual "${current:-sin rama}"

commits_default=0
[ -n "$default" ] && commits_default="$(git rev-list --count "$default" 2>/dev/null || echo 0)"
say commits_en_rama_por_defecto "$commits_default"
say commits_totales "$(git rev-list --count --all 2>/dev/null || echo 0)"
say cambios_sin_commitear "$(git status --porcelain 2>/dev/null | grep -v '^?? \.australis/' | wc -l | tr -d ' ')"

if [ -n "$current" ] && [ -n "$default" ] && [ "$current" != "$default" ]; then
  ahead="$(git rev-list --count "$default..$current" 2>/dev/null || echo 0)"
  say commits_propios_de_la_rama "$ahead"
fi

# --- GitHub: repo type, epic, PR ------------------------------------------------
if [ -n "$nwo" ]; then
  tipo="una-persona"
  for f in CODEOWNERS .github/CODEOWNERS docs/CODEOWNERS; do
    [ -f "$f" ] && tipo="equipo"
  done
  if [ "$tipo" = "una-persona" ] && [ -n "$login" ]; then
    others="$("$GH" pr list --state all --limit 50 --json author,reviews \
      --jq '[.[].author.login, (.[].reviews[].author.login)] | unique | .[]' 2>/dev/null \
      | grep -v -x -F "$login" | grep -v -i 'bot' | head -1)"
    [ -n "$others" ] && tipo="equipo"
  fi
  say tipo_de_repo "$tipo"

  epic="$("$GH" issue list --label epica --state open --limit 5 --json number,title \
    --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null | paste -sd';' -)"
  say epica_abierta "${epic:-ninguna}"

  if [ -n "$current" ] && [ "$current" != "$default" ]; then
    pr="$("$GH" pr view "$current" --json number,state,reviewDecision \
      --jq '"#\(.number) \(.state) \(.reviewDecision // "")"' 2>/dev/null)"
    say pr_de_la_rama "${pr:-ninguno}"
  fi
fi

# --- project commands ----------------------------------------------------------
pm=npm
[ -f pnpm-lock.yaml ] && pm=pnpm
[ -f yarn.lock ] && pm=yarn
{ [ -f bun.lockb ] || [ -f bun.lock ]; } && pm=bun

script_of() {
  # Prints "<pm> run <name>" when package.json defines a real script <name>.
  [ -f package.json ] || return 0
  val=""
  if [ -n "$NODE" ]; then
    val="$("$NODE" -e "try{const s=require('./package.json').scripts||{};process.stdout.write(s['$1']||'')}catch(e){}" 2>/dev/null)"
  else
    val="$(grep -E "\"$1\"[[:space:]]*:" package.json | head -1 | sed 's/.*:[[:space:]]*"\(.*\)".*/\1/')"
  fi
  case "$val" in
    ""|*"no test specified"*) return 0 ;;
  esac
  if [ "$1" = test ]; then echo "$pm test"; else echo "$pm run $1"; fi
}

test_cmd="$(script_of test)"
if [ -z "$test_cmd" ]; then
  if [ -f pytest.ini ] || grep -q '\[tool.pytest' pyproject.toml 2>/dev/null; then test_cmd="pytest"
  elif [ -f go.mod ]; then test_cmd="go test ./..."
  elif [ -f Cargo.toml ]; then test_cmd="cargo test"
  elif grep -q '^test:' Makefile 2>/dev/null; then test_cmd="make test"
  fi
fi
say comando_test "${test_cmd:-ninguno}"
say comando_dev "$(script_of dev)"
say comando_build "$(script_of build)"
say comando_lint "$(script_of lint)"
say gestor_paquetes "$([ -f package.json ] && echo "$pm" || echo ninguno)"

if grep -q '^Stack: australis' README.md 2>/dev/null; then say stack australis; else say stack propio; fi

exit 0
