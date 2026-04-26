# ULTRA MASTER ENGINEER — Skill Ecosystem Completo
## Fuentes: obra/superpowers, mattpocock/skills, alirezarezvani/claude-skills, Anthropic Official Skills, ckelsoe/prompt-architect

---

## SKILLS ORIGINALES (Skills_iniciales.md)

Los siguientes skills ya están definidos en tu sistema y **siguen vigentes**:

| Skill | Cuándo Activar |
|-------|----------------|
| `ultra-senior-engineer` | TODO código, arquitectura, debugging, revisión técnica |
| `web` (references/web.md) | React, Vue, Next.js, Node, APIs |
| `mobile` (references/mobile.md) | iOS, Android, React Native, Flutter |
| `desktop` (references/desktop.md) | Electron, Tauri, nativo |
| `data` (references/data.md) | Python data, ML, LLMs, SQL avanzado |
| `architecture` (references/architecture.md) | Sistemas distribuidos, microservicios |
| `devops` (references/devops.md) | CI/CD, Docker, K8s, Terraform |
| `security` (references/security.md) | OWASP, auth, crypto |
| `standards` (references/standards.md) | Testing, code quality, performance |
| `skill-creator` | Crear o mejorar skills |

---

## NUEVAS SKILLS — ULTRA MASTER LEVEL

12 skills nuevos extraídos de los mejores repositorios del ecosistema público:

### 🧠 SKILLS DE PROCESO Y METODOLOGÍA

#### `brainstorming`
**Fuente:** obra/superpowers (battle-tested)
**Activar:** Antes de cualquier feature no trivial. "Construye X", "implementa Y".
**Valor:** Evita ejecutar la solución incorrecta. Diseño por secciones validadas.

```yaml
---
name: brainstorming
description: >
  Activar SIEMPRE antes de escribir cualquier línea de código para features nuevas,
  componentes, sistemas, refactors significativos, o cuando el usuario diga "construye",
  "implementa", "crea", "agrega" algo que no sea trivial. NO activar para bugfixes
  simples o cambios de una línea.
---
```

#### `test-driven-development`
**Fuente:** obra/superpowers + mattpocock/skills (combinado)
**Activar:** Al implementar cualquier feature o bugfix. RED-GREEN-REFACTOR.
**Valor:** El test que nunca falla no prueba nada. TDD como disciplina de diseño.

```yaml
---
name: test-driven-development
description: >
  Activar cuando el usuario implementa features, corrige bugs, o agrega funcionalidad.
  TDD no es opcional en código de producción. Usar antes de escribir cualquier
  implementación. El ciclo RED-GREEN-REFACTOR no es negociable.
---
```

#### `systematic-debugging`
**Fuente:** obra/superpowers (4-phase root cause process)
**Activar:** "Esto no funciona", "hay un bug", "por qué falla esto".
**Valor:** 4 fases: Reproducir → Aislar → Causa raíz → Verificar fix.

```yaml
---
name: systematic-debugging
description: >
  Activar cuando hay un bug, comportamiento inesperado, error en producción, o cuando
  el usuario dice "esto no funciona", "algo está mal", "por qué falla esto".
  NO adivinar. NO lanzar fixes al azar.
---
```

#### `subagent-driven-development`
**Fuente:** obra/superpowers
**Activar:** Después de aprobar el plan. "Ejecuta el plan", "implementa esto", "adelante".
**Valor:** Paralelización + revisión de dos etapas por batch.

```yaml
---
name: subagent-driven-development
description: >
  Activar después de que el diseño y plan de implementación están aprobados,
  cuando hay tareas independientes que pueden ejecutarse en paralelo.
---
```

#### `verification-before-completion`
**Fuente:** obra/superpowers
**Activar:** Siempre antes de declarar cualquier tarea como "done".
**Valor:** Done significa done. No "creo que funciona".

```yaml
---
name: verification-before-completion
description: >
  Activar SIEMPRE antes de declarar cualquier tarea como completada. Nada está
  done hasta que la verificación objetiva lo confirma.
---
```

---

### 🔍 SKILLS DE ANÁLISIS Y REVISIÓN

#### `adversarial-reviewer`
**Fuente:** alirezarezvani/claude-skills (engineering-team)
**Activar:** Revisión de código antes de PR, "revisa esto", "¿está bien este código?".
**Valor:** 3 personas hostiles forzadas: Saboteador, Nuevo Empleado, Auditor OWASP.

