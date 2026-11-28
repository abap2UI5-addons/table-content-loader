"! <p class="shorttext synchronized">util - xlsx reader and writer</p>
"! An Excel workbook (.xlsx, Office Open XML) written from internal tables and
"! read into them - no abap2xlsx, no XCO. What the class needs of the system
"! (ZIP, UTF-8, the XML reader, RTTI) it takes from z2ui5_cl_tcl_context,
"! so it runs on every release down to 7.02 and on ABAP Cloud.
"!
"! Writing - one sheet per internal table, the file as an xstring:
"!
"!     DATA(lv_file) = z2ui5_cl_tcl_xlsx=>factory(
"!         )->add_sheet( val  = lt_orders
"!                       name = `Orders`
"!         )->add_sheet( val    = lt_items
"!                       name   = `Items`
"!                       layout = VALUE #( freeze_header = abap_true
"!                                         table_style   = `TableStyleMedium2` )
"!         )->get_xlsx( ).
"!
"! A number is a number cell, a date a date, a time a time, a timestamp a
"! date with its time, a flag (abap_bool) a boolean; a NUMC keeps its leading
"! zeros as text. A component that is a structure, a table or a reference is
"! left out.
"!
"! Reading - into a typed table by the header row, into a table of strings
"! whose columns are the header row, or cell by cell:
"!
"!     DATA(lo_xlsx) = z2ui5_cl_tcl_xlsx=>factory_by_xlsx( lv_file ).
"!     lo_xlsx->get_table( EXPORTING sheet  = `Orders`
"!                         IMPORTING result = lt_orders ).
"!     DATA(lr_any) = lo_xlsx->get_table_ref( index = 2 ).
"!     DATA(lt_cell) = lo_xlsx->get_cells( ).
"!
"! The layout of a sheet also places it (start_cell), names and styles its
"! Excel table, and gives it formula columns and a totals row - see
"! ty_s_layout and ty_s_column.
"!
"! Not in it: formatting cell by cell, a formula in a single cell (a formula
"! cell is read with its last value), merged cells, charts, images, an .xls
"! file of Excel 97-2003, a workbook with a password, changing a workbook
"! that was read.
CLASS z2ui5_cl_tcl_xlsx DEFINITION
  PUBLIC FINAL
  CREATE PROTECTED.

  PUBLIC SECTION.

    TYPES:
      "! a column of a sheet that is written, or the header of a column that
      "! is read into a component of another name
      BEGIN OF ty_s_column,
        "! the component of the row
        name    TYPE string,
        "! the text of the header cell - empty: the component name
        header  TYPE string,
        "! a number format as Excel writes it (`#,##0.00`, `0.0%`,
        "! `dd.mm.yyyy`) - empty: by the type of the component
        format  TYPE string,
        "! the width in characters - 0: by the content
        width   TYPE i,
        "! a formula instead of a component: every cell of the column holds
        "! it, with `{row}` for the number of its row (`C{row}*D{row}`). Such
        "! a column needs no name, and Excel works its values out when the
        "! file is opened
        formula TYPE string,
        "! the cell of the column in a totals row under the rows: `sum`,
        "! `average`, `count`, `countNums`, `min`, `max`, `stdDev` or `var` -
        "! any other text is a label (`Total`). One column with it gives
        "! the sheet the row
        total   TYPE string,
      END OF ty_s_column.
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH DEFAULT KEY.

    TYPES:
      "! how a sheet is written - initial: every elementary component in its
      "! order under a bold header row of the component names
      BEGIN OF ty_s_layout,
        "! the columns and their order - empty: every elementary component
        t_column       TYPE ty_t_column,
        "! no header row, the data starts in the first row
        no_header      TYPE abap_bool,
        "! the header from the data element (medium text) where a component
        "! has one and the column names no header itself
        ddic_header    TYPE abap_bool,
        "! the header row stays in place while the rows scroll
        freeze_header  TYPE abap_bool,
        "! filter buttons on the header row
        auto_filter    TYPE abap_bool,
        "! the rows as an Excel table of that style (`TableStyleMedium2`,
        "! `TableStyleLight9`, ...), with stripes and filter buttons. Needs
        "! the header row and at least one row
        table_style    TYPE string,
        "! the name of the Excel table, as a formula names it - empty:
        "! Table1, Table2, ... What Excel does not take in a name is made
        "! valid
        table_name     TYPE string,
        "! the Excel table without the stripes of its rows
        no_row_stripes TYPE abap_bool,
        "! the Excel table with stripes down its columns
        column_stripes TYPE abap_bool,
        "! the Excel table without its filter buttons
        no_filter      TYPE abap_bool,
        "! the cell the header row starts in (`B3`) - empty: A1
        start_cell     TYPE string,
      END OF ty_s_layout.

    TYPES:
      "! a cell as get_cells( ) reads it. value by kind: a number without
      "! exponent and with a period (`-12.5`), a date `YYYY-MM-DD`, a time
      "! `HH:MM:SS`, a timestamp `YYYY-MM-DDTHH:MM:SS`, a boolean `X` or
      "! empty, an error as Excel shows it (`#DIV/0!`)
      BEGIN OF ty_s_cell,
        row   TYPE i,
        col   TYPE i,
        kind  TYPE string,
        value TYPE string,
      END OF ty_s_cell.
    TYPES ty_t_cell TYPE STANDARD TABLE OF ty_s_cell WITH DEFAULT KEY.

    CONSTANTS:
      BEGIN OF cs_kind,
        text      TYPE string VALUE `S` ##NO_TEXT,
        number    TYPE string VALUE `N` ##NO_TEXT,
        date      TYPE string VALUE `D` ##NO_TEXT,
        time      TYPE string VALUE `T` ##NO_TEXT,
        timestamp TYPE string VALUE `M` ##NO_TEXT,
        boolean   TYPE string VALUE `B` ##NO_TEXT,
        error     TYPE string VALUE `E` ##NO_TEXT,
      END OF cs_kind.

    "! the MIME type of an .xlsx file - for a download or a mail attachment
    CONSTANTS mime_type TYPE string
      VALUE `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` ##NO_TEXT.

    "! a new workbook, to be filled with add_sheet( )
    CLASS-METHODS factory
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_tcl_xlsx.

    "! the workbook of a file, to be read - z2ui5_cx_tcl_error when the
    "! file is no .xlsx workbook
    CLASS-METHODS factory_by_xlsx
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_tcl_xlsx.

    "! a workbook of one sheet, in one call
    CLASS-METHODS xlsx_by_itab
      IMPORTING
        val           TYPE ANY TABLE
        layout        TYPE ty_s_layout OPTIONAL
      RETURNING
        VALUE(result) TYPE xstring.

    "! the first sheet of a file into a table, by its header row - see
    "! get_table( )
    CLASS-METHODS itab_by_xlsx
      IMPORTING
        val    TYPE xstring
      EXPORTING
        result TYPE ANY TABLE.

    "! One more sheet with the rows of val - rendered at once, so val is
    "! not kept. A name Excel does not take (longer than 31 characters,
    "! one of \ / ? * [ ] :, a name the workbook has) is made valid.
    "! @parameter name | empty: Sheet1, Sheet2, ...
    METHODS add_sheet
      IMPORTING
        val           TYPE ANY TABLE
        name          TYPE clike       OPTIONAL
        layout        TYPE ty_s_layout OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_tcl_xlsx.

    "! the file of the workbook built with add_sheet( )
    METHODS get_xlsx
      RETURNING
        VALUE(result) TYPE xstring.

    "! the names of the sheets, in the order of the workbook
    METHODS get_sheet_names
      RETURNING
        VALUE(result) TYPE string_table.

    "! Every cell of a sheet that holds a value, row by row.
    "! @parameter sheet | the name of the sheet - empty: the sheet at index
    METHODS get_cells
      IMPORTING
        sheet         TYPE clike OPTIONAL
        index         TYPE i     DEFAULT 1
      RETURNING
        VALUE(result) TYPE ty_t_cell.

    "! A sheet into a table. A column goes to the component its header
    "! names - the component name, or the header t_column gives for it;
    "! upper and lower case and the blanks around make no difference, a
    "! column without a component is left out. Every value is converted to
    "! the type of its component; a cell that does not fit (a text in a
    "! number, a number in a date) raises with its address.
    "! @parameter header_row | 0: no header, the n-th column goes to the n-th component
    METHODS get_table
      IMPORTING
        sheet      TYPE clike       OPTIONAL
        index      TYPE i           DEFAULT 1
        header_row TYPE i           DEFAULT 1
        t_column   TYPE ty_t_column OPTIONAL
      EXPORTING
        result     TYPE ANY TABLE.

    "! A sheet as a table of strings whose components are named after the
    "! header row (`Order Id` becomes ORDER_ID; a column without a header,
    "! or all of them with header_row 0, after its letters A, B, ...).
    "! Values as get_cells( ) gives them. Unbound for a sheet without a cell
    METHODS get_table_ref
      IMPORTING
        sheet         TYPE clike OPTIONAL
        index         TYPE i     DEFAULT 1
        header_row    TYPE i     DEFAULT 1
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! 1 gives A, 27 gives AA, 16384 gives XFD
    CLASS-METHODS column_to_letters
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE string.

    "! A gives 1, AA gives 27 - of a cell address (`$AB$12`) the column
    CLASS-METHODS column_to_number
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE i.

  PROTECTED SECTION.

  PRIVATE SECTION.

    " what a component is for a cell - cs_kind, and two more that are
    " text in the file but not in ABAP
    CONSTANTS:
      BEGIN OF cs_cat,
        text      TYPE string VALUE `S` ##NO_TEXT,
        number    TYPE string VALUE `N` ##NO_TEXT,
        date      TYPE string VALUE `D` ##NO_TEXT,
        time      TYPE string VALUE `T` ##NO_TEXT,
        timestamp TYPE string VALUE `M` ##NO_TEXT,
        boolean   TYPE string VALUE `B` ##NO_TEXT,
        numc      TYPE string VALUE `C` ##NO_TEXT,
        hex       TYPE string VALUE `X` ##NO_TEXT,
      END OF cs_cat.

    " the number formats Excel has built in (styles.xml names them by id
    " only). 14 and 22 show a date the way the user's Excel is set up
    CONSTANTS:
      BEGIN OF cs_numfmt,
        general  TYPE i VALUE 0,
        date     TYPE i VALUE 14,
        time     TYPE i VALUE 21,
        datetime TYPE i VALUE 22,
        custom   TYPE i VALUE 164,
      END OF cs_numfmt.

    CONSTANTS:
      BEGIN OF cs_ns,
        main    TYPE string VALUE `http://schemas.openxmlformats.org/spreadsheetml/2006/main` ##NO_TEXT,
        rel     TYPE string VALUE `http://schemas.openxmlformats.org/officeDocument/2006/relationships` ##NO_TEXT,
        pkg_rel TYPE string VALUE `http://schemas.openxmlformats.org/package/2006/relationships` ##NO_TEXT,
        types   TYPE string VALUE `http://schemas.openxmlformats.org/package/2006/content-types` ##NO_TEXT,
        ct      TYPE string VALUE `application/vnd.openxmlformats-officedocument.spreadsheetml` ##NO_TEXT,
      END OF cs_ns.

    CONSTANTS cv_xml_head TYPE string VALUE `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` ##NO_TEXT.
    CONSTANTS cv_letters  TYPE string VALUE `ABCDEFGHIJKLMNOPQRSTUVWXYZ` ##NO_TEXT.
    CONSTANTS cv_hex      TYPE string VALUE `0123456789ABCDEF` ##NO_TEXT.
    CONSTANTS cv_digits   TYPE string VALUE `0123456789` ##NO_TEXT.
    CONSTANTS cv_max_row  TYPE i VALUE 1048576.
    CONSTANTS cv_max_col  TYPE i VALUE 16384.
    " day 0 of the Excel date system: with it the serial number of every
    " date from 1900-03-01 on is the difference in days (Excel counts a
    " 1900-02-29 that never was)
    CONSTANTS cv_date_base TYPE d VALUE '18991230'.
    CONSTANTS cv_date_1900 TYPE d VALUE '19000101'.
    CONSTANTS cv_date_march TYPE d VALUE '19000301'.
    CONSTANTS cv_date_1904 TYPE d VALUE '19040101'.
    CONSTANTS cv_date_max  TYPE d VALUE '99991231'.

    " a component of the row, by name and by what it is for a cell
    TYPES:
      BEGIN OF ty_s_field,
        name     TYPE string,
        cat      TYPE string,
        rollname TYPE string,
      END OF ty_s_field.
    TYPES ty_t_field TYPE STANDARD TABLE OF ty_s_field WITH DEFAULT KEY.

    " a column while its sheet is written
    TYPES:
      BEGIN OF ty_s_out_col,
        name        TYPE string,
        header      TYPE string,
        letters     TYPE string,
        cat         TYPE string,
        style       TYPE string,
        width       TYPE i,
        len         TYPE i,
        formula     TYPE string,
        " the totals row: the function and its number in SUBTOTAL( ), or a
        " label - and what the rows add up to, for the value the cell
        " shows before Excel has worked the formula out
        total_fn    TYPE string,
        total_code  TYPE i,
        total_label TYPE string,
        sum         TYPE decfloat34,
        low         TYPE decfloat34,
        high        TYPE decfloat34,
        cells       TYPE i,
        numbers     TYPE i,
      END OF ty_s_out_col.
    TYPES ty_t_out_col TYPE STANDARD TABLE OF ty_s_out_col WITH DEFAULT KEY.

    " a sheet that is written: its part, and the part of its table
    TYPES:
      BEGIN OF ty_s_out_sheet,
        name      TYPE string,
        xml       TYPE xstring,
        table_xml TYPE xstring,
      END OF ty_s_out_sheet.

    " a cell format of styles.xml - the row index less one is what a cell
    " names in its s attribute
    TYPES:
      BEGIN OF ty_s_xf,
        numfmt TYPE i,
        bold   TYPE abap_bool,
      END OF ty_s_xf.

    TYPES:
      BEGIN OF ty_s_sheet,
        name TYPE string,
        path TYPE string,
      END OF ty_s_sheet.

    TYPES:
      BEGIN OF ty_s_rel,
        id     TYPE string,
        type   TYPE string,
        target TYPE string,
      END OF ty_s_rel.
    TYPES ty_t_rel TYPE STANDARD TABLE OF ty_s_rel WITH DEFAULT KEY.

    " writing
    TYPES temp1_6e09ec3c1d TYPE STANDARD TABLE OF ty_s_out_sheet WITH DEFAULT KEY.
DATA mt_out_sheet TYPE temp1_6e09ec3c1d.
    TYPES temp2_6e09ec3c1d TYPE STANDARD TABLE OF ty_s_xf WITH DEFAULT KEY.
DATA mt_xf        TYPE temp2_6e09ec3c1d.
    DATA mt_numfmt    TYPE string_table.
    DATA mv_tables    TYPE i.
    DATA mt_table_name TYPE string_table.
    DATA mv_formulas  TYPE abap_bool.

    " reading
    DATA mv_loaded     TYPE abap_bool.
    DATA mt_part       TYPE z2ui5_cl_tcl_context=>ty_t_zip_file.
    TYPES temp3_6e09ec3c1d TYPE STANDARD TABLE OF ty_s_sheet WITH DEFAULT KEY.
