# Enhancing the business object behavior

## Metadataextension ZC_RAP_TRAVEL_1234

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

  @UI.identification: [ { position: 90 },
                        { type: #FOR_ACTION, dataAction: 'acceptTravel', label: 'Accept Travel' },
                        { type: #FOR_ACTION, dataAction: 'rejectTravel', label: 'Reject Travel' } ]
  @UI.lineItem: [ { position: 90 },
                  { type: #FOR_ACTION, dataAction: 'acceptTravel', label: 'Accept Travel' },
                  { type: #FOR_ACTION, dataAction: 'rejectTravel', label: 'Reject Travel' } ]
  TravelStatus;

  @UI.hidden: true
  LastChangedAt;

  @UI.hidden: true
  LocalLastChangedAt;
}
```

## Behavior definition Interfaz

```ABAP
//Escenario GESTIONADO SAP SE ENCARGADA DE TODO EL CICLO DE VIDA DE LOS REGISTROS

managed;
 
define behavior for zi_rap_travel_1234 alias Travel
implementation in class zcl_rap_travel_1234 unique
persistent table zrap_atrav_1234
lock master
etag master LocalLastChangedAt
{

  create;
  update;
  delete;
  association _Booking { create; }
  field ( numbering : managed, readonly ) TravelUUID;
  
  //control de campo estático de solo lectura
  field ( readonly ) TravelID, TotalPrice, TravelStatus;
  field ( readonly ) LastChangedAt, LastChangedBy, CreatedAt, CreatedBy, LocalLastChangedAt;

  // se mostrará un pequeño asterisco rojo en la interfaz de usuario de los elementos SAP Fiori.
  field ( mandatory ) AgencyID, CustomerID;

  // Acción (función) para aprobar viajes.
  action ( features : instance ) acceptTravel result [1] $self;
  
  // Acción (función) para rechaza viajes.
  action ( features : instance ) rejectTravel result [1] $self;
  
  // Ambas devuelven $self con cardinalidad 1 como resultado.
  // $self significa que se devuelve la instancia del mismo tipo en la que se realizó la operación.

  internal action recalcTotalPrice;

  //Se utiliza para predecir el estado a N cada vez que se crea/modifica una nueva instancia.
  determination setInitialStatus on modify { create; }
  
  //se utiliza para actualizar el precio total cada vez que se cambia el código de reserva o el código de moneda.
  
  determination calculateTotalPrice on modify { field BookingFee, CurrencyCode; }
  
  //se usa para determinar el TravelID cuando se crea una nueva instancia.
  determination calculateTravelID on save { create; }

  mapping for zrap_atrav_1234
    {
      TravelUUID         = travel_uuid;
      TravelID           = travel_id;
      AgencyID           = agency_id;
      CustomerID         = customer_id;
      BeginDate          = begin_date;
      EndDate            = end_date;
      BookingFee         = booking_fee;
      TotalPrice         = total_price;
      CurrencyCode       = currency_code;
      Description        = description;
      TravelStatus       = overall_status;
      CreatedBy          = created_by;
      CreatedAt          = created_at;
      LastChangedBy      = last_changed_by;
      LastChangedAt      = last_changed_at;
      LocalLastChangedAt = local_last_changed_at;
    }

}

define behavior for zi_rap_booking_1234 alias Booking
implementation in class zcl_rap_booking_1234 unique
persistent table zrap_abook_1234
lock dependent by _Travel
etag master LocalLastChangedAt
{
  association _Travel;
  update;
  delete;
  field ( numbering : managed, readonly ) BookingUUID;
  field ( readonly ) TravelUUID, BookingID;
  field ( readonly ) CreatedBy, LastChangedBy, LocalLastChangedAt;

  determination calculateBookingID  on modify { create; }
  determination calculateTotalPrice on modify { field FlightPrice, CurrencyCode; }

  mapping for zrap_abook_1234
    {
      BookingUUID        = booking_uuid;
      TravelUUID         = travel_uuid;
      BookingID          = booking_id;
      BookingDate        = booking_date;
      CustomerID         = customer_id;
      CarrierID          = carrier_id;
      ConnectionID       = connection_id;
      FlightDate         = flight_date;
      FlightPrice        = flight_price;
      CurrencyCode       = currency_code;
      CreatedBy          = created_by;
      LastChangedBy      = last_changed_by;
      LocalLastChangedAt = local_last_changed_at;
    }
}
```

## Behavior projection

```ABAP
projection;

define behavior for ZC_RAP_TRAVEL_1234 alias Travel
use etag
{
  use create;
  use update;
  use delete;

  use association _Booking { create; }

  use action acceptTravel;
  use action rejectTravel;

}

define behavior for ZC_RAP_BOOKING_1234 alias Booking
use etag
{
  use update;
  use delete;

  use association _Travel;
}
```