---
name: preparar
description: "Dejar el kit listo para trabajar: instala la memoria, arregla el PATH y verifica todo. Trigger: preparar el kit, terminar la instalación, configurar, no me anda la memoria."
license: MIT
metadata:
  author: australis-ai
  version: "1.0"
---

# Setup Runbook

You are walking a **non-technical user on Windows** through finishing the installation. They
already installed this plugin — that is why you exist. Your job is everything that a plugin
cannot do for itself.

Speak Spanish, plainly. One step at a time. Never show raw stderr.

## Absolute Rules — violating any of these is a defect

1. **Never** run with `--dangerously-skip-permissions`, never set `bypassPermissions`, never widen
   `permissions` in any `settings.json`.
2. **Never** pipe a remote script into a shell (`curl | bash`, `iwr | iex`). Download to a path you
   show the user, verify the checksum, and only run it after `--version` succeeds.
3. **Never** ask the user to hand-edit JSON, YAML, or the PATH.
4. **Never** disable or pause Windows Defender. A folder exclusion is the only permitted action,
   and *"seguimos sin memoria"* must be offered as an equally easy choice.
5. **Never** install Go, Node, Python, or any compiler.
6. **Always** `--scope user` when installing plugins.
7. **Never** leave a half state. If a step fails, record it and continue in files-only mode.
8. **Never** ask a question that needs engineering knowledge.
9. **Never** require a GitHub account to finish.
10. **Never** modify the user's global `CLAUDE.md`, `settings.json`, or `.mcp.json`.

---

## Step 0 — Is anything already done?

If the `mem_search` tool exists in this session, memory is already working. Skip to Step 4 and
just confirm. Do not reinstall.

## Step 1 — Git

Run `git --version`.

- Works → *"✅ Git listo."*
- Fails → *"Te falta Git. Bajalo de git-scm.com/download/win y dale 'Siguiente' a todo. Cuando
  termine, volvé y escribí `/preparar`."* Then STOP — nothing else works without it.

Git also gives us Git Bash, which the memory system needs. That is why it comes first.

## Step 2 — The memory plugin

Ask once, in plain terms:

> Te propongo instalar la memoria. Sirve para que me acuerde de tu proyecto entre sesiones, así no
> tenés que explicarme todo de nuevo cada vez. Son dos minutos. ¿Le damos?
>
>   a) Dale
>   b) Ahora no — podés seguir trabajando igual

If (b): write the marker (Step 5), tell them they can run `/preparar` any time, and skip to Step 4.

If (a), run these two, asking permission for each:

```
claude plugin marketplace add Gentleman-Programming/engram
claude plugin install engram --scope user
```

## Step 3 — The memory program

The plugin above is only the wiring. The actual program is a separate download.

1. Find the latest release asset for Windows:
   `gh release view --repo Gentleman-Programming/engram --json tagName,assets`
   Look for `engram_<version>_windows_amd64.zip` (or `_arm64` on ARM machines).
   If `gh` is unavailable, fetch the same information from the GitHub releases API.
2. Download it **and** `checksums.txt` to a path you show the user, under
   `%LOCALAPPDATA%\engram\bin`.
3. **Verify the checksum before extracting.** If it does not match, stop, delete the download, and
   tell the user the download failed and you are not going to run it. Offer to retry once.
4. Extract `engram.exe` to `%LOCALAPPDATA%\engram\bin`.
5. Add that folder to the user's PATH with `setx`, user scope only. Tell them what you did in one
   plain line.
6. Verify: `engram --version`.

### If the file disappears or will not run

Windows Defender flags this program because it is not signed by a company. The file is legitimate,
but Defender does not know that. Offer exactly two paths, equally weighted:

> Windows borró el archivo de la memoria. Pasa porque el programa no está firmado por una empresa
> — no es que tenga algo malo, es que Windows no lo conoce.
>
>   a) Te muestro los 4 clics para permitirlo y seguimos
>   b) Lo dejamos y trabajamos sin memoria — funciona igual, solo que no me acuerdo entre sesiones

For (a), walk them through adding a **folder exclusion** for `%LOCALAPPDATA%\engram\bin` in
Windows Security → Virus & threat protection → Manage settings → Exclusions → Add → Folder.
Four clicks, one folder. Never suggest turning protection off.

For (b), write the marker (Step 5) and move on without a hint of failure in your tone.

## Step 4 — Verify

Run the `/chequeo` flow and show its output.

Then tell them the one thing that actually matters:

> Ahora cerrá Claude Code y abrilo de nuevo. Es necesario para que la memoria se conecte.

After the restart, `mem_search` will exist and memory is live.

## Step 5 — Record the outcome

If memory was declined or failed, create the file `~/.claude/australis/memoria-off` (create the
directory if needed) with one line explaining which it was. `/chequeo` reads this to tell
"the user said no" apart from "it broke", so it stops re-offering something already declined.

If memory succeeded, delete that file if it exists.

## Step 6 — Offer the first build

Close with:

> Listo. ¿Querés que hagamos tu primera app juntos ahora? Contame qué te gustaría construir.

---

## Sub-command: `/preparar memoria`

Runs Steps 2–5 only. Use it when memory is the only thing broken.
