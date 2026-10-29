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

    METHODS earlynumbering_cba_Attachments FOR NUMBERING
       entities FOR CREATE item\_Attachments.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD get_instance_features.
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

ENDCLASS.
```