# Extensiones al modelo de datos

En esta sección, analizaremos las opciones disponibles para marcar el modelo de datos CDS de un objeto RAP como extensible.
Mediante las anotaciones proporcionadas para este fin, se permite a los usuarios de un objeto de negocio RAP definir nuevos campos en el contexto del concepto de extensión.
Estos campos pasan a formar parte del modelo de datos transaccionales (incluida la gestión de borradores) y están disponibles para los consumidores del objeto de negocio RAP como parte de las operaciones estándar definidas para el acceso de lectura y escritura (crear, actualizar y crear por asociación).

**Creando la extensibilidad de la persistencia**

Las tablas de la base de datos se pueden marcar como extensibles mediante la anotación 

`@AbapCatalog.enhancement.category` 

Esta anotación asigna una categoría de extensión a la tabla de la base de datos. 

Cuando se crea una tabla de base de datos, la anotación preestablecida asigna el valor `#NOT_EXTENSIBLE` y la tabla no se puede ampliar por defecto.
Debe establecer la categoría de extensión explícitamente, por ejemplo, al valor `#EXTENSIBLE_CHARACTER_NUMERIC` para que la tabla de la base de datos pueda ampliarse utilizando una estructura de anexión. Los siguientes valores son posibles:

* **#EXTENSIBLE_ANY**

La estructura y sus extensiones pueden contener campos de cualquier tipo de datos.

* **#EXTENSIBLE_CHARACTER**

La estructura y sus extensiones pueden contener campos del tipo de datos de caracteres.

* **#EXTENSIBLE_CHARACTER_NUMERIC**

La estructura y sus extensiones pueden contener campos de tipos de datos de caracteres y numéricos.

``` js
@EndUserText.label: 'Purchase Order'
@AbapCatalog.enhancement.category: #EXTENSIBLE_CHARACTER_NUMERIC
...
define table zrap_po {  
   key client    : abap.clnt not null;  
   key po_number : ebeln not null;  
...
}
```

Se recomienda crear un include de extensión separado como punto de extensión para mantener los campos adicionales separados.
Para ello, debe agregar un campo auxiliar (en este caso, zrap_po_ext_dummy) para que la extensión incluya al menos un campo y pueda activarse.

``` js
@EndUserText.label: 'Extension Include Structure'
@AbapCatalog.enhancement.category: #EXTENSIBLE_CHARACTER_NUMERIC
@AbapCatalog.enhancement.fieldSuffix: 'ZAC'
@AbapCatalog.enhancement.quotaMaximumFields: 350
@AbapCatalog.enhancement.quotaMaximumBytes: 3500

define structure zrap_po_ext {

 zrap_po_ext_dummy: abap.char(1);

}
```

Si hay varias extensiones (es decir, varias estructuras de apéndice) para un include de extensión, los nombres de los campos añadidos pueden entrar en conflicto, por ejemplo, si las extensiones se crean e instalan en diferentes sistemas fuente. Para evitar tales conflictos de nombres o reducir su probabilidad, puede especificar un campo `sufijo` utilizando la anotación

`@AbapCatalog.enhancement.fieldSuffix.`

Debe constar de exactamente tres dígitos. A continuación, una comprobación de sintaxis garantiza que los nombres de todos los campos añadidos tengan este sufijo.

Se puede usar la anotacion `@AbapCatalog.enhancement.quotaMaximumFields` para especificar la cantidad de campos que se pueden añadir. La anotacion `@AbapCatalog.enhancement. quotaMaximumBytes` especifica el número de bytes reservados para el consumidor de la extensión include.

Puede agregar la tabla de base de datos correspondiente a la inclusión de la extensión utilizando la palabra clave `include`.

``` js
define table zrap_po {
      key client : abap.clnt not null;  
      key po_number         : 
      ebeln not null;  
      ...  
      include zrap_po_ext;
}
```

Si también hay una tabla de borradores, puede añdir el include de extensión usando la palabra clave `include`. De esta forma, se deja preparada la persistencia para las extensiones de campo. 

Posteriormente, se debe prepara la CDS para que sea extensible.

**Establecimiento de la extensibilidad para el modelo de datos CDS**

De forma similar a la creación del include de extensión, se recomienda que también se cree una vista de extensión para el modelo de datos, en la que se declaren los campos adicionales de la entidad CDS.
Un ejemplo de una vista de extensión:

