CLASS z2ui5_cl_tcl_app_00 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS Z2UI5_CL_TCL_APP_00 IMPLEMENTATION.


  METHOD z2ui5_if_app~main.

    IF client->get( )-check_on_navigated = abap_true.

      DATA(view) = z2ui5_cl_ui5_view_builder=>factory( 
                       )->ele( n = `View` ns = `mvc` 
                       )->a( n = `xmlns` v = `sap.m` 
                       )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` 
                       )->a( n = `xmlns:core` v = `sap.ui.core` 
                       )->a( n = `displayBlock` v = `true` 
                       )->a( n = `height` v = `100%` ).

      DATA(page) = view->ele( `Shell` 
                       )->ele( `Page` 
                       )->a( n = `title` v = 'abap2UI5 - Table Content Loader' 
                       )->a( n = `navButtonPress` v = client->_event( 'BACK' ) 
                       )->a( n = `showNavButton` b = abap_true 
                       )->ele( `headerContent` 
                       )->ele( `OverflowToolbar` 
                       )->tag( `Link` 
                       )->a( n = `text` v = 'Project on GitHub' 
                       )->a( n = `target` v = '_blank' 
                       )->a( n = `href` v = 'https://github.com/abap2UI5-addons/table-content-loader' 
                       )->end( 
                       )->end( ).
      page = page->ele( `VBox` ).
      page = page->ele( `HBox` ).
      page->ele( `GenericTile` 
          )->a( n = `class` v = 'sapUiTinyMarginBegin sapUiTinyMarginTop tileLayout' 
          )->a( n = `header` v = `JSON` 
          )->a( n = `subheader` v = `Upload DB Content` 
          )->a( n = `state` v = 'Disabled' 
          )->a( n = `press` v = client->_event( `z2ui5_cl_tcl_app_01` ) 
          )->ele( `TileContent` 
          )->ele( `ImageContent` 
          )->a( n = `src` v = 'sap-icon://upload' ).

      page->ele( `GenericTile` 
          )->a( n = `class` v = 'sapUiTinyMarginBegin sapUiTinyMarginTop tileLayout' 
          )->a( n = `header` v = `JSON` 
          )->a( n = `subheader` v = `Download DB Content` 
          )->a( n = `press` v = client->_event( `z2ui5_cl_tcl_app_03` ) 
          )->ele( `TileContent` 
          )->ele( `ImageContent` 
          )->a( n = `src` v = 'sap-icon://download' ).

      page = page->end( 
                 )->ele( `HBox` ).

      page->ele( `GenericTile` 
          )->a( n = `class` v = 'sapUiTinyMarginBegin sapUiTinyMarginTop tileLayout' 
          )->a( n = `header` v = `CSV` 
          )->a( n = `subheader` v = `Upload DB Content` 
          )->a( n = `press` v = client->_event( `z2ui5_cl_tcl_app_04` ) 
          )->a( n = `enableNavigationButton` b = abap_false 
          )->a( n = `state` v = 'Disabled' 
          )->ele( `TileContent` 
          )->ele( `ImageContent` 
          )->a( n = `src` v = 'sap-icon://upload' ).

      page->ele( `GenericTile` 
          )->a( n = `class` v = 'sapUiTinyMarginBegin sapUiTinyMarginTop tileLayout' 
          )->a( n = `header` v = `CSV` 
          )->a( n = `subheader` v = `Download DB Content` 
          )->a( n = `press` v = client->_event( `z2ui5_cl_tcl_app_04` ) 
          )->a( n = `state` v = 'Disabled' 
          )->ele( `TileContent` 
          )->ele( `ImageContent` 
          )->a( n = `src` v = 'sap-icon://download' ).

      page = page->end( 
                 )->ele( `HBox` ).

      page->ele( `GenericTile` 
          )->a( n = `class` v = 'sapUiTinyMarginBegin sapUiTinyMarginTop tileLayout' 
          )->a( n = `header` v = `XLSX` 
          )->a( n = `subheader` v = `Upload DB Content` 
          )->a( n = `state` v = 'Disabled' 
          )->a( n = `press` v = client->_event( `z2ui5_cl_tcl_app_05` ) 
          )->ele( `TileContent` 
          )->ele( `ImageContent` 
          )->a( n = `src` v = 'sap-icon://upload' ).

      page->ele( `GenericTile` 
          )->a( n = `class` v = 'sapUiTinyMarginBegin sapUiTinyMarginTop tileLayout' 
          )->a( n = `header` v = `XLSX` 
          )->a( n = `subheader` v = `Download DB Content` 
          )->a( n = `press` v = client->_event( `z2ui5_cl_tcl_app_06` ) 
          )->ele( `TileContent` 
          )->ele( `ImageContent` 
          )->a( n = `src` v = 'sap-icon://download' ).

      client->view_display( view->stringify( ) ).

    ENDIF.

    IF client->get( )-event IS INITIAL.
      RETURN.
    ENDIF.

    CASE client->get( )-event.

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

      WHEN OTHERS.

        DATA li_app TYPE REF TO z2ui5_if_app.
        DATA(lv_classname) = to_upper( client->get( )-event ).
        CREATE OBJECT li_app TYPE (lv_classname).
        client->nav_app_call( li_app ).

    ENDCASE.


  ENDMETHOD.
ENDCLASS.
