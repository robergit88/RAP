# 01 Developing a Read Only List Report App

## Modelo de datos

### Tabla zrap_atrav_1234

```ABAP
@EndUserText.label : 'Tabla de viajes'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zrap_atrav_1234 {

  key client            : abap.clnt not null;
  key travel_uuid       : sysuuid_x16 not null;
  travel_id             : /dmo/travel_id;
  agency_id             : /dmo/agency_id;
  customer_id           : /dmo/customer_id;
  begin_date            : /dmo/begin_date;
  end_date              : /dmo/end_date;
  @Semantics.amount.currencyCode : 'zrap_atrav_1234.currency_code'
  booking_fee           : /dmo/booking_fee;
  @Semantics.amount.currencyCode : 'zrap_atrav_1234.currency_code'
  total_price           : /dmo/total_price;
  currency_code         : /dmo/currency_code;
  description           : /dmo/description;
  overall_status        : /dmo/overall_status;
  created_by            : syuname;
  created_at            : timestampl;
  last_changed_by       : syuname;
  last_changed_at       : timestampl;
  local_last_changed_at : timestampl;

}
```

### Tabla zrap_abook_1234

```ABAP
@EndUserText.label : 'Tabla de reservas'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zrap_abook_1234 {

  key client            : abap.clnt not null;
  key booking_uuid      : sysuuid_x16 not null;
  travel_uuid           : sysuuid_x16 not null;
  booking_id            : /dmo/booking_id;
  booking_date          : /dmo/booking_date;
  customer_id           : /dmo/customer_id;
  carrier_id            : /dmo/carrier_id;
  connection_id         : /dmo/connection_id;
  flight_date           : /dmo/flight_date;
  @Semantics.amount.currencyCode : 'zrap_abook_1234.currency_code'
  flight_price          : /dmo/flight_price;
  currency_code         : /dmo/currency_code;
  created_by            : syuname;
  created_at            : timestampl;
  last_changed_by       : syuname;
  local_last_changed_at : timestampl;
}
```

### CDS Interfaz Travel
```ABAP
//*&---------------------------------------------------------------------*
//*& ID_PROGRAMA: zi_rap_travel_1234                                     *
//*&                                                                     *
//*& TIPO DE PROGRAMA: INTERFAZ CDS                                      *
//*&                                                                     *
//*& DESCRIPCION: Vista base sobre ella se construyen proyecciones       *
//*&                                                                     *
//*& AUTOR: CB9980000068 - Roberto Puma                                  *
//*&                                                                     *
//*& FECHA DE CREACIÓN: 01.10.2025                                       *
//*&                                                                     *
//*&---------------------------------------------------------------------*
//*&                                                                     *
//*& HISTORIAL DE CAMBIOS                                                *
//*&                                                                     *
//*&  FECHA      AUTOR        MARCA                                      *
//*&  ------     ----------   -------------                              *
//*& DD.MM.AAAA  XXXXXXX      001                                        *
//*&                                                                     *
//*&---------------------------------------------------------------------*
@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Vista interfaz viajes'

@Metadata.ignorePropagatedAnnotations: true

define root view entity zi_rap_travel_1234
  as select from zrap_atrav_1234 as Travel

  composition [0..*] of zi_rap_booking_1234 as _Booking

  association [0..1] to /DMO/I_Agency       as _Agency   on $projection.AgencyID = _Agency.AgencyID
  association [0..1] to /DMO/I_Customer     as _Customer on $projection.CustomerID = _Customer.CustomerID
  association [0..1] to I_Currency          as _Currency on $projection.CurrencyCode = _Currency.Currency

{
  key travel_uuid           as TravelUUID,

      travel_id             as TravelID,
      agency_id             as AgencyID,
      customer_id           as CustomerID,
      begin_date            as BeginDate,
      end_date              as EndDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee           as BookingFee,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price           as TotalPrice,

      currency_code         as CurrencyCode,
      description           as Description,
      overall_status        as TravelStatus,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      /*asociaciones*/
      _Booking,
      _Agency,
      _Customer,
      _Currency
}

```

