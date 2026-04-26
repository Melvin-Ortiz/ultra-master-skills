---
name: systematic-debugging
description: >
  Activar cuando hay un bug, comportamiento inesperado, error en producción, o cuando
  el usuario dice "esto no funciona", "algo está mal", "por qué falla esto". NO adivinar.
  NO lanzar fixes al azar. El debugging sin método es ruleta rusa con el código de producción.
  Este skill impone un proceso de 4 fases que encuentra la causa raíz real, no los síntomas.
---

# Systematic Debugging — 4 Fases de Root Cause Analysis

El peor bug es el que "arreglaste" sin entender por qué fallaba.
Volverá, mutado, en el peor momento posible.

## Regla Fundamental

**Nunca escribas código de fix hasta haber identificado y verificado la causa raíz.**
Un fix sin comprensión es un patch que crea el próximo bug.

## Las 4 Fases

---

### FASE 1: Reproducción Controlada

**Objetivo:** Convertir el bug de fenómeno aleatorio a fenómeno determinístico.

```
Sin reproducción confiable no hay debugging. Solo especulación.
```

**Protocolo:**
```
1. ¿Se puede reproducir? Si no → recolectar más datos (logs, traces, timing)
2. ¿Cuáles son las condiciones exactas?
   - Input específico que lo produce
   - Estado del sistema en ese momento
   - Secuencia de operaciones previa
   - Entorno (prod vs. staging vs. local)
3. ¿Con qué frecuencia ocurre? → determina si es race condition o input específico
4. ¿Cuándo comenzó? → correlacionar con deploys, cambios de config, carga
```

**Script de reproducción mínimo:**
```python
# Antes de debuggear, escribe un test que reproduce el bug:
def test_reproduces_bug_issue_123():
    """
    Bug: [descripción exacta del síntoma]
    Condiciones: [qué estado/input lo produce]
    Esperado: [comportamiento correcto]
    Actual: [comportamiento buggeado]
    """
    # Setup exacto de las condiciones del bug
    system = create_system_state(...)

    # Acción que produce el bug
    result = system.do_the_thing(problematic_input)

    # Assert del comportamiento CORRECTO (este test debe FALLAR ahora)
    assert result == expected_correct_value  # RED → confirma que el bug existe
```

---

### FASE 2: Aislamiento — Bisección hasta la Causa

**Objetivo:** Reducir el espacio del problema hasta encontrar la línea exacta de falla.

**Técnica de bisección:**
```
1. ¿El bug está en el frontend o backend? → Elimina mitad del sistema
2. ¿Está en la capa A o la capa B? → Agrega asserts/logs en el punto medio
3. ¿Está en esta función o en la que la llama? → Unit test de la función aislada
4. Repite hasta tener una función de < 20 líneas que reproduce el bug
```

**Herramientas de aislamiento:**
```python
# 1. Logging estratégico (no spam de prints):
import logging
logger = logging.getLogger(__name__)

def suspicious_function(data):
    logger.debug("Input: %s (type: %s)", data, type(data))
    intermediate = transform(data)
    logger.debug("After transform: %s", intermediate)
    result = process(intermediate)
    logger.debug("Final result: %s", result)
    return result

# 2. Assertions intermedias para detectar invariant violations:
def process_order(order):
    assert order.total > 0, f"Order total must be positive, got {order.total}"
    assert order.status in VALID_STATUSES, f"Invalid status: {order.status}"
    # ... procesamiento
    assert result.id is not None, "Processed order must have an ID"
    return result

# 3. Para race conditions — añadir delays deliberados:
import time
def concurrent_operation():
    acquire_lock()
    time.sleep(0.1)  # Exacerba el race condition para hacerlo reproducible
    critical_section()
    release_lock()
```

**Para bugs de TypeScript/JavaScript:**
```typescript
// Breakpoints condicionales (más útiles que console.log):
// En DevTools: breakpoint con condición "data.userId === 'problematic-id'"

// Type narrowing para encontrar undefined inesperados:
function debugType<T>(value: T, label: string): T {
  console.log(`[DEBUG] ${label}:`, value, `(${typeof value})`)
  return value
}

// Para async bugs — wrappear con trazas:
async function trackedOperation<T>(name: string, fn: () => Promise<T>): Promise<T> {
  console.log(`[START] ${name}`)
  try {
    const result = await fn()
    console.log(`[OK] ${name}:`, result)
    return result
  } catch (error) {
    console.error(`[FAIL] ${name}:`, error)
    throw error
  }
}
```

---

### FASE 3: Identificación de Causa Raíz

**Objetivo:** Encontrar el "por qué" real, no el "qué" superficial.

**Los 5 Porqués (aplicado a código):**
```
Síntoma: "La API retorna 500"
¿Por qué? → null reference exception en UserService.getProfile()
¿Por qué? → user.preferences es null cuando no tiene perfil
¿Por qué? → getUserById() retorna el user sin el objeto preferences
¿Por qué? → La query SQL hace LEFT JOIN pero no incluye preferences en el SELECT
¿Por qué? → El desarrollador añadió el LEFT JOIN pero olvidó el campo en SELECT

Causa raíz: Query SQL incompleta
Fix correcto: Agregar campo faltante + test de integración que cubre usuario sin perfil
Fix incorrecto: null-check en UserService (parche al síntoma, no a la causa)
```

