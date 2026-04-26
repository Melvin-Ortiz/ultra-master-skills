---
name: test-driven-development
description: >
  Activar cuando el usuario implementa features, corrige bugs, o agrega funcionalidad.
  TDD no es opcional en código de producción — es la diferencia entre código que
  funciona y código que *crees* que funciona. Usar antes de escribir cualquier
  implementación. El ciclo RED-GREEN-REFACTOR no es negociable.
---

# Test-Driven Development — RED-GREEN-REFACTOR

TDD no es escribir tests después. Es una disciplina de diseño que usa los tests
como especificación ejecutable. El test describe el comportamiento deseado;
el código lo satisface; el refactor lo hace mantenible.

## Filosofía Central

**Un test que nunca falla no prueba nada.**
Si escribes un test y pasa inmediatamente sin código nuevo, el test está mal.

**El test más valioso es el que falla por la razón correcta.**
Un test que falla con `AssertionError: expected X but got Y` está funcionando.
Un test que falla con `TypeError` o `ImportError` está mal diseñado.

## El Ciclo Completo

### 🔴 RED — Escribe el test primero

```
1. Identifica el comportamiento más pequeño que puedas validar
2. Escribe UN test que capture ese comportamiento
3. Ejecuta el test → DEBE FALLAR con el error esperado
4. Si pasa sin código: el test no prueba nada. Bórralo y reescríbelo.
5. Si falla con error inesperado: el test tiene un bug. Arréglalo primero.
```

**Anatomía de un buen test:**
```python
def test_calculate_discount_applies_percentage_to_price():
    # ARRANGE: setup mínimo, sin ruido
    price = Decimal("100.00")
    discount_rate = Decimal("0.20")

    # ACT: una sola acción
    result = calculate_discount(price, discount_rate)

    # ASSERT: una sola verificación lógica (pueden ser múltiples assert)
    assert result == Decimal("80.00")
    assert result < price  # invariante que documentamos explícitamente

# Nombre del test = especificación en lenguaje natural
# test_<unidad>_<condicion>_<resultado_esperado>
```

**Test TypeScript equivalente:**
```typescript
describe('calculateDiscount', () => {
  it('applies percentage rate to price', () => {
    // ARRANGE
    const price = 100
    const discountRate = 0.20

    // ACT
    const result = calculateDiscount(price, discountRate)

    // ASSERT
    expect(result).toBe(80)
    expect(result).toBeLessThan(price)
  })
})
```

### 🟢 GREEN — Código mínimo que hace pasar el test

```
La trampa del GREEN: escribir más código del necesario.
El objetivo no es escribir código bonito — es hacer pasar el test.

Permitido en GREEN:
- Hardcodear valores si solo hay un test
- Duplicar lógica temporalmente
- Ignorar edge cases aún no testeados
- Soluciones obvias aunque no sean las más elegantes

NO permitido en GREEN:
- Especulación sobre casos futuros
- Abstracciones no requeridas por ningún test
- Optimizaciones prematuras
```

**Regla de la triangulación:** Si la implementación hardcodeada hace pasar todos
los tests, necesitas más tests antes de generalizar.

```python
# Primer test: test_calculate_discount_applies_percentage_to_price
# GREEN naïve (válido si solo hay este test):
def calculate_discount(price, rate):
    return Decimal("80.00")  # Hardcodeado — válido hasta que haya más tests

# Segundo test: test_calculate_discount_with_different_price
# Ahora sí se requiere la implementación general:
def calculate_discount(price, rate):
    return price * (1 - rate)
```

### 🔵 REFACTOR — Mejora sin cambiar comportamiento

```
El REFACTOR es donde ocurre el diseño real.
Los tests son tu red de seguridad — si siguen verdes, el comportamiento es idéntico.

Checklist de REFACTOR:
□ ¿Hay duplicación obvia? → Extract function/method
□ ¿El nombre comunica intención? → Rename
□ ¿La función hace más de una cosa? → Single Responsibility
□ ¿Hay números mágicos? → Named constants
□ ¿La abstracción está en el nivel correcto? → Move/restructure
□ ¿Los tests siguen verdes después de cada cambio? → Commit por cambio atómico
```

