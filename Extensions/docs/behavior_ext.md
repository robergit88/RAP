# Ampliaciones del comportamiento

Puedes agregar comportamiento adicional a un objeto de negocio RAP. Dependiendo de cómo permitas la extensibilidad del objeto de negocio RAP, esto generalmente incluye las siguientes opciones:

* **Extensiones específicas o relacionadas con el campo**

Estas opciones incluyen acciones y funciones adicionales, así como la incorporación de efectos secundarios, propiedades de campos y eventos.

* **Extensibilidad con comportamiento estándar**

Esta opción te permite ampliar el comportamiento para incluir determinaciones, validaciones, un guardado adicional o asignaciones de campos.


**Extensiones específicas o relacionadas con el campo**

Si desea proporcionar extensibilidad para extensiones no estándar o relacionadas con campos en un objeto de negocio RAP, debe declararlo utilizando la palabra clave **`extensible`** en la cabecera de la definición del comportamiento. Además, se debe especificar **`extensible`** en la definición del comportamiento de la entidad correspondiente del CDS.

Declaración de ampliación en la definición de comportamiento

```ABAP
managed implementation in class zbp_rap_i_purchaseorder unique;
strict ( 2 );
with draft;
extensible; 

define behavior for ZRAP_R_PurchaseOrder 
alias PurchaseOrderextensible
persistent table zrap_po
```

En la capa de proyección, también debes declarar la extensibilidad de esta manera

```ABAP
projection;
strict ( 2 );
extensible;
use draft; 

define behavior for ZRAP_C_PurchaseOrder alias PurchaseOrder
extensible
{
```

Si desea publicar un objeto de negocio RAP para que lo utilicen usuarios externos, dicha publicación debe realizarse a través de una interfaz de objeto de negocio.
El concepto de extensibilidad también forma parte del uso de un objeto de negocio RAP. Para que esto sea posible, debes declarar la interfaz del objeto de negocio como extensible.

Cómo declarar la extensibilidad de una interfaz de objeto de negocio

```ABAP
interface;
extensible;
use draft;
use side effects;

define behavior for ZRAP_I_PurchaseOrder alias PurchaseOrder
...
```

Si declaras la extensibilidad a través de una interfaz de objeto de negocio, no necesitas la indicación **`extensible`** en el nivel de definición del comportamiento de la entidad. A diferencia de la proyección de la definición de comportamiento, la propiedad de extensibilidad se hereda de la interfaz del objeto de negocio.

**Extensibilidad con comportamiento estándar**

Si quieres permitir que un objeto de negocio RAP se amplíe mediante un comportamiento estándar, debes declarar los conceptos que deseas permitir en el encabezado de la definición del comportamiento.

Puedes ver la versión completa de una definición de comportamiento que permite a los usuarios realizar extensiones mediante determinaciones (**`with determinations`**...), así como mediante validaciones (**`with validations`**...) y un guardado adicional (**`with additional save`**).
Para ello, debes agregar la palabra clave **`extensible`** en la cabecera de la definición del comportamiento. Por supuesto, también puedes hacer una selección y permitir únicamente las validaciones, por ejemplo.

Permitir la extensibilidad para determinaciones, validaciones y guardados adicionales

```ABAP
managed 
implementation in class zbp_rap_i_purchaseorder unique;
strict ( 2 );
with draft;
extensible 
{  
    with determinations on modify;
    with determinations on save;  
    with validations on save;
    with additional save;
}
...
```

Si deseas procesar las acciones de determinación como parte de efectos secundarios, por ejemplo, puedes marcarlas como extensibles de la siguiente manera:

```ABAP
determine action doValidateSupplier extensible
{ 
...
```

Si el objeto de negocio RAP admite el manejo de borradores, también puedes abrir la acción de borrador **`Prepare`** para extensiones. De esta manera, los consumidores pueden, por ejemplo, hacer que se realicen validaciones adicionales (**`on save`**) durante la preparación para activar una instancia de borrador. Para ello, debes agregar la propiedad **`extensible`** a la acción **`Prepare`** del borrador:

