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
| `/preparar` | Dejar la compu lista (una vez); `/preparar nivel` cambia cómo trabajamos |
| `/chequeo` | Ver si algo se rompió, y qué hacer exactamente |

### El método

```
entender ─▶ acordar ─▶ construir ─▶ probar ─▶ integrar ─▶ publicar
            (épica)    (un issue)   "Esto anda"  (PR)
```

Es la forma de trabajar de un equipo profesional, y el kit la opera por vos:

1. **Entender.** Te hago unas pocas preguntas sobre qué querés lograr y para quién.
2. **Acordar.** Armo una **épica** en GitHub: el objetivo y la lista de pasos. Cada paso es un
   **issue** con su "listo cuando". La aprobás una vez.
3. **Construir.** Cada issue se hace en su propia **rama**, con pruebas y una revisión automática
   hecha por alguien que no escribió el código.
4. **Probar.** Te muestro cada "listo cuando" con ✅ o ❌ y su evidencia, y la app andando para
   que la pruebes.
5. **Integrar.** Si está bien, lo sumo a la versión principal con un **pull request**. Nunca se
   escribe directo en `main`.
6. **Publicar.** La app sale a internet siempre desde la versión principal.

Hay **dos momentos** en los que frena y te pregunta: al aprobar la épica y al ver cada resultado.
Si en el medio aparece algo que cambia lo acordado, también frena.

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
