# Instalación — instrucciones para Claude

> Este archivo está dirigido a Claude Code, no a una persona. Si sos el usuario: abrí Claude Code,
> pegale el link de este repo y pedile que siga el `INSTALL.md`. Él se encarga.

Claude: seguí estos pasos y **nada más**. Todo lo que viene después lo hace `/preparar`, que existe
recién cuando termina el paso 3.

Hablá en castellano, llano, con voseo. En Windows usá la herramienta **PowerShell** para cada
comando. En macOS o Linux usá Bash e instalá lo que falte con el gestor del sistema (`brew`, el
paquete de la distro o nodejs.org).

## Paso 1 — Ver qué hay

En una sola llamada de PowerShell, sin mostrarle la salida al usuario, comprobá:

- `claude --version`
- Git: `Test-Path "$env:ProgramFiles\Git\cmd\git.exe"` o `Get-Command git`
- GitHub CLI: `Test-Path "$env:ProgramFiles\GitHub CLI\gh.exe"` o `Get-Command gh`
- Node: `Test-Path "$env:ProgramFiles\nodejs\node.exe"` o `Get-Command node`
- Si el plugin ya está instalado: `claude plugin list`, buscando `australis-dev`

Si el plugin ya está instalado, no lo reinstales: decile *"El kit ya está instalado. Escribí
`/preparar`."* y terminá.

## Paso 2 — Instalar lo que falte (sólo si falta Git, GitHub CLI o Node)

Git tiene que estar antes que el plugin: el kit se descarga con Git.

Pedí **un solo** permiso para todo, con este aviso:

> Para usar el kit te faltan: [Git / GitHub CLI / Node]. Los instalo ahora. Windows te va a pedir
> permiso de administrador hasta [N] veces: tocá "Sí". Si no ves la ventana, mirá el escudo que
> titila en la barra de tareas. ¿Dale?

Con el sí, instalá cada uno en su propia llamada de PowerShell, con timeout 600000:

```
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe" install --id <Id> -e --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
```

| Herramienta | Id | Quedó instalada si existe |
|---|---|---|
| Git | `Git.Git` | `$env:ProgramFiles\Git\cmd\git.exe` |
| GitHub CLI | `GitHub.cli` | `$env:ProgramFiles\GitHub CLI\gh.exe` |
| Node LTS | `OpenJS.NodeJS.LTS` | `$env:ProgramFiles\nodejs\node.exe` |

Juzgá el resultado por la ruta, no por el código de salida de winget.

Si no existe `winget.exe`, decí: *"Tu Windows no tiene el instalador de aplicaciones. Abrí
Microsoft Store, buscá 'App Installer', instalalo y pegame de nuevo el mensaje del principio."* y
pará.

Si instalaste algo, imprimí esto y terminá. Es el único reinicio:

```
Instalé las herramientas. Hace falta reiniciar una sola vez:
cerrá VS Code entero (Archivo → Salir) o la terminal, abrilo de nuevo
y pegame el mismo mensaje del principio.
```

## Paso 3 — Instalar el plugin

**Si `claude` responde en PowerShell**, corré:

```
claude plugin marketplace add Australis-AI/plugin-profile-dev
claude plugin install australis-dev@australis-dev --scope user
```

`--scope user` no es opcional: hace que el kit esté disponible en todas las carpetas.

**Si `claude` no responde** (pasa con la extensión de VS Code sola), pedile al usuario que escriba
en el chat, de a una:

```
/plugin marketplace add Australis-AI/plugin-profile-dev
/plugin install australis-dev@australis-dev
```

y que elija instalarlo para su usuario.

Después imprimí exactamente esto y terminá:

```
✅ Listo, el kit está instalado.

Escribí /reload-plugins para cargarlo (si te avisa algo del caché: /reload-plugins --force).
Después escribí:  /preparar
```

---

## Reglas para vos, Claude

- **No** configures GitHub, la firma de git ni el nivel acá: eso es de `/preparar`, que se
  actualiza con el plugin. Este archivo no.
- **Nunca** uses `--dangerously-skip-permissions` ni cambies permisos en ningún `settings.json`.
- **Nunca** bajes y ejecutes un script remoto.
- **Nunca** desactives Windows Defender ni ningún antivirus.

Este archivo es un cargador de arranque, no un instalador completo. Su único trabajo es dejar las
herramientas y `/preparar` en la máquina. Si crece más allá de estos tres pasos, la instalación se
vuelve imposible de arreglar sin que el usuario vuelva al repo.

## Si ya programás y querés el kit sólo en algunos repos

No lo instales a scope user. En cambio:

```
claude plugin marketplace add Australis-AI/plugin-profile-dev    # una vez por máquina
claude plugin install australis-dev@australis-dev --scope local  # en cada repo donde lo quieras
```