DATA mt_sheet      TYPE temp3_6e09ec3c1d.
    DATA mt_shared     TYPE string_table.
    DATA mt_style_kind TYPE string_table.
    DATA mv_date1904   TYPE abap_bool.

    " ----- writing

    "! the elementary components of a row - of a row that is no structure
    "! the one field TABLE_LINE
    METHODS fields_get
      IMPORTING
        row           TYPE any
      EXPORTING
        elementary    TYPE abap_bool
        result        TYPE ty_t_field.

    "! what a type is for a cell - empty for one that is none (a structure,
    "! a table, a reference)
    METHODS category_get
      IMPORTING
        type_kind     TYPE clike
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    METHODS columns_get
      IMPORTING
        t_field       TYPE ty_t_field
        layout        TYPE ty_s_layout
        offset        TYPE i
      RETURNING
        VALUE(result) TYPE ty_t_out_col.

    "! the field of that name - initial when the row has none
    CLASS-METHODS field_find
      IMPORTING
        t_field       TYPE ty_t_field
        name          TYPE string
      RETURNING
        VALUE(result) TYPE ty_s_field.

    "! a function of a totals row and its number in SUBTOTAL( ) - code 0
    "! for a text that is none, a label
    CLASS-METHODS total_function
      IMPORTING
        val  TYPE string
      EXPORTING
        name TYPE string
        code TYPE i.

    "! what a totals cell shows before Excel has worked its formula out -
    "! empty for a function that is not worked out here
    METHODS total_value
      IMPORTING
        col           TYPE ty_s_out_col
      RETURNING
        VALUE(result) TYPE string.

    "! a name Excel takes for a table, and that no other table of the
    "! workbook has
    METHODS table_name_get
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    "! the index of a cell format, added when the workbook has none like it
    METHODS style_get
      IMPORTING
        id            TYPE i         OPTIONAL
        code          TYPE string    OPTIONAL
        bold          TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(result) TYPE i.

    METHODS sheet_name_get
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    METHODS cell_text
      IMPORTING
        address       TYPE string
        val           TYPE string
        style         TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

    METHODS styles_xml
      RETURNING
        VALUE(result) TYPE string.

    "! a relationships part with its one relationship, as the bytes of the file
    CLASS-METHODS rels_xml
      IMPORTING
        kind          TYPE string
        target        TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    METHODS table_xml
      IMPORTING
        id            TYPE i
        name          TYPE string
        range         TYPE string
        filter        TYPE string
        layout        TYPE ty_s_layout
        totals        TYPE abap_bool
        t_col         TYPE ty_t_out_col
      RETURNING
        VALUE(result) TYPE string.

    "! the serial number of a date - 0 for one Excel has none for (initial,
    "! before 1900, no date at all)
    CLASS-METHODS date_to_serial
      IMPORTING
        val           TYPE d
      RETURNING
        VALUE(result) TYPE i.

    " ----- reading

    METHODS load
      IMPORTING
        val TYPE xstring.

    METHODS part_get
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    METHODS rels_read
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_rel.

    METHODS shared_read
      IMPORTING
        val TYPE xstring.

    METHODS styles_read
      IMPORTING
        val TYPE xstring.

    "! the part of a sheet, by name or by position
    METHODS sheet_part
      IMPORTING
        sheet         TYPE clike
        index         TYPE i
      RETURNING
        VALUE(result) TYPE xstring.

    "! The cells of the next row that has any. row goes in as the row
    "! before and comes back as the row that was read
    METHODS sheet_read_row
      IMPORTING
        reader TYPE REF TO object
      EXPORTING
        t_cell TYPE ty_t_cell
        eof    TYPE abap_bool
      CHANGING
        row    TYPE i.

    "! what a c element holds: its text by the type the element names
    METHODS cell_read
      IMPORTING
        cell_type TYPE string
        style     TYPE string
        text      TYPE string
      EXPORTING
        kind      TYPE string
        value     TYPE string.

    "! a number cell by the format it is shown in: a number, a date, a time
    METHODS number_cell
      IMPORTING
        val   TYPE string
        style TYPE string
      EXPORTING
        kind  TYPE string
        value TYPE string.

    METHODS cell_to_field
      IMPORTING
        cell  TYPE ty_s_cell
        cat   TYPE string
      CHANGING
        field TYPE any.

    "! a path of the package: target as seen from the folder of base
    CLASS-METHODS path_resolve
      IMPORTING
        base          TYPE string
        target        TYPE string
      RETURNING
        VALUE(result) TYPE string.

    "! the folder a part lies in, with the slash behind it
    CLASS-METHODS path_folder
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS attr
      IMPORTING
        t_attribute   TYPE z2ui5_cl_tcl_context=>ty_t_xml_attribute
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    "! what a number format shows: D a date, T a time, M both, L a time
    "! that runs past 24 hours, empty a number
    CLASS-METHODS format_kind
      IMPORTING
        id            TYPE i
        code          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    "! `1.5E-3` gives `0.0015`, `0.30000000000000004` gives `0.3`, `12.50`
    "! gives `12.5` - a number as it is stored in the file, without
    "! exponent and without the digits a binary float adds. Empty for what
    "! is no number
    "! @parameter digits | the digits that count: 15 are what a cell shows, 17 what it stores
    CLASS-METHODS number_plain
      IMPORTING
        val           TYPE string
        digits        TYPE i DEFAULT 15
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS serial_to_date
      IMPORTING
        val           TYPE i
        date1904      TYPE abap_bool
      RETURNING
        VALUE(result) TYPE d.

    "! `_x000D_` and its like as the character it stands for - how a file
    "! holds a character XML cannot
    CLASS-METHODS text_decode
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS char_by_code
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS hex_to_int
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE i.

    "! a byte, 0 to 255, as its two hex digits
    CLASS-METHODS byte_to_hex
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS two_digits
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE string.

    "! a valid component name out of a header text
    CLASS-METHODS name_by_header
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS digits_only
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.



