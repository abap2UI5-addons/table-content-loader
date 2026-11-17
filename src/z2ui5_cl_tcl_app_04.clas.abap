CLASS z2ui5_cl_tcl_app_04 DEFINITION PUBLIC.

  PUBLIC SECTION.

    INTERFACES z2ui5_if_app.

    DATA mv_path TYPE string.
    DATA mv_value TYPE string.
    DATA mr_table TYPE REF TO data.
    DATA mv_check_edit TYPE abap_bool.

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
              FIELD-SYMBOLS <tab> TYPE table.
              DATA lv_csv TYPE string.
              DATA lv_xcsv TYPE xstring.
              DATA lv_base TYPE string.
              DATA temp1 TYPE string_table.
              DATA temp2 LIKE LINE OF temp1.
            DATA lv_data TYPE xstring.
            DATA lv_ready TYPE string.
        DATA x TYPE REF TO cx_root.
    TRY.

        CASE client->get( )-event.

          WHEN 'CHANGE'.
            ui5_view_main_display( ).

          WHEN 'DOWNLOAD'.
            " the browser saves the file - the frontend action the core has
            " for it; the html:ZZPLAIN iframe this used to write was a trick
            " of the frozen view builder and downloaded nothing any more
            IF mr_table IS NOT INITIAL.

              ASSIGN mr_table->* TO <tab>.

              lv_csv = z2ui5_cl_tcl_context=>itab_get_csv_by_itab( <tab> ).

              lv_xcsv = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( lv_csv ).

              lv_base = z2ui5_cl_tcl_context=>conv_encode_x_base64( lv_xcsv ).

              CLEAR temp1.

              temp2 = |data:text/csv;base64,{ lv_base }|.
              INSERT temp2 INTO TABLE temp1.
              INSERT `table.csv` INTO TABLE temp1.
              client->follow_up_action( val   = client->cs_event-download_b64_file
                                        t_arg = temp1 ).
            ENDIF.

          WHEN 'UPLOAD'.


            lv_data = z2ui5_cl_tcl_context=>conv_get_xstring_by_data_uri( mv_value ).

            lv_ready = z2ui5_cl_tcl_context=>conv_get_string_by_file( lv_data ).

            mr_table = z2ui5_cl_tcl_context=>itab_get_itab_by_csv( lv_ready ).
            client->message_box_display( `CSV loaded to table` ).

            ui5_view_main_display( ).

            CLEAR mv_value.
            CLEAR mv_path.

          WHEN 'BACK'.
            client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

        ENDCASE.


      CATCH cx_root INTO x.
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

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
      FIELD-SYMBOLS <tab> TYPE table.
      DATA tab TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp3 TYPE string_table.
      DATA temp4 TYPE abap_component_tab.
      DATA row LIKE LINE OF temp4.
      DATA lr_fields LIKE temp3.
      DATA lo_cols TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp5 LIKE LINE OF lr_fields.
      DATA lr_col LIKE REF TO temp5.
      DATA lo_cells TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA footer TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory(
                     )->ele( n = `View` ns = `mvc`
                     )->a( n = `xmlns` v = `sap.m`
                     )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
                     )->a( n = `xmlns:z2ui5` v = `z2ui5.cc`
                     )->a( n = `displayBlock` v = `true`
                     )->a( n = `height` v = `100%` ).

    page = view->ele( `Shell`
                     )->ele( `Page`
                     )->a( n = `title` v = 'abap2UI5 - CSV to ABAP Internal Table'
                     )->a( n = `navButtonPress` v = client->_event( 'BACK' )
                     )->a( n = `showNavButton` b = abap_true ).

    IF mr_table IS NOT INITIAL.

      ASSIGN mr_table->* TO <tab>.


      tab = page->ele( `Table`
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


      CLEAR temp3.

      temp4 = z2ui5_cl_tcl_context=>rtti_get_t_attri_by_any( <tab> ).

      LOOP AT temp4 INTO row.
        INSERT row-name INTO TABLE temp3.
      ENDLOOP.

      lr_fields = temp3.

      lo_cols = tab->ele( `columns` ).


      LOOP AT lr_fields REFERENCE INTO lr_col.
        lo_cols->ele( `Column`
            )->tag( `Text`
            )->a( n = `text` v = lr_col->* ).
      ENDLOOP.

      lo_cells = tab->ele( `items`
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


    footer = page->ele( `footer`
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

    IF client->check_on_init( ) IS NOT INITIAL.
      ui5_on_init( ).
      RETURN.
    ENDIF.

    IF client->get( )-check_on_navigated = abap_true.
      ui5_view_main_display( ).
    ENDIF.

    ui5_on_event( ).

  ENDMETHOD.
ENDCLASS.