### CDS Interfaz Booking
```ABAP
//*&---------------------------------------------------------------------*
//*& ID_PROGRAMA: zi_rap_booking_1234                                    *
//*&                                                                     *
//*& TIPO DE PROGRAMA: INTERFAZ CDS                                      *
//*&                                                                     *
//*& DESCRIPCION: CDS de BASE sobre ella se construyen proyecciones      *
//*&                                                                     *
//*& AUTOR: CB9980000068 - Roberto Puma                                  *
//*&                                                                     *
//*& FECHA DE CREACIÓN: 01.10.2025                                       *
//*&                                                                     *
//*&---------------------------------------------------------------------*
//*&                                                                     *
//*& HISTORIAL DE CAMBIOS                                                *
//*&                                                                     *
//*&  FECHA      AUTOR        MARCA                                      *
//*&  ------     ----------   -------------                              *
//*& DD.MM.AAAA  XXXXXXX      001                                        *
//*&                                                                     *
//*&---------------------------------------------------------------------*
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Interfaz CDS de Reservas'
@Metadata.allowExtensions: true

define view entity zi_rap_booking_1234
  as select from zrap_abook_1234 as Booking

  association to parent zi_rap_travel_1234 as _Travel on 
                         $projection.TravelUUID = _Travel.TravelUUID

  association [1..1] to /DMO/I_Customer as _Customer on 
                         $projection.CustomerID = _Customer.CustomerID

  association [1..1] to /dmo/carrier as _Carrier on 
                         $projection.CarrierID = _Carrier.carrier_id

  association [1..1] to /DMO/I_Connection as _Connection on 
                        $projection.CarrierID = _Connection.AirlineID and 
                        $projection.ConnectionID = _Connection.ConnectionID

  association [1..1] to /DMO/I_Flight as _Flight on 
                        $projection.CarrierID = _Flight.AirlineID and 
                        $projection.ConnectionID = _Flight.ConnectionID and 
                        $projection.FlightDate = _Flight.FlightDate

  association [0..1] to I_Currency as _Currency on 
                        $projection.CurrencyCode = _Currency.Currency
{
  key booking_uuid          as BookingUUID,

      travel_uuid           as TravelUUID,
      booking_id            as BookingID,
      booking_date          as BookingDate,
      customer_id           as CustomerID,
      carrier_id            as CarrierID,
      connection_id         as ConnectionID,
      flight_date           as FlightDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price          as FlightPrice,

      currency_code         as CurrencyCode,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      /* associations */
      _Travel,
      _Customer,
      _Carrier,
      _Connection,
      _Flight,
      _Currency
}

```

## Clase que carga las tablas

