---
name: subagent-driven-development
description: >
  Activar después de que el diseño y plan de implementación están aprobados,
  cuando hay tareas independientes que pueden ejecutarse en paralelo, o cuando
  el usuario dice "ejecuta el plan", "implementa esto", "adelante". Este skill
  organiza la ejecución en sprints de sub-agentes paralelos con revisión de dos
  etapas: primero cumplimiento del spec, luego calidad del código.
---

# Subagent-Driven Development — Ejecución Paralela con Control de Calidad

La velocidad de implementación viene de la paralelización.
La calidad de implementación viene de la revisión sistemática.
Este skill hace ambas cosas.

## Pre-requisitos

**Este skill requiere:**
1. Un plan de implementación aprobado (de `brainstorming` o `writing-plans`)
2. Tareas independientes identificadas (sin dependencias entre sí)
3. Tests o criterios de aceptación claros por tarea

**Si no tienes estas tres cosas, no activar este skill.**
Primero ir a `brainstorming` y `writing-plans`.

---

## Principio: Vertical Slices Independientes

Las tareas deben ser **verticales** (atraviesan todas las capas para una funcionalidad)
y **independientes** (un agente puede trabajar en A mientras otro trabaja en B sin conflictos).

```
✅ TAREA BIEN DEFINIDA (slice vertical):
"Implementar el endpoint POST /api/orders con validación, persistencia en DB,
y retorno del order creado. Tests unitarios e integración incluidos."

❌ TAREA MAL DEFINIDA (slice horizontal):
"Implementar el modelo de Order en la DB"
(horizontal — no tiene interfaz ni tests, bloquea el siguiente paso)

❌ TAREA CON DEPENDENCIAS OCULTAS:
"Implementar listado de orders" 
(depende del modelo de Order — si ese no está terminado, esto está bloqueado)
```

---

## Protocolo de Ejecución

### Fase 1: Decomposición del Plan

```markdown
Antes de lanzar agentes, mapear el plan en tareas independientes:

TAREA-1: [Nombre] 
  Descripción: [Qué implementa exactamente]
  Interfaces que expone: [Qué producirá que otros pueden consumir]
  Dependencias: [NINGUNA / TAREA-X]
  Criterio de done: [Test que debe pasar / comportamiento verificable]
  Archivos a tocar: [lista de archivos para detectar conflictos]
  Estimado: [horas]

TAREA-2: [Nombre]
  ...

# Verificar que no hay archivos duplicados entre tareas paralelas
# Si dos tareas tocan el mismo archivo, una debe esperar a la otra
```

### Fase 2: Lanzamiento por Batches

**Batch = conjunto de tareas que pueden ejecutarse en paralelo.**

```
Batch 1 (sin dependencias):
  → Agente A: TAREA-1
  → Agente B: TAREA-3
  → Agente C: TAREA-5

[Esperar completación de todos antes de continuar]

Revisión de Batch 1 (dos etapas)
[Si pasa → continuar]

Batch 2 (dependen de Batch 1):
  → Agente D: TAREA-2 (depende de TAREA-1)
  → Agente E: TAREA-4 (depende de TAREA-3)
```

### Fase 3: Revisión de Dos Etapas (obligatoria entre batches)

**Etapa 1: Cumplimiento del Spec**
```
Para cada tarea completada, verificar:
□ ¿Implementa exactamente lo especificado?
□ ¿Los tests pasan? ¿Hay tests?
□ ¿Las interfaces producidas coinciden con lo acordado?
□ ¿Hay edge cases no manejados que estaban en el plan?
□ ¿El criterio de done está satisfecho?

Estado posible:
- DONE: Avanzar al siguiente batch
- DONE_WITH_CONCERNS: Avanzar pero registrar los concerns
- BLOCKED: El agente necesita más contexto, no puede continuar solo
- NEEDS_CONTEXT: Hay ambigüedad en el plan que bloquea
```

**Etapa 2: Calidad del Código**
```
Para cada tarea que pasó Etapa 1:
□ ¿Los nombres comunican intención sin comentarios?
□ ¿Las funciones tienen responsabilidad única (< 30 líneas)?
□ ¿Los errores se propagan correctamente (no se swallean)?
□ ¿Hay tests de los casos de falla, no solo del happy path?
□ ¿Hay duplicación obvia que debería refactorizarse?
□ ¿Las abstracciones están en el nivel correcto?

Si hay problemas de calidad → el agente hace REFACTOR antes de continuar.
```

