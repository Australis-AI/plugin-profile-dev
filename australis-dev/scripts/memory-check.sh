#!/usr/bin/env bash
# Australis dev — SessionStart memory check.
#
# Warns exactly once per session when the memory program is installed but its
# plugin is missing or disabled: the state where the user HAD memory and
# silently lost it. That is the case worth interrupting for.
#
# Silent in every other case. Never fails a session — always exits 0.
# Windows Git Bash safe: no jq, no curl, no date arithmetic, no subshell loops.

set -u
trap 'exit 0' ERR

CONFIG_DIR="${HOME}/.claude/australis"

# 1. The user deliberately turned memory off. Say nothing, ever.
[ -f "${CONFIG_DIR}/memoria-off" ] && exit 0

# 2. Memory program not installed at all. /preparar owns that conversation.
command -v engram >/dev/null 2>&1 || exit 0

# 3. Program is installed. Is its plugin present AND enabled?
command -v claude >/dev/null 2>&1 || exit 0

STATE="unknown"

# Preferred: structured output. Fields are emitted in a stable order, so once we
# see the engram entry the next "enabled" line belongs to it.
if LISTING="$(claude plugin list --json 2>/dev/null)" && [ -n "${LISTING}" ]; then
  STATE="missing"
  # Put each plugin object on its own line so a compact (single-line) response
  # cannot let one plugin's id pair with another plugin's enabled flag.
  LISTING="${LISTING//\},/\}$'\n'}"
  in_engram=0
  while IFS= read -r line; do
    case "${line}" in *'"id"'*'engram@engram'*) in_engram=1 ;; esac
    if [ "${in_engram}" -eq 1 ]; then
      case "${line}" in
        *'"enabled"'*true*)  STATE="enabled";  break ;;
        *'"enabled"'*false*) STATE="disabled"; break ;;
      esac
    fi
  done <<EOF
${LISTING}
EOF
else
  # Fallback for builds without --json: presence only, no enabled state.
  LISTING="$(claude plugin list 2>/dev/null || true)"
  [ -z "${LISTING}" ] && exit 0
  case "${LISTING}" in
    *engram*) STATE="enabled" ;;
    *)        STATE="missing" ;;
  esac
fi

# Healthy, or we could not tell. Either way, stay quiet.
[ "${STATE}" = "enabled" ] && exit 0
[ "${STATE}" = "unknown" ] && exit 0

# 4. Program installed, plugin missing or disabled → surface it once.
if [ "${STATE}" = "disabled" ]; then
  FIX="está instalado pero apagado"
else
  FIX="no aparece instalado"
fi

cat <<NOTICE
## Australis — nota de memoria

El programa de memoria (engram) está instalado en esta máquina, pero su plugin ${FIX}
en Claude Code. Es el caso típico de "se desconectó solo".

Decíselo al usuario UNA sola vez, en una línea, sin alarma y sin jerga. Por ejemplo:

> Ojo: la memoria está instalada pero no conectada, así que por ahora no me acuerdo entre
> sesiones. Se arregla en un minuto con \`/chequeo\`.

Seguí trabajando normal — los artefactos se guardan igual en archivos, en \`.australis/\`.
No repitas el aviso más adelante en esta sesión.
NOTICE

exit 0
