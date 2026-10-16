
```ABAP

*"* use this source file for the definition and implementation of*"* local helper classes, interface definitions and type*"* declarations

CLASS lhc_reservationdocumentheader
DEFINITION INHERITING FROM  cl_abap_behavior_handler.

PUBLIC SECTION.
     CONSTANTS validate_product TYPE string VALUE  'VALIDATE_PRODUCT'.
     "state_area
     PRIVATE SECTION.
     METHODS zzvalidateproduct FOR VALIDATE ON SAVE
     IMPORTING keys FOR reservationdocumentitem~zzvalidateproduct.
     ENDCLASS.

     CLASS lhc_reservationdocumentheader IMPLEMENTATION.
     METHOD zzvalidateproduct.
     TYPES: BEGIN OF s_focusproducts,
     product TYPE matnr,
     text    TYPE text30,
     END OF s_focusproducts.

     DATA: ls_focusproduct  TYPE s_focusproducts,
           
     lt_focusproducts TYPE STANDARD TABLE OF s_focusproducts.
     
     lt_focusproducts = VALUE #( ( product = 'AS001'   text = 'Successor product in planning')
     
     ( product = 'AS002'   text = 'Product under revision' ) ).

* get reservation document items
     READ ENTITIES OF i_reservationdocumenttp IN LOCAL MODE
     ENTITY reservationdocumentitem
     FIELDS ( product )
     WITH CORRESPONDING #( keys )
     RESULT DATA(lt_items).

     LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<lfs_res_item>)
     WHERE reservationitmismarkedfordeltn EQ abap_false
     AND reservationitemisfinallyissued EQ abap_false
     AND product IS NOT INITIAL.
     
     ls_focusproduct = VALUE #( lt_focusproducts[ product = <lfs_res_item>-Product ] OPTIONAL ).

IF ls_focusproduct IS NOT INITIAL.

        APPEND VALUE #( %tky = <lfs_res_item>-%tky
        %state_area = validate_product
        %path-reservationdocument-%is_draft = <lfs_res_item>-%is_draft
        %path-reservationdocument-reservation = <lfs_res_item>-reservation
        )
        TO reported-reservationdocumentitem.

        APPEND VALUE #( %tky = <lfs_res_item>-%tky
        %state_area = validate_product
        %msg        = NEW zz_cx_rap_res_f4839(
        textid      = zz_cx_rap_res_f4839=>focusproduct
        severity =   if_abap_behv_message=>severity-warning
        product = <lfs_res_item>-product
        text    = ls_focusproduct-text
        )
        %element-resvnitmrequiredqtyinentryunit =
        if_abap_behv=>mk-on
        %path-reservationdocument-%is_draft
        =
        <lfs_res_item>-%is_draft
        %path-reservationdocument-reservation =
        <lfs_res_item>-reservation
        )
        TO reported-reservationdocumentitem.
ENDIF.

        ENDLOOP.

        ENDMETHOD.
ENDCLASS.

```