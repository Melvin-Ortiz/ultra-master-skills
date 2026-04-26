---
name: prompt-architect
description: >
  Activar cuando el usuario necesita crear, mejorar, o estructurar prompts para LLMs,
  sistemas de IA, o Claude específicamente. También cuando dice "ayúdame con este prompt",
  "cómo formulo esto para la IA", "este prompt no da buenos resultados", "optimiza este
  sistema prompt". Un prompt mal estructurado desperdicia tokens y obtiene outputs mediocres.
  Un prompt bien estructurado es la diferencia entre un junior y un senior prompt engineer.
---

# Prompt Architect — Frameworks de Ingeniería de Prompts

Un prompt es código. Tiene estructura, tiene inputs, tiene outputs esperados,
y tiene comportamientos que debes testear. Trátalo como tal.

## Framework de Selección

```
¿Cuál framework usar?

CO-STAR → Tasks complejas con outputs bien definidos, roles explícitos
RISEN   → Instrucciones precisas para outputs estructurados
ReAct   → Tasks que requieren razonamiento + uso de herramientas
CoT     → Problemas matemáticos, lógicos, de múltiples pasos
FATA    → Tasks ambiguas donde necesitas que el modelo haga preguntas primero
APE     → Cuando tienes el output ideal y necesitas reverse-engineer el prompt
ToT     → Decisiones complejas donde explorar múltiples paths es valioso
```

---

## CO-STAR — Context, Objective, Style, Tone, Audience, Response

El framework más versátil. Funciona para la mayoría de los casos.

```markdown
# Estructura CO-STAR

**[C] Context:**
Proveer el contexto mínimo necesario para entender la tarea.
¿Qué situación/dominio/proyecto es este?
¿Qué información de fondo es esencial?

**[O] Objective:**
Una sola oración clara de qué debe producir el modelo.
Empezar con un verbo de acción: "Analiza", "Escribe", "Genera", "Revisa".

**[S] Style:**
¿Cómo debe estar escrito el output?
Técnico, casual, académico, ejecutivo, periodístico.
Puede incluir referencia a un autor/fuente como ejemplo de estilo.

**[T] Tone:**
La actitud emocional del output.
Formal, empático, directo, neutro, persuasivo, crítico.

**[A] Audience:**
¿Para quién es este output?
Junior developer, CEO sin conocimiento técnico, cliente final, regulador.
Determina vocabulario, profundidad de explicación, y ejemplos usados.

**[R] Response:**
¿Qué formato exacto debe tener el output?
Markdown, JSON, lista numerada, párrafos, tabla, código.
Incluir longitud esperada si importa.
```

**Template CO-STAR:**
```
Context: [Breve descripción del proyecto/situación]

Objective: [Verbo + qué produce exactamente]

Style: [Cómo debe estar escrito]

Tone: [Actitud emocional]

Audience: [Para quién]

Response format: [Formato exacto del output]
```

---

## RISEN — Role, Instructions, Steps, End goal, Narrowing

Mejor para tasks que requieren un rol específico y pasos precisos.

```markdown
**[R] Role:**
Asigna un rol específico al modelo.
No: "Eres un experto en Python"
Sí: "Eres un senior backend engineer con 10 años de experiencia en Python,
especializado en APIs de alto rendimiento y sistemas distribuidos."
La especificidad del rol determina la especificidad del output.

**[I] Instructions:**
Qué debe hacer exactamente. Usa verbos de acción.
Incluye ejemplos de lo que debe y NO debe hacer.

**[S] Steps:**
Descomposición explícita en pasos numerados.
Si hay un proceso que debe seguir, describirlo paso a paso.

**[E] End goal:**
¿Cómo se ve el output perfecto?
¿Qué criterio define éxito?

**[N] Narrowing:**
Restricciones explícitas:
- Longitud máxima
- Formatos prohibidos
- Información a excluir
- Áreas fuera de scope
```

---

## ReAct — Reasoning + Acting

Para tasks que combinan razonamiento con uso de herramientas (tool calling).

```
Estructura de ReAct:

Thought: [El modelo razona sobre qué hacer]
Action: [Qué herramienta invocar con qué parámetros]
Observation: [Resultado de la herramienta]
Thought: [Razonar sobre el resultado]
Action: [Siguiente herramienta]
...
Thought: [Razonamiento final]
Answer: [Output al usuario]

Prompt que activa ReAct:
"Para resolver este problema:
1. Primero, piensa en voz alta sobre el approach
2. Identifica qué información necesitas
3. Usa las herramientas disponibles para obtenerla
4. Razona sobre los resultados
5. Llegua a una conclusión fundamentada"
```

---

## Chain of Thought (CoT) — Para Razonamiento Multi-paso

