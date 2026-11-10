# ZEXPENSE2_API: API Web Cloud (OData V4) sobre ABAP Environment

Documentación de cómo se construyó la API Z de informes de gastos y de cada prueba realizada desde Postman.

- **Escenario de pruebas:** SAP BTP ABAP Environment (cuenta Trial, plan `shared`) + Postman.
- **Última actualización:** 2026-11-10.
- **Estado:** cabecera, posición y adjunto (con binario) probados por la API. Borrados, acciones y deep insert pendientes.

## Índice

1. [Resumen](#1-resumen)
2. [Escenario de pruebas](#2-escenario-de-pruebas-abap-environment)
3. [Arquitectura y construcción de la API](#3-arquitectura-y-construcción-de-la-api)
4. [Conectar Postman con ABAP Environment (trial)](#4-conectar-postman-con-abap-environment-trial)
5. [Convenciones de las pruebas](#5-convenciones-de-las-pruebas)
6. [Fichas de prueba: servicio V2 de la app (referencia)](#6-fichas-de-prueba-servicio-v2-de-la-app-referencia)
7. [Fichas de prueba: API V4](#7-fichas-de-prueba-api-v4)
8. [Cómo leer el `$metadata` de la API](#8-cómo-leer-el-metadata-de-la-api)
9. [Reglas de negocio que hereda la API](#9-reglas-de-negocio-que-hereda-la-api)
10. [Errores encontrados y soluciones](#10-errores-encontrados-y-soluciones)
11. [Pendientes e ideas](#11-pendientes-e-ideas)

---

## 1. Resumen

Existe una app RAP (List Report + Object Page) de informes de gastos en el paquete `ZEXPENSE2`: Carpeta de gastos (root) → Posición (child) → Adjunto (grandchild). El objetivo es ofrecer **el mismo comportamiento como API Web Cloud**, sin duplicar tablas ni lógica.

La solución es una **segunda capa de consumo** sobre el mismo business object:

```
Tablas Z ── CDS de interfaz ZI_* ── BDEF managed (lógica, clases ZBP_*)   ← compartido
                  ├── ZC_EXP_*     → app Fiori (V2, UI)                   ← ya existía
                  └── ZC_EXPAPI_*  → API Web (V4)                         ← nuevo (ZEXPENSE2_API)
```

## 2. Escenario de pruebas (ABAP Environment)

| Elemento | Valor |
|---|---|
| Plataforma | SAP BTP, cuenta Trial, subaccount `trial`, región us10 |
| Servicio | ABAP environment, plan `shared` (instancia `default_abap-trial`) |
| Sistema / mandante | `TRL` / `100` |
| IDE | Eclipse con ABAP Development Tools (proyecto ABAP Cloud) |
| Cliente de pruebas | Postman |
| Paquete de la app | `ZEXPENSE2` |
| Paquete de la API | `ZEXPENSE2_API` |
| Instancia | Se detiene cada noche: arrancarla antes de probar |

**Hosts.** El mismo sistema tiene dos puertas:

| Host | Uso |
|---|---|
| `6449ad14-b137-4a27-8017-6421c2c4f0b0.abap-web.us10.hana.ondemand.com` | Navegador y Launchpad (login SSO). No sirve para Postman. |
| `6449ad14-b137-4a27-8017-6421c2c4f0b0.abap.us10.hana.ondemand.com` | **Postman** y cualquier cliente externo (token OAuth). |

## 3. Arquitectura y construcción de la API

### 3.1 Objetos reutilizados (no se copian)

- Tablas: `ZEXPENSE_HEADER`, `ZEXPENSE_ITEM`, `ZITEM_ATTACHMENT` y catálogos `ZEXPENSE_TYPE`, `ZHEADER_STATUS`, `ZITEM_STATUS`, `ZMIME_TYPE`.
- CDS de interfaz: `ZI_EXP_HEADER`, `ZI_EXP_ITEMM`, `ZI_EXP_ATTACH`, value helps `ZVH_*`, `ZA_EXP_REJECT_PARAM`.
- Behavior definition managed de `ZI_EXP_HEADER` (sin draft, numeración temprana) y clases `ZBP_ZI_EXP_HEADER`, `ZBP_ZI_EXP_ITEMM`, `ZBP_ZI_EXP_ATTACH`.

### 3.2 Objetos nuevos (paquete `ZEXPENSE2_API`)

| Objeto | Nombre | Descripción |
|---|---|---|
| CDS de consumo (root) | `ZC_EXPAPI_HEADER` | Expense Report - API Projection |
| CDS de consumo (hijo) | `ZC_EXPAPI_ITEM` | Expense Item - API Projection |
| CDS de consumo (nieto) | `ZC_EXPAPI_ATTACH` | Expense Attachment - API Projection |
| Behavior projection | `ZC_EXPAPI_HEADER` | Behavior Projection - Expense API |
| Service definition | `ZSD_EXPENSES_API` | Expense API - Service Definition |
| Service binding | `ZAPI_EXPENSES_O4` | Expense API - Web API (OData V4 - Web API) |

Alias expuestos en la service definition: `ExpenseReport`, `ExpenseItem`, `ExpenseAttachment`.

### 3.3 Pasos seguidos

1. **Paquete** `ZEXPENSE2_API`, con el mismo software component y transport layer que `ZEXPENSE2`.
2. **Tres CDS de consumo** nuevas, proyectando `ZI_EXP_HEADER`, `ZI_EXP_ITEMM` y `ZI_EXP_ATTACH`. Se partió de las `ZC_EXP_*` de la app, y se ajustó:
   - Las asociaciones se redirigen a las **proyecciones nuevas**, nunca a las `ZC_EXP_*` (si no, la API quedaría atada a la capa de la UI).
   - El provider contract (`transactional_query`) va solo en la proyección raíz.
   - En el adjunto se conserva la anotación de objeto grande (`@Semantics.largeObject`), que genera la propiedad binaria `AttachmentContent`.
   - Sin metadata extensions: no hay UI.
3. **Behavior projection** `ZC_EXPAPI_HEADER`, con la misma oferta que la app:

   | Entidad | Operaciones | Acciones | Crear hijos |
   |---|---|---|---|
   | `ZC_EXPAPI_HEADER` | crear, modificar, borrar | `send`, `approve`, `reject` | ítems |
   | `ZC_EXPAPI_ITEM` | modificar, borrar | ninguna | adjuntos |
   | `ZC_EXPAPI_ATTACH` | modificar, borrar | ninguna | ninguno |

   Cada hijo expone además su asociación al padre. Rol: `Implementation Type = Projection` y la raíz es la **vista de proyección nueva**, no `ZI_EXP_HEADER`.
4. **Service definition** `ZSD_EXPENSES_API` con las tres entidades.
5. **Service binding** `ZAPI_EXPENSES_O4`, tipo *OData V4 - Web API*, y **Publish**.

### 3.4 Por qué se hizo así

- **Contrato independiente de la UI.** App y API evolucionan por separado: cambiar un campo para una pantalla no rompe a un consumidor de la API.
- **Behavior de proyección propio.** Está atado a una vista de proyección concreta. Una proyección sin él es de solo lectura. No duplica lógica: solo decide qué se ofrece.
- **¿Dónde está el enlace con el BDEF de interfaz?** No está escrito en el BDEF de proyección. Lo hace la vista (`as projection on ZI_EXP_HEADER`) y el sistema comprueba cada `use` contra el BO base al activar. Se comprueba con Ctrl+clic.
- **Las metadata extensions** de la app están ligadas a las vistas `ZC_EXP_*`; una proyección con otro nombre parte limpia, sin anotaciones de UI.
- **El protocolo se elige en el binding**, no en las vistas ni en el behavior. Pasar a V2 sería otro binding sobre la misma definición.
- **V4** es la opción recomendada por SAP para servicios transaccionales nuevos. Convención de nombre de binding Web API: prefijo `API_`, sufijo `_O4`.

## 4. Conectar Postman con ABAP Environment (trial)

> Esta fue la parte más costosa del proyecto. Se documenta con detalle.

### 4.1 Lo que NO funciona en un trial

- **Basic Auth con Communication User.** Requiere Communication Management (Communication Systems, Arrangements, Users), cuyas apps **no están disponibles en el ABAP Environment trial compartido** (limitación de SAP, ver KBA 3725960). El Communication Scenario `ZEXPENSES_SCEN` que se creó en ADT no sirve para este fin.
- **Role collections de BTP.** Los roles de Communication Management no se gestionan en el cockpit y los role collections del subaccount (Build Apps, Build Code, BAS, etc.) no tienen relación.
- **Grant type `Client Credentials`.** Genera un token sin usuario de negocio que el ABAP rechaza (401 con página de login en HTML).

### 4.2 Lo que SÍ funciona: OAuth 2.0 Authorization Code con la Service Key

**Datos de la Service Key** (cockpit → Instances and Subscriptions → instancia ABAP → Service Keys). Del bloque `uaa`: `url`, `clientid`, `clientsecret`. La `url` de la raíz del JSON es la del sistema ABAP y es otra cosa.

> El `clientsecret` es un secreto: no se publica ni se comparte. Cuando termine el desarrollo conviene borrar la key y crear otra.

**Entorno de Postman** (pestaña *Environments*): dos variables, `sap_client_id` y `sap_client_secret`, con los valores del bloque `uaa`. Se usan con llaves dobles, `{{sap_client_id}}`. Sin llaves, Postman envía el texto literal y SAP responde *No client with requested id*. El entorno debe estar **seleccionado** (selector arriba a la derecha).

**Configuración OAuth 2.0** (pestaña *Authorization* de la colección o del request):

| Campo | Valor |
|---|---|
| Auth type | OAuth 2.0 |
| Add authorization data to | Request Headers |
| Grant type | **Authorization Code** |
| Callback URL | `http://localhost:8080` |
| Auth URL | `<uaa.url>/oauth/authorize` |
| Access Token URL | `<uaa.url>/oauth/token` |
| Client ID | `{{sap_client_id}}` |
| Client Secret | `{{sap_client_secret}}` |
| Scope | vacío |
| Client Authentication | Send as Basic Auth header |

Pasos:

1. **Get New Access Token** → se abre el login → *Default Identity Provider* → entrar con el usuario BTP.
2. Aparece *Authentication complete* → **Use Token**. Nombre del token usado: `TokenForAllAbapADT`.
3. En cada request, en *Authorization*, elegir ese token en el desplegable **Token**.

> **Importante:** al **duplicar** un request, el token **no** se hereda. Hay que seleccionarlo en el desplegable *Token* de cada request nuevo. Olvidarlo produce un 401 que parece de configuración.

El token caduca: ante un 401, generar uno nuevo y volver a seleccionarlo.

### 4.3 Token CSRF (obligatorio en escrituras)

Las llamadas `POST`, `PATCH`, `PUT` y `DELETE` necesitan `X-CSRF-Token`.

1. `GET` a cualquier URL del servicio con el header `X-CSRF-Token: Fetch`.
2. En la respuesta, copiar el valor del header `x-csrf-token`.
3. Usarlo en el header `X-CSRF-Token` de la escritura. Postman guarda además la cookie de sesión (`sap-XSRF_TRL_100`), a la que va ligado el token.
4. Si la escritura devuelve 403, repetir el paso 1.

## 5. Convenciones de las pruebas

**URLs base** (host `abap`, sin `-web`):

```
BASE_V2 = https://6449ad14-b137-4a27-8017-6421c2c4f0b0.abap.us10.hana.ondemand.com/sap/opu/odata/sap/ZUI_EXPENSES_O2
BASE_V4 = https://6449ad14-b137-4a27-8017-6421c2c4f0b0.abap.us10.hana.ondemand.com/sap/opu/odata4/sap/zapi_expenses_o4/srvd_a2x/sap/zsd_expenses_api/0001
```

**Claves de las entidades.** Los IDs devueltos por el servicio llevan **espacios a la izquierda**, que en la URL van como `%20`. Se usa siempre el valor **tal cual lo devuelve el servicio**.

| Entidad | Clave de ejemplo (informe 7, posición 1, adjunto 1) |
|---|---|
| `ExpenseReport` | `ExpenseReport('%20%20%20%20%20%20%20%207')` |
| `ExpenseItem` | `ExpenseItem(ReportId='%20%20%20%20%20%20%20%207',ItemId='%20%20%20%201')` |
| `ExpenseAttachment` | `ExpenseAttachment(ReportId='%20%20%20%20%20%20%20%207',ItemId='%20%20%20%201',AttachId='%20%20%20%201')` |

En V4 la clave compuesta va dentro de un solo paréntesis, con nombre de campo (`ReportId='...',ItemId='...'`). En V2 la sintaxis es distinta.

**Leyenda de requisitos en las fichas:**

- **Token**: OAuth 2.0 (`TokenForAllAbapADT`) seleccionado en el request.
- **CSRF**: `X-CSRF-Token` vigente (solo escrituras).
- **Estado**: estado que debe tener el informe para que la operación se acepte.

## 6. Fichas de prueba: servicio V2 de la app (referencia)

Servicio de la app, `ZUI_EXPENSES_O2` (OData V2 - UI). Se usó para validar la conectividad antes de construir la API.

### 6.1 Contar informes

| | |
|---|---|
| Entidad / operación | `ExpenseReport`, contar |
| Petición | `GET {BASE_V2}/ExpenseReport/$count` |
| Requisitos | Token |
| Resultado | `200`, devuelve `5` (los registros existentes) |
| Nota | En V2 no vale `$count=true` (es de V4). Alternativa: `?$inlinecount=allpages&$format=json`. |

### 6.2 Leer informes

| | |
|---|---|
| Entidad / operación | `ExpenseReport`, leer lista |
| Petición | `GET {BASE_V2}/ExpenseReport` |
| Requisitos | Token |
| Resultado | `200`, XML (Atom) por defecto. Añadir `?$format=json` para JSON. |
| Nota | Para reutilizar la clave de un registro, copiar el `uri` de `__metadata`. |

### 6.3 Obtener el token CSRF

| | |
|---|---|
| Petición | `GET {BASE_V2}/ExpenseReport` con header `X-CSRF-Token: Fetch` |
| Requisitos | Token |
| Resultado | `200`; el valor viene en el header `x-csrf-token` de la respuesta |

### 6.4 Modificar el motivo de un informe

| | |
|---|---|
| Entidad / operación | `ExpenseReport`, modificar (`PATCH`) |
| Petición | `PATCH {BASE_V2}/ExpenseReport('%20%20%20%20%20%20%20%206')` |
| Headers | Token, `X-CSRF-Token`, `Content-Type: application/json`, `Accept: application/json` |
| Estado | `OPEN` (el informe 6 se creó desde la app) |
| Body | `{ "Reason": "Salida Cultural equipo SAP - editado desde Postman" }` |
| Resultado | `204 No Content`. La app Fiori muestra el nuevo valor. |
| Nota | El informe 4 (`REJECTED`) no se podía editar en la UI: la API respeta la misma regla. `RejectReason` no es editable: solo lo escribe la acción `reject`. |

## 7. Fichas de prueba: API V4

Todas con `BASE_V4`. Requisitos comunes: **Token** seleccionado; escrituras con **CSRF**.

### 7.1 Contar informes

| | |
|---|---|
| Entidad / operación | `ExpenseReport`, contar |
| Petición | `GET {BASE_V4}/ExpenseReport/$count` |
| Requisitos | Token |
| Resultado | `200`, devuelve `6` (5 originales + 1 creado desde la app) |

### 7.2 Crear una cabecera

| | |
|---|---|
| Entidad / operación | `ExpenseReport`, crear (`POST`) |
| Petición | `POST {BASE_V4}/ExpenseReport` |
| Headers | Token, `X-CSRF-Token`, `Content-Type: application/json` |
| Campos | Solo los obligatorios (`FieldControl/Mandatory` en el metadata): `CustomerID`, `ReportDate`, `Reason`. El resto es `Core.Computed`. |

Body:

```json
{
  "CustomerID": "665",
  "ReportDate": "2026-11-10",
  "Reason": "Visita a cliente en Madrid - noviembre"
}
```

Resultado: la respuesta devuelve el informe creado con `ReportId: "        7"`, `HeaderStatus: "OPEN"`, `TotalAmount: 0.00`, `CurrencyCode: "EUR"`, `CreatedBy` y `LastChangedBy` con el usuario que llama, y `SAP__Messages` vacío.

Nota: `CurrencyCode` de la cabecera es solo lectura (lo asigna la determination `setStatusDefault`). Si se envía, el servicio lo rechaza o lo ignora. Apuntar el `ReportId` exacto para las pruebas siguientes.

### 7.3 Crear una posición dentro de una cabecera

| | |
|---|---|
| Entidad / operación | `ExpenseItem`, crear por la navegación `_Items` |
| Petición | `POST {BASE_V4}/ExpenseReport('%20%20%20%20%20%20%20%207')/_Items` |
| Headers | Token, `X-CSRF-Token`, `Content-Type: application/json` |
| Estado | `OPEN` (la creación de hijos se bloquea fuera de `OPEN`) |
| Metadata | `NavigationRestrictions` de `ExpenseReport`: `_Items` con `Insertable = true` |

Body (obligatorios: `ExpenseType`, `ExpenseDate`, `Amount`; `Vendor`, `ItemStatus` y `CurrencyCode` no admiten nulo):

```json
{
  "ExpenseType": "TAXI",
  "ItemStatus": "VALID",
  "Vendor": "Radio Taxi Madrid",
  "ExpenseDate": "2026-11-09",
  "Amount": 35.00,
  "CurrencyCode": "EUR"
}
```

Resultado: devuelve la posición con `ItemId: "    1"`. Comprobado en la app Fiori: el informe 7 muestra la posición y su `Total Amount` pasó de 0,00 a **35,00**, es decir, la determination `updateHeaderTotal` se ejecutó.

Valores válidos: `ExpenseType` = `HOTEL`, `TAXI`, `MEAL`, `KM` (catálogo `ZEXPENSE_TYPE`); `ItemStatus` = `VALID`, `PENDING`, `OBSERVED`. La API **no** expone una URL para consultarlos (ver pendientes).

### 7.4 Crear un adjunto (solo la entidad)

El flujo es en **dos tiempos**, como la app: primero la entidad, luego el fichero.

| | |
|---|---|
| Entidad / operación | `ExpenseAttachment`, crear por la navegación `_Attachments` |
| Petición | `POST {BASE_V4}/ExpenseItem(ReportId='%20%20%20%20%20%20%20%207',ItemId='%20%20%20%201')/_Attachments` |
| Headers | Token, `X-CSRF-Token`, `Content-Type: application/json` |
| Estado | `OPEN` |

Body (solo `Description`, que es el campo con `FieldControl/Mandatory`):

```json
{
  "Description": "Ticket del taxi del 9 de noviembre"
}
```

Resultado: devuelve el adjunto con `AttachId: "    1"` y el binario sin informar todavía.

Nota: la primera vez se envió también `FileName` y `MimeType`, y en la app el adjunto quedó a medias (con nombre pero sin fichero). Lo correcto es crearlo solo con la descripción y subir el fichero después.

### 7.5 Subir el contenido binario del adjunto

| | |
|---|---|
| Entidad / operación | `ExpenseAttachment`, propiedad `AttachmentContent` (`Edm.Stream`), subir (`PUT`) |
| Petición | `PUT {BASE_V4}/ExpenseAttachment(ReportId='%20%20%20%20%20%20%20%207',ItemId='%20%20%20%201',AttachId='%20%20%20%201')/AttachmentContent` |
| Headers | Token, `X-CSRF-Token`, `Content-Type: application/pdf` (debe coincidir con el fichero) |
| Body | Postman: *Body → binary → Select File* (PDF). No es JSON. |
| Resultado | `204 No Content`. En la app aparece el icono de PDF con las acciones de subir y borrar. |

Nota: el cuerpo del `PUT` son solo los bytes del archivo. **El nombre no puede ir en el body.**

### 7.6 Poner el nombre del fichero

Tras el `PUT`, la app no mostraba un nombre sobre el que hacer clic para abrir el fichero. Se resolvió informando `FileName` con una llamada propia.

| | |
|---|---|
| Entidad / operación | `ExpenseAttachment`, modificar (`PATCH`) |
| Petición | `PATCH {BASE_V4}/ExpenseAttachment(ReportId='%20%20%20%20%20%20%20%207',ItemId='%20%20%20%201',AttachId='%20%20%20%201')` |
| Headers | Token, `X-CSRF-Token`, **`Content-Type: application/json`** |
| Body | `{ "FileName": "sample_pdf_file.pdf" }` |
| Resultado | Efecto comprobado con un `GET` (7.7): `FileName` informado. |

Errores típicos de esta llamada: ver sección 10 (`NOT_ALLOWED` y `UNSUPP_MEDIA_TYPE`).

### 7.7 Leer el adjunto (metadatos)

| | |
|---|---|
| Petición | `GET {BASE_V4}/ExpenseAttachment(ReportId='%20%20%20%20%20%20%20%207',ItemId='%20%20%20%201',AttachId='%20%20%20%201')` |
| Requisitos | Token |
| Resultado | `200`, con `FileName: "sample_pdf_file.pdf"`, `MimeType: "application/pdf"`, `Description` y `AttachmentContent@odata.mediaContentType: "application/pdf"` |

### 7.8 Leer el binario del adjunto

| | |
|---|---|
| Petición | `GET {BASE_V4}/ExpenseAttachment(ReportId='%20%20%20%20%20%20%20%207',ItemId='%20%20%20%201',AttachId='%20%20%20%201')/AttachmentContent` |
| Requisitos | Token |
| Resultado | `200`, devuelve el PDF subido. En Postman se ve en la pestaña *Preview* o con *Save Response → Save to a file*. |
| Verificación cruzada | El mismo fichero se abre desde la app Fiori (servicio V2). |

## 8. Cómo leer el `$metadata` de la API

URL: `{BASE_V4}/$metadata`. Al ser un documento EDMX, **las entidades salen ordenadas por nombre, no por jerarquía**. La jerarquía se lee en las propiedades de navegación.

| Qué buscar | Qué dice |
|---|---|
| `EntitySet` dentro de `EntityContainer` | Los tres conjuntos expuestos: `ExpenseReport`, `ExpenseItem`, `ExpenseAttachment`. No hay catálogos. |
| `Key` / `PropertyRef` | Claves compuestas: item = `ReportId`+`ItemId`; adjunto = `ReportId`+`ItemId`+`AttachId`. Cada nivel arrastra la clave de su padre. |
| `NavigationProperty` con `Partner` | La composición: `_Items` ↔ `_Header`, `_Attachments` ↔ `_Item`. `OnDelete Cascade` indica borrado en cascada. |
| `ReferentialConstraint` | Qué campo del hijo corresponde al del padre. |
| `Core.Computed` | Lo pone el servidor: **no se envía** (`ReportId`, `ItemId`, `AttachId`, `HeaderStatus`, `TotalAmount`, `RejectReason`, `CurrencyCode` de la cabecera, campos de auditoría). |
| `Common.FieldControl = Mandatory` | Obligatorio. En cabecera: `CustomerID`, `ReportDate`, `Reason`. En ítem: `ExpenseType`, `ExpenseDate`, `Amount`. En adjunto: `Description`. |
| `Nullable="false"` | No admite nulo. En ABAP un campo CHAR vacío no es nulo, así que **no equivale a obligatorio**. |
| `MaxLength` | Longitud máxima (p. ej. `Reason` 100, `Vendor` 40). |
| `Capabilities.NavigationRestrictions` | Qué navegaciones admiten crear hijos (`Insertable = true` en `_Items` de la cabecera y `_Attachments` del ítem). |
| `Capabilities.InsertRestrictions` | `ExpenseItem` y `ExpenseAttachment` no se crean directamente (`Insertable = false`): se crean por la navegación del padre. |
| `Action` con `IsBound="true"` | Acciones: `send`, `approve`, `reject` (esta con el parámetro `reason`). |
| `Edm.Stream` + `Core.MediaType`/`Core.ContentDisposition` | `AttachmentContent` es el binario; su tipo sale de `MimeType` y su nombre de `FileName`. |
| Tipos | Fechas `Edm.Date` (`2026-11-10`); importes `Edm.Decimal` (número JSON, sin comillas). |

Lo que el metadata declara es lo **general**; lo que se permite en cada momento depende además del **estado** del registro (feature control).

## 9. Reglas de negocio que hereda la API

Toda la lógica vive en el business object de interfaz; la API la hereda sin escribirla de nuevo.

| Estado | Editar/borrar informe | Crear/editar gastos y adjuntos | `send` | `approve` | `reject` |
|---|---|---|---|---|---|
| `OPEN` | Sí | Sí | Sí | No | No |
| `SENT` | No | No | No | Sí | Sí |
| `APPROVED` | No | No | No | No | No |
| `REJECTED` | No | No | No | No | No |

Reglas relevantes al probar:

- Estado inicial `OPEN` y moneda `EUR`, asignados al crear.
- `TotalAmount` se recalcula como suma de los gastos.
- `Amount` debe ser mayor que 0.
- Un gasto de tipo `HOTEL` no puede superar 150 EUR (aviso al acercarse al 80 %).
- `send` exige: informe en `OPEN`, al menos un gasto y recibo (adjunto) en cada gasto de más de 50 EUR.
- `reject` exige un motivo de al menos 10 caracteres.
- Las claves (`ReportId`, `ItemId`, `AttachId`) las asigna el servidor (numeración temprana).

## 10. Errores encontrados y soluciones

| Síntoma | Causa | Solución |
|---|---|---|
| `401` con HTML de login (`Anmeldung fehlgeschlagen`) | Token caducado, no seleccionado en el request, o generado con `Client Credentials` | Generar token con **Authorization Code** y elegirlo en el desplegable *Token* |
| Error de login `No client with requested id: sap_client_id` | Variables escritas sin llaves dobles | Usar `{{sap_client_id}}` y `{{sap_client_secret}}`, con el entorno activo |
| Request duplicado da `401` aunque el original funciona | El token no se hereda al duplicar | Seleccionar el token en el nuevo request |
| Basic Auth no funciona en trial | No hay Communication Management en el trial compartido | Usar OAuth 2.0 Authorization Code con la Service Key |
| `403` en una escritura | Token CSRF ausente, caducado o de otra sesión | Repetir el `GET` con `X-CSRF-Token: Fetch` |
| `404` o registro no encontrado al filtrar por clave | Faltan o sobran espacios en la clave | Copiar la clave del `uri`/respuesta del servicio |
| `/IWCOR/CX_OD_METHD_NOT_ALLOWED` | Método no permitido para la URL (p. ej. `PATCH` sobre `.../AttachmentContent`) | `PATCH` al adjunto sin `/AttachmentContent`; ese segmento solo admite `PUT`/`GET` |
| `/IWCOR/CX_OD_UNSUPP_MEDIA_TYPE` | `Content-Type` incorrecto (p. ej. `application/pdf` en un `PATCH` con JSON) | `Content-Type: application/json` en llamadas JSON |
| `$count=true` no funciona en la app V2 | Es sintaxis de V4 | En V2, `/$count` o `$inlinecount` |
| `403`/`401` en host `abap-web` | Es el host del navegador (SSO) | Usar el host `abap` |
| Adjunto "a medias" en la app | Se creó con `FileName` y `MimeType` pero sin contenido | Crear solo con `Description`, subir el binario y después informar `FileName` |

## 11. Pendientes e ideas

**Pruebas por hacer**

- `DELETE` de adjunto, posición y cabecera (comprobar también que `updateHeaderTotal` recalcula el total al borrar una posición: es un punto a revisar).
- Acciones `send`, `approve` y `reject`: en V4 son acciones **ligadas** a la entidad y se invocan con el nombre calificado (`com.sap.gateway.srvd_a2x.zsd_expenses_api.v0001.<acción>`); por verificar. Probar la regla de recibo de más de 50 EUR y el motivo mínimo de 10 caracteres.
- Deep insert: crear la cabecera con sus posiciones en una sola llamada (`_Items` dentro del body).
- Comprobar si `MimeType` lo rellena el servidor a partir del `Content-Type` del `PUT`, o solo se conserva el enviado al crear (no está verificado).
- Probar el `PATCH` de `CurrencyCode` en una posición: el campo no es de solo lectura en el ítem.

**Mejoras y decisiones aparcadas**

- Informar `FileName` en la misma operación que la subida del contenido: `Content-Disposition` en el `PUT`, un `$batch` con *changeset*, o una acción propia en el business object. Las tres sin probar.
- Exponer los catálogos (p. ej. `ZVH_EXPENSE_TYPE`) como entity set, con proyección propia y alias CamelCase, para que un consumidor pueda consultar los valores válidos.
- Clave `ReportId`: en la documentación del modelo figura como `0000000001`, pero el servicio devuelve el valor con espacios a la izquierda. Se sospecha de la numeración temprana sobre un campo CHAR; verificar con *Data Preview* de `ZEXPENSE_HEADER` antes de cambiar nada, porque afecta también a la app.
- Autorización: es global, sin separar roles. Quien envía podría aprobar.
- El límite de hotel (150 EUR) está fijo en el código y los datos auxiliares dejan 300 EUR.
- Las llamadas de un sistema externo con usuario técnico permanente no son posibles en el trial (sin Communication Management). Requiere una cuenta con licencia o free tier.
- Gráfico de dos imágenes espejo: objetos de la app a la izquierda y de la API a la derecha, con huecos o guiones en los reutilizados.
- Valorar V2 Web API como segundo binding sobre la misma definición.
