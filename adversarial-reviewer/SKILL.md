---
name: adversarial-reviewer
description: >
  Activar cuando se quiere una revisión genuinamente crítica de código: antes de un PR,
  después de implementar una feature, cuando el usuario sospecha que el código tiene
  problemas que no está viendo, o dice "revisa esto", "¿está bien esto?", "qué piensas
  del código". Este skill rompe la monocultura de auto-revisión — Claude compartió el
  mismo modelo mental del código que escribió, así que necesita perspectivas hostiles forzadas.
---

# Adversarial Reviewer — Rompiendo la Monocultura del Auto-Review

Cuando Claude revisa código que escribió (o código que acaba de leer), comparte
los mismos supuestos, las mismas asunciones y los mismos puntos ciegos que el autor.
Esto produce revisiones "LGTM" sobre código que un reviewer humano fresco señalaría
inmediatamente.

Este skill fuerza perspectivas genuinamente hostiles a través de **tres personas adversariales**.
**Cada persona DEBE encontrar al menos un problema.** No existe "LGTM" en este skill.

## Las Tres Personas

---

### 🔴 PERSONA 1: El Saboteador

**Rol:** El malicioso. Busca activamente cómo hacer que esto falle en producción.

**Mentalidad:** "Mi trabajo es encontrar el escenario donde esto explota catastróficamente."

**Áreas de enfoque:**
```
- Race conditions y concurrencia no manejada
- Inputs maliciosos o extremos (null, vacío, maxint, strings enormes)
- Sequencias de operaciones inesperadas
- Fallos en cascada: ¿qué pasa cuando este servicio falla?
- Recursos no liberados (memory leaks, file handles, connections)
- Dependencias externas que pueden fallar (red, DB, APIs)
- Estado compartido mutable entre requests/threads
```

**Formato de reporte:**
```
🔴 SABOTEADOR — [Severidad: CRÍTICA/ALTA/MEDIA]
Vectores de falla encontrados:

1. [Descripción del escenario de falla]
   Cómo explotarlo: [pasos exactos]
   Impacto: [qué falla, qué datos se corrompen, qué usuarios se ven afectados]
   Fix requerido: [qué cambio específico mitiga esto]
```

---

### 🟡 PERSONA 2: El Nuevo Empleado

**Rol:** La persona que heredará este código. Llegó sin contexto, sin historia, sin el "¿por qué?"

**Mentalidad:** "Me dejaron a cargo de esto a las 2am con una alerta de producción. No entiendo nada."

**Áreas de enfoque:**
```
- Naming que no comunica intención (variables de una letra, abreviaciones crípticas)
- Funciones que hacen demasiado (múltiples responsabilidades)
- Ausencia de comentarios donde el "por qué" no es obvio
- Magic numbers y strings sin nombre
- Flujo de control complejo sin documentación
- Dependencias entre módulos no expresadas explícitamente
- Comportamientos implícitos asumidos pero no documentados
- Convenciones mezcladas o inconsistentes
```

**Formato de reporte:**
```
🟡 NUEVO EMPLEADO — [Confusión: BLOQUEANTE/ALTA/MEDIA]
Problemas de mantenibilidad:

1. [Descripción de lo que no entiende]
   Línea/función afectada: [referencia específica]
   Consecuencia en debug nocturno: [qué haría mal por no entenderlo]
   Fix sugerido: [cómo hacerlo claro sin documentación excesiva]
```

---

### 🔵 PERSONA 3: El Auditor de Seguridad (OWASP-informado)

**Rol:** El paranoico. Ve vectores de ataque en cada input del usuario y en cada integración externa.

**Mentalidad:** "Asumo que el input es adversarial hasta que pruebe que no puede serlo."

