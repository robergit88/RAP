
```ABAP
@Metadata.layer: #CUSTOMER

@UI.headerInfo: { typeName: 'Expense Report', typeNamePlural: 'Expense Reports', title.value: 'ReportId' }

annotate view ZC_EXP_HEADER with

{
  @UI.facet: [ { id: 'Header', label: 'General Info', type: #COLLECTION, position: 10 },
               { id: 'General',
                 parentId: 'Header',
                 label: 'General',
                 type: #FIELDGROUP_REFERENCE,
                 targetQualifier: 'General',
                 position: 10 },
               { id: 'Items',
                 label: 'Expense Items',
                 type: #LINEITEM_REFERENCE,
                 targetElement: '_Items',
                 position: 20 } ]
  @UI.fieldGroup: [ { qualifier: 'General', position: 10, label: 'Id', importance: #HIGH } ]

  // en la cabecera de la página, muestra el botón Enviar
  @UI.identification: [ { type: #FOR_ACTION, dataAction: 'send',    label: 'Enviar',   position: 10 },
                        { type: #FOR_ACTION, dataAction: 'approve', label: 'Aprobar',  position: 20 },
                        { type: #FOR_ACTION, dataAction: 'reject',  label: 'Rechazar', position: 30 } ]

  // en la tabla, muestra el botón Enviar;
  @UI.lineItem: [ { position: 10, importance: #HIGH, label: 'Id' },
                  { type: #FOR_ACTION, dataAction: 'send', label: 'Enviar' },
                  { type: #FOR_ACTION, dataAction: 'approve', label: 'Aprobar' },
                  { type: #FOR_ACTION, dataAction: 'reject', label: 'Rechazar' } ]
  ReportId;

  @UI.fieldGroup: [ { qualifier: 'General', position: 20, label: 'Reason' } ]
  @UI.lineItem: [ { position: 20, label: 'Reason' } ]
  Reason;

  @UI.fieldGroup: [ { qualifier: 'General', position: 30, label: 'Customer' } ]
  @UI.lineItem: [ { position: 30, label: 'Customer' } ]
  CustomerID;

  @UI.fieldGroup: [ { qualifier: 'General', position: 40, label: 'Open Date' } ]
  @UI.lineItem: [ { position: 40, label: 'Open Date' } ]
  ReportDate;

  @UI.fieldGroup: [ { qualifier: 'General', position: 50, label: 'Status', criticality: 'StatusCriticality' } ]
  @UI.lineItem: [ { position: 50, label: 'Status', criticality: 'StatusCriticality' } ]
  HeaderStatus;

  @UI.fieldGroup: [ { qualifier: 'General', position: 60, label: 'Total Amount' } ]
  @UI.lineItem: [ { position: 60, label: 'Total Amount' } ]
  TotalAmount;

  @UI.fieldGroup: [ { qualifier: 'General', position: 70, label: 'Rejeact Reason' } ]
  @UI.lineItem: [ { position: 70, label: 'Rejeact Reason' } ]
  RejectReason;

  @UI.hidden: true
  StatusCriticality;

  @UI.hidden: true
  CurrencyCode;
}
```

```ABAP
@Metadata.layer: #CUSTOMER

@UI.headerInfo: { typeName: 'Item', 
                  typeNamePlural: 'Items', 
                  title.value: 'ItemId' }

annotate view ZC_EXP_ITEMM with

{
  @UI.facet: [ { id: 'General',
                 label: 'Item',
                 type: #FIELDGROUP_REFERENCE,
                 targetQualifier: 'General',
                 position: 10 },
                 
               { id: 'Attachments',
                 label: 'Attachments',
                 type: #LINEITEM_REFERENCE,
                 targetElement: '_Attachments',
                 position: 20 } ]
                 
  @UI.fieldGroup: [ { qualifier: 'General', position: 10, label: 'Expense type' } ]
  @UI.lineItem: [ { position: 10, label: 'Expense type' } ]
  ExpenseType;

  @UI.fieldGroup: [ { qualifier: 'General', position: 20, label: 'Status' } ]
  @UI.lineItem: [ { position: 20, label: 'Status' } ]
  ItemStatus;

  @UI.fieldGroup: [ { qualifier: 'General', position: 30, label: 'Vendor' } ]
  @UI.lineItem: [ { position: 30, label: 'Vendor' } ]
  Vendor;

  @UI.fieldGroup: [ { qualifier: 'General', position: 40, label: 'Amount' } ]
  @UI.lineItem: [ { position: 40, label: 'Amount' } ]
  Amount;

  @UI.fieldGroup: [ { qualifier: 'General', position: 50, label: 'Date' } ]
  @UI.lineItem: [ { position: 50, label: 'Date' } ]
  ExpenseDate;
  
  @UI.hidden: true
  CurrencyCode;
}
```

```ABAP
@Metadata.layer: #CUSTOMER

annotate view ZC_EXP_ATTACH with

{
  @UI.facet: [ { id: 'General',
                 label: 'Attachment Details',
                 type: #FIELDGROUP_REFERENCE,
                 targetQualifier: 'General',
                 position: 10 } ]
                 
  @UI.fieldGroup: [ { qualifier: 'General', position: 10, label: 'File' } ]
  @UI.lineItem: [ { position: 10, label: 'File'  } ]
  AttachmentContent;

  @UI.fieldGroup: [ { qualifier: 'General', position: 20, label: 'Description' } ]
  @UI.lineItem: [ { position: 20, label: 'Description' } ]
  Description;
  
  @UI.hidden: true
  FileName;

  @UI.hidden: true
  MimeType;
}
```