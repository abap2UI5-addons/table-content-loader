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
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

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
    result = VALUE #( ( carrid = `LH` connid = `0400` fldate = `20260105` price = `100.50` seats = 10 )
                      ( carrid = `AA` connid = `0017` fldate = `20260106` price = `200.00` seats = 20 ) ).
  ENDMETHOD.

  METHOD part.
    DATA(lt_file) = z2ui5_cl_tcl_context=>zip_unpack( file ).
    LOOP AT lt_file INTO DATA(ls_file).
      IF ls_file-name = name.
        result = z2ui5_cl_tcl_context=>conv_get_string_by_xstring( ls_file-content ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD fieldcatalog_of_a_table.
    DATA(lt_fcat) = z2ui5_cl_tcl_xlsx_api=>get_fieldcatalog( rows( ) ).

    " every elementary field in its order, visible, under its name - the
    " table in the row is no column
    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = lines( lt_fcat ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = VALUE z2ui5_cl_tcl_xlsx_api=>ty_s_xlsx( name = `CARRID` position = 1 visible = abap_true header = `CARRID` )
        act = lt_fcat[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = `SEATS`
                                        act = lt_fcat[ 5 ]-name ).
    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = lt_fcat[ 5 ]-position ).
  ENDMETHOD.

  METHOD default_is_an_excel_table.
    " no settings, no catalog: every field, as an Excel table with row
    " stripes and filter buttons under a frozen header row
    DATA(lv_file) = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( val   = rows( )
                                                               title = `Flights` ).

    cl_abap_unit_assert=>assert_true( xsdbool( part( file = lv_file
                                                     name = `xl/workbook.xml` ) CS `<sheet name="Flights"` ) ).
    DATA(lv_table) = part( file = lv_file
                           name = `xl/tables/table1.xml` ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_table CS ` ref="A1:E3"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_table CS `<autoFilter ref="A1:E3"/>` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_table CS `<tableStyleInfo name="TableStyleMedium5"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_table CS `showRowStripes="1" showColumnStripes="0"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( part( file = lv_file
                                                     name = `xl/worksheets/sheet1.xml` ) CS `<pane ySplit="1"` ) ).
  ENDMETHOD.

  METHOD settings_lay_out_the_sheet.
    DATA(lv_file) = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table(
        val      = rows( )
        settings = VALUE #( table_style    = `TableStyleLight9`
                            table_name     = `Flights`
                            start_cell     = `B2`
                            column_stripes = abap_true ) ).

    " the table named and placed, without row stripes and filter buttons,
    " the header row not frozen - what the settings leave off is off
    DATA(lv_table) = part( file = lv_file
                           name = `xl/tables/table1.xml` ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_table CS `name="Flights" displayName="Flights" ref="B2:F4"` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_table CS `<autoFilter` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_table CS `showRowStripes="0" showColumnStripes="1"` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( part( file = lv_file
                                                      name = `xl/worksheets/sheet1.xml` ) CS `<pane` ) ).

    " without a table style a plain sheet, with the filter on its header
    lv_file = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( val      = rows( )
                                                        settings = VALUE #( filter = abap_true ) ).
    cl_abap_unit_assert=>assert_initial( part( file = lv_file
                                               name = `xl/tables/table1.xml` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( part( file = lv_file
                                                     name = `xl/worksheets/sheet1.xml` ) CS `<autoFilter ref="A1:E3"/>` ) ).
  ENDMETHOD.

  METHOD catalog_picks_the_columns.
    " the visible columns in the order of their positions, under their
    " headers, with a formula column and a totals row
    DATA(lv_file) = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table(
        val          = rows( )
        fieldcatalog = VALUE #( ( name = `SEATS` position = 3 visible = abap_true header = `Seats` total = `sum` )
                                ( name = `CARRID` position = 1 visible = abap_true header = `Airline` total = `Total` )
                                ( name = `CONNID` position = 2 )
                                ( name = `PRICE` position = 2 visible = abap_true format = `#,##0.00` width = 14 )
                                ( position = 4 visible = abap_true header = `Revenue` formula = `B{row}*C{row}`
                                  total = `sum` ) ) ).

    DATA(lv_sheet) = part( file = lv_file
                           name = `xl/worksheets/sheet1.xml` ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_sheet CS `<dimension ref="A1:D4"/>` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_sheet CS `>Airline</t>` ) ).
    " a header left empty is the name of the field
    cl_abap_unit_assert=>assert_true( xsdbool( lv_sheet CS `>PRICE</t>` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_sheet CS `CONNID` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_sheet CS `<c r="B2" s="1"><v>100.50</v></c><c r="C2"><v>10</v></c>` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_sheet CS `<f>B2*C2</f>` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_sheet CS `<col min="2" max="2" width="14" customWidth="1"/>` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_sheet CS `<f>SUBTOTAL(109,Table1[Seats])</f><v>30</v>` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( part( file = lv_file
                                                     name = `xl/tables/table1.xml` )
                                               CS `<tableColumn id="1" name="Airline" totalsRowLabel="Total"/>` ) ).
  ENDMETHOD.

  METHOD no_visible_column.
    TRY.
        z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( val          = rows( )
                                                  fieldcatalog = VALUE #( ( name = `CARRID` position = 1 ) ) ).
        cl_abap_unit_assert=>fail( `a catalog that shows no column has to raise` ).
      CATCH z2ui5_cx_tcl_error INTO DATA(x).
        cl_abap_unit_assert=>assert_true( xsdbool( x->get_text( ) CS `XLSX_NO_COLUMN` ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD file_back_as_a_table.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    " the upload: the first sheet as a table of strings, its columns
    " named after the header row
    DATA(lr_tab) = z2ui5_cl_tcl_xlsx_api=>get_table_by_xlsx( z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( rows( ) ) ).
    ASSIGN lr_tab->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( <tab> ) ).

    ASSIGN <tab>[ 1 ] TO FIELD-SYMBOL(<row>).
    ASSIGN COMPONENT `CONNID` OF STRUCTURE <row> TO FIELD-SYMBOL(<connid>).
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `0400`
                                        act = <connid> ).
    ASSIGN COMPONENT `FLDATE` OF STRUCTURE <row> TO FIELD-SYMBOL(<fldate>).
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-05`
                                        act = <fldate> ).
    ASSIGN COMPONENT `PRICE` OF STRUCTURE <row> TO FIELD-SYMBOL(<price>).
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `100.5`
                                        act = <price> ).
  ENDMETHOD.

  METHOD no_workbook.
    TRY.
        z2ui5_cl_tcl_xlsx_api=>get_table_by_xlsx( CONV xstring( `48656C6C6F` ) ).
        cl_abap_unit_assert=>fail( `a file that is no workbook has to raise` ).
      CATCH z2ui5_cx_tcl_error INTO DATA(x).
        cl_abap_unit_assert=>assert_true( xsdbool( x->get_text( ) CS `XLSX_NO_WORKBOOK` ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
