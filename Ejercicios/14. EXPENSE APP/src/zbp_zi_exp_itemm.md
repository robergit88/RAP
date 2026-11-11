# zbp_zi_exp_itemm

```ABAP
CLASS zbp_zi_exp_itemm DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zi_exp_header.
ENDCLASS.

CLASS zbp_zi_exp_itemm IMPLEMENTATION.
ENDCLASS.
```

```ABAP
CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR item RESULT result.

    METHODS updateheadertotal FOR DETERMINE ON SAVE
      keys FOR item~updateheadertotal.
    METHODS setcurrency FOR DETERMINE ON MODIFY
      keys FOR item~setcurrency.
    METHODS validateamount FOR VALIDATE ON SAVE
      keys FOR item~validateamount.
    METHODS validatehotellimit FOR VALIDATE ON SAVE
      keys FOR item~validatehotellimit.

    METHODS earlynumbering_cba_Attachments FOR NUMBERING
       entities FOR CREATE item\_Attachments.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.
  METHOD get_instance_features.
    CONSTANTS gc_open TYPE zexpense_header-header_status VALUE 'OPEN'.

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY item BY \_Header
         FIELDS ( header_status )
         WITH CORRESPONDING #( keys )
         RESULT DATA(headers)
         LINK DATA(links).

    result = VALUE #( FOR k IN keys
                      LET h  = VALUE #( headers[ KEY id
                                                 %tky = links[ source-%tky = k-%tky ]-target-%tky ] OPTIONAL )
                          st = COND #( WHEN h-header_status = gc_open
                                       THEN if_abap_behv=>fc-o-enabled
                                       ELSE if_abap_behv=>fc-o-disabled )
                      IN
                          ( %tky                = k-%tky
                            %update             = st
                            %delete             = st
                            %assoc-_Attachments = st ) ).
  ENDMETHOD.

  METHOD earlynumbering_cba_Attachments.
    DATA lv_max TYPE zitem_attachment-attach_id.

    LOOP AT entities INTO DATA(ls_parent).

      SELECT MAX( attach_id ) FROM zitem_attachment
        WHERE report_id = @ls_parent-report_id
          AND item_id   = @ls_parent-item_id
        INTO @lv_max.

      LOOP AT ls_parent-%target INTO DATA(ls_target).
        IF ls_target-attach_id IS INITIAL.
          lv_max += 1.
          APPEND VALUE #( %cid      = ls_target-%cid
                          report_id = ls_parent-report_id
                          item_id   = ls_parent-item_id
                          attach_id = lv_max ) TO mapped-attach.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD updateHeaderTotal.
    " 1. keys[] tiene las claves de registros CRUD
    "EML lee el estado “en vivo” de la transacción; SQL lee el estado “ya grabado”.

    " Un solo registro por vez: tomamos la primera clave
    READ TABLE keys INTO DATA(ls_key) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " 1) Todos los items vigentes de la carpeta
    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header BY \_Items
         FIELDS ( amount )
         WITH VALUE #( ( report_id = ls_key-report_id ) )
         RESULT DATA(lt_items).

    " 2) Suma (si no quedan items, queda en 0)
    DATA(lv_total) = REDUCE zexpense_header-total_amount(
                       INIT t TYPE zexpense_header-total_amount
                       FOR ls IN lt_items
                       NEXT t = t + ls-amount ).

    " 3) Escribir en el Header
    MODIFY ENTITIES OF zi_exp_header IN LOCAL MODE
           ENTITY Header
           UPDATE FIELDS ( total_amount )
           WITH VALUE #( ( report_id = ls_key-report_id
                           total_amount = lv_total ) )
           REPORTED DATA(lt_reported)
           " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
           FAILED   DATA(lt_failed).

    reported-header = CORRESPONDING #( DEEP lt_reported-header ).

*Las determinations no tienen el parámetro failed.
*En el método generado solo existen keys (entrada) y reported (salida).
*Una determination no puede rechazar la operación,
*a diferencia de una validation, que sí tiene failed para bloquear el guardado.
*failed-header   = CORRESPONDING #( DEEP lt_failed-header ).
  ENDMETHOD.

  METHOD setCurrency.
    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY item
         FIELDS ( currency_code )
         WITH CORRESPONDING #( keys )
         RESULT DATA(items).

    " Solo actualizar las que no estén ya en EUR
    DELETE items WHERE currency_code = 'EUR'.

    IF items IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zi_exp_header IN LOCAL MODE
           ENTITY item
           UPDATE FIELDS ( currency_code )
           WITH VALUE #( FOR i IN items
                         ( %tky          = i-%tky
                           currency_code = 'EUR' ) ).
  ENDMETHOD.

  METHOD validateAmount.

    " %tky identifica la instancia (y funciona igual con o sin draft).
    " %element-amount es lo que pinta el campo en rojo.
    " %path vincula el mensaje al informe padre, y la UI lo agrupa correctamente en una composición

    " Paso 1: Lectura de instancias que RAP pasa en keys
    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY item
         FIELDS ( amount report_id )
         WITH CORRESPONDING #( keys )
         RESULT DATA(items).

    " Paso 2: Aplicas la regla de negocio
    LOOP AT items INTO DATA(item) WHERE amount <= 0.

      " Paso 3: la instancia es inválida, no se guardará
      APPEND VALUE #( %tky = item-%tky ) TO failed-item.

      " Paso 4: mensaje + campo en rojo + contexto del padre
      APPEND VALUE #( %tky            = item-%tky
                      %path           = VALUE #( header-report_id = item-report_id )
                      %element-amount = if_abap_behv=>mk-on
                      %msg            = new_message_with_text(
                                            severity = if_abap_behv_message=>severity-error
                                            text     = |El importe debe ser mayor que 0 (recibido: { item-amount })| ) )
             TO reported-item.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateHotelLimit.

    CONSTANTS gc_hotel_type  TYPE zexpense_type            VALUE 'HOTEL'. " ajusta al tipo de dato real
    CONSTANTS gc_hotel_limit TYPE p LENGTH 8    DECIMALS 2 VALUE '150.00'.
    CONSTANTS gc_warn_ratio  TYPE p LENGTH 3    DECIMALS 2 VALUE '0.80'.

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY item
         FIELDS ( expense_type amount report_id )
         WITH CORRESPONDING #( keys )
         RESULT DATA(items).

    LOOP AT items INTO DATA(item) WHERE expense_type = gc_hotel_type.

      IF item-amount > gc_hotel_limit.

        " ERROR: bloquea el guardado
        APPEND VALUE #( %tky = item-%tky ) TO failed-item.

        APPEND VALUE #( %tky            = item-%tky
                        %element-amount = if_abap_behv=>mk-on
                        %msg            = new_message_with_text(
                                              severity = if_abap_behv_message=>severity-error
                                              text     = |El hotel supera el límite de { gc_hotel_limit } EUR| ) )
               TO reported-item.

      ELSEIF item-amount > gc_hotel_limit * gc_warn_ratio.
        " WARNING: avisa, pero NO se añade a failed, así que guarda
        APPEND VALUE #( %tky            = item-%tky
                        %element-amount = if_abap_behv=>mk-on
                        %msg            = new_message_with_text(
                                              severity = if_abap_behv_message=>severity-warning
                                              text     = |Cerca del límite de hotel ({ gc_hotel_limit } EUR)| ) )
               TO reported-item.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
```