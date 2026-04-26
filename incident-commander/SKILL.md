---
name: incident-commander
description: >
  Activar cuando hay un incidente de producción activo o post-mortem: error masivo,
  outage, degradación severa de performance, data corruption, security breach, o
  cualquier situación donde el usuario dice "producción está caída", "hay un outage",
  "algo explotó en prod", "perdimos datos", "hay un breach". También para PIR
  (Post-Incident Review) después de un incidente. La velocidad de respuesta y la
  claridad de comunicación en un incidente define la diferencia entre 30 min y 4 horas
  de downtime.
---

# Incident Commander — Playbook de Respuesta a Incidentes

En un incidente, el pánico y la improvisación son tus peores enemigos.
Este skill impone estructura cuando todo parece estar en llamas.

## Regla de Oro

**Comunica primero, arregla después.**
El stakeholder más importante durante un incidente no es el sistema — son las personas
que dependen de él y las que tienen que tomar decisiones sobre él.

---

## FASE 0: Clasificación Inmediata (< 2 minutos)

Antes de hacer NADA técnico, clasificar el incidente:

```
SEVERITY 1 — CRÍTICO (respuesta inmediata):
□ Sistema completamente inaccesible
□ Corrupción o pérdida de datos en curso
□ Brecha de seguridad activa
□ Impacto en > 50% de usuarios
→ Escalar AHORA. Despertar a quien sea necesario. Comunicar en < 5 min.

SEVERITY 2 — ALTO (respuesta urgente):
□ Funcionalidad core degradada significativamente
□ Impacto en 20-50% de usuarios o casos de uso
□ Posible pérdida de datos (no confirmada)
→ Equipo principal involucrado. Update cada 15 min.

SEVERITY 3 — MEDIO (respuesta normal):
□ Feature específica no funcionando (no core)
□ Impacto en < 20% de usuarios
□ Performance degradada pero funcional
→ Trabajar en horario laboral. Update cada 60 min.

SEVERITY 4 — BAJO (tracking):
□ Issue menor sin impacto en usuarios
□ Error no reproducible
→ Ticket creado, no hay urgencia.
```

---

## FASE 1: Comunicación Inmediata (< 5 minutos de SEV1/2)

**La primera comunicación se envía ANTES de entender completamente el problema.**

```markdown
# Template: Primera Comunicación

📢 [SEV-1] INCIDENTE ACTIVO — [Fecha y hora]

**Impacto:** [Lo que saben los usuarios: "El login falla para todos los usuarios"
              NO: "hay un null pointer en AuthService.ts"]

**Estado:** Investigando. Primera actualización en 15 minutos.

**Incident Commander:** [Tu nombre]
**Canal de coordinación:** [#incident-YYYY-MM-DD-N en Slack]
```

**Canales de comunicación paralelos:**
```
1. Canal interno (equipo técnico): detalles técnicos granulares
2. Canal de stakeholders (management, soporte): impacto y ETA, sin jerga técnica
3. Status page pública (si aplica): mensaje para usuarios finales

Nunca mezclar las audiencias en el mismo canal.
```

---

## FASE 2: Investigación Estructurada

### Línea de tiempo del incidente

Reconstruir la secuencia desde el inicio:

```markdown
| Hora  | Evento |
|-------|--------|
| HH:MM | Primera alerta recibida (¿por qué no se detectó antes?) |
| HH:MM | Equipo notificado |
| HH:MM | Último deploy / cambio de config / cambio de tráfico |
| HH:MM | Primera anomalía en métricas (antes de la alerta?) |
| HH:MM | ... |
```

### Hypothesis-Driven Investigation

No investigar al azar. Generar y descartar hipótesis sistemáticamente:

```
TEMPLATE POR HIPÓTESIS:

Hipótesis: "El problema es causado por [X]"
Evidencia a favor: [qué observaciones apoyan esto]
Cómo verificar: [qué acción/consulta confirma o descarta]
Resultado: [CONFIRMADA / DESCARTADA / PARCIALMENTE]
```

**Las hipótesis más comunes en orden de probabilidad:**
```
1. ¿Hubo un deploy reciente? → Correlacionar timestamps
2. ¿Hubo un cambio de config? → Config history, feature flags
3. ¿Cambió el tráfico / patrón de uso? → Analytics, load balancer logs
4. ¿Hay un servicio externo fallando? → Status pages de dependencias
5. ¿Hay un problema de recursos (CPU, memoria, disco, conexiones)? → Dashboards
6. ¿Hay un problema de datos (corrupción, migración fallida)? → DB logs
```

### Comandos de Diagnóstico Rápido

