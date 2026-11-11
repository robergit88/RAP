# Usando el Lenguaje de Manipulación de Entidades (EML) en ABAP


# Objetivo: Implementar sentencias EML para leer y modificar datos.

## Conceptos Clave:

###  EML: Conjunto de sentencias para manipular datos de objetos de negocio.

### READ ENTITIES: Para leer datos.
### MODIFY ENTITIES: Para actualizar, crear o eliminar datos.
### Tipos Derivados: Tipos de datos especiales usados en las tablas internas para leer y modificar datos. El sistema los crea automáticamente.
### Definición de Comportamiento: Esencial para usar CREATE, UPDATE y DELETE. La definición debe contener las directivas use create, use update o use delete correspondientes.

## Sentencia READ ENTITIES:
Requiere una tabla interna con las claves de los datos a leer (READ IMPORT).
Devuelve los resultados en otra tabla interna (READ RESULT).
Se especifica el nombre de la definición de comportamiento y el nombre de la entidad con la que se trabaja.

## Sentencia MODIFY ENTITIES:
Actualiza datos en el buffer transaccional.
Se especifica qué campos se deben cambiar en la adición FIELDS.
Se pasa la tabla interna con los datos a actualizar en la adición WITH.
Requiere la sentencia COMMIT ENTITIES para persistir los cambios en la base de datos (excepto dentro de la implementación del comportamiento del objeto de negocio).
Implementación de una Sentencia EML (Ejemplo):

El documento presenta un ejercicio para modificar el nombre de una agencia de viajes utilizando EML. Los pasos incluyen:

Análisis de Datos: Revisar los datos actuales usando la herramienta Data Preview.
Creación de una Clase Global: Crear una clase ABAP (ZCL_##_EML) que implemente IF_OO_ADT_CLASSRUN.
Actualización de Datos:
Declarar una tabla interna (agencies_upd) con el tipo derivado para actualizar la entidad /DMO/I_AgencyTP.
Llenar la tabla interna con los datos a actualizar.
Utilizar la sentencia MODIFY ENTITIES para actualizar la entidad /DMO/agency.
Utilizar COMMIT ENTITIES para confirmar los cambios.
Escribir un mensaje en la consola.
Activación y Prueba: Activar y ejecutar la clase para verificar los cambios en la base de datos.
Notas Importantes:

No se puede usar el alias del nombre de la entidad después de la adición OF.
El campo lista en la sentencia READ ENTITIES no está separado por comas.
Los campos clave siempre se llenan, incluso si no se especifican en la variante FIELDS.
Dentro de la implementación del comportamiento del objeto de negocio, no es necesario ni está permitido ejecutar COMMIT ENTITIES.