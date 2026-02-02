# MANAGED APP

1. [DICTIONARY](#dictionary)
   - 1.1 [Tabla BBDD](#11-tabla-bbdd)
   - 1.2 [Tabla BBDD DRAFT](#12-tabla-bbdd-draft)

2. [Core Data Services](#core-data-services)
   - 2.1 [DATA DEFINITIONS](#21-data-definitions)
     - 2.1.1 [ROOT VIEW](#211-root-view)
     - 2.1.2 [PROJECTION VIEW](#212-projection-view)
     - 2.1.3 [ABSTRACT ENTITY](#213-abstract-entity)
   - 2.2 [METADATA EXTENSIONS ¡Aquí se definen tres botones de interacción!](#22-metadata-extensions)
    - 2.3 [BEHAVIOR DEFINITIONS](#23-behavior-definitions)
     - 2.3.1 [BEHAVIOR DEFINITIONS](#231-behavior-definitions)
     - 2.3.2 [PROJECTION BEHAVIOR](#232-projection-behavior)

3. [Business Services](#business-services)
   - 3.1 [Services Definition](#31-services-definition)
   - 3.2 [Services Binding](#32-services-binding)

4. [Source Code Library](#source-code)
   - 4.1 [Clases](#41-clases)   
---

## DICTIONARY

### 1.1 Tabla BBDD

``` abap
@EndUserText.label : 'PO Master list'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zpo_master_list {

  key client      : abap.clnt not null;
  key end_user    : syuname not null;
  key file_id     : sysuuid_x16 not null;
  key line_numb   : abap.numc(10) not null;
  po_number       : ebeln;
  po_item         : ebelp;
  gr_quantity     : abap.dec(13,3);
  unit_of_measure : abap.char(3);
  site_id         : abap.char(16);
  header_text     : abap.char(40);

}
```

### 1.2 Tabla BBDD DRAFT

``` abap
@EndUserText.label : 'PO Master list Draft'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zpo_master_listd {

  key mandt     : mandt not null;
  key enduser   : syuname not null;
  key fileid    : sysuuid_x16 not null;
  key linenumb  : abap.numc(10) not null;
  ponumber      : ebeln;
  poitem        : ebelp;
  grquantity    : abap.dec(13,3);
  unitofmeasure : abap.char(3);
  siteid        : abap.char(16);
  headertext    : abap.char(40);
  "%admin"      : include sych_bdl_draft_admin_inc;
}


```

## Core Data Services

### 2.1 DATA DEFINITIONS

#### 2.1.1 ROOT VIEW

``` abap

@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Excel Data CDS'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZPO_I_MASTER_LIST
  as select from zpo_master_list

{
  key end_user        as EndUser,
  key file_id         as FileId,
  key line_numb       as LineNumb,
      po_number       as PoNumber,
      po_item         as PoItem,
      gr_quantity     as GrQuantity,
      unit_of_measure as UnitOfMeasure,
      site_id         as SiteId,
      header_text     as HeaderText
}

``` 

#### 2.1.2 PROJECTION VIEW

``` abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Excel Data CDS Consumption'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity ZPO_C_MASTER_LIST
  provider contract transactional_query
  as projection on ZPO_I_MASTER_LIST

{
  key EndUser,
  key FileId,
  key LineNumb,
      PoNumber,
      PoItem,
      GrQuantity,
      UnitOfMeasure,
      SiteId,
      HeaderText
}

```

#### 2.1.3 ABSTRACT ENTITY

**¿Qué es?**

* Es una entidad abstracta = Una estructura de datos que NO tiene tabla física detrás
* Se usa para definir parámetros de entrada/salida en funciones o acciones
* Similar a una estructura (TYPES) pero para RAP

En este caso:

* Tiene un campo dummy de tipo boolean
* Tiene una asociación _Stream a ZPO_A_STREAM
* Se usa probablemente para manejar la carga de archivos Excel

``` abap
@EndUserText.label: 'Abstract Entity for Excel Data File'
define root abstract entity ZPO_A_FILE

{
  @UI.hidden: true
  dummy   : abap_boolean;

  _Stream : association [1] to ZPO_A_STREAM on 1 = 1;
}

```

> define root abstract entity ZPO_A_STREAM

**¿Qué es?**

* Otra entidad abstracta que representa el archivo Excel en sí
* Define cómo se va a recibir/enviar el archivo

Campos importantes:

* **ExcelFile** (rawstring) = El contenido binario del archivo Excel
* **MimeType** (char 128) = Tipo de archivo (ej: "application/vnd.ms-excel")
* **FileName** (char 128) = Nombre del archivo (ej: "datos.xlsx")

``` abap
@EndUserText.label: 'Abstract Entity for Excel Data File'
define root abstract entity ZPO_A_STREAM

{
  @EndUserText.label: 'Select Excel file'
  @Semantics.largeObject: { mimeType: 'MimeType',
                            fileName: 'FileName',
                            contentDispositionPreference: #INLINE,
                            acceptableMimeTypes: [ 'application/vnd.ms-excel',
                                                   'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ] }
  ExcelFile : abap.rawstring(0);

  @UI.hidden: true
  MimeType  : abap.char(128);

  @UI.hidden: true
  FileName  : abap.char(128);
}

```
Anotaciones clave:
```js
@Semantics.largeObject: { mimeType: 'MimeType',
                          fileName: 'FileName',
                          contentDispositionPreference: #INLINE,
                          acceptableMimeTypes: [ 'application/vnd.ms-excel',
                                                 'application/vnd.openxmlformats-officedocument...' ]
}
```
Esto significa:

✅ "Este campo contiene un archivo grande (Excel)"
✅ "Solo acepta archivos .xls y .xlsx"
✅ "El nombre y tipo del archivo vienen en los otros campos"

Resumen en cristiano 🎯
En una app Fiori donde el usuario puede subir un archivo Excel:

ZPO_A_FILE = El "formulario" que el usuario ve (con un botón para adjuntar)
ZPO_A_STREAM = Los "datos del archivo" que se envían al backend (el contenido, nombre, y tipo)

Uso típico en una acción:
```js
action uploadExcel parameter ZPO_A_FILE result [1] ZPO_A_STREAM;
```

Esto permite que desde Fiori UI puedas hacer clic en "Subir Excel" → seleccionar archivo → enviarlo al sistema SAP.

### 2.2 METADATA EXTENSIONS
¡Aquí se definen tres botones de interacción!

Los Metadata Extensions sirven para definir la configuración de la UI (interfaz de usuario) de forma declarativa, permitiendo la separación entre:

* Lógica de datos (CDS View)
* Presentación visual (anotaciones UI)

Estas anotaciones se publican automáticamente en el servicio **OData** y son interpretadas por **Fiori Elements** para generar la interfaz sin programación manual.

Configuran cómo se ve y comporta la aplicación Fiori sin tocar código de datos ni frontend.

[...detalle](md_docs/metadata_extensions.md)

``` abap
@Metadata.layer: #CORE

@UI.headerInfo: { typeName: 'Excel File Data',
                  typeNamePlural: 'Excel File Datassssssssss',
                  title: { type: #STANDARD, value: 'EndUser' },
                  description: { type: #STANDARD, value: 'FileId' } }

annotate entity ZPO_C_MASTER_LIST with

{
  @UI.facet: [ { id: 'ExcelFile',
                 purpose: #STANDARD,
                 type: #IDENTIFICATION_REFERENCE,
                 position: 10,
                 label: 'Excel File' } ]
  @UI.hidden: true
  @UI.lineItem: [ { type: #FOR_ACTION, label: 'Upload Data',  dataAction: 'uploadExcelData' },
                  { type: #FOR_ACTION, label: 'Process Data', dataAction: 'processData'     } ]
  EndUser;

  @UI.hidden: true
  FileId;

  @UI.identification: [ { position: 5, label: 'Line Number' } ]
  @UI.lineItem: [ { position: 5, label: 'Line' } ]
  LineNumb;

  @UI.identification: [ { position: 10, label: 'PO Number' } ]
  @UI.lineItem: [ { position: 10, label: 'PO Number' } ]
  PoNumber;

  @UI.identification: [ { position: 20, label: 'PO Item' } ]
  @UI.lineItem: [ { position: 20, label: 'PO Item' } ]
  PoItem;

  @UI.identification: [ { position: 30, label: 'Quantity' } ]
  @UI.lineItem: [ { position: 30, label: 'Quantity' } ]
  GrQuantity;

  @UI.identification: [ { position: 40, label: 'Unit' } ]
  @UI.lineItem: [ { position: 40, label: 'UoM' } ]
  UnitOfMeasure;

  @UI.identification: [ { position: 50, label: 'Site ID' } ]
  @UI.lineItem: [ { position: 50, label: 'Site ID' } ]
  SiteId;

  @UI.identification: [ { position: 60, label: 'Header Text' } ]
  @UI.lineItem: [ { position: 60, label: 'Header Text' } ]
  HeaderText;
}
```

### 2.3 BEHAVIOR DEFINITIONS

Es un artefacto que especifica QUÉ operaciones están permitidas sobre una entidad 
y CÓMO se comporta esa entidad durante las operaciones CRUD (Create, Read, Update, Delete).

[...detalle](./md_docs/BDEF.MD)

Ventas:
* ✓ Separación de responsabilidades: Lógica de negocio separada de la UI
* ✓ Reutilización: Mismo comportamiento para múltiples interfaces (Fiori, API, etc.)
* ✓ Mantenibilidad: Cambios centralizados en un solo lugar
* ✓ Consistencia: Reglas de negocio aplicadas uniformemente
* ✓ RAP Framework: Aprovecha todas las capacidades del framework moderno de SAP

#### 2.3.1 BEHAVIOR DEFINITIONS

##### Se crea BDEF sobre CDS rot o Interfaz
![pedo](./img/BDEF_01.png)

``` abap
managed
implementation in class zbp_cds_r_travel_main unique;
strict ( 2 );
with draft;
define behavior for ZCDS_R_TRAVEL_MAIN alias Travel
persistent table ztravel_main
draft table ztravel_maind
etag master LocalLastChangedAt
lock master total etag LastChangedAt
authorization master ( global )
early numbering

{

  field ( readonly )
  TravelID;

  create;
  update;
  delete;

  draft action Activate optimized;
  draft action Discard;
  draft action Edit;
  draft action Resume;
  draft determine action Prepare;

  mapping for ztravel_main corresponding
    {
      TravelID           = travel_id;
      AgencyID           = agency_id;
      CustomerID         = customer_id;
      BeginDate          = begin_date;
      EndDate            = end_date;
      Price              = price;
      CurrencyCode       = currency_code;
      OverallStatus      = overall_status;
      CreatedBy          = created_by;
      CreatedAt          = created_at;
      LocalLastChangedBy = local_last_changed_by;
      LocalLastChangedAt = local_last_changed_at;
      LastChangedAt      = last_changed_at;
    }
}
```

#### 2.3.2 PROJECTION BEHAVIOR

#### Ventajas

1. Separación de Responsabilidades: Interface (lógica) vs Consumption (UI)
2. Múltiples UIs: Puedes tener varias proyecciones para diferentes roles
3. Mantenibilidad: Cambios en la lógica se reflejan automáticamente
4. Seguridad: Controlas qué expones en cada capa

``` abap
projection
implementation in class zbp_cds_r_travel_main unique;
strict ( 2 );
use draft;
define behavior for ZCDS_C_TRAVEL_MAIN alias Travel
use etag
{
  use create;
  use update;
  use delete;

  use action Edit;
  use action Activate;
  use action Discard;
  use action Resume;
  use action Prepare;
}
```

## business-services

### 3.1 services-definition

``` abap
@EndUserText.label: 'SERVICE DEFINITION'
define service ZUI_TRAVEL_MAIN {
  expose ZCDS_C_TRAVEL_MAIN as Travel;
}
```

### 3.2 services-binding

Pasos para la creación una nueva vinculación.

![Crear](./img/NEW_SERVICE_BINDING_01.png)


Selección del tipo de vinculación
![Binding Type](./img/NEW_SERVICE_BINDING_02.png)

Publicar el servicio
![Publish](./img/NEW_SERVICE_BINDING_03.png)

Visualizar
![Preview](./img/NEW_SERVICE_BINDING_04.png)

Prueba 1 - Crear o alta de registro.
![Botón Crear](./img/NEW_SERVICE_BINDING_05.png)

guardar
![Guardar](./img/NEW_SERVICE_BINDING_06.png)

## source-code

### 4.1 clases

``` abap
CLASS zbp_cds_r_travel_main DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zcds_r_travel_main.
ENDCLASS.

CLASS zbp_cds_r_travel_main IMPLEMENTATION.
ENDCLASS.
```

``` abap
CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

ENDCLASS.


CLASS lhc_Travel IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA entity           TYPE STRUCTURE FOR CREATE zcds_r_travel_main.
    DATA travel_id_max    TYPE /dmo/travel_id.
    DATA use_number_range TYPE abap_bool VALUE abap_true.

    " Ensure Travel ID is not set yet (idempotent)- must be checked when BO is draft-enabled
    LOOP AT entities INTO entity WHERE TravelID IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    DATA(entities_wo_travelid) = entities.

    " Remove the entries with an existing Travel ID
    DELETE entities_wo_travelid WHERE TravelID IS NOT INITIAL.

    IF use_number_range = abap_true.

      " Get numbers
      TRY.
          cl_numberrange_runtime=>number_get( EXPORTING nr_range_nr       = '01'
                                                        object            = '/DMO/TRV_M'
                                                        quantity          = CONV #( lines( entities_wo_travelid ) )
                                              IMPORTING number            = DATA(number_range_key)
                                              " TODO: variable is assigned but never used (ABAP cleaner)
                                                        returncode        = DATA(number_range_return_code)
                                                        returned_quantity = DATA(number_range_returned_quantity) ).
        CATCH cx_number_ranges INTO DATA(lx_number_ranges).
            " In case of an error, report all entities as failed
          LOOP AT entities_wo_travelid INTO entity.
            APPEND VALUE #( %cid      = entity-%cid
                            %key      = entity-%key
                            %is_draft = entity-%is_draft
                            %msg      = lx_number_ranges )
                   TO reported-travel.

            APPEND VALUE #( %cid      = entity-%cid
                            %key      = entity-%key
                            %is_draft = entity-%is_draft )
                   TO failed-travel.
          ENDLOOP.
          RETURN.
      ENDTRY.

      " determine the first free travel ID from the number range
      travel_id_max = number_range_key - number_range_returned_quantity.
    ELSE.
      " determine the first free travel ID without number range
      " Get max travel ID from active table
      SELECT FROM ztravel_main
       FIELDS MAX( travel_id ) AS travelID
        INTO @travel_id_max UP TO 1 ROWS.

      " Get max travel ID from draft table
      SELECT FROM ztravel_maind
       FIELDS MAX( travelid )
        INTO @DATA(max_travelid_draft) UP TO 1 ROWS.

      IF max_travelid_draft > travel_id_max.
        travel_id_max = max_travelid_draft.
      ENDIF.

    ENDIF.

    " Set Travel ID for new instances w/o ID
    LOOP AT entities_wo_travelid INTO entity.

      travel_id_max += 1.
      entity-TravelID = travel_id_max.

      APPEND VALUE #( %cid      = entity-%cid
                      %key      = entity-%key
                      %is_draft = entity-%is_draft )
             TO mapped-travel.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
```