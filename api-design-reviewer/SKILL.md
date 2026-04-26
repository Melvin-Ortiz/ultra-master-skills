---
name: api-design-reviewer
description: >
  Activar cuando el usuario diseña o revisa una API REST, GraphQL, o gRPC. También
  cuando dice "revisa mi API", "¿está bien este endpoint?", "diseña los endpoints para X",
  "¿cómo expongo esta funcionalidad?". Las APIs son contratos públicos — un error de
  diseño cuesta meses de compatibilidad hacia atrás o migraciones dolorosas para clientes.
---

# API Design Reviewer — Contratos que Sobreviven el Tiempo

Una API mal diseñada tiene dos costos: el costo inmediato de confundir a sus
consumidores, y el costo a largo plazo de no poder cambiarla sin romperlos.

## Principios de Diseño de API

### 1. Las APIs son contratos, no implementaciones

```
Lo que expones en tu API no es tu modelo interno — es lo que prometes a tus clientes.
El modelo interno puede cambiar libremente. El contrato, no.

Regla de Postel aplicada a APIs:
- Sé conservador en lo que produces (solo expón lo que necesitan)
- Sé tolerante en lo que aceptas (acepta variaciones razonables de input)
```

### 2. Semántica HTTP correcta

```
GET    → Idempotente, cacheable, sin side effects
POST   → Crear recurso o acción no idempotente
PUT    → Reemplazar recurso completo (idempotente)
PATCH  → Actualización parcial (idempotente si es bien implementado)
DELETE → Eliminar recurso (idempotente)

Errores comunes:
❌ GET /api/deleteUser?id=123  → DELETE /api/users/123
❌ POST /api/getOrders         → GET /api/orders
❌ PUT /api/users/123 para actualizar un campo → PATCH /api/users/123
```

### 3. Status codes correctos

```
2xx — Éxito:
200 OK           → Response con body
201 Created      → Recurso creado (+ Location header con URL del nuevo recurso)
204 No Content   → Éxito sin body (DELETE, algunas acciones)
206 Partial      → Response parcial (paginación con ranges)

4xx — Error del cliente:
400 Bad Request  → Input malformado o inválido
401 Unauthorized → No autenticado (a pesar del nombre, es AuthN)
403 Forbidden    → Autenticado pero sin autorización (es AuthZ)
404 Not Found    → Recurso no existe (cuidado: usar 403 si el recurso existe pero no autorizado)
409 Conflict     → Estado conflictivo (email duplicado, concurrent edit)
422 Unprocessable → Semánticamente inválido (validación de dominio fallida)
429 Too Many Requests → Rate limiting

5xx — Error del servidor:
500 Internal Server Error → Bug (no exponer detalles internos)
502 Bad Gateway          → Upstream service error
503 Service Unavailable  → Temporalmente fuera de servicio (con Retry-After)
```

---

## Checklist de Review

### ✅ Resource Design

```
□ ¿Los nombres de recursos son sustantivos, no verbos?
  ❌ /api/createUser, /api/getOrders, /api/deleteProduct
  ✅ /api/users, /api/orders, /api/products

□ ¿Los recursos son plurales?
  ❌ /api/user, /api/order
  ✅ /api/users, /api/orders

□ ¿La jerarquía refleja relaciones reales del dominio?
  ✅ /api/users/{userId}/orders  (orders de un user)
  ✅ /api/orders/{orderId}/items (items de una order)
  ❌ /api/users/{userId}/orders/{orderId}/items/{itemId}/product
     (demasiado profundo — considera /api/products/{productId})

□ ¿Las acciones que no son CRUD tienen endpoints de acción claros?
  ✅ POST /api/orders/{orderId}/cancel  (acción, no un field update)
  ✅ POST /api/users/{userId}/verify-email
  ❌ PATCH /api/orders/{orderId} con body { "status": "cancelled" }
     (permite valores de status inválidos, no expresa la intención)
```

### ✅ Request/Response Design

```
□ ¿El response body tiene estructura consistente en toda la API?
  Siempre el mismo envelope:
  {
    "data": { ... },           // El recurso o colección
    "meta": { "total": N },    // Metadata de paginación
    "links": { "next": "..." } // HATEOAS links (si aplica)
  }

□ ¿Los errores tienen formato consistente (RFC 9457)?
  {
    "type": "https://api.example.com/errors/validation",
    "title": "Validation Failed",
    "status": 422,
    "detail": "Email format is invalid",
    "instance": "/api/v1/users",
    "errors": [  // Detail de múltiples errores
      { "field": "email", "message": "Invalid email format", "code": "INVALID_FORMAT" }
    ]
  }

□ ¿Las fechas son ISO 8601 con timezone? (no timestamps Unix en el body)
  ✅ "created_at": "2025-01-15T10:30:00Z"
  ❌ "created_at": 1736937000

□ ¿Los IDs son strings, no integers? (escala mejor, opaco al cliente)
  ✅ "id": "usr_01JKSA..."  (ULID o UUID)
  ❌ "id": 12345

□ ¿Los campos opcionales son explícitamente null vs. ausentes?
  Decide y documenta: ¿"preferences": null significa "sin preferencias" o
  "no se cargaron las preferencias"? Son semánticas diferentes.
```

