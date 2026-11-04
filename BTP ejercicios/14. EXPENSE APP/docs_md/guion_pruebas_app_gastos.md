# Guion de pruebas: App de informes de gastos (RAP + Fiori elements)

**Autor:** Roberto Puma

**Fecha:** 04.11.2026

**Entorno:** SAP BTP ABAP Environment (Steampunk), RAP managed, Fiori elements (List Report + Object Page)

---

## Índice

1. [Resumen](#1-resumen)
2. [Modelo de datos](#2-modelo-de-datos)
3. [Reglas de negocio](#3-reglas-de-negocio)
4. [Datos de prueba](#4-datos-de-prueba)
5. [Escenarios de prueba](#5-escenarios-de-prueba)
   - [Escenario 1: Creación con valores por defecto](#escenario-1-creación-con-valores-por-defecto)
   - [Escenario 2: Validación de importe positivo](#escenario-2-validación-de-importe-positivo)
   - [Escenario 3: Límite de gasto de hotel](#escenario-3-límite-de-gasto-de-hotel)
   - [Escenario 4: Total calculado automáticamente](#escenario-4-total-calculado-automáticamente)
   - [Escenario 5: Enviar con precondiciones](#escenario-5-enviar-con-precondiciones)
   - [Escenario 6: Bloqueo por estado](#escenario-6-bloqueo-por-estado)
   - [Escenario 7: Aprobar y rechazar](#escenario-7-aprobar-y-rechazar)
   - [Escenario 8: Semáforos de estado](#escenario-8-semáforos-de-estado)
6. [Fragmento clave del BDEF](#6-fragmento-clave-del-bdef)
7. [Conceptos RAP cubiertos](#7-conceptos-rap-cubiertos)
8. [Limitaciones conocidas y próximos pasos](#8-limitaciones-conocidas-y-próximos-pasos)

---

## 1. Resumen

Aplicación para gestionar **informes de gastos** con sus **posiciones** y **adjuntos**, desarrollada con el modelo de programación RAP. El objetivo es demostrar un ciclo de vida completo con reglas de negocio reales: validaciones, cálculos automáticos, acciones de flujo, bloqueo por estado y semáforos visuales.

## 2. Modelo de datos

```
Informe (Header, root)
 └── Gasto (Item)
      └── Adjunto (Attachment)
```

- Composición de tres niveles, con borrado en cascada.

- Estados del informe: `OPEN → SENT → APPROVED / REJECTED` (REJECTED es estado final).

| Estado | Editar / Borrar | Enviar | Aprobar | Rechazar |
|---|---|---|---|---|
| OPEN | Sí | Sí | No | No |
| SENT | No | No | Sí | Sí |
| APPROVED | No | No | No | No |
| REJECTED | No | No | No | No |

## 3. Reglas de negocio

| Regla | Dónde se aplica |
|---|---|
| El importe de un gasto debe ser mayor que 0 | Validación en el item |
| Un gasto de hotel no puede superar 150 € | Validación en el item |
| El total del informe es la suma de sus gastos | Determination |
| Para enviar: al menos un gasto y recibo en cada gasto de más de 50 € | Acción `send` |
| Rechazar exige un motivo de al menos 10 caracteres | Acción `reject` |
| Moneda siempre EUR | Determination + campo de solo lectura |

## 4. Datos de prueba

Se reutilizan los cuatro informes que ya existían y se crea uno nuevo para los escenarios que parten de cero.

| Informe | Estado inicial | Uso |
|---|---|---|
| **1** | APPROVED | Muestra el estado final aprobado y el bloqueo (escenarios 6 y 8) |
| **2** | SENT | Escenarios 6 y 7 (bloqueo, rechazo con motivo corto y válido) |
| **3** | OPEN | Se deja como está, de muestra en la lista (escenario 8) |
| **4** | REJECTED | Muestra el motivo de rechazo en la Object Page |
| **Nuevo (5)** | OPEN → SENT | Escenarios 1 a 5, y después aprobación en el 7 |


---|---|---|
| **A** | Escenarios 1 a 5 | OPEN |
| **B** | Escenarios 6 y 7 (aprobación) | APPROVED |
| **C** | Escenario 7 (rechazo) | REJECTED |

---

## 5. Escenarios de prueba

### Resumen de escenarios

| # | Escenario | Qué se comprueba | Mecanismo RAP | Informe | Estado |
|---|---|---|---|---|---|
| 1 | Creación con valores por defecto | ID, estado `OPEN` y moneda `EUR` asignados por el sistema | Determination + early numbering | Nuevo | ☐ |
| 2 | Validación de importe | Importe 0 o negativo no se guarda | Validation `on save` | Nuevo | ☐ |
| 3 | Límite de hotel | Hotel de más de 150 € devuelve error | Validation con regla de negocio | Nuevo | ☐ |
| 4 | Total automático | El total del informe es la suma de los gastos | Determination + side effect | Nuevo | ☐ |
| 5 | Enviar con precondiciones | Sin gastos y sin recibo falla; correcto pasa a `SENT` | Action `send` con lectura de varias entidades | Nuevo | ☐ |
| 6 | Bloqueo por estado | En `SENT` no se edita, borra ni crea; sí se navega | Feature control por instancia | 2 | ☐ |
| 7 | Aprobar y rechazar | Rechazo con motivo, aprobación, estados finales | Actions con parámetro (abstract entity) | 2 y nuevo | ☐ |
| 8 | Semáforos de estado | Colores según estado en la lista | Criticality en CDS + anotación UI | Todos | ☐ |

**Orden de ejecución recomendado para sacar las capturas:** 1 → 4 → 2 → 3 → 5 → 6 → 7a → 7b → 7c → 8.

---

### Escenario 1: Creación con valores por defecto

| | |
|---|---|
| **Objetivo** | Comprobar que el sistema asigna ID, estado y moneda sin intervención del usuario |
| **Precondición** | Ninguna |
| **Pasos** | 1. Pulsar *Crear*. 2. Rellenar solo cliente, fecha y motivo. 3. Guardar |
| **Resultado esperado** | Informe creado con ID asignado, estado `OPEN` y moneda `EUR` |
| **Resultado obtenido** | ☐ OK  ☐ KO |

Valores a Rellenar

![Creación del informe](../img/01-creacion.png)

Informe creado

![Creación del informe](../img/01-creacion_DISPLAY.png)

**Cómo se logra:** *early numbering* para el ID y una *determination* `on modify { create; }` que informa estado y moneda. Los campos se declaran `readonly` en el BDEF para que el usuario no pueda modificarlos.

---

### Escenario 2: Validación de importe positivo

| | |
|---|---|
| **Objetivo** | Impedir guardar gastos con importe 0 o negativo |
| **Precondición** | Informe nuevo (nº 5) en estado OPEN |
| **Pasos** | 1. Añadir un gasto con importe `0` (o `-5`). 2. Guardar |
| **Resultado esperado** | Mensaje de error, campo *Importe* resaltado en rojo, no se guarda |
| **Resultado obtenido** | ☐ OK  ☐ KO |

![Error de importe](../img/02-importe.png)

**Cómo se logra:** *validation* `on save` en el item. Marca la instancia en `failed` (impide el guardado) y publica el mensaje en `reported` con `%element-amount` para resaltar el campo.

---

### Escenario 3: Límite de gasto de hotel

| | |
|---|---|
| **Objetivo** | Aplicar una regla de negocio dependiente de dos campos |
| **Precondición** | Informe nuevo (nº 5) en estado OPEN |
| **Pasos** | 1. Añadir un gasto de tipo hotel de 200 €. 2. Guardar |
| **Resultado esperado** | Error indicando que se supera el límite de 150 € |
| **Resultado obtenido** | ☐ OK  ☐ KO |

![Límite de hotel](../img/03-hotel.png)

**Cómo se logra:** validación que lee `expense_type` y `amount`. Un *error* usa `failed` + `reported`; un *warning* usaría solo `reported`.

---

### Escenario 4: Total calculado automáticamente

| | |
|---|---|
| **Objetivo** | Ver que el total de la cabecera refleja la suma de los gastos |
| **Precondición** | Informe nuevo (nº 5) con gastos válidos |
| **Pasos** | 1. Añadir dos o tres gastos. 2. Observar el total de la cabecera |
| **Resultado esperado** | El total coincide con la suma y se actualiza sin recargar |
| **Resultado obtenido** | ☐ OK  ☐ KO |

![Total calculado](../img/04-total.png)

**Cómo se logra:** *determination* en el item que recalcula el total del header y *side effect* `field amount affects field _Header.total_amount` para refrescar la interfaz.

---

### Escenario 5: Enviar con precondiciones

| | |
|---|---|
| **Objetivo** | Comprobar que la acción valida varias entidades antes de cambiar de estado |
| **Precondición** | Informe (nº 3) en estado OPEN |

| Caso | Situación | Resultado esperado |
|---|---|---|
| 5a | Informe sin gastos | Error: el informe no tiene gastos |
| 5b | Gasto de 140 € sin adjunto | Error: 1 gasto de más de 50 € sin recibo |
| 5c | Gasto de 140 € con adjunto | El informe pasa a `SENT` |

**Resultado obtenido:** ☐ 5a OK  ☐ 5b OK  ☐ 5c OK

![Enviar sin gastos](../img/05a-enviar-sin-gastos.png)

![Enviar sin recibo](../img/05b-enviar-sin-recibo.png)

![Enviar correcto](../img/05c-enviar-ok.png)

**Cómo se logra:** acción `send` con `features : instance`. Lee los gastos con `READ ENTITIES ... BY \_Items` y sus adjuntos con `BY \_Attachments ... LINK`. Si alguna precondición falla, devuelve `failed` + `reported` y no modifica el estado.

> **Decisión de diseño:** el recibo se valida en el momento del envío, no al guardar el gasto, porque depende de dos entidades y es una precondición de la transición de estado.

---

### Escenario 6: Bloqueo por estado

| | |
|---|---|
| **Objetivo** | Demostrar que un informe enviado no se puede modificar, pero sí consultar |
| **Precondición** | Informe 2 en estado SENT |
| **Pasos** | 1. Abrir el informe. 2. Abrir un gasto. 3. Abrir un adjunto |
| **Resultado esperado** | Botones *Editar*, *Eliminar* y *Crear* deshabilitados en los tres niveles; la navegación sigue disponible |
| **Resultado obtenido** | ☐ OK  ☐ KO |

![Informe bloqueado](../img/06a-bloqueo-header.png)

![Gasto bloqueado](../img/06b-bloqueo-item.png)

**Cómo se logra:** `update ( features : instance )`, `delete ( features : instance )` y `create ( features : instance )` en la asociación. En `get_instance_features`, el item y el adjunto consultan el estado **del header** navegando con `BY \_Header`. Es un control de backend, no solo visual: una llamada por API también se rechaza.

---

### Escenario 7: Aprobar y rechazar

| | |
|---|---|
| **Objetivo** | Completar el ciclo de vida con acciones, una de ellas con parámetro |
| **Precondición** | Informe 2 (SENT) e informe nuevo (SENT tras el escenario 5c) |

| Caso | Pasos | Resultado esperado |
|---|---|---|
| 7a | Rechazar el informe 2 con motivo válido | Pasa a `REJECTED`, el motivo se muestra en la Object Page |
| 7b | Aprobar el informe nuevo | Pasa a `APPROVED` |

**Resultado obtenido:** ☐ 7a OK  ☐ 7b OK  ☐ 7c OK

![Diálogo de rechazo](../img/07b-rechazado.png)

![Diálogo de rechazo](../img/07b-rechazado_DISPLAY.png)

![Informe aprobado](../img/07c-aprobado.png)

**Cómo se logra:** acciones `approve` y `reject` habilitadas solo en SENT mediante feature control. `reject` recibe su parámetro a través de una *abstract entity* (`ZA_EXP_REJECT_PARAM`) y persiste el motivo en un campo propio de solo lectura.

---

### Escenario 8: Semáforos de estado

| | |
|---|---|
| **Objetivo** | Visualizar el estado de un vistazo en la lista |
| **Precondición** | Los cinco informes, en estados distintos |
| **Pasos** | Abrir el List Report |
| **Resultado esperado** | OPEN neutro, SENT amarillo, APPROVED verde, REJECTED rojo |
| **Resultado obtenido** | ☐ OK  ☐ KO |

![Semáforos en la lista](../img/08-semaforos.png)

**Cómo se logra:** campo calculado `StatusCriticality` en la vista CDS (`case` sobre el estado) y la anotación `criticality` en `@UI.lineItem` y `@UI.fieldGroup`.

---

## 6. Fragmento clave del BDEF

```abap
define behavior for ZI_EXP_HEADER alias Header
persistent table zexpense_header
lock master
etag master last_changed_at
early numbering
{
  field ( readonly ) report_id, header_status, total_amount, currency_code;

  determination setStatusDefault on modify { create; }

  action ( features : instance ) send    result [1] $self;
  action ( features : instance ) approve result [1] $self;
  action ( features : instance ) reject parameter ZA_EXP_REJECT_PARAM result [1] $self;

  create;
  update ( features : instance );
  delete ( features : instance );

  association _Items { create ( features : instance ); }
}
```

## 7. Conceptos RAP cubiertos

- Business object managed con composición de tres niveles
- Early numbering
- Determinations (valores por defecto y cálculo del total)
- Validations (`failed` y `reported`)
- Actions con y sin parámetros (abstract entity)
- Feature control por instancia en las tres entidades
- Side effects
- Criticality
- Value helps y asociaciones a objetos estándar

## 8. Limitaciones conocidas y próximos pasos

**Limitaciones**
- Sin `draft`: los datos se guardan al instante y no hay borrador.
- Autorización global: cualquier usuario con el rol puede crear, enviar y aprobar.
- Límites de importe fijos en el código.
- Mensajes con texto directo, sin clase de mensajes.
- Validación de tipo de fichero (mime) pendiente.

**Próximos pasos**
1. Web API OData sobre el mismo BO
2. Tablas de customizing para los límites de gasto
3. Draft
4. Autorizaciones por instancia
5. Pruebas unitarias con ABAP Unit