CLASS z2ui5_cl_tcl_app_02 DEFINITION PUBLIC.

  PUBLIC SECTION.

    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_spfli,
        selkz     TYPE abap_bool,
        carrid    TYPE c LENGTH 3,
        connid    TYPE n LENGTH 4,
        countryfr TYPE c LENGTH 3,
        cityfrom  TYPE c LENGTH 20,
        airpfrom  TYPE c LENGTH 3,
        countryto TYPE c LENGTH 3,
        cityto    TYPE c LENGTH 20,
        airpto    TYPE c LENGTH 3,
      END OF ty_s_spfli.

    TYPES ty_t_table TYPE STANDARD TABLE OF ty_s_spfli WITH EMPTY KEY.

    DATA mv_view TYPE string.

    DATA:
      BEGIN OF ms_import,
        t_table     TYPE ty_t_table,
        segment_key TYPE string,
        editor      TYPE string,
      END OF ms_import.

    DATA:
      BEGIN OF ms_export,
        t_table     TYPE ty_t_table,
        segment_key TYPE string,
        editor      TYPE string,
      END OF ms_export.

    DATA:
      BEGIN OF ms_edit,
        t_table      TYPE ty_t_table,
        check_active TYPE abap_bool,
      END OF ms_edit.

    DATA check_initialized TYPE abap_bool.
    "dummy helper - not needed when using db
    DATA st_db TYPE ty_t_table.

  PROTECTED SECTION.

    METHODS z2ui5_on_event
      IMPORTING
        client TYPE REF TO z2ui5_if_client.

    METHODS z2ui5_on_render_view_import
      IMPORTING
        client TYPE REF TO z2ui5_if_client.

    METHODS z2ui5_on_render_view_edit
      IMPORTING
        client TYPE REF TO z2ui5_if_client.

    METHODS z2ui5_on_render_view_export
      IMPORTING
        client TYPE REF TO z2ui5_if_client.

  PRIVATE SECTION.

ENDCLASS.



