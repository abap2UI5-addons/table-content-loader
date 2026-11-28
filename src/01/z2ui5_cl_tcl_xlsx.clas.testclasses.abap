"! what the tests share: a part of a written file as text, and a workbook put
"! together by hand the way another program writes it
CLASS ltcl_file DEFINITION FOR TESTING.

  PUBLIC SECTION.

    CONSTANTS cv_main TYPE string VALUE `http://schemas.openxmlformats.org/spreadsheetml/2006/main`.
    CONSTANTS cv_rel  TYPE string VALUE `http://schemas.openxmlformats.org/officeDocument/2006/relationships`.
    CONSTANTS cv_pkg  TYPE string VALUE `http://schemas.openxmlformats.org/package/2006/relationships`.

    CLASS-METHODS part
      IMPORTING
        file          TYPE xstring
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS has_part
      IMPORTING
        file          TYPE xstring
        name          TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! a workbook of one sheet `Data`: the rows of its sheetData, the si
    "! elements of its shared strings, the content of its styleSheet
    CLASS-METHODS pack
      IMPORTING
        rows          TYPE string
        shared        TYPE string OPTIONAL
        styles        TYPE string OPTIONAL
        workbook_pr   TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE xstring.

ENDCLASS.

CLASS ltcl_file IMPLEMENTATION.

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

  METHOD has_part.
    DATA lt_file TYPE z2ui5_cl_tcl_context=>ty_t_zip_file.
    DATA temp1 LIKE sy-subrc.
    DATA temp2 TYPE xsdboolean.
    lt_file = z2ui5_cl_tcl_context=>zip_unpack( file ).

    READ TABLE lt_file WITH KEY name = name TRANSPORTING NO FIELDS.
    temp1 = sy-subrc.

    temp2 = boolc( temp1 = 0 ).
    result = temp2.
  ENDMETHOD.

  METHOD pack.
    DATA lv_head TYPE string.
    DATA temp2 TYPE z2ui5_cl_tcl_context=>ty_t_zip_file.
    DATA temp3 LIKE LINE OF temp2.
    DATA lt_file LIKE temp2.
      DATA temp4 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.
      DATA temp5 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.
    lv_head = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`.
    " as Excel writes it: indented, the document named from the root of the
    " package, the sheet under an id that is not its position

    CLEAR temp2.

    temp3-name = `[Content_Types].xml`.
    temp3-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string(
|{ lv_head }<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">|
&& `<Default Extension="xml" ContentType="application/xml"/></Types>` ).
    INSERT temp3 INTO TABLE temp2.
    temp3-name = `_rels/.rels`.
    temp3-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string(
|{ lv_head }<Relationships xmlns="{ cv_pkg }">|
&& |<Relationship Id="rId1" Type="{ cv_rel }/officeDocument" Target="/xl/workbook.xml"/>|
&& `</Relationships>` ).
    INSERT temp3 INTO TABLE temp2.
    temp3-name = `xl/workbook.xml`.
    temp3-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string(
|{ lv_head }\n<workbook xmlns="{ cv_main }" xmlns:r="{ cv_rel }">\n  { workbook_pr }|
&& |\n  <sheets>\n    <sheet name="Data" sheetId="7" r:id="rId3"/>\n  </sheets>\n</workbook>| ).
    INSERT temp3 INTO TABLE temp2.
    temp3-name = `xl/_rels/workbook.xml.rels`.
    temp3-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string(
|{ lv_head }<Relationships xmlns="{ cv_pkg }">|
&& |<Relationship Id="rId1" Type="{ cv_rel }/sharedStrings" Target="sharedStrings.xml"/>|
&& |<Relationship Id="rId2" Type="{ cv_rel }/styles" Target="/xl/styles.xml"/>|
&& |<Relationship Id="rId3" Type="{ cv_rel }/worksheet" Target="worksheets/sheet1.xml"/>|
&& `</Relationships>` ).
    INSERT temp3 INTO TABLE temp2.
    temp3-name = `xl/worksheets/sheet1.xml`.
    temp3-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string(
|{ lv_head }\n<worksheet xmlns="{ cv_main }">\n  <dimension ref="A1"/>|
&& |\n  <sheetData>\n    { rows }\n  </sheetData>\n  <pageMargins left="0.7" right="0.7"/>|
&& |\n</worksheet>| ).
    INSERT temp3 INTO TABLE temp2.

    lt_file = temp2.
    IF shared IS NOT INITIAL.

      CLEAR temp4.
      temp4-name = `xl/sharedStrings.xml`.
      temp4-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( |{ lv_head }<sst xmlns="{ cv_main }">{ shared }</sst>| ).
      INSERT temp4 INTO TABLE lt_file.
    ENDIF.
    IF styles IS NOT INITIAL.

      CLEAR temp5.
      temp5-name = `xl/styles.xml`.
      temp5-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( |{ lv_head }<styleSheet xmlns="{ cv_main }">{ styles }</styleSheet>| ).
      INSERT temp5
             INTO TABLE lt_file.
    ENDIF.
    result = z2ui5_cl_tcl_context=>zip_pack( lt_file ).
  ENDMETHOD.

ENDCLASS.


"! ================================================================
"! WRITING
"! ================================================================
CLASS ltcl_write DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_s_row,
        text   TYPE string,
        num    TYPE i,
        amount TYPE p LENGTH 8 DECIMALS 2,
        date   TYPE d,
        time   TYPE t,
        numc   TYPE n LENGTH 4,
        flag   TYPE abap_bool,
        sub    TYPE string_table,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    METHODS rows
      RETURNING
        VALUE(result) TYPE ty_t_row.

    METHODS parts_of_a_workbook  FOR TESTING RAISING cx_static_check.
    METHODS cells_by_type        FOR TESTING RAISING cx_static_check.
    METHODS header_row           FOR TESTING RAISING cx_static_check.
    METHODS dates_excel_has_none FOR TESTING RAISING cx_static_check.
    METHODS layout_columns       FOR TESTING RAISING cx_static_check.
    METHODS column_unknown       FOR TESTING RAISING cx_static_check.
    METHODS freeze_and_filter    FOR TESTING RAISING cx_static_check.
    METHODS excel_table          FOR TESTING RAISING cx_static_check.
    METHODS excel_table_options  FOR TESTING RAISING cx_static_check.
    METHODS start_cell           FOR TESTING RAISING cx_static_check.
    METHODS start_cell_invalid   FOR TESTING RAISING cx_static_check.
    METHODS totals_row           FOR TESTING RAISING cx_static_check.
    METHODS totals_row_of_table  FOR TESTING RAISING cx_static_check.
    METHODS formula_column       FOR TESTING RAISING cx_static_check.
    METHODS sheet_names          FOR TESTING RAISING cx_static_check.
    METHODS empty_workbook       FOR TESTING RAISING cx_static_check.
    METHODS no_columns           FOR TESTING RAISING cx_static_check.
    METHODS column_letters       FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_write IMPLEMENTATION.

  METHOD rows.
    DATA temp6 TYPE ltcl_write=>ty_t_row.
    DATA temp7 LIKE LINE OF temp6.
    CLEAR temp6.

    CLEAR temp7.
    temp7-text = `  a&b<c`.
    temp7-num = -5.
    temp7-amount = `-12.5`.
    temp7-date = `20240315`.
    temp7-time = `103000`.
    temp7-numc = `0042`.
    temp7-flag = abap_true.
    INSERT temp7 INTO TABLE temp6.
    CLEAR temp7.
    temp7-text = |x{ cl_abap_char_utilities=>form_feed }y|.
    INSERT temp7 INTO TABLE temp6.
    result = temp6.
  ENDMETHOD.

  METHOD parts_of_a_workbook.
    DATA lv_file TYPE xstring.
    DATA lv_book TYPE string.
    DATA temp3 TYPE xsdboolean.
    DATA lv_types TYPE string.
    DATA temp4 TYPE xsdboolean.
    DATA temp5 TYPE xsdboolean.
    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( rows( ) ).

    cl_abap_unit_assert=>assert_true( ltcl_file=>has_part( file = lv_file
                                                           name = `[Content_Types].xml` ) ).
    cl_abap_unit_assert=>assert_true( ltcl_file=>has_part( file = lv_file
                                                           name = `_rels/.rels` ) ).
    cl_abap_unit_assert=>assert_true( ltcl_file=>has_part( file = lv_file
                                                           name = `xl/workbook.xml` ) ).
    cl_abap_unit_assert=>assert_true( ltcl_file=>has_part( file = lv_file
                                                           name = `xl/_rels/workbook.xml.rels` ) ).
    cl_abap_unit_assert=>assert_true( ltcl_file=>has_part( file = lv_file
                                                           name = `xl/styles.xml` ) ).
    cl_abap_unit_assert=>assert_true( ltcl_file=>has_part( file = lv_file
                                                           name = `xl/worksheets/sheet1.xml` ) ).


    lv_book = ltcl_file=>part( file = lv_file
                                     name = `xl/workbook.xml` ).

    temp3 = boolc( lv_book CS `<sheet name="Sheet1" sheetId="1" r:id="rId1"/>` ).
    cl_abap_unit_assert=>assert_true( temp3 ).

    lv_types = ltcl_file=>part( file = lv_file
                                      name = `[Content_Types].xml` ).

    temp4 = boolc( lv_types CS `PartName="/xl/worksheets/sheet1.xml"` ).
    cl_abap_unit_assert=>assert_true( temp4 ).

    temp5 = boolc( lv_types CS `PartName="/xl/styles.xml"` ).
    cl_abap_unit_assert=>assert_true( temp5 ).
  ENDMETHOD.

  METHOD cells_by_type.
    DATA lv_file TYPE xstring.
    DATA lv_sheet TYPE string.
    DATA temp6 TYPE xsdboolean.
    DATA temp7 TYPE xsdboolean.
    DATA temp8 TYPE xsdboolean.
    DATA temp9 TYPE xsdboolean.
    DATA temp10 TYPE xsdboolean.
    DATA temp11 TYPE xsdboolean.
    DATA temp12 TYPE xsdboolean.
    DATA temp13 TYPE xsdboolean.
    DATA temp14 TYPE xsdboolean.
    DATA temp15 TYPE xsdboolean.
    DATA temp16 TYPE xsdboolean.
    DATA temp17 TYPE xsdboolean.
    DATA temp18 TYPE xsdboolean.
    DATA lv_styles TYPE string.
    DATA temp19 TYPE xsdboolean.
    DATA temp20 TYPE xsdboolean.
    DATA temp21 TYPE xsdboolean.
    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( rows( ) ).

    lv_sheet = ltcl_file=>part( file = lv_file
                                      name = `xl/worksheets/sheet1.xml` ).

    " a text with the blanks in front, & and < escaped

    temp6 = boolc( lv_sheet CS `<c r="A2" t="inlineStr"><is><t xml:space="preserve">  a&amp;b&lt;c</t></is></c>` ).
    cl_abap_unit_assert=>assert_true( temp6 ).
    " numbers as values, with a period and the sign in front

    temp7 = boolc( lv_sheet CS `<c r="B2"><v>-5</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp7 ).

    temp8 = boolc( lv_sheet CS `<c r="C2"><v>-12.50</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp8 ).
    " 2024-03-15 is day 45366, 10:30 is 0.4375 of a day - both with a format

    temp9 = boolc( lv_sheet CS `<c r="D2" s="1"><v>45366</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp9 ).

    temp10 = boolc( lv_sheet CS `<c r="E2" s="2"><v>0.4375</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp10 ).
    " a NUMC keeps its zeros as text, a flag is a boolean

    temp11 = boolc( lv_sheet CS `<c r="F2" t="inlineStr"><is><t xml:space="preserve">0042</t>` ).
    cl_abap_unit_assert=>assert_true( temp11 ).

    temp12 = boolc( lv_sheet CS `<c r="G2" t="b"><v>1</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp12 ).
    " the table column is no column: seven of them

    temp13 = boolc( lv_sheet CS `<dimension ref="A1:G3"/>` ).
    cl_abap_unit_assert=>assert_true( temp13 ).

    temp14 = boolc( lv_sheet CS `r="H1"` ).
    cl_abap_unit_assert=>assert_false( temp14 ).

    " second row: the form feed XML forbids dropped, an initial date and a
    " flag that is not set no cell at all

    temp15 = boolc( lv_sheet CS `<t xml:space="preserve">xy</t>` ).
    cl_abap_unit_assert=>assert_true( temp15 ).

    temp16 = boolc( lv_sheet CS `r="D3"` ).
    cl_abap_unit_assert=>assert_false( temp16 ).

    temp17 = boolc( lv_sheet CS `r="G3"` ).
    cl_abap_unit_assert=>assert_false( temp17 ).

    temp18 = boolc( lv_sheet CS `<c r="B3"><v>0</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp18 ).

    " the formats the cells name: the date and the time Excel has built in

    lv_styles = ltcl_file=>part( file = lv_file
                                       name = `xl/styles.xml` ).

    temp19 = boolc( lv_styles CS `<cellXfs count="4">` ).
    cl_abap_unit_assert=>assert_true( temp19 ).

    temp20 = boolc( lv_styles CS `<xf numFmtId="14" fontId="0"` ).
    cl_abap_unit_assert=>assert_true( temp20 ).

    temp21 = boolc( lv_styles CS `<xf numFmtId="21" fontId="0"` ).
    cl_abap_unit_assert=>assert_true( temp21 ).
  ENDMETHOD.

  METHOD header_row.
    DATA lv_file TYPE xstring.
    DATA lv_sheet TYPE string.
    DATA temp22 TYPE xsdboolean.
    DATA lv_styles TYPE string.
    DATA temp23 TYPE xsdboolean.
    DATA temp8 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp24 TYPE xsdboolean.
    DATA temp25 TYPE xsdboolean.
    DATA temp26 TYPE xsdboolean.
    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( rows( ) ).

    lv_sheet = ltcl_file=>part( file = lv_file
                                      name = `xl/worksheets/sheet1.xml` ).
    " the component names, in the bold format

    temp22 = boolc( lv_sheet CS `<row r="1"><c r="A1" s="3" t="inlineStr"><is><t xml:space="preserve">TEXT</t></is></c>` ).
    cl_abap_unit_assert=>assert_true( temp22 ).

    lv_styles = ltcl_file=>part( file = lv_file
                                       name = `xl/styles.xml` ).

    temp23 = boolc( lv_styles CS `<xf numFmtId="0" fontId="1"` ).
    cl_abap_unit_assert=>assert_true( temp23 ).


    CLEAR temp8.
    temp8-no_header = abap_true.
    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = rows( )
                                                    layout = temp8 ).
    lv_sheet = ltcl_file=>part( file = lv_file
                                name = `xl/worksheets/sheet1.xml` ).

    temp24 = boolc( lv_sheet CS `>TEXT<` ).
    cl_abap_unit_assert=>assert_false( temp24 ).

    temp25 = boolc( lv_sheet CS `<c r="B1"><v>-5</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp25 ).

    temp26 = boolc( lv_sheet CS `<dimension ref="A1:G2"/>` ).
    cl_abap_unit_assert=>assert_true( temp26 ).
  ENDMETHOD.

  METHOD dates_excel_has_none.
    TYPES:
      BEGIN OF ty_s_date,
        date TYPE d,
      END OF ty_s_date.
    TYPES temp1 TYPE STANDARD TABLE OF ty_s_date WITH DEFAULT KEY.
