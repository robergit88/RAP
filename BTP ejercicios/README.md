# Guía de diseño de apps ABAP RAP

## Orden de creación


![building_04](../../RAP/img/building_04.png)


Buenas prácticas paso a paso, de la tabla al servicio OData.

**Leyenda:** 

- 🟢 Obligatorio
- 🟡 Opcional (solo con escritura o lógica) 
- 🔵 Según necesidad

**Criterio general:** comportamiento y estructura abajo, semántica en la capa C, aspecto en la metadata extension.

## Visión general

### App transaccional

| # | Paso | Estado | Regla en una frase |
|---|---|---|---|
| 1 | Tabla | 🟢 | Solo almacena datos, sin integridad referencial |
| 2 | CDS R + DCL | 🟢 | Modelo de negocio y navegación, sin presentación |
| 3 | CDS C (projection) | 🟢 | Renombra, enriquece con semántica y redirige |
| 4 | BDEF R | 🟡 | Qué puede hacer el BO y qué lógica ejecuta |
| 5 | BDEF projection | 🟡 | Qué comportamiento se expone |
| 6 | Metadata extension | 🟢 | Cómo se dibuja, solo @UI |
| 7 | Service definition y binding | 🟢 | Publicación OData |

### App de solo lectura

1. Tabla 🟢
2. CDS R + DCL 🟢
3. CDS C 🟢
4. Metadata extension 🟢
5. Service definition y binding 🟢

Sin BDEF no hay create, update, delete, draft ni acciones. En solo lectura, la CDS C no lleva `provider contract transactional_query` y la capa R puede ser `define view entity` (el `root` solo es necesario con BDEF).

### Regla de decisión rápida

- ¿La app solo lee y muestra? Salta los pasos 🟡.
- ¿Hay escritura? Añade BDEF R, BDEF projection y los campos administrativos.
- ¿Hay lógica de negocio? Dentro del BDEF R añade solo lo 🔵 que necesites (acción, validación, determinación).

## Paso 1: Tabla de base de datos 🟢

<span style="color:gold">**Regla:** solo almacena datos. Sin integridad referencial, pero con la semántica técnica de importes y cantidades.</span>


- 🟢 Campo `client` como primera clave (`abap.clnt`)
- 🟢 Campos de negocio, **tabla rasa**: sin foreign keys ni check tables. La integridad la garantiza el BO.
- 🟢 Importes y cantidades siempre con su moneda o unidad en la propia tabla
- 🟢 Solo tipos liberados (ABAP Cloud)
- 🟡 Clave técnica UUID (`sysuuid_x16`): solo con BDEF managed
- 🟡 Campos administrativos (`created_by`, `created_at`, `last_changed_by`, `last_changed_at`, `local_last_changed_at`): solo con escritura. El último sirve de ETag.
- 🟡 Tabla draft: no se crea a mano, se genera desde el BDEF con quick fix
- 🔵 Tabla de textos con clave de idioma, para descripciones traducibles
- 🔵 Estados como `abap.char(1)` con constantes en el BO

```abap
@EndUserText.label : 'Booking'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zbooking {
  key client            : abap.clnt not null;
  key booking_uuid      : sysuuid_x16 not null;
  booking_id            : abap.numc(8);
  customer_id           : abap.char(10);
  status                : abap.char(1);
  @Semantics.amount.currencyCode : 'zbooking.currency_code'
  total_price           : abap.curr(15,2);
  currency_code         : abap.cuky;
  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  last_changed_by       : abp_lastchange_user;
  last_changed_at       : abp_lastchange_tstmpl;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;
}
```

## Paso 2: CDS interfaz, capa R 🟢

<span style="color:gold">**Regla:** define el modelo de negocio. Estructura, navegación y anotaciones que cambian el comportamiento del runtime. Nada de presentación. Es la capa de la que depende el BDEF.</span>

**Qué va aquí**

- 🟢 Nombres técnicos tal cual vienen de la tabla, sin alias ni PascalCase (`booking_uuid`, no `BookingUUID`). Así `mapping corresponding` y la tabla draft funcionan sin mapeos manuales.
- 🟢 `@AccessControl.authorizationCheck` con su DCL (o `#NOT_REQUIRED` justificado)
- 🟢 `@Semantics.amount.currencyCode` y `@Semantics.quantity.unitOfMeasure`
- 🟢 Asociaciones de negocio entre entidades propias (reserva → cliente, posición → producto), con cardinalidad explícita y expuestas en el select list con `_` delante. Al ser tabla rasa, la relación solo existe aquí.
- 🟡 `root`, `composition of` en el padre y `association to parent` en el hijo (solo con BDEF o estructura padre-hijo)
- 🟡 `@Semantics` de campos administrativos (`user.createdBy`, `systemDateTime.createdAt`, `user.lastChangedBy`, `systemDateTime.lastChangedAt`, `systemDateTime.localInstanceLastChangedAt`): solo con BDEF

