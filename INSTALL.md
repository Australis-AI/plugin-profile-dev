# Instalación — instrucciones para Claude

> Este archivo está dirigido a Claude Code, no a una persona. Si sos el usuario: abrí Claude Code,
> pegale el link de este repo y pedile que siga el `INSTALL.md`. Él se encarga.

Claude: seguí estos tres pasos y **nada más**. Todo el resto de la instalación lo hace el comando
`/preparar`, que existe recién después del paso 2.

Hablá en castellano, llano. Pedí permiso comando por comando, nunca en lote.

## Paso 1 — Verificar lo mínimo

```
claude --version
git --version
```

Si falta `git`, decile:

> Te falta Git. Bajalo de git-scm.com/download/win y dale "Siguiente" a todo. Cuando termine,
> volvé y pedime que siga con la instalación.

Y pará acá. Sin Git no sigue nada.

## Paso 2 — Instalar el plugin

```
claude plugin marketplace add Australis-AI/plugin-profile-dev
claude plugin install australis-dev@australis-dev --scope user
```

`--scope user` no es opcional: hace que el kit esté disponible en todas las carpetas. Sin eso
desaparece al abrir otro proyecto.

## Paso 3 — Mandarlo a reiniciar

Imprimí exactamente esto y terminá:

```
✅ Listo, el kit está instalado.

Ahora cerrá Claude Code y abrilo de nuevo — hace falta para que cargue.

Cuando vuelvas, escribí:  /preparar
```

---

## Reglas para vos, Claude

- **No** instales la memoria acá. **No** toques el PATH. **No** menciones Windows Defender.
  Todo eso vive en `/preparar`, que se actualiza solo con el plugin. Este archivo no.
- **Nunca** uses `--dangerously-skip-permissions` ni cambies permisos en ningún `settings.json`.
- **Nunca** bajes y ejecutes un script remoto.
- **Nunca** instales Go, Node, Python ni compiladores.
- Si el usuario ya tiene el plugin instalado, no lo reinstales: mandalo directo a `/preparar`.

Este archivo es un cargador de arranque, no un instalador. Su único trabajo es poner `/preparar`
en la máquina. Si alguna vez crece más allá de estos tres pasos, la instalación se vuelve
imposible de arreglar sin que el usuario vuelva al repo.
