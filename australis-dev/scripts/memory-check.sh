#!/usr/bin/env bash
# Australis dev — SessionStart memory check.
#
# Warns exactly once per session when the memory program is installed but its
# plugin is not connected: the state where the user HAD memory and silently lost it.
#
# Silent in every other case. Never fails a session — always exits 0.
# Windows Git Bash safe: no jq, no curl, no date arithmetic.

set -u

# Never let this hook break a session.
trap 'exit 0' ERR

CONFIG_DIR="${HOME}/.claude/australis"

# 1. The user deliberately turned memory off. Say nothing, ever.
if [ -f "${CONFIG_DIR}/memoria-off" ]; then
  exit 0
fi

# 2. Memory program not installed at all. /preparar owns that conversation, not us.
if ! command -v engram >/dev/null 2>&1; then
  exit 0
fi

# 3. Program is installed. Is its plugin connected?
#    `claude plugin list` is the cheapest reliable signal; if it is unavailable
#    or slow, stay silent rather than guess.
PLUGINS=""
if command -v claude >/dev/null 2>&1; then
  PLUGINS="$(claude plugin list 2>/dev/null || true)"
fi

if [ -z "${PLUGINS}" ]; then
  exit 0
fi

case "${PLUGINS}" in
  *engram*)
    # Present. Whether its MCP tools actually registered is something the model
    # checks at use time via tool presence — not something a shell can see.
    exit 0
    ;;
esac

# 4. Program installed, plugin absent → the disconnect case worth surfacing.
cat <<'NOTICE'
## Australis — nota de memoria

El programa de memoria (engram) está instalado en esta máquina, pero su plugin no aparece
conectado en Claude Code. Es el caso típico de "se desconectó solo".

Decíselo al usuario UNA sola vez, en una línea, sin alarma y sin jerga. Por ejemplo:

> Ojo: la memoria está instalada pero no conectada, así que por ahora no me acuerdo entre
> sesiones. Se arregla en un minuto con `/chequeo`.

Seguí trabajando normal — los artefactos se guardan igual en archivos, en `.australis/`.
No repitas el aviso más adelante en esta sesión.
NOTICE

exit 0