CLASS z2ui5_cl_tcl_xlsx IMPLEMENTATION.

  METHOD factory.

    CREATE OBJECT result.

  ENDMETHOD.

  METHOD factory_by_xlsx.

    CREATE OBJECT result.
    result->load( val ).

  ENDMETHOD.

  METHOD xlsx_by_itab.

    result = factory( )->add_sheet( val    = val
                                    layout = layout )->get_xlsx( ).

  ENDMETHOD.

  METHOD itab_by_xlsx.

    DATA temp1 TYPE REF TO z2ui5_cl_tcl_xlsx.
    temp1 = factory_by_xlsx( val ).
    temp1->get_table( IMPORTING result = result ).

  ENDMETHOD.

  METHOD add_sheet.

    DATA lr_line    TYPE REF TO data.
    DATA lt_field   TYPE ty_t_field.
    DATA lt_xml     TYPE string_table.
    DATA lt_head    TYPE string_table.
    DATA lv_cells   TYPE string.
    DATA lv_text    TYPE string.
    DATA lv_value   TYPE string.
    DATA lv_ref     TYPE string.
    DATA lv_row     TYPE i.
    DATA lv_col0    TYPE i.
    DATA lv_row0    TYPE i.
    DATA lv_date    TYPE d.
    DATA lv_time    TYPE t.
    DATA lv_serial  TYPE i.
    DATA lv_seconds TYPE i.
    DATA lv_number  TYPE decfloat34.
    DATA lv_elementary TYPE abap_bool.
    DATA lv_totals  TYPE abap_bool.
    DATA lv_table_name TYPE string.
    DATA ls_sheet   TYPE ty_s_out_sheet.
    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.
    FIELD-SYMBOLS <col>  TYPE ty_s_out_col.
      DATA lv_start_row TYPE string.
    DATA lt_col TYPE z2ui5_cl_tcl_xlsx=>ty_t_out_col.
    DATA lv_table TYPE abap_bool.
    DATA temp1 TYPE xsdboolean.
        DATA temp2 TYPE xsdboolean.
    DATA lv_head_style TYPE string.
      DATA temp109 LIKE LINE OF lt_xml.
    DATA lv_first_data TYPE i.
        DATA temp110 LIKE LINE OF lt_xml.
    DATA lv_last_data LIKE lv_row.
          DATA lv_total_style LIKE <col>-style.
      DATA temp111 LIKE LINE OF lt_xml.
    DATA lv_range TYPE string.
    DATA lv_filter TYPE string.
      DATA lv_left TYPE string.
      DATA lv_right TYPE string.
      DATA lv_filter_end TYPE i.
    DATA lv_tab_selected TYPE string.
    DATA lv_pane TYPE string.
    DATA temp112 LIKE LINE OF lt_head.
    DATA temp113 LIKE LINE OF lt_head.
    DATA temp114 LIKE LINE OF lt_head.
        DATA lv_index TYPE i.
        DATA lv_width LIKE <col>-width.
        DATA temp115 LIKE LINE OF lt_head.
      DATA temp116 LIKE LINE OF lt_xml.

    IF mv_loaded = abap_true.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `XLSX_READ_ONLY - a workbook that was read takes no sheet`.
    ENDIF.

    " where the header row starts: A1, or the cell the layout names
    IF layout-start_cell IS NOT INITIAL.

      lv_start_row = digits_only( layout-start_cell ).
      lv_col0 = column_to_number( layout-start_cell ) - 1.
      IF lv_col0 < 0 OR lv_start_row IS INITIAL OR strlen( lv_start_row ) > 7.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val = |XLSX_START_CELL - { layout-start_cell } is no cell of a sheet|.
      ENDIF.
      lv_row0 = lv_start_row.
      lv_row0 = lv_row0 - 1.
      IF lv_row0 < 0.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val = |XLSX_START_CELL - { layout-start_cell } is no cell of a sheet|.
      ENDIF.
    ENDIF.
    " the header and the totals row are two more
    IF lines( val ) + lv_row0 + 2 > cv_max_row.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = |XLSX_TOO_MANY_ROWS - a sheet holds { cv_max_row } rows, the table has { lines( val ) }|.
    ENDIF.

    CREATE DATA lr_line LIKE LINE OF val.
    ASSIGN lr_line->* TO <line>.
    fields_get( EXPORTING row        = <line>
                IMPORTING elementary = lv_elementary
                          result     = lt_field ).

    lt_col = columns_get( t_field = lt_field
                                layout  = layout
                                offset  = lv_col0 ).


    temp1 = boolc( layout-table_style IS NOT INITIAL AND layout-no_header = abap_false AND val IS NOT INITIAL AND lt_col IS NOT INITIAL ).
    lv_table = temp1.
    IF lv_table = abap_true.
      lv_table_name = table_name_get( layout-table_name ).
    ENDIF.
    LOOP AT lt_col ASSIGNING <col>.
      IF <col>-total_fn IS NOT INITIAL OR <col>-total_label IS NOT INITIAL.
        " a totals row under no rows adds up nothing

        temp2 = boolc( val IS NOT INITIAL ).
        lv_totals = temp2.
      ENDIF.
    ENDLOOP.

    " an Excel table formats its header and its totals row itself

    lv_head_style = ``.
    IF lv_table = abap_false.
      lv_head_style = | s="{ style_get( bold = abap_true ) }"|.
    ENDIF.

    lv_row = lv_row0.
    IF layout-no_header = abap_false AND lt_col IS NOT INITIAL.
      lv_row = lv_row + 1.
      LOOP AT lt_col ASSIGNING <col>.
        lv_cells = lv_cells && cell_text( address = |{ <col>-letters }{ lv_row }|
                                          val     = <col>-header
                                          style   = lv_head_style ).
        " the filter button takes its room in the header cell
        <col>-len = strlen( <col>-header ) + 3.
      ENDLOOP.

      temp109 = |<row r="{ lv_row }">{ lv_cells }</row>|.
      INSERT temp109 INTO TABLE lt_xml.
    ENDIF.

    lv_first_data = lv_row + 1.

    LOOP AT val ASSIGNING <row>.
      lv_row = lv_row + 1.
      CLEAR lv_cells.
      LOOP AT lt_col ASSIGNING <col>.
        lv_ref = |{ <col>-letters }{ lv_row }|.

        IF <col>-formula IS NOT INITIAL.
          " no value with it: Excel works the formula out when it opens
          " the file (get_xlsx asks it to)
          lv_value = replace( val  = <col>-formula
                              sub  = `{row}`
                              with = |{ lv_row }|
                              occ  = 0 ).
          lv_value = z2ui5_cl_tcl_context=>c_escape_xml( lv_value ).
          lv_cells = |{ lv_cells }<c r="{ lv_ref }"{ <col>-style }><f>{ lv_value }</f></c>|.
          mv_formulas = abap_true.
          CONTINUE.
        ENDIF.

        IF lv_elementary = abap_true.
          ASSIGN <row> TO <cell>.
        ELSE.
          ASSIGN COMPONENT <col>-name OF STRUCTURE <row> TO <cell>.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.
        ENDIF.
        CLEAR lv_text.

        CASE <col>-cat.

          WHEN cs_cat-number.
            " a string template writes the sign in front and a period as
            " decimal separator, whatever the user's settings
            lv_text = |{ <cell> }|.
            lv_cells = |{ lv_cells }<c r="{ lv_ref }"{ <col>-style }><v>{ lv_text }</v></c>|.
            IF <col>-total_fn IS NOT INITIAL.
              lv_number = <cell>.
              <col>-sum = <col>-sum + lv_number.
              IF <col>-numbers = 0 OR lv_number < <col>-low.
                <col>-low = lv_number.
              ENDIF.
              IF <col>-numbers = 0 OR lv_number > <col>-high.
                <col>-high = lv_number.
              ENDIF.
              <col>-numbers = <col>-numbers + 1.
            ENDIF.

          WHEN cs_cat-date.
            lv_date = <cell>.
            lv_serial = date_to_serial( lv_date ).
            IF lv_serial > 0.
              lv_text = `0000-00-00`.
              lv_cells = |{ lv_cells }<c r="{ lv_ref }"{ <col>-style }><v>{ lv_serial }</v></c>|.
            ELSEIF lv_date IS NOT INITIAL.
              " a date Excel has no number for - before 1900, or none at
              " all - stays readable as text
              lv_text = |{ lv_date(4) }-{ lv_date+4(2) }-{ lv_date+6(2) }|.
              lv_cells = lv_cells && cell_text( address = lv_ref
                                                val     = lv_text ).
            ENDIF.

          WHEN cs_cat-time.
            lv_time = <cell>.
            lv_seconds = lv_time(2) * 3600 + lv_time+2(2) * 60 + lv_time+4(2).
            " the fraction of a day with every digit the cell stores: cut
            " shorter, 23:59:59 comes out a hair below itself, and a reader
            " that cuts off the rest shows 23:59:58
            lv_number = lv_seconds.
            lv_number = round( val = lv_number / 86400
                               dec = 18 ).
            lv_value = number_plain( val    = |{ lv_number }|
                                     digits = 17 ).
            lv_text = `00:00:00`.
            lv_cells = |{ lv_cells }<c r="{ lv_ref }"{ <col>-style }><v>{ lv_value }</v></c>|.

          WHEN cs_cat-timestamp.
            " YYYYMMDDHHMMSS, with or without a fraction of a second
            lv_text = |{ <cell> }|.
            IF lv_text CS `.`.
              lv_text = substring_before( val = lv_text
                                          sub = `.` ).
            ENDIF.
            IF strlen( lv_text ) = 14 AND lv_text CO cv_digits.
              lv_date = lv_text(8).
              lv_serial = date_to_serial( lv_date ).
            ELSE.
              lv_serial = 0.
            ENDIF.
            IF lv_serial > 0.
              lv_seconds = lv_text+8(2) * 3600 + lv_text+10(2) * 60 + lv_text+12(2).
              lv_number = lv_seconds.
              lv_number = lv_serial + round( val = lv_number / 86400
                                             dec = 18 ).
              lv_value = number_plain( val    = |{ lv_number }|
                                       digits = 17 ).
              lv_text = `0000-00-00 00:00`.
              lv_cells = |{ lv_cells }<c r="{ lv_ref }"{ <col>-style }><v>{ lv_value }</v></c>|.
            ELSE.
              CLEAR lv_text.
            ENDIF.

          WHEN cs_cat-boolean.
            " a flag that is not set is an empty cell, not a FALSE in
            " every row
            IF <cell> IS NOT INITIAL.
              lv_text = `TRUE`.
              lv_cells = |{ lv_cells }<c r="{ lv_ref }" t="b"><v>1</v></c>|.
            ENDIF.

          WHEN OTHERS.
            " text, and what is text in the file: a NUMC with its leading
            " zeros, bytes as hex digits
            IF <cell> IS NOT INITIAL OR <col>-cat = cs_cat-numc.
              lv_text = |{ <cell> }|.
              lv_cells = lv_cells && cell_text( address = lv_ref
                                                val     = lv_text ).
            ENDIF.

        ENDCASE.

        IF lv_text IS NOT INITIAL.
          <col>-cells = <col>-cells + 1.
        ENDIF.
        IF strlen( lv_text ) > <col>-len.
          <col>-len = strlen( lv_text ).
        ENDIF.
      ENDLOOP.
      IF lv_cells IS NOT INITIAL.

        temp110 = |<row r="{ lv_row }">{ lv_cells }</row>|.
        INSERT temp110 INTO TABLE lt_xml.
      ENDIF.
    ENDLOOP.

    lv_last_data = lv_row.

    IF lv_totals = abap_true.
      " a formula over the rows: SUBTOTAL( ) leaves out what a filter
      " hides. In an Excel table it names the column, else its cells
      lv_row = lv_row + 1.
      CLEAR lv_cells.
      LOOP AT lt_col ASSIGNING <col>.
        lv_ref = |{ <col>-letters }{ lv_row }|.
        IF <col>-total_fn IS NOT INITIAL.
          IF lv_table = abap_true.
            " in the name of a column, what a structured reference reads
            " as its own syntax is marked with an apostrophe
            lv_text = <col>-header.
            lv_text = replace( val  = lv_text
                               sub  = `'`
                               with = `''`
                               occ  = 0 ).
            lv_text = replace( val  = lv_text
                               sub  = `[`
                               with = `'[`
                               occ  = 0 ).
            lv_text = replace( val  = lv_text
                               sub  = `]`
                               with = `']`
                               occ  = 0 ).
            lv_text = replace( val  = lv_text
                               sub  = `#`
                               with = `'#`
                               occ  = 0 ).
            lv_value = |SUBTOTAL({ <col>-total_code },{ lv_table_name }[{ lv_text }])|.
          ELSE.
            lv_value = |SUBTOTAL({ <col>-total_code },{ <col>-letters }{ lv_first_data }:{ <col>-letters }{ lv_last_data })|.
          ENDIF.
          lv_value = z2ui5_cl_tcl_context=>c_escape_xml( lv_value ).
          " a count is a number whatever the column holds

          lv_total_style = <col>-style.
          IF <col>-total_fn = `count` OR <col>-total_fn = `countNums`.
            CLEAR lv_total_style.
          ENDIF.
          lv_text = total_value( <col> ).
          IF lv_text IS NOT INITIAL.
            lv_text = |<v>{ lv_text }</v>|.
          ENDIF.
          lv_cells = |{ lv_cells }<c r="{ lv_ref }"{ lv_total_style }><f>{ lv_value }</f>{ lv_text }</c>|.
          mv_formulas = abap_true.
        ELSEIF <col>-total_label IS NOT INITIAL.
          lv_cells = lv_cells && cell_text( address = lv_ref
                                            val     = <col>-total_label
                                            style   = lv_head_style ).
        ENDIF.
      ENDLOOP.

      temp111 = |<row r="{ lv_row }">{ lv_cells }</row>|.
      INSERT temp111 INTO TABLE lt_xml.
    ENDIF.

    " what stands in front of the rows is known only now: the range of the
    " sheet and the widths of its columns

    lv_range = `A1`.

    lv_filter = ``.
    IF lt_col IS NOT INITIAL AND lv_row > lv_row0.

      lv_left = column_to_letters( lv_col0 + 1 ).

      lv_right = column_to_letters( lv_col0 + lines( lt_col ) ).
      lv_range = |{ lv_left }{ lv_row0 + 1 }:{ lv_right }{ lv_row }|.
      " the filter ends above the totals row

      lv_filter_end = nmax( val1 = lv_last_data
                                  val2 = lv_row0 + 1 ).
      lv_filter = |{ lv_left }{ lv_row0 + 1 }:{ lv_right }{ lv_filter_end }|.
    ENDIF.

    lv_tab_selected = ``.
    IF mt_out_sheet IS INITIAL.
      lv_tab_selected = ` tabSelected="1"`.
    ENDIF.

    lv_pane = ``.
    IF layout-freeze_header = abap_true AND layout-no_header = abap_false.
      lv_pane = |<pane ySplit="{ lv_row0 + 1 }" topLeftCell="A{ lv_row0 + 2 }" activePane="bottomLeft" state="frozen"/>|.
    ENDIF.


    temp112 = |{ cv_xml_head }<worksheet xmlns="{ cs_ns-main }" xmlns:r="{ cs_ns-rel }">|.
    INSERT temp112 INTO TABLE lt_head.

    temp113 = |<dimension ref="{ lv_range }"/>|.
    INSERT temp113 INTO TABLE lt_head.

    temp114 = |<sheetViews><sheetView workbookViewId="0"{ lv_tab_selected }>{ lv_pane }</sheetView></sheetViews>|.
    INSERT temp114
           INTO TABLE lt_head.
    INSERT `<sheetFormatPr defaultRowHeight="15"/>` INTO TABLE lt_head.
    IF lt_col IS NOT INITIAL.
      INSERT `<cols>` INTO TABLE lt_head.
      LOOP AT lt_col ASSIGNING <col>.

        lv_index = lv_col0 + sy-tabix.

        lv_width = <col>-width.
        IF lv_width <= 0.
          " by the longest content, in bounds: a long text does not push
          " every other column off the screen
          lv_width = nmin( val1 = nmax( val1 = <col>-len + 2
                                        val2 = 6 )
                           val2 = 60 ).
        ENDIF.

        temp115 = |<col min="{ lv_index }" max="{ lv_index }" width="{ lv_width }" customWidth="1"/>|.
        INSERT temp115
               INTO TABLE lt_head.
      ENDLOOP.
      INSERT `</cols>` INTO TABLE lt_head.
    ENDIF.
    INSERT `<sheetData>` INTO TABLE lt_head.

    INSERT `</sheetData>` INTO TABLE lt_xml.
    IF lv_table = abap_true.
      mv_tables = mv_tables + 1.
      IF layout-no_filter = abap_true.
        CLEAR lv_filter.
      ENDIF.
      ls_sheet-table_xml = z2ui5_cl_tcl_context=>conv_get_xstring_by_string(
                               table_xml( id     = mv_tables
                                          name   = lv_table_name
                                          range  = lv_range
                                          filter = lv_filter
                                          layout = layout
                                          totals = lv_totals
                                          t_col  = lt_col ) ).
      INSERT `<tableParts count="1"><tablePart r:id="rId1"/></tableParts>` INTO TABLE lt_xml.
    ELSEIF layout-auto_filter = abap_true AND layout-no_header = abap_false AND lt_col IS NOT INITIAL.

      temp116 = |<autoFilter ref="{ lv_filter }"/>|.
      INSERT temp116 INTO TABLE lt_xml.
    ENDIF.
    INSERT `</worksheet>` INTO TABLE lt_xml.

    ls_sheet-name = sheet_name_get( name ).
    ls_sheet-xml = z2ui5_cl_tcl_context=>conv_get_xstring_by_string(
                       concat_lines_of( lt_head ) && concat_lines_of( lt_xml ) ).
    INSERT ls_sheet INTO TABLE mt_out_sheet.

    result = me.

  ENDMETHOD.

  METHOD fields_get.

    DATA ls_field TYPE ty_s_field.
    DATA lv_kind TYPE string.
    DATA lt_comp TYPE abap_component_tab.
    DATA temp117 LIKE LINE OF lt_comp.
    DATA lr_comp LIKE REF TO temp117.
      DATA lv_name TYPE string.

    CLEAR elementary.
    CLEAR result.


    lv_kind = z2ui5_cl_tcl_context=>rtti_get_type_kind( row ).
    IF lv_kind <> z2ui5_cl_tcl_context=>cv_typedescr_typekind_struct1
        AND lv_kind <> z2ui5_cl_tcl_context=>cv_typedescr_typekind_struct2.
      elementary = abap_true.
      ls_field-name = `TABLE_LINE`.
      ls_field-cat = category_get( type_kind = lv_kind
                                   name      = z2ui5_cl_tcl_context=>rtti_get_type_name( row ) ).
      IF ls_field-cat IS NOT INITIAL.
        INSERT ls_field INTO TABLE result.
      ENDIF.
      RETURN.
    ENDIF.

    " the included view: an include gives its fields, not one column

    lt_comp = z2ui5_cl_tcl_context=>rtti_get_t_attri_by_any( row ).


    LOOP AT lt_comp REFERENCE INTO lr_comp.
      IF lr_comp->type->kind <> z2ui5_cl_tcl_context=>cv_typedescr_kind_elem.
        CONTINUE.
      ENDIF.
      CLEAR ls_field.
      ls_field-name = lr_comp->name.

      lv_name = lr_comp->type->get_relative_name( ).
      ls_field-cat = category_get( type_kind = lr_comp->type->type_kind
                                   name      = lv_name ).
      IF ls_field-cat IS INITIAL.
        CONTINUE.
      ENDIF.
      IF lr_comp->type->is_ddic_type( ) = abap_true.
        ls_field-rollname = lv_name.
      ENDIF.
      INSERT ls_field INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD category_get.

    DATA lv_name TYPE string.
    lv_name = to_upper( name ).

    IF type_kind = z2ui5_cl_tcl_context=>cv_typedescr_typekind_date.
      result = cs_cat-date.
    ELSEIF type_kind = z2ui5_cl_tcl_context=>cv_typedescr_typekind_time.
      result = cs_cat-time.
    ELSEIF z2ui5_cl_tcl_context=>rtti_check_typekind_number( type_kind ) = abap_true.
      " a timestamp is a packed number that says what it is by its name only
      IF lv_name = `TIMESTAMP` OR lv_name = `TIMESTAMPL` OR lv_name = `TZNTSTMPS` OR lv_name = `TZNTSTMPL`.
        result = cs_cat-timestamp.
      ELSE.
        result = cs_cat-number.
      ENDIF.
    ELSEIF type_kind = z2ui5_cl_tcl_context=>cv_typedescr_typekind_char.
      IF z2ui5_cl_tcl_context=>boolean_check_by_name( lv_name ) = abap_true.
        result = cs_cat-boolean.
      ELSE.
        result = cs_cat-text.
      ENDIF.
    ELSEIF type_kind = z2ui5_cl_tcl_context=>cv_typedescr_typekind_string.
      result = cs_cat-text.
    ELSEIF type_kind = z2ui5_cl_tcl_context=>cv_typedescr_typekind_num.
      result = cs_cat-numc.
    ELSEIF type_kind = z2ui5_cl_tcl_context=>cv_typedescr_typekind_hex
        OR type_kind = z2ui5_cl_tcl_context=>cv_typedescr_typekind_xstring.
      result = cs_cat-hex.
    ELSEIF type_kind <> z2ui5_cl_tcl_context=>cv_typedescr_typekind_table
        AND type_kind <> z2ui5_cl_tcl_context=>cv_typedescr_typekind_dref
        AND type_kind <> z2ui5_cl_tcl_context=>cv_typedescr_typekind_oref
        AND type_kind <> z2ui5_cl_tcl_context=>cv_typedescr_typekind_struct1
        AND type_kind <> z2ui5_cl_tcl_context=>cv_typedescr_typekind_struct2.
      " an elementary type a later release added (utclong) - written the
      " way a string template shows it
      result = cs_cat-text.
    ENDIF.

  ENDMETHOD.

  METHOD columns_get.

    DATA ls_col   TYPE ty_s_out_col.
    DATA lt_taken TYPE string_table.
    DATA ls_field TYPE ty_s_field.

    " the columns the layout names, in its order - or every field
    DATA lt_column LIKE layout-t_column.
        DATA temp118 TYPE z2ui5_cl_tcl_xlsx=>ty_s_column.
    DATA temp119 LIKE LINE OF lt_column.
    DATA lr_column LIKE REF TO temp119.
      DATA lv_position TYPE i.
      DATA lv_name TYPE string.
            DATA ls_text TYPE z2ui5_cl_tcl_context=>ty_s_data_element_text.
        DATA lv_header LIKE ls_col-header.
        DATA lv_suffix TYPE i.
          DATA lv_upper TYPE string.
          DATA temp120 LIKE sy-subrc.
      DATA lv_style TYPE i.
    lt_column = layout-t_column.
    IF lt_column IS INITIAL.
      LOOP AT t_field INTO ls_field.

        CLEAR temp118.
        temp118-name = ls_field-name.
        INSERT temp118 INTO TABLE lt_column.
      ENDLOOP.
    ENDIF.
    IF lines( lt_column ) + offset > cv_max_col.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = |XLSX_TOO_MANY_COLUMNS - a sheet holds { cv_max_col } columns|.
    ENDIF.



    LOOP AT lt_column REFERENCE INTO lr_column.

      lv_position = lines( result ) + 1.

      lv_name = z2ui5_cl_tcl_context=>c_trim_upper( lr_column->name ).

      CLEAR ls_col.
      CLEAR ls_field.
      IF lr_column->formula IS NOT INITIAL.
        " a formula column has no component behind it: a number, whatever
        " the formula gives
        ls_field-name = lv_name.
        ls_field-cat = cs_cat-number.
        ls_col-formula = lr_column->formula.
        IF ls_col-formula(1) = `=`.
          ls_col-formula = substring( val = ls_col-formula
                                      off = 1 ).
        ENDIF.
      ELSE.
        ls_field = field_find( t_field = t_field
                               name    = lv_name ).
        IF ls_field IS INITIAL.
          RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
            EXPORTING
              val = |XLSX_COLUMN_UNKNOWN - the row has no elementary component { lv_name }|.
        ENDIF.
      ENDIF.

      ls_col-name = ls_field-name.
      ls_col-cat = ls_field-cat.
      ls_col-width = lr_column->width.
      ls_col-letters = column_to_letters( offset + lv_position ).

      ls_col-header = lr_column->header.
      IF ls_col-header IS INITIAL AND layout-ddic_header = abap_true AND ls_field-rollname IS NOT INITIAL.
        TRY.

            ls_text = z2ui5_cl_tcl_context=>rtti_get_data_element_texts( ls_field-rollname ).
            ls_col-header = ls_text-medium.
            IF ls_col-header IS INITIAL.
              ls_col-header = ls_text-long.
            ENDIF.
          CATCH cx_root ##NO_HANDLER.
            " no text to be had - the component name below
        ENDTRY.
      ENDIF.
      IF ls_col-header IS INITIAL.
        ls_col-header = ls_col-name.
      ENDIF.
      IF ls_col-header IS INITIAL.
        " a formula column without a name and without a header
        ls_col-header = |Column{ lv_position }|.
      ENDIF.
      " an Excel table takes every column name once, and so does a reader
      " that goes by the header
      IF layout-table_style IS NOT INITIAL.

        lv_header = ls_col-header.

        lv_suffix = 1.
        DO.
          " in a variable: a function in the key of a table expression is
          " read as a method call on 7.02

          lv_upper = to_upper( lv_header ).

          READ TABLE lt_taken WITH KEY table_line = lv_upper TRANSPORTING NO FIELDS.
          temp120 = sy-subrc.
          IF NOT temp120 = 0.
            EXIT.
          ENDIF.
          lv_suffix = lv_suffix + 1.
          lv_header = |{ ls_col-header } { lv_suffix }|.
        ENDDO.
        ls_col-header = lv_header.
        INSERT lv_upper INTO TABLE lt_taken.
      ENDIF.

      IF lr_column->total IS NOT INITIAL.
        total_function( EXPORTING val  = lr_column->total
                        IMPORTING name = ls_col-total_fn
                                  code = ls_col-total_code ).
        IF ls_col-total_code = 0.
          ls_col-total_label = lr_column->total.
        ENDIF.
      ENDIF.


      lv_style = 0.
      CASE ls_col-cat.
        WHEN cs_cat-number.
          IF lr_column->format IS NOT INITIAL.
            lv_style = style_get( code = lr_column->format ).
          ENDIF.
        WHEN cs_cat-date.
          lv_style = style_get( id   = cs_numfmt-date
                                code = lr_column->format ).
        WHEN cs_cat-time.
          lv_style = style_get( id   = cs_numfmt-time
                                code = lr_column->format ).
        WHEN cs_cat-timestamp.
          lv_style = style_get( id   = cs_numfmt-datetime
                                code = lr_column->format ).
      ENDCASE.
      IF lv_style > 0.
        ls_col-style = | s="{ lv_style }"|.
      ENDIF.

      INSERT ls_col INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD field_find.

    LOOP AT t_field INTO result.
      IF result-name = name.
        RETURN.
      ENDIF.
    ENDLOOP.
    CLEAR result.

  ENDMETHOD.

  METHOD total_function.
    DATA lv_name TYPE string.

    CLEAR name.
    CLEAR code.

    " the names a table part knows, and the numbers SUBTOTAL( ) takes for
    " them - the ones from 101 on, which leave out a hidden row
    " in a variable: 7.02 takes no function as the operand of a CASE

    lv_name = to_lower( condense( val ) ).
    CASE lv_name.
      WHEN `sum`.
        name = `sum`.
        code = 109.
      WHEN `average`.
        name = `average`.
        code = 101.
      WHEN `count`.
        name = `count`.
        code = 103.
      WHEN `countnums`.
        name = `countNums`.
        code = 102.
      WHEN `max`.
        name = `max`.
        code = 104.
      WHEN `min`.
        name = `min`.
        code = 105.
      WHEN `stddev`.
        name = `stdDev`.
        code = 107.
      WHEN `var`.
        name = `var`.
        code = 110.
    ENDCASE.

  ENDMETHOD.

  METHOD total_value.

    DATA lv_number TYPE decfloat34.

    " a formula column has no values here to add up
    IF col-formula IS NOT INITIAL.
      RETURN.
    ENDIF.

    CASE col-total_fn.
      WHEN `count`.
        result = |{ col-cells }|.
        RETURN.
      WHEN `countNums`.
        result = |{ col-numbers }|.
        RETURN.
      WHEN `sum`.
        lv_number = col-sum.
      WHEN `average`.
        IF col-numbers = 0.
          RETURN.
        ENDIF.
        lv_number = col-sum / col-numbers.
      WHEN `min`.
        lv_number = col-low.
      WHEN `max`.
        lv_number = col-high.
      WHEN OTHERS.
        " stdDev, var: left to Excel
        RETURN.
    ENDCASE.
    result = number_plain( |{ lv_number }| ).

  ENDMETHOD.

  METHOD table_name_get.

    DATA lv_pos TYPE i.

    " letters, digits, underscores and periods, a letter or an underscore
    " in front
    DATA lv_len TYPE i.
      DATA lv_char TYPE string.
      DATA lv_letters TYPE string.
      DATA lv_rest TYPE string.
    DATA lv_base LIKE result.
    DATA lv_suffix TYPE i.
      DATA lv_upper TYPE string.
      DATA temp121 LIKE sy-subrc.
    lv_len = strlen( val ).
    WHILE lv_pos < lv_len.

      lv_char = substring( val = val
                                 off = lv_pos
                                 len = 1 ).
      IF lv_char CA `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.`.
        result = result && lv_char.
      ELSEIF lv_char <> ` `.
        result = result && `_`.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.
    IF result IS INITIAL.
      result = |Table{ mv_tables + 1 }|.
    ENDIF.
    IF result(1) CA `0123456789.`.
      result = `_` && result.
    ENDIF.
    " a name that reads as a cell - up to three letters, then digits only
    " (A1, XFD12) - is none
    lv_len = strlen( result ).
    lv_pos = 0.
    WHILE lv_pos < lv_len AND lv_pos < 4 AND result+lv_pos(1) NA cv_digits.
      lv_pos = lv_pos + 1.
    ENDWHILE.
    IF lv_pos >= 1 AND lv_pos <= 3 AND lv_pos < lv_len.

      lv_letters = result(lv_pos).

      lv_rest = result+lv_pos.
      IF lv_rest CO cv_digits AND lv_letters CO `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`.
        result = `_` && result.
      ENDIF.
    ENDIF.
    IF strlen( result ) > 200.
      result = result(200).
    ENDIF.

    " once in the workbook, whatever its case

    lv_base = result.

    lv_suffix = 1.
    DO.

      lv_upper = to_upper( result ).

      READ TABLE mt_table_name WITH KEY table_line = lv_upper TRANSPORTING NO FIELDS.
      temp121 = sy-subrc.
      IF NOT temp121 = 0.
        EXIT.
      ENDIF.
      lv_suffix = lv_suffix + 1.
      result = |{ lv_base }_{ lv_suffix }|.
    ENDDO.
    INSERT lv_upper INTO TABLE mt_table_name.

  ENDMETHOD.

  METHOD style_get.

    DATA ls_xf TYPE ty_s_xf.
      DATA lv_index TYPE i.
      DATA lv_code LIKE LINE OF mt_numfmt.
    DATA temp122 LIKE LINE OF mt_xf.
    DATA lr_xf LIKE REF TO temp122.

    " index 0, the format of every cell that names none
    IF mt_xf IS INITIAL.
      INSERT ls_xf INTO TABLE mt_xf.
    ENDIF.

    ls_xf-bold = bold.
    ls_xf-numfmt = id.
    IF code IS NOT INITIAL.
      " a format of the caller: a custom one, named from 164 on. Looked
      " up in a loop: line_index( ) of a row that is not there comes out
      " of the 7.02 downport as the index of an earlier read

      lv_index = 0.

      LOOP AT mt_numfmt INTO lv_code.
        IF lv_code = code.
          lv_index = sy-tabix.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_index = 0.
        INSERT code INTO TABLE mt_numfmt.
        lv_index = lines( mt_numfmt ).
      ENDIF.
      ls_xf-numfmt = cs_numfmt-custom + lv_index - 1.
    ENDIF.



    LOOP AT mt_xf REFERENCE INTO lr_xf.
      IF lr_xf->numfmt = ls_xf-numfmt AND lr_xf->bold = ls_xf-bold.
        result = sy-tabix.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF result = 0.
      INSERT ls_xf INTO TABLE mt_xf.
      result = lines( mt_xf ).
    ENDIF.
    result = result - 1.

  ENDMETHOD.

  METHOD sheet_name_get.

    DATA lv_pos TYPE i.

    DATA lv_name TYPE string.
    DATA lv_len TYPE i.
      DATA lv_char TYPE string.
    DATA lv_base LIKE result.
    DATA lv_suffix TYPE i.
      DATA lv_taken LIKE abap_false.
      DATA temp123 LIKE LINE OF mt_out_sheet.
      DATA lr_sheet LIKE REF TO temp123.
      DATA lv_tail TYPE string.
      DATA lv_keep TYPE i.
    lv_name = z2ui5_cl_tcl_context=>c_trim( val ).
    IF lv_name IS INITIAL.
      lv_name = |Sheet{ lines( mt_out_sheet ) + 1 }|.
    ENDIF.

    " what Excel does not take in a sheet name

    lv_len = strlen( lv_name ).
    WHILE lv_pos < lv_len.

      lv_char = substring( val = lv_name
                                 off = lv_pos
                                 len = 1 ).
      IF lv_char CA `\\/?*[]:`.
        lv_char = `_`.
      ENDIF.
      result = result && lv_char.
      lv_pos = lv_pos + 1.
    ENDWHILE.
    IF strlen( result ) > 31.
      result = substring( val = result
                          len = 31 ).
    ENDIF.

    " a name the workbook has, whatever its case

    lv_base = result.

    lv_suffix = 1.
    DO.

      lv_taken = abap_false.


      LOOP AT mt_out_sheet REFERENCE INTO lr_sheet.
        IF to_upper( lr_sheet->name ) = to_upper( result ).
          lv_taken = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_taken = abap_false.
        EXIT.
      ENDIF.
      lv_suffix = lv_suffix + 1.

      lv_tail = | ({ lv_suffix })|.

      lv_keep = nmin( val1 = strlen( lv_base )
                            val2 = 31 - strlen( lv_tail ) ).
      result = substring( val = lv_base
                          len = lv_keep ) && lv_tail.
    ENDDO.

  ENDMETHOD.

  METHOD cell_text.
    DATA lv_text TYPE string.

    IF val IS INITIAL.
      RETURN.
    ENDIF.

    " c_escape_xml drops the control characters XML forbids (Excel
    " "repairs" a workbook with one). `_x` in front of four hex digits is
    " how a file names a character by its number, so a text that reads like
    " that has its underscore named that way

    lv_text = z2ui5_cl_tcl_context=>c_escape_xml( val ).
    IF lv_text CS `_x`.
      lv_text = replace( val  = lv_text
                         sub  = `_x`
                         with = `_x005F_x`
                         occ  = 0 ).
    ENDIF.
    " xml:space keeps the blanks in front and behind
    result = |<c r="{ address }"{ style } t="inlineStr"><is><t xml:space="preserve">{ lv_text }</t></is></c>|.

  ENDMETHOD.

  METHOD date_to_serial.

    IF val IS INITIAL OR val < cv_date_1900 OR val > cv_date_max.
      RETURN.
    ENDIF.
    result = val - cv_date_base.
    IF val < cv_date_march.
      result = result - 1.
    ENDIF.
    " what is no date at all counts as day 0 of the calendar
    IF result < 1.
      result = 0.
    ENDIF.

  ENDMETHOD.

  METHOD table_xml.

    DATA lt_xml TYPE string_table.

    DATA lv_totals TYPE string.
    DATA temp124 LIKE LINE OF lt_xml.
    DATA temp125 LIKE LINE OF lt_xml.
      DATA temp126 LIKE LINE OF lt_xml.
    DATA temp127 LIKE LINE OF lt_xml.
    DATA temp128 LIKE LINE OF t_col.
    DATA lr_col LIKE REF TO temp128.
      DATA lv_total TYPE string.
      DATA lv_column TYPE string.
      DATA temp129 LIKE LINE OF lt_xml.
    DATA lv_rows TYPE string.
    DATA lv_columns TYPE string.
    DATA lv_style TYPE string.
    DATA temp130 LIKE LINE OF lt_xml.
    DATA temp131 LIKE LINE OF lt_xml.
    lv_totals = ` totalsRowShown="0"`.
    IF totals = abap_true.
      lv_totals = ` totalsRowCount="1"`.
    ENDIF.
    " one piece per INSERT, here and wherever a part is put together: the
    " 7.02 downport writes the operands of a `&&` in an INSERT on one line,
    " and a line of more than 255 characters is cut on import

    temp124 = |{ cv_xml_head }<table xmlns="{ cs_ns-main }" id="{ id }" name="{ name }" displayName="{ name }"|.
    INSERT temp124
           INTO TABLE lt_xml.

    temp125 = | ref="{ range }"{ lv_totals }>|.
    INSERT temp125 INTO TABLE lt_xml.
    IF filter IS NOT INITIAL.

      temp126 = |<autoFilter ref="{ filter }"/>|.
      INSERT temp126 INTO TABLE lt_xml.
    ENDIF.

    temp127 = |<tableColumns count="{ lines( t_col ) }">|.
    INSERT temp127 INTO TABLE lt_xml.


    LOOP AT t_col REFERENCE INTO lr_col.

      lv_total = ``.
      IF lr_col->total_fn IS NOT INITIAL.
        lv_total = | totalsRowFunction="{ lr_col->total_fn }"|.
      ELSEIF lr_col->total_label IS NOT INITIAL.
        lv_total = | totalsRowLabel="{ z2ui5_cl_tcl_context=>c_escape_xml( lr_col->total_label ) }"|.
      ENDIF.

      lv_column = z2ui5_cl_tcl_context=>c_escape_xml( lr_col->header ).

      temp129 = |<tableColumn id="{ sy-tabix }" name="{ lv_column }"{ lv_total }/>|.
      INSERT temp129 INTO TABLE lt_xml.
    ENDLOOP.

    lv_rows = `1`.
    IF layout-no_row_stripes = abap_true.
      lv_rows = `0`.
    ENDIF.

    lv_columns = `0`.
    IF layout-column_stripes = abap_true.
      lv_columns = `1`.
    ENDIF.

    lv_style = z2ui5_cl_tcl_context=>c_escape_xml( layout-table_style ).

    temp130 = |</tableColumns><tableStyleInfo name="{ lv_style }" showFirstColumn="0" showLastColumn="0"|.
    INSERT temp130
           INTO TABLE lt_xml.

    temp131 = | showRowStripes="{ lv_rows }" showColumnStripes="{ lv_columns }"/></table>|.
    INSERT temp131 INTO TABLE lt_xml.
    result = concat_lines_of( lt_xml ).

  ENDMETHOD.

  METHOD rels_xml.

    DATA lv_xml TYPE string.
    lv_xml = |{ cv_xml_head }<Relationships xmlns="{ cs_ns-pkg_rel }">|.
    lv_xml = |{ lv_xml }<Relationship Id="rId1" Type="{ cs_ns-rel }/{ kind }" Target="{ target }"/></Relationships>|.
    result = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( lv_xml ).

  ENDMETHOD.

  METHOD styles_xml.

    DATA lt_xml TYPE string_table.
      DATA temp132 TYPE z2ui5_cl_tcl_xlsx=>ty_s_xf.
    DATA temp133 LIKE LINE OF lt_xml.
      DATA temp134 LIKE LINE OF lt_xml.
      DATA lv_code LIKE LINE OF mt_numfmt.
        DATA lv_id TYPE i.
        DATA temp135 LIKE LINE OF lt_xml.
    DATA temp136 LIKE LINE OF lt_xml.
    DATA temp137 LIKE LINE OF mt_xf.
    DATA lr_xf LIKE REF TO temp137.
      DATA lv_font TYPE i.
      DATA lv_apply TYPE string.
      DATA temp138 LIKE LINE OF lt_xml.

    IF mt_xf IS INITIAL.

      CLEAR temp132.
      INSERT temp132 INTO TABLE mt_xf.
    ENDIF.


    temp133 = |{ cv_xml_head }<styleSheet xmlns="{ cs_ns-main }">|.
    INSERT temp133 INTO TABLE lt_xml.
    IF mt_numfmt IS NOT INITIAL.

      temp134 = |<numFmts count="{ lines( mt_numfmt ) }">|.
      INSERT temp134 INTO TABLE lt_xml.

      LOOP AT mt_numfmt INTO lv_code.

        lv_id = cs_numfmt-custom + sy-tabix - 1.

        temp135 = |<numFmt numFmtId="{ lv_id }" formatCode="{ z2ui5_cl_tcl_context=>c_escape_xml( lv_code ) }"/>|.
        INSERT temp135
               INTO TABLE lt_xml.
      ENDLOOP.
      INSERT `</numFmts>` INTO TABLE lt_xml.
    ENDIF.
    " font 0 the default, font 1 the bold one of a header row; the two fills
    " and the one border are what Excel expects to find
    INSERT `<fonts count="2"><font><sz val="11"/><name val="Calibri"/><family val="2"/></font>`
           INTO TABLE lt_xml.
    INSERT `<font><b/><sz val="11"/><name val="Calibri"/><family val="2"/></font></fonts>`
           INTO TABLE lt_xml.
    INSERT `<fills count="2"><fill><patternFill patternType="none"/></fill>`
           INTO TABLE lt_xml.
    INSERT `<fill><patternFill patternType="gray125"/></fill></fills>`
           INTO TABLE lt_xml.
    INSERT `<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>`
           INTO TABLE lt_xml.
    INSERT `<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>`
           INTO TABLE lt_xml.

    temp136 = |<cellXfs count="{ lines( mt_xf ) }">|.
    INSERT temp136 INTO TABLE lt_xml.


    LOOP AT mt_xf REFERENCE INTO lr_xf.

      lv_font = 0.

      lv_apply = ``.
      IF lr_xf->bold = abap_true.
        lv_font = 1.
        lv_apply = ` applyFont="1"`.
      ENDIF.
      IF lr_xf->numfmt <> cs_numfmt-general.
        lv_apply = lv_apply && ` applyNumberFormat="1"`.
      ENDIF.

      temp138 = |<xf numFmtId="{ lr_xf->numfmt }" fontId="{ lv_font }" fillId="0" borderId="0" xfId="0"{ lv_apply }/>|.
      INSERT temp138
             INTO TABLE lt_xml.
    ENDLOOP.
    INSERT `</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>`
           INTO TABLE lt_xml.
    INSERT `</styleSheet>` INTO TABLE lt_xml.
    result = concat_lines_of( lt_xml ).

  ENDMETHOD.

  METHOD get_xlsx.

    DATA lt_file  TYPE z2ui5_cl_tcl_context=>ty_t_zip_file.
    DATA lt_types TYPE string_table.
    DATA lt_book  TYPE string_table.
    DATA lt_rels  TYPE string_table.
    DATA lv_table TYPE i.
      DATA temp139 TYPE z2ui5_cl_tcl_xlsx=>ty_s_out_sheet.
    DATA temp140 LIKE LINE OF lt_types.
    DATA temp141 LIKE LINE OF lt_types.
    DATA temp142 LIKE LINE OF lt_types.
    DATA temp143 LIKE LINE OF lt_book.
    DATA temp144 LIKE LINE OF lt_rels.
    DATA temp145 LIKE LINE OF mt_out_sheet.
    DATA lr_sheet LIKE REF TO temp145.
      DATA lv_index LIKE sy-tabix.
      DATA temp146 LIKE LINE OF lt_types.
      DATA lv_name TYPE string.
      DATA temp147 LIKE LINE OF lt_book.
      DATA temp148 LIKE LINE OF lt_rels.
      DATA temp149 LIKE LINE OF lt_rels.
      DATA temp150 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.
        DATA temp151 LIKE LINE OF lt_types.
        DATA temp152 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.
        DATA temp153 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.
    DATA temp154 LIKE LINE OF lt_rels.
    DATA temp155 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.
    DATA temp156 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.
    DATA temp157 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.
    DATA temp158 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.
    DATA temp159 TYPE z2ui5_cl_tcl_context=>ty_s_zip_file.

    IF mv_loaded = abap_true.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `XLSX_READ_ONLY - a workbook that was read is not written again`.
    ENDIF.
    " a workbook without a sheet is none Excel opens
    IF mt_out_sheet IS INITIAL.

      CLEAR temp139.
      temp139-name = `Sheet1`.
      temp139-xml = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( |{ cv_xml_head }<worksheet xmlns="{ cs_ns-main }"><sheetData/></worksheet>| ).
      INSERT temp139
             INTO TABLE mt_out_sheet.
    ENDIF.


    temp140 = |{ cv_xml_head }<Types xmlns="{ cs_ns-types }">|.
    INSERT temp140 INTO TABLE lt_types.
    INSERT `<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>`
           INTO TABLE lt_types.
    INSERT `<Default Extension="xml" ContentType="application/xml"/>` INTO TABLE lt_types.

    temp141 = |<Override PartName="/xl/workbook.xml" ContentType="{ cs_ns-ct }.sheet.main+xml"/>|.
    INSERT temp141
           INTO TABLE lt_types.

    temp142 = |<Override PartName="/xl/styles.xml" ContentType="{ cs_ns-ct }.styles+xml"/>|.
    INSERT temp142
           INTO TABLE lt_types.

    temp143 = |{ cv_xml_head }<workbook xmlns="{ cs_ns-main }" xmlns:r="{ cs_ns-rel }">|.
    INSERT temp143 INTO TABLE lt_book.
    INSERT `<bookViews><workbookView/></bookViews><sheets>` INTO TABLE lt_book.

    temp144 = |{ cv_xml_head }<Relationships xmlns="{ cs_ns-pkg_rel }">|.
    INSERT temp144 INTO TABLE lt_rels.



    LOOP AT mt_out_sheet REFERENCE INTO lr_sheet.

      lv_index = sy-tabix.

      temp146 = |<Override PartName="/xl/worksheets/sheet{ lv_index }.xml" ContentType="{ cs_ns-ct }.worksheet+xml"/>|.
      INSERT temp146
             INTO TABLE lt_types.

      lv_name = z2ui5_cl_tcl_context=>c_escape_xml( lr_sheet->name ).

      temp147 = |<sheet name="{ lv_name }" sheetId="{ lv_index }" r:id="rId{ lv_index }"/>|.
      INSERT temp147 INTO TABLE lt_book.

      temp148 = |<Relationship Id="rId{ lv_index }" Type="{ cs_ns-rel }/worksheet"|.
      INSERT temp148 INTO TABLE lt_rels.

      temp149 = | Target="worksheets/sheet{ lv_index }.xml"/>|.
      INSERT temp149 INTO TABLE lt_rels.

      CLEAR temp150.
      temp150-name = |xl/worksheets/sheet{ lv_index }.xml|.
      temp150-content = lr_sheet->xml.
      INSERT temp150 INTO TABLE lt_file.

      IF lr_sheet->table_xml IS NOT INITIAL.
        lv_table = lv_table + 1.

        temp151 = |<Override PartName="/xl/tables/table{ lv_table }.xml" ContentType="{ cs_ns-ct }.table+xml"/>|.
        INSERT temp151
               INTO TABLE lt_types.

        CLEAR temp152.
        temp152-name = |xl/tables/table{ lv_table }.xml|.
        temp152-content = lr_sheet->table_xml.
        INSERT temp152 INTO TABLE lt_file.

        CLEAR temp153.
        temp153-name = |xl/worksheets/_rels/sheet{ lv_index }.xml.rels|.
        temp153-content = rels_xml( kind = `table` target = |../tables/table{ lv_table }.xml| ).
        INSERT temp153 INTO TABLE lt_file.
      ENDIF.
    ENDLOOP.

    INSERT `</Types>` INTO TABLE lt_types.
    INSERT `</sheets>` INTO TABLE lt_book.
    IF mv_formulas = abap_true.
      " the formulas carry no value, or one worked out here: Excel works
      " them out when it opens the file
      INSERT `<calcPr fullCalcOnLoad="1"/>` INTO TABLE lt_book.
    ENDIF.
    INSERT `</workbook>` INTO TABLE lt_book.

    temp154 = |<Relationship Id="rId{ lines( mt_out_sheet ) + 1 }" Type="{ cs_ns-rel }/styles" Target="styles.xml"/>|.
    INSERT temp154
           INTO TABLE lt_rels.
    INSERT `</Relationships>` INTO TABLE lt_rels.


    CLEAR temp155.
    temp155-name = `[Content_Types].xml`.
    temp155-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( concat_lines_of( lt_types ) ).
    INSERT temp155
           INTO lt_file INDEX 1.

    CLEAR temp156.
    temp156-name = `_rels/.rels`.
    temp156-content = rels_xml( kind = `officeDocument` target = `xl/workbook.xml` ).
    INSERT temp156
           INTO lt_file INDEX 2.

    CLEAR temp157.
    temp157-name = `xl/workbook.xml`.
    temp157-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( concat_lines_of( lt_book ) ).
    INSERT temp157
           INTO lt_file INDEX 3.

    CLEAR temp158.
    temp158-name = `xl/_rels/workbook.xml.rels`.
    temp158-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( concat_lines_of( lt_rels ) ).
    INSERT temp158
           INTO lt_file INDEX 4.

    CLEAR temp159.
    temp159-name = `xl/styles.xml`.
    temp159-content = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( styles_xml( ) ).
    INSERT temp159
           INTO lt_file INDEX 5.

    result = z2ui5_cl_tcl_context=>zip_pack( lt_file ).

  ENDMETHOD.

  METHOD column_to_letters.

    DATA lv_rest LIKE val.
      DATA lv_digit TYPE i.
    lv_rest = val.
    WHILE lv_rest > 0.

      lv_digit = ( lv_rest - 1 ) MOD 26.
      result = substring( val = cv_letters
                          off = lv_digit
                          len = 1 ) && result.
      lv_rest = ( lv_rest - 1 ) DIV 26.
    ENDWHILE.

  ENDMETHOD.

  METHOD column_to_number.

    DATA lv_pos TYPE i.

    DATA lv_text TYPE string.
    DATA lv_len TYPE i.
      DATA lv_found TYPE i.
    lv_text = to_upper( val ).

    lv_len = strlen( lv_text ).
    WHILE lv_pos < lv_len.

      lv_found = find( val = cv_letters
                             sub = substring( val = lv_text
                                              off = lv_pos
                                              len = 1 ) ).
      lv_pos = lv_pos + 1.
      IF lv_found < 0.
        " the $ of an absolute address, and the row behind the letters
        IF result > 0.
          RETURN.
        ENDIF.
        CONTINUE.
      ENDIF.
      result = result * 26 + lv_found + 1.
    ENDWHILE.

  ENDMETHOD.

  METHOD load.

    DATA lv_kind TYPE string.
    DATA lv_name TYPE string.
    DATA lt_attr TYPE z2ui5_cl_tcl_context=>ty_t_xml_attribute.

    " a workbook is a ZIP archive, and one starts with PK. Looked at here:
    " what the ZIP class does with other bytes differs by release
    CONSTANTS lc_zip TYPE x LENGTH 2 VALUE '504B'.
    CONSTANTS lc_ole TYPE x LENGTH 4 VALUE 'D0CF11E0'.
        DATA x TYPE REF TO cx_root.
    DATA lv_book TYPE string.
    DATA temp160 TYPE z2ui5_cl_tcl_xlsx=>ty_t_rel.
    DATA temp38 LIKE LINE OF temp160.
    DATA lr_rel LIKE REF TO temp38.
    DATA lv_content TYPE xstring.
    DATA lv_folder TYPE string.
    DATA lt_rel TYPE z2ui5_cl_tcl_xlsx=>ty_t_rel.
    DATA lo_reader TYPE REF TO object.
          DATA lv_1904 TYPE string.
          DATA temp3 TYPE xsdboolean.
          DATA lv_id TYPE string.
              DATA temp161 TYPE z2ui5_cl_tcl_xlsx=>ty_s_sheet.
      DATA lv_path TYPE string.

    mv_loaded = abap_true.

    IF xstrlen( val ) >= 4 AND val(4) = lc_ole.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `XLSX_NO_WORKBOOK - the file is an .xls file of Excel 97-2003 or a workbook with a password`.
    ENDIF.
    IF xstrlen( val ) < 4 OR val(2) <> lc_zip.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `XLSX_NO_WORKBOOK - the file is no .xlsx workbook`.
    ENDIF.
    TRY.
        mt_part = z2ui5_cl_tcl_context=>zip_unpack( val ).

      CATCH cx_root INTO x.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val      = `XLSX_NO_WORKBOOK - the file is no .xlsx workbook`
            previous = x.
    ENDTRY.

    " the workbook part is the one the package names as its document

    lv_book = `xl/workbook.xml`.

    temp160 = rels_read( `_rels/.rels` ).


    LOOP AT temp160 REFERENCE INTO lr_rel.
      IF z2ui5_cl_tcl_context=>c_ends_with( val    = lr_rel->type
                                                 suffix = `/officeDocument` ) = abap_true.
        lv_book = path_resolve( base   = ``
                                target = lr_rel->target ).
      ENDIF.
    ENDLOOP.

    lv_content = part_get( lv_book ).
    IF lv_content IS INITIAL.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `XLSX_NO_WORKBOOK - the file is no .xlsx workbook`.
    ENDIF.


    lv_folder = path_folder( lv_book ).

    lt_rel = rels_read( |{ lv_folder }_rels/{ substring( val = lv_book
                                                              off = strlen( lv_folder ) ) }.rels| ).


    lo_reader = z2ui5_cl_tcl_context=>xml_reader_create( lv_content ).
    DO.
      z2ui5_cl_tcl_context=>xml_reader_next( EXPORTING reader      = lo_reader
                                                  IMPORTING kind        = lv_kind
                                                            name        = lv_name
                                                            t_attribute = lt_attr ).
      IF lv_kind = z2ui5_cl_tcl_context=>cs_xml_node-end.
        EXIT.
      ENDIF.
      IF lv_kind <> z2ui5_cl_tcl_context=>cs_xml_node-open.
        CONTINUE.
      ENDIF.
      CASE lv_name.
        WHEN `workbookPr`.
          " the date system of Excel for Mac up to 2008: day 0 is 1904-01-01

          lv_1904 = attr( t_attribute = lt_attr
                                name        = `date1904` ).

          temp3 = boolc( lv_1904 = `1` OR lv_1904 = `true` ).
          mv_date1904 = temp3.
        WHEN `sheet`.

          lv_id = attr( t_attribute = lt_attr
                              name        = `id` ).
          LOOP AT lt_rel REFERENCE INTO lr_rel.
            IF lr_rel->id = lv_id.

              CLEAR temp161.
              temp161-name = attr( t_attribute = lt_attr name = `name` ).
              temp161-path = path_resolve( base = lv_book target = lr_rel->target ).
              INSERT temp161 INTO TABLE mt_sheet.
              EXIT.
            ENDIF.
          ENDLOOP.
      ENDCASE.
    ENDDO.

    LOOP AT lt_rel REFERENCE INTO lr_rel.

      lv_path = path_resolve( base   = lv_book
                                    target = lr_rel->target ).
      IF z2ui5_cl_tcl_context=>c_ends_with( val    = lr_rel->type
                                                 suffix = `/sharedStrings` ) = abap_true.
        shared_read( part_get( lv_path ) ).
        " read once, and a large part - not kept twice
        DELETE mt_part WHERE name = lv_path.
      ELSEIF z2ui5_cl_tcl_context=>c_ends_with( val    = lr_rel->type
                                                     suffix = `/styles` ) = abap_true.
        styles_read( part_get( lv_path ) ).
        DELETE mt_part WHERE name = lv_path.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD part_get.

    DATA temp162 LIKE LINE OF mt_part.
    DATA lr_part LIKE REF TO temp162.
    DATA lv_name TYPE string.
    LOOP AT mt_part REFERENCE INTO lr_part.
      IF lr_part->name = val.
        result = lr_part->content.
        RETURN.
      ENDIF.
    ENDLOOP.
    " a package names its parts without regard to case

    lv_name = to_upper( val ).
    LOOP AT mt_part REFERENCE INTO lr_part.
      IF to_upper( lr_part->name ) = lv_name.
        result = lr_part->content.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD rels_read.

    DATA lv_kind TYPE string.
    DATA lv_name TYPE string.
    DATA lt_attr TYPE z2ui5_cl_tcl_context=>ty_t_xml_attribute.

    DATA lv_content TYPE xstring.
    DATA lo_reader TYPE REF TO object.
        DATA temp163 TYPE z2ui5_cl_tcl_xlsx=>ty_s_rel.
    lv_content = part_get( val ).
    IF lv_content IS INITIAL.
      RETURN.
    ENDIF.


    lo_reader = z2ui5_cl_tcl_context=>xml_reader_create( lv_content ).
    DO.
      z2ui5_cl_tcl_context=>xml_reader_next( EXPORTING reader      = lo_reader
                                                  IMPORTING kind        = lv_kind
                                                            name        = lv_name
                                                            t_attribute = lt_attr ).
      IF lv_kind = z2ui5_cl_tcl_context=>cs_xml_node-end.
        EXIT.
      ENDIF.
      IF lv_kind = z2ui5_cl_tcl_context=>cs_xml_node-open AND lv_name = `Relationship`.

        CLEAR temp163.
        temp163-id = attr( t_attribute = lt_attr name = `Id` ).
        temp163-type = attr( t_attribute = lt_attr name = `Type` ).
        temp163-target = attr( t_attribute = lt_attr name = `Target` ).
        INSERT temp163 INTO TABLE result.
      ENDIF.
    ENDDO.

  ENDMETHOD.

  METHOD shared_read.

    DATA lv_kind  TYPE string.
    DATA lv_name  TYPE string.
    DATA lv_value TYPE string.
    DATA lv_text  TYPE string.
    DATA lv_take  TYPE abap_bool.
    DATA lv_ruby  TYPE abap_bool.
    DATA lo_reader TYPE REF TO object.
              DATA temp4 TYPE xsdboolean.

    IF val IS INITIAL.
      RETURN.
    ENDIF.


    lo_reader = z2ui5_cl_tcl_context=>xml_reader_create( val ).
    DO.
      z2ui5_cl_tcl_context=>xml_reader_next( EXPORTING reader = lo_reader
                                                  IMPORTING kind   = lv_kind
                                                            name   = lv_name
                                                            value  = lv_value ).
      CASE lv_kind.
        WHEN z2ui5_cl_tcl_context=>cs_xml_node-open.
          CASE lv_name.
            WHEN `si`.
              CLEAR lv_text.
            WHEN `rPh`.
              " the reading aid of a Japanese text is no part of the text
              lv_ruby = abap_true.
            WHEN `t`.
              " one t, or one per run of a text formatted in parts

              temp4 = boolc( lv_ruby = abap_false ).
              lv_take = temp4.
          ENDCASE.
        WHEN z2ui5_cl_tcl_context=>cs_xml_node-value.
          IF lv_take = abap_true.
            lv_text = lv_text && lv_value.
          ENDIF.
        WHEN z2ui5_cl_tcl_context=>cs_xml_node-close.
          CASE lv_name.
            WHEN `t`.
              lv_take = abap_false.
            WHEN `rPh`.
              lv_ruby = abap_false.
            WHEN `si`.
              INSERT text_decode( lv_text ) INTO TABLE mt_shared.
          ENDCASE.
        WHEN OTHERS.
          EXIT.
      ENDCASE.
    ENDDO.

  ENDMETHOD.

  METHOD styles_read.

    TYPES:
      BEGIN OF ty_s_fmt,
        id   TYPE i,
        code TYPE string,
      END OF ty_s_fmt.
    TYPES temp4 TYPE STANDARD TABLE OF ty_s_fmt WITH DEFAULT KEY.
