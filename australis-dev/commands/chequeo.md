---
description: Revisar que todo esté funcionando y decirte exactamente qué hacer si algo falta
---

Health check. Print **at most 10 lines**. Every failure names an **action**, never a diagnosis.

Never print raw stderr, a stack trace, or a file path the user did not ask for.
Never use the words "PATH", "binary", "MCP", "hook", or "cuarentena" in your output.

## How to gather

On Windows, run every check below in **one** PowerShell tool call. Call tools by absolute path
when the bare name is not found (`$env:ProgramFiles\Git\cmd\git.exe`,
`$env:ProgramFiles\GitHub CLI\gh.exe`, `$env:ProgramFiles\nodejs\node.exe`). On macOS or Linux,
use the Bash equivalents. All checks are read-only.

## Checks, in this order

| Check | How | ✅ | ❌ or ⚪ says |
|---|---|---|---|
| Git | git present | `✅ Git` | `❌ Falta Git → escribí /preparar` |
| Firma | `git config --global user.email` not empty | `✅ Tus cambios van firmados` | `❌ Falta tu firma → escribí /preparar` |
| GitHub | gh present and `gh auth status` succeeds | `✅ GitHub conectado` | `❌ GitHub sin conectar → escribí /preparar` |
| Node | node present | `✅ Node` | `⚪ Falta Node — hace falta para crear apps → escribí /preparar` |
| Carpeta | can create a file here: write and delete `.chequeo.tmp` with `[IO.File]::WriteAllText` and `[IO.File]::Delete` (not `Remove-Item`: Claude Code's safety check can block the whole call) | `✅ Puedo guardar en esta carpeta` | `❌ No puedo escribir acá → abrí Claude Code en una carpeta tuya, por ejemplo %USERPROFILE%\apps` |
| OneDrive | current folder is under OneDrive | — (no line when not under OneDrive) | `⚪ Esta carpeta está en OneDrive — para apps nuevas usá %USERPROFILE%\apps` |
| Nombres largos | `git config --global core.longpaths` is `true` | `✅ Nombres largos` | `⚪ Puede fallar con nombres de archivo largos → escribí /preparar` |
| Lectura del kit | `permissions.blockReadsOutsideWorkingDirectories` in `$HOME\.claude\settings.json` is not `true` | — (no line when fine) | `❌ Bloqueaste la lectura del kit → escribí /preparar` |
| Nivel | `$HOME\.australis\nivel` contains `aprendiz` or `dev` | `✅ Modo aprendiz` / `✅ Modo directo` | `⚪ Sin nivel elegido → escribí /preparar nivel` |
| Versión | installed version in `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` vs. published version from `gh api repos/Australis-AI/plugin-profile-dev/contents/australis-dev/.claude-plugin/plugin.json --jq .content`, decoded with `[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(...))` | `✅ Kit al día (vX.Y.Z)` | `⚪ Hay una versión nueva → /plugin → Marketplaces → australis-dev → Update, y después /reload-plugins` |

Skip the Versión line silently when gh is missing or offline.

## Closing line — always exactly one

- All ✅ → `Todo listo. Contame qué querés construir y arrancamos.`
- Only ⚪ lines → `Podés trabajar igual. Lo de arriba lo arreglamos cuando quieras.`
- Any ❌ → `Arreglá lo de arriba y volvé a escribir /chequeo.`