```bash
# --- Estado general de servicios ---
kubectl get pods --all-namespaces | grep -v Running
systemctl status <service>

# --- Logs recientes (últimos 15 min del error) ---
kubectl logs <pod> --since=15m | grep -i "error\|critical\|fatal"
journalctl -u <service> --since "15 minutes ago" | grep -iE "error|warn"

# --- Métricas de recursos ---
top -bn1 | head -20
df -h  # Disco
free -h  # Memoria
netstat -an | grep ESTABLISHED | wc -l  # Conexiones

# --- Database ---
# PostgreSQL: conexiones activas y queries lentas
SELECT pid, now() - pg_stat_activity.query_start AS duration,
       query, state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

# Locks (PostgreSQL)
SELECT * FROM pg_locks pl LEFT JOIN pg_stat_activity psa
ON pl.pid = psa.pid WHERE NOT granted;

# --- HTTP errors en NGINX/ALB ---
grep " [5][0-9][0-9] " /var/log/nginx/access.log | tail -100

# --- Deployment reciente ---
kubectl rollout history deployment/<name>
git log --oneline -20  # Últimos commits
```

---

## FASE 3: Mitigación (Estabilizar antes de arreglar)

**Regla de la mitigación:**
El objetivo inmediato es **detener el daño**, no arreglar la causa raíz.

```
Orden de prioridad:
1. ¿Puedo revertir el último cambio? → Rollback (más rápido que arreglar)
2. ¿Puedo aislar el componente afectado? → Circuit breaker, feature flag off
3. ¿Puedo escalar recursos? → Horizontal scaling, aumentar límites
4. ¿Puedo redirigir tráfico? → Failover a región secundaria, backup
5. ¿Puedo poner el sistema en modo degradado? → Deshabilitar features no críticas

Rollback siempre es la opción más segura si hay un deploy reciente.
```

**Checklist antes de aplicar cualquier fix:**
```
□ ¿Entiendo por qué esto va a funcionar?
□ ¿Qué pasa si este fix empeora la situación?
□ ¿Tengo un plan de rollback de este fix?
□ ¿Alguien más está mirando cuando lo aplico?
□ ¿Hay un runbook de este tipo de operación?
```

---

## FASE 4: Comunicación Durante el Incidente

**Update template cada 15 minutos (SEV1) / 30 min (SEV2):**

```markdown
📊 UPDATE #N — [HH:MM]

**Estado:** [Investigando / Mitigando / Estabilizando / Resuelto]
**Impacto actual:** [Número de usuarios afectados y de qué forma]
**Causa raíz:** [Si está identificada / "Aún investigando"]
**Acciones en curso:** [Qué están haciendo ahora]
**Próximo update:** [HH:MM]
**ETA de resolución:** [Estimado / Sin ETA clara]
```

---

## FASE 5: Resolución y PIR

### Declaración de resolución:

```markdown
✅ INCIDENTE RESUELTO — [HH:MM]

**Duración:** X horas Y minutos
**Impacto total:** [usuarios afectados × horas]
**Causa raíz:** [Una frase específica]
**Fix aplicado:** [Qué se cambió]
**PIR programado:** [Fecha]
```

### Post-Incident Review (PIR) — Template:

```markdown
# PIR: [Título del Incidente]
**Fecha del incidente:** [Fecha]
**Duración:** [Tiempo desde primera alerta hasta resolución]
**Severidad:** SEV-[N]
**Autores:** [Quiénes participaron]

## Impacto
- Usuarios afectados: [N usuarios / % del total]
- Operaciones fallidas: [N requests / transacciones]
- Revenue impactado: [$X estimado]

## Timeline
[Reconstrucción detallada minuto a minuto]

## Causa Raíz
[Una explicación técnica sin culpas]

## Por Qué No Lo Detectamos Antes
[Brecha en monitoreo, alertas, tests, proceso]

## 5 Porqués
1. ¿Por qué ocurrió el incidente? → [causa inmediata]
2. ¿Por qué existía esa condición? → [causa subyacente]
3. ¿Por qué no había protección contra ella? → [brecha del sistema]
4. ¿Por qué no fue detectada antes? → [brecha de observabilidad]
5. ¿Por qué no había proceso para prevenirla? → [brecha organizacional]

## Acciones de Prevención
| Acción | Owner | Due date | Prioridad |
|--------|-------|----------|-----------|
| [Acción específica y medible] | [Persona] | [Fecha] | P1/P2/P3 |

## Qué Salió Bien
[El sistema de alertas funcionó, la comunicación fue clara, el rollback fue rápido]

## Reglas del PIR
- Sin culpas: Los sistemas fallan, las personas hacen lo mejor que pueden
- Retrospectiva justa: Juzgar con la información que se tenía en ese momento
- Acciones SMART: Específicas, medibles, alcanzables, con dueño y fecha
```

---

## Incident Commander Checklist

```
Durante el incidente:
□ ¿Tengo designado un IC claro? (una persona con autoridad de decisión)
□ ¿Están todos los responders en el canal de coordinación?
□ ¿Hay updates de comunicación regulares?
□ ¿Hay alguien explorando causas alternativas si la hipótesis principal no funciona?
□ ¿Tenemos un scribe tomando notas del timeline?
□ ¿Hay alguien pensando en comunicación externa mientras los técnicos debuggean?

Antes de aplicar cualquier cambio:
□ ¿Tenemos rollback plan?
□ ¿Alguien más está mirando?
□ ¿Entendemos por qué este cambio va a ayudar?

Al resolver:
□ ¿La resolución está confirmada por métricas, no solo por intuición?
□ ¿Se comunicó la resolución a todos los canales?
□ ¿Está el PIR agendado?
```
