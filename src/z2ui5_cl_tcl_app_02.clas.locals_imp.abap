CLASS lcl_db DEFINITION.


  PUBLIC SECTION.


    TYPES ty_t_table TYPE z2ui5_cl_tcl_app_02=>ty_t_table.

    CLASS-DATA app TYPE REF TO z2ui5_cl_tcl_app_02.
    "CLASS-DATA st_table TYPE ty_t_table.

    CLASS-METHODS generate_test_data.

    CLASS-METHODS get_table_by_json
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_table.

    CLASS-METHODS get_table_by_xml
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_table.

    CLASS-METHODS get_table_by_csv
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_table.

    CLASS-METHODS get_csv_by_table
      IMPORTING
        val           TYPE ty_t_table
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS get_xml_by_table
      IMPORTING
        val           TYPE ty_t_table
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS get_json_by_table
      IMPORTING
        val           TYPE ty_t_table
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS get_fieldlist_by_table
      IMPORTING
        it_table      TYPE ty_t_table
      RETURNING
        VALUE(result) TYPE string_table.

    CLASS-METHODS db_save
      IMPORTING
        value TYPE ty_t_table.

    CLASS-METHODS db_read
      RETURNING
        VALUE(result) TYPE ty_t_table.
    CLASS-METHODS get_test_data_json
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.

