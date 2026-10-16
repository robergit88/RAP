# Ampliación de un objeto de negocio estándar

- [Descripción del caso de uso](#descripción-del-caso-de-uso)
- [Ampliación del modelo de datos](#ampliación-del-modelo-de-datos)
- [Ampliación del comportamiento](#ampliación-del-comportamiento)
- [Eventos derivados](#eventos-derivados)


# Descripción del caso de uso

Vamos a implementar las extensiones descritas en las siguientes secciones en un sistema SAP S/4HANA local con la versión 2023. En esta versión, SAP solo ha publicado unos pocos objetos de negocio estándar para su extensión.

Seleccionamos el modelo de datos y el comportamiento del objeto de negocio **`R_ReservationDocumentHeaderTP`**, que SAP proporciona para su ampliación. Este objeto de negocio se puede utilizar para leer, crear, actualizar y eliminar reservaciones manuales.
**El nombre de la interfaz del objeto de negocio correspondiente es `I_ReservationDocumentTP`**.
Para obtener información sobre el objeto de negocio, puedes consultar el Documento de transferencia de conocimiento (KTD) correspondiente a la interfaz de este objeto de negocio

Información sobre el objeto de negocio en el documento de transferencia de conocimiento para la interfaz del objeto de negocio

![I_ReservationDocumentTP](Extensions/img/I_RESERVATION_01.png)

![Api](./img/API_STATE.png)

La estructura del modelo de datos de este objeto de negocio se muestra en la [Figura 7.5](./img/C_RESERVATION_01.png).

**El comportamiento del objeto de negocio siempre se amplía a través de la interfaz del objeto de negocio.**

El objeto de negocio constituye la base de la aplicación `Administrar reservaciones manuales` (ID F4839).
Para probar la extensión más adelante en la aplicación, debes asignarle a tu usuario el rol `SAP_BR_WAREHOUSE_CLERK`, que autoriza la ejecución de la aplicación.
Como alternativa, también puedes ejecutar el servicio vinculado a `UI_RESERVATION_HDR_MNG_V2` con la función de vista previa de ADT para probar la aplicación.

Figura 7.5 - Estructura del modelo de datos `R_ReservationDocumentHeaderTP`

![Figura 7.5](./img/C_RESERVATION_01.png)

Puedes ver la interfaz de usuario (UI) de la aplicación para probar. Allí puedes administrar las reservaciones de forma manual, es decir, crearlas, actualizarlas y eliminarlas.

Ejecución de la función de vista previa para el enlace de servicio `UI_RESERVATION_HDR_MNG_V2`

![Figura 7.7](./img/UI_RESERVATION_01.png)

Aplicación de reservas manuales

![Figura 7.8](./img/APP_01.png)

A continuación, ampliaremos el modelo de datos para incluir un campo adicional específico del cliente. Para ello, crearemos una estructura de anexo para la tabla RKPF (cabecera de documento de reservación), que sirve como almacenamiento persistente para el objeto de negocio. Agregaremos otra validación a las validaciones del objeto de negocio que ya existen en el estándar. La extensión descrita en la sección 7.3.4 se basará en un caso de uso diferente. Se implementó en SAP S/4HANA Cloud Public Edition 2402.


# Ampliación del modelo de datos

En esta sección, agregaremos un campo Z al objeto de negocio `R_ReservationDocumentHeaderTP`. El campo debe permitir a los usuarios ingresar un texto sencillo y breve. Se supone que este texto se guardará a nivel de cabecera y se podrá actualizar en la aplicación, en el área `Reservation Details`. 

Primero, veamos si el modelo de datos cumple con los requisitos previos para dicha extensión.

**Verificación de la extensibilidad del modelo de datos**

En primer lugar, queremos verificar si se cumplen los requisitos necesarios para la ampliación de las tablas de la base de datos en cuestión. La forma más sencilla de determinar las tablas que se deben revisar (la tabla base y la tabla de borrador, ya que se trata de un objeto de negocio con funcionalidad de borrador) es revisar la definición de comportamiento del objeto de negocio base en ADT. 

Tablas de base de datos para el objeto comercial `R_ReservationDocumentHeaderTP`

![Figura 7.9](./img/R_RESERVA_01.png)

En ambas tablas, `RKPF` e `IMRS_D_DOC_HDR`, se integra la estructura de ampliación `RKPF_INCL_EEW_PS`, como se puede observar en la definición de la tabla. Al abrir la pestaña `Properties`  de esta estructura, verás que se puede ampliar con campos de tipo carácter y numéricos, y que se ha lanzado con el contrato `C0` [Figura 7.10](./img/RKPF_INCL_EEW_PS.png). Por lo tanto, a nivel de la base de datos se cumplen los requisitos previos para agregar un campo de texto adicional al objeto de negocio.

Ahora continuaremos con la revisión del modelo de datos de CDS. Para ello, debemos analizar más a fondo la entidad raíz de CDS, `R_ReservationDocumentHeaderTP`. 
Esto no está permitido explícitamente para las extensiones mediante anotaciones, pero tampoco se prohíben explícitamente las extensiones. Dado que no se han establecido anotaciones relevantes a nivel del encabezado de la vista (véanse las anotaciones comentadas en la Figura 7.11), la entidad de vista del CDS se considera extensible por defecto. Además, el estado de liberación es `C0`, por lo que el objeto de desarrollo está concebido como una API estable para ampliaciones. Además la CDS `R_ReservationDocumentHeaderTP` tiene una asociación con la vista de ampliación `E_ReservationDocument`.

Figura 7.10

Propiedades de la estructura de ampliación `RKPF_INCL_EEW_PS`

![Figura 7.10](./img/RKPF_INCL_EEW_PS.png)

Código fuente y propiedades de la CDS raíz `R_ReservationDocumentHeaderTP`

![Figura 7.11](./img/R_RESERVA_02.png)

A continuación, debemos revisar la vista de inclusión de la extensión asociada, E_ReservationDocument. Aquí encontrarás la misma situación. Es (implícitamente) extensible y también tiene el estado de lanzamiento C0

Más adelante utilizaremos la extensión `E_ReservationDocument` para incluir el campo Z adicional en otras vistas del modelo de datos del CDS. 
Estas otras vistas que se van a ampliar son las siguientes:

* `C_ReservationDocTP_F4839`

* `I_ReservationDocumentTP`

* `R_ReservationDocumentHdrDraft`

* `E_ReservationDocumentDraft`

Fragmento de código fuente y propiedades de la vista de ampliación `E_ReservationDocument`

![Figura 7.12](./img/E_ReservationDocument.png)

Los requisitos mencionados anteriormente también se cumplen de la misma manera para la ampliación de estas vistas de CDS. 

Por lo tanto, es posible ampliar todo el modelo de datos de CDS del objeto de negocio.

**Cómo agregar un campo adicional al modelo de datos**

Comenzamos agregando el campo Z adicional sobre la tabla RKPF. 
Para ello, utilizamos la estructura de inclusión `RKPF_INCL_EEW_PS`.

Primero, debes crear una estructura `append` sobre la estructura estándard:

1. Selecciona `New Append Structure` en el menú contextual de la estructura `RKPF_INCL_EEW_PS`
    
    Creación de una estructura de anexión

    ![Figura 7.13](./img/APPEND_01.png)

2. En la ventana emergente que se abre, debes ingresar un paquete y el nombre de la estructura de anexo (en este caso, es `ZZS_EXT_RAP_RKPF_F4839`) y una descripción.

    Mantenimiento de las propiedades de la estructura de anexo **`ZZS_EXT_RAP_RKPF_F4839`**

    ![Figura 7.13](./img/APPEND_02.png)

3. Puede utilizar la instrucción `extend type ... with` para agregar el campo `ZZ_TEXT_F4839`, de tipo `TEXT25`, a la estructura (véase la Figura 7.15) y, a continuación, activar la estructura.


    Figura 7.15. 
    Agregar la estructura «ZZS_EXT_RAP_RKPF_F4839» con el campo «ZZ_TEXT_F4839»

    ![Figura 7.15](./img/APPEND_03.png)

Por lo tanto, el campo está disponible en ambas tablas (la tabla base `RKPF` y la tabla de borrador `IMRS_D_DOC_HDR`).

En el siguiente paso, comenzamos a ampliar el modelo de datos del CDS. 
El primer paso consiste en ampliar la vista de inclusión de extensión
 `E_ReservationDocument`:

 1. En el menú contextual de la vista de extensión, selecciona la opción `New Data Definition` (véase la Figura 7.16) para crear una nueva definición de datos para la extensión de la vista CDS.
    
    Figura 7.16

    ![Figura 7.16](./img/APPEND_04.png)

2. En la ventana emergente que se abre, ingresa un paquete, un nombre (en este caso, `ZZ_EXT_RAP_RKPF_F4839`) y una descripción; luego, haz clic en el botón `Next` (Figura 7.17).

3. Dado que la vista `E_ReservationDocument` es una vista CDS del tipo **`DDIC-based view`**, debes seleccionar la plantilla **`extendView`** en lugar de la plantilla **`extendViewEntity`** para ampliar esta vista. Haz clic en el botón `Finish` (Figura 7.18).

    Figura 7.17

    ![Figura 7.17](./img/APPEND_05.png)

    Figura 7.18

    ![Figura 7.18](./img/APPEND_06.png)

4. Completa el código generado por la plantilla tal como se muestra en el Listado 7.30. No olvides agregar la extensión `sqlViewAppendName` a la anotación `@AbapCatalog`.
```ABAP
@AbapCatalog.sqlViewAppendName: 'ZZERRKPF4839V'
@EndUserText.label: 'RAP extension data model F4839'
extend view E_RESERVATIONDOCUMENT with ZZ_EXT_RAP_RKPF_F4839
{   
    Persistence.zz_text_f4839
}
```

5. Activar

La siguiente vista del modelo de datos que quieres expandir es la entidad raíz del CDS, `R_ReservationDocumentHeaderTP`. Selecciona `ZZ_EXT_RAP_R_RKPF_F4839` como nombre de la extensión. Esta vista y todas las vistas posteriores que se amplíen son del tipo entidad CDS. Por esta razón, debes utilizar la plantilla **`extendViewEntity`**. Completa el código generado por la plantilla de la siguiente manera:

```ABAP
extend view entity R_ReservationDocumentHeaderTP 
with
{   _Extension.zz_text_f4839
}
```

Continúa de la misma manera con la ampliación de las demás vistas CDS del modelo de datos:

*   **Ampliación del Borrador**

    *  CDS: `E_ReservationDocumentDraft`
    *  Nombre de ampliación: `ZZ_EXT_RAP_RKPF_DRAFT_F4839`
    *  Código:
    ```ABAP
    extend view entity E_ReservationDocumentDraft with
    {   
        Persistence.zz_text_f4839
    }
    ```

*   **Vista Borrador**
    *  CDS: `R_ReservationDocumentHdrDraft`
    *  Nombre de ampliación: `ZZ_EXT_RAP_R_RKPF_DRAFT_F4839`
    *  Código:
    ```ABAP
    extend view entity E_ReservationDocumentHdrDraft with
    {   
        Extension.zz_text_f4839
    }
    ```

*   Vista de consumo:
    *  CDS: `C_ReservationDocTP_F4839`
    *  Nombre de ampliación: `ZZ_EXT_RAP_C_RKPF_F4839`
    *  Código:
    ```ABAP
        extend view entity C_ReservationDocTP_f4839 with
        {  
            @UI: {    
                selectionField: [ { position: 100 } ],
                lineItem: [ { position: 100, importance: #HIGH } ]    
                fieldGroup: [ { qualifier: 'Resvn_Det',                     
                                position: 100 } ]       
                    }  
            @Consumption.filter.selectionType: #RANGE  
            _ReservationDocument.zz_text_f4389
        }
    ```

*   **Vista Interfaz**
    *  CDS: `I_ReservationDocumentTP`
    *  Nombre de ampliación: `ZZ_EXT_RAP_I_RKPF_F4839`
    *  Código:
    ```ABAP
        extend view entity I_ReservationDocumentTP with
        {   
            ReservationDocument.zz_text_f4839
        }
    ```

Ya se han implementado todas las extensiones necesarias para el campo adicional, y ya puedes probar la extensión del modelo de datos. Para ello, debes utilizar la interfaz del objeto de negocio `I_ReservationDocumentTP` para actualizar el contenido del campo adicional en instancias individuales del objeto de negocio mediante sentencias EML.

Ejemplo EML para modificar el contenido del campo adicional

```JS
CLASS zcl_test_reservation DEFINITION  
PUBLIC  
FINAL  

CREATE PUBLIC .   

PUBLIC SECTION.     

INTERFACES if_oo_adt_classrun .  
PROTECTED SECTION.  
PRIVATE SECTION.
ENDCLASS. 

CLASS zcl_test_reservation IMPLEMENTATION.

METHOD if_oo_adt_classrun~main.     

DATA rsnum TYPE rsnum VALUE '0000000101'.     

MODIFY ENTITIES OF I_ReservationDocumentTP
      ENTITY ReservationDocument      
      UPDATE      
      FIELDS ( zz_text_f4839 )      
      WITH VALUE #( ( zz_text_f4839 = 'Test EML'                                       
      %key-Reservation = rsnum ) )
FAILED   DATA(failed)      
REPORTED DATA(reported).     

COMMIT ENTITIES.

ENDMETHOD.

ENDCLASS.
```

Como alternativa, puedes probar la extensión directamente en la aplicación “Administrar reservas manuales”. El campo adicional ahora forma parte de la lista de resultados y se puede seleccionar como un filtro adicional. 

Figura 7.19

APP con el campo Z añadido

![Figura 7.19](./img/APPEND_07.png)

El contenido del nuevo campo se puede actualizar en la página del objeto

![Figura 7.20](./img/APPEND_08.png)

También puedes usar la función de vista previa para el enlace de servicio en ADT para probar la extensión. Para ello, debes llamar al enlace de servicio **`UI_Reservation_HRD_MNG_V2`** y hacer clic en el botón `Preview` 

Figura 7.21
Vista previa para el servicio `UI_Reservation_HDR_MNG_V2`

![Figura 7.21](./img/UI_RESERVATION_01.png)

# Ampliación del comportamiento

dsdwec svtgf

# Eventos derivados

cdcdsvrevrfe