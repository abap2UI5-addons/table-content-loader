CLASS z2ui5_cl_tcl_app_04 DEFINITION PUBLIC.

  PUBLIC SECTION.

    INTERFACES z2ui5_if_app.

    DATA mv_path TYPE string.
    DATA mv_value TYPE string.
    DATA mr_table TYPE REF TO data.
    DATA mv_check_edit TYPE abap_bool.
    DATA mv_check_download TYPE abap_bool.

  PROTECTED SECTION.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS ui5_on_init.
    METHODS ui5_on_event.

    METHODS ui5_view_main_display.

    METHODS ui5_view_init_display.

  PRIVATE SECTION.
ENDCLASS.



CLASS Z2UI5_CL_TCL_APP_04 IMPLEMENTATION.


  METHOD ui5_on_event.
    TRY.

        CASE client->get( )-event.

          WHEN 'START' OR 'CHANGE'.
            ui5_view_main_display( ).

          WHEN 'DOWNLOAD'.
            mv_check_download = abap_true.
            ui5_view_main_display( ).

          WHEN 'UPLOAD'.

            DATA(lv_data) = z2ui5_cl_tcl_context=>conv_get_xstring_by_data_uri( mv_value ).
            DATA(lv_ready) = z2ui5_cl_tcl_context=>conv_get_string_by_xstring( lv_data ).

            mr_table = z2ui5_cl_tcl_context=>itab_get_itab_by_csv( lv_ready ).
            client->message_box_display( `CSV loaded to table` ).

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


  METHOD ui5_on_init.

    ui5_view_init_display( ).

  ENDMETHOD.


  METHOD ui5_view_init_display.

    ui5_view_main_display( ).

  ENDMETHOD.


  METHOD ui5_view_main_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( 
                     )->ele( n = `View` ns = `mvc` 
                     )->a( n = `xmlns` v = `sap.m` 
                     )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` 
                     )->a( n = `xmlns:core` v = `sap.ui.core` 
                     )->a( n = `xmlns:html` v = `http://www.w3.org/1999/xhtml` 
                     )->a( n = `xmlns:z2ui5` v = `z2ui5.cc` 
                     )->a( n = `displayBlock` v = `true` 
                     )->a( n = `height` v = `100%` ).
    DATA(page) = view->ele( `Shell` 
                     )->ele( `Page` 
                     )->a( n = `title` v = 'abap2UI5 - CSV to ABAP internal Table' 
                     )->a( n = `navButtonPress` v = client->_event( 'BACK' ) 
                     )->a( n = `showNavButton` b = abap_true 
                     )->ele( `headerContent` 
                     )->tag( `ToolbarSpacer` 
                     )->end( ).

    IF mv_check_download = abap_true.

      FIELD-SYMBOLS <tab> TYPE table.
      ASSIGN mr_table->* TO <tab>.
      mv_check_download = abap_false.
      DATA(lv_csv) = z2ui5_cl_tcl_context=>itab_get_csv_by_itab( <tab> ).
      DATA(lv_xcsv) = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( lv_csv ).
      DATA(lv_base) = z2ui5_cl_tcl_context=>conv_encode_x_base64( lv_xcsv ).
      view->tag( n = `ZZPLAIN` ns = `html` 
          )->a( n = `VALUE` v = '<html:iframe src="data:text/csv;base64,' && lv_base && '" height="0%" width="0%"/>' ).
    ENDIF.

    IF mr_table IS NOT INITIAL.
      ASSIGN mr_table->* TO <tab>.

      DATA(tab) = page->ele( `Table` 
                      )->a( n = `items` v = client->_bind_edit( <tab> ) 
                      )->ele( `headerToolbar` 
                      )->ele( `OverflowToolbar` 
                      )->tag( `Title` 
                      )->a( n = `text` v = 'CSV Content' 
                      )->tag( `ToolbarSpacer` 
                      )->tag( `Switch` 
                      )->a( n = `change` v = client->_event( `CHANGE` ) 
                      )->a( n = `state` v = client->_bind_edit( mv_check_edit ) 
                      )->a( n = `customTextOn` v = 'Edit' 
                      )->a( n = `customTextOff` v = 'View' 
                      )->end( 
                      )->end( ).


      DATA(lr_fields) = VALUE string_table( FOR row IN z2ui5_cl_tcl_context=>rtti_get_t_attri_by_any( <tab> ) ( row-name ) ).
      DATA(lo_cols) = tab->ele( `columns` ).
      LOOP AT lr_fields REFERENCE INTO DATA(lr_col).
        lo_cols->ele( `Column` 
            )->tag( `Text` 
            )->a( n = `text` v = lr_col->* ).
      ENDLOOP.
      DATA(lo_cells) = tab->ele( `items` 
                           )->ele( `ColumnListItem` 
                           )->ele( `cells` ).
      LOOP AT lr_fields REFERENCE INTO lr_col.
        IF mv_check_edit = abap_true.
          lo_cells->tag( `Input` 
              )->a( n = `value` v = `{` && lr_col->* && `}` ).
        ELSE.
          lo_cells->tag( `Text` 
              )->a( n = `text` v = `{` && lr_col->* && `}` ).
        ENDIF.
      ENDLOOP.
    ENDIF.

    DATA(footer) = page->ele( `footer` 
                       )->ele( `OverflowToolbar` ).

    footer->tag( n = `FileUploader` ns = `z2ui5` 
        )->a( n = `value` v = client->_bind_edit( mv_value ) 
        )->a( n = `path` v = client->_bind_edit( mv_path ) 
        )->a( n = `placeholder` v = `File path here...` 
        )->a( n = `upload` v = client->_event( 'UPLOAD' ) ).

    footer->tag( `ToolbarSpacer` 
        )->tag( `Button` 
        )->a( n = `text` v = 'Download CSV' 
        )->a( n = `press` v = client->_event( 'DOWNLOAD' ) 
        )->a( n = `type` v = 'Emphasized' 
        )->a( n = `icon` v = 'sap-icon://download' ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      ui5_on_init( ).
      RETURN.
    ENDIF.

    IF client->get( )-check_on_navigated = abap_true.
      ui5_view_main_display( ).
    ENDIF.

    ui5_on_event( ).

  ENDMETHOD.
ENDCLASS.