CLASS lcl_db IMPLEMENTATION.

  METHOD generate_test_data.

    app->st_db = VALUE #(
        ( carrid = 'DL' connid = '0106' countryfr = 'US' cityfrom = 'NEW YORK' airpfrom = 'JFK' countryto = 'DE' cityto = 'FRANKFURT' airpto = 'FR' )
        ( carrid = 'DL' connid = '0106' countryfr = 'US' cityfrom = 'NEW YORK' airpfrom = 'JFK' countryto = 'DE' cityto = 'FRANKFURT' airpto = 'FR' )
        ( carrid = 'DL' connid = '0106' countryfr = 'US' cityfrom = 'NEW YORK' airpfrom = 'JFK' countryto = 'DE' cityto = 'FRANKFURT' airpto = 'FR' )
        ( carrid = 'DL' connid = '0106' countryfr = 'US' cityfrom = 'NEW YORK' airpfrom = 'JFK' countryto = 'DE' cityto = 'FRANKFURT' airpto = 'FR' )
        ( carrid = 'DL' connid = '0106' countryfr = 'US' cityfrom = 'NEW YORK' airpfrom = 'JFK' countryto = 'DE' cityto = 'FRANKFURT' airpto = 'FR' )
        ( carrid = 'DL' connid = '0106' countryfr = 'US' cityfrom = 'NEW YORK' airpfrom = 'JFK' countryto = 'DE' cityto = 'FRANKFURT' airpto = 'FR' )
        ( carrid = 'DL' connid = '0106' countryfr = 'US' cityfrom = 'NEW YORK' airpfrom = 'JFK' countryto = 'DE' cityto = 'FRANKFURT' airpto = 'FR' )
        ( carrid = 'DL' connid = '0106' countryfr = 'US' cityfrom = 'NEW YORK' airpfrom = 'JFK' countryto = 'DE' cityto = 'FRANKFURT' airpto = 'FR' )
    ).

  ENDMETHOD.


  METHOD get_table_by_json.

    z2ui5_cl_util=>json_parse( EXPORTING val  = val
                               CHANGING  data = result ).

  ENDMETHOD.


  METHOD get_table_by_xml.

    z2ui5_cl_util=>xml_parse( EXPORTING xml = val
                              IMPORTING any = result ).

  ENDMETHOD.

  METHOD get_table_by_csv.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA(lr_tab) = z2ui5_cl_util=>itab_get_itab_by_csv( val ).
    ASSIGN lr_tab->* TO <tab>.

    z2ui5_cl_util=>itab_corresponding( EXPORTING val = <tab>
                                       CHANGING  tab = result ).

  ENDMETHOD.

  METHOD db_save.

    "normally modify database here

    "test scenario, therefore write internal table instead
    app->st_db = value.

  ENDMETHOD.

  METHOD db_read.

    "normally read database here

    "test scenario, therefore read internal table instead

    result = app->st_db.

  ENDMETHOD.

  METHOD get_csv_by_table.

    result = z2ui5_cl_util=>itab_get_csv_by_itab( val ).

  ENDMETHOD.

  METHOD get_json_by_table.

    result = z2ui5_cl_util=>json_stringify( val ).

  ENDMETHOD.

  METHOD get_xml_by_table.

    result = z2ui5_cl_util=>xml_stringify( val ).

  ENDMETHOD.

  METHOD get_fieldlist_by_table.

    LOOP AT z2ui5_cl_util=>rtti_get_t_attri_by_any( it_table ) REFERENCE INTO DATA(lr_attri).
      INSERT CONV #( lr_attri->name ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_test_data_json.

    result = `[` && |\n| &&
             `  {` && |\n| &&
             `    "CARRID": "DL",` && |\n| &&
             `    "CONNID": 106,` && |\n| &&
             `    "COUNTRYFR": "US",` && |\n| &&
             `    "CITYFROM": "NEW YORK",` && |\n| &&
             `    "AIRPFROM": "JFK",` && |\n| &&
             `    "COUNTRYTO": "DE",` && |\n| &&
             `    "CITYTO": "FRANKFURT",` && |\n| &&
             `    "AIRPTO": "FR"` && |\n| &&
             `  },` && |\n| &&
             `  {` && |\n| &&
             `    "CARRID": "DL",` && |\n| &&
             `    "CONNID": 106,` && |\n| &&
             `    "COUNTRYFR": "US",` && |\n| &&
             `    "CITYFROM": "NEW YORK",` && |\n| &&
             `    "AIRPFROM": "JFK",` && |\n| &&
             `    "COUNTRYTO": "DE",` && |\n| &&
             `    "CITYTO": "FRANKFURT",` && |\n| &&
             `    "AIRPTO": "FR"` && |\n| &&
             `  },` && |\n| &&
             `  {` && |\n| &&
             `    "CARRID": "DL",` && |\n| &&
             `    "CONNID": 106,` && |\n| &&
             `    "COUNTRYFR": "US",` && |\n| &&
             `    "CITYFROM": "NEW YORK",` && |\n| &&
             `    "AIRPFROM": "JFK",` && |\n| &&
             `    "COUNTRYTO": "DE",` && |\n| &&
             `    "CITYTO": "FRANKFURT",` && |\n| &&
             `    "AIRPTO": "FR"` && |\n| &&
             `  },` && |\n| &&
             `  {` && |\n| &&
             `    "CARRID": "DL",` && |\n| &&
             `    "CONNID": 106,` && |\n| &&
             `    "COUNTRYFR": "US",` && |\n| &&
             `    "CITYFROM": "NEW YORK",` && |\n| &&
             `    "AIRPFROM": "JFK",` && |\n| &&
             `    "COUNTRYTO": "DE",` && |\n| &&
             `    "CITYTO": "FRANKFURT",` && |\n| &&
             `    "AIRPTO": "FR"` && |\n| &&
             `  },` && |\n| &&
             `  {` && |\n| &&
             `    "CARRID": "DL",` && |\n| &&
             `    "CONNID": 106,` && |\n| &&
             `    "COUNTRYFR": "US",` && |\n| &&
             `    "CITYFROM": "NEW YORK",` && |\n| &&
             `    "AIRPFROM": "JFK",` && |\n| &&
             `    "COUNTRYTO": "DE",` && |\n| &&
             `    "CITYTO": "FRANKFURT",` && |\n| &&
             `    "AIRPTO": "FR"` && |\n| &&
             `  },` && |\n| &&
             `  {` && |\n| &&
             `    "CARRID": "DL",` && |\n| &&
             `    "CONNID": 106,` && |\n| &&
             `    "COUNTRYFR": "US",` && |\n| &&
             `    "CITYFROM": "NEW YORK",` && |\n| &&
             `    "AIRPFROM": "JFK",` && |\n| &&
             `    "COUNTRYTO": "DE",` && |\n| &&
             `    "CITYTO": "FRANKFURT",` && |\n| &&
             `    "AIRPTO": "FR"` && |\n| &&
             `  },` && |\n| &&
             `  {` && |\n| &&
             `    "CARRID": "DL",` && |\n| &&
             `    "CONNID": 106,` && |\n| &&
             `    "COUNTRYFR": "US",` && |\n| &&
             `    "CITYFROM": "NEW YORK",` && |\n| &&
             `    "AIRPFROM": "JFK",` && |\n| &&
             `    "COUNTRYTO": "DE",` && |\n| &&
             `    "CITYTO": "FRANKFURT",` && |\n| &&
             `    "AIRPTO": "FR"` && |\n| &&
             `  },` && |\n| &&
             `  {` && |\n| &&
             `    "CARRID": "DL",` && |\n| &&
             `    "CONNID": 106,` && |\n| &&
             `    "COUNTRYFR": "US",` && |\n| &&
             `    "CITYFROM": "NEW YORK",` && |\n| &&
             `    "AIRPFROM": "JFK",` && |\n| &&
             `    "COUNTRYTO": "DE",` && |\n| &&
             `    "CITYTO": "FRANKFURT",` && |\n| &&
             `    "AIRPTO": "FR"` && |\n| &&
             `  }` && |\n| &&
             `]`.

  ENDMETHOD.

ENDCLASS.