```ABAP
class zcl_load_temp_table definition
  public final
  create public.

  public section.
    interfaces if_oo_adt_classrun.
endclass.


class zcl_load_temp_table implementation.
  method if_oo_adt_classrun~main.
    " delete existing entries in the database table
    delete from zrap_atrav_1234.
    delete from zrap_abook_1234.

    " Se insertan viajes
    insert zrap_atrav_1234 from (
        select from /dmo/travel
          fields uuid( )             as travel_uuid,
                 travel_id           as travel_id,
                 agency_id           as agency_id,
                 customer_id         as customer_id,
                 begin_date          as begin_date,
                 end_date            as end_date,
                 booking_fee         as booking_fee,
                 total_price         as total_price,
                 currency_code       as currency_code,
                 description         as description,
                 case status
                   when 'B' then 'A' " accepted
                   when 'X' then 'X' " cancelled
                   else 'O'          " open
                 end                 as overall_status,
                 createdby           as created_by,
                 createdat           as created_at,
                 lastchangedby       as last_changed_by,
                 lastchangedat       as last_changed_at,
                 lastchangedat       as local_last_changed_at
          order by travel_id
*         UP TO 200 ROWS
      ).

    if sy-subrc = 0.
      commit work.
      out->write( | Se ha cagado la tabla ZRAP_ATRAV_1234 con { sy-dbcnt } registros | ).
    endif.

    " Se inserta reservas de clientes para los viajes
    insert zrap_abook_1234 from (
        select
          from /dmo/booking as booking join
               zrap_atrav_1234 as z on booking~travel_id = z~travel_id
          fields
                 uuid( )               as booking_uuid,
                 z~travel_uuid         as travel_uuid,
                 booking~booking_id    as booking_id,
                 booking~booking_date  as booking_date,
                 booking~customer_id   as customer_id,
                 booking~carrier_id    as carrier_id,
                 booking~connection_id as connection_id,
                 booking~flight_date   as flight_date,
                 booking~flight_price  as flight_price,
                 booking~currency_code as currency_code,
                 z~created_by          as created_by,
*                 z~last_changed_by     AS last_changed_by       ,
                 z~last_changed_at     AS local_last_changed_by
      ).

    if sy-subrc = 0.
      commit work.
      out->write( | Se ha cagado la tabla ZRAP_ABOOK_1234 con { sy-dbcnt } registros | ).
    endif.
  endmethod.
endclass.
```

### CDS Travel Consumption
```ABAP
//*&---------------------------------------------------------------------*
//*& ID_PROGRAMA: ZC_RAP_TRAVEL_1234                                     *
//*&                                                                     *
//*& TIPO DE PROGRAMA: Vista CONSUMO CDS                                 *
//*&                                                                     *
//*& DESCRIPCION: Vista proyección                                       *
//*&                                                                     *
//*& AUTOR: CB9980000068 - Roberto Puma                                  *
//*&                                                                     *
//*& FECHA DE CREACIÓN: 01.10.2025                                       *
//*&                                                                     *
//*&---------------------------------------------------------------------*
//*&                                                                     *
//*& HISTORIAL DE CAMBIOS                                                *
//*&                                                                     *
//*&  FECHA      AUTOR        MARCA                                      *
//*&  ------     ----------   -------------                              *
//*& DD.MM.AAAA  XXXXXXX      001                                        *
//*&                                                                     *
//*&---------------------------------------------------------------------*
@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Vista consumo viajes'

@Metadata.allowExtensions: true

@Search.searchable: true

define root view entity ZC_RAP_TRAVEL_1234
  as projection on zi_rap_travel_1234 as Travel

{
  key TravelUUID,

      @Search.defaultSearchElement: true
      TravelID,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Agency', element: 'AgencyID' } } ]
      @ObjectModel.text.element: [ 'AgencyName' ]
      @Search.defaultSearchElement: true
      AgencyID,

      _Agency.Name        as AgencyName,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Customer', element: 'CustomerID' } } ]
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Search.defaultSearchElement: true
      CustomerID,

      _Customer.LastName  as CustomerName,
      BeginDate,
      EndDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Currency', element: 'Currency' } } ]
      CurrencyCode,

      Description,
      TravelStatus,
      LastChangedAt,
      LocalLastChangedAt,

      /* Associations */
      _Agency,
      _Booking : redirected to composition child ZC_RAP_BOOKING_1234,

      _Currency,
      _Customer
}

``` 