### Fase 4: Manejo de Estados

**DONE:**
```
→ Commit del trabajo
→ Marcar tarea como completa
→ Desbloquear tareas dependientes en el siguiente batch
```

**DONE_WITH_CONCERNS:**
```
→ Commit del trabajo
→ Registrar concern en el plan como deuda técnica potencial
→ Continuar (el concern no bloquea, pero queda visible)
```

**BLOCKED:**
```
→ No hacer commit de trabajo incompleto
→ Escalar al usuario con pregunta específica:
  "TAREA-X bloqueada: necesito saber [pregunta específica].
   El plan dice [X] pero la realidad del código dice [Y].
   ¿Cómo procedo?"
→ Esperar respuesta antes de continuar
```

**NEEDS_CONTEXT:**
```
→ No hacer commit
→ Escalar con contexto:
  "TAREA-X no puede completarse sin más contexto:
   [Describe la ambigüedad específica]
   Opciones posibles:
   A) [opción A y sus tradeoffs]
   B) [opción B y sus tradeoffs]
   Recomiendo [A/B] porque [razón]"
```

---

## Template de Instrucción de Sub-agente

Cada sub-agente recibe exactamente esta estructura:

```markdown
# Tarea: [NOMBRE-TAREA]

## Contexto
[Descripción breve del sistema y qué estamos construyendo]

## Tu Trabajo
[Descripción exacta de qué implementar]

## Interfaces Requeridas
Tu código debe exponer:
- [función/clase/endpoint específico con firma exacta]
- [otro]

## Criterio de Done
Esta tarea está done cuando:
- [ ] [test específico que debe pasar]
- [ ] [comportamiento verificable]
- [ ] Todos los tests existentes siguen pasando

## Archivos que Puedes Tocar
- [lista de archivos — NO modificar otros sin aprobación]

## Constraints
- [lenguaje, framework, convenciones específicas]
- Usar TDD (test primero, luego implementación)

## Reportar Estado Al Terminar
Reportar uno de: DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT
Con detalle de lo que hiciste y cualquier decisión que tomaste.
```

---

## Control de Calidad Continuo

### Checkpoint de Integración (después de cada batch)

```bash
# Después de cada batch de tareas completadas:
git status                    # ¿Qué cambió?
npm test / pytest / go test   # ¿Todos los tests pasan?
npm run build / cargo build   # ¿Compila sin errores?
npm run typecheck             # ¿Sin errores de tipos?
npm run lint                  # ¿Sin violaciones de estilo?
```

Si algo falla después de un batch:
1. Identificar qué tarea introdujo la regresión (`git bisect`)
2. El agente responsable de esa tarea hace el fix
3. No continuar al siguiente batch hasta que todo esté verde

### Límites de Autonomía

```
Un agente puede decidir autónomamente:
✅ Cómo implementar internamente (dentro del spec)
✅ Nombres de variables/funciones internas
✅ Extraer funciones helper dentro de su módulo
✅ Añadir tests adicionales no especificados

Un agente DEBE escalar:
❌ Cambiar una interfaz pública acordada
❌ Añadir una dependencia nueva no discutida
❌ Cambiar el comportamiento acordado aunque "tenga sentido"
❌ Tocar archivos fuera de su scope asignado
❌ Hacer commits que rompen los tests existentes
```

---

## Anti-Patrones de Este Proceso

```
🚨 "Ya que estoy, también arreglo X"
   → Scope creep. Registrar como deuda o nuevo ticket. No implementar ahora.

🚨 Batch siguiente sin revisión del anterior
   → Los errores se acumulan. La revisión es obligatoria entre batches.

🚨 Tareas que "comparten" archivos sin coordinación
   → Conflictos de merge, comportamientos undefined. Serializar esas tareas.

🚨 Agente marca DONE sin que los tests pasen
   → DONE significa: tests pasan, código revisa, spec cumplido.

🚨 Continuar después de un BLOCKED sin respuesta
   → El trabajo incompleto bloqueado puede corromper el trabajo subsiguiente.
```
