---
name: improve-codebase-architecture
description: >
  Activar cuando el usuario quiere mejorar la estructura del codebase, hay demasiados
  archivos pequeños difíciles de navegar, los tests son difíciles de escribir por
  límites de módulo poco claros, hay confusión sobre qué hace qué, o el usuario
  dice "el código está muy fragmentado", "no sé dónde poner esto", "difícil de testear".
  También activar antes de comenzar TDD en un codebase existente.
---

# Improve Codebase Architecture — Profundizando Módulos Superficiales

Un codebase es difícil de trabajar no por su tamaño, sino por su estructura.
Los módulos demasiado pequeños hacen que entender cualquier concepto requiera
navegar entre 10 archivos. Los módulos bien diseñados tienen **interfaces delgadas**
sobre **implementaciones profundas**.

## El Problema Que Este Skill Resuelve

**Síntoma del codebase enfermo:**
```
Para entender cómo se procesa un pago, el desarrollador debe leer:
├── payment/index.ts
├── payment/types.ts
├── payment/validators/amount-validator.ts
├── payment/validators/currency-validator.ts
├── payment/processors/stripe-processor.ts
├── payment/processors/base-processor.ts
├── payment/utils/format.ts
├── payment/utils/helpers.ts
└── payment/constants.ts

9 archivos para entender un concepto.
```

**Síntoma del codebase sano:**
```
payment/
├── PaymentService.ts    # Interfaz pública — todo lo que necesitas saber
└── internal/            # Implementación — no necesitas leerla para usar el módulo
    ├── stripe.ts
    ├── validation.ts
    └── formatting.ts
```

## Proceso de Análisis

### Fase 1: Exploración Natural del Codebase

Explorar el codebase como lo haría un developer que llega por primera vez:

```
Preguntas durante la exploración:
1. ¿Cuántos archivos tengo que leer para entender [concepto X]?
2. ¿Dónde vive la lógica de [Y]? ¿En un lugar o en varios?
3. ¿Si quiero cambiar [comportamiento Z], qué archivos se ven afectados?
4. ¿Qué módulos son "de adentro" (implementación) vs. "de afuera" (API pública)?
5. ¿Los tests me dicen dónde están los límites de responsabilidad?
```

### Fase 2: Identificar las "Confusiones"

Mapear donde el codebase causa fricción:

**Patrón: Extracción por testabilidad (no por coherencia)**
```typescript
// 🚨 Anti-patrón: funciones puras extraídas SOLO para poder testearlas,
// no porque tengan sentido como módulo independiente

// math-utils.ts (existe solo para testear internals de OrderService)
export function calculateSubtotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price * item.qty, 0)
}

// El problema real: los tests de OrderService son tan difíciles de escribir
// que se extraen internals. La solución es mejorar OrderService, no fragmentarlo.

// ✅ Mejor: tests de comportamiento observable, no de internals
describe('OrderService.createOrder', () => {
  it('calculates correct total with multiple items', async () => {
    const order = await orderService.create({
      items: [{ productId: 'A', qty: 2 }, { productId: 'B', qty: 1 }]
    })
    expect(order.total).toBe(expectedTotal)
  })
})
```

**Patrón: Módulo demasiado delgado (no justifica su existencia)**
```
Señales de alerta:
- Archivo de < 20 líneas que solo reexporta de otro
- Módulo con un solo consumidor que vive en la misma carpeta
- "Helpers" que son realmente internals de otro módulo
- "Types" que solo contienen interfaces de un solo módulo
```

**Patrón: Límites de dominio poco claros**
```
Si tienes dudas sobre si algo va en módulo A o B → los límites están mal definidos.
Si un cambio de negocio requiere modificar 5+ archivos → falta cohesión.
Si no puedes hacer mock de una dependencia sin tocar 3 archivos → las capas están mezcladas.
```

### Fase 3: Diseñar Módulos con Interfaces Delgadas

El objetivo: **interfaces más pequeñas, implementaciones más profundas**.