### ✅ Versioning

```
□ ¿Hay versioning desde el primer endpoint?
  /api/v1/...  o header: API-Version: 2025-01

□ ¿La estrategia de versioning está documentada?
  - URL versioning: /v1/, /v2/ → más simple, visible en logs
  - Header versioning: más RESTful, más complejo de implementar
  - Query param: /api/users?version=2 → evitar, cacheable poorly

□ ¿Hay una política clara de deprecación?
  "V1 será soportada por 12 meses después del lanzamiento de V2"
  Header en respuestas deprecated: Deprecation: true, Sunset: 2026-01-01
```

### ✅ Breaking Changes — Detector

**Cambios que rompen a los clientes existentes:**
```
🚨 BREAKING CHANGES (requieren nueva versión de API):
- Eliminar un campo del response
- Renombrar un campo del response
- Cambiar el tipo de un campo (string → number, object → array)
- Cambiar el formato de un campo (ISO date → timestamp)
- Eliminar un endpoint
- Cambiar el método HTTP de un endpoint
- Hacer obligatorio un campo que era opcional en request
- Cambiar la semántica de un status code existente
- Cambiar la estructura del error response

✅ NON-BREAKING CHANGES (backward compatible):
- Añadir un campo nuevo al response (los clientes lo ignoran)
- Añadir un endpoint nuevo
- Hacer opcional un campo que era obligatorio en request
- Añadir un nuevo valor a un enum (si los clientes manejan unknown values)
- Cambiar validaciones a ser más permisivas
- Mejorar mensajes de error sin cambiar estructura
```

### ✅ Paginación

```
□ ¿Las colecciones grandes tienen paginación?

□ ¿Qué estrategia de paginación usar?

Offset-based: /api/orders?page=3&limit=20
  ✅ Simple, fácil de implementar
  ❌ Inconsistente si datos cambian entre pages
  ❌ Performance pobre en páginas tardías (OFFSET N es O(N))
  → Usar para: UIs con "página X de Y", colecciones estables

Cursor-based: /api/orders?after=cursor_abc&limit=20
  ✅ Consistente (no se pierden items si datos cambian)
  ✅ Performance constante
  ❌ No permite saltar a página específica
  → Usar para: infinite scroll, feeds, datos que cambian frecuentemente

Keyset pagination: /api/orders?after_id=123&limit=20
  ✅ Más simple que cursors pero similar comportamiento
  → Usar para: tablas con ID monotónico

□ ¿El response incluye metadata de paginación?
  {
    "data": [...],
    "pagination": {
      "total": 1024,
      "page": 3,
      "per_page": 20,
      "next_cursor": "abc...",  // o next_page
      "has_more": true
    }
  }
```

### ✅ Filtrado y Búsqueda

```
□ ¿Los filtros son consistentes en sintaxis?
  /api/orders?status=completed&created_after=2025-01-01

□ ¿Hay operadores para rangos y comparaciones?
  /api/products?price_min=100&price_max=500

□ ¿La búsqueda de texto libre es un endpoint separado?
  GET /api/products/search?q=laptop&page=1
  (no mezclar full-text search con filtros simples)
```

### ✅ Seguridad

```
□ ¿Todos los endpoints tienen autenticación? ¿Los que no, están explícitamente marcados como públicos?
□ ¿La autorización se verifica POR RECURSO, no solo en el middleware global?
□ ¿Los IDs son opacos (no predecibles)? → UUID/ULID, no autoincrement
□ ¿Los rate limits están implementados y documentados?
□ ¿Hay CORS configurado correctamente (no Access-Control-Allow-Origin: *)?
□ ¿Los campos sensibles no están en URLs (en logs, no en body)?
   ❌ GET /api/users?token=secret123
   ✅ Header: Authorization: Bearer secret123
```

### ✅ Documentación

```
□ ¿Hay un OpenAPI/Swagger spec actualizado?
□ ¿Cada endpoint documenta: parámetros, responses posibles, errores posibles?
□ ¿Los errores documentados incluyen sus códigos de error internos (machine-readable)?
□ ¿Hay ejemplos de request/response reales?
□ ¿La autenticación está documentada con ejemplos?
□ ¿Están documentados los rate limits y sus headers?
```

---

## Output del Review

```markdown
## API Design Review — [Nombre de la API]

### 🔴 Issues Bloqueantes (deben resolverse antes de lanzar)
1. [Issue específico con endpoint y propuesta de fix]

### 🟡 Issues Importantes (resolver en próxima iteración)
1. [Issue con menor impacto inmediato]

### 🟢 Breaking Changes Identificados (requieren nueva versión)
1. [Cambio que rompe clientes existentes]

### ✅ Aspectos Bien Diseñados
- [Qué está correcto — el review no es solo crítica]

### Scorecard
| Área | Puntuación | Notas |
|------|-----------|-------|
| Resource naming | ⭐⭐⭐⭐☆ | |
| HTTP semantics | ⭐⭐⭐☆☆ | |
| Error handling | ⭐⭐⭐⭐⭐ | |
| Versioning | ⭐⭐☆☆☆ | No hay versioning |
| Security | ⭐⭐⭐⭐☆ | |
| Documentation | ⭐⭐⭐☆☆ | |
```
