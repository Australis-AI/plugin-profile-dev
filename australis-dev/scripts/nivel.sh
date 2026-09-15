#!/usr/bin/env bash
# Australis dev — SessionStart level hook.
#
# Tells the model which level this machine is set to (aprendiz | dev) and which
# concepts were already taught, so the persona adapts its depth without asking.
#
# Silent when the level file does not exist: /preparar has not run yet, and the
# orchestrator treats a missing level as aprendiz. Never fails a session.
# Windows Git Bash safe: no jq, no subshell loops.

set -u
trap 'exit 0' ERR

DIR="${HOME}/.australis"
LEVEL_FILE="${DIR}/nivel"
TAUGHT_FILE="${DIR}/ensenado"

[ -f "${LEVEL_FILE}" ] || exit 0

level="$(head -n 1 "${LEVEL_FILE}" 2>/dev/null | tr -d '[:space:]')"
case "${level}" in
  aprendiz|dev) ;;
  *) exit 0 ;;
esac

taught="ninguno"
if [ -s "${TAUGHT_FILE}" ]; then
  taught="$(tr -d '\r' < "${TAUGHT_FILE}" | grep -v '^[[:space:]]*$' | paste -sd, -)"
  [ -n "${taught}" ] || taught="ninguno"
fi

printf 'Australis: nivel del usuario = %s. Conceptos ya explicados en esta máquina: %s.\n' "${level}" "${taught}"
exit 0
