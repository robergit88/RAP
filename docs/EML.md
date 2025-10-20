# UNDERSTANDING ENTITY MANIPULATION LANGUAGE (EML)

## ¿qué es EML?
## Es parte del lenguaje ABAP y significa que hay nuevas sintaxis disponibles en ABAP para:

* Controlar el comportamiento del objeto de negocio en el ABAP SAP, utilizando el código ABAP el usuario puede manipular el objeto de negocio creado utilizando el modelo ABAP RAP

* proporciona un acceso de lectura y modificación de tipo guardado a los datos en escenarios de desarrollo transaccional.

## ¿Cómo se ve las sintaxis de EML?
### Cuando se ejecuta EML

``` mermaid js
graph
    A[Interaction Phase]

    subgraph Aqui actúa EML
        direction LR
        D[EML]
        B[Transactional Buffer]
    end

    B[Transactional Buffer] 
    C[Save sequence]

    A --> B
    B --> A
    B --> C
    C --> B

 
```
## ¿Cómo se ve las sintaxis de EML?
### EML contiene sintaxis para LEER, MODIFICAR (Crear, Actualizar, Eliminar, Ejecutar acciones) y CONFIRMAR. Veamos cada sintaxis paso a paso.

## READ ENTITIES FROM VALUE
``` abap
    read entities of ZI_RAP_Travel_1234
         entity travel
         from value #( ( traveluuid = '01B76631521D6D95190054A2FA8B1542' ) )
         result data(travels).

    out->write( travels ).
```
El primer ejemplo de EML realiza una operación de lectura.
Solo se completa el campo clave.
Esto se debe a que no se especifican los campos que deben leerse.
Las claves se proporcionan por defecto.

## READ ENTITIES FIELDS
``` abap
read entities of ZI_RAP_Travel_1234
         entity travel
         fields ( TravelID AgencyID CustomerID )
         with value #( ( traveluuid = '01B76631521D6D95190054A2FA8B1542' ) )
         result data(travels).

    out->write( travels ).
```
Ahora se llen los campos AgencyID y el CustomerID

## READ ENTITIES ALL FIELDS
```abap
read entities of ZI_RAP_Travel_1234
         entity travel
         all fields
         with value #( ( traveluuid = '01B76631521D6D95190054A2FA8B1542' ) )
         result data(travels).

    out->write( travels ).
```
utilizando ALL FIELDS se leen todos los campos de la entidad

## READ ENTITIES BY ASSOCIATION
``` abap
    read entities of ZI_RAP_Travel_1234
         entity travel by \_Booking
         all fields with value #( ( TravelUUID = '01B76631521D6D95190054A2FA8B1542' ) )
         result data(bookings).

    out->write( bookings ).
```
Lectura por asociación siguiendo la asociación definida en la definición de comportamiento.

## READ ENTITIES UNSUCCESSFUL
```abap
    read entities of ZI_RAP_Travel_1234
         entity travel
         all fields with value #( ( TravelUUID = '11111111111111111111111111111111' ) )
         result data(travels)
         failed data(failed)
         reported data(reported).

    out->write( travels ).
    out->write( failed ).    " complex structures not supported by the console output
    out->write( reported ).  " complex structures not supported by the console output
```
Al realizar operaciones de lectura de EML, no solo debe considerar la tabla de resultados,
sino también las tablas de errores y las tablas de informes.
- failed: se utiliza para indicar operaciones fallidas.
- reported: se utiliza opcionalmente para proporcionar mensajes T100 relacionados.

## MODIFY ENTITIES - CREATE
```abap
    modify entities of ZI_RAP_Travel_1234
           entity travel
           create
           set fields with value
             #( ( %cid        = 'cid1'
                  AgencyID    = '70012'
                  CustomerID  = '14'
                  BeginDate   = cl_abap_context_info=>get_system_date( )
                  EndDate     = cl_abap_context_info=>get_system_date( ) + 10
                  Description = 'NEW TRAVEL ADDED BY ROBERTO PUM!!' ) )

           mapped data(mapped)
           failed data(failed)
           reported data(reported).

    out->write( mapped-travel ).

    commit entities
           response of ZI_RAP_Travel_1234
           failed   data(failed_commit)
           reported data(reported_commit).

    out->write( 'Create done' ).
```
la instrucción MODIFY con la cláusula CREATE creará entidades nuevas.
Al finalizar se devuelve una tabla mapeada que asigna la instancia creada al ID de contenido proporcionado.

## MODIFY ENTITIES - UPDATE
```abap
modify entities of ZI_RAP_Travel_1234
           entity travel
           update
           set fields with value
             #( ( TravelUUID  = '01B76631521D6D95190054A2FA8B1542'
                  Description = 'I like RAP@openSAP' ) )
           failed data(failed)
           reported data(reported).

    " step 6b - Commit Entities. Tambien funciona con COMMIT WORK
    commit entities
           response of ZI_RAP_Travel_1234
           failed   data(failed_commit)
           reported data(reported_commit).

    out->write( 'Update done' ).
```
modificar una entidad existente.

## MODIFY ENTITIES - DELETE FROM
```abap
modify entities of ZI_RAP_Travel_1234
           entity travel
           delete from
           value
             #( ( TravelUUID  = '7E76DD340D501FE0A8D585850BB32E55' ) )
           failed data(failed)
           reported data(reported).

    commit entities
           response of ZI_RAP_Travel_1234
           failed   data(failed_commit)
           reported data(reported_commit).

    out->write( 'Delete done' ).
```
El borrado de entidades se realiza con la instrucción MODIFY ENTITIES con la cláusula DELETE.

## MODIFY ENTITIES - ACTION
```abap
modify entities of ZI_RAP_Travel_1234
           entity travel
           EXECUTE acceptTravel
           from value
             #( ( TravelUUID  = '7E76DD340D501FE0A8D585850BB32E55' ) )
           result data(result)
           mapped data(mapped)
           failed data(failed)
           reported data(reported).

    commit entities
           response of ZI_RAP_Travel_1234
           failed   data(failed_commit)
           reported data(reported_commit).

    out->write( 'Delete done' ).
```
En ABAP RAP, MODIFY ENTITIES es una sentencia EML que se utiliza para modificar entidades de objetos de negocio, y ACTION es una operación específica no estándar que se puede invocar mediante MODIFY ENTITIES para cambiar el estado de una instancia.