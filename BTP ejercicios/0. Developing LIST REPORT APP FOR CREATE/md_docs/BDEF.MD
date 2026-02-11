# Behavior Definition en SAP
Una Behavior Definition es un componente clave del SAP RAP (RESTFUL ABAP Programming) que define el comportamiento transaccional y la lógica de negocio de un Business Object (BO).

# Concepto Principal
Es un artefacto que especifica QUÉ operaciones están permitidas sobre una entidad y CÓMO se comporta esa entidad durante las operaciones CRUD (Create, Read, Update, Delete).

# Estructura Básica
``` abap
managed implementation in class zbp_i_travel unique;
strict ( 2 );

define behavior for ZI_Travel alias Travel
persistent table ztravel
lock master
authorization master ( instance )
etag master last_changed_at
{
  // Operaciones estándar
  create;
  update;
  delete;
  
  // Campos de solo lectura
  field ( readonly ) travel_id, created_at;
  
  // Validaciones
  validation validateDates on save { field begin_date, end_date; }
  
  // Determinaciones (cálculos automáticos)
  determination calculateTotalPrice on modify { field booking_fee; }
  
  // Acciones
  action acceptTravel result [1] $self;
  action rejectTravel result [1] $self;
  
  // Asociaciones
  association _Booking { create; }
}
``` 

# Elementos Principales

### 1. Operaciones Estándar

* `create` - Permite crear nuevas instancias
* `update` - Permite modificar registros existentes
* `delete` - Permite eliminar registros
* `read` - Permite leer datos (implícito por defecto)

### 2. Control de Campos
```abap
field ( readonly ) travel_id;
field ( mandatory ) customer_id;
field ( readonly : update ) booking_date;
```

###  3. Validations (Validaciones)
Se ejecutan para verificar la consistencia de los datos:
```abap
validation validateCustomer on save 
{ 
  field customer_id; 
}
```

### 4. Determinations (Determinaciones)
Calculan o establecen valores automáticamente:
```abap
determination calculateTotal on modify 
{ 
  field booking_fee, currency_code; 
}
```

### 5. Actions (Acciones)
Operaciones de negocio personalizadas:
```abap
action acceptTravel result [1] $self;
action copyTravel parameter ZI_TravelCopy result [1] $self;
```

### 6. Lock Master
Define el mecanismo de bloqueo para evitar conflictos concurrentes.
### 7. Authorization Master
Controla las autorizaciones a nivel de instancia u operación.
### 8. ETag Master
Campo para control de concurrencia optimista (detecta modificaciones simultáneas).

# Tipos de Behavior Definition
## Managed
SAP gestiona automáticamente la persistencia:
``` abap
managed implementation in class zbp_i_travel unique;
```
## Unmanaged
El desarrollador controla completamente la lógica de persistencia:
```abap
unmanaged implementation in class zbp_i_travel unique;
```

# Implementation Type

## Abstract: 
Para composiciones y herencia
## Projection: 
Para exponer comportamientos específicos en servicios

## Behavior Implementation Class
La lógica real se implementa en una clase ABAP asociada:
```abap
CLASS zbp_i_travel DEFINITION PUBLIC ABSTRACT FINAL 
  FOR BEHAVIOR OF zi_travel.
  
  PRIVATE SECTION.
    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateDates.
      
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calculateTotalPrice.
      
    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~acceptTravel 
      RESULT result.
ENDCLASS.
```

# Relación con Fiori Elements
## Las Behavior Definitions se exponen automáticamente a través de servicios OData, 
## y Fiori Elements interpreta estas definiciones para:

* Mostrar/ocultar botones (Create, Edit, Delete)
* Habilitar acciones personalizadas en la UI
* Aplicar validaciones en tiempo real
* Controlar campos editables vs solo lectura
* Gestionar drafts (borradores)

# Ejemplo Completo
```abap
managed implementation in class zbp_travel unique;
strict ( 2 );
with draft;

define behavior for ZI_Travel alias Travel
persistent table ztravel
draft table ztravel_d
lock master total etag last_changed_at
authorization master ( instance )
{
  // Operaciones
  create;
  update;
  delete;
  
  // Campos
  field ( readonly ) travel_id;
  field ( mandatory ) agency_id, customer_id;
  
  // Draft (borrador)
  draft action Edit;
  draft action Activate;
  draft action Discard;
  draft action Resume;
  
  // Validaciones
  validation validateCustomer on save { field customer_id; }
  validation validateDates on save { field begin_date, end_date; }
  
  // Determinaciones
  determination setTravelNumber on save { create; }
  determination calculatePrice on modify { field booking_fee; }
  
  // Acciones
  action ( features: instance ) acceptTravel result [1] $self;
  action rejectTravel result [1] $self;
  
  // Composición (relación padre-hijo)
  association _Booking { create; with draft; }
}
```