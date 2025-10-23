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

[...detalle](/docs/metadata_extensions.md)

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

#### DETALLE DE LISTADO

![LISTA](/img/UNMANAGED_01.png)

#### DETALLE ELEMENTO

![LISTA](/img/UNMANAGED_02.png)

### 2.3 BEHAVIOR DEFINITIONS

Es un artefacto que especifica QUÉ operaciones están permitidas sobre una entidad 
y CÓMO se comporta esa entidad durante las operaciones CRUD (Create, Read, Update, Delete).

[...detalle](/docs/BDEF_MANAGED_1.md)

#### 2.3.1 BEHAVIOR DEFINITIONS

##### Se crea BDEF sobre CDS root o Interfaz

<!-- ![pedo](./img/BDEF_01.png) -->
<!-- ![pedo](/img/) -->

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

Servicio OData V4

![pedos](/img/SERVICE_BINDING_O4.png)


## source-code

### 4.1 clases

``` abap
CLASS zbp_i_person DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF z_i_person.
ENDCLASS.

CLASS zbp_i_person IMPLEMENTATION.
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


CLASS lhc_person DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR person RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR person RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE person.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE person.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE person.

    METHODS read FOR READ
      IMPORTING keys FOR READ person RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK person.

ENDCLASS.


CLASS lhc_person IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.
    DATA lt_person TYPE TABLE OF zperson_t.
    DATA ls_person TYPE zperson_t.

    GET TIME STAMP FIELD DATA(lv_timestamp).
    DATA(lv_user) = sy-uname.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      CLEAR ls_person.
      ls_person-client     = sy-mandt.
      ls_person-id         = <entity>-Id.
      ls_person-name       = <entity>-Name.
      ls_person-address    = <entity>-Address.
      ls_person-created_by = lv_user.
      ls_person-created_at = lv_timestamp.

      APPEND ls_person TO lt_person.
    ENDLOOP.

    INSERT zperson_t FROM TABLE @lt_person.
  ENDMETHOD.

  METHOD update.
    DATA lt_person TYPE TABLE OF zperson_t.

    GET TIME STAMP FIELD DATA(lv_timestamp).
    DATA(lv_user) = sy-uname.

    SELECT * FROM zperson_t
      FOR ALL ENTRIES IN @entities
      WHERE id = @entities-Id
      INTO TABLE @lt_person.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

      ASSIGN lt_person[ id = <entity>-Id ] TO FIELD-SYMBOL(<db>).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      <db>-name            = COND #( WHEN <entity>-%control-Name = if_abap_behv=>mk-on
                                     THEN <entity>-Name
                                     ELSE <db>-name ).

      <db>-address         = COND #( WHEN <entity>-%control-Address = if_abap_behv=>mk-on
                                     THEN <entity>-Address
                                     ELSE <db>-address ).
      <db>-last_changed_by = lv_user.
      <db>-last_changed_at = lv_timestamp.
    ENDLOOP.

    UPDATE zperson_t FROM TABLE @lt_person.
  ENDMETHOD.

  METHOD delete.
    DATA lt_person TYPE TABLE OF zperson_t.

    SELECT * FROM zperson_t
      FOR ALL ENTRIES IN @keys
      WHERE id = @keys-Id
      INTO TABLE @lt_person.

    DELETE zperson_t FROM TABLE @lt_person.
  ENDMETHOD.

  METHOD read.
    DATA lt_person TYPE TABLE OF zperson_t.

    SELECT * FROM zperson_t
      FOR ALL ENTRIES IN @keys
      WHERE id = @keys-Id
      INTO TABLE @lt_person.

    result = VALUE #( FOR ls_stud IN lt_person
                      ( Id            = ls_stud-id
                        Name          = ls_stud-name
                        Address       = ls_stud-address
                        CreatedBy     = ls_stud-created_by
                        CreatedAt     = ls_stud-created_at
                        LastChangedBy = ls_stud-last_changed_by
                        LastChangedAt = ls_stud-last_changed_at ) ).
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.
ENDCLASS.


CLASS lsc_Z_I_PERSON DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize          REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save              REDEFINITION.

    METHODS cleanup           REDEFINITION.

    METHODS cleanup_finalize  REDEFINITION.

ENDCLASS.


CLASS lsc_Z_I_PERSON IMPLEMENTATION.
  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.
ENDCLASS.
```