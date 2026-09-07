---
description: Revisar que todo esté funcionando y decirte exactamente qué hacer si algo falta
---

Health check for a non-technical user. Print **at most 8 lines**. Every failure names an
**action**, never a diagnosis.

Never print raw stderr, a stack trace, or a file path the user did not ask for.
Never use the words "PATH", "binary", "MCP", "hook", or "cuarentena" in your output.

RUN THESE CHECKS, in order:

| Check | How | ✅ | ❌ says |
|---|---|---|---|
| Kit activo | plugin appears enabled in `claude plugin list` | `✅ El kit está andando` | `❌ El kit está apagado → escribí: claude plugin enable australis-dev@australis-dev` |
| Git | `git --version` | `✅ Git` | `❌ Falta Git → bajalo de git-scm.com/download/win, dale "Siguiente" a todo, y volvé a escribir /chequeo` |
| Carpeta usable | can create `.australis/` here | `✅ Puedo guardar en esta carpeta` | `❌ No puedo escribir acá → abrí Claude Code dentro de una carpeta tuya, por ejemplo Documentos\mis-apps` |
| Programa de memoria | `engram --version` | `✅ Memoria instalada` | `❌ Falta la memoria → escribí: /preparar memoria` |
| Memoria conectada | does the `mem_search` tool exist in this session? | `✅ Memoria conectada` | `❌ La memoria no se conectó → cerrá Claude Code, abrilo de nuevo, y escribí /chequeo` |
| GitHub (opcional) | `gh auth status` | `✅ GitHub` | `⚪ GitHub sin conectar — no hace falta todavía` |
| Nombres de archivo largos | `git config --global core.longpaths` | `✅ Nombres largos` | `⚪ Puede fallar al instalar cosas si tu usuario de Windows tiene el nombre largo → se arregla con: git config --global core.longpaths true` |

SPECIAL CASES:

- If the memory program was installed but the file is now missing, Windows Defender removed it.
  Say: `❌ Windows borró el archivo de la memoria → escribí: /preparar memoria` and offer the
  folder-exclusion walkthrough or working without memory, weighted equally.
- If `~/.claude/australis/memoria-off` exists, the user already declined memory on purpose.
  Report it as `⚪ Memoria desactivada por vos — escribí /preparar memoria si cambiás de idea` and
  do NOT treat it as a failure.

CLOSING LINE — always exactly one:

- All ✅ → `Todo listo. Contame qué querés construir y arrancamos.`
- Only memory or optional checks failing → `Podés trabajar igual. Lo de arriba lo arreglamos cuando quieras.`
- Git or folder failing → `Arreglá lo de arriba y volvé a escribir /chequeo.`

CONTEXT:

- Working directory: !`pwd`
- Git: !`git --version 2>/dev/null || echo "FALTA"`
- Memory program: !`engram --version 2>/dev/null || echo "FALTA"`
- GitHub: !`gh auth status 2>&1 | head -1 || echo "sin conectar"`
- Memory declined earlier: !`test -f "$HOME/.claude/australis/memoria-off" && echo "sí" || echo "no"`
- Long paths: !`git config --global core.longpaths 2>/dev/null || echo "no seteado"`
- Plugins: !`claude plugin list 2>/dev/null | head -10 || echo "(no disponible)"`
