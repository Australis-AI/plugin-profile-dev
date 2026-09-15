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
| `/nuevo` | Arrancar algo nuevo — explora el proyecto y arma el plan que vas a aprobar |
| `/construir` | Construir lo que ya acordaron y verificar que ande |
| `/seguir` | Retomar donde quedaste, en otra sesión |
| `/juzgar` | Revisión adversarial: dos revisores ciegos sobre el mismo código |
| `/preparar` | Dejar la compu lista (una vez); `/preparar nivel` cambia cómo trabajamos |
| `/chequeo` | Ver si algo se rompió, y qué hacer exactamente |

### El flujo

```
entender ──▶ acordar ──▶ diseñar ──▶ construir ──▶ verificar
    │            │                                     │
    ▼            ▼                                     ▼
"Esto entendí"  "Esto va a hacer"                "Esto anda"
```

Son **tres momentos** en los que se detiene y te pregunta. El resto corre solo.

El punto clave: la lista numerada que aprobás en *"Esto va a hacer"* es la misma lista, palabra
por palabra, que vuelve al final en *"Esto anda"* con un ✅ o un ❌ por ítem. Podés leer el
reporte de verificación porque aprobaste cada línea diez minutos antes.

### Qué deja en tu proyecto

```
.australis/
├── proyecto.md          lo que se sabe del proyecto, acumulado
├── cambios/<nombre>/    el cambio en curso: plan, tareas, verificación
└── hecho/               los cambios cerrados
```

Son archivos de texto. Los podés abrir, leer y versionar en git. No hay base de datos escondida.

### Ramas

Nunca escribe en `main`. Antes de tocar código crea `feat/<nombre>` y te lo dice en una línea.
Los commits siguen [conventional commits](https://www.conventionalcommits.org/).

## Actualizar

```bash
claude plugin marketplace update australis-dev
claude plugin update australis-dev@australis-dev
```

## Prestárselo a alguien que no programa

Todo el módulo es un interruptor:

```bash
claude plugin disable australis-dev@australis-dev
claude plugin enable  australis-dev@australis-dev
```

## Licencia

MIT. Ver [LICENSE](LICENSE).