**Categorías de causas raíz más comunes:**
```
1. Estado inesperado
   → Variable no inicializada, race condition, cache stale

2. Asunción incorrecta sobre el contrato
   → La función retorna null (no esperado), el tipo no es lo que parece

3. Timing / orden de operaciones
   → Async sin await, event listener registrado tarde, initialization order

4. Overflow / underflow / truncación
   → Integer overflow, float precision, string encoding

5. Configuración de entorno
   → La variable de entorno no está en prod, diferente versión de librería

6. Concurrencia
   → Race condition, deadlock, stale closure en async JS/Swift
```

**Técnica de eliminación de hipótesis:**
```
Para cada hipótesis sobre la causa:
1. Predice: "Si la causa es X, entonces cuando hago Y debería ver Z"
2. Experimenta: ejecuta Y
3. Observa: ¿ves Z?
4. Si sí → hipótesis confirmada, avanza a Fase 4
5. Si no → hipótesis descartada, genera nueva hipótesis
```

---

### FASE 4: Verificación del Fix

**Objetivo:** Confirmar que el fix resuelve la causa raíz sin romper nada más.

**Protocolo de verificación:**
```
1. El test de regresión (creado en Fase 1) debe pasar → GREEN
2. Todos los tests existentes deben seguir pasando → NO REGRESIONES
3. Verificar en el entorno donde ocurrió el bug, no solo en local
4. Si fue un bug de producción: replay del log/evento que lo causó
5. Si fue un race condition: stress test con concurrencia elevada
```

**Defense in Depth — Añadir capas de protección:**
```python
# No solo fixes el bug — previene la clase de bugs similar:

# Antes (fix puntual):
def get_user_profile(user_id):
    user = db.query("SELECT * FROM users WHERE id = %s", user_id)
    # Fix: añadir preferences al SELECT
    user = db.query("SELECT *, preferences FROM users WHERE id = %s", user_id)
    return user

# Después (defense in depth):
def get_user_profile(user_id: str) -> UserProfile:
    user = db.query(
        "SELECT id, email, name, preferences FROM users WHERE id = %s",
        user_id
    )
    if user is None:
        raise UserNotFoundError(f"User {user_id} not found")

    # Invariant assertion — si esto explota, hay un bug en la query
    assert 'preferences' in user, (
        f"Query returned user without preferences field. "
        f"This is a data integrity issue. User: {user_id}"
    )

    return UserProfile.from_dict(user)
```

**Post-mortem mínimo para bugs de producción:**
```markdown
## Bug Post-mortem: [título]

**Timeline:**
- HH:MM: Primera alerta / reporte
- HH:MM: Debugging iniciado
- HH:MM: Causa raíz identificada
- HH:MM: Fix desplegado
- HH:MM: Sistema estabilizado

**Causa raíz:** [una frase]

**Por qué no fue detectado antes:**
- [ ] No había test para este caso
- [ ] El test existente tenía mocks que ocultaban el bug
- [ ] Solo ocurre bajo carga alta
- [ ] Otra razón: ___

**Acciones de prevención:**
1. Test de regresión añadido (PR #___)
2. Monitoreo/alerta añadido
3. Documentación actualizada
```

## Técnicas Avanzadas

### Root Cause Tracing — Para Bugs Profundos

Cuando el stack trace no es suficiente, traza la cadena completa de causalidad:

```
Observación → Consecuencia Inmediata → Consecuencia Secundaria → ... → Input Original

Ejemplo:
NullPointerException en PaymentService
← Order.customer es null
← Customer no se cargó en la hydración del Order
← La query eager load no incluye Customer cuando Order.status == 'draft'
← La condición fue añadida como "optimización" hace 3 sprints
← Input original: el usuario creó un borrador y luego intentó pagar
```

### Condition-Based Waiting — Para Race Conditions

```javascript
// ❌ Timing-based (flaky, no determinístico):
await sleep(2000) // "deja que termine el async"

// ✅ Condition-based (determinístico):
await waitForCondition(
  () => document.querySelector('[data-testid="result"]') !== null,
  { timeout: 5000, interval: 100 }
)

// En tests con async:
await expect.poll(
  () => getProcessedCount(),
  { timeout: 5000 }
).toBe(expectedCount)
```

## Lo Que NUNCA Hacer al Debuggear

```
🚨 "Probar random stuff hasta que funcione"
   → Si no sabes por qué funciona, no sabes por qué podría volver a romperse

🚨 Añadir try/catch vacíos para "suprimir el error"
   → Estás convirtiendo bugs evidentes en bugs silenciosos que aparecen tarde

🚨 "Funciona en mi máquina" sin investigar la diferencia
   → La diferencia es la causa raíz. Investígala.

🚨 Revertir sin entender qué causó el bug
   → El problema sigue existiendo en el código. Solo lo aplazaste.

🚨 Fix en producción directamente sin test
   → El fix de hoy es el bug de mañana si no hay test de regresión
```
