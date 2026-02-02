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

5. [Pruebas](#pruebas)

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

<!-- [...detalle](md_docs/metadata_extensions.md) -->
[...detalle](../0.%20Developing%20LIST%20REPORT%20APP%20FOR%20CREATE/md_docs/metadata_extensions.md)

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

<!-- [...detalle](./md_docs/BDEF.MD) -->
[...detalle](../0.%20Developing%20LIST%20REPORT%20APP%20FOR%20CREATE/md_docs/BDEF.MD)

Ventas:
* ✓ Separación de responsabilidades: Lógica de negocio separada de la UI
* ✓ Reutilización: Mismo comportamiento para múltiples interfaces (Fiori, API, etc.)
* ✓ Mantenibilidad: Cambios centralizados en un solo lugar
* ✓ Consistencia: Reglas de negocio aplicadas uniformemente
* ✓ RAP Framework: Aprovecha todas las capacidades del framework moderno de SAP

#### 2.3.1 BEHAVIOR DEFINITIONS

##### Se crea BDEF sobre CDS root o Interfaz
<!-- ![pedo](./img/BDEF_01.png) -->
![pedo](../0.%20Developing%20LIST%20REPORT%20APP%20FOR%20CREATE/img/BDEF_01.png)

``` abap
managed implementation in class zbp_po_cl_master_list unique;
strict ( 2 );
with draft;
define behavior for ZPO_I_MASTER_LIST alias ExcData
persistent table zpo_master_list
draft table zpo_master_listd
etag master FileId
lock master total etag FileId
authorization master ( global )
{
  create;
  update;
  delete;
  field ( readonly, numbering : managed ) FileId;
  field ( readonly ) EndUser, LineNumb;

  static action uploadExcelData deep parameter ZPO_A_FILE;
  action processData result [1] $self;

  draft action Activate optimized;
  draft action Discard;
  draft action Edit;
  draft action Resume;
  draft determine action Prepare;

  mapping for zpo_master_list
    {
      EndUser       = end_user;
      FileId        = file_id;
      LineNumb      = line_numb;
      PoNumber      = po_number;
      PoItem        = po_item;
      GrQuantity    = gr_quantity;
      UnitOfMeasure = unit_of_measure;
      SiteId        = site_id;
      HeaderText    = header_text;
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
projection;
strict ( 2 );
use draft;

define behavior for ZPO_C_MASTER_LIST //alias <alias_name>
{
  use create;
  use update;
  use delete;

  use action uploadExcelData;
  use action processData;

  use action Activate;
  use action Discard;
  use action Edit;
  use action Resume;
  use action Prepare;
}
```

``` abap
abstract;
strict ( 2 );
with hierarchy;
define behavior for ZPO_A_STREAM //alias <alias_name>
{
}
```

``` abap
abstract;
strict ( 2 );
with hierarchy;
define behavior for ZPO_A_FILE //alias <alias_name>
{
  association _Stream with hierarchy;
}
```

## business-services

### 3.1 services-definition

``` abap
@EndUserText.label: 'SERVICE DEFINITION Master List Projection'
define service ZSD_PO_C_MASTER_LIST {
  expose ZPO_C_MASTER_LIST;
}
```

### 3.2 services-binding

Pasos para la creación una nueva vinculación.

![Crear](../0.%20Developing%20LIST%20REPORT%20APP%20FOR%20CREATE/img/NEW_SERVICE_BINDING_01.png)
<!-- ![Crear](./img/NEW_SERVICE_BINDING_01.png) -->


Selección del tipo de vinculación
<!-- ![Binding Type](./img/NEW_SERVICE_BINDING_02.png) -->
![Binding Type](../0.%20Developing%20LIST%20REPORT%20APP%20FOR%20CREATE/img/NEW_SERVICE_BINDING_02.png)

Publicar el servicio
<!-- ![Publish](./img/NEW_SERVICE_BINDING_03.png) -->
![Publish](../0.%20Developing%20LIST%20REPORT%20APP%20FOR%20CREATE/img/NEW_SERVICE_BINDING_03.png)

Visualizar
<!-- ![Preview](./img/NEW_SERVICE_BINDING_04.png) -->
![Preview](../0.%20Developing%20LIST%20REPORT%20APP%20FOR%20CREATE/img/NEW_SERVICE_BINDING_04.png)

<!-- Prueba 1 - Crear o alta de registro.
<!-- ![Botón Crear](./img/NEW_SERVICE_BINDING_05.png) -->
<!-- ![Botón Crear](../0.%20Developing%20LIST%20REPORT%20APP%20FOR%20CREATE/img/NEW_SERVICE_BINDING_05.png) -->

<!-- guardar -->
<!-- ![Guardar](./img/NEW_SERVICE_BINDING_06.png) -->
<!-- ![Guardar](../0.%20Developing%20LIST%20REPORT%20APP%20FOR%20CREATE/img/NEW_SERVICE_BINDING_06.png) --> -->

## source-code

### 4.1 clases

``` abap
CLASS zbp_po_cl_master_list DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zpo_i_master_list.
ENDCLASS.

CLASS zbp_po_cl_master_list IMPLEMENTATION.
ENDCLASS.
```

``` abap
class lhc_ZPO_I_MASTER_LIST definition inheriting from cl_abap_behavior_handler.
  private section.
    methods get_global_authorizations for global authorization
      importing request requested_authorizations for ExcData result result.

    methods processData for modify
      importing keys for action zpo_i_master_list~processData result result.

    methods uploadExcelData for modify
      importing keys for action zpo_i_master_list~uploadExcelData.

endclass.


class lhc_ZPO_I_MASTER_LIST implementation.
  method get_global_authorizations.
  endmethod.

  method processData.
  endmethod.

  method uploadExcelData.
    types: begin of gty_gr_xl,
             po_number       type string,
             po_item         type string,
             gr_quantity     type string,
             unit_of_measure type string,
             site_id         type string,
             header_text     type string,
             line_number     type string,
             file_id         type string,
             end_user        type string,
           end of gty_gr_xl.

    data lo_table_descr  type ref to cl_abap_tabledescr.
    data lo_struct_descr type ref to cl_abap_structdescr.
    data lt_excel        type standard table of gty_gr_xl.
    data lt_data         type table for create zpo_i_master_list\\ExcData.
    data lv_index        type sy-index.

    field-symbols <lfs_col_header> type string.

    data(lv_attachment) = value #( keys[ 1 ]-%param-_stream-ExcelFile optional ).
    if lv_attachment is initial.
      return.
    endif.

    data(lo_xlsx) = xco_cp_xlsx=>document->for_file_content( iv_file_content = lv_attachment )->read_access( ).

    data(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).

    data(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).

    data(lo_execute) = lo_worksheet->select( lo_selection_pattern )->row_stream( )->operation->write_to(
                                                                      ref #( lt_excel ) ).

    lo_execute->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
                                        )->if_xco_xlsx_ra_operation~execute( ).

    try.
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel ).
        lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
        data(lv_no_of_cols) = lines( lo_struct_descr->components ).
      catch cx_sy_move_cast_error.

    endtry.

    data(ls_excel) = value #( lt_excel[ 1 ] optional ).
    if ls_excel is not initial.
      do lv_no_of_cols times.
        lv_index = sy-index.
        assign component lv_index of structure ls_excel to <lfs_col_header>.
        if <lfs_col_header> is not assigned.
          continue.
        endif.
        data(lv_value) = to_upper( <lfs_col_header> ).
        data(lv_has_error) = abap_false.
        case lv_index.
          when 1.
            lv_has_error = cond #( when lv_value <> 'PO NUMBER (10)' then abap_true else lv_has_error ).
          when 2.
            lv_has_error = cond #( when lv_value <> 'PO ITEM (5)' then abap_true else lv_has_error ).
          when 3.
            lv_has_error = cond #( when lv_value <> 'QUANTITY' then abap_true else lv_has_error ).
          when 4.
            lv_has_error = cond #( when lv_value <> 'UNIT (3)' then abap_true else lv_has_error ).
          when 5.
            lv_has_error = cond #( when lv_value <> 'SITE ID (16)' then abap_true else lv_has_error ).
          when 6.
            lv_has_error = cond #( when lv_value <> 'HEADER TEXT (40)' then abap_true else lv_has_error ).
        endcase.
        if lv_has_error = abap_true.
          " append value #( %cid = keys[ 1 ]-%cid ) to failed-excdata.
          append value #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = 'Wrong File Format!!' ) ) to reported-excdata.
          unassign <lfs_col_header>.
          exit.
        endif.
        unassign <lfs_col_header>.
      enddo.
    endif.
    if lv_has_error = abap_true.
      return.
    endif.

    delete lt_excel index 1.
    delete lt_excel where po_number is initial.

    try.
        data(lv_file_id) = cl_system_uuid=>create_uuid_x16_static( ).
      catch cx_uuid_error.
    endtry.
    loop at lt_excel assigning field-symbol(<lfs_excel>).
      <lfs_excel>-file_id     = lv_file_id.
      <lfs_excel>-line_number = sy-tabix.
      <lfs_excel>-end_user    = cl_abap_context_info=>get_user_technical_name( ).
    endloop.

    lt_data = value #( for lwa_excel in lt_excel
                       ( "%cid         = keys[ 1 ]-%cid
                         "%is_draft    = keys[ 1 ]-%is_draft
                         %data    = value #( EndUser       = lwa_excel-end_user
                                             FileId        = lwa_excel-file_id
                                             LineNumb      = lwa_excel-line_number
                                             PoNumber      = lwa_excel-po_number
                                             PoItem        = lwa_excel-po_item
                                             GrQuantity    = lwa_excel-gr_quantity
                                             UnitOfMeasure = lwa_excel-unit_of_measure
                                             SiteId        = lwa_excel-site_id
                                             HeaderText    = lwa_excel-header_text )
                         %control = value #( EndUser       = if_abap_behv=>mk-on
                                             FileId        = if_abap_behv=>mk-on
                                             LineNumb      = if_abap_behv=>mk-on
                                             PoNumber      = if_abap_behv=>mk-on
                                             PoItem        = if_abap_behv=>mk-on
                                             GrQuantity    = if_abap_behv=>mk-on
                                             UnitOfMeasure = if_abap_behv=>mk-on
                                             SiteId        = if_abap_behv=>mk-on
                                             HeaderText    = if_abap_behv=>mk-on ) ) ).

    modify entities of zpo_i_master_list in local mode
           entity ExcData create auto fill cid with lt_data
           mapped data(lt_mapped)
           reported data(lt_reported)
           failed data(lt_failed).

    reported = lt_reported.
    mapped = lt_mapped.
    failed = lt_failed.

    if lt_failed is initial.
      append value #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                    text     = 'Excel File have been uploaded' ) ) to reported-excdata.

      read entities of zpo_i_master_list in local mode
           entity ExcData all fields with corresponding #( lt_mapped-excdata )
           " TODO: variable is assigned but never used (ABAP cleaner)
           result data(lt_updated).

    endif.
  endmethod.
endclass.
```

## pruebas
[Presentación](./img/SCREEN_01.png)
[Presentación](./img/SCREEN_02_UPLOAD.png)
[Presentación](./img/SCREEN_03_FILES.png)
[Presentación](./img/SCREEN_04_UPLOAD.png)
[Presentación](./img/SCREEN_05_UPLOADED.png)
[Presentación](./img/SCREEN_06_GO.png)
[Presentación](./img/SCREEN_07_DISPLAY_DATA.png)
[Presentación](./img/SCREEN_08_SAVE.png)