```typescript
// ❌ Módulo superficial (interfaz amplia, implementación distribuida):
// users/index.ts — exporta 47 cosas
export { getUserById, getUserByEmail, createUser, updateUser, deleteUser,
         validateEmail, hashPassword, sendWelcomeEmail, UserType, UserStatus,
         formatUserName, isUserAdmin, getUserRoles, ... }

// ✅ Módulo profundo (interfaz delgada, implementación contenida):
// users/index.ts — exporta solo lo que otros módulos necesitan
export type { User, UserId } from './types'
export { UserService } from './UserService'
// Todo lo demás (validateEmail, hashPassword, etc.) es internal
```

**Diseño de la interfaz pública:**
```typescript
// La interfaz pública del módulo = el contrato con el mundo exterior
// Debe ser lo más pequeña posible sin perder expresividad

interface UserService {
  // Queries
  findById(id: UserId): Promise<User | null>
  findByEmail(email: string): Promise<User | null>

  // Commands
  create(input: CreateUserInput): Promise<User>
  update(id: UserId, changes: Partial<UpdateUserInput>): Promise<User>
  deactivate(id: UserId): Promise<void>
}

// Nota: No exponemos:
// - hashPassword (internal)
// - validateEmail (internal)
// - UserRepository (internal)
// - La query SQL (internal)
```

### Fase 4: Plan de Refactoring Seguro

**Nunca refactorizar sin tests en verde primero.**

```
Secuencia segura de refactoring:
1. Escribir tests de comportamiento observable (si no existen)
   → Estos tests NO cambian durante el refactor
2. Mover archivos (rename/move en el IDE, no a mano)
3. Actualizar imports (herramientas automáticas)
4. Verificar que tests siguen en verde
5. Hacer commit atómico de cada paso
6. Simplificar la implementación ahora que la estructura es clara

Un refactor sin tests es una reescritura. Una reescritura tiene la misma
probabilidad de tener bugs que el código original.
```

## Heurísticas de Evaluación

### ¿Cuántos archivos para entender un concepto?

```
1-2 archivos: Excelente — módulo bien definido
3-4 archivos: Aceptable — puede mejorar
5-7 archivos: Problema — refactorizar
8+ archivos: Crisis — probablemente varios módulos mezclados
```

### ¿Los tests dicen algo sobre el diseño?

```
Tests fáciles de escribir → módulo con buena interfaz
Tests que requieren muchos mocks → dependencias ocultas o mal definidas
Tests que prueban internals → las abstracciones están en el nivel incorrecto
Tests que dependen del orden de ejecución → estado global o dependencias cíclicas
```

### ¿Las dependencias fluyen en la dirección correcta?

```
✅ Core domain (sin dependencias externas)
  ↑ depende de
Application services (orquestan el dominio)
  ↑ depende de
Infrastructure (DB, APIs externas, file system)
  ↑ depende de
Presentation (API routes, UI components)

🚨 Si el core domain importa de infrastructure → inversión de dependencias incorrecta
🚨 Si los services importan de presentation → estás mezclando capas
```

## Entregables del Skill

Al final del análisis, producir:

```markdown
## Análisis de Arquitectura: [Nombre del Módulo/Sistema]

### Diagnóstico
- Número de archivos promedio por concepto: X
- Módulos con interfaz demasiado amplia: [lista]
- Módulos sin razón de ser independiente: [lista]
- Dependencias que van en la dirección incorrecta: [lista]

### Refactors Prioritarios
1. [Refactor específico] — Impacto: [ALTO/MEDIO/BAJO] — Esfuerzo: [horas estimadas]
2. ...

### Plan de Ejecución
- Fase 1 (segura, sin cambios de comportamiento): [específico]
- Fase 2 (consolidación de módulos): [específico]
- Fase 3 (mejora de interfaces): [específico]

### Métricas de Éxito
- Archivos por concepto: de X a Y
- Exports por módulo principal: de X a Y
- Tests que prueban internals: de X a 0
```
