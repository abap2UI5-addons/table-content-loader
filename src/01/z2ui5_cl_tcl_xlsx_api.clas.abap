CLASS z2ui5_cl_tcl_xlsx_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES ty_t_xlsx TYPE zexcel_t_fieldcatalog.
    TYPES ty_s_xlsx_settings TYPE zexcel_s_table_settings.

    CLASS-METHODS get_table_by_xlsx
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE REF TO data.

    CLASS-METHODS get_xlsx_by_table
      IMPORTING
        val           TYPE any
        title         TYPE clike DEFAULT `Internal table`
        settings      TYPE ty_s_xlsx_settings OPTIONAL
        fieldcatalog  TYPE ty_t_xlsx OPTIONAL
      RETURNING
        VALUE(result) TYPE xstring.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS z2ui5_cl_tcl_xlsx_api IMPLEMENTATION.


  METHOD get_xlsx_by_table.

    DATA: lo_excel     TYPE REF TO zcl_excel,
          lo_writer    TYPE REF TO zif_excel_writer,
          lo_worksheet TYPE REF TO zcl_excel_worksheet.

    DATA: lt_field_catalog  TYPE zexcel_t_fieldcatalog,
          ls_table_settings TYPE zexcel_s_table_settings.


    " Creates active sheet
    CREATE OBJECT lo_excel.

    " Get active sheet
    lo_worksheet = lo_excel->get_active_worksheet( ).
    lo_worksheet->set_title( CONV #( title ) ).

    lt_field_catalog = fieldcatalog.
    IF lt_field_catalog IS INITIAL.
      lt_field_catalog = zcl_excel_common=>get_fieldcatalog( val ).
    ENDIF.

    ls_table_settings = settings.
    IF ls_table_settings IS INITIAL.
      ls_table_settings-table_style = zcl_excel_table=>builtinstyle_medium5.
    ENDIF.

    lo_worksheet->bind_table( ip_table          = val
                              is_table_settings = ls_table_settings
                              it_field_catalog  = lt_field_catalog ).

    lo_worksheet->freeze_panes( ip_num_rows = 1 ).

    CREATE OBJECT lo_writer TYPE zcl_excel_writer_2007.
    result = lo_writer->write_file( lo_excel ).


  ENDMETHOD.

  METHOD get_table_by_xlsx.

    DATA: lo_excel     TYPE REF TO zcl_excel,
          lo_reader    TYPE REF TO zif_excel_reader,
          lo_worksheet TYPE REF TO zcl_excel_worksheet.

    CREATE OBJECT lo_reader TYPE zcl_excel_reader_2007.
    lo_excel = lo_reader->load( val ).
    lo_worksheet = lo_excel->get_worksheet_by_index( 1 ).
    lo_worksheet->convert_to_table(
      IMPORTING
        er_data          = result
    ).

  ENDMETHOD.

ENDCLASS.
