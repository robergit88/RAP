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

ENDCLASS.
```