**Qué NO va aquí (se lleva a la capa C o a la metadata)**

- Alias y renombrado
- `@UI`, `@EndUserText`, `@ObjectModel.text.*`
- `@Consumption.valueHelpDefinition` y vistas de value help
- Asociaciones que solo sirven para textos o value helps (moneda, descripción de estado)
- Cálculos y lógica de presentación

**Criterio:** ¿cambia cómo se comporta el BO o cómo se navega por él? Capa R. ¿Cambia cómo se ve o cómo se ayuda a rellenar? Capa C.

```abap
@AccessControl.authorizationCheck: #CHECK
define root view entity ZR_Booking
  as select from zbooking
  composition [0..*] of ZR_BookingItem as _Item
  association [0..1] to ZR_Customer    as _Customer
    on $projection.customer_id = _Customer.customer_id
{
  key booking_uuid,
      booking_id,
      customer_id,
      status,
      @Semantics.amount.currencyCode: 'currency_code'
      total_price,
      currency_code,
      @Semantics.user.createdBy: true
      created_by,
      @Semantics.systemDateTime.createdAt: true
      created_at,
      @Semantics.user.lastChangedBy: true
      last_changed_by,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at,
      _Item,
      _Customer
}
```

**Hijo:**

```abap
@AccessControl.authorizationCheck: #CHECK
define view entity ZR_BookingItem
  as select from zbooking_item
  association to parent ZR_Booking as _Booking
    on $projection.booking_uuid = _Booking.booking_uuid
  association [0..1] to ZR_Product as _Product
    on $projection.product_id = _Product.product_id
{
  key item_uuid,
      booking_uuid,
      product_id,
      @Semantics.quantity.unitOfMeasure: 'unit'
      quantity,
      unit,
      _Booking,
      _Product
}
```

**Checklist**

- [ ] Una vista por tabla, 1:1
- [ ] Nombres idénticos a la tabla
- [ ] Clave técnica (UUID) como `key`
- [ ] Composiciones y `association to parent` definidas
- [ ] Asociaciones de negocio con cardinalidad y expuestas con `_`
- [ ] Anotaciones solo de runtime
- [ ] DCL creado o `#NOT_REQUIRED` justificado

## Paso 3: CDS consumption, capa C 🟢

<span style="color:gold">**Regla:** renombra, enriquece con semántica y redirige. No calcula ni agrega.</span>

**Qué va aquí**

- 🟢 Alias en PascalCase
- 🟢 `@Metadata.allowExtensions: true`
- 🟢 Asociaciones redirigidas (`redirected to composition child`, `redirected to`)
- 🟢 `@EndUserText.label`
- 🟢 Anotaciones de moneda y cantidad con los alias nuevos
- 🟡 `provider contract transactional_query`: solo con BDEF
- 🔵 Textos de datos: `@ObjectModel.text.element` en el código y `@Semantics.text` en el texto
- 🔵 Value helps: `@Consumption.valueHelpDefinition`, apuntando a vistas `_VH` propias
- 🔵 Comportamiento de filtros: `@Consumption.filter` (`selectionType`, `multipleSelections`, `mandatory`, `defaultValue`)
- 🔵 Búsqueda: `@Search.searchable`, `@Search.defaultSearchElement`, `@Search.fuzzinessThreshold`

**Qué NO va aquí**

- `@UI` (incluido `@UI.selectionField`): va a la metadata extension
- Agregaciones, cálculos y joins: una projection (`as projection on`) no admite `group by` ni joins; se hacen en vistas propias (`define view entity ... as select from`), separadas de la consumption del BO
- Lógica de negocio: va en el BDEF

### Qué significa texto en esta capa

| Tipo | Ejemplo | Dónde |
|---|---|---|
| Descripción de un código | Juan Pérez para C0001 | Capa C (`@ObjectModel.text`, `@Semantics.text`) |
| Etiqueta del campo | Cliente | Capa C (`@EndUserText.label`) |
| Títulos y rótulos de pantalla | Datos generales | Metadata extension (`@UI.*.label`) |

