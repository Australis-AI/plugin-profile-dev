#!/usr/bin/env bash
# Acceptance test — run this before handing the plugin to anyone.
#
#   bash test/aceptacion.sh
#
# Simulates a fresh Windows machine and installs the plugin from the real
# GitHub remote, exactly as a client would. Every check prints PASS or FAIL.
#
# Why the isolation matters: the author's machine has other tooling that leaves
# files in ~/.claude and binaries on PATH. Version 1 of this plugin appeared to
# work for two months because it silently read files another tool had installed.
# A test that runs in the author's own environment proves nothing.

set -u

REPO_SLUG="Australis-AI/plugin-profile-dev"
PLUGIN="australis-dev@australis-dev"

# Short paths on purpose: Windows caps paths at 260 characters unless
# core.longpaths is on, and the plugin cache nests deeply.
H="${TEST_HOME:-C:/t/acc-home}"
PROJ="${TEST_PROJ:-C:/t/acc-proj}"

pass=0; fail=0; skip=0
ok()   { printf '  \033[32mPASS\033[0m  %s\n' "$1"; pass=$((pass+1)); }
no()   { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; [ $# -gt 1 ] && printf '        %s\n' "$2"; fail=$((fail+1)); }
sk()   { printf '  ----  %s\n' "$1"; skip=$((skip+1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# ---------------------------------------------------------------- isolation --
head_ "0. Ambiente aislado"

if [ ! -f "$HOME/.claude/.credentials.json" ]; then
  echo "  No encuentro tus credenciales en \$HOME/.claude/.credentials.json." >&2
  echo "  Corré este script desde una sesión donde ya estés logueado." >&2
  exit 1
fi

rm -rf "$H" "$PROJ" 2>/dev/null
mkdir -p "$H/.claude" "$PROJ" || { echo "  No pude crear $H — probá con TEST_HOME=D:/t/h" >&2; exit 1; }
cp "$HOME/.claude/.credentials.json" "$H/.claude/.credentials.json"

# Strip tool-specific entries from PATH too. Isolating HOME alone is not enough:
# binaries installed system-wide still leak into the "clean" environment.
CLEAN_PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v -i -E 'engram|gentle-ai|scoop' | paste -sd: -)"

run() { env HOME="$H" USERPROFILE="$H" PATH="$CLEAN_PATH" "$@"; }

if [ -z "$(run claude plugin list 2>&1 | grep -i 'no plugins')" ]; then
  no "el ambiente no arrancó limpio" "$(run claude plugin list 2>&1 | head -3)"
else
  ok "ambiente limpio: sin plugins, sin CLAUDE.md, sin skills"
fi

run command -v engram >/dev/null 2>&1 && no "engram sigue en el PATH — el aislamiento filtra" || ok "sin engram en el PATH"

lp="$(git config --global core.longpaths 2>/dev/null)"
[ "$lp" = "true" ] && ok "core.longpaths activado" \
  || sk "core.longpaths no está activado — riesgo de 'Filename too long' con usuarios de nombre largo"

# ------------------------------------------------------------- installation --
head_ "1. Instalación, tal como la hace un cliente"

add_out="$(cd "$PROJ" && run claude plugin marketplace add "$REPO_SLUG" 2>&1)"
printf '%s' "$add_out" | grep -qi 'success' \
  && ok "marketplace add" \
  || no "marketplace add" "$(printf '%s' "$add_out" | tail -2)"

ins_out="$(cd "$PROJ" && run claude plugin install "$PLUGIN" --scope user 2>&1)"
printf '%s' "$ins_out" | grep -qi 'success' \
  && ok "plugin install --scope user" \
  || no "plugin install" "$(printf '%s' "$ins_out" | tail -2)"

VER="$(cd "$PROJ" && run claude plugin list 2>&1 | grep -A2 'australis-dev' | grep -i version | head -1 | tr -dc '0-9.')"
[ -n "$VER" ] && ok "instalado, versión $VER" || no "no aparece instalado"

cd "$PROJ" && run claude plugin list 2>&1 | grep -qi 'enabled' \
  && ok "queda habilitado" || no "no quedó habilitado"

P="$H/.claude/plugins/cache/australis-dev/australis-dev/${VER:-0.0.0}"

# --------------------------------------------------------------- integrity --
head_ "2. Integridad del paquete instalado"

if [ ! -d "$P" ]; then
  no "no encuentro el paquete instalado en $P"
else
  n_sk=$(find "$P/skills" -name SKILL.md 2>/dev/null | wc -l)
  n_ag=$(ls "$P/agents"/*.md 2>/dev/null | wc -l)
  n_cm=$(ls "$P/commands"/*.md 2>/dev/null | wc -l)
  [ "$n_sk" -ge 10 ] && ok "$n_sk skills" || no "solo $n_sk skills"
  [ "$n_ag" -ge 5 ]  && ok "$n_ag agentes" || no "solo $n_ag agentes"
  [ "$n_cm" -ge 4 ]  && ok "$n_cm comandos" || no "solo $n_cm comandos"
  [ -f "$P/hooks/hooks.json" ] && ok "hook presente" || no "falta hooks.json"
  [ -x "$P/scripts/memory-check.sh" ] && ok "script del hook ejecutable" \
    || no "el script del hook no tiene bit de ejecución" "el hook no va a correr"

  # This is the check that would have caught the v1 failure.
  broken=""
  while read -r ref; do
    [ -z "$ref" ] && continue
    rel="${ref#\$\{CLAUDE_PLUGIN_ROOT\}/}"
    [ -e "$P/$rel" ] || broken="$broken $ref"
  done <<< "$(grep -rho '\${CLAUDE_PLUGIN_ROOT}/[A-Za-z0-9_/.-]*' "$P" 2>/dev/null | sort -u)"
  [ -z "$broken" ] && ok "todas las referencias internas resuelven" \
    || no "referencias rotas:" "$broken"

  leak="$(grep -rl -E 'C:.Users|/Users/[a-z]|~/\.claude/skills|~/\.claude/CLAUDE|gentle-ai|\.atl/' "$P" 2>/dev/null | head -3)"
  [ -z "$leak" ] && ok "no depende de la máquina del autor" \
    || no "depende de rutas del autor:" "$leak"

  crlf="$(file "$P/scripts/memory-check.sh" 2>/dev/null | grep -c CRLF)"
  [ "${crlf:-0}" -eq 0 ] && ok "script sin CRLF" \
    || no "el script tiene CRLF" "Git Bash va a fallar con 'bad interpreter'"
fi

# ------------------------------------------------------------- degradation --
head_ "3. Degradación: qué pasa cuando falta algo"

if [ -x "$P/scripts/memory-check.sh" ]; then
  out="$(env PATH="$CLEAN_PATH" HOME="$H" bash "$P/scripts/memory-check.sh" 2>&1)"
  [ -z "$out" ] && ok "sin memoria instalada: no molesta" \
    || no "avisa a alguien que nunca tuvo memoria" "$out"

  mkdir -p "$H/.claude/australis" && touch "$H/.claude/australis/memoria-off"
  out="$(env PATH="$CLEAN_PATH" HOME="$H" bash "$P/scripts/memory-check.sh" 2>&1)"
  [ -z "$out" ] && ok "respeta al que dijo que no quiere memoria" \
    || no "insiste después de un no" "$out"
  rm -f "$H/.claude/australis/memoria-off"
fi

# ------------------------------------------------------------------ safety --
head_ "4. Seguridad"

if [ -d "$P" ]; then
  for pat in 'bypassPermissions' 'dangerously-skip-permissions'; do
    hits="$(grep -rn "$pat" "$P" 2>/dev/null | grep -v -i -E 'never|nunca' | head -1)"
    [ -z "$hits" ] && ok "sin $pat" || no "aparece $pat" "$hits"
  done
  hits="$(grep -rnE 'curl[^|]*\|[^|]*sh|iwr[^|]*\|[^|]*iex' "$P" 2>/dev/null | grep -v -i -E 'never|nunca' | head -1)"
  [ -z "$hits" ] && ok "sin descargar-y-ejecutar" || no "hay curl|bash" "$hits"

  grep -rqi 'default branch\|rama por defecto\|protected branch' "$P" 2>/dev/null \
    && ok "hay guarda de rama protegida" || no "no encuentro la guarda de rama"
fi

# ------------------------------------------------------------------ report --
head_ "Resultado"
printf '  %s PASS · %s FAIL · %s a revisar a mano\n\n' "$pass" "$fail" "$skip"

cat <<'PENDIENTE'
  Lo que este script NO puede probar — hacelo a mano:

  1. Un cliente real, en su Windows, sin ayuda, con solo el link del repo.
     Mirá dónde duda, dónde pregunta, dónde abandona.
  2. El flujo completo hasta código andando: pedí una app chica y contá
     cuántas veces tuvo que decidir algo. Más de 3 checkpoints = falla de diseño.
  3. Que nunca le pregunte algo que no pueda contestar (framework, base de
     datos, TDD). Si pasa una sola vez, es un bug.
  4. Instalar Engram siguiendo /preparar en una máquina con Defender activo.

PENDIENTE

[ "$fail" -eq 0 ] && exit 0 || exit 1
