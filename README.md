# Australis Dev

La metodología de desarrollo de Australis, empaquetada como plugin de Claude Code.

Sirve para construir software con un plan acordado antes de escribir código, y para verificar al
final que hace exactamente lo que se acordó. Está pensado para que lo pueda usar alguien que no
programa — y para que le sirva igual a alguien que sí.

## Cómo se instala

Abrí Claude Code en cualquier carpeta y pegale esto:

```
Instalá el kit de Australis: https://github.com/Australis-AI/plugin-profile-dev
Leé el INSTALL.md de ese repo y seguilo paso a paso.
```

Claude hace el resto. Si te faltan herramientas, te pide permiso una sola vez para instalarlas y
te avisa de los carteles de Windows. Como mucho vas a reiniciar una vez. Cuando termine, escribí
`/preparar`: ahí elegís cómo querés trabajar, conectás GitHub y queda todo listo.

Si preferís hacerlo a mano:

```bash
claude plugin marketplace add Australis-AI/plugin-profile-dev
claude plugin install australis-dev@australis-dev --scope user
# en Claude Code: /reload-plugins, y después:
/preparar
```

### Qué necesitás

| | Para qué | ¿Quién lo instala? |
|---|---|---|
| **Claude Code** | Es donde corre todo | Vos |
| **Cuenta de GitHub** | Es donde se guarda tu trabajo y su historia | Vos (gratis); `/preparar` te guía |
| **Git** | Para guardar tu trabajo y manejar las ramas | La instalación, con tu permiso |
| **GitHub CLI (`gh`)** | Para que el kit trabaje con GitHub por vos | La instalación, con tu permiso |
| **Node** | Para crear y correr apps | La instalación, con tu permiso |

Funciona en Windows, macOS y Linux. En Windows todo se instala con el instalador de aplicaciones
del sistema (winget): nada de descargar programas sueltos.

## Cómo se usa

La mayoría de las veces no hace falta ningún comando: le decís qué querés construir y arranca solo.

| Comando | Para qué |
|---|---|
| `/nuevo` | Arrancar algo nuevo: entendemos qué querés, armamos la épica y la aprobás |
| `/construir` | Construir el próximo paso de la épica y mostrarte que anda |
| `/seguir` | Retomar donde quedaste, en otra sesión o en otra compu |
| `/publicar` | Poner tu app en internet (la primera vez te guío; después se publica sola) |
| `/juzgar` | Revisión a fondo: dos revisores ciegos sobre el mismo cambio |
| `/auditar` | Revisar el proyecto entero (o un área): seguridad, cómo está armada la base de datos, si conviene una API, y qué conviene hacer distinto. Lo que elijas se vuelve issues |
| `/preparar` | Dejar la compu lista (una vez); `/preparar nivel` cambia cómo trabajamos |
| `/chequeo` | Ver si algo se rompió, y qué hacer exactamente |

### El método

```
entender ─▶ acordar ─▶ construir ─▶ probar ─▶ integrar ─▶ publicar
            (épica)    (un issue)   "Esto anda"  (PR)
```

Es la forma de trabajar de un equipo profesional, y el kit la opera por vos:

1. **Entender.** Te hago unas pocas preguntas sobre qué querés lograr y para quién.
2. **Acordar.** Armo una **épica** en GitHub: el objetivo y la lista de pasos. Los pasos se
   agrupan en **milestones**, tramos que al cerrarse te dejan algo que ya podés usar, y se
   construyen uno después del otro. Cada paso es un **issue** con su "listo cuando". La aprobás
   una vez.
3. **Construir.** Cada issue se hace en su propia **rama**, con pruebas y una revisión automática
   hecha por alguien que no escribió el código. Las pruebas automáticas cubren lo que no se ve
   usando la app (permisos, que no se pierdan ni se rompan datos, reglas y cálculos); lo que se
   ve, lo probás vos con la app andando.
4. **Probar.** Te muestro cada "listo cuando" con ✅ o ❌ y su evidencia, y la app andando para
   que la pruebes. Todas las pruebas corren una sola vez, sobre la versión final; antes de
   integrar se repiten solo si el código cambió o si la versión principal se movió en el medio.
5. **Integrar.** Si está bien, lo sumo a la versión principal con un **pull request**. Nunca se
   escribe directo en `main`.
6. **Publicar.** La app sale a internet siempre desde la versión principal.

Hay **dos momentos** en los que frena y te pregunta: al aprobar lo que se va a hacer (la épica, o
el issue si es un cambio chico) y al ver cada resultado. Si en el medio aparece algo que cambia lo
acordado, también frena.

