CLASS z2ui5_cl_tcl_app_06 DEFINITION PUBLIC.

  PUBLIC SECTION.

    INTERFACES z2ui5_if_app.

    DATA check_initialized TYPE abap_bool.
    DATA client TYPE REF TO z2ui5_if_client.
    DATA mv_file TYPE string.
    DATA mv_check_download_file TYPE abap_bool.

    TYPES:
      BEGIN OF ty_s_config_head,
        title TYPE string,
      END OF ty_s_config_head.

    DATA:
      BEGIN OF ms_draft,
        table_name               TYPE string,
        check_load_pressed       TYPE abap_bool,
        check_config_pressed     TYPE abap_bool,
        check_config_pos_pressed TYPE abap_bool,
        check_preview_pressed    TYPE abap_bool,
        check_download_pressed   TYPE abap_bool,
        t_tab                    TYPE REF TO data,
        max_rows                 TYPE i VALUE 10,
        t_fcat                   TYPE z2ui5_cl_tcl_xlsx_api=>ty_t_xlsx,
        t_config                 TYPE STANDARD TABLE OF z2ui5_cl_tcl_xlsx_api=>ty_s_xlsx_settings WITH EMPTY KEY,
        t_config_head            TYPE STANDARD TABLE OF ty_s_config_head WITH EMPTY KEY,
        check_download_active    TYPE abap_bool,
        check_file_row_limit     TYPE abap_bool VALUE abap_true,
        file_max_rows            TYPE i VALUE 10,
        file_rows                TYPE i,
        file_size                TYPE i,
      END OF ms_draft.

    METHODS set_view.
    METHODS load_table.

    METHODS on_event.
    METHODS on_callback.
    METHODS on_init.
    METHODS set_view_load
      IMPORTING
        page TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS set_view_config
      IMPORTING
        page TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS set_view_preview
      IMPORTING
        page TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS set_view_config_pos
      IMPORTING
        page TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS set_view_download
      IMPORTING
        page TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS create_file.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS Z2UI5_CL_TCL_APP_06 IMPLEMENTATION.


  METHOD create_file.

    TRY.

        DATA(lr_tab) = z2ui5_cl_tcl_context=>rtti_create_tab_by_name( ms_draft-table_name ).
        FIELD-SYMBOLS <tab> TYPE table.
        ASSIGN lr_tab->* TO <tab>.

        IF ms_draft-check_file_row_limit = abap_true.

          SELECT FROM (ms_draft-table_name)
            FIELDS *
            INTO CORRESPONDING FIELDS OF TABLE @<tab>
            UP TO @ms_draft-file_max_rows ROWS.

        ELSE.

          SELECT FROM (ms_draft-table_name)
            FIELDS *
            INTO CORRESPONDING FIELDS OF TABLE @<tab>.

        ENDIF.

        DATA(lv_result) = z2ui5_cl_tcl_xlsx_api=>get_xlsx_by_table( val          = <tab>
                                                                    title        = ms_draft-t_config_head[ 1 ]-title
                                                                    settings     = ms_draft-t_config[ 1 ]
                                                                    fieldcatalog = ms_draft-t_fcat ).
        mv_file = z2ui5_cl_tcl_context=>conv_encode_x_base64( lv_result ).

        ms_draft-file_rows = lines( <tab> ).
        ms_draft-file_size = xstrlen( lv_result ) / 1000.

      CATCH cx_root INTO DATA(lx).
        client->message_box_display(
            text = lx->get_text( )
            type = 'error' ).
    ENDTRY.
  ENDMETHOD.


  METHOD load_table.

    FIELD-SYMBOLS <tab> TYPE table.
    ASSIGN ms_draft-t_tab->* TO <tab>.

    SELECT FROM (ms_draft-table_name)
      FIELDS *
      INTO CORRESPONDING FIELDS OF TABLE @<tab>
      UP TO @ms_draft-max_rows ROWS.

  ENDMETHOD.


  METHOD on_callback.

    TRY.
        DATA(lo_prev) = client->get_app( client->get( )-s_draft-id_prev_app ).
        ms_draft-table_name = CAST z2ui5_cl_popup_input_val( lo_prev )->result( )-value.
        ms_draft-check_load_pressed = abap_true.

        ms_draft-t_tab = z2ui5_cl_tcl_context=>rtti_create_tab_by_name( ms_draft-table_name ).
        FIELD-SYMBOLS <tab> TYPE table.
        ASSIGN  ms_draft-t_tab->* TO <tab>.

        ms_draft-t_fcat = zcl_excel_common=>get_fieldcatalog( <tab> ).
        DATA ls_table_settings TYPE zexcel_s_table_settings.
        ls_table_settings-table_style  = zcl_excel_table=>builtinstyle_medium5.
        INSERT ls_table_settings INTO TABLE ms_draft-t_config.

        DATA ls_config_head TYPE ty_s_config_head.
        ls_config_head-title = `tabtitle`.
        INSERT ls_config_head INTO TABLE ms_draft-t_config_head.

        load_table( ).
        set_view( ).

      CATCH cx_root.
    ENDTRY.

  ENDMETHOD.


  METHOD on_event.

    CASE client->get( )-event.

      WHEN 'BACK'.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

      WHEN `DOWNLOAD_FILE`.
        mv_check_download_file = abap_true.
        set_view( ).

      WHEN 'CREATE_FILE'.
        create_file( ).
        set_view( ).

      WHEN `VIEW_LOAD`.
        ms_draft-check_load_pressed = abap_true.
        ms_draft-check_config_pressed = abap_false.
        ms_draft-check_config_pos_pressed = abap_false.
        ms_draft-check_preview_pressed = abap_false.
        ms_draft-check_download_pressed = abap_false.
        set_view( ).

      WHEN `VIEW_CONFIG`.
        ms_draft-check_load_pressed = abap_false.
        ms_draft-check_config_pressed = abap_true.
        ms_draft-check_config_pos_pressed = abap_false.
        ms_draft-check_preview_pressed = abap_false.
        ms_draft-check_download_pressed = abap_false.
        set_view( ).

      WHEN `VIEW_CONFIG_POS`.
        ms_draft-check_load_pressed = abap_false.
        ms_draft-check_config_pressed = abap_false.
        ms_draft-check_config_pos_pressed = abap_true.
        ms_draft-check_preview_pressed = abap_false.
        ms_draft-check_download_pressed = abap_false.
        set_view( ).

      WHEN `VIEW_PREVIEW`.
        ms_draft-check_load_pressed = abap_false.
        ms_draft-check_config_pressed = abap_false.
        ms_draft-check_config_pos_pressed = abap_false.
        ms_draft-check_preview_pressed = abap_true.
        ms_draft-check_download_pressed = abap_false.
        set_view( ).

      WHEN `VIEW_DOWNLOAD`.
        ms_draft-check_load_pressed = abap_false.
        ms_draft-check_config_pressed = abap_false.
        ms_draft-check_config_pos_pressed = abap_false.
        ms_draft-check_preview_pressed = abap_false.
        ms_draft-check_download_pressed = abap_true.
        set_view( ).

      WHEN `LOAD`.
        load_table( ).
        set_view( ).

      WHEN `RESET_CONFIG`.
        CLEAR ms_draft-t_config.
        DATA ls_table_settings TYPE zexcel_s_table_settings.
        ls_table_settings-table_style = zcl_excel_table=>builtinstyle_medium5.
        INSERT ls_table_settings INTO TABLE ms_draft-t_config.
        CLEAR ms_draft-t_config_head.
        DATA ls_config_head TYPE ty_s_config_head.
        ls_config_head-title = `tabtitle`.
        INSERT ls_config_head INTO TABLE ms_draft-t_config_head.
        set_view( ).

      WHEN `RESET_FCAT`.
        IF ms_draft-t_tab IS BOUND.
          FIELD-SYMBOLS <tab_fcat> TYPE table.
          ASSIGN ms_draft-t_tab->* TO <tab_fcat>.
          ms_draft-t_fcat = zcl_excel_common=>get_fieldcatalog( <tab_fcat> ).
        ENDIF.
        set_view( ).

      WHEN 'DOWNLOAD'.
        IF ms_draft-t_tab IS NOT BOUND.
          client->message_box_display( `Table is empty, no export possible` ).
          RETURN.
        ENDIF.
        ms_draft-check_download_active = abap_true.
        set_view( ).

      WHEN `NEW`.
        DATA(lo_app) = z2ui5_cl_popup_input_val=>factory(
            title   = `Create a New XLSX Draft`
            text    = `Database Table:`
            val     = ms_draft-table_name ).
        client->nav_app_call( lo_app ).

    ENDCASE.

  ENDMETHOD.


  METHOD on_init.

    set_view( ).

  ENDMETHOD.


  METHOD set_view.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( 
                     )->ele( n = `View` ns = `mvc` 
                     )->a( n = `xmlns` v = `sap.m` 
                     )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` 
                     )->a( n = `xmlns:core` v = `sap.ui.core` 
                     )->a( n = `xmlns:form` v = `sap.ui.layout.form` 
                     )->a( n = `xmlns:html` v = `http://www.w3.org/1999/xhtml` 
                     )->a( n = `displayBlock` v = `true` 
                     )->a( n = `height` v = `100%` ).

    DATA(page) = view->ele( `Page` 
                     )->a( n = `title` v = 'abap2UI5 - XLSX Download' 
                     )->a( n = `navButtonPress` v = client->_event( 'BACK' ) 
                     )->a( n = `showNavButton` b = xsdbool( client->get( )-s_draft-id_prev_app_stack IS NOT INITIAL ) 
                     )->ele( `headerContent` 
                     )->tag( `Link` 
                     )->a( n = `text` v = 'Project on GitHub' 
                     )->a( n = `target` v = '_blank' 
                     )->a( n = `href` v = `https://github.com/abap2UI5-addons/table-content-loader` 
                     )->end( ).

    CASE abap_true.
      WHEN ms_draft-check_load_pressed.
        set_view_load( page ).
      WHEN ms_draft-check_config_pressed.
        set_view_config( page ).
      WHEN ms_draft-check_config_pos_pressed.
        set_view_config_pos( page ).
      WHEN ms_draft-check_preview_pressed.
        set_view_preview( page ).
      WHEN ms_draft-check_download_pressed.
        set_view_download( page ).
    ENDCASE.

    DATA(footer) = page->ele( `footer` 
                       )->ele( `OverflowToolbar` ).
    footer->tag( `Button` 
        )->a( n = `icon` v = 'sap-icon://create' 
        )->a( n = `text` v = `New` 
        )->a( n = `press` v = client->_event( 'NEW' ) 
        )->tag( `Button` 
        )->a( n = `text` v = 'Load' 
        )->a( n = `press` v = client->_event( 'LOAD' ) 
        )->a( n = `icon` v = `sap-icon://download-from-cloud` 
        )->tag( `Button` 
        )->a( n = `text` v = 'Save Draft' 
        )->a( n = `press` v = client->_event( 'DOWNLOAD' ) 
        )->a( n = `icon` v = `sap-icon://upload-to-cloud` 
        )->tag( `Input` 
        )->a( n = `description` v = `Table` 
        )->a( n = `value` v = client->_bind_edit( ms_draft-table_name ) 
        )->a( n = `width` v = `15%` 
        )->a( n = `enabled` b = abap_false 
        )->tag( `ToolbarSpacer` ).

    IF ms_draft-table_name IS NOT INITIAL.
      footer->tag( `Button` 
          )->a( n = `text` v = '(1) Data Preview' 
          )->a( n = `type` v = `Emphasized` 
          )->a( n = `press` v = client->_event( 'VIEW_LOAD' ) 
          )->a( n = `enabled` b = xsdbool( ms_draft-check_load_pressed = abap_false ) 
          )->tag( `Button` 
          )->a( n = `text` v = '(2) Config Head' 
          )->a( n = `type` v = `Emphasized` 
          )->a( n = `press` v = client->_event( 'VIEW_CONFIG' ) 
          )->a( n = `enabled` b = xsdbool( ms_draft-check_config_pressed = abap_false ) 
          )->tag( `Button` 
          )->a( n = `text` v = '(3) Config Pos' 
          )->a( n = `type` v = `Emphasized` 
          )->a( n = `press` v = client->_event( 'VIEW_CONFIG_POS' ) 
          )->a( n = `enabled` b = xsdbool( ms_draft-check_config_pos_pressed = abap_false ) 
          )->tag( `Button` 
          )->a( n = `text` v = '(4) XLSX Preview' 
          )->a( n = `type` v = `Emphasized` 
          )->a( n = `press` v = client->_event( 'VIEW_PREVIEW' ) 
          )->a( n = `enabled` b = xsdbool( ms_draft-check_preview_pressed = abap_false ) 
          )->tag( `Button` 
          )->a( n = `text` v = '(5) Download' 
          )->a( n = `type` v = `Emphasized` 
          )->a( n = `press` v = client->_event( 'VIEW_DOWNLOAD' ) 
          )->a( n = `enabled` b = xsdbool( ms_draft-check_download_pressed = abap_false ) ).
    ENDIF.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD set_view_config.

    DATA(cont) = page->ele( `ScrollContainer` 
                     )->a( n = `height` v = `30%` 
                     )->a( n = `width` v = `100%` 
                     )->a( n = `vertical` b = abap_true 
                     )->a( n = `horizontal` b = abap_true ).

    DATA(tab) = cont->ele( `Table` 
                    )->a( n = `items` v = client->_bind_edit( ms_draft-t_config ) 
                    )->ele( `headerToolbar` 
                    )->ele( `OverflowToolbar` 
                    )->tag( `Title` 
                    )->a( n = `text` v = `Excel Configuration` 
                    )->tag( `ToolbarSpacer` 
                    )->tag( `Button` 
                    )->a( n = `text` v = `Reset` 
                    )->a( n = `press` v = client->_event( `RESET_CONFIG` ) 
                    )->a( n = `icon` v = `sap-icon://refresh` 
                    )->a( n = `type` v = `Emphasized` 
                    )->end( 
                    )->end( ).

    DATA(lt_fields) = z2ui5_cl_tcl_context=>rtti_get_t_attri_by_any( ms_draft-t_config ).

    DATA(lo_columns) = tab->ele( `columns` ).
    LOOP AT lt_fields INTO DATA(lv_field) FROM 1.
      lo_columns->ele( `Column` 
          )->tag( `Text` 
          )->a( n = `text` v = lv_field-name ).
    ENDLOOP.

    DATA(lo_cells) = tab->ele( `items` 
                         )->ele( `ColumnListItem` 
                         )->ele( `cells` ).
    LOOP AT lt_fields INTO lv_field FROM 1.
      lo_cells->tag( `Input` 
          )->a( n = `value` v = `{` && lv_field-name && `}` ).
    ENDLOOP.

    cont = page->ele( `ScrollContainer` 
               )->a( n = `height` v = `30%` 
               )->a( n = `width` v = `100%` 
               )->a( n = `vertical` b = abap_true 
               )->a( n = `horizontal` b = abap_true ).

    tab = cont->ele( `Table` 
              )->a( n = `items` v = client->_bind_edit( ms_draft-t_config_head ) 
              )->ele( `headerToolbar` 
              )->ele( `OverflowToolbar` 
              )->tag( `Title` 
              )->a( n = `text` v = `Parameter` 
              )->tag( `ToolbarSpacer` 
              )->tag( `Button` 
              )->a( n = `text` v = `Reset` 
              )->a( n = `press` v = client->_event( `RESET_CONFIG` ) 
              )->a( n = `icon` v = `sap-icon://refresh` 
              )->a( n = `type` v = `Emphasized` 
              )->end( 
              )->end( ).

    lt_fields = z2ui5_cl_tcl_context=>rtti_get_t_attri_by_any( ms_draft-t_config_head ).

    lo_columns = tab->ele( `columns` ).
    LOOP AT lt_fields INTO lv_field FROM 1.
      lo_columns->ele( `Column` 
          )->tag( `Text` 
          )->a( n = `text` v = lv_field-name ).
    ENDLOOP.

    lo_cells = tab->ele( `items` 
                   )->ele( `ColumnListItem` 
                   )->ele( `cells` ).
    LOOP AT lt_fields INTO lv_field FROM 1.
      lo_cells->tag( `Input` 
          )->a( n = `value` v = `{` && lv_field-name && `}` ).
    ENDLOOP.

  ENDMETHOD.


  METHOD set_view_config_pos.

    DATA(cont) = page->ele( `ScrollContainer` 
                     )->a( n = `height` v = `100%` 
                     )->a( n = `width` v = `100%` 
                     )->a( n = `vertical` b = abap_true 
                     )->a( n = `horizontal` b = abap_true ).

    DATA(tab) = cont->ele( `Table` 
                    )->a( n = `items` v = client->_bind_edit( ms_draft-t_fcat ) 
                    )->ele( `headerToolbar` 
                    )->ele( `OverflowToolbar` 
                    )->tag( `Title` 
                    )->a( n = `text` v = `Excel Fieldcatalog` 
                    )->tag( `ToolbarSpacer` 
                    )->tag( `Button` 
                    )->a( n = `text` v = `Reset` 
                    )->a( n = `press` v = client->_event( `RESET_FCAT` ) 
                    )->a( n = `icon` v = `sap-icon://refresh` 
                    )->a( n = `type` v = `Emphasized` 
                    )->end( 
                    )->end( ).

    DATA(lt_fields) = z2ui5_cl_tcl_context=>rtti_get_t_attri_by_any( ms_draft-t_fcat ).

    DATA(lo_columns) = tab->ele( `columns` ).
    LOOP AT lt_fields INTO DATA(lv_field) FROM 1.
      lo_columns->ele( `Column` 
          )->tag( `Text` 
          )->a( n = `text` v = lv_field-name ).
    ENDLOOP.

    DATA(lo_cells) = tab->ele( `items` 
                         )->ele( `ColumnListItem` 
                         )->ele( `cells` ).
    LOOP AT lt_fields INTO lv_field FROM 1.
      lo_cells->tag( `Input` 
          )->a( n = `value` v = `{` && lv_field-name && `}` ).
    ENDLOOP.

  ENDMETHOD.


  METHOD set_view_download.

    IF mv_check_download_file = abap_true.
      mv_check_download_file = abap_false.

      page->ele( n = `iframe` ns = `html` 
          )->a( n = `src` v = `data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,` && mv_file 
          )->a( n = `hidden` v = `hidden` ).

    ENDIF.

    DATA(content) = page->ele( n = `SimpleForm` ns = `form` 
                        )->a( n = `title` v = `Create File .xlsx` 
                        )->a( n = `layout` v = `ResponsiveGridLayout` 
                        )->a( n = `editable` v = `true` ).

    content->tag( `Label` 
        )->a( n = `text` v = `Activate Row Limitation` 
        )->tag( `CheckBox` 
        )->a( n = `selected` v = client->_bind_edit( ms_draft-check_file_row_limit ) 
        )->tag( `Label` 
        )->a( n = `text` v = `Rows` 
        )->tag( `Input` 
        )->a( n = `value` v = client->_bind_edit( ms_draft-file_max_rows ) 
        )->a( n = `enabled` v = client->_bind_edit( ms_draft-check_file_row_limit ) 
        )->a( n = `width` v = `10%` 
        )->tag( `Label` 
        )->a( n = `text` v = `Prepare File with abap2xlsx` 
        )->tag( `Button` 
        )->a( n = `text` v = `Create` 
        )->a( n = `width` v = `7%` 
        )->a( n = `press` v = client->_event( `CREATE_FILE` ) 
        )->tag( `Label` 
        )->a( n = `text` v = `Number of Entries` 
        )->tag( `Input` 
        )->a( n = `value` v = client->_bind( ms_draft-file_rows ) 
        )->a( n = `width` v = `10%` 
        )->a( n = `enabled` b = abap_false 
        )->tag( `Label` 
        )->a( n = `text` v = `File Size` 
        )->tag( `Input` 
        )->a( n = `value` v = client->_bind( ms_draft-file_size ) 
        )->a( n = `width` v = `10%` 
        )->a( n = `description` v = `kB` 
        )->a( n = `enabled` b = abap_false 
        )->tag( `Label` 
        )->a( n = `text` v = `File` 
        )->tag( `Button` 
        )->a( n = `text` v = `Download` 
        )->a( n = `width` v = `7%` 
        )->a( n = `enabled` v = COND #( WHEN mv_file IS NOT INITIAL THEN abap_true ELSE abap_false ) 
        )->a( n = `press` v = client->_event( `DOWNLOAD_FILE` ) ).

  ENDMETHOD.


  METHOD set_view_load.

    IF ms_draft-t_tab IS BOUND.

      FIELD-SYMBOLS <tab> TYPE table.
      ASSIGN  ms_draft-t_tab->* TO <tab>.

      DATA(cont) = page->ele( `ScrollContainer` 
                       )->a( n = `height` v = `100%` 
                       )->a( n = `width` v = `100%` 
                       )->a( n = `vertical` b = abap_true 
                       )->a( n = `horizontal` b = abap_true ).

      DATA(tab) = cont->ele( `Table` 
                      )->a( n = `items` v = client->_bind( <tab> ) 
                      )->ele( `headerToolbar` 
                      )->ele( `OverflowToolbar` 
                      )->tag( `Title` 
                      )->a( n = `text` v = `(1) Data Preview - ` && ms_draft-table_name 
                      )->tag( `ToolbarSpacer` 
                      )->tag( `Input` 
                      )->a( n = `description` v = `rows` 
                      )->a( n = `value` v = client->_bind_edit( ms_draft-max_rows ) 
                      )->a( n = `width` v = `10%` 
                      )->tag( `Button` 
                      )->a( n = `text` v = `Reset` 
                      )->a( n = `press` v = client->_event( `LOAD` ) 
                      )->a( n = `icon` v = `sap-icon://refresh` 
                      )->a( n = `type` v = `Emphasized` 
                      )->end( 
                      )->end( ).

      DATA(lt_fields) = z2ui5_cl_tcl_context=>rtti_get_t_attri_by_any( <tab> ).

      DATA(lo_columns) = tab->ele( `columns` ).
      LOOP AT lt_fields INTO DATA(lv_field) FROM 1.
        lo_columns->ele( `Column` 
            )->tag( `Text` 
            )->a( n = `text` v = lv_field-name ).
      ENDLOOP.

      DATA(lo_cells) = tab->ele( `items` 
                           )->ele( `ColumnListItem` 
                           )->ele( `cells` ).
      LOOP AT lt_fields INTO lv_field FROM 1.
        lo_cells->tag( `Text` 
            )->a( n = `text` v = `{` && lv_field-name && `}` ).
      ENDLOOP.

    ENDIF.

  ENDMETHOD.


  METHOD set_view_preview.


  ENDMETHOD.


  METHOD z2ui5_if_app~main.

    me->client = client.

    IF check_initialized = abap_false.
      check_initialized = abap_true.
      on_init( ).
      RETURN.
    ENDIF.

    IF client->get( )-check_on_navigated = abap_true.
      on_callback( ).
      RETURN.
    ENDIF.

    on_event( ).

  ENDMETHOD.
ENDCLASS.