```
Activación simple: añadir "Razona paso a paso antes de dar tu respuesta final."

CoT estructurado:
"Antes de responder:
1. Identifica todos los elementos del problema
2. Establece qué sabes y qué necesitas determinar
3. Trabaja el problema en pasos explícitos
4. Verifica tu razonamiento
5. Da tu respuesta final"

Zero-shot CoT: "Piensa paso a paso."
Few-shot CoT: Proveer 2-3 ejemplos completos de razonamiento antes del problema.

Cuándo usar CoT:
✅ Matemáticas y lógica
✅ Problemas multi-paso
✅ Análisis de causa raíz
✅ Decisiones con múltiples factores
❌ Tasks creativas simples (añade ruido sin valor)
❌ Clasificaciones directas
```

---

## FATA — Focused, Adaptive, Targeted, Actionable

Para tasks ambiguas donde el modelo debe preguntar antes de responder.
Basado en arXiv 2508.08308 — ~40% mejora sobre prompting estándar.

```
Estructura FATA:

Prompt: "Tengo [tarea vaga o ambigua]. Antes de responder:
1. Identifica los 3 puntos de ambigüedad más críticos
2. Haz esas preguntas específicamente
3. No asumas — pregunta
4. Solo cuando tengas las respuestas, procede con [objetivo]"

Cuándo usar:
✅ Requests vagos donde asumir podría desperdiciar mucho trabajo
✅ Tasks donde el contexto del usuario es esencial
✅ Diseño de sistemas donde las restricciones importan
❌ Tasks con spec completo (preguntar cuando ya sabes es condescendiente)
```

---

## APE — Automatic Prompt Engineering (Reverse Mode)

Cuando tienes el output ideal y necesitas el prompt que lo genera.

```
Prompt para APE:
"Tengo este output ideal:
[PEGAR EL OUTPUT IDEAL]

Genera el prompt que produciría este tipo de output de manera consistente.
El prompt debe:
1. Capturar el tono, estilo y estructura del output
2. Incluir instrucciones específicas para reproducirlo
3. Funcionar para inputs similares, no solo este caso
4. Ser reutilizable como template"
```

---

## Mejores Prácticas Universales

### Positivos vs. Negativos

```
❌ Débil: "No uses lenguaje complicado"
✅ Fuerte: "Usa vocabulario comprensible para alguien sin conocimiento técnico"

❌ Débil: "No hagas la respuesta muy larga"
✅ Fuerte: "Limita la respuesta a 200 palabras máximo"

Los modelos responden mejor a instrucciones de qué hacer que a qué no hacer.
```

### Few-Shot Examples

```
Los ejemplos son más efectivos que las instrucciones para patrones de formato:

En lugar de describir el formato, mostrarlo:
"Input: [ejemplo de input]
Output: [ejemplo de output exacto]

Input: [segundo ejemplo]
Output: [segundo output exacto]

Ahora procesa: [input real del usuario]"

Usar 2-3 ejemplos para establecer patrones.
Más de 5 raramente añade valor y aumenta tokens.
```

### Anchoring y Estructura XML

```
Los LLMs modernos responden bien a XML para separar secciones:

<context>
El sistema de pagos procesa $2M diarios con latencia < 100ms
</context>

<task>
Revisar el siguiente código de transacción:
</task>

<code>
[código aquí]
</code>

<requirements>
1. Identificar race conditions
2. Verificar manejo de errores
3. Evaluar seguridad
</requirements>
```

### Delimitadores para Datos

```
Usar delimitadores consistentes para separar instrucciones de datos:

Instrucción: Analiza este contrato y extrae las cláusulas de penalización.

CONTRATO:
---
[texto del contrato]
---

Sin delimitadores, el modelo puede confundir instrucciones con datos.
```

---

## Evaluación de Prompts

Un prompt de producción debe tener tests:

```python
# Framework mínimo de evaluación de prompt:

test_cases = [
    {
        "input": "caso normal",
        "expected_characteristics": ["menciona X", "no incluye Y", "formato Z"]
    },
    {
        "input": "edge case 1",
        "expected_characteristics": ["maneja correctamente cuando..."]
    }
]

def evaluate_prompt(prompt: str, test_cases: list) -> dict:
    results = []
    for case in test_cases:
        response = call_llm(prompt, case["input"])
        passed = all(
            check_characteristic(response, char)
            for char in case["expected_characteristics"]
        )
        results.append({"case": case["input"], "passed": passed})

    pass_rate = sum(r["passed"] for r in results) / len(results)
    return {"pass_rate": pass_rate, "results": results}
```

### Métricas de un Buen Prompt

```
✅ Consistencia: el mismo prompt produce outputs similares en calidad (variance < 20%)
✅ Especificidad: el output cumple exactamente el criterio de done
✅ Eficiencia: mínimos tokens para el mismo resultado
✅ Robustez: funciona con variaciones del input, no solo el caso ideal
✅ Reproducibilidad: otro engineer puede usar el prompt y obtener resultados equivalentes
```