La anotación del **código** apunta al **texto**; la del **texto** solo lo marca como tal. Si el texto viene de una tabla de textos por idioma, la asociación se define con `@ObjectModel.text.association`.

### Filtros: qué va en C y qué en la metadata

- ¿Define **cómo se comporta** el filtro (tipo, obligatoriedad, ayuda de búsqueda)? Capa C.
- ¿Define **si aparece** en la barra y en qué orden? Metadata extension (`@UI.selectionField`).

```abap
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Booking - Consumption'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_Booking
  provider contract transactional_query
  as projection on ZR_Booking
{
  key booking_uuid as BookingUUID,

      @Search.defaultSearchElement: true
      booking_id   as BookingID,

      @ObjectModel.text.element: ['CustomerName']
      @Consumption.filter: { selectionType: #RANGE, multipleSelections: true }
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_Customer_VH', element: 'CustomerID' } }]
      customer_id  as CustomerID,

      @Semantics.text: true
      _Customer.name as CustomerName,

      status       as Status,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      @Consumption.filter.selectionType: #INTERVAL
      total_price  as TotalPrice,

      @Consumption.valueHelpDefinition: [{
        entity: { name: 'I_Currency', element: 'Currency' } }]
      currency_code as CurrencyCode,

      local_last_changed_at as LocalLastChangedAt,

      _Item     : redirected to composition child ZC_BookingItem,
      _Customer : redirected to ZC_Customer
}
```

**Checklist**

- [ ] Una projection por servicio o app
- [ ] Alias en PascalCase
- [ ] Todas las asociaciones redirigidas a su proyección
- [ ] Value helps apuntando a vistas `_VH` propias
- [ ] Textos con su campo `@Semantics.text`
- [ ] Moneda y cantidad con el alias nuevo
- [ ] Sin `@UI`

## Paso 4: BDEF R 🟡

<span style="color:gold">**Regla:** define qué puede hacer el BO y qué lógica ejecuta. Aquí nacen las acciones, validaciones y determinaciones; la UI solo enlaza las acciones.</span>

- 🟢 (dentro del paso) Cabecera: `managed`, `strict ( 2 )`, `persistent table`, `lock master`, `authorization master`, `etag master`
- 🟡 `create`, `update`, `delete`: solo las operaciones que se permitan
- 🟡 `with draft` y `draft table` (la tabla se genera con quick fix)
- 🔵 Acciones, validaciones, determinaciones y feature control: cada pieza se declara en el BDEF y se implementa en la clase

| Pieza | Cuándo se ejecuta | Para qué |
|---|---|---|
| Determinación | `on modify` o `on save` | Rellenar campos (estado inicial, totales) |
| Validación | `on save` | Comprobar datos y rechazar el guardado |
| Acción | A petición del usuario | Operación de negocio (aprobar) |
| Feature control | Al leer | Habilitar o deshabilitar botones y campos |

<span style="color:gold">**Regla de oro:** las determinaciones rellenan, las validaciones comprueban. Nunca mezclar.</span>

**BDEF R:**

```abap
managed implementation in class zbp_r_booking unique;
strict ( 2 );
with draft;

define behavior for ZR_Booking alias Booking
persistent table zbooking
draft table zbooking_d
lock master total etag local_last_changed_at
authorization master ( instance )
etag master local_last_changed_at
{
  create;
  update;
  delete;

  field ( numbering : managed, readonly ) booking_uuid;
  field ( readonly ) status, created_by, created_at,
                     last_changed_by, last_changed_at, local_last_changed_at;

  determination setInitialStatus on modify { create; }
  validation validateCustomer on save { create; field customer_id; }

  action ( features : instance ) approve result [1] $self;

  mapping for zbooking corresponding;
  association _Item { create; with draft; }
}
```

**Clase de implementación:**

