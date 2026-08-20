CLASS z2ui5_cl_tcl_app_01 DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES z2ui5_if_app.

    DATA:
      BEGIN OF ms_app,
        check_initialized     TYPE abap_bool,
        file                  TYPE string,
        file_size             TYPE string,
        file_entries          TYPE string,
        check_appwidthlimited TYPE abap_bool VALUE abap_true,
        db_table              TYPE string VALUE 'z2ui5_dbl_t_01',
        db_table_entries      TYPE string,
      END OF ms_app.

    DATA mt_tab TYPE REF TO data.

  PROTECTED SECTION.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS z2ui5_on_init.
    METHODS z2ui5_on_event.
    METHODS z2ui5_view_display.

  PRIVATE SECTION.
ENDCLASS.



CLASS Z2UI5_CL_TCL_APP_01 IMPLEMENTATION.


  METHOD z2ui5_if_app~main.

    me->client     = client.

    IF ms_app-check_initialized = abap_false.
      ms_app-check_initialized = abap_true.
      z2ui5_on_init( ).
      RETURN.
    ENDIF.

    IF client->get( )-check_on_navigated = abap_true.
      TRY.
          DATA(lo_popup_file) = CAST z2ui5_cl_popup_file_ul( client->get_app( client->get( )-s_draft-id_prev_app ) ).
          IF lo_popup_file->result( )-check_confirmed = abap_true.
            ms_app-file = lo_popup_file->result( )-value.
            client->message_toast_display( `File uploaded successfully` ).
            ms_app-file_size = CONV i( ( strlen( ms_app-file ) ) / 1000 ).
            client->view_model_update( ).
          ENDIF.
          RETURN.
        CATCH cx_root.
      ENDTRY.
      TRY.
          DATA(lo_popup_confirm) = CAST z2ui5_cl_popup_to_confirm( client->get_app( client->get( )-s_draft-id_prev_app ) ).
          IF lo_popup_confirm->result( ) = abap_true.

            FIELD-SYMBOLS <tab2> TYPE STANDARD TABLE.
            ASSIGN mt_tab->* TO <tab2>.
            MODIFY (ms_app-db_table) FROM TABLE <tab2>.
            COMMIT WORK AND WAIT.
            client->message_box_display( `DB updated` ).
          ENDIF.
          RETURN.
        CATCH cx_root.
      ENDTRY.
    ENDIF.

    IF client->get( )-event IS NOT INITIAL.
      z2ui5_on_event( ).
    ENDIF.


  ENDMETHOD.


  METHOD z2ui5_on_event.

    CASE client->get( )-event.

      WHEN `DB_CHECK`.

        TRY.
            ms_app-db_table = to_upper( ms_app-db_table ).

            SELECT SINGLE COUNT( * )
            FROM (ms_app-db_table)
            INTO ms_app-db_table_entries.

            IF to_upper( ms_app-db_table(1) ) <> `Z` AND to_upper( ms_app-db_table(1) ) <> `Y`.
              client->message_box_display( `Only Tables in namespace Z or Y allowed` ).
            ENDIF.

            client->view_model_update( ).
          CATCH cx_root.
            client->message_box_display( |DB Table not found, check input: { ms_app-db_table }| ).
        ENDTRY.

      WHEN `PROCESS`.
        TRY.
            FIELD-SYMBOLS <tab2> TYPE STANDARD TABLE.

            CREATE DATA mt_tab TYPE STANDARD TABLE OF (ms_app-db_table).
            ASSIGN mt_tab->* TO <tab2>.

            z2ui5_cl_tcl_context=>json_parse(
              EXPORTING
                val  = ms_app-file
              CHANGING
                data = <tab2>
            ).

            ms_app-file_entries = lines( <tab2> ).
            client->view_model_update( ).

          CATCH cx_root INTO DATA(x).
            client->message_box_display( x->get_text( ) ).
        ENDTRY.

      WHEN `PREVIEW`.

        DATA lr_tab TYPE REF TO data.

        lr_tab = z2ui5_cl_tcl_context=>conv_copy_ref_data( mt_tab ).

        ASSIGN lr_tab->* TO <tab2>.
        DELETE <tab2> FROM 6.

        client->nav_app_call( z2ui5_cl_popup_table=>factory( <tab2> ) ).

      WHEN `DB_SAVE`.
        client->nav_app_call( z2ui5_cl_popup_to_confirm=>factory( `Database will be deleted and new entries filled. Are you sure?` ) ).

      WHEN `UPLOAD`.
        client->nav_app_call( z2ui5_cl_popup_file_ul=>factory( ) ).

      WHEN `BUTTON_CANCEL`.
        client->message_toast_display( `Cancelled` ).

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD z2ui5_on_init.

    z2ui5_view_display( ).

  ENDMETHOD.


  METHOD z2ui5_view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( 
                     )->ele( n = `View` ns = `mvc` 
                     )->a( n = `xmlns` v = `sap.m` 
                     )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` 
                     )->a( n = `xmlns:core` v = `sap.ui.core` 
                     )->a( n = `xmlns:form` v = `sap.ui.layout.form` 
                     )->a( n = `displayBlock` v = `true` 
                     )->a( n = `height` v = `100%` ).

    DATA(page) = view->ele( `Shell` 
                     )->a( n = `appWidthLimited` v = client->_bind_edit( ms_app-check_appwidthlimited ) 
                     )->ele( `Page` 
                     )->a( n = `title` v = 'abap2UI5 - JSON File Upload' 
                     )->a( n = `navButtonPress` v = client->_event( `BACK` ) 
                     )->a( n = `showNavButton` b = xsdbool( client->get( )-s_draft-id_prev_app_stack IS NOT INITIAL ) 
                     )->ele( `headerContent` 
                     )->ele( `OverflowToolbar` 
                     )->tag( `ToolbarSpacer` 
                     )->tag( `Label` 
                     )->a( n = `text` v = `Shell` 
                     )->tag( `Switch` 
                     )->a( n = `state` v = client->_bind_edit( ms_app-check_appwidthlimited ) 
                     )->tag( `Link` 
                     )->a( n = `text` v = 'Project on GitHub' 
                     )->a( n = `target` v = '_blank' 
                     )->a( n = `href` v = `https://github.com/abap2UI5-addons/table-content-loader` 
                     )->end( 
                     )->end( ).

    DATA(content) = page->ele( n = `SimpleForm` ns = `form` 
                        )->a( n = `editable` v = `true` ).

    content->tag( `Label` 
        )->a( n = `text` v = `(1) JSON File Upload` 
        )->tag( `Button` 
        )->a( n = `text` v = `Go` 
        )->a( n = `width` v = `10%` 
        )->a( n = `press` v = client->_event( `UPLOAD` ) 
        )->tag( `Label` 
        )->tag( `Input` 
        )->a( n = `width` v = `30%` 
        )->a( n = `description` v = `Size (kB)` 
        )->a( n = `value` v = client->_bind( ms_app-file_size ) 
        )->a( n = `enabled` b = abap_false 
        )->tag( `Label` 
        )->a( n = `text` v = `(2) Check DB Table` 
        )->tag( `Input` 
        )->a( n = `width` v = `30%` 
        )->a( n = `description` v = `DB Table` 
        )->a( n = `value` v = client->_bind_edit( ms_app-db_table ) 
        )->tag( `Label` 
        )->tag( `Button` 
        )->a( n = `text` v = `Go` 
        )->a( n = `width` v = `10%` 
        )->a( n = `press` v = client->_event( `DB_CHECK` ) 
        )->tag( `Label` 
        )->tag( `Input` 
        )->a( n = `width` v = `30%` 
        )->a( n = `description` v = `DB Entries` 
        )->a( n = `value` v = client->_bind_edit( ms_app-db_table_entries ) 
        )->a( n = `enabled` b = abap_false 
        )->tag( `Label` 
        )->a( n = `text` v = `(3) JSON -> ITAB` 
        )->tag( `Button` 
        )->a( n = `text` v = `Go` 
        )->a( n = `width` v = `10%` 
        )->a( n = `press` v = client->_event( `PROCESS` ) 
        )->tag( `Label` 
        )->tag( `Input` 
        )->a( n = `width` v = `30%` 
        )->a( n = `description` v = `Number of Entries` 
        )->a( n = `value` v = client->_bind_edit( ms_app-file_entries ) 
        )->a( n = `enabled` b = abap_false 
        )->tag( `Label` 
        )->a( n = `text` v = `(4) Preview Rows` 
        )->tag( `Button` 
        )->a( n = `text` v = `Go` 
        )->a( n = `width` v = `10%` 
        )->a( n = `press` v = client->_event( `PREVIEW` ) 
        )->tag( `Label` 
        )->a( n = `text` v = `(5) Save Database` 
        )->tag( `Text` 
        )->a( n = `text` v = `Attention - Database Content will be deleted!` 
        )->tag( `Label` 
        )->tag( `Button` 
        )->a( n = `text` v = `Run` 
        )->a( n = `width` v = `10%` 
        )->a( n = `press` v = client->_event( `DB_SAVE` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.
ENDCLASS.