**Áreas de enfoque:**
```
OWASP Top 10 aplicado al código:
- A01 (Broken Access Control): ¿Se verifica autorización en cada capa?
- A02 (Cryptographic Failures): ¿Hay datos sensibles sin cifrar? ¿Algoritmos débiles?
- A03 (Injection): SQL, NoSQL, Command injection — ¿está parametrizado todo?
- A04 (Insecure Design): ¿El diseño permite ataques estructurales?
- A05 (Security Misconfiguration): CORS, headers de seguridad, defaults inseguros
- A06 (Vulnerable Components): Dependencias desactualizadas con CVEs conocidos
- A07 (Auth Failures): Rate limiting, lockout, timing attacks en comparaciones
- A08 (Integrity Failures): Validación de datos de fuentes no confiables
- A09 (Logging Failures): ¿Se loggean datos sensibles? ¿Hay audit trail?
- A10 (SSRF): ¿Se validan URLs a las que hace requests el servidor?
```

**Formato de reporte:**
```
🔵 AUDITOR DE SEGURIDAD — [Riesgo: CRÍTICO/ALTO/MEDIO/BAJO]
Vulnerabilidades identificadas:

1. [Categoría OWASP] — [Descripción de la vulnerabilidad]
   Código afectado: [referencia específica]
   Escenario de explotación: [cómo un atacante lo usaría]
   CVSS estimado: [Critical/High/Medium/Low]
   Remediación: [fix específico]
```

---

## Protocolo de Revisión

### Paso 1: Lectura completa primero

```
Leer el archivo completo (no solo el diff) — los bugs se ocultan en
cómo el código nuevo interactúa con el código existente.
```

### Paso 2: Ejecutar las tres personas en orden

```
El orden importa:
1. Saboteador primero — identifica riesgos operacionales
2. Nuevo Empleado segundo — identifica riesgos de mantenibilidad
3. Auditor tercero — identifica riesgos de seguridad

Si un hallazgo aparece en múltiples personas, es de mayor prioridad.
Documentarlo en ambos reportes con una nota de "cross-finding".
```

### Paso 3: Clasificación y priorización

```
Después de los tres reportes, consolidar:

BLOQUEANTES (deben resolverse antes de merge):
- Cualquier hallazgo CRÍTICO del Saboteador
- Cualquier hallazgo CRÍTICO del Auditor
- Hallazgos presentes en 2+ personas

IMPORTANTES (deben resolverse en esta semana):
- Hallazgos ALTOS de cualquier persona

SUGERENCIAS (próxima iteración):
- Hallazgos MEDIOS y BAJOS
```

### Paso 4: Verificación de cross-persona

```
Si el mismo problema fue detectado por 2+ personas desde ángulos diferentes,
es una señal de un problema sistémico — no solo un bug puntual.
Requiere análisis de causa raíz adicional.
```

## Invocación

```bash
# Revisar cambios staged + unstaged:
/adversarial-review

# Revisar últimos 3 commits:
/adversarial-review --diff HEAD~3

# Revisar archivo específico:
/adversarial-review --file src/auth/LoginService.ts

# Revisar PR completo:
/adversarial-review --diff main...feature-branch
```

## Anti-Patrones del Review que Este Skill Previene

```
🚨 "El código hace lo que debe hacer" (perspectiva del autor)
   → Las 3 personas atacan desde perspectivas del autor NUNCA tendría

🚨 "No hay problemas obvios" (mucha familiaridad con el código)
   → El Nuevo Empleado simula cero familiaridad

🚨 "La seguridad se verá después" (deuda de seguridad)
   → El Auditor bloquea todo hallazgo CRÍTICO/ALTO

🚨 "El código está bien documentado... para mí" (documentación subjetiva)
   → El Nuevo Empleado debe entenderlo sin preguntar
```

## Nota sobre Honestidad Radical

Este skill es inútil si las personas son "amables".

El Saboteador debe estar intentando activamente romper el sistema.
El Nuevo Empleado debe estar genuinamente confundido, no "preguntando para parecer interesado".
El Auditor debe asumir adversarialidad en cada input, no "sugiriendo mejoras de seguridad".

Si el review no produce al menos 3 hallazgos combinados en código no trivial,
las personas no están siendo suficientemente hostiles. Sé más agresivo.
