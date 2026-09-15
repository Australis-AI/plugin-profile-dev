---
name: preparar
description: "Dejar la compu lista para trabajar con el kit: nivel, GitHub, firma de git y herramientas. Trigger: preparar el kit, terminar la instalación, configurar, cambiar el nivel, no me anda GitHub."
argument-hint: "[nivel]"
license: MIT
metadata:
  author: australis-ai
  version: "2.0"
---

# Setup Runbook

You finish the installation on this machine. `INSTALL.md` already installed the tools and the
plugin; you configure what a plugin cannot configure for itself. Run it once per machine, and
again any time something here breaks.

Speak Spanish with voseo, plainly. Never show raw stderr. Instructions below are for you; every
quoted line in Spanish is what the user sees.

Argument: $ARGUMENTS

- If the argument is `nivel`, run only **Step 1** (the level question) and **Step 5**, then stop.
- Otherwise run every step in order.

## Tools and shell

On Windows use the **PowerShell tool** for every command in this runbook, and call tools by
absolute path when a bare name is not found — a program installed during this session is not on
this session's PATH until Claude Code restarts:

| Tool | Absolute path on Windows |
|---|---|
| git | `$env:ProgramFiles\Git\cmd\git.exe` |
| gh | `$env:ProgramFiles\GitHub CLI\gh.exe` |
| node | `$env:ProgramFiles\nodejs\node.exe` |
| winget | `$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe` |

On macOS or Linux use Bash, and replace the winget step with the one install command for the
missing tool (`brew install gh`, the distro package, or nodejs.org).

## Absolute rules — violating any of these is a defect

1. **Never** use `--dangerously-skip-permissions`, never set `bypassPermissions`, never widen
   `permissions` in any settings file.
2. **Never** pipe a remote script into a shell (`curl | bash`, `iwr | iex`).
3. **Never** ask the user to hand-edit JSON, YAML, the registry, or the PATH.
4. **Never** disable or pause Windows Defender or any security product.
5. **Never** ask for a password, token, or recovery code in the chat. GitHub login happens in the
   browser.
6. **Never** ask a question that needs engineering knowledge.
7. **Never** modify the user's global `CLAUDE.md`, `settings.json`, or `.mcp.json` — with one
   exception: Step 7 may set `permissions.blockReadsOutsideWorkingDirectories` back to `false`,
   only after the user says yes to that exact change.
8. **Never** leave a half state. If a step fails, say which one in one line, finish the others,
   and let `/chequeo` point at it.

---

## Step 0 — Read the current state (silent)

Run these read-only checks in **one** PowerShell call and keep the results. Do not print them.

- git present: `Get-Command git` or the absolute path exists
- gh present, and `gh auth status` succeeds
- node present
- `git config --global user.name`, `git config --global user.email`, `git config --global core.longpaths`
- level file: `$HOME\.australis\nivel` (content `aprendiz` or `dev`)
- read block: `$HOME\.claude\settings.json` has `permissions.blockReadsOutsideWorkingDirectories` = `true`

Skip every later question whose answer is already known.

## Step 1 — One message with every question

Send a **single** message. Include only the parts that still apply:

> Vamos a dejar tu compu lista. Te hago todas las preguntas juntas:
>
> **1. ¿Cómo querés que trabajemos?**
>   a) Estoy aprendiendo — explicame cada paso
>   b) Ya programo — andá directo
>
> **2. ¿Ya tenés cuenta de GitHub?** (es donde se guarda tu trabajo y su historia) — sí / no
>
> **3. Si estás aprendiendo: ¿cómo se llama tu primera app?** Un nombre corto, por ejemplo
> `mis-gastos`. Si no sabés todavía, poné `mi-primera-app`.
>
> Dos avisos antes de empezar:
> - Claude Code te va a mostrar carteles pidiendo permiso para correr comandos. Son normales:
>   leé qué dice y aceptá.
> - En algún momento te va a preguntar si puede leer archivos del kit que están fuera de esta
>   carpeta. Elegí la opción que **permite** seguir leyendo. Nunca "Block from now on": eso
>   rompe el kit.
[If tools are missing, add the Step 2 notice here and ask for the grouped permission in this same message.]

Wait for the answer. Question 1 is skipped when the level file exists (except with the `nivel`
argument). Question 2 is skipped when `gh auth status` already succeeds. Question 3 only applies at
`aprendiz`, and is skipped when `$HOME\apps` already has a folder with a `.git` inside.

Turn the app name into a slug: lowercase, no accents, spaces to hyphens, only `a-z0-9-`.

## Step 2 — Missing tools (only if Git, GitHub CLI, or Node is missing)

`INSTALL.md` normally installed these. A machine that installed an older version of the kit may
lack them. Ask for **one** grouped permission, inside the Step 1 message:

> Te faltan herramientas: [Git / GitHub CLI / Node]. Las instalo ahora. Windows te va a pedir
> permiso de administrador hasta [N] veces: tocá "Sí". Si no ves la ventana, mirá el escudo que
> titila en la barra de tareas. ¿Dale?

