CLASS z2ui5_cl_tcl_app_03 DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES z2ui5_if_app.

    DATA mt_tab TYPE REF TO data.

    " deprecated: nothing calls it, and the popup it opens ignores itab - it
    " shows the same table form as the app, in a dialog. Start the app with
    " NEW z2ui5_cl_tcl_app_03( ) instead. Kept for compatibility, to be
    " removed together with ms_app-itab and ms_app-check_popup.
    CLASS-METHODS factory_popup_by_itab
      IMPORTING
        itab            TYPE data
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_tcl_app_03.

    DATA:
      BEGIN OF ms_app,
        check_initialized     TYPE abap_bool,
        " deprecated, see factory_popup_by_itab
        check_popup           TYPE abap_bool,
        " deprecated, see factory_popup_by_itab
        itab                  TYPE REF TO data,
        " deprecated: no longer filled - the file is kept in mv_file until it
        " is downloaded. To be removed together with ms_app-itab.
        file                  TYPE string,
        check_appwidthlimited TYPE abap_bool VALUE abap_true,
        db_table              TYPE string VALUE 'SPFLI',
        db_table_entries      TYPE string,
        " the most rows DB -> JSON reads; 0 or less stands for the default
        max_rows              TYPE i VALUE 1000,
      END OF ms_app.

  PROTECTED SECTION.

    DATA client TYPE REF TO z2ui5_if_client.
    " the JSON of step (2) - not bound, and cleared once it is handed to the
    " download, so it does not travel in every later draft
    DATA mv_file TYPE string.

    METHODS z2ui5_on_init.
    METHODS z2ui5_on_event.
    METHODS z2ui5_view_display.

  PRIVATE SECTION.
    " the rows DB -> JSON reads when the input asks for none
    CONSTANTS mc_default_rows TYPE i VALUE 1000.
ENDCLASS.