CLASS Z2UI5_CL_TCL_APP_02 IMPLEMENTATION.


  METHOD z2ui5_if_app~main.
    "dummy helper - not needed when using db
    lcl_db=>app = me.


    IF check_initialized = abap_false.
      check_initialized = abap_true.

      ms_import-segment_key = 'json'.
      ms_import-editor = lcl_db=>get_test_data_json( ).
      ms_export-segment_key = 'json'.
      mv_view = 'IMPORT_TABLE'.

    ENDIF.

    z2ui5_on_event( client ).

    CASE mv_view.
      WHEN 'IMPORT_TABLE'.
        z2ui5_on_render_view_import( client ).
      WHEN 'EDIT_TABLE'.
        z2ui5_on_render_view_edit( client ).
      WHEN 'EXPORT_TABLE'.
        z2ui5_on_render_view_export( client ).
    ENDCASE.

  ENDMETHOD.


  METHOD z2ui5_on_event.

    CASE client->get( )-event.

      WHEN 'IMPORT_DB'.
        ms_import-t_table = SWITCH #( ms_import-segment_key
          WHEN 'json' THEN lcl_db=>get_table_by_json( ms_import-editor )
          WHEN 'csv'  THEN lcl_db=>get_table_by_csv( ms_import-editor )
          WHEN 'xml'  THEN lcl_db=>get_table_by_xml( ms_import-editor ) ).

        lcl_db=>db_save( ms_import-t_table ).
        client->message_box_display( 'Table data imported successfully' ).

      WHEN 'EXPORT_DB'.
        ms_export-t_table = lcl_db=>db_read( ).
        ms_export-editor = SWITCH #( ms_export-segment_key
          WHEN 'json' THEN lcl_db=>get_json_by_table( ms_export-t_table )
          WHEN 'csv'  THEN lcl_db=>get_csv_by_table( ms_export-t_table )
          WHEN 'xml'  THEN lcl_db=>get_xml_by_table( ms_export-t_table ) ).

        client->message_box_display( 'Table data exported successfully' ).

      WHEN 'IMPORT_CLEAR'.
        CLEAR ms_import-editor.

      WHEN 'EDIT_DB_READ'.
        ms_edit-t_table = lcl_db=>db_read( ).
        client->message_box_display( 'Table read successfully' ).

      WHEN 'EDIT_DB_SAVE'.
        lcl_db=>db_save( ms_edit-t_table ).
        client->message_box_display( 'Table data saved to database successfully' ).

      WHEN 'EDIT_ROW_DELETE'.
        DELETE ms_edit-t_table WHERE selkz = abap_true.

      WHEN 'EDIT_CHANGE_MODE'.
        ms_edit-check_active = xsdbool( ms_edit-check_active = abap_false ).

      WHEN 'EDIT_ROW_ADD'.
        INSERT VALUE #( ) INTO TABLE ms_edit-t_table.

      WHEN 'BTN_IMPORT'.
        mv_view = 'IMPORT_TABLE'.
      WHEN 'BTN_EDIT'.
        mv_view = 'EDIT_TABLE'.
      WHEN 'BTN_EXPORT'.
        mv_view = 'EXPORT_TABLE'.
      WHEN 'BACK'.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD z2ui5_on_render_view_edit.

    DATA(page) = z2ui5_cl_ui5_view_builder=>factory( 
                     )->ele( n = `View` ns = `mvc` 
                     )->a( n = `xmlns` v = `sap.m` 
                     )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` 
                     )->a( n = `xmlns:core` v = `sap.ui.core` 
                     )->a( n = `xmlns:editor` v = `sap.ui.codeeditor` 
                     )->a( n = `xmlns:form` v = `sap.ui.layout.form` 
                     )->a( n = `xmlns:layout` v = `sap.ui.layout` 
                     )->a( n = `displayBlock` v = `true` 
                     )->a( n = `height` v = `100%` 
                     )->ele( `Shell` 
                     )->ele( `Page` 
                     )->a( n = `title` v = 'abap2UI5 - Table Maintenance' 
                     )->a( n = `navButtonPress` v = client->_event( 'BACK' ) 
                     )->a( n = `showNavButton` b = abap_true 
                     )->ele( `headerContent` 
                     )->tag( `Link` 
                     )->a( n = `text` v = 'Demo' 
                     )->a( n = `target` v = '_blank' 
                     )->a( n = `href` v = `https://twitter.com/abap2UI5/status/1634206964291911682` 
                     )->end( 
                     )->ele( `subHeader` 
                     )->ele( `OverflowToolbar` 
                     )->tag( `Button` 
                     )->a( n = `text` v = '(1) Import Data' 
                     )->a( n = `press` v = client->_event( 'BTN_IMPORT' ) 
                     )->tag( `Button` 
                     )->a( n = `text` v = '(2) Edit Data' 
                     )->a( n = `press` v = client->_event( 'BTN_EDIT' ) 
                     )->a( n = `enabled` b = abap_false 
                     )->tag( `Button` 
                     )->a( n = `text` v = '(3) Export Data' 
                     )->a( n = `press` v = client->_event( 'BTN_EXPORT' ) 
                     )->end( 
                     )->end( ).

    DATA(grid) = page->ele( n = `Grid` ns = `layout` 
                     )->a( n = `defaultSpan` v = 'L7 M7 S7' 
                     )->ele( n = `content` ns = `layout` ).

    grid->ele( n = `SimpleForm` ns = `form` 
        )->a( n = `title` v = '2. Edit Data' 
        )->ele( n = `content` ns = `form` 
        )->tag( `Label` 
        )->a( n = `text` v = 'Table' 
        )->tag( `Input` 
        )->a( n = `value` v = 'SPFLI' ).

    grid = page->ele( n = `Grid` ns = `layout` 
               )->a( n = `defaultSpan` v = 'L12 M12 S12' 
               )->ele( n = `content` ns = `layout` ).

    DATA(cont) = grid->ele( n = `SimpleForm` ns = `form` 
                     )->ele( n = `content` ns = `form` ).

    cont->ele( `OverflowToolbar` 
        )->tag( `Button` 
        )->a( n = `text` v = 'Reload' 
        )->a( n = `icon` v = 'sap-icon://refresh' 
        )->a( n = `press` v = client->_event( 'EDIT_DB_READ' ) 
        )->tag( `ToolbarSpacer` 
        )->tag( `Button` 
        )->a( n = `text` v = 'Delete Row' 
        )->a( n = `icon` v = 'sap-icon://delete' 
        )->a( n = `press` v = client->_event( 'EDIT_ROW_DELETE' ) 
        )->tag( `Button` 
        )->a( n = `text` v = 'Add Row' 
        )->a( n = `icon` v = 'sap-icon://add' 
        )->a( n = `press` v = client->_event( 'EDIT_ROW_ADD' ) ).

    DATA(scroll) = cont->ele( `ScrollContainer` 
                       )->a( n = `vertical` b = abap_true 
                       )->a( n = `horizontal` b = abap_true ).

    DATA(tab) = scroll->ele( `Table` 
                    )->a( n = `width` v = '100rem' 
                    )->a( n = `items` v = client->_bind_edit( ms_edit-t_table ) 
                    )->a( n = `mode` v = 'MultiSelect' ).

    DATA(lt_fields) = lcl_db=>get_fieldlist_by_table( ms_edit-t_table ).

    DATA(lo_columns) = tab->ele( `columns` ).
    LOOP AT lt_fields INTO DATA(lv_field) FROM 2.
      lo_columns->ele( `Column` 
          )->tag( `Text` 
          )->a( n = `text` v = lv_field ).
    ENDLOOP.

    DATA(lo_cells) = tab->ele( `items` 
                         )->ele( `ColumnListItem` 
                         )->a( n = `selected` v = '{SELKZ}' 
                         )->ele( `cells` ).
    LOOP AT lt_fields INTO lv_field FROM 2.
      lo_cells->tag( `Input` 
          )->a( n = `value` v = `{` && lv_field && `}` ).
    ENDLOOP.

    page->ele( `footer` 
        )->ele( `OverflowToolbar` 
        )->tag( `ToolbarSpacer` 
        )->tag( `Button` 
        )->a( n = `text` v = 'Save' 
        )->a( n = `press` v = client->_event( 'EDIT_DB_SAVE' ) 
        )->a( n = `type` v = 'Emphasized' 
        )->a( n = `icon` v = 'sap-icon://upload-to-cloud' ).

    client->view_display( page->stringify( ) ).

  ENDMETHOD.


  METHOD z2ui5_on_render_view_export.

    DATA(page) = z2ui5_cl_ui5_view_builder=>factory( 
                     )->ele( n = `View` ns = `mvc` 
                     )->a( n = `xmlns` v = `sap.m` 
                     )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` 
                     )->a( n = `xmlns:core` v = `sap.ui.core` 
                     )->a( n = `xmlns:editor` v = `sap.ui.codeeditor` 
                     )->a( n = `xmlns:form` v = `sap.ui.layout.form` 
                     )->a( n = `xmlns:layout` v = `sap.ui.layout` 
                     )->a( n = `displayBlock` v = `true` 
                     )->a( n = `height` v = `100%` 
                     )->ele( `Shell` 
                     )->ele( `Page` 
                     )->a( n = `title` v = 'abap2UI5 - Table Maintenance' 
                     )->a( n = `navButtonPress` v = client->_event( 'BACK' ) 
                     )->a( n = `showNavButton` b = abap_true 
                     )->ele( `headerContent` 
                     )->tag( `Link` 
                     )->a( n = `text` v = 'Demo' 
                     )->a( n = `href` v = `https://twitter.com/abap2UI5/status/1634206964291911682` 
                     )->end( 
                     )->ele( `subHeader` 
                     )->ele( `OverflowToolbar` 
                     )->tag( `Button` 
                     )->a( n = `text` v = '(1) Import Data' 
                     )->a( n = `press` v = client->_event( 'BTN_IMPORT' ) 
                     )->tag( `Button` 
                     )->a( n = `text` v = '(2) Edit Data' 
                     )->a( n = `press` v = client->_event( 'BTN_EDIT' ) 
                     )->tag( `Button` 
                     )->a( n = `text` v = '(3) Export Data' 
                     )->a( n = `press` v = client->_event( 'BTN_EXPORT' ) 
                     )->a( n = `enabled` b = abap_false 
                     )->end( 
                     )->end( ).

    DATA(grid) = page->ele( n = `Grid` ns = `layout` 
                     )->a( n = `defaultSpan` v = 'L7 M7 S7' 
                     )->ele( n = `content` ns = `layout` ).

    grid->ele( n = `SimpleForm` ns = `form` 
        )->a( n = `title` v = '3. Export Data' 
        )->ele( n = `content` ns = `form` 
        )->tag( `Label` 
        )->a( n = `text` v = 'Table' 
        )->tag( `Input` 
        )->a( n = `value` v = 'SPFLI' 
        )->tag( `Label` 
        )->a( n = `text` v = 'Format' 
        )->ele( `SegmentedButton` 
        )->a( n = `selectedKey` v = client->_bind_edit( ms_export-segment_key ) 
        )->ele( `items` 
        )->tag( `SegmentedButtonItem` 
        )->a( n = `key` v = 'json' 
        )->a( n = `text` v = 'json' 
        )->tag( `SegmentedButtonItem` 
        )->a( n = `key` v = 'csv' 
        )->a( n = `text` v = 'csv' 
        )->tag( `SegmentedButtonItem` 
        )->a( n = `key` v = 'xml' 
        )->a( n = `text` v = 'xml' ).

    grid = page->ele( n = `Grid` ns = `layout` 
               )->a( n = `defaultSpan` v = 'L12 M12 S12' 
               )->ele( n = `content` ns = `layout` ).

    page->tag( n = `CodeEditor` ns = `editor` 
        )->a( n = `type` v = COND #( WHEN ms_export-segment_key = 'csv' THEN |plain_text| ELSE ms_export-segment_key ) 
        )->a( n = `value` v = client->_bind( ms_export-editor ) 
        )->a( n = `editable` b = abap_false ).

    page->ele( `footer` 
        )->ele( `OverflowToolbar` 
        )->tag( `ToolbarSpacer` 
        )->tag( `Button` 
        )->a( n = `text` v = 'Export' 
        )->a( n = `press` v = client->_event( 'EXPORT_DB' ) 
        )->a( n = `type` v = 'Emphasized' 
        )->a( n = `icon` v = 'sap-icon://download-from-cloud' ).

    client->view_display( page->stringify( ) ).

  ENDMETHOD.


  METHOD z2ui5_on_render_view_import.

    DATA(page) = z2ui5_cl_ui5_view_builder=>factory( 
                     )->ele( n = `View` ns = `mvc` 
                     )->a( n = `xmlns` v = `sap.m` 
                     )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` 
                     )->a( n = `xmlns:core` v = `sap.ui.core` 
                     )->a( n = `xmlns:editor` v = `sap.ui.codeeditor` 
                     )->a( n = `xmlns:form` v = `sap.ui.layout.form` 
                     )->a( n = `xmlns:layout` v = `sap.ui.layout` 
                     )->a( n = `displayBlock` v = `true` 
                     )->a( n = `height` v = `100%` 
                     )->ele( `Shell` 
                     )->ele( `Page` 
                     )->a( n = `title` v = 'abap2UI5 - Table Maintenance' 
                     )->a( n = `navButtonPress` v = client->_event( 'BACK' ) 
                     )->a( n = `showNavButton` b = abap_true 
                     )->ele( `headerContent` 
                     )->tag( `Link` 
                     )->a( n = `text` v = 'Demo' 
                     )->a( n = `href` v = `https://twitter.com/abap2UI5/status/1634206964291911682` 
                     )->end( 
                     )->ele( `subHeader` 
                     )->ele( `OverflowToolbar` 
                     )->tag( `Button` 
                     )->a( n = `text` v = '(1) Import Data' 
                     )->a( n = `press` v = client->_event( 'BTN_IMPORT' ) 
                     )->a( n = `enabled` b = abap_false 
                     )->tag( `Button` 
                     )->a( n = `text` v = '(2) Edit Data' 
                     )->a( n = `press` v = client->_event( 'BTN_EDIT' ) 
                     )->tag( `Button` 
                     )->a( n = `text` v = '(3) Export Data' 
                     )->a( n = `press` v = client->_event( 'BTN_EXPORT' ) 
                     )->end( 
                     )->end( ).

    DATA(grid) = page->ele( n = `Grid` ns = `layout` 
                     )->a( n = `defaultSpan` v = 'L7 M12 S12' 
                     )->ele( n = `content` ns = `layout` ).

    grid->ele( n = `SimpleForm` ns = `form` 
        )->a( n = `title` v = '1. Import Data' 
        )->ele( n = `content` ns = `form` 
        )->tag( `Label` 
        )->a( n = `text` v = 'Table' 
        )->tag( `Input` 
        )->a( n = `value` v = 'SPFLI' 
        )->tag( `Label` 
        )->a( n = `text` v = 'Format' 
        )->ele( `SegmentedButton` 
        )->a( n = `selectedKey` v = client->_bind_edit( ms_import-segment_key ) 
        )->ele( `items` 
        )->tag( `SegmentedButtonItem` 
        )->a( n = `key` v = 'json' 
        )->a( n = `text` v = 'json' 
        )->tag( `SegmentedButtonItem` 
        )->a( n = `key` v = 'csv' 
        )->a( n = `text` v = 'csv' 
        )->tag( `SegmentedButtonItem` 
        )->a( n = `key` v = 'xml' 
        )->a( n = `text` v = 'xml' ).

    grid = page->ele( n = `Grid` ns = `layout` 
               )->a( n = `defaultSpan` v = 'L12 M12 S12' 
               )->ele( n = `content` ns = `layout` ).

    page->tag( n = `CodeEditor` ns = `editor` 
        )->a( n = `type` v = COND #( WHEN ms_import-segment_key = 'csv' THEN |plain_text| ELSE ms_import-segment_key ) 
        )->a( n = `value` v = client->_bind_edit( ms_import-editor ) 
        )->a( n = `editable` b = abap_true ).

    page->ele( `footer` 
        )->ele( `OverflowToolbar` 
        )->tag( `Button` 
        )->a( n = `text` v = 'Clear' 
        )->a( n = `press` v = client->_event( 'IMPORT_CLEAR' ) 
        )->a( n = `icon` v = 'sap-icon://delete' 
        )->tag( `ToolbarSpacer` 
        )->tag( `Button` 
        )->a( n = `text` v = 'Import' 
        )->a( n = `press` v = client->_event( 'IMPORT_DB' ) 
        )->a( n = `type` v = 'Emphasized' 
        )->a( n = `icon` v = 'sap-icon://upload-to-cloud' ).

    client->view_display( page->stringify( ) ).


  ENDMETHOD.
ENDCLASS.
