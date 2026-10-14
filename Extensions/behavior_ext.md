# Ampliaciones del comportamiento

Puedes agregar comportamiento adicional a un objeto de negocio RAP. Dependiendo de cómo permitas la extensibilidad del objeto de negocio RAP, esto generalmente incluye las siguientes opciones:

* **Extensiones específicas o relacionadas con el campo**

Estas opciones incluyen acciones y funciones adicionales, así como la incorporación de efectos secundarios, propiedades de campos y eventos.

* **Extensibilidad con comportamiento estándar**

Esta opción te permite ampliar el comportamiento para incluir determinaciones, validaciones, un guardado adicional o asignaciones de campos.


**Extensiones específicas o relacionadas con el campo**

Si desea proporcionar extensibilidad para extensiones no estándar o relacionadas con campos en un objeto de negocio RAP, debe declararlo utilizando la palabra clave **`extensible`** en la cabecera de la definición del comportamiento. Además, se debe especificar **`extensible`** en la definición del comportamiento de la entidad correspondiente del CDS.

```ABAP
managed implementation in class zbp_rap_i_purchaseorder unique;
strict ( 2 );
with draft;
extensible; 

define behavior for ZRAP_R_PurchaseOrder 
alias PurchaseOrderextensible
persistent table zrap_po
```