Then install each missing one, one PowerShell call each, timeout 600000:

```
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe" install --id <Id> -e --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
```

| Tool | Id | Success check |
|---|---|---|
| Git | `Git.Git` | `Test-Path "$env:ProgramFiles\Git\cmd\git.exe"` |
| GitHub CLI | `GitHub.cli` | `Test-Path "$env:ProgramFiles\GitHub CLI\gh.exe"` |
| Node LTS | `OpenJS.NodeJS.LTS` | `Test-Path "$env:ProgramFiles\nodejs\node.exe"` |

Judge success by the path check, not by winget's exit code. If winget itself is missing, say:
*"Tu Windows no tiene el instalador de aplicaciones. Abrí Microsoft Store, buscá 'App Installer',
instalalo y escribí `/preparar` de nuevo."* and continue with the steps that do not need it.

Remember that something was installed: Step 8 needs it.

## Step 3 — GitHub

Skip if `gh auth status` already succeeds.

1. If the user has no account: open `https://github.com/signup` with `Start-Process` and say
   *"Creá tu cuenta en la página que se abrió. Cuando termines, escribí listo."* Wait.
2. Start the login as a **background** command (it never finishes until the user authorizes):
   `& "<gh>" auth login --hostname github.com --git-protocol https --web --clipboard`
3. Read its output until the one-time code (`XXXX-XXXX`) appears. Then open
   `https://github.com/login/device` with `Start-Process` and say:
   *"Se abrió GitHub. Pegá el código **XXXX-XXXX** (ya está copiado: Ctrl+V), tocá Continuar y
   después Authorize. No hace falta que escribas nada acá."*
4. Wait for the background command to finish. If the code expires, start it once more. If it
   fails again, say it in one line and move on.
5. Run `gh auth status` and `gh auth setup-git`.

## Step 4 — Git signature and long paths

- If `user.email` is empty and gh is logged in: read the account with
  `gh api user --jq '.id,.login,.name'` and set
  - `git config --global user.name "<name, or login if name is empty>"`
  - `git config --global user.email "<id>+<login>@users.noreply.github.com"`

  Tell the user in one line: *"Tus cambios van a quedar firmados con tu cuenta de GitHub."*
- If `user.email` already has a value, keep it.
- If `core.longpaths` is not `true`: `git config --global core.longpaths true`.

## Step 5 — Level

Write the level chosen in Step 1:

```
New-Item -ItemType Directory -Force "$HOME\.australis" | Out-Null
Set-Content -Path "$HOME\.australis\nivel" -Value "<aprendiz|dev>" -Encoding ascii
```

Confirm in one line: *"Listo: modo aprendiz."* or *"Listo: modo directo."*

## Step 6 — Updates

Updates of this kit do not arrive on their own until you enable them. Say:

> Para que el kit se actualice solo: escribí `/plugin`, entrá en **Marketplaces**, elegí
> **australis-dev** y tocá **Enable auto-update**. Es una sola vez.

## Step 7 — Read block (only if detected in Step 0)

> Antes bloqueaste que lea archivos fuera de esta carpeta, y eso deja al kit sin sus
> instrucciones. ¿Lo vuelvo a permitir? Es una sola línea de tu configuración de Claude.

Only on yes, set `permissions.blockReadsOutsideWorkingDirectories` to `false` in
`$HOME\.claude\settings.json`, preserving every other key.

## Step 8 — First app folder (aprendiz only, GitHub connected)

Create the project where npm works (never inside OneDrive), born on GitHub and cloned, so `main`
exists before any commit and the remote is configured from the first session in that folder:

```
New-Item -ItemType Directory -Force "$HOME\apps" | Out-Null
Set-Location "$HOME\apps"
& "<gh>" repo view "<login>/<slug>" *> $null
# if it does not exist:
& "<gh>" repo create "<login>/<slug>" --private --add-readme --gitignore Node --clone
# if it already exists and is not cloned here:
& "<gh>" repo clone "<login>/<slug>"
```

At `aprendiz`, this is where you teach `repositorio` for the first time.

## Step 9 — Close

- `aprendiz` with the app folder created:
  > Listo, tu compu está preparada y tu primera app ya tiene su lugar.
  > [If anything was installed in Step 2: Primero cerrá VS Code entero (Archivo → Salir) y abrilo de nuevo.]
  > Ahora: **Archivo → Abrir carpeta** → `%USERPROFILE%\apps\<slug>` → **Sí, confío en los
  > autores**. Ahí escribí `/nuevo` y contame qué querés que haga tu app.

  In a terminal instead of VS Code: `cd ~\apps\<slug>` and then `claude`.
- `dev`, or when the folder could not be created:
  - If anything was installed in Step 2:
    > Instalé herramientas nuevas, así que hace falta reiniciar una vez. Cerrá VS Code entero
    > (Archivo → Salir) o la terminal, abrilo de nuevo y escribí `/chequeo`.
  - Otherwise run the `/chequeo` checks now and show their result.