```yaml
---
name: adversarial-reviewer
description: >
  Activar cuando se quiere una revisión genuinamente crítica de código: antes de un PR,
  después de implementar una feature, cuando el usuario dice "revisa esto", "qué piensas
  del código". Rompe la monocultura del auto-review con 3 personas adversariales.
---
```

#### `grill-me`
**Fuente:** mattpocock/skills
**Activar:** "¿Tiene sentido este diseño?", "dame feedback de mi plan", validar propuestas.
**Valor:** Interrogación implacable hasta que cada rama del árbol de decisión esté resuelta.

```yaml
---
name: grill-me
description: >
  Activar cuando el usuario tiene un plan, diseño, o idea y quiere validarlo en profundidad.
  Invierte la dinámica: Claude interroga al usuario en lugar de validar pasivamente.
---
```

#### `improve-codebase-architecture`
**Fuente:** mattpocock/skills
**Activar:** "El código está muy fragmentado", "no sé dónde poner esto", antes de TDD en legacy.
**Valor:** Identifica módulos superficiales y propone interfaces más delgadas sobre implementaciones más profundas.

```yaml
---
name: improve-codebase-architecture
description: >
  Activar cuando el codebase está muy fragmentado, los tests son difíciles de escribir,
  hay confusión sobre qué hace qué, o antes de comenzar TDD en codebase existente.
---
```

#### `api-design-reviewer`
**Fuente:** alirezarezvani/claude-skills (engineering advanced)
**Activar:** Diseñar/revisar APIs REST o GraphQL. "¿Está bien este endpoint?".
**Valor:** REST linter + breaking change detector + scorecard completo.

```yaml
---
name: api-design-reviewer
description: >
  Activar cuando el usuario diseña o revisa una API REST, GraphQL, o gRPC.
  Las APIs son contratos públicos — un error de diseño cuesta meses de compatibilidad.
---
```

---

### 🚨 SKILLS OPERACIONALES

#### `incident-commander`
**Fuente:** alirezarezvani/claude-skills (engineering team)
**Activar:** "Producción está caída", "hay un outage", "algo explotó en prod", PIR.
**Valor:** Clasificación de severidad + comunicación estructurada + 4 fases de respuesta + PIR template.

```yaml
---
name: incident-commander
description: >
  Activar cuando hay un incidente de producción activo o post-mortem. También para PIR
  (Post-Incident Review). La velocidad y claridad en un incidente define la diferencia
  entre 30 min y 4 horas de downtime.
---
```

#### `tech-debt-tracker`
**Fuente:** alirezarezvani/claude-skills (engineering team)
**Activar:** "El código está muy desordenado", "mucha deuda técnica", "¿por dónde empezamos?".
**Valor:** Taxonomía de deuda + scoring de prioridad + Tech Debt Register.

```yaml
---
name: tech-debt-tracker
description: >
  Activar cuando el usuario quiere auditar, cuantificar, o priorizar deuda técnica.
  La deuda técnica invisible es la que mata los proyectos — este skill la hace visible
  y accionable con scoring de prioridad y plan de pago.
---
```

---

### 🎯 SKILLS META

#### `prompt-architect`
**Fuente:** ckelsoe/prompt-architect + investigación académica (arXiv 2025)
**Activar:** "Ayúdame con este prompt", "cómo formulo esto para la IA", "optimiza este system prompt".
**Valor:** 7 frameworks de prompting (CO-STAR, RISEN, ReAct, CoT, FATA, APE, ToT) con evaluación.

```yaml
---
name: prompt-architect
description: >
  Activar cuando el usuario necesita crear, mejorar, o estructurar prompts para LLMs.
  Un prompt mal estructurado desperdicia tokens. Un prompt bien estructurado es código.
---
```

---

## WORKFLOW MAESTRO — Cómo Orquestar Los Skills

```
PARA UNA FEATURE NUEVA:
1. brainstorming → diseño validado por secciones
2. (opcional) grill-me → interrogación del diseño si es complejo
3. improve-codebase-architecture → si el codebase tiene problemas estructurales
4. test-driven-development → implementación con RED-GREEN-REFACTOR
5. adversarial-reviewer → revisión crítica antes del PR
6. verification-before-completion → nada está done sin verificación

PARA UN BUG:
1. systematic-debugging → 4 fases de RCA
2. test-driven-development → test de regresión primero
3. verification-before-completion → confirmar que está realmente arreglado

PARA UN PROYECTO GRANDE (múltiples tareas):
1. brainstorming → diseño general
2. grill-me → validación del plan
3. subagent-driven-development → ejecución paralela por batches
4. adversarial-reviewer → revisión de cada batch
5. verification-before-completion → done real, no pseudo-done

PARA UN INCIDENTE DE PRODUCCIÓN:
1. incident-commander → protocolo inmediato

PARA DEUDA TÉCNICA:
1. tech-debt-tracker → auditoría y priorización
2. improve-codebase-architecture → si hay problemas estructurales
3. test-driven-development → tests primero al limpiar deuda

PARA DISEÑO DE API:
1. grill-me → validar el diseño con el usuario
2. api-design-reviewer → revisión formal del contrato

PARA PROMPTS DE IA:
1. prompt-architect → framework correcto para el caso de uso
```

