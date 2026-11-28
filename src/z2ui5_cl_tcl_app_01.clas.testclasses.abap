*"* use this source file for your ABAP unit test classes

CLASS ltcl_unit_test DEFINITION DEFERRED.
CLASS z2ui5_cl_tcl_app_01 DEFINITION LOCAL FRIENDS ltcl_unit_test.

CLASS ltcl_unit_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS first_test FOR TESTING RAISING cx_static_check.
    METHODS file_utf8 FOR TESTING RAISING cx_static_check.
    METHODS file_windows_1252 FOR TESTING RAISING cx_static_check.
    METHODS write_refused_core_table FOR TESTING RAISING cx_static_check.
    METHODS write_refused_addon_table FOR TESTING RAISING cx_static_check.
    METHODS write_refused_other_namespace FOR TESTING RAISING cx_static_check.
    METHODS write_allowed_own_table FOR TESTING RAISING cx_static_check.
    METHODS table_name_plain FOR TESTING RAISING cx_static_check.
    METHODS table_name_with_clause FOR TESTING RAISING cx_static_check.
    METHODS table_name_no_structure FOR TESTING RAISING cx_static_check.

    "! the name of the core's draft table - by type, so a rename carries it
    METHODS get_core_table
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS ltcl_unit_test IMPLEMENTATION.

  METHOD first_test.

    DATA lv_csv_base64 TYPE string.
    DATA lv_data TYPE xstring.
    DATA lv_ready TYPE string.
    DATA lv_readyx TYPE xstring.
    DATA lv_data2 TYPE string.
    lv_csv_base64 =
`VXNlcm5hbWUsIElkZW50aWZpZXIsRmlyc3QgbmFtZSxMYXN0IG5hbWUNCmJvb2tlcjEyLDkwMTIsUmFjaGVsLEJvb2tlcg0KZ3JleTA3LDIwNzAsTGF1cmEsR3JleQ0Kam9obnNvbjgxLDQwODEsQ3JhaWcsSm9obnNvbg0KamVua2luczQ2LDkzNDYsTWFyeSxKZW5raW5zDQpzbWl0aDc5LDUwNzksSmFtaWUsU21pdGg=`.


    lv_data = z2ui5_cl_tcl_context=>conv_decode_x_base64( lv_csv_base64 ).

    lv_ready = z2ui5_cl_tcl_context=>conv_get_string_by_xstring( lv_data ).


    lv_readyx = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( lv_ready ).

    lv_data2 = z2ui5_cl_tcl_context=>conv_encode_x_base64( lv_readyx ).

    cl_abap_unit_assert=>assert_equals( exp = lv_csv_base64
                                        act = lv_data2 ).

  ENDMETHOD.

  METHOD file_utf8.

    " H + a-umlaut in UTF-8 - hex, as a literal umlaut breaks the 7-bit rule
    DATA temp1 TYPE xstring.
    DATA lv_text TYPE string.
    DATA temp2 TYPE xstring.
    temp1 = `48C3A4`.

    lv_text = z2ui5_cl_tcl_context=>conv_get_string_by_file( temp1 ).


    temp2 = `48C3A4`.
    cl_abap_unit_assert=>assert_equals(
        exp = temp2
        act = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( lv_text ) ).

  ENDMETHOD.

  METHOD file_windows_1252.

    " H + a-umlaut as Excel's plain "CSV" writes it on Windows: E4 alone is not UTF-8
    DATA temp3 TYPE xstring.
    DATA lv_text TYPE string.
    DATA temp4 TYPE xstring.
    temp3 = `48E4`.

    lv_text = z2ui5_cl_tcl_context=>conv_get_string_by_file( temp3 ).


    temp4 = `48C3A4`.
    cl_abap_unit_assert=>assert_equals(
        exp = temp4
        act = z2ui5_cl_tcl_context=>conv_get_xstring_by_string( lv_text ) ).

  ENDMETHOD.

  METHOD get_core_table.

    DATA ls_core_table TYPE z2ui5_t_01.
    result = cl_abap_typedescr=>describe_by_data( ls_core_table )->get_relative_name( ).

  ENDMETHOD.

  METHOD write_refused_core_table.

    " the draft table - rows planted there would run in another user's session
    cl_abap_unit_assert=>assert_not_initial( z2ui5_cl_tcl_app_01=>get_write_refusal( get_core_table( ) ) ).
    cl_abap_unit_assert=>assert_not_initial( z2ui5_cl_tcl_app_01=>get_write_refusal( to_lower( get_core_table( ) ) ) ).

  ENDMETHOD.

  METHOD write_refused_addon_table.

    " a table of an addon carries the same prefix - e.g. the configuration
    DATA lv_addon_table TYPE string.
    lv_addon_table = replace( val  = get_core_table( )
                                    sub  = `T_01`
                                    with = `T_29` ).
    cl_abap_unit_assert=>assert_not_initial( z2ui5_cl_tcl_app_01=>get_write_refusal( lv_addon_table ) ).

  ENDMETHOD.

  METHOD write_refused_other_namespace.

    cl_abap_unit_assert=>assert_not_initial( z2ui5_cl_tcl_app_01=>get_write_refusal( `MARA` ) ).

  ENDMETHOD.

  METHOD write_allowed_own_table.

    cl_abap_unit_assert=>assert_initial( z2ui5_cl_tcl_app_01=>get_write_refusal( `YTCL_TEST_TABLE` ) ).

  ENDMETHOD.

  METHOD table_name_plain.

    cl_abap_unit_assert=>assert_equals(
        exp = get_core_table( )
        act = z2ui5_cl_tcl_context=>db_get_table_name( | { to_lower( get_core_table( ) ) } | ) ).

  ENDMETHOD.

  METHOD table_name_with_clause.

    " a join or any further clause is no table name
    cl_abap_unit_assert=>assert_initial(
        z2ui5_cl_tcl_context=>db_get_table_name( |{ get_core_table( ) } AS a| ) ).
    cl_abap_unit_assert=>assert_initial(
        z2ui5_cl_tcl_context=>db_get_table_name( |{ get_core_table( ) },{ get_core_table( ) }| ) ).

  ENDMETHOD.

  METHOD table_name_no_structure.

    cl_abap_unit_assert=>assert_initial( z2ui5_cl_tcl_context=>db_get_table_name( `STRING` ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_tcl_context=>db_get_table_name( `` ) ).

  ENDMETHOD.

ENDCLASS.