### Escala y dónde se publica

Al planificar se definen dos cosas que cambian cómo se construye:

- **Escala.** *Prototipo* (para probar una idea), *producto* (lo usa un negocio todos los días) o
  *plataforma* (varios tipos de usuario, integraciones, o más de una forma de entrar: web, una
  CLI, un MCP, otros sistemas). Una plataforma nace con una API en el medio; un prototipo o un
  producto no la necesitan.
- **Dónde se publica.** Vercel por defecto; Railway, o infraestructura propia (un servidor con
  Dokploy) cuando se elige. En Vercel y Railway se publica siempre con **GitHub Actions**: cada
  integración a la versión principal se publica sola, la haga quien la haga, sin pagar un lugar
  en Vercel por cada persona que integra.

Las dos quedan anotadas en el README del proyecto.

### Proyectos de una persona o de equipo

El kit trabaja distinto según quién integra:

- **De una persona:** corre la revisión automática y, cuando aprobás el resultado, integra él.
- **De equipo:** no corre la revisión automática, deja el PR esperando la revisión de una persona
  y nunca integra.

Lo deduce solo: es de equipo si el repo tiene un archivo `CODEOWNERS`, o si en los últimos pull
requests aparece otra persona. Cuando eso no refleja cómo se trabaja, el proyecto lo declara en
un archivo `australis.json` en la raíz del repo, que se sube con el código:

```json
{ "tipo_de_repo": "una-persona" }
```

El caso típico: un desarrollador principal que integra solo, aunque otros abran PRs de vez en
cuando. Sin el archivo, alcanza con que alguien más abra un PR para que el kit deje todo
esperando una revisión que nadie va a hacer. Al revés, `"equipo"` obliga a la revisión humana
aunque por ahora trabaje una sola persona.

Lo declarado en `australis.json` manda sobre `CODEOWNERS`, y `CODEOWNERS` manda sobre lo que se
deduce de los PRs. Ninguna opción saltea la aprobación del resultado («Esto anda») ni integra con
pruebas en rojo.

### Cambios chicos

Un cambio chico (un texto, un color, un arreglo, un campo, un filtro) no pasa por todo el método,
pero sí por la definición:

1. Te muestro un issue con uno a tres "listo cuando" y lo aprobás. No hay entrevista ni épica.
2. Lo construyo en una rama, con sus pruebas, sin las etapas de exploración y diseño.
3. Corro todas las pruebas una sola vez, sobre la versión final.
4. Pasa por revisión automática solo si toca datos guardados, el servidor o las claves.
5. Te muestro el resultado con su evidencia y decidís si se integra.

Es chico si se resuelve en unos tres archivos o menos, sin cambiar la base de datos, sin sumar
dependencias ni servicios y sin tocar el inicio de sesión ni los permisos. Si en el camino crece,
te aviso y sigue como un paso completo.

### Cómo te habla

Al preparar la compu elegís el nivel:

- **Aprendiendo:** nombra cada etapa, te explica cada concepto la primera vez que aparece (rama,
  commit, pull request…) y nunca te pregunta cosas técnicas: las decide y te dice por qué.
- **Ya programo:** va directo, te muestra las decisiones técnicas y te pregunta cuando hace falta.

En los dos niveles hay cosas que no se negocian: no se escribe en `main`, no se sube una clave, no
se integra algo que rompe pruebas y no se da nada por terminado sin evidencia.

### Dónde queda tu trabajo

- **En GitHub:** la épica, los issues, los pull requests y toda la historia.
- **En tu repo:** el código y la documentación que perdura (README, decisiones importantes).
- **En `.australis/`:** archivos de trabajo temporales del paso en curso. No se suben a GitHub.
- **En `.env.local`:** las claves de tu app y las del kit (leer tu base de datos, publicar desde
  GitHub). Ese archivo nunca se sube. Las secretas las pegás vos ahí: el kit no te las pide por
  el chat ni las muestra.

## Actualizar

Lo más simple: en Claude Code escribí `/plugin`, entrá en **Marketplaces**, elegí
**australis-dev** y activá **Enable auto-update**. A mano:

```bash
claude plugin marketplace update australis-dev
claude plugin update australis-dev@australis-dev
```

## Si otra persona usa tu compu

`/preparar nivel` cambia cómo trabaja el kit. Para apagarlo del todo:

```bash
claude plugin disable australis-dev@australis-dev
claude plugin enable  australis-dev@australis-dev
```

## Licencia

MIT. Ver [LICENSE](LICENSE).