### CDS Booking Consumption
```ABAP
//*&---------------------------------------------------------------------*
//*& ID_PROGRAMA: ZC_RAP_BOOKING_1234                                    *
//*&                                                                     *
//*& TIPO DE PROGRAMA: Vista CONSUMO CDS                                 *
//*&                                                                     *
//*& DESCRIPCION: Vista proyección                                       *
//*&                                                                     *
//*& AUTOR: CB9980000068 - Roberto Puma                                  *
//*&                                                                     *
//*& FECHA DE CREACIÓN: 01.10.2025                                       *
//*&                                                                     *
//*&---------------------------------------------------------------------*
//*&                                                                     *
//*& HISTORIAL DE CAMBIOS                                                *
//*&                                                                     *
//*&  FECHA      AUTOR        MARCA                                      *
//*&  ------     ----------   -------------                              *
//*& DD.MM.AAAA  XXXXXXX      001                                        *
//*&                                                                     *
//*&---------------------------------------------------------------------*
@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Vista de CONSUMO de reservas'

@Metadata.allowExtensions: true

@Search.searchable: true
//@ObjectModel.usageType: #CONSUMPTION

define view entity ZC_RAP_BOOKING_1234
  as projection on zi_rap_booking_1234

{
  key BookingUUID,

      TravelUUID,

      @Search.defaultSearchElement: true
      BookingID,

      BookingDate,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Customer', element: 'CustomerID' } } ]
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Search.defaultSearchElement: true
      CustomerID,

      _Customer.LastName  as CustomerName,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Carrier', element: 'AirlineID' } } ]
      @ObjectModel.text.element: [ 'CarrierName' ]
      CarrierID,

      _Carrier.name       as CarrierName,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Flight', element: 'ConnectionID' },
                                            additionalBinding: [ { localElement: 'CarrierID', element: 'AirlineID' },
                                                                 { localElement: 'FlightDate',
                                                                   element: 'FlightDate',
                                                                   usage: #RESULT },
                                                                 { localElement: 'FlightPrice',
                                                                   element: 'Price',
                                                                   usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                   element: 'CurrencyCode',
                                                                   usage: #RESULT } ] } ]
      ConnectionID,

      FlightDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Currency', element: 'Currency' } } ]
      CurrencyCode,

      LocalLastChangedAt,

      /* associations */
      _Travel : redirected to parent ZC_RAP_TRAVEL_1234,

      _Customer,
      _Carrier,
      _Connection,
      _Flight
}

```