DATA lt_date TYPE temp1.

    DATA temp9 LIKE lt_date.
    DATA temp10 LIKE LINE OF temp9.
    DATA lv_sheet TYPE string.
    DATA temp27 TYPE xsdboolean.
    DATA temp28 TYPE xsdboolean.
    DATA temp29 TYPE xsdboolean.
    DATA temp30 TYPE xsdboolean.
    DATA temp31 TYPE xsdboolean.
    CLEAR temp9.

    temp10-date = `18991231`.
    INSERT temp10 INTO TABLE temp9.
    temp10-date = `19000101`.
    INSERT temp10 INTO TABLE temp9.
    temp10-date = `19000228`.
    INSERT temp10 INTO TABLE temp9.
    temp10-date = `19000301`.
    INSERT temp10 INTO TABLE temp9.
    temp10-date = `99991231`.
    INSERT temp10 INTO TABLE temp9.
    lt_date = temp9.

    lv_sheet = ltcl_file=>part( file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( lt_date )
                                      name = `xl/worksheets/sheet1.xml` ).
    " before 1900 a text, then the days as Excel counts them - one ahead
    " up to the 1900-02-29 it believes in

    temp27 = boolc( lv_sheet CS `<c r="A2" t="inlineStr"><is><t xml:space="preserve">1899-12-31</t>` ).
    cl_abap_unit_assert=>assert_true( temp27 ).

    temp28 = boolc( lv_sheet CS `<c r="A3" s="1"><v>1</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp28 ).

    temp29 = boolc( lv_sheet CS `<c r="A4" s="1"><v>59</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp29 ).

    temp30 = boolc( lv_sheet CS `<c r="A5" s="1"><v>61</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp30 ).

    temp31 = boolc( lv_sheet CS `<c r="A6" s="1"><v>2958465</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp31 ).
  ENDMETHOD.

  METHOD layout_columns.
    DATA temp11 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp1 TYPE z2ui5_cl_tcl_xlsx=>ty_t_column.
    DATA temp2 LIKE LINE OF temp1.
    DATA lv_file TYPE xstring.
    DATA lv_sheet TYPE string.
    DATA temp32 TYPE xsdboolean.
    DATA temp33 TYPE xsdboolean.
    DATA temp34 TYPE xsdboolean.
    DATA temp35 TYPE xsdboolean.
    DATA temp36 TYPE xsdboolean.
    DATA lv_styles TYPE string.
    DATA temp37 TYPE xsdboolean.
    DATA temp38 TYPE xsdboolean.
    DATA temp39 TYPE xsdboolean.
    CLEAR temp11.

    CLEAR temp1.

    CLEAR temp2.
    temp2-name = `amount`.
    temp2-header = `Amount "net"`.
    temp2-format = `#,##0.00`.
    temp2-width = 20.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-name = `TEXT`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-name = `date`.
    temp2-format = `dd.mm.yyyy`.
    INSERT temp2 INTO TABLE temp1.
    temp11-t_column = temp1.

    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab(
        val    = rows( )
        layout = temp11 ).

    lv_sheet = ltcl_file=>part( file = lv_file
                                      name = `xl/worksheets/sheet1.xml` ).

    " the columns the layout names, in its order, under its headers

    temp32 = boolc( lv_sheet CS `<t xml:space="preserve">Amount &quot;net&quot;</t>` ).
    cl_abap_unit_assert=>assert_true( temp32 ).

    temp33 = boolc( lv_sheet CS `<c r="A2" s="1"><v>-12.50</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp33 ).

    temp34 = boolc( lv_sheet CS `<c r="C2" s="2"><v>45366</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp34 ).

    temp35 = boolc( lv_sheet CS `<dimension ref="A1:C3"/>` ).
    cl_abap_unit_assert=>assert_true( temp35 ).

    temp36 = boolc( lv_sheet CS `<col min="1" max="1" width="20" customWidth="1"/>` ).
    cl_abap_unit_assert=>assert_true( temp36 ).


    lv_styles = ltcl_file=>part( file = lv_file
                                       name = `xl/styles.xml` ).

    temp37 = boolc( lv_styles CS `<numFmt numFmtId="164" formatCode="#,##0.00"/>` ).
    cl_abap_unit_assert=>assert_true( temp37 ).

    temp38 = boolc( lv_styles CS `<numFmt numFmtId="165" formatCode="dd.mm.yyyy"/>` ).
    cl_abap_unit_assert=>assert_true( temp38 ).

    temp39 = boolc( lv_styles CS `<xf numFmtId="165" fontId="0"` ).
    cl_abap_unit_assert=>assert_true( temp39 ).
  ENDMETHOD.

  METHOD column_unknown.
        DATA temp12 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
        DATA temp3 TYPE z2ui5_cl_tcl_xlsx=>ty_t_column.
        DATA temp4 LIKE LINE OF temp3.
        DATA x TYPE REF TO z2ui5_cx_tcl_error.
        DATA temp40 TYPE xsdboolean.
    TRY.

        CLEAR temp12.

        CLEAR temp3.

        temp4-name = `NOPE`.
        INSERT temp4 INTO TABLE temp3.
        temp12-t_column = temp3.
        z2ui5_cl_tcl_xlsx=>xlsx_by_itab(
            val    = rows( )
            layout = temp12 ).
        cl_abap_unit_assert=>fail( `a column the row does not have has to raise` ).

      CATCH z2ui5_cx_tcl_error INTO x.

        temp40 = boolc( x->get_text( ) CS `XLSX_COLUMN_UNKNOWN` ).
        cl_abap_unit_assert=>assert_true( temp40 ).
    ENDTRY.
  ENDMETHOD.

  METHOD freeze_and_filter.
    DATA temp13 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA lv_sheet TYPE string.
    DATA temp41 TYPE xsdboolean.
    DATA temp42 TYPE xsdboolean.
    CLEAR temp13.
    temp13-freeze_header = abap_true.
    temp13-auto_filter = abap_true.

    lv_sheet = ltcl_file=>part(
        file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = rows( )
                                                     layout = temp13 )
        name = `xl/worksheets/sheet1.xml` ).

    temp41 = boolc( lv_sheet CS `<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>` ).
    cl_abap_unit_assert=>assert_true( temp41 ).

    temp42 = boolc( lv_sheet CS `</sheetData><autoFilter ref="A1:G3"/></worksheet>` ).
    cl_abap_unit_assert=>assert_true( temp42 ).
  ENDMETHOD.

  METHOD excel_table.
    DATA temp14 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp5 TYPE z2ui5_cl_tcl_xlsx=>ty_t_column.
    DATA temp6 LIKE LINE OF temp5.
    DATA lv_file TYPE xstring.
    DATA lv_table TYPE string.
    DATA temp43 TYPE xsdboolean.
    DATA temp44 TYPE xsdboolean.
    DATA temp45 TYPE xsdboolean.
    DATA temp46 TYPE xsdboolean.
    DATA lv_sheet TYPE string.
    DATA temp47 TYPE xsdboolean.
    DATA temp48 TYPE xsdboolean.
    DATA lv_rels TYPE string.
    DATA temp49 TYPE xsdboolean.
    DATA lv_types TYPE string.
    DATA temp50 TYPE xsdboolean.
    DATA lt_none TYPE ty_t_row.
    DATA temp15 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    CLEAR temp14.
    temp14-table_style = `TableStyleMedium2`.

    CLEAR temp5.

    temp6-name = `TEXT`.
    temp6-header = `Name`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `NUM`.
    temp6-header = `name`.
    INSERT temp6 INTO TABLE temp5.
    temp14-t_column = temp5.

    lv_file = z2ui5_cl_tcl_xlsx=>factory(
        )->add_sheet( rows( )
        )->add_sheet( val    = rows( )
                      layout = temp14
        )->get_xlsx( ).

    " the table of the second sheet is table 1 of the workbook

    lv_table = ltcl_file=>part( file = lv_file
                                      name = `xl/tables/table1.xml` ).

    temp43 = boolc( lv_table CS `id="1" name="Table1" displayName="Table1" ref="A1:B3"` ).
    cl_abap_unit_assert=>assert_true( temp43 ).

    temp44 = boolc( lv_table CS `<tableStyleInfo name="TableStyleMedium2"` ).
    cl_abap_unit_assert=>assert_true( temp44 ).
    " a column name once - a second `name` gets a number

    temp45 = boolc( lv_table CS `<tableColumn id="1" name="Name"/>` ).
    cl_abap_unit_assert=>assert_true( temp45 ).

    temp46 = boolc( lv_table CS `<tableColumn id="2" name="name 2"/>` ).
    cl_abap_unit_assert=>assert_true( temp46 ).


    lv_sheet = ltcl_file=>part( file = lv_file
                                      name = `xl/worksheets/sheet2.xml` ).

    temp47 = boolc( lv_sheet CS `<tableParts count="1"><tablePart r:id="rId1"/></tableParts>` ).
    cl_abap_unit_assert=>assert_true( temp47 ).
    " the header as the table names its columns, and not bold: the table
    " formats it

    temp48 = boolc( lv_sheet CS `<c r="B1" t="inlineStr"><is><t xml:space="preserve">name 2</t></is></c>` ).
    cl_abap_unit_assert=>assert_true( temp48 ).


    lv_rels = ltcl_file=>part( file = lv_file
                                     name = `xl/worksheets/_rels/sheet2.xml.rels` ).

    temp49 = boolc( lv_rels CS `Target="../tables/table1.xml"` ).
    cl_abap_unit_assert=>assert_true( temp49 ).

    lv_types = ltcl_file=>part( file = lv_file
                                      name = `[Content_Types].xml` ).

    temp50 = boolc( lv_types CS `PartName="/xl/tables/table1.xml"` ).
    cl_abap_unit_assert=>assert_true( temp50 ).

    " no row, no table: Excel takes none without one


    CLEAR temp15.
    temp15-table_style = `TableStyleMedium2`.
    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = lt_none
                                                    layout = temp15 ).
    cl_abap_unit_assert=>assert_false( ltcl_file=>has_part( file = lv_file
                                                            name = `xl/tables/table1.xml` ) ).
  ENDMETHOD.

  METHOD excel_table_options.
    DATA temp16 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp7 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp1 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA lv_file TYPE xstring.
    DATA lv_table TYPE string.
    DATA temp51 TYPE xsdboolean.
    DATA temp52 TYPE xsdboolean.
    DATA temp53 TYPE xsdboolean.
    DATA temp54 TYPE xsdboolean.
    DATA temp55 TYPE xsdboolean.
    DATA temp56 TYPE xsdboolean.
    DATA temp57 TYPE xsdboolean.
    CLEAR temp16.
    temp16-table_style = `TableStyleLight9`.
    temp16-table_name = `My Orders 2024`.
    temp16-no_row_stripes = abap_true.
    temp16-column_stripes = abap_true.
    temp16-no_filter = abap_true.

    CLEAR temp7.
    temp7-table_style = `TableStyleLight9`.
    temp7-table_name = `myorders2024`.

    CLEAR temp1.
    temp1-table_style = `TableStyleLight9`.
    temp1-table_name = `A1`.

    lv_file = z2ui5_cl_tcl_xlsx=>factory(
        )->add_sheet( val    = rows( )
                      layout = temp16
        )->add_sheet( val    = rows( )
                      layout = temp7
        )->add_sheet( val    = rows( )
                      layout = temp1
        )->get_xlsx( ).

    " the name without what Excel does not take in one, no filter, the
    " stripes as asked for

    lv_table = ltcl_file=>part( file = lv_file
                                      name = `xl/tables/table1.xml` ).

    temp51 = boolc( lv_table CS `name="MyOrders2024" displayName="MyOrders2024"` ).
    cl_abap_unit_assert=>assert_true( temp51 ).

    temp52 = boolc( lv_table CS `<autoFilter` ).
    cl_abap_unit_assert=>assert_false( temp52 ).

    temp53 = boolc( lv_table CS `showRowStripes="0" showColumnStripes="1"` ).
    cl_abap_unit_assert=>assert_true( temp53 ).

    " a name the workbook has, whatever its case, gets a number - and one
    " that reads as a cell an underscore
    lv_table = ltcl_file=>part( file = lv_file
                                name = `xl/tables/table2.xml` ).

    temp54 = boolc( lv_table CS `name="myorders2024_2"` ).
    cl_abap_unit_assert=>assert_true( temp54 ).

    temp55 = boolc( lv_table CS `<autoFilter ref="A1:G3"/>` ).
    cl_abap_unit_assert=>assert_true( temp55 ).

    temp56 = boolc( lv_table CS `showRowStripes="1" showColumnStripes="0"` ).
    cl_abap_unit_assert=>assert_true( temp56 ).
    lv_table = ltcl_file=>part( file = lv_file
                                name = `xl/tables/table3.xml` ).

    temp57 = boolc( lv_table CS `name="_A1"` ).
    cl_abap_unit_assert=>assert_true( temp57 ).
  ENDMETHOD.

  METHOD start_cell.
    DATA temp17 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA lv_sheet TYPE string.
    DATA temp58 TYPE xsdboolean.
    DATA temp59 TYPE xsdboolean.
    DATA temp60 TYPE xsdboolean.
    DATA temp61 TYPE xsdboolean.
    DATA temp62 TYPE xsdboolean.
    DATA temp63 TYPE xsdboolean.
    DATA temp64 TYPE xsdboolean.
    DATA temp18 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA lv_table TYPE string.
    DATA temp65 TYPE xsdboolean.
    CLEAR temp17.
    temp17-start_cell = `b3`.
    temp17-freeze_header = abap_true.
    temp17-auto_filter = abap_true.

    lv_sheet = ltcl_file=>part(
        file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = rows( )
                                                     layout = temp17 )
        name = `xl/worksheets/sheet1.xml` ).

    " the header in B3, the rows under it, the columns from B on

    temp58 = boolc( lv_sheet CS `<dimension ref="B3:H5"/>` ).
    cl_abap_unit_assert=>assert_true( temp58 ).

    temp59 = boolc( lv_sheet CS `<row r="3"><c r="B3" s="3" t="inlineStr">` ).
    cl_abap_unit_assert=>assert_true( temp59 ).

    temp60 = boolc( lv_sheet CS `<c r="C4"><v>-5</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp60 ).

    temp61 = boolc( lv_sheet CS `<col min="2" max="2"` ).
    cl_abap_unit_assert=>assert_true( temp61 ).

    temp62 = boolc( lv_sheet CS `<col min="1" max="1"` ).
    cl_abap_unit_assert=>assert_false( temp62 ).
    " what is frozen ends with the header row, and the filter is on it

    temp63 = boolc( lv_sheet CS `<pane ySplit="3" topLeftCell="A4"` ).
    cl_abap_unit_assert=>assert_true( temp63 ).

    temp64 = boolc( lv_sheet CS `<autoFilter ref="B3:H5"/>` ).
    cl_abap_unit_assert=>assert_true( temp64 ).

    " an Excel table stands where the rows stand

    CLEAR temp18.
    temp18-start_cell = `$C$2`.
    temp18-table_style = `TableStyleMedium2`.

    lv_table = ltcl_file=>part(
        file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = rows( )
                                                     layout = temp18 )
        name = `xl/tables/table1.xml` ).

    temp65 = boolc( lv_table CS ` ref="C2:I4"` ).
    cl_abap_unit_assert=>assert_true( temp65 ).
  ENDMETHOD.

  METHOD start_cell_invalid.
        DATA temp19 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
        DATA x TYPE REF TO z2ui5_cx_tcl_error.
        DATA temp66 TYPE xsdboolean.
        DATA temp20 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    TRY.

        CLEAR temp19.
        temp19-start_cell = `here`.
        z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = rows( )
                                              layout = temp19 ).
        cl_abap_unit_assert=>fail( `a start cell that is none has to raise` ).

      CATCH z2ui5_cx_tcl_error INTO x.

        temp66 = boolc( x->get_text( ) CS `XLSX_START_CELL` ).
        cl_abap_unit_assert=>assert_true( temp66 ).
    ENDTRY.
    TRY.

        CLEAR temp20.
        temp20-start_cell = `B0`.
        z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = rows( )
                                              layout = temp20 ).
        cl_abap_unit_assert=>fail( `row 0 has to raise` ).
      CATCH z2ui5_cx_tcl_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD totals_row.
    DATA temp21 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp8 TYPE z2ui5_cl_tcl_xlsx=>ty_t_column.
    DATA temp9 LIKE LINE OF temp8.
    DATA lv_file TYPE xstring.
    DATA lv_sheet TYPE string.
    DATA temp67 TYPE xsdboolean.
    DATA temp68 TYPE xsdboolean.
    DATA temp69 TYPE xsdboolean.
    DATA temp70 TYPE xsdboolean.
    DATA temp71 TYPE xsdboolean.
    DATA temp72 TYPE xsdboolean.
    DATA temp73 TYPE xsdboolean.
    DATA temp74 TYPE xsdboolean.
    DATA temp75 TYPE xsdboolean.
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    FIELD-SYMBOLS <temp22> LIKE LINE OF lt_cell.
    DATA temp23 LIKE sy-tabix.
    DATA lt_none TYPE ty_t_row.
    DATA temp24 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp10 TYPE z2ui5_cl_tcl_xlsx=>ty_t_column.
    DATA temp11 LIKE LINE OF temp10.
    DATA temp76 TYPE xsdboolean.
    CLEAR temp21.
    temp21-auto_filter = abap_true.

    CLEAR temp8.

    CLEAR temp9.
    temp9-name = `TEXT`.
    temp9-total = `Total`.
    INSERT temp9 INTO TABLE temp8.
    CLEAR temp9.
    temp9-name = `NUM`.
    temp9-total = `SUM`.
    INSERT temp9 INTO TABLE temp8.
    CLEAR temp9.
    temp9-name = `AMOUNT`.
    temp9-total = `average`.
    temp9-format = `0.00`.
    INSERT temp9 INTO TABLE temp8.
    CLEAR temp9.
    temp9-name = `DATE`.
    temp9-total = `count`.
    INSERT temp9 INTO TABLE temp8.
    CLEAR temp9.
    temp9-name = `NUMC`.
    temp9-total = `max`.
    INSERT temp9 INTO TABLE temp8.
    temp21-t_column = temp8.

    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab(
        val    = rows( )
        layout = temp21 ).

    lv_sheet = ltcl_file=>part( file = lv_file
                                      name = `xl/worksheets/sheet1.xml` ).

    " a row under the rows: the label bold, a formula over the cells of
    " the column with the value it gives - -5 and 0, -12.5 and 0

    temp67 = boolc( lv_sheet CS `<dimension ref="A1:E4"/>` ).
    cl_abap_unit_assert=>assert_true( temp67 ).

    temp68 = boolc( lv_sheet CS `<row r="4"><c r="A4" s="3" t="inlineStr"><is><t xml:space="preserve">Total</t></is></c>` ).
    cl_abap_unit_assert=>assert_true( temp68 ).

    temp69 = boolc( lv_sheet CS `<c r="B4"><f>SUBTOTAL(109,B2:B3)</f><v>-5</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp69 ).

    temp70 = boolc( lv_sheet CS `<c r="C4" s="1"><f>SUBTOTAL(101,C2:C3)</f><v>-6.25</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp70 ).
    " a count is a number, not a date: the cells that hold a value, one

    temp71 = boolc( lv_sheet CS `<c r="D4"><f>SUBTOTAL(103,D2:D3)</f><v>1</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp71 ).
    " a NUMC is text: nothing to add up here, the formula stands

    temp72 = boolc( lv_sheet CS `<c r="E4"><f>SUBTOTAL(104,E2:E3)</f>` ).
    cl_abap_unit_assert=>assert_true( temp72 ).
    " the filter ends above the totals row

    temp73 = boolc( lv_sheet CS `<autoFilter ref="A1:E3"/>` ).
    cl_abap_unit_assert=>assert_true( temp73 ).

    " Excel is asked to work the formulas out when it opens the file

    temp74 = boolc( ltcl_file=>part( file = lv_file name = `xl/workbook.xml` ) CS `</sheets><calcPr fullCalcOnLoad="1"/></workbook>` ).
    cl_abap_unit_assert=>assert_true( temp74 ).

    temp75 = boolc( ltcl_file=>part( file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( rows( ) ) name = `xl/workbook.xml` ) CS `calcPr` ).
    cl_abap_unit_assert=>assert_false( temp75 ).

    " read back, a totals cell holds the value that was written with it

    lt_cell = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( lv_file )->get_cells( ).


    temp23 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 4 col = 3 ASSIGNING <temp22>.
    sy-tabix = temp23.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `-6.25`
                                        act = <temp22>-value ).

    " no row, no totals row


    CLEAR temp24.

    CLEAR temp10.

    temp11-name = `NUM`.
    temp11-total = `sum`.
    INSERT temp11 INTO TABLE temp10.
    temp24-t_column = temp10.
    lv_sheet = ltcl_file=>part(
        file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab(
                   val    = lt_none
                   layout = temp24 )
        name = `xl/worksheets/sheet1.xml` ).

    temp76 = boolc( lv_sheet CS `SUBTOTAL` ).
    cl_abap_unit_assert=>assert_false( temp76 ).
  ENDMETHOD.

  METHOD totals_row_of_table.
    DATA temp25 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp12 TYPE z2ui5_cl_tcl_xlsx=>ty_t_column.
    DATA temp13 LIKE LINE OF temp12.
    DATA lv_file TYPE xstring.
    DATA lv_table TYPE string.
    DATA temp77 TYPE xsdboolean.
    DATA temp78 TYPE xsdboolean.
    DATA temp79 TYPE xsdboolean.
    DATA temp80 TYPE xsdboolean.
    DATA lv_sheet TYPE string.
    DATA temp81 TYPE xsdboolean.
    DATA temp82 TYPE xsdboolean.
    DATA temp83 TYPE xsdboolean.
    CLEAR temp25.
    temp25-table_style = `TableStyleMedium2`.
    temp25-table_name = `Orders`.

    CLEAR temp12.

    CLEAR temp13.
    temp13-name = `TEXT`.
    temp13-header = `Name`.
    temp13-total = `Total`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-name = `NUM`.
    temp13-header = `Qty [pcs] #1`.
    temp13-total = `sum`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-name = `AMOUNT`.
    temp13-total = `min`.
    INSERT temp13 INTO TABLE temp12.
    temp25-t_column = temp12.

    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab(
        val    = rows( )
        layout = temp25 ).

    " the table reaches over the totals row, its filter does not

    lv_table = ltcl_file=>part( file = lv_file
                                      name = `xl/tables/table1.xml` ).

    temp77 = boolc( lv_table CS ` ref="A1:C4" totalsRowCount="1"><autoFilter ref="A1:C3"/>` ).
    cl_abap_unit_assert=>assert_true( temp77 ).

    temp78 = boolc( lv_table CS `<tableColumn id="1" name="Name" totalsRowLabel="Total"/>` ).
    cl_abap_unit_assert=>assert_true( temp78 ).

    temp79 = boolc( lv_table CS `name="Qty [pcs] #1" totalsRowFunction="sum"/>` ).
    cl_abap_unit_assert=>assert_true( temp79 ).

    temp80 = boolc( lv_table CS `name="AMOUNT" totalsRowFunction="min"/>` ).
    cl_abap_unit_assert=>assert_true( temp80 ).

    " the formula names the column of the table - with what a reference
    " reads as its own syntax marked - and the label is not bold: the
    " table formats its totals row

    lv_sheet = ltcl_file=>part( file = lv_file
                                      name = `xl/worksheets/sheet1.xml` ).

    temp81 = boolc( lv_sheet CS `<c r="A4" t="inlineStr"><is><t xml:space="preserve">Total</t></is></c>` ).
    cl_abap_unit_assert=>assert_true( temp81 ).

    temp82 = boolc( lv_sheet CS `<c r="B4"><f>SUBTOTAL(109,Orders[Qty '[pcs'] '#1])</f><v>-5</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp82 ).

    temp83 = boolc( lv_sheet CS `<c r="C4"><f>SUBTOTAL(105,Orders[AMOUNT])</f><v>-12.5</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp83 ).
  ENDMETHOD.

  METHOD formula_column.
    DATA temp26 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp14 TYPE z2ui5_cl_tcl_xlsx=>ty_t_column.
    DATA temp15 LIKE LINE OF temp14.
    DATA lv_file TYPE xstring.
    DATA lv_sheet TYPE string.
    DATA temp84 TYPE xsdboolean.
    DATA temp85 TYPE xsdboolean.
    DATA temp86 TYPE xsdboolean.
    DATA temp87 TYPE xsdboolean.
    DATA temp88 TYPE xsdboolean.
    DATA temp89 TYPE xsdboolean.
    DATA temp90 TYPE xsdboolean.
    DATA lt_back TYPE ty_t_row.
    FIELD-SYMBOLS <temp27> LIKE LINE OF lt_back.
    DATA temp28 LIKE sy-tabix.
    CLEAR temp26.

    CLEAR temp14.

    CLEAR temp15.
    temp15-name = `NUM`.
    INSERT temp15 INTO TABLE temp14.
    CLEAR temp15.
    temp15-name = `AMOUNT`.
    INSERT temp15 INTO TABLE temp14.
    CLEAR temp15.
    temp15-header = `Value`.
    temp15-formula = `=A{row}*B{row}`.
    temp15-format = `0.00`.
    temp15-total = `sum`.
    INSERT temp15 INTO TABLE temp14.
    CLEAR temp15.
    temp15-formula = `IF(A{row}<0,"neg","")`.
    INSERT temp15 INTO TABLE temp14.
    temp26-t_column = temp14.

    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab(
        val    = rows( )
        layout = temp26 ).

    lv_sheet = ltcl_file=>part( file = lv_file
                                      name = `xl/worksheets/sheet1.xml` ).

    " every cell of the column the formula for its row, without a value

    temp84 = boolc( lv_sheet CS `>Value</t>` ).
    cl_abap_unit_assert=>assert_true( temp84 ).

    temp85 = boolc( lv_sheet CS `<c r="C2" s="1"><f>A2*B2</f></c>` ).
    cl_abap_unit_assert=>assert_true( temp85 ).

    temp86 = boolc( lv_sheet CS `<c r="C3" s="1"><f>A3*B3</f></c>` ).
    cl_abap_unit_assert=>assert_true( temp86 ).

    temp87 = boolc( lv_sheet CS `<c r="D2"><f>IF(A2&lt;0,&quot;neg&quot;,&quot;&quot;)</f></c>` ).
    cl_abap_unit_assert=>assert_true( temp87 ).
    " a column without a name and without a header is named by its place

    temp88 = boolc( lv_sheet CS `>Column4</t>` ).
    cl_abap_unit_assert=>assert_true( temp88 ).
    " its total is a formula too, and nothing was added up for it here

    temp89 = boolc( lv_sheet CS `<c r="C4" s="1"><f>SUBTOTAL(109,C2:C3)</f></c>` ).
    cl_abap_unit_assert=>assert_true( temp89 ).

    temp90 = boolc( ltcl_file=>part( file = lv_file name = `xl/workbook.xml` ) CS `fullCalcOnLoad` ).
    cl_abap_unit_assert=>assert_true( temp90 ).

    " read back, a formula without a value is no cell - the columns with
    " values are read as before

    z2ui5_cl_tcl_xlsx=>itab_by_xlsx( EXPORTING val    = lv_file
                                          IMPORTING result = lt_back ).


    temp28 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp27>.
    sy-tabix = temp28.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = -5
                                        act = <temp27>-num ).
  ENDMETHOD.

  METHOD sheet_names.
    DATA lt_none TYPE ty_t_row.

    DATA lo_xlsx TYPE REF TO z2ui5_cl_tcl_xlsx.
    DATA lt_name TYPE string_table.
    FIELD-SYMBOLS <temp29> LIKE LINE OF lt_name.
    DATA temp30 LIKE sy-tabix.
    FIELD-SYMBOLS <temp31> LIKE LINE OF lt_name.
    DATA temp32 LIKE sy-tabix.
    FIELD-SYMBOLS <temp33> LIKE LINE OF lt_name.
    DATA temp34 LIKE sy-tabix.
    FIELD-SYMBOLS <temp35> LIKE LINE OF lt_name.
    DATA temp36 LIKE sy-tabix.
    DATA lv_book TYPE string.
    DATA temp91 TYPE xsdboolean.
    lo_xlsx = z2ui5_cl_tcl_xlsx=>factory(
        )->add_sheet( val  = lt_none
                      name = `Q1/Q2: [plan]`
        )->add_sheet( val  = lt_none
                      name = `q1_q2_ _plan_`
        )->add_sheet( lt_none
        )->add_sheet( val  = lt_none
                      name = `a name that is longer than Excel takes it` ).


    lt_name = lo_xlsx->get_sheet_names( ).
    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lines( lt_name ) ).


    temp30 = sy-tabix.
    READ TABLE lt_name INDEX 1 ASSIGNING <temp29>.
    sy-tabix = temp30.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `Q1_Q2_ _plan_`
                                        act = <temp29> ).


    temp32 = sy-tabix.
    READ TABLE lt_name INDEX 2 ASSIGNING <temp31>.
    sy-tabix = temp32.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `q1_q2_ _plan_ (2)`
                                        act = <temp31> ).


    temp34 = sy-tabix.
    READ TABLE lt_name INDEX 3 ASSIGNING <temp33>.
    sy-tabix = temp34.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `Sheet3`
                                        act = <temp33> ).


    temp36 = sy-tabix.
    READ TABLE lt_name INDEX 4 ASSIGNING <temp35>.
    sy-tabix = temp36.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `a name that is longer than Exce`
                                        act = <temp35> ).


    lv_book = ltcl_file=>part( file = lo_xlsx->get_xlsx( )
                                     name = `xl/workbook.xml` ).

    temp91 = boolc( lv_book CS `<sheet name="Sheet3" sheetId="3" r:id="rId3"/>` ).
    cl_abap_unit_assert=>assert_true( temp91 ).
  ENDMETHOD.

  METHOD empty_workbook.
    DATA lo_xlsx TYPE REF TO z2ui5_cl_tcl_xlsx.
    DATA lt_name TYPE string_table.
    FIELD-SYMBOLS <temp37> LIKE LINE OF lt_name.
    DATA temp38 LIKE sy-tabix.
    lo_xlsx = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( z2ui5_cl_tcl_xlsx=>factory( )->get_xlsx( ) ).

    lt_name = lo_xlsx->get_sheet_names( ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_name ) ).


    temp38 = sy-tabix.
    READ TABLE lt_name INDEX 1 ASSIGNING <temp37>.
    sy-tabix = temp38.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `Sheet1`
                                        act = <temp37> ).
    cl_abap_unit_assert=>assert_initial( lo_xlsx->get_cells( ) ).
  ENDMETHOD.

  METHOD no_columns.
    " a row without an elementary component: a sheet without a cell
    TYPES temp2 TYPE STANDARD TABLE OF string_table WITH DEFAULT KEY.
