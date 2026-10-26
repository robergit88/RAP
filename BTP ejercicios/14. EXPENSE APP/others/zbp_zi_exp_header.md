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

    METHODS earlynumbering_create FOR NUMBERING
       entities FOR CREATE Header.

    METHODS earlynumbering_cba_Items FOR NUMBERING
       entities FOR CREATE Header\_Items.

ENDCLASS.

CLASS lhc_Header IMPLEMENTATION.

  METHOD get_instance_features.
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

ENDCLASS.

*CLASS lsc_ZI_EXP_HEADER DEFINITION INHERITING FROM cl_abap_behavior_saver.
*  PROTECTED SECTION.
*
**    METHODS save_modified REDEFINITION.
*
*    METHODS cleanup_finalize REDEFINITION.
*
*ENDCLASS.


*CLASS lsc_ZI_EXP_HEADER IMPLEMENTATION.
*
**  METHOD save_modified.
**  ENDMETHOD.
*
*  METHOD cleanup_finalize.
*  ENDMETHOD.
*
*ENDCLASS.
```