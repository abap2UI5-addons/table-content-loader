"! The XLSX upload: the CSV app z2ui5_cl_tcl_app_04 with the format of an
"! XLSX file (abap2xlsx)
CLASS z2ui5_cl_tcl_app_05 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_tcl_app_04.

  PUBLIC SECTION.

    " deprecated: not read or shown any more - the input that was bound to
    " it did nothing. Kept for compatibility, to be removed.
    DATA mv_tab_name TYPE string ##NEEDED.

  PROTECTED SECTION.

    METHODS get_format REDEFINITION.
    METHODS get_table_by_file REDEFINITION.
    METHODS get_file_by_table REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS z2ui5_cl_tcl_app_05 IMPLEMENTATION.


  METHOD get_format.

    result = VALUE #( name     = `XLSX`
                      title    = `abap2UI5 - XLSX Uploader`
                      mime     = `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
                      filename = `table.xlsx` ).

  ENDMETHOD.


  METHOD get_table_by_file.

    result = z2ui5_cl_tcl_xlsx_api=>get_table_by_xlsx( val ).

  ENDMETHOD.


  METHOD get_file_by_table.

    result = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( val ).

  ENDMETHOD.

ENDCLASS.