DATA lt_deep TYPE temp2.
    DATA temp39 TYPE string_table.
    DATA lv_sheet TYPE string.
    DATA temp92 TYPE xsdboolean.
    DATA temp93 TYPE xsdboolean.
    CLEAR temp39.
    INSERT `a` INTO TABLE temp39.
    INSERT temp39 INTO TABLE lt_deep.

    lv_sheet = ltcl_file=>part( file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( lt_deep )
                                      name = `xl/worksheets/sheet1.xml` ).

    temp92 = boolc( lv_sheet CS `<dimension ref="A1"/>` ).
    cl_abap_unit_assert=>assert_true( temp92 ).

    temp93 = boolc( lv_sheet CS `<cols>` ).
    cl_abap_unit_assert=>assert_false( temp93 ).
  ENDMETHOD.

  METHOD column_letters.
    cl_abap_unit_assert=>assert_equals( exp = `A`
                                        act = z2ui5_cl_tcl_xlsx=>column_to_letters( 1 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Z`
                                        act = z2ui5_cl_tcl_xlsx=>column_to_letters( 26 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `AA`
                                        act = z2ui5_cl_tcl_xlsx=>column_to_letters( 27 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `XFD`
                                        act = z2ui5_cl_tcl_xlsx=>column_to_letters( 16384 ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = z2ui5_cl_tcl_xlsx=>column_to_number( `A` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 27
                                        act = z2ui5_cl_tcl_xlsx=>column_to_number( `aa` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 28
                                        act = z2ui5_cl_tcl_xlsx=>column_to_number( `$AB$12` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 16384
                                        act = z2ui5_cl_tcl_xlsx=>column_to_number( `XFD1048576` ) ).
  ENDMETHOD.

ENDCLASS.


"! ================================================================
"! WRITING AND READING BACK
"! ================================================================
CLASS ltcl_roundtrip DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_s_row,
        text   TYPE string,
        code   TYPE c LENGTH 5,
        num    TYPE i,
        amount TYPE p LENGTH 8 DECIMALS 2,
        ratio  TYPE f,
        date   TYPE d,
        time   TYPE t,
        numc   TYPE n LENGTH 4,
        flag   TYPE abap_bool,
        bytes  TYPE x LENGTH 2,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    METHODS rows
      RETURNING
        VALUE(result) TYPE ty_t_row.

    "! a text with umlauts, blanks around it and what XML escapes - built
    "! from the bytes, so that this source stays 7-bit ASCII
    METHODS text_with_umlauts
      RETURNING
        VALUE(result) TYPE string.

    METHODS typed_table        FOR TESTING RAISING cx_static_check.
    METHODS two_sheets         FOR TESTING RAISING cx_static_check.
    METHODS cells              FOR TESTING RAISING cx_static_check.
    METHODS table_of_strings   FOR TESTING RAISING cx_static_check.
    METHODS headers_of_caller  FOR TESTING RAISING cx_static_check.
    METHODS header_as_name     FOR TESTING RAISING cx_static_check.
    METHODS without_header     FOR TESTING RAISING cx_static_check.
    METHODS elementary_line    FOR TESTING RAISING cx_static_check.
    METHODS text_like_a_code   FOR TESTING RAISING cx_static_check.
    METHODS timestamp          FOR TESTING RAISING cx_static_check.
    METHODS start_cell         FOR TESTING RAISING cx_static_check.
    METHODS other_target_types FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_roundtrip IMPLEMENTATION.

  METHOD text_with_umlauts.
    DATA temp41 TYPE xstring.
    DATA lv_ue TYPE string.
    DATA temp42 TYPE xstring.
    DATA lv_oe TYPE string.
    temp41 = `C3BC`.

    lv_ue = z2ui5_cl_tcl_context=>conv_get_string_by_xstring( temp41 ).

    temp42 = `C3B6`.

    lv_oe = z2ui5_cl_tcl_context=>conv_get_string_by_xstring( temp42 ).
    result = |  M{ lv_ue }ller & S{ lv_oe }hne <GmbH>  |.
  ENDMETHOD.

  METHOD rows.
    DATA temp43 TYPE ltcl_roundtrip=>ty_t_row.
    DATA temp44 LIKE LINE OF temp43.
    CLEAR temp43.

    CLEAR temp44.
    temp44-text = text_with_umlauts( ).
    temp44-code = `AB`.
    temp44-num = -5.
    temp44-amount = `-1234.5`.
    temp44-ratio = `0.25`.
    temp44-date = `20240315`.
    temp44-time = `103000`.
    temp44-numc = `0042`.
    temp44-flag = abap_true.
    temp44-bytes = `00FF`.
    INSERT temp44 INTO TABLE temp43.
    CLEAR temp44.
    INSERT temp44 INTO TABLE temp43.
    CLEAR temp44.
    temp44-text = |line 1{ cl_abap_char_utilities=>newline }line 2|.
    temp44-num = 2147483647.
    temp44-amount = `99999999.99`.
    temp44-date = `19000228`.
    temp44-time = `235959`.
    temp44-numc = `9999`.
    INSERT temp44 INTO TABLE temp43.
    result = temp43.
  ENDMETHOD.

  METHOD typed_table.
    DATA lt_back TYPE ty_t_row.

    DATA lt_rows TYPE ltcl_roundtrip=>ty_t_row.
    lt_rows = rows( ).
    z2ui5_cl_tcl_xlsx=>itab_by_xlsx( EXPORTING val    = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( lt_rows )
                                          IMPORTING result = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = lt_rows
                                        act = lt_back ).
  ENDMETHOD.

  METHOD two_sheets.
    DATA lt_back  TYPE ty_t_row.
    DATA lt_names TYPE string_table.
    DATA lt_text  TYPE string_table.

    DATA temp45 TYPE string_table.
    DATA lo_xlsx TYPE REF TO z2ui5_cl_tcl_xlsx.
    DATA temp47 TYPE string_table.
        DATA x TYPE REF TO z2ui5_cx_tcl_error.
        DATA temp94 TYPE xsdboolean.
    CLEAR temp45.
    INSERT `one` INTO TABLE temp45.
    INSERT `two` INTO TABLE temp45.
    lt_names = temp45.

    lo_xlsx = z2ui5_cl_tcl_xlsx=>factory_by_xlsx(
        z2ui5_cl_tcl_xlsx=>factory(
            )->add_sheet( val  = rows( )
                          name = `Rows`
            )->add_sheet( val  = lt_names
                          name = `Names`
            )->get_xlsx( ) ).


    CLEAR temp47.
    INSERT `Rows` INTO TABLE temp47.
    INSERT `Names` INTO TABLE temp47.
    cl_abap_unit_assert=>assert_equals( exp = temp47
                                        act = lo_xlsx->get_sheet_names( ) ).

    " by its name, whatever the case - and by its position
    lo_xlsx->get_table( EXPORTING sheet  = `names`
                        IMPORTING result = lt_text ).
    cl_abap_unit_assert=>assert_equals( exp = lt_names
                                        act = lt_text ).
    lo_xlsx->get_table( EXPORTING index  = 1
                        IMPORTING result = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = rows( )
                                        act = lt_back ).

    TRY.
        lo_xlsx->get_cells( sheet = `Nope` ).
        cl_abap_unit_assert=>fail( `a sheet the workbook does not have has to raise` ).

      CATCH z2ui5_cx_tcl_error INTO x.

        temp94 = boolc( x->get_text( ) CS `XLSX_SHEET_UNKNOWN` ).
        cl_abap_unit_assert=>assert_true( temp94 ).
    ENDTRY.
    TRY.
        lo_xlsx->get_cells( index = 3 ).
        cl_abap_unit_assert=>fail( `a position behind the last sheet has to raise` ).
      CATCH z2ui5_cx_tcl_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD cells.
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    DATA temp49 TYPE z2ui5_cl_tcl_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp16> LIKE LINE OF lt_cell.
    DATA temp17 LIKE sy-tabix.
    DATA temp50 TYPE z2ui5_cl_tcl_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp18> LIKE LINE OF lt_cell.
    DATA temp19 LIKE sy-tabix.
    DATA temp51 TYPE z2ui5_cl_tcl_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp20> LIKE LINE OF lt_cell.
    DATA temp21 LIKE sy-tabix.
    DATA temp52 TYPE z2ui5_cl_tcl_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp22> LIKE LINE OF lt_cell.
    DATA temp23 LIKE sy-tabix.
    DATA temp53 TYPE z2ui5_cl_tcl_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp24> LIKE LINE OF lt_cell.
    DATA temp25 LIKE sy-tabix.
    DATA temp54 TYPE z2ui5_cl_tcl_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp26> LIKE LINE OF lt_cell.
    DATA temp27 LIKE sy-tabix.
    DATA temp55 TYPE z2ui5_cl_tcl_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp28> LIKE LINE OF lt_cell.
    DATA temp29 LIKE sy-tabix.
    FIELD-SYMBOLS <temp56> LIKE LINE OF lt_cell.
    DATA temp57 LIKE sy-tabix.
    FIELD-SYMBOLS <temp58> LIKE LINE OF lt_cell.
    DATA temp59 LIKE sy-tabix.
    DATA temp95 TYPE xsdboolean.
    DATA temp1 LIKE sy-subrc.
    lt_cell = z2ui5_cl_tcl_xlsx=>factory_by_xlsx(
                        z2ui5_cl_tcl_xlsx=>xlsx_by_itab( rows( ) ) )->get_cells( ).

    " the header, then every cell of the first row by what it is

    CLEAR temp49.
    temp49-row = 1.
    temp49-col = 1.
    temp49-kind = `S`.
    temp49-value = `TEXT`.


    temp17 = sy-tabix.
    READ TABLE lt_cell INDEX 1 ASSIGNING <temp16>.
    sy-tabix = temp17.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        exp = temp49
        act = <temp16> ).

    CLEAR temp50.
    temp50-row = 2.
    temp50-col = 1.
    temp50-kind = `S`.
    temp50-value = text_with_umlauts( ).


    temp19 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 col = 1 ASSIGNING <temp18>.
    sy-tabix = temp19.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        exp = temp50
        act = <temp18> ).

    CLEAR temp51.
    temp51-row = 2.
    temp51-col = 3.
    temp51-kind = `N`.
    temp51-value = `-5`.


    temp21 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 col = 3 ASSIGNING <temp20>.
    sy-tabix = temp21.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        exp = temp51
        act = <temp20> ).

    CLEAR temp52.
    temp52-row = 2.
    temp52-col = 4.
    temp52-kind = `N`.
    temp52-value = `-1234.5`.


    temp23 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 col = 4 ASSIGNING <temp22>.
    sy-tabix = temp23.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        exp = temp52
        act = <temp22> ).

    CLEAR temp53.
    temp53-row = 2.
    temp53-col = 6.
    temp53-kind = `D`.
    temp53-value = `2024-03-15`.


    temp25 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 col = 6 ASSIGNING <temp24>.
    sy-tabix = temp25.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        exp = temp53
        act = <temp24> ).

    CLEAR temp54.
    temp54-row = 2.
    temp54-col = 7.
    temp54-kind = `T`.
    temp54-value = `10:30:00`.


    temp27 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 col = 7 ASSIGNING <temp26>.
    sy-tabix = temp27.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        exp = temp54
        act = <temp26> ).

    CLEAR temp55.
    temp55-row = 2.
    temp55-col = 9.
    temp55-kind = `B`.
    temp55-value = `X`.


    temp29 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 col = 9 ASSIGNING <temp28>.
    sy-tabix = temp29.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        exp = temp55
        act = <temp28> ).
    " 1900-02-28, the last day before the one Excel made up


    temp57 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 4 col = 6 ASSIGNING <temp56>.
    sy-tabix = temp57.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `1900-02-28`
                                        act = <temp56>-value ).


    temp59 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 4 col = 7 ASSIGNING <temp58>.
    sy-tabix = temp59.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `23:59:59`
                                        act = <temp58>-value ).
    " a cell without a value is none


    READ TABLE lt_cell WITH KEY row = 3 col = 1 TRANSPORTING NO FIELDS.
    temp1 = sy-subrc.
    temp95 = boolc( temp1 = 0 ).
    cl_abap_unit_assert=>assert_false( temp95 ).
  ENDMETHOD.

  METHOD table_of_strings.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA lr_tab TYPE REF TO data.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <amount> TYPE any.
    FIELD-SYMBOLS <date> TYPE any.
    FIELD-SYMBOLS <text> TYPE any.
    FIELD-SYMBOLS <num> TYPE any.
    FIELD-SYMBOLS <b> TYPE any.
    lr_tab = z2ui5_cl_tcl_xlsx=>factory_by_xlsx(
                       z2ui5_cl_tcl_xlsx=>xlsx_by_itab( rows( ) ) )->get_table_ref( ).
    ASSIGN lr_tab->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( <tab> ) ).


    READ TABLE <tab> INDEX 1 ASSIGNING <row>.

    ASSIGN COMPONENT `AMOUNT` OF STRUCTURE <row> TO <amount>.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `-1234.5`
                                        act = <amount> ).

    ASSIGN COMPONENT `DATE` OF STRUCTURE <row> TO <date>.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `2024-03-15`
                                        act = <date> ).
    " the second row holds its numbers and nothing else
    READ TABLE <tab> INDEX 2 ASSIGNING <row>.

    ASSIGN COMPONENT `TEXT` OF STRUCTURE <row> TO <text>.
    cl_abap_unit_assert=>assert_initial( <text> ).

    ASSIGN COMPONENT `NUM` OF STRUCTURE <row> TO <num>.
    cl_abap_unit_assert=>assert_equals( exp = `0`
                                        act = <num> ).

    " no header row: the columns by their letters, the header a row
    lr_tab = z2ui5_cl_tcl_xlsx=>factory_by_xlsx(
                 z2ui5_cl_tcl_xlsx=>xlsx_by_itab( rows( ) ) )->get_table_ref( header_row = 0 ).
    ASSIGN lr_tab->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lines( <tab> ) ).
    READ TABLE <tab> INDEX 1 ASSIGNING <row>.

    ASSIGN COMPONENT `B` OF STRUCTURE <row> TO <b>.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `CODE`
                                        act = <b> ).
  ENDMETHOD.

  METHOD headers_of_caller.
    DATA lt_back TYPE ty_t_row.

    DATA temp60 TYPE z2ui5_cl_tcl_xlsx=>ty_t_column.
    DATA temp61 LIKE LINE OF temp60.
    DATA lt_column LIKE temp60.
    DATA temp62 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA lv_file TYPE xstring.
    DATA temp1 TYPE REF TO z2ui5_cl_tcl_xlsx.
    FIELD-SYMBOLS <temp63> LIKE LINE OF lt_back.
    DATA temp64 LIKE sy-tabix.
    FIELD-SYMBOLS <temp65> LIKE LINE OF lt_back.
    DATA temp66 LIKE sy-tabix.
    FIELD-SYMBOLS <temp67> LIKE LINE OF lt_back.
    DATA temp68 LIKE sy-tabix.
    DATA temp2 TYPE REF TO z2ui5_cl_tcl_xlsx.
    CLEAR temp60.

    temp61-name = `NUM`.
    temp61-header = `Anzahl`.
    INSERT temp61 INTO TABLE temp60.
    temp61-name = `TEXT`.
    temp61-header = `Bezeichnung`.
    INSERT temp61 INTO TABLE temp60.

    lt_column = temp60.

    CLEAR temp62.
    temp62-t_column = lt_column.

    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = rows( )
                                                          layout = temp62 ).

    " the headers that wrote the columns read them back

    temp1 = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( lv_file ).
    temp1->get_table( EXPORTING t_column = lt_column
                                                                   IMPORTING result   = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_back ) ).


    temp64 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp63>.
    sy-tabix = temp64.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = -5
                                        act = <temp63>-num ).


    temp66 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp65>.
    sy-tabix = temp66.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = text_with_umlauts( )
                                        act = <temp65>-text ).


    temp68 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp67>.
    sy-tabix = temp68.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp67>-amount ).

    " without them no column has a component: no row

    temp2 = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( lv_file ).
    temp2->get_table( IMPORTING result = lt_back ).
    cl_abap_unit_assert=>assert_initial( lt_back ).
  ENDMETHOD.

  METHOD header_as_name.
    TYPES:
      BEGIN OF ty_s_order,
        order_id TYPE i,
        net_eur  TYPE p LENGTH 8 DECIMALS 2,
      END OF ty_s_order.
    TYPES temp3 TYPE STANDARD TABLE OF ty_s_order WITH DEFAULT KEY.
DATA lt_order TYPE temp3.
    TYPES temp4 TYPE STANDARD TABLE OF ty_s_order WITH DEFAULT KEY.
DATA lt_back  TYPE temp4.

    DATA temp69 LIKE lt_order.
    DATA temp70 LIKE LINE OF temp69.
    DATA temp71 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA temp30 TYPE z2ui5_cl_tcl_xlsx=>ty_t_column.
    DATA temp31 LIKE LINE OF temp30.
    DATA lv_file TYPE xstring.
    CLEAR temp69.

    temp70-order_id = 4711.
    temp70-net_eur = `10.5`.
    INSERT temp70 INTO TABLE temp69.
    lt_order = temp69.
    " a header as a person writes it finds its component: ` Order Id `

    CLEAR temp71.

    CLEAR temp30.

    temp31-name = `ORDER_ID`.
    temp31-header = ` Order Id `.
    INSERT temp31 INTO TABLE temp30.
    temp31-name = `NET_EUR`.
    temp31-header = `net eur`.
    INSERT temp31 INTO TABLE temp30.
    temp71-t_column = temp30.

    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab(
        val    = lt_order
        layout = temp71 ).
    z2ui5_cl_tcl_xlsx=>itab_by_xlsx( EXPORTING val    = lv_file
                                          IMPORTING result = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = lt_order
                                        act = lt_back ).
  ENDMETHOD.

  METHOD without_header.
    DATA lt_back TYPE ty_t_row.

    DATA temp72 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA lv_file TYPE xstring.
    DATA temp1 TYPE REF TO z2ui5_cl_tcl_xlsx.
    CLEAR temp72.
    temp72-no_header = abap_true.

    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = rows( )
                                                          layout = temp72 ).

    temp1 = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( lv_file ).
    temp1->get_table( EXPORTING header_row = 0
                                                                   IMPORTING result     = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = rows( )
                                        act = lt_back ).
  ENDMETHOD.

  METHOD elementary_line.
    TYPES temp5 TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA lt_num  TYPE temp5.
    TYPES temp6 TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA lt_back TYPE temp6.

    DATA temp73 LIKE lt_num.
    DATA lv_file TYPE xstring.
    DATA temp96 TYPE xsdboolean.
    CLEAR temp73.
    INSERT 3 INTO TABLE temp73.
    INSERT -1 INTO TABLE temp73.
    INSERT 0 INTO TABLE temp73.
    lt_num = temp73.

    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( lt_num ).

    temp96 = boolc( ltcl_file=>part( file = lv_file name = `xl/worksheets/sheet1.xml` ) CS `>TABLE_LINE<` ).
    cl_abap_unit_assert=>assert_true( temp96 ).
    z2ui5_cl_tcl_xlsx=>itab_by_xlsx( EXPORTING val    = lv_file
                                          IMPORTING result = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = lt_num
                                        act = lt_back ).
  ENDMETHOD.

  METHOD text_like_a_code.
    " `_x0041_` is how a file names the character A - a text that reads
    " like that has to come back as it went in
    DATA lt_text TYPE string_table.
    DATA lt_back TYPE string_table.

    DATA temp75 TYPE string_table.
    CLEAR temp75.
    INSERT `a_x0041_b` INTO TABLE temp75.
    INSERT `_x` INTO TABLE temp75.
    INSERT `=SUM(A1)` INTO TABLE temp75.
    INSERT `007` INTO TABLE temp75.
    lt_text = temp75.
    z2ui5_cl_tcl_xlsx=>itab_by_xlsx( EXPORTING val    = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( lt_text )
                                          IMPORTING result = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = lt_text
                                        act = lt_back ).
  ENDMETHOD.

  METHOD timestamp.
    TYPES:
      BEGIN OF ty_s_stamp,
        stamp TYPE timestamp,
      END OF ty_s_stamp.
    TYPES temp7 TYPE STANDARD TABLE OF ty_s_stamp WITH DEFAULT KEY.
DATA lt_stamp TYPE temp7.
    TYPES temp8 TYPE STANDARD TABLE OF ty_s_stamp WITH DEFAULT KEY.
DATA lt_back  TYPE temp8.

    DATA temp77 LIKE lt_stamp.
    DATA temp78 LIKE LINE OF temp77.
    FIELD-SYMBOLS <temp79> LIKE LINE OF lt_stamp.
    DATA temp80 LIKE sy-tabix.
    DATA lv_file TYPE xstring.
    DATA temp97 TYPE xsdboolean.
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    FIELD-SYMBOLS <temp81> LIKE LINE OF lt_cell.
    DATA temp82 LIKE sy-tabix.
    DATA temp83 LIKE lt_stamp.
    DATA temp84 LIKE LINE OF temp83.
    CLEAR temp77.

    CLEAR temp78.
    temp78-stamp = `20240315103000`.
    INSERT temp78 INTO TABLE temp77.
    CLEAR temp78.
    INSERT temp78 INTO TABLE temp77.
    lt_stamp = temp77.
    " a timestamp is a packed number that says what it is by its name
    " only - a runtime that does not hand the name on writes the number


    temp80 = sy-tabix.
    READ TABLE lt_stamp INDEX 1 ASSIGNING <temp79>.
    sy-tabix = temp80.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF z2ui5_cl_tcl_context=>rtti_get_type_name( <temp79>-stamp ) <> `TIMESTAMP`.
      RETURN.
    ENDIF.


    lv_file = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( lt_stamp ).
    " the day and the fraction of the day, in the date-and-time format

    temp97 = boolc( ltcl_file=>part( file = lv_file name = `xl/worksheets/sheet1.xml` ) CS `<c r="A2" s="1"><v>45366.4375</v></c>` ).
    cl_abap_unit_assert=>assert_true( temp97 ).

    lt_cell = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( lv_file )->get_cells( ).


    temp82 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 ASSIGNING <temp81>.
    sy-tabix = temp82.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `2024-03-15T10:30:00`
                                        act = <temp81>-value ).


    CLEAR temp83.

    temp84-stamp = `20240315103000`.
    INSERT temp84 INTO TABLE temp83.
    lt_stamp = temp83.
    z2ui5_cl_tcl_xlsx=>itab_by_xlsx( EXPORTING val    = lv_file
                                          IMPORTING result = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = lt_stamp
                                        act = lt_back ).
  ENDMETHOD.

  METHOD start_cell.
    " rows that do not start in A1 are read by the row their header is in
    DATA lt_back TYPE ty_t_row.

    DATA temp85 TYPE z2ui5_cl_tcl_xlsx=>ty_s_layout.
    DATA lo_xlsx TYPE REF TO z2ui5_cl_tcl_xlsx.
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    DATA temp86 TYPE z2ui5_cl_tcl_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp32> LIKE LINE OF lt_cell.
    DATA temp33 LIKE sy-tabix.
    CLEAR temp85.
    temp85-start_cell = `C5`.

    lo_xlsx = z2ui5_cl_tcl_xlsx=>factory_by_xlsx(
                        z2ui5_cl_tcl_xlsx=>xlsx_by_itab( val    = rows( )
                                                              layout = temp85 ) ).
    lo_xlsx->get_table( EXPORTING header_row = 5
                        IMPORTING result     = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = rows( )
                                        act = lt_back ).


    lt_cell = lo_xlsx->get_cells( ).

    CLEAR temp86.
    temp86-row = 5.
    temp86-col = 3.
    temp86-kind = `S`.
    temp86-value = `TEXT`.


    temp33 = sy-tabix.
    READ TABLE lt_cell INDEX 1 ASSIGNING <temp32>.
    sy-tabix = temp33.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        exp = temp86
        act = <temp32> ).
  ENDMETHOD.

  METHOD other_target_types.
    " what was written as one type read into another: every cell as text,
    " a date and a flag as numbers
    TYPES:
      BEGIN OF ty_s_text,
        text   TYPE string,
        num    TYPE string,
        amount TYPE c LENGTH 20,
        date   TYPE string,
        time   TYPE string,
        flag   TYPE i,
      END OF ty_s_text.
    TYPES temp9 TYPE STANDARD TABLE OF ty_s_text WITH DEFAULT KEY.
DATA lt_back TYPE temp9.
    FIELD-SYMBOLS <temp87> LIKE LINE OF lt_back.
    DATA temp88 LIKE sy-tabix.
    FIELD-SYMBOLS <temp89> LIKE LINE OF lt_back.
    DATA temp90 LIKE sy-tabix.
    FIELD-SYMBOLS <temp91> LIKE LINE OF lt_back.
    DATA temp92 LIKE sy-tabix.
    FIELD-SYMBOLS <temp93> LIKE LINE OF lt_back.
    DATA temp94 LIKE sy-tabix.
    FIELD-SYMBOLS <temp95> LIKE LINE OF lt_back.
    DATA temp96 LIKE sy-tabix.

    z2ui5_cl_tcl_xlsx=>itab_by_xlsx( EXPORTING val    = z2ui5_cl_tcl_xlsx=>xlsx_by_itab( rows( ) )
                                          IMPORTING result = lt_back ).


    temp88 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp87>.
    sy-tabix = temp88.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `-5`
                                        act = <temp87>-num ).


    temp90 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp89>.
    sy-tabix = temp90.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `-1234.5`
                                        act = <temp89>-amount ).


    temp92 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp91>.
    sy-tabix = temp92.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `2024-03-15`
                                        act = <temp91>-date ).


    temp94 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp93>.
    sy-tabix = temp94.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `10:30:00`
                                        act = <temp93>-time ).


    temp96 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp95>.
    sy-tabix = temp96.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = <temp95>-flag ).
  ENDMETHOD.

ENDCLASS.


"! ================================================================
"! READING WHAT ANOTHER PROGRAM WROTE
"! ================================================================
CLASS ltcl_read DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.

    METHODS cell
      IMPORTING
        t_cell        TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell
        row           TYPE i
        col           TYPE i
      RETURNING
        VALUE(result) TYPE string.

    METHODS shared_strings       FOR TESTING RAISING cx_static_check.
    METHODS dates_by_format      FOR TESTING RAISING cx_static_check.
    METHODS numbers_as_stored    FOR TESTING RAISING cx_static_check.
    METHODS cells_without_address FOR TESTING RAISING cx_static_check.
    METHODS other_cell_types     FOR TESTING RAISING cx_static_check.
    METHODS date_system_1904     FOR TESTING RAISING cx_static_check.
    METHODS typed_from_text      FOR TESTING RAISING cx_static_check.
    METHODS cell_that_does_not_fit FOR TESTING RAISING cx_static_check.
    METHODS no_workbook          FOR TESTING RAISING cx_static_check.
    METHODS written_is_not_read  FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_read IMPLEMENTATION.

  METHOD cell.
    DATA ls_cell LIKE LINE OF t_cell.
    " kind and value in one, `-` for a cell that is not there
    result = `-`.

    LOOP AT t_cell INTO ls_cell.
      IF ls_cell-row = row AND ls_cell-col = col.
        result = |{ ls_cell-kind }:{ ls_cell-value }|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD shared_strings.
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    lt_cell = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( ltcl_file=>pack(
        shared = `<si><t>plain</t></si>`
              && `<si><r><rPr><b/></rPr><t>bold</t></r><r><t xml:space="preserve"> and not</t></r></si>`
              && `<si><t>kanji</t><rPh sb="0" eb="1"><t>reading</t></rPh><phoneticPr fontId="1"/></si>`
              && `<si><t>line 1_x000D__x000A_line 2 _x0041_ _x005F_x0041_ _xZZZZ_</t></si>`
              && `<si><t xml:space="preserve">  </t></si>`
        rows   = `<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c>`
              && `<c r="C1" t="s"><v>2</v></c><c r="D1" t="s"><v>3</v></c><c r="E1" t="s"><v>4</v></c>`
              && `<c r="F1" t="s"><v>99</v></c></row>` ) )->get_cells( ).

    cl_abap_unit_assert=>assert_equals( exp = `S:plain`
                                        act = cell( t_cell = lt_cell row = 1 col = 1 ) ).
    " a text formatted in parts is one text
    cl_abap_unit_assert=>assert_equals( exp = `S:bold and not`
                                        act = cell( t_cell = lt_cell row = 1 col = 2 ) ).
    " without the reading aid
    cl_abap_unit_assert=>assert_equals( exp = `S:kanji`
                                        act = cell( t_cell = lt_cell row = 1 col = 3 ) ).
    " a character named by its number, an underscore named that way, and
    " what only looks like one
    cl_abap_unit_assert=>assert_equals(
        exp = |S:line 1{ cl_abap_char_utilities=>cr_lf }line 2 A _x0041_ _xZZZZ_|
        act = cell( t_cell = lt_cell row = 1 col = 4 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `S:  `
                                        act = cell( t_cell = lt_cell row = 1 col = 5 ) ).
    " an index the file has no text for
    cl_abap_unit_assert=>assert_equals( exp = `-`
                                        act = cell( t_cell = lt_cell row = 1 col = 6 ) ).
  ENDMETHOD.

  METHOD dates_by_format.
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    lt_cell = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( ltcl_file=>pack(
        styles = `<numFmts count="4">`
              && `<numFmt numFmtId="164" formatCode="dd/mm/yyyy\ hh:mm"/>`
              && `<numFmt numFmtId="165" formatCode="[$-407]d\.\ mmmm\ yyyy;@"/>`
              && `<numFmt numFmtId="166" formatCode="#,##0.00\ &quot;days&quot;;[Red]\-#,##0.00"/>`
              && `<numFmt numFmtId="167" formatCode="[h]:mm:ss"/></numFmts>`
              && `<cellStyleXfs count="1"><xf numFmtId="14"/></cellStyleXfs>`
              && `<cellXfs count="7"><xf numFmtId="0"/><xf numFmtId="14"/><xf numFmtId="164"/>`
              && `<xf numFmtId="165"/><xf numFmtId="166"/><xf numFmtId="20"/><xf numFmtId="167"/></cellXfs>`
        rows   = `<row r="1"><c r="A1"><v>45366</v></c><c r="B1" s="1"><v>45366</v></c>`
              && `<c r="C1" s="2"><v>45366.4375</v></c><c r="D1" s="3"><v>45366</v></c>`
              && `<c r="E1" s="4"><v>45366</v></c><c r="F1" s="5"><v>0.4375</v></c>`
              && `<c r="G1" s="6"><v>1.5</v></c><c r="H1" s="6"><v>0.5</v></c></row>`
              && `<row r="2"><c r="A2" s="2"><v>45366.999999</v></c><c r="B2" s="1"><v>60</v></c>`
              && `<c r="C2" s="1"><v>1</v></c><c r="D2" s="1"><v>0</v></c>`
              && `<c r="E2" s="1"><v>45366.75</v></c><c r="F2" s="5"><v>45366.75</v></c></row>` ) )->get_cells( ).

    " the same number is a number, a date or a date with its time - by
    " the format of its cell, a built-in one or one of the file
    cl_abap_unit_assert=>assert_equals( exp = `N:45366`
                                        act = cell( t_cell = lt_cell row = 1 col = 1 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `D:2024-03-15`
                                        act = cell( t_cell = lt_cell row = 1 col = 2 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `M:2024-03-15T10:30:00`
                                        act = cell( t_cell = lt_cell row = 1 col = 3 ) ).
    " a locale in brackets and escaped characters are no part of the format
    cl_abap_unit_assert=>assert_equals( exp = `D:2024-03-15`
                                        act = cell( t_cell = lt_cell row = 1 col = 4 ) ).
    " the d and the y of a quoted text and the Red of a colour make no date
    cl_abap_unit_assert=>assert_equals( exp = `N:45366`
                                        act = cell( t_cell = lt_cell row = 1 col = 5 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `T:10:30:00`
                                        act = cell( t_cell = lt_cell row = 1 col = 6 ) ).
    " a duration runs on past 24 hours
    cl_abap_unit_assert=>assert_equals( exp = `S:36:00:00`
                                        act = cell( t_cell = lt_cell row = 1 col = 7 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `T:12:00:00`
                                        act = cell( t_cell = lt_cell row = 1 col = 8 ) ).

    " a second before midnight that rounds up is the next day
    cl_abap_unit_assert=>assert_equals( exp = `M:2024-03-16T00:00:00`
                                        act = cell( t_cell = lt_cell row = 2 col = 1 ) ).
    " the 1900-02-29 of Excel is the first of March, day 1 the first of January
    cl_abap_unit_assert=>assert_equals( exp = `D:1900-03-01`
                                        act = cell( t_cell = lt_cell row = 2 col = 2 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `D:1900-01-01`
                                        act = cell( t_cell = lt_cell row = 2 col = 3 ) ).
    " day 0 is no date
    cl_abap_unit_assert=>assert_equals( exp = `N:0`
                                        act = cell( t_cell = lt_cell row = 2 col = 4 ) ).
    " a date format shows the day, a time format the time of a date with one
    cl_abap_unit_assert=>assert_equals( exp = `D:2024-03-15`
                                        act = cell( t_cell = lt_cell row = 2 col = 5 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `T:18:00:00`
                                        act = cell( t_cell = lt_cell row = 2 col = 6 ) ).
  ENDMETHOD.

  METHOD numbers_as_stored.
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    lt_cell = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( ltcl_file=>pack(
        rows = `<row r="3"><c r="A3"><v>1.5E-3</v></c><c r="B3"><v>0.30000000000000004</v></c>`
            && `<c r="C3"><v>-1.2345E+4</v></c><c r="D3"><v>12.50</v></c><c r="E3"><v>1E+20</v></c>`
            && `<c r="F3"><v>0.1</v><f>A3*2</f></c><c r="G3"><v>999999999999999.9</v></c>`
            && `<c r="H3"><v>0.0</v></c></row>` ) )->get_cells( ).

    " without exponent, and without the digits of the binary number
    cl_abap_unit_assert=>assert_equals( exp = `N:0.0015`
                                        act = cell( t_cell = lt_cell row = 3 col = 1 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:0.3`
                                        act = cell( t_cell = lt_cell row = 3 col = 2 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:-12345`
                                        act = cell( t_cell = lt_cell row = 3 col = 3 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:12.5`
                                        act = cell( t_cell = lt_cell row = 3 col = 4 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:100000000000000000000`
                                        act = cell( t_cell = lt_cell row = 3 col = 5 ) ).
    " a formula cell with the value it had last
    cl_abap_unit_assert=>assert_equals( exp = `N:0.1`
                                        act = cell( t_cell = lt_cell row = 3 col = 6 ) ).
    " the 16th digit rounds, and the carry runs through
    cl_abap_unit_assert=>assert_equals( exp = `N:1000000000000000`
                                        act = cell( t_cell = lt_cell row = 3 col = 7 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:0`
                                        act = cell( t_cell = lt_cell row = 3 col = 8 ) ).
  ENDMETHOD.

  METHOD cells_without_address.
    " r is optional: a cell follows the one before, a row the row before
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    lt_cell = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( ltcl_file=>pack(
        rows = `<row><c><v>1</v></c><c><v>2</v></c></row><row/>`
            && `<row r="5"><c r="C5"><v>3</v></c><c><v>4</v></c></row><row><c><v>5</v></c></row>` ) )->get_cells( ).

    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = lines( lt_cell ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:2`
                                        act = cell( t_cell = lt_cell row = 1 col = 2 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:3`
                                        act = cell( t_cell = lt_cell row = 5 col = 3 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:4`
                                        act = cell( t_cell = lt_cell row = 5 col = 4 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:5`
                                        act = cell( t_cell = lt_cell row = 6 col = 1 ) ).
  ENDMETHOD.

  METHOD other_cell_types.
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    lt_cell = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( ltcl_file=>pack(
        rows = `<row r="1"><c r="A1" t="str"><f>A2&amp;"x"</f><v>result</v></c><c r="B1" t="b"><v>1</v></c>`
            && `<c r="C1" t="b"><v>0</v></c><c r="D1" t="e"><v>#DIV/0!</v></c>`
            && `<c r="E1" t="inlineStr"><is><r><t>in</t></r><r><t>line</t></r></is></c>`
            && `<c r="F1" t="d"><v>2024-03-15</v></c><c r="G1" t="d"><v>2024-03-15T10:30:00.000Z</v></c>`
            && `<c r="H1" s="3"/><c r="I1" t="n"><v>7</v></c></row>` ) )->get_cells( ).

    cl_abap_unit_assert=>assert_equals( exp = `S:result`
                                        act = cell( t_cell = lt_cell row = 1 col = 1 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `B:X`
                                        act = cell( t_cell = lt_cell row = 1 col = 2 ) ).
    " a FALSE is a cell, and empty
    cl_abap_unit_assert=>assert_equals( exp = `B:`
                                        act = cell( t_cell = lt_cell row = 1 col = 3 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `E:#DIV/0!`
                                        act = cell( t_cell = lt_cell row = 1 col = 4 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `S:inline`
                                        act = cell( t_cell = lt_cell row = 1 col = 5 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `D:2024-03-15`
                                        act = cell( t_cell = lt_cell row = 1 col = 6 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `M:2024-03-15T10:30:00`
                                        act = cell( t_cell = lt_cell row = 1 col = 7 ) ).
    " a cell that is formatted only is none
    cl_abap_unit_assert=>assert_equals( exp = `-`
                                        act = cell( t_cell = lt_cell row = 1 col = 8 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `N:7`
                                        act = cell( t_cell = lt_cell row = 1 col = 9 ) ).
  ENDMETHOD.

  METHOD date_system_1904.
    " day 0 is 1904-01-01 - the same number is another date
    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
    lt_cell = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( ltcl_file=>pack(
        workbook_pr = `<workbookPr date1904="1"/>`
        styles      = `<cellXfs count="2"><xf numFmtId="0"/><xf numFmtId="14"/></cellXfs>`
        rows        = `<row r="1"><c r="A1" s="1"><v>43904</v></c></row>` ) )->get_cells( ).
    cl_abap_unit_assert=>assert_equals( exp = `D:2024-03-15`
                                        act = cell( t_cell = lt_cell row = 1 col = 1 ) ).
  ENDMETHOD.

  METHOD typed_from_text.
    " a sheet a person filled in: everything typed as text, in the
    " notations people use
    TYPES:
      BEGIN OF ty_s_row,
        day    TYPE d,
        day2   TYPE d,
        day3   TYPE d,
        at     TYPE t,
        at2    TYPE t,
        amount TYPE p LENGTH 8 DECIMALS 2,
        flag   TYPE abap_bool,
        numc   TYPE n LENGTH 6,
        serial TYPE d,
      END OF ty_s_row.
    TYPES temp10 TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA lt_row TYPE temp10.
    DATA ls_row LIKE LINE OF lt_row.
    FIELD-SYMBOLS <temp34> LIKE LINE OF lt_row.
    DATA temp35 LIKE sy-tabix.
    DATA temp97 TYPE d.
    DATA temp98 TYPE d.
    DATA temp99 TYPE d.
    DATA temp100 TYPE t.
    DATA temp101 TYPE t.
    DATA temp102 TYPE decfloat34.
    DATA temp36 TYPE decfloat34.
    DATA temp103 TYPE string.
    DATA temp104 TYPE d.

    z2ui5_cl_tcl_xlsx=>itab_by_xlsx(
      EXPORTING
        val    = ltcl_file=>pack(
                     rows = `<row r="1"><c r="A1" t="inlineStr"><is><t>DAY</t></is></c>`
                         && `<c r="B1" t="inlineStr"><is><t>day2</t></is></c>`
                         && `<c r="C1" t="inlineStr"><is><t>Day3</t></is></c>`
                         && `<c r="D1" t="inlineStr"><is><t>AT</t></is></c>`
                         && `<c r="E1" t="inlineStr"><is><t>AT2</t></is></c>`
                         && `<c r="F1" t="inlineStr"><is><t>AMOUNT</t></is></c>`
                         && `<c r="G1" t="inlineStr"><is><t>FLAG</t></is></c>`
                         && `<c r="H1" t="inlineStr"><is><t>NUMC</t></is></c>`
                         && `<c r="I1" t="inlineStr"><is><t>SERIAL</t></is></c>`
                         && `<c r="J1" t="inlineStr"><is><t>NO COMPONENT</t></is></c></row>`
                         && `<row r="2"><c r="A2" t="inlineStr"><is><t>2024-03-15</t></is></c>`
                         && `<c r="B2" t="inlineStr"><is><t>15.03.2024</t></is></c>`
                         && `<c r="C2"><v>20240315</v></c>`
                         && `<c r="D2" t="inlineStr"><is><t>10:30</t></is></c>`
                         && `<c r="E2"><v>0.4375</v></c>`
                         && `<c r="F2" t="inlineStr"><is><t>1.234,56</t></is></c>`
                         && `<c r="G2" t="inlineStr"><is><t>true</t></is></c>`
                         && `<c r="H2"><v>42</v></c>`
                         && `<c r="I2"><v>45366</v></c>`
                         && `<c r="J2"><v>1</v></c></row>` )
      IMPORTING
        result = lt_row ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_row ) ).



    temp35 = sy-tabix.
    READ TABLE lt_row INDEX 1 ASSIGNING <temp34>.
    sy-tabix = temp35.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_row = <temp34>.

    temp97 = `20240315`.
    cl_abap_unit_assert=>assert_equals( exp = temp97
                                        act = ls_row-day ).

    temp98 = `20240315`.
    cl_abap_unit_assert=>assert_equals( exp = temp98
                                        act = ls_row-day2 ).

    temp99 = `20240315`.
    cl_abap_unit_assert=>assert_equals( exp = temp99
                                        act = ls_row-day3 ).

    temp100 = `103000`.
    cl_abap_unit_assert=>assert_equals( exp = temp100
                                        act = ls_row-at ).

    temp101 = `103000`.
    cl_abap_unit_assert=>assert_equals( exp = temp101
                                        act = ls_row-at2 ).

    temp102 = `1234.56`.

    temp36 = ls_row-amount.
    cl_abap_unit_assert=>assert_equals( exp = temp102
                                        act = temp36 ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = ls_row-flag ).

    temp103 = ls_row-numc.
    cl_abap_unit_assert=>assert_equals( exp = `000042`
                                        act = temp103 ).
    " a number in a date component that is no YYYYMMDD is the day Excel counts

    temp104 = `20240315`.
    cl_abap_unit_assert=>assert_equals( exp = temp104
                                        act = ls_row-serial ).
  ENDMETHOD.

  METHOD cell_that_does_not_fit.
    TYPES:
      BEGIN OF ty_s_row,
        num TYPE i,
        day TYPE d,
      END OF ty_s_row.
    TYPES temp11 TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA lt_row TYPE temp11.
        DATA x TYPE REF TO z2ui5_cx_tcl_error.
        DATA temp98 TYPE xsdboolean.
        DATA temp99 TYPE xsdboolean.
        DATA temp100 TYPE xsdboolean.
        DATA temp101 TYPE xsdboolean.
        DATA temp102 TYPE xsdboolean.

    " a text in a number: the address of the cell and what it holds
    TRY.
        z2ui5_cl_tcl_xlsx=>itab_by_xlsx(
          EXPORTING
            val    = ltcl_file=>pack(
                         rows = `<row r="1"><c r="A1" t="inlineStr"><is><t>NUM</t></is></c></row>`
                             && `<row r="2"><c r="A2"><v>1</v></c></row>`
                             && `<row r="3"><c r="A3" t="inlineStr"><is><t>total</t></is></c></row>` )
          IMPORTING
            result = lt_row ).
        cl_abap_unit_assert=>fail( `a text in a number component has to raise` ).

      CATCH z2ui5_cx_tcl_error INTO x.

        temp98 = boolc( x->get_text( ) CS `XLSX_CELL_TYPE` ).
        cl_abap_unit_assert=>assert_true( temp98 ).

        temp99 = boolc( x->get_text( ) CS `cell A3` ).
        cl_abap_unit_assert=>assert_true( temp99 ).

        temp100 = boolc( x->get_text( ) CS `total` ).
        cl_abap_unit_assert=>assert_true( temp100 ).
    ENDTRY.

    TRY.
        z2ui5_cl_tcl_xlsx=>itab_by_xlsx(
          EXPORTING
            val    = ltcl_file=>pack(
                         rows = `<row r="1"><c r="A1" t="inlineStr"><is><t>DAY</t></is></c></row>`
                             && `<row r="2"><c r="A2" t="inlineStr"><is><t>soon</t></is></c></row>` )
          IMPORTING
            result = lt_row ).
        cl_abap_unit_assert=>fail( `a text that is no date has to raise` ).
      CATCH z2ui5_cx_tcl_error INTO x.

        temp101 = boolc( x->get_text( ) CS `is no date` ).
        cl_abap_unit_assert=>assert_true( temp101 ).
    ENDTRY.

    " an error cell is no value for any component
    TRY.
        z2ui5_cl_tcl_xlsx=>itab_by_xlsx(
          EXPORTING
            val    = ltcl_file=>pack(
                         rows = `<row r="1"><c r="A1" t="inlineStr"><is><t>NUM</t></is></c></row>`
                             && `<row r="2"><c r="A2" t="e"><v>#N/A</v></c></row>` )
          IMPORTING
            result = lt_row ).
        cl_abap_unit_assert=>fail( `an error cell has to raise` ).
      CATCH z2ui5_cx_tcl_error INTO x.

        temp102 = boolc( x->get_text( ) CS `XLSX_CELL_ERROR` ).
        cl_abap_unit_assert=>assert_true( temp102 ).
    ENDTRY.
  ENDMETHOD.

  METHOD no_workbook.
        DATA temp105 TYPE xstring.
        DATA x TYPE REF TO z2ui5_cx_tcl_error.
        DATA temp103 TYPE xsdboolean.
        DATA temp106 TYPE xstring.
        DATA temp104 TYPE xsdboolean.
        DATA temp109 TYPE xsdboolean.
        DATA temp107 TYPE z2ui5_cl_tcl_context=>ty_t_zip_file.
        DATA temp108 LIKE LINE OF temp107.
        DATA temp37 TYPE xstring.
        DATA temp110 TYPE xsdboolean.
    " not a ZIP archive at all
    TRY.

        temp105 = `48656C6C6F2C20776F726C64`.
        z2ui5_cl_tcl_xlsx=>factory_by_xlsx( temp105 ).
        cl_abap_unit_assert=>fail( `a file that is no workbook has to raise` ).

      CATCH z2ui5_cx_tcl_error INTO x.

        temp103 = boolc( x->get_text( ) CS `XLSX_NO_WORKBOOK` ).
        cl_abap_unit_assert=>assert_true( temp103 ).
    ENDTRY.

    " the container of an .xls file of Excel 97-2003
    TRY.

        temp106 = `D0CF11E0A1B11AE10000000000000000`.
        z2ui5_cl_tcl_xlsx=>factory_by_xlsx( temp106 ).
        cl_abap_unit_assert=>fail( `an .xls file has to raise` ).
      CATCH z2ui5_cx_tcl_error INTO x.

        temp104 = boolc( x->get_text( ) CS `XLSX_NO_WORKBOOK` ).
        cl_abap_unit_assert=>assert_true( temp104 ).

        temp109 = boolc( x->get_text( ) CS `.xls` ).
        cl_abap_unit_assert=>assert_true( temp109 ).
    ENDTRY.

    " a ZIP archive that is no workbook
    TRY.

        CLEAR temp107.

        temp108-name = `readme.txt`.

        temp37 = `414243`.
        temp108-content = temp37.
        INSERT temp108 INTO TABLE temp107.
        z2ui5_cl_tcl_xlsx=>factory_by_xlsx( z2ui5_cl_tcl_context=>zip_pack(
            temp107 ) ).
        cl_abap_unit_assert=>fail( `an archive without a workbook has to raise` ).
      CATCH z2ui5_cx_tcl_error INTO x.

        temp110 = boolc( x->get_text( ) CS `XLSX_NO_WORKBOOK` ).
        cl_abap_unit_assert=>assert_true( temp110 ).
    ENDTRY.
  ENDMETHOD.

  METHOD written_is_not_read.
    DATA lt_text TYPE string_table.
        DATA x TYPE REF TO z2ui5_cx_tcl_error.
        DATA temp111 TYPE xsdboolean.
        DATA temp112 TYPE xsdboolean.

    TRY.
        z2ui5_cl_tcl_xlsx=>factory( )->add_sheet( lt_text )->get_cells( ).
        cl_abap_unit_assert=>fail( `a workbook that is written is not read` ).

      CATCH z2ui5_cx_tcl_error INTO x.

        temp111 = boolc( x->get_text( ) CS `XLSX_NOT_READ` ).
        cl_abap_unit_assert=>assert_true( temp111 ).
    ENDTRY.
    TRY.
        z2ui5_cl_tcl_xlsx=>factory_by_xlsx( z2ui5_cl_tcl_xlsx=>xlsx_by_itab( lt_text )
            )->add_sheet( lt_text ).
        cl_abap_unit_assert=>fail( `a workbook that was read takes no sheet` ).
      CATCH z2ui5_cx_tcl_error INTO x.

        temp112 = boolc( x->get_text( ) CS `XLSX_READ_ONLY` ).
        cl_abap_unit_assert=>assert_true( temp112 ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
