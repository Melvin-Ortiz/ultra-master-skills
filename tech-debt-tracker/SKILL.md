---
name: tech-debt-tracker
description: >
  Activar cuando el usuario quiere auditar, cuantificar, o priorizar deuda técnica.
  También cuando dice "el código está muy desordenado", "tenemos mucha deuda técnica",
  "¿por dónde empezamos a limpiar esto?", "esto es un legacy nightmare". La deuda
  técnica invisible es la que mata los proyectos — este skill la hace visible y accionable.
---

# Tech Debt Tracker — Hacer Visible la Deuda Invisible

La deuda técnica no es inherentemente mala. Como la deuda financiera, puede ser
una herramienta si se gestiona conscientemente. El problema es la deuda acumulada
sin intención ni plan de pago.

## Taxonomía de Deuda Técnica

### Tipo 1: Deuda Deliberada Prudente
```
"Sabemos que esto no es ideal, pero hay una fecha límite.
Lo haremos bien en la siguiente iteración."
→ Aceptable SI: hay un ticket/decisión registrada y un plan de resolución
→ Inaceptable SI: nunca se registró y nadie recuerda por qué se hizo así
```

### Tipo 2: Deuda Deliberada Irresponsable
```
"No hay tiempo para tests. YOLO."
→ Inaceptable en cualquier circunstancia
→ Identificar y priorizar para eliminación inmediata
```

### Tipo 3: Deuda Involuntaria (la más común y peligrosa)
```
"No sabíamos que había una mejor forma de hacerlo."
→ El equipo aprendió mejores patrones después de escribir el código
→ El conocimiento del dominio evolucionó y el código no
→ Acumulada de modo silencioso durante años
```

---

## Protocolo de Auditoría

### Paso 1: Clasificación por Dominio

Escanear el codebase buscando deuda en cada categoría:

```python
# Script de análisis estático de deuda (Python stdlib):

import ast
import os
from pathlib import Path
from dataclasses import dataclass, field
from typing import List

@dataclass
class DebtItem:
    file: str
    line: int
    category: str
    severity: str  # CRITICAL/HIGH/MEDIUM/LOW
    description: str
    effort_estimate: str  # horas estimadas

def scan_for_debt(directory: str) -> List[DebtItem]:
    items = []

    for path in Path(directory).rglob("*.py"):
        with open(path) as f:
            source = f.read()
            lines = source.splitlines()

        # 1. Detectar TODOs, FIXMEs, HACKs
        for i, line in enumerate(lines, 1):
            for marker in ["TODO", "FIXME", "HACK", "XXX", "WORKAROUND"]:
                if marker in line:
                    items.append(DebtItem(
                        file=str(path),
                        line=i,
                        category="code_comment",
                        severity="MEDIUM",
                        description=f"{marker}: {line.strip()}",
                        effort_estimate="1-4h"
                    ))

        # 2. Detectar funciones demasiado largas
        try:
            tree = ast.parse(source)
            for node in ast.walk(tree):
                if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    end_line = max(getattr(n, 'lineno', 0) for n in ast.walk(node))
                    length = end_line - node.lineno
                    if length > 50:
                        items.append(DebtItem(
                            file=str(path),
                            line=node.lineno,
                            category="complexity",
                            severity="HIGH" if length > 100 else "MEDIUM",
                            description=f"Function '{node.name}' has {length} lines",
                            effort_estimate="4-8h"
                        ))
        except SyntaxError:
            pass

    return items
```

### Paso 2: Categorías de Deuda a Identificar

```
📋 DEUDA DE CÓDIGO:
□ Funciones > 50 líneas (violación de SRP)
□ Clases con más de 10 métodos públicos
□ Archivos > 300 líneas
□ Duplicación de código (WET — Write Everything Twice+)
□ Código muerto (funciones/variables no usadas)
□ Magic numbers/strings sin nombre
□ Comentarios TODO/FIXME/HACK acumulados

🧪 DEUDA DE TESTING:
□ Cobertura < 70% en módulos de lógica de negocio
□ Tests sin asserts (tests que siempre pasan)
□ Tests que prueban implementación (no comportamiento)
□ Fixtures compartidas entre tests (acoplamiento)
□ Tests con sleep() (timing-dependent, flaky)
□ Ausencia completa de tests en módulos críticos

🏗️ DEUDA DE ARQUITECTURA:
□ Dependencias circulares entre módulos
□ Violaciones de capas (UI importando de DB directamente)
□ Módulos que hacen demasiado (god objects)
□ Ausencia de interfaces/abstracciones (hardcoded dependencies)
□ Config hardcodeada en código
□ Secrets en código fuente o historia de git

📦 DEUDA DE DEPENDENCIAS:
□ Dependencias con vulnerabilidades conocidas (CVEs)
□ Dependencias deprecadas o sin mantenimiento
□ Versiones major desactualizadas (>2 versiones atrás)
□ Dependencias redundantes (dos librerías haciendo lo mismo)
□ Dependencias no utilizadas

📝 DEUDA DE DOCUMENTACIÓN:
□ APIs sin documentación (falta de OpenAPI/docstrings)
□ ADRs (Architecture Decision Records) ausentes
□ README desactualizado
□ Onboarding imposible sin ayuda de un colega
□ Lógica de negocio compleja sin explicación del "por qué"

🔒 DEUDA DE SEGURIDAD:
□ Versiones con CVEs conocidos
□ Secrets en variables de entorno sin rotación
□ Logging de datos sensibles
□ Input no sanitizado
□ Ausencia de rate limiting
```