``` js
@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Extension View Purchase Order'
@AbapCatalog.extensibility: {

extensible: true,  
elementSuffix: 'ZAC',  
allowNewDatasources: false,  
dataSources: ['PurchaseOrder'],  
quota: {    
        maximumFields: 350,    
        maximumBytes: 3500  }
 }

define view entity ZRAP_E_PurchaseOrder  
as select from zrap_po as PurchaseOrder {  
    key po_number as PurchaseOrder
}
```

Se puede añadir la anotación `@AbapCatalog.extensibility.extensible: true` a la vista de extensión y marcarla como extensible.
Es esencial que configure la categoría de extensión de vista en la anotación.
`@AbapCatalog.viewEnhancementCategory.`
El valor por defecto es `#NONE` Cambia esto al valor `#PROJECTION_LIST` (Esta anotación es una matriz que permite múltiples valores). Este valor especifica que la lista de selección de la entidad CDS puede ampliarse con campos y asociaciones adicionales.

En la sección `dataSources`, se debe ingresar nombres de alias de las fuentes de datos (en este caso, `PurchaseOrder`) para utilizar en las extensiones. El consumidor utiliza luego estos nombres de alias dentro de una extensión de vista de CDS para especificar el campo adicional. Esto significa que los nombres especificados en la anotación también forman parte de la interfaz pública de la aplicación en lo que respecta a la extensibilidad y, por lo tanto, deben permanecer estables.

Como ya sabes por el modelo de datos virtual (VDM), la vista de extensión está integrada en la entidad CDS del objeto de negocio RAP que se va a extender mediante una asociación

Extensión: Incluir vista por asociación

``` js
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Root Late Numbering'
@AbapCatalog.extensibility: {
...  
dataSources: ['_Extension'],  
...
}

define root view entity ZRAP_R_PurchaseOrder  
as select from zrap_po  
 associationg[1] to ZRAP_E_PurchaseOrder as _Extension on 
 _Extension.PurchaseOrder = $projection.PurchaseOrder 
  {  
    key po_number as PurchaseOrder,  
    ...
  }
```

La asociación `_Extension` no queda expuesta. Está disponible como un componente privado de la entidad CDS dentro de la vista «include» de la extensión. 

Para las demás entidades CDS de la pila de vistas, que consisten en entidades CDS de la capa de proyección o en una vista de interfaz CDS (como base para una interfaz de objeto de negocio), también puedes utilizar las anotaciones especificadas en `@AbapCatalog.extensibility`.

Extensibilidad de una vista de proyección CDS

```js
...
@AbapCatalog.extensibility: {  
    extensible: true,  
    elementSuffix: 'ZAC',  
    allowNewDatasources: false,  
    dataSources: ['PurchaseOrder'],  
    quota: {    maximumFields: 350,    
                maximumBytes: 3500  
           }
        }
    @Metadata.allowExtensions: true
    define root view entity ZRAP_C_PurchaseOrder  
    provider contract transactional_query  
    as projection on ZRAP_R_PurchaseOrder as PurchaseOrder
    {
...
```

Por lo general en una vista de proyección de CDS la anotación `@Metadata.allow Extensions: true` permite la extensión de metadatos. 
Si permites extensiones de campos de esta manera, también debes considerar cómo se asignan los campos adicionales a los campos de la tabla de la base de datos como parte de la secuencia de guardado.

Para ello, puedes utilizar la asignación de campos en la definición del comportamiento agregando la entrada `corresponding`. De esta manera, los campos con el mismo nombre en la CDS y en la tabla de la base de datos se asignan entre sí, y los valores respectivos de los campos se almacenan de manera persistente sin que tengas que declarar explícitamente que la asignación de campos es extensible.
Si falta el `corresponding` y no se puede ampliar la asignación de campos La implementación de la secuencia de guardado del objeto de negocio RAP debe garantizar que los campos con el mismo nombre se transfieran a la tabla de la base de datos (en el caso de un `unmanaged save`) por ejemplo, mediante la expresión del constructor `#( corresponding ...)`.

Por lo tanto, el procedimiento depende de si implementas la secuencia de guardado por tu cuenta o si utilizas el tipo de implementación administrada.

Si el objeto de negocio RAP que deseas preparar para las extensiones cuenta con la función de manejo de borradores, debes crear una entidad CDS separada basada en la tabla de borradores con las anotaciones ya conocidas, de modo que los campos adicionales también formen parte de las instancias de borrador.
Esto se debe a que estas instancias de borrador se almacenan de manera persistente por separado de las instancias activas. Para ello, debes crear una vista de consulta preliminar, tal como se muestra aqui

