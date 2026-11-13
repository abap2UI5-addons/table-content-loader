CLASS z2ui5_cl_tcl_app_00 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS Z2UI5_CL_TCL_APP_00 IMPLEMENTATION.


  METHOD z2ui5_if_app~main.
      DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
        DATA temp1 TYPE REF TO z2ui5_cl_tcl_app_01.
        DATA temp2 TYPE REF TO z2ui5_cl_tcl_app_03.
        DATA temp3 TYPE REF TO z2ui5_cl_tcl_app_04.
        DATA temp4 TYPE REF TO z2ui5_cl_tcl_app_05.
        DATA temp5 TYPE REF TO z2ui5_cl_tcl_app_06.

    IF client->get( )-check_on_navigated = abap_true.


      view = z2ui5_cl_ui5_view_builder=>factory(
                       )->ele( n = `View` ns = `mvc`
                       )->a( n = `xmlns` v = `sap.m`
                       )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
                       )->a( n = `displayBlock` v = `true`
                       )->a( n = `height` v = `100%` ).


      page = view->ele( `Shell`
                       )->ele( `Page`
                       )->a( n = `title` v = `abap2UI5 - Table Content Loader`
                       )->a( n = `navButtonPress` v = client->_event( `BACK` )
                       )->a( n = `showNavButton` b = abap_true
                       )->ele( `headerContent`
                       )->ele( `OverflowToolbar`
                       )->tag( `Link`
                       )->a( n = `text` v = `Project on GitHub`
                       )->a( n = `target` v = `_blank`
                       )->a( n = `href` v = `https://github.com/abap2UI5-addons/table-content-loader`
                       )->end(
                       )->end( ).
      page = page->ele( `VBox` ).
      page = page->ele( `HBox` ).
      page->ele( `GenericTile`
          )->a( n = `class` v = `sapUiTinyMarginBegin sapUiTinyMarginTop`
          )->a( n = `header` v = `JSON`
          )->a( n = `subheader` v = `Upload DB Content`
          )->a( n = `state` v = `Disabled`
          )->a( n = `press` v = client->_event( `APP_01` )
          )->ele( `TileContent`
          )->ele( `ImageContent`
          )->a( n = `src` v = `sap-icon://upload` ).

      page->ele( `GenericTile`
          )->a( n = `class` v = `sapUiTinyMarginBegin sapUiTinyMarginTop`
          )->a( n = `header` v = `JSON`
          )->a( n = `subheader` v = `Download DB Content`
          )->a( n = `press` v = client->_event( `APP_03` )
          )->ele( `TileContent`
          )->ele( `ImageContent`
          )->a( n = `src` v = `sap-icon://download` ).

      page = page->end(
                 )->ele( `HBox` ).

      page->ele( `GenericTile`
          )->a( n = `class` v = `sapUiTinyMarginBegin sapUiTinyMarginTop`
          )->a( n = `header` v = `CSV`
          )->a( n = `subheader` v = `Upload DB Content`
          )->a( n = `press` v = client->_event( `APP_04` )
          )->a( n = `enableNavigationButton` b = abap_false
          )->a( n = `state` v = `Disabled`
          )->ele( `TileContent`
          )->ele( `ImageContent`
          )->a( n = `src` v = `sap-icon://upload` ).

      page->ele( `GenericTile`
          )->a( n = `class` v = `sapUiTinyMarginBegin sapUiTinyMarginTop`
          )->a( n = `header` v = `CSV`
          )->a( n = `subheader` v = `Download DB Content`
          )->a( n = `press` v = client->_event( `APP_04` )
          )->a( n = `state` v = `Disabled`
          )->ele( `TileContent`
          )->ele( `ImageContent`
          )->a( n = `src` v = `sap-icon://download` ).

      page = page->end(
                 )->ele( `HBox` ).

      page->ele( `GenericTile`
          )->a( n = `class` v = `sapUiTinyMarginBegin sapUiTinyMarginTop`
          )->a( n = `header` v = `XLSX`
          )->a( n = `subheader` v = `Upload DB Content`
          )->a( n = `state` v = `Disabled`
          )->a( n = `press` v = client->_event( `APP_05` )
          )->ele( `TileContent`
          )->ele( `ImageContent`
          )->a( n = `src` v = `sap-icon://upload` ).

      page->ele( `GenericTile`
          )->a( n = `class` v = `sapUiTinyMarginBegin sapUiTinyMarginTop`
          )->a( n = `header` v = `XLSX`
          )->a( n = `subheader` v = `Download DB Content`
          )->a( n = `press` v = client->_event( `APP_06` )
          )->ele( `TileContent`
          )->ele( `ImageContent`
          )->a( n = `src` v = `sap-icon://download` ).

      client->view_display( view->stringify( ) ).

    ENDIF.

    IF client->get( )-event IS INITIAL.
      RETURN.
    ENDIF.

    CASE client->get( )-event.

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

      " one branch per tile instead of CREATE OBJECT TYPE (event): the event
      " name comes from the browser, and any class of the system implementing
      " z2ui5_if_app could be started through it - an unknown name ended in a
      " short dump. Static references also follow a namespace rename, and the
      " event is a plain name rather than the class's: the rename rewrites
      " references, never a literal.
      WHEN `APP_01`.

        CREATE OBJECT temp1 TYPE z2ui5_cl_tcl_app_01.
        client->nav_app_call( temp1 ).

      WHEN `APP_03`.

        CREATE OBJECT temp2 TYPE z2ui5_cl_tcl_app_03.
        client->nav_app_call( temp2 ).

      WHEN `APP_04`.

        CREATE OBJECT temp3 TYPE z2ui5_cl_tcl_app_04.
        client->nav_app_call( temp3 ).

      WHEN `APP_05`.

        CREATE OBJECT temp4 TYPE z2ui5_cl_tcl_app_05.
        client->nav_app_call( temp4 ).

      WHEN `APP_06`.

        CREATE OBJECT temp5 TYPE z2ui5_cl_tcl_app_06.
        client->nav_app_call( temp5 ).

    ENDCASE.

  ENDMETHOD.
ENDCLASS.