```ABAP
draft determine action Prepare extensible
{ 
    ...
```

Si has habilitado la opción de extensiones de campo, es recomendable declarar la asignación de campos correspondiente como extensible en la definición del comportamiento, aunque esto no sea obligatorio para las extensiones de campo. Puedes especificar la adición extensible de la siguiente manera:

```ABAP
mapping for zrap_a_po extensible
{ 
...
```

**Implementación de extensiones**

Para implementar extensiones, debes crear una extensión de comportamiento para la definición de comportamiento.

Puedes ver el código fuente del lenguaje de definición de comportamiento (BDL) que genera ADT al crear una extensión de comportamiento basada en una definición de comportamiento.

Creación inicial de una extensión de comportamiento

```ABAP
extension implementation in class zbp_rap_i_purchaseorder
draft  unique; 

extend behavior for PurchaseOrder
{
}
```

El nombre de alias **`PurchaseOrder`** que aparece después de la palabra clave **`extend behavior`** proviene de la definición de comportamiento del objeto de negocio RAP al que se le aplica la extensión.Una vez que hayas especificado este alias, puedes usar el BDL para definir qué extensiones quieres implementar para la entidad CDS. Por ejemplo, podrías crear algunas operaciones específicas, como una acción o una función, y asignarles un control de características y una verificación previa.

Declaración de extensiones específicas y relacionadas con el campo

```ABAP
extension implementation in class zbp_rap_i_purchaseorder_ext unique;

extend behavior for PurchaseOrder
{  
    action (features: instance, precheck) ZzMyCustomAction;  
    function ZzMyCustomFunc result [1] $self;
}

```

Los nombres de las extensiones, al igual que el nombre de la acción, deben estar en el espacio de nombres correspondiente. Como parte de una extensión de campo, es posible que desees verificar el campo mediante una validación antes de guardarlo. Dentro de la fase de interacción, deseas preestablecerlo con un valor predeterminado mediante una determinación. Para ello, debes ampliar el borrador de la acción `Prepare` (ampliar el borrador de la determinación `Prepare`) para que la nueva validación se procese allí. También podrías usar una propiedad de campo para definir que un campo adicional solo se pueda configurar al crearlo, pero no al modificarlo.

Extensiones con comportamiento estándar y una propiedad de campo

```ABAP
extension implementation in class zbp_rap_i_purchaseorder_ext_d  unique;

extend behavior for PurchaseOrder
{  
    determination ZzSetDefaultForCustomField on modify { create; }  
    validation ZzValidateCustomField on save { field ZzMy_Custom_Field_ZAC; }   
    
    extend draft determine action Prepare {
        validation ZzValidateCustomField;  
        }
field ( readonly:update ) ZzMy_Custom_Field_ZAC;

}
```

Debes ir subiendo por la pila de definiciones de comportamiento y exponer allí también todas las nuevas funcionalidades que tengan un carácter externo. Por esta razón, también debes implementar la declaración tanto en la capa de proyección como en la definición de comportamiento.

Cómo agregar una acción a la definición del comportamiento de proyección

```ABAP
extension for projection; 
extend behavior for PurchaseOrder
{  
    use action ZzMyCustomAction;
}
```

Si un objeto de negocio RAP expone su interfaz a través de una interfaz de objeto de negocio, debes utilizar la palabra **`using`** para hacer referencia a la interfaz de objeto de negocio.

Cómo exponer una extensión de comportamiento a través de una interfaz de objeto de negocio

```ABAP
extension using interface zrap_i_purchaseorder
implementation in class zbp_i_purchaseorder_ext_2 unique; 
extend behavior for PurchaseOrder 
{ ...
```

De esta manera, solo puedes extender las entidades CDS que están declaradas en la interfaz del objeto de negocio, lo cual es el procedimiento recomendado para implementar extensiones a través de una interfaz de objeto de negocio o para ponerlas a disposición.