Vista preliminar de consulta para la extensibilidad basada en la tabla preliminar

``` js
...
@AbapCatalog.extensibility: {  
    extensible: true,  
    dataSources: ['PurchaseOrder'],  
    elementSuffix: 'ZAC',  
    quota: {    
        maximumFields: 350,    
        maximumBytes: 3500  
        }
    }
    
    define view entity ZRAP_R_PurchaseOrderDraft  
     as select from zrap_d_po as PurchaseOrder
     { 
...

```

Puedes utilizar esta vista en la definición de comportamiento para preparar la tabla preliminar para las extensiones. En la definición de comportamiento, ingresa la vista utilizando el complemento de consulta después del nombre de la tabla preliminar declarada allí

Vista de consulta de borradores para la tabla de borradores

``` js
define behavior for ZRAP_R_PurchaseOrder alias PurchaseOrder
persistent table zrap_po
draft table zrap_d_po query ZRAP_R_PurchaseOrderDraft
...
```

**Cómo realizar extensiones**
Si, como consumidor, deseas ampliar un objeto de negocio RAP con campos adicionales, primero debes crear una estructura de anexo para el include de extensión proporcionado por el proveedor.
Ahí es donde se declara el campo adicional. 

Para conocer el procedimiento exacto, un ejemplo

Creación de una estructura de anexo para la inclusión de extensión con extensión de campo

``` abap
@EndUserText.label: 'PO Extension'
@AbapCatalog.enhancement.category: #NOT_EXTENSIBLE
extend type zrap_po_ext with zrap_po_extension {
zzmy_custom_field_zac: abap.char(2);
}
```

El campo adicional `zzmy_custom_field_zac` definido aquí debe estar en el espacio de nombres correspondiente del paquete en el que guardas todos los objetos de desarrollo de tu extensión. Por lo general, este es el espacio de nombres clásico del cliente, que comienza con **zz** (o **yy**).
Sin embargo, también puede ser un espacio de nombres reservado especialmente (por ejemplo, **/DMO/**). Además, el nombre del campo debe incluir el sufijo del campo si el proveedor lo ha especificado (en este caso, `zac`); de lo contrario, se producirá un error de sintaxis.

Ahora puedes incluir el campo adicional en la vista `include` de la extensión utilizando la palabra clave `extend view`.

``` js
extend view entity ZRAP_E_PurchaseOrder with 
{    
    PurchaseOrder.zzmy_custom_field_zac as ZzMy_Custom_Field_ZAC
}
```

Aquí haces referencia a la tabla de la base de datos y, por lo tanto, al nuevo campo `zzmy_custom_field_zac` con el alias `PurchaseOrder`, publicado a través del atributo `dataSources`.
Si el nuevo campo debe (o tiene que) guardarse con el mismo nombre (si el objeto de negocio RAP del proveedor lo permite), no puedes asignarle un nuevo nombre en este momento. Solo puedes cambiar las mayúsculas. Si el campo existe en la vista `include` de la extensión, puedes agregarlo a la entidad CDS real.

Entidad raíz CDS con la extensión de campo

``` js
extend view entity ZRAP_R_PurchaseOrder with 
 {  
    _Extension.ZzMy_Custom_Field_ZAC
 }
```

De esta manera, has agregado un campo a la entidad CDS a nivel del objeto de negocio subyacente.
La extensión de las entidades CDS correspondientes en la pila de vistas (es decir, la vista de proyección CDS o la vista de interfaz CDS) también se puede realizar utilizando la palabra clave `extend view` y el nombre del alias

Ampliar CDS de proyección

``` js
extend view entity ZRAP_C_PurchaseOrder with
{  
    PurchaseOrder.ZzMy_Custom_Field_ZAC
}
```

Por último, debes aplicar el mismo procedimiento a la vista de consulta del borrador, que volverás a ampliar mediante la función `extend view`. Usa el alias definido allí para acceder al nuevo campo en la tabla del borrador.

Ampliar la vista de borrador

``` js
extend view entity ZRAP_R_PurchaseOrderDraft with
{  
    PurchaseOrder.zzmy_custom_field_zac as ZzMy_Custom_Field_ZAC
}
```

Si implementas extensiones de campo de esta manera y a lo largo de la pila de vistas de CDS, el nuevo campo forma parte del modelo de datos transaccional del objeto de negocio RAP y está disponible allí, por ejemplo, como parte de una operación de `create`  o `update`. Se toma en cuenta tanto para el acceso local a través de EML como para el acceso remoto a través de OData.
