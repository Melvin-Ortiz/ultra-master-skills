---
name: verification-before-completion
description: >
  Activar SIEMPRE antes de declarar cualquier tarea como completada. Si el usuario
  dice "listo", "terminé", "está done", "ya lo arreglé" — este skill verifica que
  sea verdad. No existe "done" sin verificación. El trabajo no terminado que parece
  terminado es peor que el trabajo que claramente no está terminado.
---

# Verification Before Completion — Done Significa Done

La diferencia entre "creo que está arreglado" y "está arreglado" es exactamente
la diferencia entre "probablemente fallará en producción" y "no fallará en producción".

## Regla Fundamental

**Nada está done hasta que la verificación lo confirma.**

Ni el código más elegante, ni la solución más "obvia", ni la confianza más alta.
La verificación es objetiva. La confianza es subjetiva.

---

## Checklist de Verificación — Por Tipo de Trabajo

### Para Bugfixes

```
□ El test de regresión que reproduce el bug ahora PASA
  (Si no escribiste ese test, el bug no está realmente arreglado — lo suprimiste)

□ El bug no reaparece con variaciones del input original:
  - ¿Qué pasa con inputs similares pero diferentes?
  - ¿El fix asume algo específico del input que podría no cumplirse?

□ Todos los tests existentes siguen pasando:
  npm test / pytest / go test / etc.
  Si alguno falló → regresión introducida → no está done

□ El fix funciona en el entorno donde ocurrió el bug:
  - ¿Solo probaste en local?
  - ¿El bug ocurría en staging/prod con configs diferentes?
  - ¿Hay datos de producción necesarios para reproducirlo?

□ Se verificó la causa raíz, no solo el síntoma:
  - ¿El mismo bug podría ocurrir en otro lugar con el mismo patrón?
  - Si es así → fix en ambos lugares, no solo donde fue reportado
```

### Para Features Nuevas

```
□ El criterio de done del ticket está satisfecho:
  - Leer el ticket/spec de nuevo, no desde memoria
  - Verificar cada punto explícitamente
  - Los edge cases mencionados en el spec están cubiertos

□ Tests del happy path pasan

□ Tests de los casos de error/falla pasan

□ Los edge cases documentados tienen tests:
  - null/undefined/vacío
  - mínimos y máximos
  - concurrencia si aplica
  - usuario sin permisos
  - datos corruptos o inesperados

□ La feature funciona end-to-end, no solo unitariamente:
  - ¿Probaste el flujo completo desde la entrada hasta la salida?
  - ¿Solo probaste el módulo en aislamiento?

□ Performance aceptable bajo carga realista:
  - ¿Qué pasa con N=1000 registros, no solo N=5?
  - ¿Hay queries N+1 ocultas?
```

### Para Refactors

```
□ El comportamiento observable es IDÉNTICO antes y después:
  - Los tests existentes siguen pasando (sin modificación)
  - Si modificaste tests para que pasaran → cambiaste el comportamiento (no es refactor)

□ Los tests nuevos que escribiste para el refactor también pasan

□ La build completa sin warnings adicionales:
  - TypeScript sin any nuevos
  - ESLint/pylint sin nuevas violaciones
  - Sin dead code introducido

□ El código refactorizado es más fácil de entender que antes:
  - Un colega podría entenderlo sin explicación?
  - Los nombres comunican intención?
```

### Para Cambios de Infrastructure / Config

```
□ Verificado en un entorno de test PRIMERO, nunca directo en producción:
  - ¿Hay un staging donde validar?
  - ¿Hay un namespace de K8s de prueba?

□ El rollback está documentado y probado:
  - ¿Cómo revierto si esto sale mal?
  - ¿El rollback fue probado o solo documentado?

□ Las métricas post-cambio muestran comportamiento esperado:
  - Error rates normales?
  - Latencia normal?
  - Resource usage normal?

□ Los runbooks / documentación están actualizados:
  - Si otro engineer tiene que manejar este sistema a las 3am, ¿encuentra documentación actualizada?
```

---

## El Test de "Explain to a Skeptic"

Antes de declarar done, imagina que un ingeniero senior escéptico pregunta:
**"¿Cómo sé que esto realmente funciona?"**

Tu respuesta debe ser:
```
"Puedo mostrarte exactamente que funciona corriendo [comando específico].
El output esperado es [output específico].
Y puedo mostrarte que el escenario de falla original ya no ocurre porque
[test específico] ahora pasa."
```

Si no puedes dar esa respuesta → no está done.

**No son evidencias válidas de done:**
- "Lo revisé y se ve bien"
- "Es un cambio simple, no puede haber fallado nada"
- "Funciona en mi máquina"
- "Los tests principales pasan" (sin especificar cuáles)
- "Estoy bastante seguro de que funciona"

---

## Verificación Rápida vs. Verificación Completa

No toda tarea requiere el mismo nivel de verificación. Calibrar según el riesgo:

```
VERIFICACIÓN RÁPIDA (cambio de bajo riesgo: typo, color, texto):
□ El cambio se ve correcto visualmente
□ Build no rompe
□ Ningún test relacionado falla

VERIFICACIÓN ESTÁNDAR (la mayoría de features y bugfixes):
□ Checklist completo por tipo de trabajo (arriba)
□ Test en entorno similar al objetivo

VERIFICACIÓN EXHAUSTIVA (cambios de alta criticidad: auth, payments, data migrations):
□ Checklist completo + revisión de código por otro ingeniero
□ Test en staging con datos similares a producción
□ Load test si aplica
□ Security review si hay inputs del usuario o datos sensibles
□ Plan de rollback documentado y aprobado
□ Monitoreo activo por [N] horas post-deploy
```

---

## Cuando La Verificación Falla

Si la verificación revela que algo no funciona:

```
1. NO declarar done parcialmente ("está casi listo")
   Parcialmente done = no done.

2. Identificar exactamente qué falla:
   - ¿Es un caso edge que no consideraste?
   - ¿Es una regresión que introdujiste?
   - ¿Es el spec incompleto o ambiguo?

3. Decidir:
   - Si es fix rápido (< 30 min): resolver ahora, re-verificar
   - Si es trabajo significativo: documentar lo que falta, hacer PR de lo que sí está done,
     crear ticket para el resto
   - Si es el spec el problema: discutir con stakeholder, no implementar suposiciones

4. Nunca hacer push de código que sabes que tiene problemas sin documentarlos.
```

---

## Señal de Done Real

```
✅ Done real:
- Los tests automatizados confirman el comportamiento
- Probé manualmente el flujo end-to-end
- No hay casos conocidos sin manejar
- El código está en el repositorio (no en local sin commit)
- La documentación está actualizada
- La persona que lo reportó (si es un bug) puede confirmar que ya no ocurre

❌ Pseudo-done (false positive):
- "Creo que funciona"
- "Los tests unitarios pasan" (pero no hay tests de integración)
- "Lo probé con mi usuario de prueba" (no con los edge cases del bug original)
- "El código está listo pero me falta hacer commit"
- "Lo hice pero no verifiqué que funciona de punta a punta"
```
