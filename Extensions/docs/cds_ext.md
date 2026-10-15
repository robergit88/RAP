# Ampliaciones con entidades CDS adicionales

En esta sección, aprenderás a habilitar un objeto de negocio RAP para su extensibilidad con entidades CDS adicionales en el árbol de composición de objetos de negocio.

**Creación de extensibilidad**

Para declarar la extensibilidad, debes agregar la anotación 

`@AbapCatalog.extensibility.allowNewCompositions: true` 

al modelo de datos CDS, de modo que se puedan agregar asociaciones de composición adicionales a la entidad CDS.

Permitir composiciones en la entidad CDS

```ABAP
...
@AbapCatalog.extensibility: {  
    extensible: true,  
    ...  
    allowNewCompositions: true
    }

define root view entity ZRAP_R_PurchaseOrder
...

```

Esta anotación debe especificarse a lo largo de la cadena de entidades CDS, es decir, también en la vista de proyección de CDS.

En la definición de comportamiento (y en las definiciones de comportamiento de proyección o en las interfaces de objetos de negocio basadas en ella), los objetos de negocio RAP deben marcarse como extensibles a nivel de encabezado. Además, es necesario marcar la entidad CDS correspondiente en la definición de comportamiento de la entidad como extensible mediante el uso del complemento `extensible`, de modo que puedas agregar una nueva entidad hija de CDS, por ejemplo, creando una operación de asociación para la entidad padre de CDS.

Si bien no fue necesario ampliar la definición del servicio en los escenarios de extensión descritos hasta este momento, esto se vuelve necesario cuando se amplía el árbol de composición de objetos de negocio con entidades CDS adicionales. Para ello, debes agregar la anotación 

`@AbapCatalog.extensibility.extensible: true` 

a la definición del servicio correspondiente.

Cómo declarar una definición de servicio como extensible

```ABAP
...
@AbapCatalog.extensibility.extensible: true
define service ZRAP_PURCHASE_ORDER  
provider contracts odata_v2_ui, odata_v4_ui 
{  
    expose ZRAP_R_PurchaseOrder as PurchaseOrder;
}
```

Agregar la propiedad *provider contract* (en este caso, `odata_v2_ui` u `odata_v4_ui`) para que solo se puedan agregar entidades CDS compatibles con este contrato de proveedor. No se debe confundir el contrato del proveedor con el contrato de liberación. El contrato del proveedor define la implementación de la entidad CDS en tiempo de ejecución y la funcionalidad disponible en ella.

**Implementación de extensiones**

Si desea agregar una o varias entidades CDS adicionales a una entidad CDS existente, se aplican las mismas reglas y condiciones que para el diseño de un objeto de negocio RAP. Debe definir su propia tabla de base de datos con una entidad CDS y una vista de proyección CDS, ambas basadas en esa tabla.
Dado que desea integrar la entidad CDS en un árbol de composición de objetos de negocio ya existente, esta no debe ser una entidad raíz de CDS (`root`).

El comportamiento de la nueva entidad CDS se declara en una extensión de comportamiento y, posteriormente, se puede implementar en el grupo de comportamientos correspondiente. En el modelo de datos CDS, debes agregar la nueva entidad CDS al árbol de composición de objetos de negocio utilizando la palabra clave `association to parent`.

Declaración de una asociación de padres para una entidad matriz de CDS

```ABAP

@EndUserText.label: 'Node Exte***nsion Supplier Info'
define view entity ZRAP_R_PurchaseOrderSuppInfo  
as select from zrap_a_supp_i
association to parent ZRAP_R_PurchaseOrder as _PurchaseOrder on
   $projection.PurchaseOrder =  _PurchaseOrder.PurchaseOrder
   {  
    key po_number      as PurchaseOrder,  
    key counter        as Counter,      
    ...
```

Al utilizar una extensión de vista definida mediante `extend view`, puedes extender la entidad CDS que sirve como entidad padre para la nueva entidad CDS, declarar allí una asociación de composición y exponerla

Vista de extensión con una asociación de composición

```ABAP
extend view entity ZRAP_R_PurchaseOrder with
composition [0..*] of ZRAP_R_PurchaseOrderSuppInfo as 
_ZzSupplierInfoZAC
{  
    _ZzSupplierInfoZAC
}
```

Estos pasos también deben realizarse en la capa de proyección del CDS.
Al utilizar una extensión de comportamiento, puedes agregar un comportamiento adicional a la nueva entidad CDS. Para ampliar el árbol de composición de objetos de negocio, debes ingresar dos elementos distintos allí:

* Define las extensiones del objeto de negocio RAP existente mediante `extend behavior`.

* Define el comportamiento de la nueva entidad CDS mediante la opción `define behavior`.

Agregamos una nueva entidad CDS a la entidad principal CDS mediante la creación de una operación de creación por asociación.

Integración de la nueva entidad CDS mediante la creación de una operación de asociación

```ABAP
extension implementation in class zbp_rap_x_purchaseordersuppin  
unique; 

extend behavior for PurchaseOrder
{  
    association _ZzSupplierInfoZAC { create; with draft; }
}

define behavior for ZRAP_R_PurchaseOrderSuppInfo alias ZzSupplierInfo
```

Dentro de la misma extensión de comportamiento, puedes especificar el comportamiento de la nueva entidad CDS.

Continuación: Especificación del comportamiento de la nueva entidad CDS en la extensión de comportamiento

```ABAP
...
define behavior for ZRAP_R_PurchaseOrderSuppInfo alias ZzSupplierInfo
persistent table zrap_a_supp_i
draft table zrap_d_supp_i
authorization dependent
lock dependent
late numbering
{  
    field ( readonly ) PurchaseOrder, Counter;
    update;  
    delete;
       
    association _PurchaseOrder { with draft; }   
    mapping for zrap_a_supp_i corresponding
{ ... }
}
```

A su vez, se expone la operación correspondiente mediante extensiones de la definición del comportamiento de proyección (`extend behavior`) y se utiliza la sintaxis «use» para exponer la nueva asociación `_ZzSupplierInfoZAC`, por ejemplo. Para implementar el comportamiento, debes utilizar el conjunto de comportamientos declarado en la extensión del comportamiento.

Por último, debes agregar la entidad CDS adicional a la definición del servicio. 
Sigue estos pasos:

1. En el **`Project Explorer`**, abre el menú contextual de la definición de servicio que deseas ampliar y seleccione **`New Service Definition template`**.

2. En el cuadro de diálogo que se abre, ingresa un nombre en el campo `Nombre` y una descripción en el campo `Description`. Asegúrate de que el valor `Extensión` esté seleccionado en el menú desplegable `Tipo de fuente`.

3. Haz clic en el botón `Next`, selecciona una solicitud de transporte y, a continuación, la plantilla `extend Service`.

5. Finaliza el proceso haciendo clic en el botón `Finish`.

En este ejemplo puedes ver el código fuente correspondiente a la extensión de definición del servicio.

Ampliación de la definición del servicio con una entidad CDS

```ABAP
extend service ZRAP_PURCHASE_ORDER with {
  expose ZRAP_R_PurchaseOrderSuppInfo as  
ZZRAP_R_PurchaseOrderSuppInfo;
}
...
```

Esto amplía la definición del servicio para incluir la entidad CDS recién agregada y la pone a disposición en el enlace de servicio correspondiente. Con este paso concluye nuestra descripción de la última opción de extensión: la incorporación de entidades CDS al árbol de composición de objetos de negocio.
