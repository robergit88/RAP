# Extensibilidad de los objetos de negocio

## Introducción al concepto de extensibilidad

El concepto de extensión del modelo de programación de aplicaciones ABAP RESTful tiene las siguientes propiedades:

* **Los objetos de negocio RAP no son extensibles por defecto**

Un objeto de negocio RAP no es extensible por defecto y, por lo tanto, debe marcarse explícitamente como extensible mediante las palabras clave adecuadas en los puntos previstos para tal fin. Solo entonces un consumidor podrá realizar extensiones.

* **Puntos de extensión previstos**

Los campos con propiedades y asignación de campos, determinaciones, validaciones u operaciones específicas pueden implementarse como puntos de extensión si el objeto de negocio RAP permite una extensión correspondiente.

* **Estabilidad del ciclo de vida**

Si un objeto de negocio RAP ofrece extensibilidad, celebra un contrato público (contrato de lanzamiento C0) con los consumidores. Todas las extensiones potencialmente implementadas deben seguir funcionando incluso después de una actualización del objeto de negocio RAP del proveedor. Por este motivo, los puntos de extensión forman parte de la interfaz pública de un objeto de negocio RAP y, una vez publicados, deben mantenerse compatibles con los consumidores de dichos puntos.

* **extensiones aisladas**

Las extensiones para un objeto de negocio RAP son autónomas y pueden proporcionarse de forma aislada. Para un objeto de negocio RAP, puede desarrollar diferentes extensiones de forma independiente.

* **La funcionalidad existente no se puede sobrescribir**

La funcionalidad existente de un objeto de negocio RAP no se puede sobrescribir con una extensión.

* **Capas de extensión**

Las extensiones pueden declararse como extensibles y formar una cascada de extensiones. De este modo, una nueva extensión puede extender una extensión existente. Por ejemplo, un producto de software de un socio de SAP podría extender significativamente un objeto de negocio RAP del sistema SAP estándar. La extensión dentro del producto de software del socio podría, a su vez, ser extendida por los clientes del socio.

* **Extensiones como parte del objeto de negocio RAP**

Las extensiones a un objeto de negocio RAP se convierten en parte habitual del objeto de negocio RAP extendido en el diseño y en tiempo de ejecución. Las validaciones añadidas, por ejemplo, se convierten en parte habitual de la secuencia de guardado temprano.

Como ya se mencionó, los objetos de negocio RAP deben liberarse específicamente para que los usuarios puedan extenderlos. La liberación de los objetos de desarrollo se realiza a través de la interfaz de programación de aplicaciones (API) de los objetos de desarrollo en las herramientas de desarrollo ABAP (ADT).

Esto comprende un conjunto de contratos de lanzamiento (o contratos, para abreviar) compatibles con el objeto de desarrollo. Para que un objeto de desarrollo sea extensible a través de software, debe haberse especificado con el contrato C0 (extender).

Recomendamos la asignación específica del contrato C0 para aquellos objetos de desarrollo de un objeto de negocio RAP que deban ser extensibles.

Por otro lado, el contrato C1 (uso interno del sistema) permite el uso del objeto de desarrollo para una interfaz de objeto de negocio, por ejemplo, que se pueda llamar a través del lenguaje de manipulación de entidades (EML).

En ADT, puede mantener el contrato a través de la vista Propiedades del objeto de desarrollo en la pestaña `API State` tab.

![Api](./img/API_STATE.png)

## ABAP RESTful ofrece las siguientes opciones de extensión:

* **Extensibilidad del modelo de datos**

La extensibilidad del modelo de datos incluye la extensión de campos a nivel de base de datos y a nivel de las entidades de CDS del árbol de composición de objetos de negocio. También incluye la adición de asociaciones.

* **Extensibilidad del comportamiento**

La extensibilidad del objeto comportamiento incluye determinaciones, validaciones u operaciones específicas adicionales.

* **Extensibilidad con entidades CDS adicionales**

Finalmente, es posible definir la extensibilidad de entidades CDS adicionales dentro del árbol de composición de objetos de negocio, lo que también incluye el comportamiento de estas entidades. Para este escenario, se ha establecido el término extensibilidad de nodo.

## Opciones de Extensión

### Extensiones al modelo de datos

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

Se recomienda crear una inclusión de extensión separada como punto de extensión para mantener los campos de extensión en un objeto de desarrollo separado.
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

Si hay varias extensiones (es decir, varias estructuras de apéndice) para una inclusión de extensión, los nombres de los campos agregados pueden entrar en conflicto, por ejemplo, si las extensiones se crean e instalan en diferentes sistemas fuente. Para evitar tales conflictos de nombres o reducir su probabilidad, puede especificar un campo `sufijo` utilizando la anotación

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

De forma similar a la creación del inclusión de extensión, se recomienda que también se cree una vista de inclusión de extensión para el modelo de datos, en la que se declaren los campos adicionales de la entidad CDS.
Un ejemplo de dicha extensión:

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