**Regla: Nunca refactorizar con tests en rojo.**

## Qué Testear y Qué No

### ✅ Siempre testear:
```
- Lógica de negocio (cálculos, transformaciones, validaciones)
- Casos borde: null/undefined/vacío/máximos/mínimos
- Manejo de errores: ¿qué lanza? ¿qué retorna en failure?
- Invariantes: propiedades que siempre deben cumplirse
- Contratos de interfaces públicas
```

### ❌ No testear (o testear de forma diferente):
```
- Implementación interna (private methods) → testea el comportamiento observable
- Framework/librería de terceros → confía en sus propios tests
- Getters/setters triviales sin lógica → son código de datos, no lógica
- Configuración estática → integration tests, no units
```

### Sobre los Mocks

```python
# ✅ Mock dependencias externas (I/O, red, tiempo, randomness)
@patch('mymodule.datetime')
def test_expires_correctly(mock_dt):
    mock_dt.now.return_value = datetime(2025, 1, 1)
    result = create_session(user_id="123")
    assert result.expires_at == datetime(2025, 1, 8)

# ❌ No mockear lo que estás testeando
# Si mockeas la clase que testeas, no estás testeando nada

# ✅ Test doubles para dependencias en integration
class FakeEmailService(EmailServiceProtocol):
    def __init__(self):
        self.sent = []
    def send(self, to, subject, body):
        self.sent.append({'to': to, 'subject': subject})
```

## TDD para Bugs — El Protocolo de Regresión

```
NUNCA corrijas un bug sin escribir primero un test que lo reproduce:

1. Reproduce el bug con un test → RED
2. Verifica que el test falla por la razón correcta (el bug)
3. Corrige el bug mínimamente → GREEN
4. El test se convierte en prueba de no-regresión permanente
5. REFACTOR si aplica

Si no puedes escribir un test que reproduce el bug,
no entiendes el bug. Investiga más antes de arreglarlo.
```

## Vertical Slices — TDD para Features Completas

Para features que cruzan múltiples capas (API → Service → DB):

```
1. Escribe el test de integración end-to-end primero (falla)
2. Identifica la primera unidad a implementar para avanzar
3. Escribe test unitario para esa unidad (falla)
4. Implementa la unidad → GREEN
5. Sube un nivel → el test de integración falla por la siguiente pieza
6. Repite hasta que el test e2e pase
```

Esta técnica garantiza que cada pieza construida es necesaria y suficiente.

## Anti-Patrones Críticos a Evitar

```
🚨 Test después de implementar:
   "Voy a implementar primero y luego le agrego tests"
   → No es TDD. Es documentación de código existente.
   → Los tests que pasan desde el principio no probaron nada nuevo.

🚨 Tests que no fallan:
   Escribes un test, pasa inmediatamente. No agregaste valor.
   → Haz el test más estricto hasta que falle.

🚨 Múltiples asserts en conceptos diferentes:
   def test_everything_about_user():
       assert user.name == ...
       assert user.email == ...
       assert user.age > 18
       assert user.is_active
   → Separa en tests distintos. Cada test = un concepto.

🚨 Tests que dependen del orden de ejecución:
   Si el test B solo pasa si el test A corrió antes, tienes estado compartido.
   → Cada test debe ser completamente independiente.

🚨 Ignorar tests lentos:
   "Ese test tarda 5 segundos, lo saltamos en local"
   → Mocks o test doubles. Los tests deben correr en < 1s para unit, < 30s para suite.
```

## Métricas de Calidad de Test

```
Suite de tests saludable:
- Velocidad: unit tests < 10ms c/u, suite completa < 30s
- Confiabilidad: 0 flaky tests en 10 ejecuciones consecutivas
- Cobertura de ramas: > 80% (no % de líneas — las ramas importan más)
- Ratio test/código: 1:1 a 2:1 en lógica de negocio es normal
- Tests que fallaron al menos una vez: 100% (si nunca falló, no probó nada)
```
