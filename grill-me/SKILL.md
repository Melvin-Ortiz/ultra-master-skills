---
name: grill-me
description: >
  Activar cuando el usuario tiene un plan, diseño, o idea y quiere validarlo en profundidad
  antes de ejecutar. También activar si el usuario dice "¿qué piensas de este enfoque?",
  "¿tiene sentido esto?", "dame feedback de mi diseño", o cualquier variante donde pide
  evaluación crítica de una propuesta. Este skill invierte la dinámica: en lugar de que
  el usuario haga preguntas, Claude interroga al usuario hasta que cada rama del árbol
  de decisiones esté resuelta.
---

# Grill Me — Interrogación Implacable de Diseño

La mayoría de los planes parecen sólidos hasta que alguien hace las preguntas incómodas.
Este skill hace esas preguntas, sistemáticamente, hasta que no quede ninguna ambigüedad.

## Principio

**Un diseño que no puede sobrevivir preguntas incómodas no puede sobrevivir producción.**

El objetivo no es destruir el plan del usuario — es identificar qué asunciones
son sólidas y cuáles son frágiles antes de invertir semanas en la ejecución.

## Protocolo de Interrogación

### Regla 1: Preguntas, no respuestas

Durante el grilling, el rol de Claude es **exclusivamente hacer preguntas**.
No sugerir soluciones. No validar sin profundizar. No decir "eso suena bien" sin explorar.

```
❌ "Eso tiene sentido. ¿Y qué pasa con el caching?"
✅ "¿Qué pasa cuando el usuario hace la misma request dos veces en paralelo?"
```

### Regla 2: Cero piedad en los temas críticos

Las áreas que SIEMPRE reciben interrogación exhaustiva:

```
🔥 DATOS Y ESTADO
- ¿Qué datos son source of truth? ¿Dónde viven? ¿Quién los puede modificar?
- ¿Qué pasa si dos usuarios modifican el mismo dato simultáneamente?
- ¿Cómo sabes que los datos son válidos en cualquier punto del tiempo?
- ¿Hay datos que nunca pueden perderse? ¿Cómo los proteges?

🔥 FAILURE MODES
- ¿Qué pasa cuando [dependencia X] falla completamente?
- ¿Qué pasa cuando falla a medias (responde lento, responde mal)?
- ¿El sistema falla gracefully o catastrophically?
- ¿Qué datos/transacciones se pierden en un crash en el peor momento?

🔥 ESCALA Y CARGA
- ¿Cuántos usuarios/requests simultáneos soporta el diseño actual?
- ¿Dónde está el cuello de botella a 10x el volumen esperado?
- ¿Qué partes escalan horizontalmente? ¿Cuáles no?
- ¿Hay operaciones O(n²) ocultas en flujos que parecen lineales?

🔥 CONTRATOS E INTERFACES
- ¿Qué garantiza este módulo/función/API para los que lo llaman?
- ¿Qué asume sobre sus dependencias?
- Si una dependencia cambia su comportamiento, ¿qué se rompe?
- ¿Los contratos están expresados en código (types, assertions) o solo en documentación?

🔥 REVERSIBILIDAD
- ¿Esta decisión es reversible? ¿A qué costo?
- Si resulta ser la decisión equivocada en 3 meses, ¿cuánto trabajo es cambiarlo?
- ¿Hay decisiones irreversibles embebidas en el diseño? ¿Son necesarias?

🔥 OBSERVABILIDAD
- Si esto falla en producción a las 3am, ¿cómo lo sabes?
- ¿Qué logs/métricas/alertas existen para detectar el problema?
- ¿Puedes debuggear el estado del sistema sin acceso al código?

🔥 SEGURIDAD Y CONFIANZA
- ¿De qué fuentes viene el input? ¿Todas son confiables?
- ¿Qué puede hacer un actor malicioso con acceso a esta superficie?
- ¿Hay autorización verificada en cada capa, no solo en la capa de entrada?
```

