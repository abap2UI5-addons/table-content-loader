CLASS z2ui5_cl_tcl_app_04 DEFINITION PUBLIC.

  PUBLIC SECTION.

    INTERFACES z2ui5_if_app.

    DATA mv_path TYPE string.
    DATA mv_value TYPE string.
    DATA mr_table TYPE REF TO data.
    DATA mv_check_edit TYPE abap_bool.

  PROTECTED SECTION.

    TYPES:
      BEGIN OF ty_s_format,
        " the format in the texts of the view - CSV, XLSX
        name     TYPE string,
        " the title of the page
        title    TYPE string,
        " the media type of the download's data: URI
        mime     TYPE string,
        " the name the browser saves the download under
        filename TYPE string,
      END OF ty_s_format.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS ui5_on_event.

    METHODS ui5_view_main_display.

    "! The file format this app reads and writes: CSV here - the XLSX app
    "! z2ui5_cl_tcl_app_05 is this app with the format redefined
    METHODS get_format
      RETURNING
        VALUE(result) TYPE ty_s_format.

    "! The rows of an uploaded file
    METHODS get_table_by_file
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! The file of the rows, for the download
    METHODS get_file_by_table
      IMPORTING
        val           TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE xstring.

  PRIVATE SECTION.
ENDCLASS.



CLASS z2ui5_cl_tcl_app_04 IMPLEMENTATION.


  METHOD get_format.

    result = VALUE #( name     = `CSV`
                      title    = `abap2UI5 - CSV to ABAP Internal Table`
                      mime     = `text/csv`
                      filename = `table.csv` ).

  ENDMETHOD.


  METHOD get_table_by_file.

    " UTF-8, or Windows-1252 where the bytes are no valid UTF-8
    DATA(lv_text) = z2ui5_cl_tcl_context=>conv_get_string_by_file( val ).
    result = z2ui5_cl_tcl_context=>itab_get_itab_by_csv( lv_text ).

  ENDMETHOD.


  METHOD get_file_by_table.

    DATA(lv_csv) = z2ui5_cl_tcl_context=>itab_get_csv_by_itab( val ).
    result = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( lv_csv ).

  ENDMETHOD.


  METHOD ui5_on_event.
    TRY.

        CASE client->get( )-event.

          WHEN 'CHANGE'.
            ui5_view_main_display( ).

          WHEN 'DOWNLOAD'.
            " nothing uploaded yet - there is no table to build the file from
            IF mr_table IS INITIAL.
              client->message_toast_display( |Upload a { get_format( )-name } file first| ).
              RETURN.
            ENDIF.
            " the browser saves the file - the frontend action the core has
            " for it; the iframe with a data: URI this used to write was a
            " trick of the frozen view builder and downloaded nothing any more
            FIELD-SYMBOLS <tab> TYPE table.
            ASSIGN mr_table->* TO <tab>.
            DATA(ls_format) = get_format( ).
            DATA(lv_base) = z2ui5_cl_tcl_context=>conv_encode_x_base64( get_file_by_table( <tab> ) ).
            client->follow_up_action( val   = client->cs_event-download_b64_file
                                      t_arg = VALUE #( ( |data:{ ls_format-mime };base64,{ lv_base }| )
                                                       ( ls_format-filename ) ) ).

          WHEN 'UPLOAD'.

            DATA(lv_data) = z2ui5_cl_tcl_context=>conv_get_xstring_by_data_uri( mv_value ).
            mr_table = get_table_by_file( lv_data ).
            client->message_box_display( |{ get_format( )-name } loaded to table| ).

            ui5_view_main_display( ).

            CLEAR mv_value.
            CLEAR mv_path.

          WHEN 'BACK'.
            client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

        ENDCASE.

      CATCH cx_root INTO DATA(x).
        client->message_box_display( text = x->get_text( ) type = `error` ).
    ENDTRY.

  ENDMETHOD.


  METHOD ui5_view_main_display.

    DATA(ls_format) = get_format( ).

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
                     )->ele( n = `View` ns = `mvc`
                     )->a( n = `xmlns` v = `sap.m`
                     )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
                     )->a( n = `xmlns:z2ui5` v = `z2ui5.cc`
                     )->a( n = `displayBlock` v = `true`
                     )->a( n = `height` v = `100%` ).
    DATA(page) = view->ele( `Shell`
                     )->ele( `Page`
                     )->a( n = `title` t = ls_format-title
                     )->a( n = `navButtonPress` v = client->_event( 'BACK' )
                     )->a( n = `showNavButton` b = abap_true ).

    IF mr_table IS NOT INITIAL.
      FIELD-SYMBOLS <tab> TYPE table.
      ASSIGN mr_table->* TO <tab>.

      DATA(tab) = page->ele( `Table`
                      )->a( n = `items` v = client->_bind( <tab> )
                      )->ele( `headerToolbar`
                      )->ele( `OverflowToolbar`
                      )->tag( `Title`
                      )->a( n = `text` t = |{ ls_format-name } Content|
                      )->tag( `ToolbarSpacer`
                      )->tag( `Switch`
                      )->a( n = `change` v = client->_event( `CHANGE` )
                      )->a( n = `state` v = client->_bind( mv_check_edit )
                      )->a( n = `customTextOn` v = 'Edit'
                      )->a( n = `customTextOff` v = 'View'
                      )->end(
                      )->end( ).

      " the column names come from the file: a text, never a binding
      DATA(lt_fields) = z2ui5_cl_tcl_context=>rtti_get_t_attri_by_any( <tab> ).
      DATA(lo_cols) = tab->ele( `columns` ).
      LOOP AT lt_fields REFERENCE INTO DATA(lr_col).
        lo_cols->ele( `Column`
            )->tag( `Text`
            )->a( n = `text` t = lr_col->name ).
      ENDLOOP.
      DATA(lo_cells) = tab->ele( `items`
                           )->ele( `ColumnListItem`
                           )->ele( `cells` ).
      LOOP AT lt_fields REFERENCE INTO lr_col.
        IF mv_check_edit = abap_true.
          lo_cells->tag( `Input`
              )->a( n = `value` v = `{` && lr_col->name && `}` ).
        ELSE.
          lo_cells->tag( `Text`
              )->a( n = `text` v = `{` && lr_col->name && `}` ).
        ENDIF.
      ENDLOOP.
    ENDIF.

    DATA(footer) = page->ele( `footer`
                       )->ele( `OverflowToolbar` ).

    footer->tag( n = `FileUploader` ns = `z2ui5`
        )->a( n = `value` v = client->_bind( mv_value )
        )->a( n = `path` v = client->_bind( mv_path )
        )->a( n = `placeholder` v = `File path here...`
        )->a( n = `upload` v = client->_event( 'UPLOAD' ) ).

    footer->tag( `ToolbarSpacer`
        )->tag( `Button`
        )->a( n = `text` t = |Download { ls_format-name }|
        )->a( n = `press` v = client->_event( 'DOWNLOAD' )
        )->a( n = `type` v = 'Emphasized'
        )->a( n = `icon` v = 'sap-icon://download' ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      ui5_view_main_display( ).
      RETURN.
    ENDIF.

    IF client->get( )-check_on_navigated = abap_true.
      ui5_view_main_display( ).
    ENDIF.

    ui5_on_event( ).

  ENDMETHOD.
ENDCLASS.
