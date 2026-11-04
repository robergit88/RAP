# zbp_zi_exp_attach

```ABAP
CLASS zbp_zi_exp_attach DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zi_exp_header.
ENDCLASS.

CLASS zbp_zi_exp_attach IMPLEMENTATION.
ENDCLASS.
```

```ABAP
CLASS lhc_attach DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR attach RESULT result.

ENDCLASS.

CLASS lhc_attach IMPLEMENTATION.

  METHOD get_instance_features.
    CONSTANTS gc_open TYPE zexpense_header-header_status VALUE 'OPEN'.

    READ ENTITIES OF zi_exp_header IN LOCAL MODE
         ENTITY attach BY \_Header
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
                          ( %tky    = k-%tky
                            %update = st
                            %delete = st ) ).
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
```