```abap
CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~setInitialStatus.
    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateCustomer.
    METHODS approve FOR MODIFY
      IMPORTING keys FOR ACTION Booking~approve RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Booking RESULT result.
ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.
  METHOD setInitialStatus.
    MODIFY ENTITIES OF zr_booking IN LOCAL MODE
      ENTITY Booking
        UPDATE FIELDS ( status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky status = 'N' ) ).
  ENDMETHOD.

  METHOD validateCustomer.
    READ ENTITIES OF zr_booking IN LOCAL MODE
      ENTITY Booking FIELDS ( customer_id ) WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    LOOP AT bookings INTO DATA(b) WHERE customer_id IS INITIAL.
      APPEND VALUE #( %tky = b-%tky ) TO failed-booking.
      APPEND VALUE #( %tky = b-%tky
                      %element-customer_id = if_abap_behv=>mk-on
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text = 'El cliente es obligatorio' ) )
        TO reported-booking.
    ENDLOOP.
  ENDMETHOD.

  METHOD approve.
    MODIFY ENTITIES OF zr_booking IN LOCAL MODE
      ENTITY Booking
        UPDATE FIELDS ( status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky status = 'A' ) ).

    READ ENTITIES OF zr_booking IN LOCAL MODE
      ENTITY Booking ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    result = VALUE #( FOR b IN bookings ( %tky = b-%tky %param = b ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zr_booking IN LOCAL MODE
      ENTITY Booking FIELDS ( status ) WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    result = VALUE #( FOR b IN bookings
      ( %tky = b-%tky
        %action-approve = COND #( WHEN b-status = 'A'
                                  THEN if_abap_behv=>fc-o-disabled
                                  ELSE if_abap_behv=>fc-o-enabled ) ) ).
  ENDMETHOD.
ENDCLASS.
```

**Detalles clave**

- `failed` cancela el guardado; `reported` muestra el mensaje y marca el campo con `%element`.
- Las validaciones se ejecutan en `on save`, así que no bloquean al usuario mientras escribe en borrador.
- `IN LOCAL MODE` modifica dentro del BO sin pasar por autorizaciones ni features, y evita bucles. Por eso la determinación puede escribir campos `readonly`.
- `features : instance` más `get_instance_features` habilitan o deshabilitan el botón según el estado de cada fila.

**Checklist**

- [ ] Cabecera completa
- [ ] Solo las operaciones necesarias
- [ ] Cada pieza declarada tiene su método con la signatura exacta
- [ ] Campos de estado y administrativos en `readonly`
- [ ] Determinaciones solo rellenan; validaciones solo comprueban

## Paso 5: BDEF projection 🟡

<span style="color:gold">**Regla:** expone solo la parte del comportamiento que este servicio necesita.</span>

- 🟢 (dentro del paso) `projection;` y `strict ( 2 )`
- 🟡 `use create / update / delete`: solo lo que se exponga (puede ser menos que el BDEF R)
- 🟡 `use draft`: solo si el BDEF R tiene `with draft`
- 🔵 `use action`: una por cada acción a exponer
- 🔵 `use association _Item { create; with draft; }` para los hijos

```abap
projection;
strict ( 2 );
use draft;

define behavior for ZC_Booking alias Booking
{
  use create;
  use update;
  use delete;
  use action approve;
  use association _Item { create; with draft; }
}
```

Lo que no se declara con `use`, no se expone. Así un mismo BO sirve a una app que solo lee y a otra que aprueba.

## Paso 6: Metadata extension 🟢

<span style="color:gold">**Regla:** define cómo se dibuja la pantalla. Solo `@UI`.</span>

- 🟢 `@UI.headerInfo`, `@UI.facet`, `@UI.lineItem`, `@UI.identification`
- 🔵 `@UI.selectionField`: campos de la barra de filtros
- 🔵 `@UI.textArrangement`: orden código/texto (`#TEXT_FIRST`, etc.)
- 🔵 `#FOR_ACTION`: solo para acciones con botón
- 🔵 `@UI` en la abstract entity si una acción tiene parámetros

```abap
@Metadata.layer: #CUSTOMER
annotate entity ZC_Booking with
{
  @UI.facet: [{ id: 'General', purpose: #STANDARD,
                type: #IDENTIFICATION_REFERENCE,
                label: 'Datos generales', position: 10 }]

  @UI.lineItem: [
    { position: 10 },
    { type: #FOR_ACTION, dataAction: 'approve', label: 'Aprobar' } ]
  @UI.identification: [
    { position: 10 },
    { type: #FOR_ACTION, dataAction: 'approve', label: 'Aprobar' } ]
  BookingID;

  @UI.lineItem: [{ position: 20 }]
  @UI.selectionField: [{ position: 10 }]
  @UI.textArrangement: #TEXT_FIRST
  CustomerID;

  @UI.lineItem: [{ position: 30 }]
  TotalPrice;
}
```

### Qué necesita enlace en la UI y qué no

