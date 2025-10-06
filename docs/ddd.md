# behavior definition

## Escenario GESTIONADO 

### SAP SE ENCARGADA DE TODO EL CICLO DE VIDA DE LOS REGISTROS

``` js

managed;

define behavior for zi_rap_travel_1234 alias Travel
persistent table zrap_atrav_1234
lock master
//authorization master ( instance ) // Si desmarco hay dump
etag master LocalLastChangedAt
{
//  create ( authorization : global ); // Si pido chequeo de autorizacion hay dump si no se implementa
  create;
  update;
  delete;
  association _Booking { create; }
  field ( numbering : managed, readonly ) TravelUUID;

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
persistent table zrap_abook_1234
lock dependent by _Travel
//authorization dependent by _Travel // Si desmarco hay dump
etag master LocalLastChangedAt
{
  association _Travel;
  update;
  delete;
  field ( numbering : managed, readonly ) BookingUUID;
  field ( readonly ) TravelUUID;

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