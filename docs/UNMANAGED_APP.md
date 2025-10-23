# UNMANAGED APP

1. [DICTIONARY](#dictionary)
   - 1.1 [Tabla BBDD](#11-tabla-bbdd)
   - 1.2 [Tabla BBDD DRAFT](#12-tabla-bbdd-draft)

2. [Core Data Services](#core-data-services)
   - 2.1 [DATA DEFINITIONS](#21-data-definitions)
     - 2.1.1 [ROOT VIEW](#211-root-view)
     - 2.1.2 [PROJECTION VIEW](#212-projection-view)
   - 2.2 [METADATA EXTENSIONS](#22-metadata-extensions)
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
@EndUserText.label : 'Tabla de personas'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zperson_t {

  key client      : abap.clnt not null;
  key id          : abap.char(10) not null;
  name            : abap.char(50);
  address         : abap.char(100);
  created_by      : syuname;
  created_at      : timestampl;
  last_changed_by : syuname;
  last_changed_at : timestampl;

}
```

### 1.2 Tabla BBDD DRAFT

``` abap
@EndUserText.label : ''
@AbapCatalog.enhancement.category : #EXTENSIBLE_ANY
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zperson_td {

  key mandt     : mandt not null;
  key id        : abap.char(10) not null;
  name          : abap.char(50);
  address       : abap.char(100);
  createdby     : syuname;
  createdat     : timestampl;
  lastchangedby : syuname;
  lastchangedat : timestampl;
  "%admin"      : include sych_bdl_draft_admin_inc;

}
```

## Core Data Services

### 2.1 DATA DEFINITIONS

#### 2.1.1 ROOT VIEW

``` abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ROOT VIEW ENTITY'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_PERSON
  as select from zperson_t

{
  key id              as Id,
      name            as Name,
      address         as Address,
      created_by      as CreatedBy,
      created_at      as CreatedAt,
      last_changed_by as LastChangedBy,
      last_changed_at as LastChangedAt

}

``` 

#### 2.1.2 PROJECTION VIEW

``` abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PROJECTION VIEW'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity Z_C_PERSON
  provider contract transactional_query
  as projection on Z_I_PERSON
{
      @Search.defaultSearchElement: true
  key Id,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
      Name,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
      Address,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt
}

```

### 2.2 METADATA EXTENSIONS

[...detalle](md_docs/metadata_extensions.md)

``` abap
@Metadata.layer: #CUSTOMER

//Título de la lista
//es una anotación de entidad porque se refiere a toda la entidad y no a un elemento específico.
@UI.headerInfo: { 
                  typeNamePlural: 'Lista de Personas',
                  typeName: 'Datos de la persona',
                  title: { type: #STANDARD, value: 'Name' } }

annotate view Z_C_PERSON with

{
  @UI.facet: [ { 
                 purpose: #STANDARD,
                 type: #IDENTIFICATION_REFERENCE,
                 label: 'Datos personales'
                 } ]
  
  //@UI.lineItem: posición y título en el listado
  @UI.lineItem: [ { position: 10, label: 'ID Persona', importance: #HIGH } ]
  //@UI.identification: posición y título como detalle
  @UI.identification: [ { position: 10, label: 'nuevo id Persona' } ]
  //@UI.selectionField: filtros de selección listado
  @UI.selectionField: [ { position: 10 } ]
  Id;

  @UI.lineItem: [ { position: 20, label: 'Nombre', importance: #HIGH } ]
  @UI.identification: [ { position: 20 , label: 'nuevo Nombre' } ]
  Name;

  @UI.lineItem: [ { position: 30, label: 'Dirección', importance: #MEDIUM } ]
  @UI.identification: [ { position: 30, label: 'nueva Dirección' } ]
  Address;

  @UI.lineItem: [ { position: 40, label: 'Creado Por', importance: #MEDIUM } ]
  @UI.identification: [ { position: 40, label: 'usuario creador' } ]
  CreatedBy;

  @UI.lineItem: [ { position: 50, label: 'Creado el', importance: #MEDIUM } ]
  @UI.identification: [ { position: 50, label: 'fecha creación' } ]
  CreatedAt;

  @UI.adaptationHidden: true
  LastChangedBy;

  @UI.adaptationHidden: true
  LastChangedAt;
}
```

### 2.3 BEHAVIOR DEFINITIONS

Es un artefacto que especifica QUÉ operaciones están permitidas sobre una entidad 
y CÓMO se comporta esa entidad durante las operaciones CRUD (Create, Read, Update, Delete).

[...detalle](./md_docs/BDEF.MD)

#### 2.3.1 BEHAVIOR DEFINITIONS

##### Se crea BDEF sobre CDS rot o Interfaz
![pedo](./img/BDEF_01.png)

``` abap
unmanaged
implementation in class zbp_i_person unique;
strict;
with draft;

define behavior for Z_I_PERSON alias person
draft table zperson_td
lock master total etag LastChangedAt
etag master LastChangedAt
authorization master ( instance )

{

  create ( authorization : global );
  update;
  delete;
  field ( readonly ) CreatedBy, CreatedAt, LastChangedBy, LastChangedAt;

  draft action Edit;
  draft action Activate optimized;
  draft action Discard;
  draft action Resume;
  draft determine action Prepare;

  mapping for zperson_t
    {
      Id            = id;
      Name          = name;
      Address       = address;
      CreatedBy     = created_by;
      CreatedAt     = created_at;
      LastChangedBy = last_changed_by;
      LastChangedAt = last_changed_at;
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
strict;
use draft;

define behavior for Z_C_PERSON alias person
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
@EndUserText.label: 'SERVICE DEFINITION person'
define service ZSD_PERSON {
  expose Z_C_PERSON as person;
}
```

### 3.2 services-binding

Pasos para la creación una nueva vinculación.

![pedo](./img/Service_BINDING_O4.png)


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