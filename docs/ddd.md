# behavior definition

## Escenario GESTIONADO 

### SAP SE ENCARGADA DE TODO EL CICLO DE VIDA DE LOS REGISTROS

Esa es una pregunta excelente que toca el núcleo del desarrollo moderno de aplicaciones SAP, utilizando el modelo de programación RESTful ABAP (RAP).

Aquí tienes una explicación breve y simple del **Behavior Definition (Definición de Comportamiento)** en el contexto de las aplicaciones SAP Fiori Elements:

### **El "Behavior Definition" (BDEF) en Fiori Elements**

Piensa en el Behavior Definition (BDEF) como el **guion de lo que tu aplicación puede hacer con los datos**. Es el documento que le dice al *back-end* (el servidor ABAP) y, por extensión, a la interfaz de Fiori, qué tipo de transacciones están permitidas.

**En resumen, su función es:**

1.  **Definir Acciones Estándar (CRUD):** Especifica si el usuario puede **C**rear, **R**eer (Leer), **U**pdate (Actualizar) y **D**elete (Eliminar) registros del modelo de datos.
2.  **Definir Acciones Personalizadas:** Permite definir botones o funciones adicionales (como "Aprobar", "Rechazar", o "Cambiar Estatus") que no son estándar de CRUD.
3.  **Manejar el Comportamiento Transaccional:** Define si la aplicación usa la funcionalidad de *Draft* (borrador) y cómo manejar los bloqueos de registros (`LOCK`) para evitar que dos usuarios modifiquen el mismo dato a la vez.

---

### **¿Cómo se conecta con Fiori Elements?**

Fiori Elements es un *framework* que genera la interfaz de usuario (la pantalla) automáticamente a partir de los metadatos (anotaciones CDS).

1.  **Modelo de Datos (CDS Views):** Define los campos que se ven.
2.  **Behavior Definition (BDEF):** Define las acciones que se pueden realizar.

Cuando el marco de Fiori Elements lee el **Behavior Definition** a través del servicio OData, sabe exactamente qué botones mostrar.

* Si el BDEF permite `UPDATE`, Fiori Elements mostrará automáticamente un botón "Editar" o permitirá modificar los campos.
* Si el BDEF define una acción llamada `Aprobar`, Fiori Elements creará un botón llamado "Aprobar" en la barra de herramientas de la aplicación.

En esencia, el BDEF se asegura de que la interfaz de Fiori muestre el **comportamiento transaccional** correcto de tu objeto de negocio sin que tengas que escribir código JavaScript para la UI.


``` cds

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