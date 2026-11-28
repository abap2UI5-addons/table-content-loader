CLASS ltcl_unit_test DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_s_row,
        carrid TYPE c LENGTH 3,
        connid TYPE n LENGTH 4,
        fldate TYPE d,
        price  TYPE p LENGTH 8 DECIMALS 2,
        seats  TYPE i,
        sub    TYPE string_table,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    METHODS rows
      RETURNING
        VALUE(result) TYPE ty_t_row.

    "! the text of a part of a workbook
    METHODS part
      IMPORTING
        file          TYPE xstring
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS fieldcatalog_of_a_table  FOR TESTING RAISING cx_static_check.
    METHODS default_is_an_excel_table FOR TESTING RAISING cx_static_check.
    METHODS settings_lay_out_the_sheet FOR TESTING RAISING cx_static_check.
    METHODS catalog_picks_the_columns FOR TESTING RAISING cx_static_check.
    METHODS no_visible_column        FOR TESTING RAISING cx_static_check.
    METHODS file_back_as_a_table     FOR TESTING RAISING cx_static_check.
    METHODS no_workbook              FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_unit_test IMPLEMENTATION.

  METHOD rows.
    DATA temp1 TYPE ltcl_unit_test=>ty_t_row.
    DATA temp2 LIKE LINE OF temp1.
    CLEAR temp1.

    temp2-carrid = `LH`.
    temp2-connid = `0400`.
    temp2-fldate = `20260105`.
    temp2-price = `100.50`.
    temp2-seats = 10.
    INSERT temp2 INTO TABLE temp1.
    temp2-carrid = `AA`.
    temp2-connid = `0017`.
    temp2-fldate = `20260106`.
    temp2-price = `200.00`.
    temp2-seats = 20.
    INSERT temp2 INTO TABLE temp1.
    result = temp1.
  ENDMETHOD.

  METHOD part.
    DATA lt_file TYPE z2ui5_cl_tcl_context=>ty_t_zip_file.
    DATA ls_file LIKE LINE OF lt_file.
    lt_file = z2ui5_cl_tcl_context=>zip_unpack( file ).

    LOOP AT lt_file INTO ls_file.
      IF ls_file-name = name.
        result = z2ui5_cl_tcl_context=>conv_get_string_by_xstring( ls_file-content ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD fieldcatalog_of_a_table.
    DATA lt_fcat TYPE z2ui5_cl_tcl_xlsx_api=>ty_t_xlsx.
    DATA temp3 TYPE z2ui5_cl_tcl_xlsx_api=>ty_s_xlsx.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_fcat.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp4> LIKE LINE OF lt_fcat.
    DATA temp5 LIKE sy-tabix.
    FIELD-SYMBOLS <temp6> LIKE LINE OF lt_fcat.
    DATA temp7 LIKE sy-tabix.
    lt_fcat = z2ui5_cl_tcl_xlsx_api=>get_fieldcatalog( rows( ) ).

    " every elementary field in its order, visible, under its name - the
    " table in the row is no column
    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = lines( lt_fcat ) ).

    CLEAR temp3.
    temp3-name = `CARRID`.
    temp3-position = 1.
    temp3-visible = abap_true.
    temp3-header = `CARRID`.


    temp2 = sy-tabix.
    READ TABLE lt_fcat INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        exp = temp3
        act = <temp1> ).


    temp5 = sy-tabix.
    READ TABLE lt_fcat INDEX 5 ASSIGNING <temp4>.
    sy-tabix = temp5.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `SEATS`
                                        act = <temp4>-name ).


    temp7 = sy-tabix.
    READ TABLE lt_fcat INDEX 5 ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = <temp6>-position ).
  ENDMETHOD.

  METHOD default_is_an_excel_table.
    " no settings, no catalog: every field, as an Excel table with row
    " stripes and filter buttons under a frozen header row
    DATA lv_file TYPE xstring.
    DATA temp1 TYPE xsdboolean.
    DATA lv_table TYPE string.
    DATA temp2 TYPE xsdboolean.
    DATA temp3 TYPE xsdboolean.
    DATA temp4 TYPE xsdboolean.
    DATA temp5 TYPE xsdboolean.
    DATA temp6 TYPE xsdboolean.
    lv_file = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( val   = rows( )
                                                               title = `Flights` ).


    temp1 = boolc( part( file = lv_file name = `xl/workbook.xml` ) CS `<sheet name="Flights"` ).
    cl_abap_unit_assert=>assert_true( temp1 ).

    lv_table = part( file = lv_file
                           name = `xl/tables/table1.xml` ).

    temp2 = boolc( lv_table CS ` ref="A1:E3"` ).
    cl_abap_unit_assert=>assert_true( temp2 ).

    temp3 = boolc( lv_table CS `<autoFilter ref="A1:E3"/>` ).
    cl_abap_unit_assert=>assert_true( temp3 ).

    temp4 = boolc( lv_table CS `<tableStyleInfo name="TableStyleMedium5"` ).
    cl_abap_unit_assert=>assert_true( temp4 ).

    temp5 = boolc( lv_table CS `showRowStripes="1" showColumnStripes="0"` ).
    cl_abap_unit_assert=>assert_true( temp5 ).

    temp6 = boolc( part( file = lv_file name = `xl/worksheets/sheet1.xml` ) CS `<pane ySplit="1"` ).
    cl_abap_unit_assert=>assert_true( temp6 ).
  ENDMETHOD.

  METHOD settings_lay_out_the_sheet.
    DATA temp8 TYPE z2ui5_cl_tcl_xlsx_api=>ty_s_xlsx_settings.
    DATA lv_file TYPE xstring.
    DATA lv_table TYPE string.
    DATA temp7 TYPE xsdboolean.
    DATA temp10 TYPE xsdboolean.
    DATA temp11 TYPE xsdboolean.
    DATA temp12 TYPE xsdboolean.
    DATA temp9 TYPE z2ui5_cl_tcl_xlsx_api=>ty_s_xlsx_settings.
    DATA temp13 TYPE xsdboolean.
    CLEAR temp8.
    temp8-table_style = `TableStyleLight9`.
    temp8-table_name = `Flights`.
    temp8-start_cell = `B2`.
    temp8-column_stripes = abap_true.

    lv_file = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table(
        val      = rows( )
        settings = temp8 ).

    " the table named and placed, without row stripes and filter buttons,
    " the header row not frozen - what the settings leave off is off

    lv_table = part( file = lv_file
                           name = `xl/tables/table1.xml` ).

    temp7 = boolc( lv_table CS `name="Flights" displayName="Flights" ref="B2:F4"` ).
    cl_abap_unit_assert=>assert_true( temp7 ).

    temp10 = boolc( lv_table CS `<autoFilter` ).
    cl_abap_unit_assert=>assert_false( temp10 ).

    temp11 = boolc( lv_table CS `showRowStripes="0" showColumnStripes="1"` ).
    cl_abap_unit_assert=>assert_true( temp11 ).

    temp12 = boolc( part( file = lv_file name = `xl/worksheets/sheet1.xml` ) CS `<pane` ).
    cl_abap_unit_assert=>assert_false( temp12 ).

    " without a table style a plain sheet, with the filter on its header

    CLEAR temp9.
    temp9-filter = abap_true.
    lv_file = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( val      = rows( )
                                                        settings = temp9 ).
    cl_abap_unit_assert=>assert_initial( part( file = lv_file
                                               name = `xl/tables/table1.xml` ) ).

    temp13 = boolc( part( file = lv_file name = `xl/worksheets/sheet1.xml` ) CS `<autoFilter ref="A1:E3"/>` ).
    cl_abap_unit_assert=>assert_true( temp13 ).
  ENDMETHOD.

  METHOD catalog_picks_the_columns.
    " the visible columns in the order of their positions, under their
    " headers, with a formula column and a totals row
    DATA temp10 TYPE z2ui5_cl_tcl_xlsx_api=>ty_t_xlsx.
    DATA temp11 LIKE LINE OF temp10.
    DATA lv_file TYPE xstring.
    DATA lv_sheet TYPE string.
    DATA temp14 TYPE xsdboolean.
    DATA temp15 TYPE xsdboolean.
    DATA temp16 TYPE xsdboolean.
    DATA temp17 TYPE xsdboolean.
    DATA temp18 TYPE xsdboolean.
    DATA temp19 TYPE xsdboolean.
    DATA temp20 TYPE xsdboolean.
    DATA temp21 TYPE xsdboolean.
    DATA temp22 TYPE xsdboolean.
    CLEAR temp10.

    CLEAR temp11.
    temp11-name = `SEATS`.
    temp11-position = 3.
    temp11-visible = abap_true.
    temp11-header = `Seats`.
    temp11-total = `sum`.
    INSERT temp11 INTO TABLE temp10.
    CLEAR temp11.
    temp11-name = `CARRID`.
    temp11-position = 1.
    temp11-visible = abap_true.
    temp11-header = `Airline`.
    temp11-total = `Total`.
    INSERT temp11 INTO TABLE temp10.
    CLEAR temp11.
    temp11-name = `CONNID`.
    temp11-position = 2.
    INSERT temp11 INTO TABLE temp10.
    CLEAR temp11.
    temp11-name = `PRICE`.
    temp11-position = 2.
    temp11-visible = abap_true.
    temp11-format = `#,##0.00`.
    temp11-width = 14.
    INSERT temp11 INTO TABLE temp10.
    CLEAR temp11.
    temp11-position = 4.
    temp11-visible = abap_true.
    temp11-header = `Revenue`.
    temp11-formula = `B{row}*C{row}`.
    temp11-total = `sum`.
    INSERT temp11 INTO TABLE temp10.

    lv_file = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table(
        val          = rows( )
        fieldcatalog = temp10 ).


    lv_sheet = part( file = lv_file
                           name = `xl/worksheets/sheet1.xml` ).

    temp14 = boolc( lv_sheet CS `<dimension ref="A1:D4"/>` ).
    cl_abap_unit_assert=>assert_true( temp14 ).

    temp15 = boolc( lv_sheet CS `>Airline</t>` ).
    cl_abap_unit_assert=>assert_true( temp15 ).
    " a header left empty is the name of the field

    temp16 = boolc( lv_sheet CS `>PRICE</t>` ).
    cl_abap_unit_assert=>assert_true( temp16 ).

    temp17 = boolc( lv_sheet CS `CONNID` ).
    cl_abap_unit_assert=>assert_false( temp17 ).

    temp18 = boolc( lv_sheet CS `<c r="B2" s="1"><v>100.50</v></c><c r="C2"><v>10</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp18 ).

    temp19 = boolc( lv_sheet CS `<f>B2*C2</f>` ).
    cl_abap_unit_assert=>assert_true( temp19 ).

    temp20 = boolc( lv_sheet CS `<col min="2" max="2" width="14" customWidth="1"/>` ).
    cl_abap_unit_assert=>assert_true( temp20 ).

    temp21 = boolc( lv_sheet CS `<f>SUBTOTAL(109,Table1[Seats])</f><v>30</v>` ).
    cl_abap_unit_assert=>assert_true( temp21 ).

    temp22 = boolc( part( file = lv_file name = `xl/tables/table1.xml` ) CS `<tableColumn id="1" name="Airline" totalsRowLabel="Total"/>` ).
    cl_abap_unit_assert=>assert_true( temp22 ).
  ENDMETHOD.

  METHOD no_visible_column.
        DATA temp12 TYPE z2ui5_cl_tcl_xlsx_api=>ty_t_xlsx.
        DATA temp13 LIKE LINE OF temp12.
        DATA x TYPE REF TO z2ui5_cx_tcl_error.
        DATA temp23 TYPE xsdboolean.
    TRY.

        CLEAR temp12.

        temp13-name = `CARRID`.
        temp13-position = 1.
        INSERT temp13 INTO TABLE temp12.
        z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( val          = rows( )
                                                  fieldcatalog = temp12 ).
        cl_abap_unit_assert=>fail( `a catalog that shows no column has to raise` ).

      CATCH z2ui5_cx_tcl_error INTO x.

        temp23 = boolc( x->get_text( ) CS `XLSX_NO_COLUMN` ).
        cl_abap_unit_assert=>assert_true( temp23 ).
    ENDTRY.
  ENDMETHOD.

  METHOD file_back_as_a_table.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    " the upload: the first sheet as a table of strings, its columns
    " named after the header row
    DATA lr_tab TYPE REF TO data.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <connid> TYPE any.
    FIELD-SYMBOLS <fldate> TYPE any.
    FIELD-SYMBOLS <price> TYPE any.
    lr_tab = z2ui5_cl_tcl_xlsx_api=>get_table_by_xlsx( z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( rows( ) ) ).
    ASSIGN lr_tab->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( <tab> ) ).


    READ TABLE <tab> INDEX 1 ASSIGNING <row>.

    ASSIGN COMPONENT `CONNID` OF STRUCTURE <row> TO <connid>.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `0400`
                                        act = <connid> ).

    ASSIGN COMPONENT `FLDATE` OF STRUCTURE <row> TO <fldate>.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-05`
                                        act = <fldate> ).

    ASSIGN COMPONENT `PRICE` OF STRUCTURE <row> TO <price>.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `100.5`
                                        act = <price> ).
  ENDMETHOD.

  METHOD no_workbook.
        DATA temp14 TYPE xstring.
        DATA x TYPE REF TO z2ui5_cx_tcl_error.
        DATA temp24 TYPE xsdboolean.
    TRY.

        temp14 = `48656C6C6F`.
        z2ui5_cl_tcl_xlsx_api=>get_table_by_xlsx( temp14 ).
        cl_abap_unit_assert=>fail( `a file that is no workbook has to raise` ).

      CATCH z2ui5_cx_tcl_error INTO x.

        temp24 = boolc( x->get_text( ) CS `XLSX_NO_WORKBOOK` ).
        cl_abap_unit_assert=>assert_true( temp24 ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
