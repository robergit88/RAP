# MANAGED APP

1. [Crear tabla de BBDD](#crear-tabla-de-bbdd)
2. [Crear tabla de BBDD DRAFT](#crear-tabla-de-bbdd-draft)

---

## Crear tabla de BBDD

Descripción de la tarea para crear la tabla principal de base de datos.
```ABAP
@EndUserText.label : 'Solo tabla travel'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table ztravel_main {

  key client            : abap.clnt not null;
  key travel_id         : /dmo/travel_id not null;
  agency_id             : /dmo/agency_id;
  customer_id           : /dmo/customer_id;
  begin_date            : /dmo/begin_date;
  end_date              : /dmo/end_date;
  @Semantics.amount.currencyCode : 'ztravel_main.currency_code'
  price                 : /dmo/total_price;
  currency_code         : /dmo/currency_code;
  overall_status        : /dmo/overall_status;
  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  local_last_changed_by : abp_locinst_lastchange_user;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;
  last_changed_at       : abp_lastchange_tstmpl;

}
```

## Crear tabla de BBDD DRAFT

Descripción de la tarea para crear la tabla de borradores en base de datos.
