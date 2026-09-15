# Material para enseñar — nivel aprendiz

Read this only at level `aprendiz`. It holds the stage names and the concepts to explain the
first time each one appears. The words below are what the user sees; adapt them to the
conversation, keep them short.

## How to teach a concept

1. Check the session-start line: if the concept id is already listed as explained, give one line
   at most, and only if it helps.
2. Otherwise explain it in this shape, right when it happens, never as a lesson up front:
   - **El problema** — one line.
   - **La idea** — up to three lines, plain words, an everyday analogy only if it clarifies.
   - **Para verlo vos** — one concrete thing they can look at or do now.
3. Record it: `Add-Content -Path "$HOME\.australis\ensenado" -Value "<id>"`.
4. If they say "ya sé" or "no hace falta", record it without explaining.

Never explain more than one concept in the same message. If two appear at once, explain the one
the user has to act on and leave the other for its next appearance.

## Stages

Name the stage when you enter it, with its reason in one line.

| Etapa | Qué pasa | Por qué frenamos ahí |
|---|---|---|
| Entender | Te pregunto qué querés lograr y para quién | Cambiar una idea cuesta un minuto; cambiar código, una hora |
| Acordar | Armamos la épica y la lista de pasos, y la aprobás | Así los dos sabemos qué significa "terminado" antes de empezar |
| Construir | Hago un paso por vez, en su propia rama | Si algo sale mal, no rompe lo que ya anda |
| Probar | Te muestro que cumple lo acordado y lo probás vos | Nada se da por hecho sin verlo funcionar |
| Integrar | Sumo el paso a la versión principal | Lo aprobado pasa a ser la base del siguiente paso |
| Publicar | La app queda en internet | Sale siempre de la versión principal, nunca de algo a medio hacer |

## Concepts

### `repositorio` — repositorio y GitHub
- **El problema:** si tu proyecto vive sólo en tu compu, se pierde con la compu y no hay forma de
  volver atrás.
- **La idea:** un repositorio es la carpeta del proyecto con toda su historia guardada. GitHub
  guarda una copia en internet, así que tu trabajo queda respaldado y se puede compartir.
- **Para verlo vos:** abrí el link del repo en el navegador: ahí está todo lo que hicimos.

### `epica` — épica e issues
- **El problema:** una app entera es demasiado grande para hacerla de una vez sin perderse.
- **La idea:** la épica es el objetivo grande y su lista de pasos. Cada paso es un issue: una
  tarjeta con qué tiene que pasar para darlo por terminado. La épica es la única lista de
  pendientes.
- **Para verlo vos:** en GitHub, pestaña **Issues**: está la épica y un issue por paso.

### `rama` — rama
- **El problema:** si trabajás directo sobre la versión que anda, un error la rompe.
- **La idea:** una rama es una copia de trabajo separada. Construimos ahí, y la versión principal
  (`main`) no se toca hasta que lo nuevo está probado.
- **Para verlo vos:** abajo a la izquierda en VS Code aparece el nombre de la rama en la que
  estamos.

### `commit` — commit
- **El problema:** sin puntos de guardado, no se puede volver a un momento en que andaba.
- **La idea:** un commit es un punto de guardado con una descripción de qué cambió. Se van
  sumando y forman la historia del proyecto.
- **Para verlo vos:** en GitHub, entrá a la rama y tocá **Commits**.

### `pr` — pull request
- **El problema:** hace falta un lugar para mirar un cambio completo antes de sumarlo.
- **La idea:** un pull request (PR) es la propuesta de sumar una rama a la versión principal.
  Muestra qué cambió, por qué y cómo se comprobó.
- **Para verlo vos:** en GitHub, pestaña **Pull requests**.

### `revision` — revisión
- **El problema:** quien escribió el código es quien peor ve sus propios errores.
- **La idea:** antes de sumar un cambio, alguien que no lo escribió lo revisa buscando fallas. En
  un proyecto tuyo lo hace un revisor automático; en un equipo, una persona.
- **Para verlo vos:** en el PR, la sección **Verification** y los comentarios de revisión.

### `merge` — integrar (merge)
- **El problema:** lo aprobado tiene que pasar a ser la base del próximo paso.
- **La idea:** integrar suma la rama a la versión principal y cierra el issue. La rama ya no hace
  falta y se borra.
- **Para verlo vos:** el issue aparece como **Closed** y el PR como **Merged**.

### `evidencia` — tests y evidencia
- **El problema:** "creo que anda" no alcanza: algo que andaba ayer se puede romper mañana.
- **La idea:** un test es un pequeño programa que comprueba solo que la app hace lo acordado. Se
  corre cada vez, y si algo se rompe avisa antes de que lo notes vos.
- **Para verlo vos:** en el PR, cada punto de "listo cuando" tiene su comprobación al lado.

### `secretos` — secretos
- **El problema:** una clave publicada por error le da acceso a tus datos a cualquiera.
- **La idea:** las claves viven en un archivo `.env.local` que nunca se sube a GitHub. El kit
  frena cualquier intento de subir una.
- **Para verlo vos:** el archivo `.gitignore` lista lo que nunca se sube; `.env*` está ahí.

### `deploy` — publicar (deploy)
- **El problema:** una app que sólo corre en tu compu no la puede usar nadie más.
- **La idea:** publicar pone la versión principal en un servidor con una dirección web. Cada vez
  que integrás un paso, se publica solo.
- **Para verlo vos:** abrí la dirección de tu app desde el celular.
