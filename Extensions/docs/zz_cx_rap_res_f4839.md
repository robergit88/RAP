
```ABAP
CLASS zz_cx_rap_res_f4839 DEFINITION  
PUBLIC  
INHERITING FROM cx_static_check  
FINAL  
CREATE 
PUBLIC .

PUBLIC SECTION.
     
INTERFACES if_t100_message .    
INTERFACES if_t100_dyn_msg .    
INTERFACES if_abap_behv_message.

CONSTANTS: message_class TYPE symsgid VALUE 'ZZ_RAP_RES_F4839',

BEGIN OF focusproduct,        
msgid TYPE symsgid VALUE message_class,        
msgno TYPE symsgno VALUE '001',        
attr1 TYPE scx_attrname VALUE 'MV_PRODUCT',        
attr2 TYPE scx_attrname VALUE 'MV_TEXT',        
attr3 TYPE scx_attrname VALUE '',        
attr4 TYPE scx_attrname VALUE '',      
END OF focusproduct.

DATA: 
mv_product TYPE i_reservationdocumentitem-product,          
mv_text    TYPE text30.

METHODS constructor
      IMPORTING
	  !textid   LIKE if_t100_message=>t100key OPTIONAL
	  !previous LIKE previous OPTIONAL
	  severity  TYPE if_abap_behv_message=>t_severity DEFAULT

	  if_abap_behv_message=>severity-error
	  text      TYPE text30 OPTIONAL
	  product   TYPE i_reservationdocumentitem-product OPTIONAL
	  PREFERRED PARAMETER textid.

	  PROTECTED SECTION.
	  PRIVATE SECTION.

ENDCLASS.

CLASS zz_cx_rap_res_f4839 IMPLEMENTATION.

METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
	EXPORTING
	previous = previous.

	 me->if_abap_behv_message~m_severity = severity.
     me->mv_product     = product.
	 me->mv_text        = text.

CLEAR me->textid.

IF textid IS INITIAL.

if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
	if_t100_message~t100key = textid.
    ENDIF.

ENDMETHOD.

 ENDCLASS.

```