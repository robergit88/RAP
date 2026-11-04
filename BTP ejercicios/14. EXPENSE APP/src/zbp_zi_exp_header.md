# zbp_zi_exp_header

```ABAP
CLASS zbp_zi_exp_header DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zi_exp_header.
ENDCLASS.

CLASS zbp_zi_exp_header IMPLEMENTATION.
ENDCLASS.
```

```ABAP
CLASS lhc_Header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR Header RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR Header RESULT result.

    METHODS setStatusDefault FOR DETERMINE ON MODIFY
      keys FOR Header~setStatusDefault.

    METHODS send FOR MODIFY
      keys FOR ACTION Header~send RESULT result.
    METHODS approve FOR MODIFY
      keys FOR ACTION Header~approve RESULT result.
    METHODS reject FOR MODIFY
      keys FOR ACTION Header~reject RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
       entities FOR CREATE Header.

    METHODS earlynumbering_cba_Items FOR NUMBERING
       entities FOR CREATE Header\_Items.

ENDCLASS.

CLASS lhc_Header IMPLEMENTATION.

  METHOD get_instance_features.

    CONSTANTS gc_open TYPE zexpense_header-header_status VALUE 'OPEN'.
    CONSTANTS gc_sent TYPE zexpense_header-header_status VALUE 'SENT'.

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header
         FIELDS ( header_status )
         WITH CORRESPONDING #( keys )
         RESULT DATA(headers).

    result = VALUE #( FOR h IN headers
                      LET is_open = COND #( WHEN h-header_status = gc_open
                                            THEN if_abap_behv=>fc-o-enabled
                                            ELSE if_abap_behv=>fc-o-disabled )
                          is_sent = COND #( WHEN h-header_status = gc_sent
                                            THEN if_abap_behv=>fc-o-enabled
                                            ELSE if_abap_behv=>fc-o-disabled )
                      IN
                          ( %tky            = h-%tky
                            %action-send    = is_open
                            %action-approve = is_sent
                            %action-reject  = is_sent
                            %update         = is_open
                            %delete         = is_open
                            %assoc-_Items   = is_open ) ).
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA lv_max_report_id TYPE zexpense_header-report_id.

    SELECT MAX( report_id ) FROM zexpense_header
      INTO @lv_max_report_id.

    LOOP AT entities INTO DATA(ls).
      IF ls-report_id IS INITIAL.
        lv_max_report_id += 1.
        APPEND VALUE #( %cid      = ls-%cid
                        report_id = lv_max_report_id ) TO mapped-header.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Items.
    " entities aquí trae report_id del header + %cid + %is_draft
    " target trae los fields del item a crear
    DATA lv_max TYPE zexpense_item-item_id.

    LOOP AT entities INTO DATA(ls_parent).
      SELECT MAX( item_id ) FROM zexpense_item
        WHERE report_id = @ls_parent-report_id
        INTO @lv_max.

      LOOP AT ls_parent-%target INTO DATA(ls_target).
        IF ls_target-item_id IS INITIAL.
          lv_max += 1.
          APPEND VALUE #( %cid      = ls_target-%cid
                          report_id = ls_parent-report_id
                          item_id   = lv_max ) TO mapped-item.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD setStatusDefault.
    CONSTANTS gc_open TYPE zexpense_header-header_status VALUE 'OPEN'.
    CONSTANTS gc_eur  TYPE zexpense_header-currency_code VALUE 'EUR'.

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header
         FIELDS ( header_status currency_code )
         WITH CORRESPONDING #( keys )
         RESULT DATA(headers).

    MODIFY ENTITIES OF zi_exp_header IN LOCAL MODE
           ENTITY Header
           UPDATE FIELDS ( header_status currency_code )
           WITH VALUE #( FOR h IN headers
                         ( %tky          = h-%tky
                           header_status = gc_open
                           currency_code = gc_eur ) ).
  ENDMETHOD.

  METHOD send.
    CONSTANTS gc_open          TYPE zexpense_header-header_status VALUE 'OPEN'.
    CONSTANTS gc_sent          TYPE zexpense_header-header_status VALUE 'SENT'.
    CONSTANTS gc_receipt_limit TYPE p LENGTH 8 DECIMALS 2         VALUE '50.00'.

    DATA ok_updates TYPE TABLE FOR UPDATE zi_exp_header\\Header.

    " 1. Leer headers, items (con enlaces) y attachments (solo enlaces)
    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header
         FIELDS ( header_status )
         WITH CORRESPONDING #( keys )
         RESULT DATA(headers).

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header BY \_Items
         FIELDS ( amount )
         WITH CORRESPONDING #( headers )
         RESULT DATA(items)
         LINK DATA(header_item_links).

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY item BY \_Attachments
         FIELDS ( attach_id )
         WITH CORRESPONDING #( items )
         " TODO: variable is assigned but never used (ABAP cleaner)
         RESULT DATA(attachments)
         LINK DATA(item_attach_links).

    " 2. Comprobar precondiciones, una cadena por informe
    LOOP AT headers INTO DATA(header).

      DATA(error_text) = VALUE string( ).

      " 2a. Estado correcto
      IF header-header_status <> gc_open.
        error_text = |Solo se pueden enviar informes en estado { gc_open }|.
      ENDIF.

      " 2b. Al menos un item
      DATA(item_count) = 0.
      DATA(missing_receipts) = 0.

      LOOP AT header_item_links INTO DATA(hi_link)
           WHERE source-%tky = header-%tky.
        item_count += 1.

        ASSIGN items[ %tky = hi_link-target-%tky ] TO FIELD-SYMBOL(<item>).
        IF         sy-subrc      = 0
           AND     <item>-amount > gc_receipt_limit
           AND NOT line_exists( item_attach_links[ source-%tky = <item>-%tky ] ).
          missing_receipts += 1.
        ENDIF.
      ENDLOOP.

      IF error_text IS INITIAL AND item_count = 0.
        error_text = |El informe no tiene gastos|.
      ENDIF.

      " 2c. Recibos obligatorios
      IF error_text IS INITIAL AND missing_receipts > 0.
        error_text = |{ missing_receipts } gasto(s) de más de { gc_receipt_limit } EUR no tienen recibo|.
      ENDIF.

      " 3. Resultado
      IF error_text IS NOT INITIAL.
        APPEND VALUE #( %tky = header-%tky ) TO failed-header.
        APPEND VALUE #( %tky         = header-%tky
                        %action-send = if_abap_behv=>mk-on
                        %msg         = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                              text     = error_text ) )
               TO reported-header.
      ELSE.
        APPEND VALUE #( %tky          = header-%tky
                        header_status = gc_sent ) TO ok_updates.
      ENDIF.

    ENDLOOP.

    " 4. Cambiar estado solo de los informes válidos
    IF ok_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_exp_header IN LOCAL MODE
             ENTITY Header
             UPDATE FIELDS ( header_status )
             WITH ok_updates.
    ENDIF.

    " 5. Devolver los informes actualizados
    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(updated_headers).

    result = VALUE #( FOR u IN updated_headers
                      ( %tky = u-%tky %param = u ) ).
  ENDMETHOD.

  METHOD approve.

    CONSTANTS gc_sent     TYPE zexpense_header-header_status VALUE 'SENT'.
    CONSTANTS gc_approved TYPE zexpense_header-header_status VALUE 'APPROVED'.

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header
         FIELDS ( header_status )
         WITH CORRESPONDING #( keys )
         RESULT DATA(headers).

    " Defensa en profundidad: solo se aprueba desde SENT
    LOOP AT headers INTO DATA(ls_hdr) WHERE header_status <> gc_sent.
      APPEND VALUE #( %tky = ls_hdr-%tky ) TO failed-header.
      APPEND VALUE #( %tky            = ls_hdr-%tky
                      %action-approve = if_abap_behv=>mk-on
                      %msg            = new_message_with_text(
                                            severity = if_abap_behv_message=>severity-error
                                            text     = |Solo se pueden aprobar informes en estado { gc_sent }| ) )
             TO reported-header.
    ENDLOOP.

    DELETE headers WHERE header_status <> gc_sent.

    IF headers IS NOT INITIAL.
      MODIFY ENTITIES OF zi_exp_header IN LOCAL MODE
             ENTITY Header
             UPDATE FIELDS ( header_status )
             WITH VALUE #( FOR h IN headers
                           ( %tky = h-%tky header_status = gc_approved ) ).
    ENDIF.

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(updated).

    result = VALUE #( FOR u IN updated
                      ( %tky = u-%tky %param = u ) ).
  ENDMETHOD.

  METHOD reject.

    CONSTANTS gc_sent     TYPE zexpense_header-header_status VALUE 'SENT'.
    CONSTANTS gc_rejected TYPE zexpense_header-header_status VALUE 'REJECTED'.

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header
         FIELDS ( header_status )
         WITH CORRESPONDING #( keys )
         RESULT DATA(headers).

    LOOP AT headers INTO DATA(ls_hdr).

      " El motivo viaja en %param de la entrada correspondiente
      DATA(lv_reason) = VALUE string( ).
      ASSIGN keys[ KEY entity
                   %tky = ls_hdr-%tky ] TO FIELD-SYMBOL(<key>).
      IF sy-subrc = 0.
        lv_reason = condense( <key>-%param-reason ).
      ENDIF.

      DATA(lv_error) = VALUE string( ).
      IF ls_hdr-header_status <> gc_sent.
        lv_error = |Solo se pueden rechazar informes en estado { gc_sent }|.
      ELSEIF strlen( lv_reason ) < 10.
        lv_error = |El motivo del rechazo debe tener al menos 10 caracteres|.
      ENDIF.

      IF lv_error IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_hdr-%tky ) TO failed-header.
        APPEND VALUE #( %tky           = ls_hdr-%tky
                        %action-reject = if_abap_behv=>mk-on
                        %msg           = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                                text     = lv_error ) )
               TO reported-header.
      ELSE.
        MODIFY ENTITIES OF zi_exp_header IN LOCAL MODE
               ENTITY Header
               UPDATE FIELDS ( header_status reject_reason )
               WITH VALUE #( ( %tky          = ls_hdr-%tky
                               header_status = gc_rejected
                               reject_reason = lv_reason ) ).
      ENDIF.

    ENDLOOP.

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY Header
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(updated).

    result = VALUE #( FOR u IN updated
                      ( %tky = u-%tky %param = u ) ).
  ENDMETHOD.

ENDCLASS.
```