| Elemento del BDEF | ¿Algo en la metadata? | Cómo lo refleja la UI |
|---|---|---|
| Validación | No | El mensaje sale solo y marca el campo |
| Determinación | No | El campo aparece ya rellenado |
| `readonly` / `mandatory` | No | No editable o con asterisco, automáticamente |
| `create`, `update`, `delete` | No | Los botones salen solos |
| Draft | No | Guardar, Descartar e indicador de borrador |
| Features | No | El botón se habilita o deshabilita solo |
| **Acción** | **Sí** (`#FOR_ACTION`) | Es lo único que necesita botón declarado |
| Acción con parámetros | **Sí** | El diálogo se dibuja con los `@UI` de la abstract entity |

### La cadena completa de un botón

| # | Pieza | Dónde | Qué hace |
|---|---|---|---|
| 1 | Declarar la acción | BDEF R (paso 4) | `action approve result [1] $self;` |
| 2 | Implementar la lógica | Clase `ZBP_R_BOOKING` (paso 4) | Método `approve` |
| 3 | Exponerla | BDEF projection (paso 5) | `use action approve;` |
| 4 | Dibujar el botón | Metadata extension (este paso) | `#FOR_ACTION, dataAction: 'approve'` |

El nombre `approve` debe ser idéntico en las 4 piezas. Como el BDEF ya está cerrado cuando se llega a este paso, el botón se dibuja una sola vez. El `@UI.lineItem` pone el botón sobre la tabla y el `@UI.identification` en la cabecera de la Object Page; se puede declarar sobre cualquier campo, el botón no pertenece al campo.

**Errores típicos**

- Botón no aparece: falta `use action` en la projection, o `dataAction` no coincide.
- Botón gris siempre: `get_instance_features` devuelve `disabled` o no está implementada.
- Error de activación en la clase: el nombre del método no coincide con la acción o falta la signatura `FOR ACTION Booking~approve`.
- Acción sin efecto en pantalla: falta `result [1] $self`.

**Checklist**

- [ ] Solo anotaciones `@UI`
- [ ] Una metadata extension por projection
- [ ] Todo campo de `lineItem` tiene `position`
- [ ] Facetas definidas (sin ellas la Object Page sale vacía)
- [ ] `@UI.selectionField` solo en los campos que filtran de verdad
- [ ] Todas las acciones con botón tienen su `#FOR_ACTION`

## Paso 7: Service definition y binding 🟢

<span style="color:gold">**Regla:** publica la projection como servicio OData.</span>

- 🟢 Service definition: qué entidades se exponen
- 🟢 Service binding: protocolo (OData V4 - UI) y publicación
- 🔵 Binding OData V2 si el cliente lo exige
- 🔵 `@EndUserText.label` en la definición
- 🔵 `as` para alias en el servicio

```abap
@EndUserText.label: 'Booking Service'
define service ZUI_BOOKING {
  expose ZC_Booking     as Booking;
  expose ZC_BookingItem as BookingItem;
  expose ZC_Customer    as Customer;
  expose ZI_Customer_VH as CustomerVH;
  expose I_Currency     as Currency;
}
```

**Detalles**

- Hay que exponer también las entidades a las que apuntan asociaciones y value helps; si no, la navegación y las ayudas de búsqueda fallan.
- En el service binding: tipo OData V4 - UI, nombre `ZUI_BOOKING_O4`, pulsar Publish y luego Preview sobre la entidad raíz.
- Para una API sin UI, el tipo es OData V4 - Web API y no hace falta metadata extension.

**Checklist**

- [ ] Projection BDEF con `use` solo de lo necesario
- [ ] `use draft` coherente con el BDEF R
- [ ] Service definition expone raíz, hijos y entidades de value help
- [ ] Binding publicado y probado con Preview

## Resumen: qué va en cada capa

| Capa | Contiene | No contiene |
|---|---|---|
| Tabla | Datos, moneda y unidad de importes y cantidades | Foreign keys |
| CDS R | Nombres de tabla, asociaciones, composiciones, `@Semantics` de runtime, `@AccessControl` | Alias, `@UI`, textos, value helps |
| CDS C | Alias, textos, value helps, filtros, búsqueda, redirecciones | `@UI`, agregaciones, lógica de negocio |
| BDEF R | Operaciones, draft, acciones, validaciones, determinaciones | Presentación |
| BDEF projection | `use` de lo que se expone | Lógica |
| Metadata extension | Solo `@UI`, enlace de acciones con `#FOR_ACTION` | Semántica y lógica |
| Service | Entidades expuestas y protocolo | Todo lo anterior |