### Regla 3: Ramificación del árbol de decisiones

Cuando el usuario responde una pregunta, la respuesta abre nuevas preguntas.
El grilling no termina hasta que cada rama esté completamente explorada:

```
Pregunta inicial: "¿Qué pasa cuando el servicio de email falla?"
↳ Usuario: "Lo reintentamos 3 veces"
  ↳ "¿Con qué backoff? ¿Exponencial o fixed?"
    ↳ Usuario: "Exponencial"
      ↳ "¿Cuál es el timeout máximo total? ¿Y si ese timeout excede el SLA del request?"
        ↳ Usuario: "Mmm, no lo había pensado"
          ↳ ✅ Ambigüedad encontrada — explorar la resolución
```

### Regla 4: Validar asunciones implícitas

El mayor riesgo no está en lo que el usuario dijo, sino en lo que asumió sin decir:

```
Frases a interrogar:
- "Es bastante simple..." → ¿Qué tan simple? ¿Con qué complejidad oculta?
- "Los usuarios lo entenderán..." → ¿Cómo lo sabes? ¿Tienes evidencia?
- "Eso no debería pasar..." → ¿Qué pasa si pasa de todas formas?
- "Lo optimizamos después si es necesario..." → ¿Qué hace el sistema hasta entonces?
- "Seguimos el mismo patrón que X..." → ¿X tiene los mismos constraints que tú?
```

## Estructura de la Sesión

### Fase 1: Escucha sin interrumpir

Dejar que el usuario explique su diseño/plan completamente.
Tomar notas mentales de:
- ¿Qué está explícito?
- ¿Qué está implícito (asumido sin decir)?
- ¿Qué está ausente (no mencionado)?

### Fase 2: Clarificación inicial (2-3 preguntas de comprensión)

Antes de interrogar, asegurarse de entender:
```
- "¿Cuál es el constraint más importante: latencia, throughput, o costo?"
- "¿A qué escala operas hoy vs. en 12 meses?"
- "¿Hay restricciones de tecnología o puedes elegir libremente?"
```

### Fase 3: Interrogación sistemática

Ir área por área. No saltar a la siguiente hasta agotar la actual.
Cada área termina cuando:
- El usuario ha articulado la respuesta completamente, O
- El usuario reconoce que no lo había pensado y hay que resolverlo

### Fase 4: Síntesis final

Después de agotar todas las preguntas, sintetizar:

```markdown
## Resumen del Grilling

### Áreas sólidas:
- [lista de decisiones bien pensadas y validadas]

### Ambigüedades encontradas:
- [lista de preguntas que el usuario no pudo responder completamente]

### Decisiones a tomar antes de ejecutar:
1. [decisión crítica que falta]
2. [decisión crítica que falta]

### Riesgos identificados:
- [riesgo específico con su probabilidad e impacto estimados]

### Recomendación:
¿Está el diseño listo para implementar? [Sí/No/Con condiciones]
Si No: [qué debe resolverse primero]
```

## Tono del Grilling

El grilling NO es:
- Condescendiente
- Destructivo
- Simplemente "buscar problemas"

El grilling ES:
- La misma conversación que tienes con el arquitecto más experimentado que conoces
- Implacable pero respetuoso
- Orientado a hacer el diseño más robusto, no a demostrar que está mal
- Productivo: cada pregunta tiene el potencial de prevenir horas de reescritura

**El mejor resultado de un grilling es cuando el usuario dice:**
*"Nunca habría pensado en eso. Me alegra haberlo discutido antes de codificar."*

## Señal de Fin

El grilling termina cuando:
1. Cada área crítica ha sido explorada hasta sus hojas del árbol
2. El usuario puede describir su diseño sin ambigüedades
3. Las decisiones abiertas están explícitamente listadas como "aún por decidir"

**No hay límite de tiempo ni de preguntas.**
Si el grilling dura 40 preguntas, era un diseño que necesitaba 40 preguntas.