### Metadata extension Travel
```ABAP
//*&---------------------------------------------------------------------*
//*& ID_PROGRAMA: ZC_RAP_TRAVEL_1234                                     *
//*&                                                                     *
//*& TIPO DE PROGRAMA: UI ANOTACION                                      *
//*&                                                                     *
//*& DESCRIPCION: Vista anotaciones de interfaz usuario                  *
//*&                                                                     *
//*& AUTOR: CB9980000068 - Roberto Puma                                  *
//*&                                                                     *
//*& FECHA DE CREACIÓN: 01.10.2025                                       *
//*&                                                                     *
//*&---------------------------------------------------------------------*
//*&                                                                     *
//*& HISTORIAL DE CAMBIOS                                                *
//*&                                                                     *
//*&  FECHA      AUTOR        MARCA                                      *
//*&  ------     ----------   -------------                              *
//*& DD.MM.AAAA  XXXXXXX      001                                        *
//*&                                                                     *
//*&---------------------------------------------------------------------*
@Metadata.layer: #CORE

@UI.headerInfo: { typeName: 'Travel',
                  typeNamePlural: 'Viajes',
                  title: { type: #STANDARD, label: 'Travel', value: 'TravelID' } }

@UI.presentationVariant: [ { sortOrder: [ { by: 'TravelID', direction: #DESC } ] } ]

annotate entity ZC_RAP_TRAVEL_1234 with

{
  @UI.facet: [ { id: 'Travel',
                 purpose: #STANDARD,
                 type: #IDENTIFICATION_REFERENCE,
                 label: 'Travel',
                 position: 10 },
               { id: 'Booking',
                 purpose: #STANDARD,
                 type: #LINEITEM_REFERENCE,
                 label: 'Booking',
                 position: 20,
                 targetElement: '_Booking' } ]
  @UI.identification: [ { position: 1, label: 'Travel UUID' } ]
  TravelUUID;

  @UI.identification: [ { position: 10 } ]
  @UI.lineItem: [ { position: 10 } ]
  @UI.selectionField: [ { position: 10 } ]
  TravelID;

  @UI.identification: [ { position: 20 } ]
  @UI.lineItem: [ { position: 20 } ]
  @UI.selectionField: [ { position: 20 } ]
  AgencyID;

  @UI.identification: [ { position: 30 } ]
  @UI.lineItem: [ { position: 30 } ]
  @UI.selectionField: [ { position: 30 } ]
  CustomerID;

  @UI.identification: [ { position: 40 } ]
  @UI.lineItem: [ { position: 40 } ]
  BeginDate;

  @UI.identification: [ { position: 50 } ]
  @UI.lineItem: [ { position: 50 } ]
  EndDate;

  @UI.identification: [ { position: 60 } ]
  @UI.lineItem: [ { position: 60 } ]
  BookingFee;

  @UI.identification: [ { position: 70 } ]
  @UI.lineItem: [ { position: 70 } ]
  TotalPrice;

  @UI.identification: [ { position: 80 } ]
  @UI.lineItem: [ { position: 80 } ]
  Description;

  @UI.identification: [ { position: 90 } ]
  @UI.lineItem: [ { position: 90 } ]
  TravelStatus;

  @UI.hidden: true
  LastChangedAt;

  @UI.hidden: true
  LocalLastChangedAt;
}
```
### Metadata extension Booking
```ABAP
//*&---------------------------------------------------------------------*
//*& ID_PROGRAMA: ZC_RAP_BOOKING_1234                                    *
//*&                                                                     *
//*& TIPO DE PROGRAMA: UI ANOTACION                                      *
//*&                                                                     *
//*& DESCRIPCION: Vista anotaciones de interfaz usuario                  *
//*&                                                                     *
//*& AUTOR: CB9980000068 - Roberto Puma                                  *
//*&                                                                     *
//*& FECHA DE CREACIÓN: 01.10.2025                                       *
//*&                                                                     *
//*&---------------------------------------------------------------------*
//*&                                                                     *
//*& HISTORIAL DE CAMBIOS                                                *
//*&                                                                     *
//*&  FECHA      AUTOR        MARCA                                      *
//*&  ------     ----------   -------------                              *
//*& DD.MM.AAAA  XXXXXXX      001                                        *
//*&                                                                     *
//*&---------------------------------------------------------------------*
@Metadata.layer: #CORE
 
@UI.headerInfo: { typeName: 'Booking',
                  typeNamePlural: 'Bookings',
                  title: { type: #STANDARD, value: 'BookingID' } }

annotate entity ZC_RAP_BOOKING_1234 with

{
  @UI.facet: [ { id: 'Booking',
                 purpose: #STANDARD,
                 type: #IDENTIFICATION_REFERENCE,
                 label: 'Booking',
                 position: 10 } ]
  @UI.identification: [ { position: 10, label: 'Booking UUID' } ]
  BookingUUID;

  @UI.hidden: true
  TravelUUID;

  @UI.identification: [ { position: 20 } ]
  @UI.lineItem: [ { position: 20 } ]
  BookingID;

  @UI.identification: [ { position: 30 } ]
  @UI.lineItem: [ { position: 30 } ]
  BookingDate;

  @UI.identification: [ { position: 40 } ]
  @UI.lineItem: [ { position: 40 } ]
  CustomerID;

  @UI.identification: [ { position: 50 } ]
  @UI.lineItem: [ { position: 50 } ]
  CarrierID;

  @UI.identification: [ { position: 60 } ]
  @UI.lineItem: [ { position: 60 } ]
  ConnectionID;

  @UI.identification: [ { position: 70 } ]
  @UI.lineItem: [ { position: 70 } ]
  FlightDate;

  @UI.identification: [ { position: 80 } ]
  @UI.lineItem: [ { position: 80 } ]
  FlightPrice;

  @UI.hidden: true
  LocalLastChangedAt;
}
```