### Paso 3: Scoring de Prioridad

Para cada ítem de deuda, calcular un score de prioridad:

```python
def calculate_debt_priority(item: DebtItem) -> float:
    """
    Priority Score = Impact × Probability × (1 / Effort)
    
    Impact: ¿Qué pasa si esto sigue así?
    - CRITICAL (5): Sistema puede fallar, datos pueden perderse
    - HIGH (4): Performance degradada, bugs frecuentes
    - MEDIUM (3): Velocidad de desarrollo reducida
    - LOW (2): Cosmético, molesto pero no bloqueante
    
    Probability: ¿Con qué frecuencia afecta el trabajo?
    - Daily (5): Tropezamos con esto todos los días
    - Weekly (4): Nos afecta varias veces por semana
    - Monthly (3): Surge ocasionalmente
    - Rare (1): Solo importa en casos edge
    
    Effort: ¿Cuánto cuesta resolverlo?
    - <2h (4): Fix rápido
    - 2-8h (3): Medio día a un día
    - 1-3 days (2): Varios días
    - >3 days (1): Sprint completo o más
    """
    impact_map = {"CRITICAL": 5, "HIGH": 4, "MEDIUM": 3, "LOW": 2}
    impact = impact_map.get(item.severity, 3)
    
    # Simplificación para el cálculo:
    priority_score = impact * (1.0 / estimate_effort_days(item))
    
    return priority_score
```

### Paso 4: Tech Debt Register

Mantener un registro vivo de la deuda:

```markdown
# Tech Debt Register — [Proyecto]
*Última actualización: [Fecha]*

## Deuda Crítica (resolver este sprint)
| ID | Descripción | Archivo | Categoría | Esfuerzo | Owner | Due |
|----|-------------|---------|-----------|----------|-------|-----|
| TD-001 | AuthService hace 3 cosas | auth/service.ts | Arquitectura | 8h | - | - |

## Deuda Alta (resolver próximo sprint)
| ... |

## Deuda Media (backlog priorizado)
| ... |

## Deuda Aceptada (decisión consciente de vivir con ella)
| ID | Descripción | Razón | Fecha de revisión |
|----|-------------|-------|-------------------|
| TD-099 | Using deprecated API X | Proveedor no tiene alternativa | 2025-Q3 |

## Métricas de Salud
- Deuda crítica total: N items, ~Xh
- Deuda alta total: N items, ~Xh
- Trend (vs. mes anterior): ↑ / ↓ / → 
- % de tiempo del sprint dedicado a deuda: X%
```

---

## Framework de Priorización: La Matriz de Urgencia vs. Valor

```
                    ALTO VALOR DE ELIMINAR
                           │
         ┌─────────────────┼─────────────────┐
         │   QUICK WINS    │  STRATEGIC DEBT  │
URGENCIA │ (hacer ahora)   │ (planificar)     │
BAJA     │                 │                  │
         ├─────────────────┼─────────────────┤
URGENCIA │    FILL-INS     │   DON'T BOTHER   │
ALTA     │ (si hay tiempo) │  (vivir con      │
         │                 │   ella)          │
         └─────────────────┴─────────────────┘
                    BAJO VALOR DE ELIMINAR
```

**Quick Wins:** Deuda fácil de pagar con alto impacto → hacer ahora
**Strategic Debt:** Grande, costosa, alto impacto → planificar como proyecto
**Fill-Ins:** Pequeña pero bajo impacto → cuando hay tiempo disponible
**Don't Bother:** Costosa y bajo impacto → documentar como deuda aceptada

---

## Reporte de Deuda Técnica

```markdown
# Tech Debt Report — [Fecha]

## Executive Summary
- **Deuda total identificada:** N items (~X horas de trabajo)
- **Deuda crítica bloqueante:** N items
- **Costo de inacción (estimado):** X horas/sprint de productividad perdida

## Top 5 Prioridades
1. **[Ítem más urgente]** — [Categoría] — [Estimado: Xh]
   *Por qué importa:* [impacto específico en el equipo/sistema]
   *Fix propuesto:* [descripción concreta del trabajo]

## Distribución de Deuda
| Categoría | Items | Horas |
|-----------|-------|-------|
| Código | N | Xh |
| Testing | N | Xh |
| Arquitectura | N | Xh |
| Dependencias | N | Xh |
| Seguridad | N | Xh |

## Recomendación
Dedicar X% del tiempo del equipo a deuda técnica durante Y sprints.
Con este ritmo, la deuda crítica estará saldada en [fecha estimada].
```
