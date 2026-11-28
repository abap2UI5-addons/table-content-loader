"! The XLSX format of the upload and the download app (05, 06): a sheet out
"! of a table, laid out by the settings and the field catalog app 06 lets
"! the user edit, and the first sheet of a file as a table. The files are
"! written and read by z2ui5_cl_tcl_xlsx - plain ABAP, no abap2xlsx - so the
"! apps run on ABAP Cloud and on 7.02 as they do on Standard ABAP.
CLASS z2ui5_cl_tcl_xlsx_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      "! a column of the sheet - a row of the field catalog
      BEGIN OF ty_s_xlsx,
        "! the field of the table - empty for a formula column
        name     TYPE string,
        "! the columns stand in the order of their positions
        position TYPE i,
        "! a column that is not visible is left out of the sheet
        visible  TYPE abap_bool,
        "! the text of the header cell - empty: the name
        header   TYPE string,
        "! the width in characters - 0: by the content
        width    TYPE i,
        "! a number format as Excel writes it (`#,##0.00`, `dd.mm.yyyy`)
        format   TYPE string,
        "! a formula instead of the field, with `{row}` for the number of
        "! its row (`C{row}*D{row}`)
        formula  TYPE string,
        "! the cell of the column in a totals row: sum, average, count,
        "! countNums, min, max, stdDev, var - or a text as a label
        total    TYPE string,
      END OF ty_s_xlsx.
    TYPES ty_t_xlsx TYPE STANDARD TABLE OF ty_s_xlsx WITH DEFAULT KEY.

    TYPES:
      "! how the sheet is laid out
      BEGIN OF ty_s_xlsx_settings,
        "! the rows as an Excel table of that style (`TableStyleMedium5`) -
        "! empty: a plain sheet
        table_style    TYPE string,
        "! the name of the Excel table - empty: Table1
        table_name     TYPE string,
        "! the cell the header row starts in - empty: A1
        start_cell     TYPE string,
        "! the stripes of the Excel table: its rows, its columns
        row_stripes    TYPE abap_bool,
        column_stripes TYPE abap_bool,
        "! filter buttons on the header row
        filter         TYPE abap_bool,
        "! the header row stays in place while the rows scroll
        freeze_header  TYPE abap_bool,
      END OF ty_s_xlsx_settings.

    "! the settings a new draft starts with: an Excel table with row
    "! stripes and filter buttons under a frozen header row
    CLASS-METHODS get_settings_default
      RETURNING
        VALUE(result) TYPE ty_s_xlsx_settings.

    "! the field catalog of a table: every elementary field in its order,
    "! visible, under the medium text of its data element where it has one
    CLASS-METHODS get_fieldcatalog
      IMPORTING
        val           TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE ty_t_xlsx.

    "! The first sheet of a file as a table of strings whose components are
    "! named after the header row. Unbound for a sheet without a cell;
    "! z2ui5_cx_tcl_error for a file that is no .xlsx workbook
    CLASS-METHODS get_table_by_xlsx
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! A workbook of one sheet with the rows of val.
    "! @parameter title        | the name of the sheet
    "! @parameter settings     | initial: get_settings_default( )
    "! @parameter fieldcatalog | initial: get_fieldcatalog( val )
    CLASS-METHODS get_xlsx_by_table
      IMPORTING
        val           TYPE ANY TABLE
        title         TYPE clike DEFAULT `Internal table`
        settings      TYPE ty_s_xlsx_settings OPTIONAL
        fieldcatalog  TYPE ty_t_xlsx OPTIONAL
      RETURNING
        VALUE(result) TYPE xstring.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS z2ui5_cl_tcl_xlsx_api IMPLEMENTATION.


  METHOD get_settings_default.

    result-table_style = `TableStyleMedium5`.
    result-row_stripes = abap_true.
    result-filter = abap_true.
    result-freeze_header = abap_true.

  ENDMETHOD.


  METHOD get_fieldcatalog.

    DATA ls_field TYPE ty_s_xlsx.

    DATA lt_comp TYPE abap_component_tab.
    DATA temp15 LIKE LINE OF lt_comp.
    DATA lr_comp LIKE REF TO temp15.
            DATA ls_text TYPE z2ui5_cl_tcl_context=>ty_s_data_element_text.
    lt_comp = z2ui5_cl_tcl_context=>rtti_get_t_attri_by_any( val ).


    LOOP AT lt_comp REFERENCE INTO lr_comp.
      " a structure, a table or a reference in a row is no column
      IF lr_comp->type->kind <> z2ui5_cl_tcl_context=>cv_typedescr_kind_elem.
        CONTINUE.
      ENDIF.

      CLEAR ls_field.
      ls_field-name = lr_comp->name.
      ls_field-position = lines( result ) + 1.
      ls_field-visible = abap_true.
      IF lr_comp->type->is_ddic_type( ) = abap_true.
        TRY.

            ls_text = z2ui5_cl_tcl_context=>rtti_get_data_element_texts(
                                lr_comp->type->get_relative_name( ) ).
            ls_field-header = ls_text-medium.
            IF ls_field-header IS INITIAL.
              ls_field-header = ls_text-long.
            ENDIF.
          CATCH cx_root ##NO_HANDLER.
            " no text to be had - the name below
        ENDTRY.
      ENDIF.
      IF ls_field-header IS INITIAL.
        ls_field-header = ls_field-name.
      ENDIF.
      INSERT ls_field INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_xlsx_by_table.

    DATA ls_layout TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.

    DATA lt_fieldcatalog LIKE fieldcatalog.
    DATA ls_settings LIKE settings.
    DATA temp16 LIKE LINE OF lt_fieldcatalog.
    DATA lr_field LIKE REF TO temp16.
      DATA temp17 TYPE z2ui5_cl_tcl_xlsx=>ty_s_column.
    DATA temp1 TYPE xsdboolean.
    DATA temp2 TYPE xsdboolean.
    lt_fieldcatalog = fieldcatalog.
    IF lt_fieldcatalog IS INITIAL.
      lt_fieldcatalog = get_fieldcatalog( val ).
    ENDIF.

    ls_settings = settings.
    IF ls_settings IS INITIAL.
      ls_settings = get_settings_default( ).
    ENDIF.

    " the columns in the order of their positions - STABLE: two with the
    " same position stay in the order of the catalog
    SORT lt_fieldcatalog STABLE BY position.


    LOOP AT lt_fieldcatalog REFERENCE INTO lr_field.
      IF lr_field->visible = abap_false.
        CONTINUE.
      ENDIF.

      CLEAR temp17.
      temp17-name = lr_field->name.
      temp17-header = lr_field->header.
      temp17-width = lr_field->width.
      temp17-format = lr_field->format.
      temp17-formula = lr_field->formula.
      temp17-total = lr_field->total.
      INSERT temp17 INTO TABLE ls_layout-t_column.
    ENDLOOP.
    IF ls_layout-t_column IS INITIAL.
      " an empty column list would be every field to the XLSX class
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `XLSX_NO_COLUMN - the field catalog shows no column`.
    ENDIF.

    ls_layout-table_style = ls_settings-table_style.
    ls_layout-table_name = ls_settings-table_name.
    ls_layout-start_cell = ls_settings-start_cell.

    temp1 = boolc( ls_settings-row_stripes = abap_false ).
    ls_layout-no_row_stripes = temp1.
    ls_layout-column_stripes = ls_settings-column_stripes.
    " the filter of the Excel table, or of the plain sheet

    temp2 = boolc( ls_settings-filter = abap_false ).
    ls_layout-no_filter = temp2.
    ls_layout-auto_filter = ls_settings-filter.
    ls_layout-freeze_header = ls_settings-freeze_header.

    result = z2ui5_cl_tcl_xlsx=>factory(
        )->add_sheet( val    = val
                      name   = title
                      layout = ls_layout
        )->get_xlsx( ).

  ENDMETHOD.


  METHOD get_table_by_xlsx.

    result = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( val )->get_table_ref( ).

  ENDMETHOD.

ENDCLASS.
