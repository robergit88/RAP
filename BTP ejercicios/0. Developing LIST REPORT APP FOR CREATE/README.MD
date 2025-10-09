# MANAGED APP

1. [DICTIONARY](#dictionary)
   - 1.1 [Crear tabla de BBDD](#crear-tabla-de-bbdd)
   - 1.2 [Crear tabla de BBDD DRAFT](#crear-tabla-de-bbdd-draft)

---

## DICTIONARY

### 1.1 Crear tabla de BBDD

Tabla normal
```abap
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

### 1.2 Crear tabla de BBDD DRAFT

Tabla de datos temporales
``` abap
@EndUserText.label : 'DRAFT travel main table'
@AbapCatalog.enhancement.category : #EXTENSIBLE_ANY
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table ztravel_maind {

  key mandt          : mandt not null;
  key travelid       : /dmo/travel_id not null;
  agencyid           : /dmo/agency_id;
  customerid         : /dmo/customer_id;
  begindate          : /dmo/begin_date;
  enddate            : /dmo/end_date;
  @Semantics.amount.currencyCode : 'ztravel_maind.currencycode'
  price              : /dmo/total_price;
  currencycode       : /dmo/currency_code;
  overallstatus      : /dmo/overall_status;
  createdby          : abp_creation_user;
  createdat          : abp_creation_tstmpl;
  locallastchangedby : abp_locinst_lastchange_user;
  locallastchangedat : abp_locinst_lastchange_tstmpl;
  lastchangedat      : abp_lastchange_tstmpl;
  "%admin"           : include sych_bdl_draft_admin_inc;

}
```