---

## MAPA DE SKILLS POR TRIGGER

| Trigger del usuario | Skills a activar |
|---------------------|-----------------|
| "Construye/crea/implementa X" | `brainstorming` → `test-driven-development` |
| "Hay un bug / esto no funciona" | `systematic-debugging` |
| "Revisa este código" | `adversarial-reviewer` |
| "¿Tiene sentido este plan?" | `grill-me` |
| "Ejecuta el plan" | `subagent-driven-development` |
| "Ya terminé / está listo" | `verification-before-completion` |
| "Producción caída / outage" | `incident-commander` |
| "Mucha deuda técnica" | `tech-debt-tracker` |
| "Código muy fragmentado" | `improve-codebase-architecture` |
| "Diseña la API" | `api-design-reviewer` |
| "Mejora este prompt" | `prompt-architect` |
| "React/Next/Vue/Node" | `ultra-senior-engineer` + `web` |
| "iOS/Android/Flutter" | `ultra-senior-engineer` + `mobile` |
| "Docker/K8s/CI-CD" | `ultra-senior-engineer` + `devops` |
| "Seguridad/OWASP" | `ultra-senior-engineer` + `security` |
| "ML/Data/Python data" | `ultra-senior-engineer` + `data` |
| "Arquitectura de sistemas" | `ultra-senior-engineer` + `architecture` |

---

## FUENTES Y CRÉDITOS

Estos skills fueron destilados de:

| Repositorio | Stars | Skills tomados |
|-------------|-------|----------------|
| [obra/superpowers](https://github.com/obra/superpowers) | ⭐⭐⭐⭐⭐ | brainstorming, TDD, systematic-debugging, subagent-driven-development, verification-before-completion |
| [mattpocock/skills](https://github.com/mattpocock/skills) | ⭐⭐⭐⭐⭐ | grill-me, improve-codebase-architecture, TDD (complemento) |
| [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) | ⭐⭐⭐⭐⭐ (11.2K) | adversarial-reviewer, incident-commander, api-design-reviewer, tech-debt-tracker |
| [ckelsoe/prompt-architect](https://github.com/ckelsoe/claude-skill-prompt-architect) | ⭐⭐⭐⭐ | prompt-architect (CO-STAR, RISEN, ReAct, CoT, FATA, APE) |
| [anthropics/skills](https://github.com/anthropics/skills) | Oficial | Patrones de skill-creator, progressive disclosure |
| arXiv 2508.08308 (FATA Framework) | Académico | ~40% mejora sobre prompting estándar |
| arXiv 2411.06729 (APE - EMNLP 2025) | Académico | Reverse prompt engineering |

---

## ELEVACIÓN DEL NIVEL: de Ultra-Senior a Ultra-Master

| Dimensión | Ultra-Senior (antes) | Ultra-Master (ahora) |
|-----------|---------------------|---------------------|
| **Proceso de diseño** | Implementación directa | Brainstorming validado por secciones |
| **Testing** | Tests como afterthought | TDD: test primero, siempre |
| **Debugging** | Instintivo y experiencial | 4 fases sistemáticas con RCA |
| **Code review** | Perspectiva del autor | 3 personas adversariales forzadas |
| **Validación de ideas** | "Suena bien" | Interrogación implacable (grill-me) |
| **Ejecución de planes** | Secuencial | Paralela con revisión de 2 etapas |
| **"Done"** | Subjetivo | Verificación objetiva obligatoria |
| **Incidentes** | Reactivo | Protocolo de IC + comunicación estructurada |
| **Deuda técnica** | Acumulada sin visibilidad | Catalogada, priorizada, con plan de pago |
| **APIs** | Funcionales | Contratos formalmente revisados |
| **Prompts** | Intuitivos | Frameworks académicos + evaluación |
| **Arquitectura** | "El código está así" | Módulos profundos con interfaces delgadas |