CLASS z2ui5_cl_tcl_app_03 IMPLEMENTATION.

  METHOD factory_popup_by_itab.

    CREATE OBJECT result.
    result->ms_app-itab = z2ui5_cl_tcl_context=>conv_copy_ref_data( itab ).
    result->ms_app-check_popup = abap_true.

  ENDMETHOD.


  METHOD z2ui5_if_app~main.

    me->client     = client.

    IF ms_app-check_initialized = abap_false.
      ms_app-check_initialized = abap_true.
      z2ui5_on_init( ).
      RETURN.
    ENDIF.

    IF client->get( )-check_on_navigated = abap_true.
      z2ui5_view_display( ).
    ENDIF.

    IF client->get( )-event IS NOT INITIAL.
      z2ui5_on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD z2ui5_on_event.
            DATA lv_check_table TYPE string.
        FIELD-SYMBOLS <tab2> TYPE STANDARD TABLE.
            DATA lv_table TYPE string.
            DATA x TYPE REF TO cx_root.
            DATA lv_preview_table TYPE string.
            DATA lv_prev_json TYPE string.
            DATA x_preview TYPE REF TO cx_root.

    CASE client->get( )-event.

      WHEN 'DB_CHECK'.

        TRY.
            ms_app-db_table = to_upper( ms_app-db_table ).
            " the name is bound - only a plain DDIC table name reaches the FROM

            lv_check_table = z2ui5_cl_tcl_context=>db_get_table_name( ms_app-db_table ).
            IF lv_check_table IS INITIAL.
              client->message_box_display( |DB Table not found, check input: { ms_app-db_table }| ).
              RETURN.
            ENDIF.

            SELECT SINGLE COUNT( * )
            FROM (lv_check_table)
            INTO ms_app-db_table_entries.

          CATCH cx_root.
            client->message_box_display( |DB Table not found, check input: { ms_app-db_table }| ).
        ENDTRY.

      WHEN `PROCESS`.



        " a table name that does not exist reaches here too - no table for
        " it, or a SELECT that fails, ends in a message, not in a dump
        TRY.
            CLEAR mv_file.
            " the name is bound - only a plain DDIC table name reaches the FROM

            lv_table = z2ui5_cl_tcl_context=>db_get_table_name( ms_app-db_table ).
            IF lv_table IS INITIAL.
              client->message_box_display( |DB Table not found, check input: { ms_app-db_table }| ).
              RETURN.
            ENDIF.
            mt_tab = z2ui5_cl_tcl_context=>rtti_create_tab_by_name( lv_table ).
            ASSIGN mt_tab->* TO <tab2>.

            " UP TO 0 ROWS reads every row - a limit of 0 or less is no limit
            " the user meant, the default stands in
            IF ms_app-max_rows <= 0.
              ms_app-max_rows = mc_default_rows.
            ENDIF.

            SELECT *
            FROM (lv_table)
            INTO CORRESPONDING FIELDS OF TABLE <tab2>
            UP TO ms_app-max_rows ROWS.

            mv_file = z2ui5_cl_tcl_context=>json_stringify( <tab2> ).
            IF lines( <tab2> ) >= ms_app-max_rows.
              client->message_toast_display( |JSON created - the first { ms_app-max_rows } rows, raise Max Rows for more| ).
            ELSE.
              client->message_toast_display( |JSON created - { lines( <tab2> ) } rows| ).
            ENDIF.


          CATCH cx_root INTO x.
            client->message_box_display( x->get_text( ) ).
        ENDTRY.

      WHEN `PREVIEW`.

        TRY.
            " the name is bound - only a plain DDIC table name reaches the FROM

            lv_preview_table = z2ui5_cl_tcl_context=>db_get_table_name( ms_app-db_table ).
            IF lv_preview_table IS INITIAL.
              client->message_box_display( |DB Table not found, check input: { ms_app-db_table }| ).
              RETURN.
            ENDIF.
            mt_tab = z2ui5_cl_tcl_context=>rtti_create_tab_by_name( lv_preview_table ).
            ASSIGN mt_tab->* TO <tab2>.

            SELECT *
            FROM (lv_preview_table)
            INTO CORRESPONDING FIELDS OF TABLE <tab2>
            UP TO 10 ROWS.


            lv_prev_json = z2ui5_cl_tcl_context=>json_stringify( <tab2> ).
            client->nav_app_call( z2ui5_cl_popup_textedit=>factory( lv_prev_json ) ).


          CATCH cx_root INTO x_preview.
            client->message_box_display( x_preview->get_text( ) ).
        ENDTRY.

      WHEN 'DOWNLOAD'.
        IF mv_file IS INITIAL.
          client->message_toast_display( `Create the JSON first - step (2)` ).
          RETURN.
        ENDIF.
        client->nav_app_call( z2ui5_cl_popup_file_dl=>factory( mv_file ) ).
        " handed to the download popup - the app keeps no copy
        CLEAR mv_file.

      WHEN 'BACK'.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD z2ui5_on_init.

    z2ui5_view_display( ).

  ENDMETHOD.


  METHOD z2ui5_view_display.
      DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp1 TYPE xsdboolean.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.

    IF ms_app-check_popup = abap_true.

      view = z2ui5_cl_ui5_view_builder=>factory(
                       )->ele( n = `FragmentDefinition` ns = `core`
                       )->a( n = `xmlns` v = `sap.m`
                       )->a( n = `xmlns:core` v = `sap.ui.core`
                       )->a( n = `xmlns:form` v = `sap.ui.layout.form` ).

      page = view->ele( `Dialog` ).
    ELSE.
      view = z2ui5_cl_ui5_view_builder=>factory(
                 )->ele( n = `View` ns = `mvc`
                 )->a( n = `xmlns` v = `sap.m`
                 )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
                 )->a( n = `xmlns:form` v = `sap.ui.layout.form`
                 )->a( n = `displayBlock` v = `true`
                 )->a( n = `height` v = `100%` ).

      temp1 = boolc( client->get( )-s_draft-id_prev_app_stack IS NOT INITIAL ).
      page = view->ele( `Shell`
                 )->a( n = `appWidthLimited` v = client->_bind( ms_app-check_appwidthlimited )
                 )->ele( `Page`
                 )->a( n = `title` v = 'abap2UI5 - JSON File Download'
                 )->a( n = `navButtonPress` v = client->_event( 'BACK' )
                 )->a( n = `showNavButton` b = temp1
                 )->ele( `headerContent`
                 )->ele( `OverflowToolbar`
                 )->tag( `ToolbarSpacer`
                 )->tag( `Label`
                 )->a( n = `text` v = `Shell`
                 )->tag( `Switch`
                 )->a( n = `state` v = client->_bind( ms_app-check_appwidthlimited )
                 )->end(
                 )->end( ).
    ENDIF.


    content = page->ele( n = `SimpleForm` ns = `form`
                        )->a( n = `editable` v = `true` ).

    content->tag( `Label`
        )->a( n = `text` v = `(1) Set DB Table`
        )->tag( `Input`
        )->a( n = `width` v = `30%`
        )->a( n = `description` v = `DB Table`
        )->a( n = `value` v = client->_bind( ms_app-db_table )
        )->tag( `Label`
        )->tag( `Button`
        )->a( n = `text` v = `Go`
        )->a( n = `width` v = `10%`
        )->a( n = `press` v = client->_event( `DB_CHECK` )
        )->tag( `Label`
        )->tag( `Input`
        )->a( n = `width` v = `30%`
        )->a( n = `description` v = `DB Entries`
        )->a( n = `value` v = client->_bind( ms_app-db_table_entries )
        )->a( n = `enabled` b = abap_false
        )->tag( `Label`
        )->a( n = `text` v = `(2) DB -> JSON`
        )->tag( `Input`
        )->a( n = `width` v = `30%`
        )->a( n = `description` v = `Max Rows`
        )->a( n = `type` v = `Number`
        )->a( n = `value` v = client->_bind( ms_app-max_rows )
        )->tag( `Label`
        )->tag( `Button`
        )->a( n = `text` v = `Go`
        )->a( n = `width` v = `10%`
        )->a( n = `press` v = client->_event( `PROCESS` )
        )->tag( `Label`
        )->a( n = `text` v = `(3) Preview JSON`
        )->tag( `Button`
        )->a( n = `text` v = `Go`
        )->a( n = `width` v = `10%`
        )->a( n = `press` v = client->_event( `PREVIEW` )
        )->tag( `Label`
        )->a( n = `text` v = `(4) Export`
        )->tag( `Button`
        )->a( n = `text` v = `Run`
        )->a( n = `width` v = `10%`
        )->a( n = `press` v = client->_event( `DOWNLOAD` ) ).

    IF ms_app-check_popup = abap_true.
      client->popup_display( view->stringify( ) ).
    ELSE.
      client->view_display( view->stringify( ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