DATA lt_fmt  TYPE temp4.
    DATA lv_kind TYPE string.
    DATA lv_name TYPE string.
    DATA lt_attr TYPE z2ui5_cl_tcl_context=>ty_t_xml_attribute.
    DATA lv_cell TYPE abap_bool.
    DATA lv_id   TYPE i.
    DATA lo_reader TYPE REF TO object.
              DATA temp164 TYPE ty_s_fmt.
              DATA lv_code TYPE string.
              DATA temp165 LIKE LINE OF lt_fmt.
              DATA lr_fmt LIKE REF TO temp165.

    IF val IS INITIAL.
      RETURN.
    ENDIF.


    lo_reader = z2ui5_cl_tcl_context=>xml_reader_create( val ).
    DO.
      z2ui5_cl_tcl_context=>xml_reader_next( EXPORTING reader      = lo_reader
                                                  IMPORTING kind        = lv_kind
                                                            name        = lv_name
                                                            t_attribute = lt_attr ).
      CASE lv_kind.
        WHEN z2ui5_cl_tcl_context=>cs_xml_node-open.
          CASE lv_name.
            WHEN `numFmt`.
              lv_id = hex_to_int( attr( t_attribute = lt_attr
                                        name        = `numFmtId` ) ).

              CLEAR temp164.
              temp164-id = lv_id.
              temp164-code = attr( t_attribute = lt_attr name = `formatCode` ).
              INSERT temp164 INTO TABLE lt_fmt.
            WHEN `cellXfs`.
              " the formats a cell names - cellStyleXfs holds xf elements too
              lv_cell = abap_true.
            WHEN `xf`.
              IF lv_cell = abap_false.
                CONTINUE.
              ENDIF.
              lv_id = hex_to_int( attr( t_attribute = lt_attr
                                        name        = `numFmtId` ) ).

              lv_code = ``.


              LOOP AT lt_fmt REFERENCE INTO lr_fmt.
                IF lr_fmt->id = lv_id.
                  lv_code = lr_fmt->code.
                  EXIT.
                ENDIF.
              ENDLOOP.
              INSERT format_kind( id   = lv_id
                                  code = lv_code ) INTO TABLE mt_style_kind.
          ENDCASE.
        WHEN z2ui5_cl_tcl_context=>cs_xml_node-close.
          IF lv_name = `cellXfs`.
            EXIT.
          ENDIF.
        WHEN z2ui5_cl_tcl_context=>cs_xml_node-end.
          EXIT.
      ENDCASE.
    ENDDO.

  ENDMETHOD.

  METHOD format_kind.

    DATA lv_pos     TYPE i.
    DATA lv_bare    TYPE string.
    DATA lv_elapsed TYPE abap_bool.
    DATA lv_code TYPE string.
    DATA lv_len TYPE i.
      DATA lv_char TYPE string.
          DATA lv_end TYPE i.
          DATA lv_section TYPE string.
    DATA lv_date TYPE abap_bool.
    DATA temp5 TYPE xsdboolean.
    DATA lv_time TYPE abap_bool.
    DATA temp6 TYPE xsdboolean.

    IF code IS INITIAL.
      " a built-in format: the ids of the dates and times of every locale
      IF id >= 14 AND id <= 17 OR id >= 27 AND id <= 36 OR id >= 50 AND id <= 58.
        result = cs_kind-date.
      ELSEIF id >= 18 AND id <= 21 OR id = 45 OR id = 47.
        result = cs_kind-time.
      ELSEIF id = 22.
        result = cs_kind-timestamp.
      ELSEIF id = 46.
        result = `L`.
      ENDIF.
      RETURN.
    ENDIF.

    " The letters that format the value: without the quoted text, the
    " character behind a backslash, an underscore or an asterisk, and
    " the sections in brackets (a colour, a locale, a condition) - but a
    " section of h, m or s only is a time that runs on past 24 hours

    lv_code = to_lower( code ).

    lv_len = strlen( lv_code ).
    WHILE lv_pos < lv_len.

      lv_char = substring( val = lv_code
                                 off = lv_pos
                                 len = 1 ).
      lv_pos = lv_pos + 1.
      CASE lv_char.
        WHEN `"`.

          lv_end = find( val = lv_code
                               sub = `"`
                               off = lv_pos ).
          IF lv_end < 0.
            EXIT.
          ENDIF.
          lv_pos = lv_end + 1.
        WHEN `\\` OR `_` OR `*`.
          lv_pos = lv_pos + 1.
        WHEN `[`.
          lv_end = find( val = lv_code
                         sub = `]`
                         off = lv_pos ).
          IF lv_end < 0.
            EXIT.
          ENDIF.

          lv_section = substring( val = lv_code
                                        off = lv_pos
                                        len = lv_end - lv_pos ).
          IF lv_section IS NOT INITIAL AND ( lv_section CO `h` OR lv_section CO `m` OR lv_section CO `s` ).
            lv_elapsed = abap_true.
          ENDIF.
          lv_pos = lv_end + 1.
        WHEN OTHERS.
          lv_bare = lv_bare && lv_char.
      ENDCASE.
    ENDWHILE.



    temp5 = boolc( lv_bare CA `dy` ).
    lv_date = temp5.


    temp6 = boolc( lv_elapsed = abap_true OR lv_bare CA `hs` ).
    lv_time = temp6.
    IF lv_date = abap_false AND lv_time = abap_false AND lv_bare CA `m`.
      " months only (`mmmm`) - no number format has an m of its own
      lv_date = abap_true.
    ENDIF.

    IF lv_date = abap_true AND lv_time = abap_true.
      result = cs_kind-timestamp.
    ELSEIF lv_date = abap_true.
      result = cs_kind-date.
    ELSEIF lv_elapsed = abap_true.
      result = `L`.
    ELSEIF lv_time = abap_true.
      result = cs_kind-time.
    ENDIF.

  ENDMETHOD.

  METHOD get_sheet_names.
      DATA temp166 LIKE LINE OF mt_sheet.
      DATA lr_sheet LIKE REF TO temp166.
      DATA temp167 LIKE LINE OF mt_out_sheet.
      DATA lr_out LIKE REF TO temp167.

    IF mv_loaded = abap_true.


      LOOP AT mt_sheet REFERENCE INTO lr_sheet.
        INSERT lr_sheet->name INTO TABLE result.
      ENDLOOP.
    ELSE.


      LOOP AT mt_out_sheet REFERENCE INTO lr_out.
        INSERT lr_out->name INTO TABLE result.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD sheet_part.

    DATA lv_path TYPE string.
      DATA lv_name TYPE string.
      DATA temp168 LIKE LINE OF mt_sheet.
      DATA lr_sheet LIKE REF TO temp168.
      DATA lv_sheets TYPE i.
      FIELD-SYMBOLS <temp169> LIKE LINE OF mt_sheet.
      DATA temp170 LIKE sy-tabix.

    IF mv_loaded = abap_false.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `XLSX_NOT_READ - a workbook built with factory( ) is written, not read`.
    ENDIF.

    IF sheet IS NOT INITIAL.

      lv_name = to_upper( sheet ).


      LOOP AT mt_sheet REFERENCE INTO lr_sheet.
        IF to_upper( lr_sheet->name ) = lv_name.
          lv_path = lr_sheet->path.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_path IS INITIAL.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val = |XLSX_SHEET_UNKNOWN - the workbook has no sheet { sheet }|.
      ENDIF.
    ELSE.

      lv_sheets = lines( mt_sheet ).
      IF index < 1 OR index > lv_sheets.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val = |XLSX_SHEET_UNKNOWN - the workbook has { lv_sheets } sheets, none at { index }|.
      ENDIF.


      temp170 = sy-tabix.
      READ TABLE mt_sheet INDEX index ASSIGNING <temp169>.
      sy-tabix = temp170.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      lv_path = <temp169>-path.
    ENDIF.

    result = part_get( lv_path ).
    IF result IS INITIAL.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = |XLSX_SHEET_UNKNOWN - the file has no part { lv_path }|.
    ENDIF.

  ENDMETHOD.

  METHOD sheet_read_row.

    DATA lv_kind   TYPE string.
    DATA lv_name   TYPE string.
    DATA lv_value  TYPE string.
    DATA lt_attr   TYPE z2ui5_cl_tcl_context=>ty_t_xml_attribute.
    DATA lv_text   TYPE string.
    DATA lv_take   TYPE abap_bool.
    DATA lv_ruby   TYPE abap_bool.
    DATA lv_col    TYPE i.
    DATA lv_type   TYPE string.
    DATA lv_style  TYPE string.
    DATA lv_ref    TYPE string.
    DATA ls_cell   TYPE ty_s_cell.
              DATA temp7 TYPE xsdboolean.

    CLEAR t_cell.
    CLEAR eof.

    DO.
      z2ui5_cl_tcl_context=>xml_reader_next( EXPORTING reader      = reader
                                                  IMPORTING kind        = lv_kind
                                                            name        = lv_name
                                                            value       = lv_value
                                                            t_attribute = lt_attr ).
      CASE lv_kind.

        WHEN z2ui5_cl_tcl_context=>cs_xml_node-open.
          CASE lv_name.
            WHEN `row`.
              " r is optional: without it the row follows the one before
              lv_ref = attr( t_attribute = lt_attr
                             name        = `r` ).
              IF lv_ref IS NOT INITIAL AND lv_ref CO cv_digits.
                row = lv_ref.
              ELSE.
                row = row + 1.
              ENDIF.
              lv_col = 0.
            WHEN `c`.
              lv_ref = attr( t_attribute = lt_attr
                             name        = `r` ).
              IF lv_ref IS NOT INITIAL.
                lv_col = column_to_number( lv_ref ).
              ELSE.
                lv_col = lv_col + 1.
              ENDIF.
              lv_type = attr( t_attribute = lt_attr
                              name        = `t` ).
              lv_style = attr( t_attribute = lt_attr
                               name        = `s` ).
              CLEAR lv_text.
            WHEN `v`.
              lv_take = abap_true.
            WHEN `t`.
              " the text of an inline string, in one piece or in runs

              temp7 = boolc( lv_ruby = abap_false ).
              lv_take = temp7.
            WHEN `rPh`.
              lv_ruby = abap_true.
          ENDCASE.

        WHEN z2ui5_cl_tcl_context=>cs_xml_node-value.
          IF lv_take = abap_true.
            lv_text = lv_text && lv_value.
          ENDIF.

        WHEN z2ui5_cl_tcl_context=>cs_xml_node-close.
          CASE lv_name.
            WHEN `v` OR `t`.
              lv_take = abap_false.
            WHEN `rPh`.
              lv_ruby = abap_false.
            WHEN `c`.
              CLEAR ls_cell.
              ls_cell-row = row.
              ls_cell-col = lv_col.
              cell_read( EXPORTING cell_type = lv_type
                                   style     = lv_style
                                   text      = lv_text
                         IMPORTING kind      = ls_cell-kind
                                   value     = ls_cell-value ).
              " a FALSE is a value: its cell is there, and empty
              IF ls_cell-value IS NOT INITIAL OR ls_cell-kind = cs_kind-boolean.
                INSERT ls_cell INTO TABLE t_cell.
              ENDIF.
            WHEN `row`.
              IF t_cell IS NOT INITIAL.
                RETURN.
              ENDIF.
            WHEN `sheetData`.
              eof = abap_true.
              RETURN.
          ENDCASE.

        WHEN OTHERS.
          eof = abap_true.
          RETURN.

      ENDCASE.
    ENDDO.

  ENDMETHOD.

  METHOD cell_read.
          DATA temp171 TYPE i.
          DATA lv_index TYPE i.
          DATA lv_texts TYPE i.
            FIELD-SYMBOLS <temp172> LIKE LINE OF mt_shared.
            DATA temp173 LIKE sy-tabix.

    CLEAR kind.
    CLEAR value.

    CASE cell_type.
      WHEN `s`.
        " the index of the text in the shared strings, from 0
        kind = cs_kind-text.
        IF text IS NOT INITIAL AND text CO cv_digits.

          temp171 = text.

          lv_index = temp171 + 1.

          lv_texts = lines( mt_shared ).
          IF lv_index <= lv_texts.


            temp173 = sy-tabix.
            READ TABLE mt_shared INDEX lv_index ASSIGNING <temp172>.
            sy-tabix = temp173.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            value = <temp172>.
          ENDIF.
        ENDIF.
      WHEN `inlineStr` OR `str`.
        kind = cs_kind-text.
        value = text_decode( text ).
      WHEN `b`.
        kind = cs_kind-boolean.
        IF text = `1`.
          value = `X`.
        ENDIF.
      WHEN `e`.
        kind = cs_kind-error.
        value = text.
      WHEN `d`.
        " a date in ISO 8601, as a strict workbook writes it
        value = text.
        IF strlen( text ) > 10.
          kind = cs_kind-timestamp.
          IF strlen( text ) > 19.
            value = substring( val = text
                               len = 19 ).
          ENDIF.
        ELSE.
          kind = cs_kind-date.
        ENDIF.
      WHEN OTHERS.
        IF text IS NOT INITIAL.
          number_cell( EXPORTING val   = text
                                 style = style
                       IMPORTING kind  = kind
                                 value = value ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD number_cell.

    DATA lv_fraction TYPE decfloat34.
    DATA lv_seconds  TYPE i.
    DATA lv_days     TYPE i.
    DATA lv_number TYPE string.
    DATA lv_format TYPE string.
      DATA temp174 TYPE i.
      DATA lv_index TYPE i.
      DATA lv_styles TYPE i.
        FIELD-SYMBOLS <temp175> LIKE LINE OF mt_style_kind.
        DATA temp176 LIKE sy-tabix.
    DATA lv_whole LIKE lv_number.
    DATA lv_part TYPE string.
    DATA lv_time TYPE string.
    DATA lv_date TYPE d.

    CLEAR kind.
    CLEAR value.


    lv_number = number_plain( val ).
    IF lv_number IS INITIAL.
      " no number after all - handed on as it stands
      kind = cs_kind-text.
      value = val.
      RETURN.
    ENDIF.
    kind = cs_kind-number.
    value = lv_number.

    " the format the cell is shown in says whether the number is a date

    lv_format = ``.
    IF style IS NOT INITIAL AND style CO cv_digits.

      temp174 = style.

      lv_index = temp174 + 1.

      lv_styles = lines( mt_style_kind ).
      IF lv_index <= lv_styles.


        temp176 = sy-tabix.
        READ TABLE mt_style_kind INDEX lv_index ASSIGNING <temp175>.
        sy-tabix = temp176.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        lv_format = <temp175>.
      ENDIF.
    ENDIF.
    IF lv_format IS INITIAL OR lv_number(1) = `-`.
      RETURN.
    ENDIF.

    " whole days and the fraction of a day, to the second

    lv_whole = lv_number.

    lv_part = `0`.
    IF lv_number CS `.`.
      lv_whole = substring_before( val = lv_number
                                   sub = `.` ).
      lv_part = substring_after( val = lv_number
                                 sub = `.` ).
    ENDIF.
    IF strlen( lv_whole ) > 7.
      RETURN.
    ENDIF.
    lv_days = lv_whole.
    lv_fraction = |0.{ lv_part }|.
    lv_seconds = round( val = lv_fraction * 86400
                        dec = 0 ).
    IF lv_seconds >= 86400.
      lv_seconds = lv_seconds - 86400.
      lv_days = lv_days + 1.
    ENDIF.

    lv_time = |{ two_digits( lv_seconds DIV 3600 ) }:{ two_digits( lv_seconds MOD 3600 DIV 60 ) }|
                 && |:{ two_digits( lv_seconds MOD 60 ) }|.

    IF lv_format = `L`.
      " a duration: the hours are not wrapped at 24
      kind = cs_kind-time.
      IF lv_days > 0.
        kind = cs_kind-text.
        lv_time = |{ lv_days * 24 + lv_seconds DIV 3600 }{ substring( val = lv_time
                                                                      off = 2 ) }|.
      ENDIF.
      value = lv_time.
      RETURN.
    ENDIF.
    IF lv_format = cs_kind-time.
      kind = cs_kind-time.
      value = lv_time.
      RETURN.
    ENDIF.


    lv_date = serial_to_date( val      = lv_days
                                    date1904 = mv_date1904 ).
    IF lv_date IS INITIAL.
      " day 0 or beyond the year 9999 - no date, the number stays
      RETURN.
    ENDIF.
    value = |{ lv_date(4) }-{ lv_date+4(2) }-{ lv_date+6(2) }|.
    IF lv_format = cs_kind-date.
      kind = cs_kind-date.
    ELSE.
      kind = cs_kind-timestamp.
      value = |{ value }T{ lv_time }|.
    ENDIF.

  ENDMETHOD.

  METHOD serial_to_date.

    IF val > 2958465.
      RETURN.
    ENDIF.
    IF date1904 = abap_true.
      result = cv_date_1904 + val.
    ELSEIF val >= 61.
      result = cv_date_base + val.
    ELSEIF val >= 1.
      " up to 1900-02-28 Excel is one day ahead, and its 1900-02-29 (60)
      " is the first of March here
      result = cv_date_base + val + 1.
    ENDIF.

  ENDMETHOD.

  METHOD number_plain.

    DATA lv_exp   TYPE i.
    DATA lv_point TYPE i.
    DATA lv_round TYPE p LENGTH 16 DECIMALS 0.

    DATA lv_text TYPE string.
    DATA lv_sign TYPE string.
      DATA lv_exp_text TYPE string.
      DATA lv_exp_sign TYPE i.
    DATA lv_whole LIKE lv_text.
    DATA lv_part TYPE string.
    DATA lv_digits TYPE string.
    DATA lv_zeros TYPE i.
    DATA lv_len TYPE i.
      DATA lv_next TYPE string.
    lv_text = to_upper( condense( val ) ).

    lv_sign = ``.
    IF lv_text IS INITIAL.
      RETURN.
    ENDIF.
    CASE lv_text(1).
      WHEN `-`.
        lv_sign = `-`.
        lv_text = substring( val = lv_text
                             off = 1 ).
      WHEN `+`.
        lv_text = substring( val = lv_text
                             off = 1 ).
    ENDCASE.

    " mantissa and exponent
    IF lv_text CS `E`.

      lv_exp_text = substring_after( val = lv_text
                                           sub = `E` ).
      lv_text = substring_before( val = lv_text
                                  sub = `E` ).

      lv_exp_sign = 1.
      IF lv_exp_text IS NOT INITIAL AND lv_exp_text(1) = `-`.
        lv_exp_sign = -1.
        lv_exp_text = substring( val = lv_exp_text
                                 off = 1 ).
      ELSEIF lv_exp_text IS NOT INITIAL AND lv_exp_text(1) = `+`.
        lv_exp_text = substring( val = lv_exp_text
                                 off = 1 ).
      ENDIF.
      IF lv_exp_text IS INITIAL OR lv_exp_text CN cv_digits OR strlen( lv_exp_text ) > 4.
        RETURN.
      ENDIF.
      lv_exp = lv_exp_text.
      lv_exp = lv_exp * lv_exp_sign.
    ENDIF.

    " the digits, and where the point stands in them

    lv_whole = lv_text.

    lv_part = ``.
    IF lv_text CS `.`.
      lv_whole = substring_before( val = lv_text
                                   sub = `.` ).
      lv_part = substring_after( val = lv_text
                                 sub = `.` ).
    ENDIF.

    lv_digits = lv_whole && lv_part.
    IF lv_digits IS INITIAL OR lv_digits CN cv_digits.
      RETURN.
    ENDIF.
    lv_point = strlen( lv_whole ) + lv_exp.

    " without the zeros in front

    lv_zeros = 0.

    lv_len = strlen( lv_digits ).
    WHILE lv_zeros < lv_len AND lv_digits+lv_zeros(1) = `0`.
      lv_zeros = lv_zeros + 1.
    ENDWHILE.
    IF lv_zeros = lv_len.
      result = `0`.
      RETURN.
    ENDIF.
    lv_digits = substring( val = lv_digits
                           off = lv_zeros ).
    lv_point = lv_point - lv_zeros.

    " 15 digits are what a cell shows - the 16th and 17th are the noise
    " of the binary number behind it (0.30000000000000004)
    IF strlen( lv_digits ) > digits.

      lv_next = lv_digits+digits(1).
      lv_digits = lv_digits(digits).
      IF lv_next >= `5`.
        lv_round = lv_digits.
        lv_round = lv_round + 1.
        lv_digits = |{ lv_round }|.
        IF strlen( lv_digits ) > digits.
          lv_digits = lv_digits(digits).
          lv_point = lv_point + 1.
        ENDIF.
      ENDIF.
    ENDIF.

    " without the zeros behind
    lv_len = strlen( lv_digits ).
    WHILE lv_len > 1 AND substring( val = lv_digits
                                    off = lv_len - 1
                                    len = 1 ) = `0`.
      lv_len = lv_len - 1.
    ENDWHILE.
    lv_digits = lv_digits(lv_len).

    IF lv_point <= 0.
      result = |0.{ repeat( val = `0`
                            occ = 0 - lv_point ) }{ lv_digits }|.
    ELSEIF lv_point >= lv_len.
      result = |{ lv_digits }{ repeat( val = `0`
                                       occ = lv_point - lv_len ) }|.
    ELSE.
      result = |{ lv_digits(lv_point) }.{ lv_digits+lv_point }|.
    ENDIF.
    result = lv_sign && result.

  ENDMETHOD.

  METHOD get_cells.

    DATA lt_row TYPE ty_t_cell.
    DATA lv_eof TYPE abap_bool.
    DATA lv_row TYPE i.

    DATA lo_reader TYPE REF TO object.
    lo_reader = z2ui5_cl_tcl_context=>xml_reader_create( sheet_part( sheet = sheet
                                                                                index = index ) ).
    DO.
      sheet_read_row( EXPORTING reader = lo_reader
                      IMPORTING t_cell = lt_row
                                eof    = lv_eof
                      CHANGING  row    = lv_row ).
      IF lv_eof = abap_true.
        EXIT.
      ENDIF.
      INSERT LINES OF lt_row INTO TABLE result.
    ENDDO.

  ENDMETHOD.

  METHOD get_table.

    TYPES:
      BEGIN OF ty_s_map,
        name TYPE string,
        cat  TYPE string,
      END OF ty_s_map.
    TYPES temp5 TYPE STANDARD TABLE OF ty_s_map WITH DEFAULT KEY.
DATA lt_map     TYPE temp5.
    DATA lr_line    TYPE REF TO data.
    DATA lt_field   TYPE ty_t_field.
    DATA lt_row     TYPE ty_t_cell.
    DATA lv_eof     TYPE abap_bool.
    DATA lv_row     TYPE i.
    DATA lv_mapped  TYPE abap_bool.
    DATA lv_any     TYPE abap_bool.
    DATA lv_elementary TYPE abap_bool.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <field> TYPE any.
    FIELD-SYMBOLS <cell>  TYPE ty_s_cell.
    FIELD-SYMBOLS <map>   TYPE ty_s_map.
      DATA temp177 LIKE LINE OF lt_field.
      DATA lr_field LIKE REF TO temp177.
        DATA temp178 TYPE ty_s_map.
    DATA lo_reader TYPE REF TO object.
          DATA lv_header TYPE string.
          DATA lv_name LIKE lv_header.
          DATA temp179 LIKE LINE OF t_column.
          DATA lr_column LIKE REF TO temp179.
          DATA ls_field TYPE z2ui5_cl_tcl_xlsx=>ty_s_field.
            DATA temp180 TYPE ty_s_map.
      DATA lv_columns TYPE i.

    CLEAR result.
    CREATE DATA lr_line LIKE LINE OF result.
    ASSIGN lr_line->* TO <line>.
    fields_get( EXPORTING row        = <line>
                IMPORTING elementary = lv_elementary
                          result     = lt_field ).

    IF header_row <= 0.
      " no header: the n-th column is the n-th component


      LOOP AT lt_field REFERENCE INTO lr_field.

        CLEAR temp178.
        temp178-name = lr_field->name.
        temp178-cat = lr_field->cat.
        INSERT temp178 INTO TABLE lt_map.
      ENDLOOP.
      lv_mapped = abap_true.
    ENDIF.


    lo_reader = z2ui5_cl_tcl_context=>xml_reader_create( sheet_part( sheet = sheet
                                                                                index = index ) ).
    DO.
      sheet_read_row( EXPORTING reader = lo_reader
                      IMPORTING t_cell = lt_row
                                eof    = lv_eof
                      CHANGING  row    = lv_row ).
      IF lv_eof = abap_true.
        EXIT.
      ENDIF.
      IF lv_row < header_row.
        CONTINUE.
      ENDIF.

      IF lv_mapped = abap_false.
        lv_mapped = abap_true.
        IF lv_row > header_row.
          " the header row is empty - no column has a component
          EXIT.
        ENDIF.
        LOOP AT lt_row ASSIGNING <cell>.

          lv_header = z2ui5_cl_tcl_context=>c_trim_upper( <cell>-value ).

          lv_name = lv_header.
          " the header the caller gives for a component goes first


          LOOP AT t_column REFERENCE INTO lr_column.
            IF lr_column->header IS NOT INITIAL
                AND z2ui5_cl_tcl_context=>c_trim_upper( lr_column->header ) = lv_header.
              lv_name = z2ui5_cl_tcl_context=>c_trim_upper( lr_column->name ).
              EXIT.
            ENDIF.
          ENDLOOP.

          ls_field = field_find( t_field = lt_field
                                       name    = lv_name ).
          IF ls_field IS INITIAL.
            " `Order Id` for ORDER_ID
            ls_field = field_find( t_field = lt_field
                                   name    = name_by_header( lv_header ) ).
          ENDIF.
          IF ls_field IS INITIAL.
            CONTINUE.
          ENDIF.
          WHILE lines( lt_map ) < <cell>-col.

            CLEAR temp180.
            INSERT temp180 INTO TABLE lt_map.
          ENDWHILE.
          READ TABLE lt_map INDEX <cell>-col ASSIGNING <map>.
          <map>-name = ls_field-name.
          <map>-cat = ls_field-cat.
        ENDLOOP.
        CONTINUE.
      ENDIF.

      CLEAR <line>.
      lv_any = abap_false.

      lv_columns = lines( lt_map ).
      LOOP AT lt_row ASSIGNING <cell>.
        IF <cell>-col > lv_columns.
          CONTINUE.
        ENDIF.
        READ TABLE lt_map INDEX <cell>-col ASSIGNING <map>.
        IF <map>-name IS INITIAL.
          CONTINUE.
        ENDIF.
        IF lv_elementary = abap_true.
          ASSIGN <line> TO <field>.
        ELSE.
          ASSIGN COMPONENT <map>-name OF STRUCTURE <line> TO <field>.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.
        ENDIF.
        cell_to_field( EXPORTING cell  = <cell>
                                 cat   = <map>-cat
                       CHANGING  field = <field> ).
        lv_any = abap_true.
      ENDLOOP.
      IF lv_any = abap_true.
        INSERT <line> INTO TABLE result.
      ENDIF.
    ENDDO.

  ENDMETHOD.

  METHOD cell_to_field.

    DATA lv_date    TYPE d.
    DATA lv_time    TYPE t.
    DATA lv_number  TYPE string.
    DATA lv_serial  TYPE i.
    DATA lv_seconds TYPE i.
    DATA lv_fraction TYPE decfloat34.

    DATA lv_value LIKE cell-value.
    DATA lv_address TYPE string.
        DATA lv_flag TYPE string.
        DATA temp8 TYPE xsdboolean.
                  DATA lv_parsed TYPE decfloat34.
            DATA x TYPE REF TO cx_root.
    lv_value = cell-value.

    lv_address = |{ column_to_letters( cell-col ) }{ cell-row }|.

    IF cell-kind = cs_kind-error.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = |XLSX_CELL_ERROR - cell { lv_address } holds the error { lv_value }|.
    ENDIF.

    CASE cat.

      WHEN cs_cat-text.
        field = lv_value.

      WHEN cs_cat-numc.
        " a NUMC takes the digits and fills up with zeros in front
        field = digits_only( lv_value ).

      WHEN cs_cat-hex.
        TRY.
            field = lv_value.
          CATCH cx_root.
            RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
              EXPORTING
                val = |XLSX_CELL_TYPE - cell { lv_address }: { lv_value } is no hex value|.
        ENDTRY.

      WHEN cs_cat-boolean.

        lv_flag = to_upper( condense( lv_value ) ).

        temp8 = boolc( lv_flag = `X` OR lv_flag = `TRUE` OR lv_flag = `1` ).
        field = temp8.

      WHEN cs_cat-date.
        CASE cell-kind.
          WHEN cs_kind-date OR cs_kind-timestamp.
            " YYYY-MM-DD in front, whatever follows
            lv_number = digits_only( lv_value ).
            IF strlen( lv_number ) > 8.
              lv_number = lv_number(8).
            ENDIF.
          WHEN cs_kind-number.
            " a number shown as a number: YYYYMMDD, or the day Excel counts
            lv_number = lv_value.
            IF lv_number CS `.`.
              lv_number = substring_before( val = lv_number
                                            sub = `.` ).
            ENDIF.
            IF lv_number CO cv_digits AND strlen( lv_number ) < 8.
              lv_serial = lv_number.
              lv_date = serial_to_date( val      = lv_serial
                                        date1904 = mv_date1904 ).
              lv_number = lv_date.
            ENDIF.
          WHEN OTHERS.
            " a text: 2024-03-15, 20240315, 15.03.2024
            lv_number = condense( lv_value ).
            IF strlen( lv_number ) = 10 AND lv_number+2(1) = `.` AND lv_number+5(1) = `.`.
              lv_number = lv_number+6(4) && lv_number+3(2) && lv_number(2).
            ELSE.
              IF strlen( lv_number ) > 10.
                lv_number = lv_number(10).
              ENDIF.
              lv_number = digits_only( lv_number ).
            ENDIF.
        ENDCASE.
        IF strlen( lv_number ) <> 8 OR lv_number CN cv_digits.
          RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
            EXPORTING
              val = |XLSX_CELL_TYPE - cell { lv_address }: { lv_value } is no date|.
        ENDIF.
        field = lv_number.

      WHEN cs_cat-time.
        CASE cell-kind.
          WHEN cs_kind-timestamp.
            " the HH:MM:SS behind the date
            lv_number = digits_only( lv_value ).
            IF strlen( lv_number ) >= 14.
              lv_number = lv_number+8(6).
            ELSE.
              CLEAR lv_number.
            ENDIF.
          WHEN cs_kind-number.
            " the fraction of a day
            lv_fraction = lv_value.
            lv_fraction = frac( lv_fraction ).
            lv_seconds = round( val = lv_fraction * 86400
                                dec = 0 ).
            IF lv_seconds >= 86400.
              lv_seconds = 0.
            ENDIF.
            lv_number = |{ two_digits( lv_seconds DIV 3600 ) }{ two_digits( lv_seconds MOD 3600 DIV 60 ) }|
                     && |{ two_digits( lv_seconds MOD 60 ) }|.
          WHEN OTHERS.
            " 10:30:00, 10:30, 103000
            lv_number = digits_only( lv_value ).
            IF strlen( lv_number ) = 4.
              lv_number = lv_number && `00`.
            ENDIF.
        ENDCASE.
        IF strlen( lv_number ) <> 6 OR lv_number CN cv_digits.
          RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
            EXPORTING
              val = |XLSX_CELL_TYPE - cell { lv_address }: { lv_value } is no time|.
        ENDIF.
        lv_time = lv_number.
        field = lv_time.

      WHEN OTHERS.
        " a number, and a timestamp as the number it is in ABAP
        CASE cell-kind.
          WHEN cs_kind-boolean.
            lv_number = `1`.
          WHEN cs_kind-date OR cs_kind-time OR cs_kind-timestamp.
            lv_number = digits_only( lv_value ).
          WHEN OTHERS.
            lv_number = number_plain( lv_value ).
            IF lv_number IS INITIAL AND lv_value CA cv_digits AND lv_value CO `0123456789.,-+ `.
              " a text that reads as a number in another notation
              " (1.234,56) is one; anything else is not, and the parser
              " would hand back a 0 for it
              TRY.

                  lv_parsed = z2ui5_cl_tcl_context=>conv_string_to_number( lv_value ).
                  lv_number = number_plain( |{ lv_parsed }| ).
                CATCH cx_root.
                  CLEAR lv_number.
              ENDTRY.
            ENDIF.
        ENDCASE.
        IF lv_number IS INITIAL.
          RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
            EXPORTING
              val = |XLSX_CELL_TYPE - cell { lv_address }: { lv_value } is no number|.
        ENDIF.
        TRY.
            field = lv_number.

          CATCH cx_root INTO x.
            RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
              EXPORTING
                val      = |XLSX_CELL_TYPE - cell { lv_address }: { lv_value } does not fit the component|
                previous = x.
        ENDTRY.

    ENDCASE.

  ENDMETHOD.

  METHOD get_table_ref.

    DATA lt_name TYPE string_table.
    DATA lv_cols TYPE i.
    DATA lr_line TYPE REF TO data.
    DATA lv_row  TYPE i.
    FIELD-SYMBOLS <tab>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <field> TYPE any.
    FIELD-SYMBOLS <cell>  TYPE ty_s_cell.
    FIELD-SYMBOLS <name>  TYPE string.

    DATA lt_cell TYPE z2ui5_cl_tcl_xlsx=>ty_t_cell.
      DATA lv_tabix LIKE sy-tabix.
      DATA lv_base LIKE <name>.
      DATA lv_suffix TYPE i.
        DATA lv_first TYPE i.
        DATA lv_other LIKE LINE OF lt_name.
        DATA lv_tail TYPE string.
    lt_cell = get_cells( sheet = sheet
                               index = index ).
    DELETE lt_cell WHERE row < header_row.
    LOOP AT lt_cell ASSIGNING <cell>.
      IF <cell>-col > lv_cols.
        lv_cols = <cell>-col.
      ENDIF.
    ENDLOOP.
    IF lv_cols = 0.
      RETURN.
    ENDIF.

    " a component per column: after the header where there is one, after
    " the letters of the column else - and every name once
    DO lv_cols TIMES.
      INSERT `` INTO TABLE lt_name.
    ENDDO.
    IF header_row > 0.
      LOOP AT lt_cell ASSIGNING <cell> WHERE row = header_row. "#EC CI_SORTSEQ
        READ TABLE lt_name INDEX <cell>-col ASSIGNING <name>.
        <name> = name_by_header( <cell>-value ).
      ENDLOOP.
    ENDIF.
    LOOP AT lt_name ASSIGNING <name>.

      lv_tabix = sy-tabix.
      IF <name> IS INITIAL.
        <name> = column_to_letters( lv_tabix ).
      ENDIF.

      lv_base = <name>.

      lv_suffix = 1.
      DO.
        " the first column of that name - this one, when no earlier has it

        lv_first = 0.

        LOOP AT lt_name INTO lv_other.
          IF lv_other = <name>.
            lv_first = sy-tabix.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF lv_first = lv_tabix.
          EXIT.
        ENDIF.
        lv_suffix = lv_suffix + 1.

        lv_tail = |_{ lv_suffix }|.
        <name> = substring( val = lv_base
                            len = nmin( val1 = strlen( lv_base )
                                        val2 = 30 - strlen( lv_tail ) ) ) && lv_tail.
      ENDDO.
    ENDLOOP.

    result = z2ui5_cl_tcl_context=>rtti_create_tab_by_names( lt_name ).
    ASSIGN result->* TO <tab>.
    CREATE DATA lr_line LIKE LINE OF <tab>.
    ASSIGN lr_line->* TO <line>.

    LOOP AT lt_cell ASSIGNING <cell> WHERE row > header_row. "#EC CI_SORTSEQ
      IF <cell>-row <> lv_row.
        IF lv_row > 0.
          INSERT <line> INTO TABLE <tab>.
        ENDIF.
        CLEAR <line>.
        lv_row = <cell>-row.
      ENDIF.
      ASSIGN COMPONENT <cell>-col OF STRUCTURE <line> TO <field>.
      IF sy-subrc = 0.
        <field> = <cell>-value.
      ENDIF.
    ENDLOOP.
    IF lv_row > 0.
      INSERT <line> INTO TABLE <tab>.
    ENDIF.

  ENDMETHOD.

  METHOD name_by_header.

    DATA lv_pos TYPE i.

    DATA lv_name TYPE string.
    DATA lv_len TYPE i.
      DATA lv_char TYPE string.
    lv_name = z2ui5_cl_tcl_context=>c_trim_upper( val ).

    lv_len = strlen( lv_name ).
    WHILE lv_pos < lv_len.

      lv_char = substring( val = lv_name
                                 off = lv_pos
                                 len = 1 ).
      IF lv_char CA `ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_`.
        result = result && lv_char.
      ELSE.
        result = result && `_`.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.

    IF result IS INITIAL.
      RETURN.
    ENDIF.
    IF result(1) CA cv_digits.
      result = `C_` && result.
    ENDIF.
    IF strlen( result ) > 30.
      result = result(30).
    ENDIF.

  ENDMETHOD.

  METHOD digits_only.

    DATA lv_pos TYPE i.

    DATA lv_len TYPE i.
      DATA lv_char TYPE string.
    lv_len = strlen( val ).
    WHILE lv_pos < lv_len.

      lv_char = substring( val = val
                                 off = lv_pos
                                 len = 1 ).
      IF lv_char CA cv_digits.
        result = result && lv_char.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.

  ENDMETHOD.

  METHOD two_digits.

    result = |{ val }|.
    IF strlen( result ) < 2.
      result = `0` && result.
    ENDIF.

  ENDMETHOD.

  METHOD attr.

    DATA temp181 LIKE LINE OF t_attribute.
    DATA lr_attr LIKE REF TO temp181.
    LOOP AT t_attribute REFERENCE INTO lr_attr.
      IF lr_attr->name = name.
        result = lr_attr->value.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD path_folder.

    DATA lv_pos TYPE i.
    lv_pos = find( val = val
                         sub = `/`
                         occ = -1 ).
    IF lv_pos >= 0.
      result = substring( val = val
                          len = lv_pos + 1 ).
    ENDIF.

  ENDMETHOD.

  METHOD path_resolve.

    DATA lt_done TYPE string_table.

    " from the root of the package when it starts with a slash, from the
    " folder of the part that names it else
    DATA lv_path LIKE target.
    TYPES temp6 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA lt_step TYPE temp6.
    DATA lv_step LIKE LINE OF lt_step.
    lv_path = target.
    IF lv_path IS NOT INITIAL AND lv_path(1) = `/`.
      lv_path = substring( val = lv_path
                           off = 1 ).
    ELSE.
      lv_path = path_folder( base ) && lv_path.
    ENDIF.



    SPLIT lv_path AT `/` INTO TABLE lt_step.

    LOOP AT lt_step INTO lv_step.
      IF lv_step = `..`.
        IF lt_done IS NOT INITIAL.
          DELETE lt_done INDEX lines( lt_done ).
        ENDIF.
      ELSEIF lv_step <> `.` AND lv_step IS NOT INITIAL.
        INSERT lv_step INTO TABLE lt_done.
      ENDIF.
    ENDLOOP.
    result = concat_lines_of( table = lt_done
                              sep   = `/` ).

  ENDMETHOD.

  METHOD text_decode.

    DATA lv_off TYPE i.
    DATA lv_len TYPE i.
      DATA lv_pos TYPE i.
      DATA lv_code TYPE string.

    result = val.
    IF result NS `_x`.
      RETURN.
    ENDIF.

    CLEAR result.

    lv_len = strlen( val ).
    DO.

      lv_pos = find( val = val
                           sub = `_x`
                           off = lv_off ).
      IF lv_pos < 0 OR lv_pos + 7 > lv_len.
        EXIT.
      ENDIF.

      lv_code = to_upper( substring( val = val
                                           off = lv_pos + 2
                                           len = 4 ) ).
      IF lv_code CO cv_hex AND substring( val = val
                                          off = lv_pos + 6
                                          len = 1 ) = `_`.
        result = result && substring( val = val
                                      off = lv_off
                                      len = lv_pos - lv_off ) && char_by_code( hex_to_int( lv_code ) ).
        lv_off = lv_pos + 7.
      ELSE.
        result = result && substring( val = val
                                      off = lv_off
                                      len = lv_pos + 2 - lv_off ).
        lv_off = lv_pos + 2.
      ENDIF.
    ENDDO.
    result = result && substring( val = val
                                  off = lv_off ).

  ENDMETHOD.

  METHOD hex_to_int.

    DATA lv_pos TYPE i.

    " digits only is a decimal number as well: an id of styles.xml
    DATA lv_text TYPE string.
    DATA lv_len TYPE i.
    DATA lv_base TYPE i.
      DATA lv_digit TYPE i.
    lv_text = to_upper( val ).

    lv_len = strlen( lv_text ).

    lv_base = 16.
    IF lv_text CO cv_digits AND lv_len <> 4.
      lv_base = 10.
    ENDIF.
    WHILE lv_pos < lv_len.

      lv_digit = find( val = cv_hex
                             sub = substring( val = lv_text
                                              off = lv_pos
                                              len = 1 ) ).
      IF lv_digit < 0.
        result = 0.
        RETURN.
      ENDIF.
      result = result * lv_base + lv_digit.
      lv_pos = lv_pos + 1.
    ENDWHILE.

  ENDMETHOD.

  METHOD byte_to_hex.

    result = substring( val = cv_hex
                        off = val DIV 16
                        len = 1 ) && substring( val = cv_hex
                                                off = val MOD 16
                                                len = 1 ).

  ENDMETHOD.

  METHOD char_by_code.

    DATA lv_hex TYPE string.
            DATA temp182 TYPE xstring.

    CASE val.
      WHEN 9.
        result = z2ui5_cl_tcl_context=>cv_char_util_horizontal_tab.
      WHEN 10.
        result = z2ui5_cl_tcl_context=>cv_char_util_newline.
      WHEN 13.
        result = z2ui5_cl_tcl_context=>cv_char_util_cr_lf(1).
      WHEN OTHERS.
        IF val < 32.
          " a control character no text has a use for
          RETURN.
        ENDIF.
        " the character as its UTF-8 bytes, which the context turns into
        " a string on every release
        IF val < 128.
          lv_hex = byte_to_hex( val ).
        ELSEIF val < 2048.
          lv_hex = byte_to_hex( 192 + val DIV 64 ) && byte_to_hex( 128 + val MOD 64 ).
        ELSE.
          lv_hex = byte_to_hex( 224 + val DIV 4096 ) && byte_to_hex( 128 + val DIV 64 MOD 64 )
                && byte_to_hex( 128 + val MOD 64 ).
        ENDIF.
        TRY.

            temp182 = lv_hex.
            result = z2ui5_cl_tcl_context=>conv_get_string_by_xstring( temp182 ).
          CATCH cx_root ##NO_HANDLER.
            " no converter - the text without that character
        ENDTRY.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
