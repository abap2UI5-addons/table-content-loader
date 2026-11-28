CLASS z2ui5_cl_tcl_context DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_s_name_value,
        n TYPE string,
        v TYPE string,
      END OF ty_s_name_value.
    TYPES ty_t_name_value TYPE STANDARD TABLE OF ty_s_name_value WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_msg,
        text       TYPE string,
        id         TYPE string,
        no         TYPE string,
        type       TYPE string,
        v1         TYPE string,
        v2         TYPE string,
        v3         TYPE string,
        v4         TYPE string,
        timestampl TYPE timestampl,
        t_meta     TYPE ty_t_name_value,
      END OF ty_s_msg,
      ty_t_msg TYPE STANDARD TABLE OF ty_s_msg WITH DEFAULT KEY.

    " Environment-abstracted character/format constants. Callers must read
    " these from z2ui5_cl_util instead of referencing cl_abap_char_utilities /
    " cl_abap_format directly, so the dependency on those SAP standard classes
    " lives in exactly one place (this class' class_constructor) and can be
    " ported once for non-ABAP runtimes (e.g. transpiled JS).
    CLASS-DATA cv_char_util_newline        TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_char_util_cr_lf          TYPE c LENGTH 2 READ-ONLY.

    CLASS-DATA cv_char_util_horizontal_tab TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_char_util_charsize       TYPE i          READ-ONLY.

    CLASS-DATA cv_format_e_xml_attr             TYPE i          READ-ONLY.

    " RTTI type-kind / kind / visibility constants, so callers can branch on
    " stored type_kind/kind fields without referencing cl_abap_typedescr /
    " cl_abap_objectdescr directly.
    CLASS-DATA cv_typedescr_typekind_table   TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_dref    TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_oref    TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_struct1 TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_struct2 TYPE c LENGTH 1 READ-ONLY.

    " the three elementary kinds whose JSON form is not their ABAP form
    " (ISO date/time strings, ISO timestamps) - what a caller converting a
    " scalar between the two representations has to branch on
    CLASS-DATA cv_typedescr_typekind_date    TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_time    TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_packed  TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_kind_struct      TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_kind_elem        TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_kind_ref         TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_objectdescr_public         TYPE c LENGTH 1 READ-ONLY.

    CLASS-METHODS class_constructor.

    CLASS-METHODS msg_get_t
      IMPORTING
        !val          TYPE any
        !val2         TYPE any OPTIONAL
      RETURNING
        VALUE(result) TYPE ty_t_msg.

    " depth guards the mutual recursion between these two (an include whose
    " expansion reaches itself would otherwise be an unbounded stack).
    " Optional and last in the list, so every existing caller is unaffected
    CLASS-METHODS rtti_get_t_attri_by_include
      IMPORTING
        !type         TYPE REF TO cl_abap_datadescr
        depth         TYPE i DEFAULT 0
      RETURNING
        VALUE(result) TYPE abap_component_tab.

    CLASS-METHODS expand_components
      IMPORTING
        val           TYPE abap_component_tab
        depth         TYPE i DEFAULT 0
      RETURNING
        VALUE(result) TYPE abap_component_tab.

    CLASS-METHODS itab_get_itab_by_csv
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE REF TO data.

    CLASS-METHODS itab_get_csv_by_itab
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS json_stringify
      IMPORTING
        !any          TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS xml_parse
      IMPORTING
        !xml TYPE clike
      EXPORTING
        !any TYPE any.

    CLASS-METHODS xml_stringify
      IMPORTING
        !any          TYPE any
      RETURNING
        VALUE(result) TYPE string
      RAISING
        cx_xslt_serialization_error.

    CLASS-METHODS json_parse
      IMPORTING
        val   TYPE any
      CHANGING
        !data TYPE any.

    CLASS-METHODS c_trim_upper
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS c_trim
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS rtti_get_t_attri_by_any
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE cl_abap_structdescr=>component_table.

    CLASS-METHODS rtti_create_tab_by_name
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! The name in upper case when it is a single name of a DDIC structure
    "! type - a database table or view - and empty for anything else: a
    "! dynamic FROM built from it holds no join, alias or further clause.
    "! Never raises.
    CLASS-METHODS db_get_table_name
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS rtti_check_ref_data
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS itab_corresponding
      IMPORTING
        val  TYPE STANDARD TABLE
      CHANGING
        !tab TYPE STANDARD TABLE.

    CLASS-METHODS conv_copy_ref_data
      IMPORTING
        !from         TYPE any
      RETURNING
        VALUE(result) TYPE REF TO data.

    CLASS-METHODS conv_get_xstring_by_data_uri
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE xstring.

    TYPES:
      BEGIN OF ty_s_data_uri,
        mime_type TYPE string,
        content   TYPE xstring,
      END OF ty_s_data_uri.

    "! A data URI (RFC 2397, data:[mime][;charset=...][;base64],payload) as
    "! MIME type and content: the payload base64-decoded when the header
    "! says `;base64`, otherwise percent-decoded to its bytes (text between
    "! the escapes as UTF-8). The MIME type is lower case; when the URI
    "! names none, or only application/octet-stream, it is taken from
    "! file_name (file_get_mimetype) if one is given. A bare base64 payload
    "! without the `data:...,` prefix is decoded as base64.
    CLASS-METHODS conv_get_file_by_data_uri
      IMPORTING
        val           TYPE clike
        file_name     TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE ty_s_data_uri.

    TYPES:
      BEGIN OF ty_s_sy,
        datum TYPE d,
        uzeit TYPE t,
        uname TYPE c LENGTH 12,
        sysid TYPE c LENGTH 8,
        saprl TYPE c LENGTH 4,
      END OF ty_s_sy.

    " THE one place that reads a system field for its VALUE - date, time,
    " user, system id, release. Every other class asks here
    " (sy_get( )-uname), for two reasons: ABAP for Cloud Development reports
    " the old system fields on every statement that names one ("The old
    " variant of SY-DATUM should not be used ..."), so one reader is one
    " finding per field instead of one per use; and the day one of them
    " has to come from another API, it changes here and nowhere else.
    " Not meant: sy-subrc, sy-tabix and sy-index - those are the result of
    " the statement before them and have to be read where it stands
    CLASS-METHODS sy_get
      RETURNING
        VALUE(result) TYPE ty_s_sy.

    CLASS-METHODS uuid_get_c32
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS conv_decode_x_base64
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    CLASS-METHODS conv_encode_x_base64
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS conv_get_string_by_xstring
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS conv_get_xstring_by_string
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    "! An uploaded text file: UTF-8, and Windows-1252 when the bytes are not
    "! valid UTF-8 - what Excel's plain "CSV" export writes on Windows
    CLASS-METHODS conv_get_string_by_file
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE string.

    " Every public, non-static, non-constant attribute of an exception that
    " has a printable value - the class-specific payload the text alone does
    " not carry (source/target type of a cast error, the offending value of a
    " conversion error, DB object of an SQL error, ...). The general cx_root
    " attributes (PREVIOUS, TEXTID, IS_RESUMABLE, KERNEL_ERRID) are skipped -
    " the caller renders them itself or they carry no information.
    CLASS-METHODS error_get_attributes
      IMPORTING
        val           TYPE REF TO cx_root
      RETURNING
        VALUE(result) TYPE ty_t_name_value.

    CLASS-METHODS msg_map
      IMPORTING
        name          TYPE clike
        val           TYPE data
        msg           TYPE ty_s_msg
      RETURNING
        VALUE(result) TYPE ty_s_msg.

    CLASS-METHODS file_get_mimetype
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    " The source-code position an exception was raised at, as
    " `<program> / <include> / line <n>`; empty when the runtime supplies
    " none. Wraps cx_root->get_source_position so the dependency on the SAP
    " standard exception API stays inside this class. This is what identifies
    " the failing method for exceptions that carry no text of their own -
    " a CX_SY_MOVE_CAST_ERROR only says which types did not match, the
    " position says where.
    CLASS-METHODS error_get_source_position
      IMPORTING
        val           TYPE REF TO cx_root
      RETURNING
        VALUE(result) TYPE string.

    " abap_true for values that can be rendered into a text without a
    " conversion dump - the elementary types. Anything structured (struct,
    " table, reference) must be excluded before a generic `|{ val }|`.
    CLASS-METHODS rtti_check_printable
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS rtti_get_classname_by_ref
      IMPORTING
        val           TYPE REF TO object
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS rtti_check_clike
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS rtti_get_t_attri_by_oref
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_attrdescr_tab.

    CLASS-METHODS rtti_get_type_kind
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    TYPES:
      BEGIN OF ty_s_data_element_text,
        header TYPE string,
        short  TYPE string,
        medium TYPE string,
        long   TYPE string,
      END OF ty_s_data_element_text.

    TYPES:
      BEGIN OF ty_s_zip_file,
        name    TYPE string,
        content TYPE xstring,
      END OF ty_s_zip_file.

    TYPES ty_t_zip_file TYPE STANDARD TABLE OF ty_s_zip_file WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_xml_attribute,
        name  TYPE string,
        value TYPE string,
      END OF ty_s_xml_attribute.

    TYPES ty_t_xml_attribute TYPE STANDARD TABLE OF ty_s_xml_attribute WITH DEFAULT KEY.

    CONSTANTS:
      "! the kinds of node xml_reader_next( ) hands out - `end` (initial) when
      "! the document is read to its end
      BEGIN OF cs_xml_node,
        open  TYPE string VALUE `O` ##NO_TEXT,
        close TYPE string VALUE `C` ##NO_TEXT,
        value TYPE string VALUE `V` ##NO_TEXT,
        end   TYPE string VALUE `` ##NO_TEXT,
      END OF cs_xml_node.

    " the elementary kinds a caller has to tell apart to write a value into
    " a file and to read it back (the XLSX reader and writer): text, a
    " NUMC with its leading zeros, bytes
    CLASS-DATA cv_typedescr_typekind_char    TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_num     TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_string  TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_hex     TYPE c LENGTH 1 READ-ONLY.

    CLASS-DATA cv_typedescr_typekind_xstring TYPE c LENGTH 1 READ-ONLY.

    CLASS-METHODS rtti_get_type_name
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    "! A standard table whose line is built from components - the
    "! structdescr, the tabledescr and the CREATE DATA in one call.
    "! cx_sy_struct_creation and cx_sy_table_creation reach the caller.
    "! @parameter val    | the components, e.g. from rtti_get_t_attri_by_table_name
    "! @parameter result | a reference to the new, empty table
    CLASS-METHODS rtti_create_tab_by_comps
      IMPORTING
        val           TYPE abap_component_tab
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! A standard table whose line has one string component per name - the
    "! table for a file whose columns are only known when it is read (CSV,
    "! XLSX). The names have to be valid and unique component names.
    "! @parameter val    | the component names, in the order of the columns
    "! @parameter result | a reference to the new, empty table
    CLASS-METHODS rtti_create_tab_by_names
      IMPORTING
        val           TYPE string_table
      RETURNING
        VALUE(result) TYPE REF TO data.

    CLASS-METHODS boolean_check_by_name
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS c_ends_with
      IMPORTING
        val           TYPE clike
        suffix        TYPE clike
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS conv_string_to_number
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE decfloat34.

    CLASS-METHODS rtti_get_data_element_texts
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE ty_s_data_element_text.

    CLASS-METHODS zip_pack
      IMPORTING
        !files        TYPE ty_t_zip_file
      RETURNING
        VALUE(result) TYPE xstring.

    CLASS-METHODS zip_unpack
      IMPORTING
        !val          TYPE xstring
      RETURNING
        VALUE(result) TYPE ty_t_zip_file.

    "! A reader over an XML document, node by node and without building a
    "! tree - what a large document (the sheet of a workbook) needs. The
    "! handle goes to xml_reader_next( ); it is the sXML reader, which is
    "! there on every release down to 7.02 and released on ABAP Cloud, and
    "! this class is the only one that names it. A text of blanks only
    "! arrives where it is all an element holds; the indentation between
    "! two elements is not reported
    CLASS-METHODS xml_reader_create
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE REF TO object.

    "! The next node of the document: an element opening (name, and its
    "! attributes when t_attribute is asked for), its text (value) or its
    "! end (name). Names come without their namespace prefix. kind is
    "! initial (cs_xml_node-end) behind the last node
    CLASS-METHODS xml_reader_next
      IMPORTING
        reader      TYPE REF TO object
      EXPORTING
        kind        TYPE string
        name        TYPE string
        value       TYPE string
        t_attribute TYPE ty_t_xml_attribute.

    "! Escape a text for an XML attribute value: `&`, `<`, `>`, `"` as
    "! entities, LF, CR and TAB as character references (attribute-value
    "! normalization would turn them into blanks), and the control
    "! characters XML 1.0 forbids outright dropped. Degrades when the
    "! codepage API is missing - see the method.
    CLASS-METHODS c_escape_xml
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! whether a type kind is a number: i, int1, int2, int8, p, f,
    "! decfloat16, decfloat34 - the one list the number checks share. int8
    "! by its value `8`, a constant lower releases do not have. Public for
    "! a caller that holds the type kind of a component, not its value
    CLASS-METHODS rtti_check_typekind_number
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE abap_bool.

  PROTECTED SECTION.

    CLASS-METHODS msg_get_internal
      IMPORTING
        val           TYPE any
        " the RAP-shape check of a structure is a property of its TYPE - a
        " table decides it once for its rows (msg_get_internal_tab) and hands
        " the answer down, instead of asking for every row
        iv_check_rap  TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE ty_t_msg.

    CLASS-METHODS msg_get_by_oref
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE ty_t_msg.

    CLASS-METHODS check_is_rap_struct
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS msg_get_rap
      IMPORTING
        val           TYPE any
        entity_name   TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE ty_t_msg.

    CLASS-METHODS msg_get_rap_row
      IMPORTING
        val         TYPE any
        entity_name TYPE string OPTIONAL
      EXPORTING
        messages    TYPE ty_t_msg
        is_row      TYPE abap_bool.

    CLASS-METHODS msg_get_rap_element
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS msg_get_rap_state_area
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS msg_get_rap_action
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS msg_get_rap_pid
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS msg_get_rap_cid
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS msg_get_rap_tky
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS msg_get_rap_flatten
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS get_comp_str
      IMPORTING
        val           TYPE any
        comp          TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS scan_flag_prefix
      IMPORTING
        val           TYPE any
        prefix        TYPE clike
      RETURNING
        VALUE(result) TYPE string_table.

    CLASS-METHODS msg_get_rap_meta
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE ty_t_name_value.

    CLASS-METHODS msg_get_rap_fail_text
      IMPORTING
        cause         TYPE i
      RETURNING
        VALUE(result) TYPE string.

    " The base value of an IF_ABAP_BEHV=>T_FAIL_CAUSE value, from its name;
    " -1 for a name this release does not know.
    CLASS-METHODS msg_get_rap_cause_value
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE i.

  PRIVATE SECTION.

    " the character set c_escape_xml guards against, concatenated once per
    " roll area instead of once per attribute value. Lazily filled on first
    " use - a public class_constructor is the alternative and a known trap
    CLASS-DATA gv_xml_escape_specials TYPE string.

    CLASS-DATA gv_xml_escape_controls TYPE string.

    CLASS-METHODS rtti_get_dtel_texts_by_ddic
      IMPORTING
        name        TYPE string
      EXPORTING
        texts       TYPE ty_s_data_element_text
        do_fallback TYPE abap_bool.

    CLASS-METHODS rtti_get_dtel_texts_by_xco
      IMPORTING
        name        TYPE string
      EXPORTING
        texts       TYPE ty_s_data_element_text
        do_fallback TYPE abap_bool.

    TYPES:
      BEGIN OF ty_s_attri_cache,
        absolute_name TYPE string,
        o_struct      TYPE REF TO cl_abap_structdescr,
        t_attri       TYPE cl_abap_structdescr=>component_table,
      END OF ty_s_attri_cache.

    CLASS-DATA mt_attri_cache TYPE HASHED TABLE OF ty_s_attri_cache WITH UNIQUE KEY absolute_name.

    " Guards the cycle z2ui5_cx_tcl_error=>constructor -> uuid_get_c32 ->
    " RAISE z2ui5_cx_tcl_error -> ... see uuid_get_c32.
    CLASS-DATA gv_uuid_failed TYPE abap_bool.

    "! codepage: the IANA name CL_ABAP_CONV_CODEPAGE takes; encoding: the
    "! name or SAP code page number CL_ABAP_CONV_IN_CE takes. invalid is set
    "! when a converter ran and rejected the bytes; no converter at all
    "! raises UNSUPPORTED_CODEPAGE_API
    CLASS-METHODS conv_get_string_by_xstring_cp
      IMPORTING
        val      TYPE xstring
        codepage TYPE string
        encoding TYPE string
      EXPORTING
        result   TYPE string
        invalid  TYPE abap_bool.

    " the bytes of a percent-encoded text (a data URI payload): an escape is
    " its byte, the text between escapes its UTF-8 bytes; `+` is a plus
    CLASS-METHODS conv_get_xstring_by_percent
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    " Splits CSV text into rows of cells, RFC 4180: a cell may be wrapped in
    " double quotes and then carry the separator, a line break and a doubled
    " quote. Rows end with CRLF, LF or CR. Empty rows are left out.
    TYPES ty_t_csv_rows TYPE STANDARD TABLE OF string_table WITH DEFAULT KEY.

    CLASS-METHODS csv_split_rows
      IMPORTING
        val           TYPE string
        separator     TYPE string DEFAULT `;`
      RETURNING
        VALUE(result) TYPE ty_t_csv_rows.

    " Reads a quoted cell: pos stands on the opening quote and is moved
    " behind the closing one; a doubled quote inside is one quote.
    CLASS-METHODS csv_read_quoted
      IMPORTING
        val  TYPE string
      CHANGING
        pos  TYPE i
        cell TYPE string.

    " The text without the byte order mark Excel's "CSV UTF-8" starts a
    " file with.
    CLASS-METHODS csv_strip_bom
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    " A header cell as a component name: letters, digits and underscores,
    " not empty, not starting with a digit, at most 30 characters.
    CLASS-METHODS csv_get_column_name
      IMPORTING
        val           TYPE string
        index         TYPE i
      RETURNING
        VALUE(result) TYPE string.

    " One CSV cell: wrapped in double quotes when it carries the separator,
    " a quote or a line break, quotes doubled.
    CLASS-METHODS csv_escape_cell
      IMPORTING
        val           TYPE string
        separator     TYPE string DEFAULT `;`
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS check_msg_container
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the public attributes of an object that carry a message part (TEXT,
    "! TYPE, MSGV1 ...), mapped over is_msg - see msg_map
    CLASS-METHODS msg_get_by_oref_attri
      IMPORTING
        io_obj        TYPE REF TO object
        is_msg        TYPE ty_s_msg
      RETURNING
        VALUE(result) TYPE ty_s_msg.

    "! the rows of a table, the RAP shape decided on the first structured row
    CLASS-METHODS msg_get_internal_tab
      IMPORTING
        it_tab        TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE ty_t_msg.

ENDCLASS.

CLASS z2ui5_cl_tcl_context IMPLEMENTATION.

  METHOD class_constructor.

    cv_char_util_newline        = cl_abap_char_utilities=>newline.
    cv_char_util_cr_lf          = cl_abap_char_utilities=>cr_lf.
    cv_char_util_horizontal_tab = cl_abap_char_utilities=>horizontal_tab.
    cv_char_util_charsize       = cl_abap_char_utilities=>charsize.
    cv_format_e_xml_attr        = cl_abap_format=>e_xml_attr.

    cv_typedescr_typekind_table      = cl_abap_typedescr=>typekind_table.
    cv_typedescr_typekind_dref       = cl_abap_typedescr=>typekind_dref.
    cv_typedescr_typekind_oref       = cl_abap_typedescr=>typekind_oref.
    cv_typedescr_typekind_struct1    = cl_abap_typedescr=>typekind_struct1.
    cv_typedescr_typekind_struct2    = cl_abap_typedescr=>typekind_struct2.
    cv_typedescr_typekind_date       = cl_abap_typedescr=>typekind_date.
    cv_typedescr_typekind_time       = cl_abap_typedescr=>typekind_time.
    cv_typedescr_typekind_packed     = cl_abap_typedescr=>typekind_packed.
    cv_typedescr_kind_struct         = cl_abap_typedescr=>kind_struct.
    cv_typedescr_kind_elem           = cl_abap_typedescr=>kind_elem.
    cv_typedescr_kind_ref            = cl_abap_typedescr=>kind_ref.
    cv_objectdescr_public            = cl_abap_objectdescr=>public.

    cv_typedescr_typekind_char       = cl_abap_typedescr=>typekind_char.
    cv_typedescr_typekind_num        = cl_abap_typedescr=>typekind_num.
    cv_typedescr_typekind_string     = cl_abap_typedescr=>typekind_string.
    cv_typedescr_typekind_hex        = cl_abap_typedescr=>typekind_hex.
    cv_typedescr_typekind_xstring    = cl_abap_typedescr=>typekind_xstring.
  ENDMETHOD.

  METHOD conv_copy_ref_data.

    FIELD-SYMBOLS <from>   TYPE data.
    FIELD-SYMBOLS <result> TYPE data.

    IF rtti_check_ref_data( from ) IS NOT INITIAL.
      ASSIGN from->* TO <from>.
      IF <from> IS NOT ASSIGNED.
        " unbound data reference - nothing to copy, return an initial reference
        RETURN.
      ENDIF.
    ELSE.
      ASSIGN from TO <from>.
    ENDIF.
    CREATE DATA result LIKE <from>.
    ASSIGN result->* TO <result>.

    <result> = <from>.

  ENDMETHOD.

  METHOD conv_get_xstring_by_data_uri.

    result = conv_get_file_by_data_uri( val )-content.

  ENDMETHOD.

  METHOD conv_get_file_by_data_uri.

    DATA lv_header TYPE string.
    DATA lv_data   TYPE string.

    DATA temp1 TYPE string.
    DATA lv_val LIKE temp1.
    DATA lv_base64 LIKE abap_true.
      TYPES temp3 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA lt_part TYPE temp3.
      DATA temp2 LIKE LINE OF lt_part.
      DATA lr_part LIKE REF TO temp2.
        DATA lv_part TYPE string.
    temp1 = val.

    lv_val = temp1.
    IF lv_val NS `,`.
      " a bare base64 payload, without the `data:...;base64,` prefix - the
      " SPLIT put the whole value into the metadata half and the payload
      " decoded to an empty xstring without a word
      result-content = conv_decode_x_base64( lv_val ).
      RETURN.
    ENDIF.
    SPLIT lv_val AT `,` INTO lv_header lv_data.

    " data:[<mime type>][;charset=...][;base64] - the payload used to be
    " base64-decoded whatever the header said, so a percent-encoded one
    " (`data:text/plain,a%20b`) came out as garbage

    lv_base64 = abap_true.
    IF strlen( lv_header ) >= 5 AND to_lower( lv_header(5) ) = `data:`.
      lv_base64 = abap_false.


      SPLIT substring( val = lv_header
                       off = 5 ) AT `;` INTO TABLE lt_part.


      LOOP AT lt_part REFERENCE INTO lr_part.

        lv_part = to_lower( c_trim( lr_part->* ) ).
        IF sy-tabix = 1.
          result-mime_type = lv_part.
        ELSEIF lv_part = `base64`.
          lv_base64 = abap_true.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF lv_base64 = abap_true.
      result-content = conv_decode_x_base64( lv_data ).
    ELSE.
      result-content = conv_get_xstring_by_percent( lv_data ).
    ENDIF.

    IF ( result-mime_type IS INITIAL OR result-mime_type = `application/octet-stream` )
        AND file_name IS NOT INITIAL.
      result-mime_type = file_get_mimetype( file_name ).
    ENDIF.

  ENDMETHOD.

  METHOD conv_get_xstring_by_percent.

    " the bytes as hex digits, converted in one step at the end - a byte
    " string has no expression that appends to it (see url_decode)
    DATA lv_hex TYPE string.
    DATA lv_run TYPE string.
    DATA lv_x   TYPE x LENGTH 1.

    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
      DATA lv_char TYPE string.
      DATA lv_code TYPE string.
          DATA lv_run_x TYPE xstring.
    lv_len = strlen( val ).

    lv_pos = 0.
    WHILE lv_pos < lv_len.

      lv_char = substring( val = val
                                 off = lv_pos
                                 len = 1 ).

      lv_code = ``.
      IF lv_char = `%` AND lv_pos + 2 < lv_len.
        lv_code = to_upper( substring( val = val
                                       off = lv_pos + 1
                                       len = 2 ) ).
      ENDIF.
      IF lv_code IS NOT INITIAL AND lv_code CO `0123456789ABCDEF`.
        IF lv_run IS NOT INITIAL.

          lv_run_x = conv_get_xstring_by_string( lv_run ).
          lv_hex = |{ lv_hex }{ lv_run_x }|.
          CLEAR lv_run.
        ENDIF.
        lv_x = lv_code.
        lv_hex = |{ lv_hex }{ lv_x }|.
        lv_pos = lv_pos + 3.
        CONTINUE.
      ENDIF.
      lv_run = lv_run && lv_char.
      lv_pos = lv_pos + 1.
    ENDWHILE.
    IF lv_run IS NOT INITIAL.
      lv_run_x = conv_get_xstring_by_string( lv_run ).
      lv_hex = |{ lv_hex }{ lv_run_x }|.
    ENDIF.

    result = lv_hex.

  ENDMETHOD.

  METHOD c_trim.
      DATA lv_before LIKE result.

    result = val.
    " spaces and tabs alternate at either end (`\t \tx`) - one pass of each
    " leaves the inner layer standing, so strip until nothing changes. No
    " fixed number of passes: ten left the eleventh layer of a padded value
    " standing. Every pass that changes something shortens the string, so
    " the loop ends
    DO.

      lv_before = result.
      result = shift_left( shift_right( result ) ).
      result = shift_right( val = result
                            sub = cv_char_util_horizontal_tab ).
      result = shift_left( val = result
                           sub = cv_char_util_horizontal_tab ).
      IF result = lv_before.
        EXIT.
      ENDIF.
    ENDDO.

  ENDMETHOD.

  METHOD c_trim_upper.

    result = to_upper( c_trim( val ) ).

  ENDMETHOD.

  METHOD itab_get_csv_by_itab.
    FIELD-SYMBOLS <tab>   TYPE table.
    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <field> TYPE any.
    DATA lt_lines TYPE string_table.
    DATA lt_cells TYPE string_table.
    " the component per column, empty for a column without text
    DATA lt_names TYPE string_table.
    DATA temp3 TYPE REF TO cl_abap_tabledescr.
    DATA tab LIKE temp3.
    DATA temp4 TYPE REF TO cl_abap_structdescr.
    DATA struc LIKE temp4.
    DATA temp5 TYPE abap_component_view_tab.
    DATA temp1 LIKE LINE OF temp5.
    DATA lr_comp LIKE REF TO temp1.
      DATA temp6 TYPE string.
    DATA temp2 TYPE string.
      DATA temp7 LIKE LINE OF lt_names.
      DATA lr_name LIKE REF TO temp7.
      DATA temp8 TYPE string.

    ASSIGN val TO <tab>.

    temp3 ?= cl_abap_typedescr=>describe_by_data( <tab> ).

    tab = temp3.


    temp4 ?= tab->get_table_line_type( ).

    struc = temp4.

    " the included view, not get_components( ): an include (a DDIC
    " table's .INCLUDE, an append, INCLUDE TYPE) is ONE nameless component
    " there, so the header had an empty cell where the rows had one cell
    " per field of the include, and every column behind it shifted. The
    " kind is a property of the line type - decided here once per column,
    " not described again for every cell. A table, a structure or a
    " reference has no text - in a string template it is a runtime error,
    " so its cell stays empty

    temp5 = struc->get_included_view( ).


    LOOP AT temp5 REFERENCE INTO lr_comp.
      INSERT csv_escape_cell( lr_comp->name ) INTO TABLE lt_cells.

      IF lr_comp->type->kind = cl_abap_typedescr=>kind_elem.
        temp6 = lr_comp->name.
      ELSE.
        CLEAR temp6.
      ENDIF.
      INSERT temp6 INTO TABLE lt_names.
    ENDLOOP.

    temp2 = concat_lines_of( table = lt_cells sep = `;` ).
    INSERT temp2 INTO TABLE lt_lines.

    LOOP AT <tab> ASSIGNING <row>.

      CLEAR lt_cells.


      LOOP AT lt_names REFERENCE INTO lr_name.
        IF lr_name->* IS INITIAL.
          INSERT `` INTO TABLE lt_cells.
          CONTINUE.
        ENDIF.
        ASSIGN COMPONENT lr_name->* OF STRUCTURE <row> TO <field>.
        " the value as it is - a separator, a quote or a line break inside
        " it is quoted, not replaced
        INSERT csv_escape_cell( |{ <field> }| ) INTO TABLE lt_cells.
      ENDLOOP.

      temp8 = concat_lines_of( table = lt_cells sep = `;` ).
      INSERT temp8 INTO TABLE lt_lines.
    ENDLOOP.

    result = concat_lines_of( table = lt_lines
                              sep   = cv_char_util_cr_lf ).
  ENDMETHOD.

  METHOD itab_get_itab_by_csv.
    DATA lt_comp TYPE cl_abap_structdescr=>component_table.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lr_row TYPE REF TO data.
    DATA lt_names TYPE string_table.
    FIELD-SYMBOLS <field> TYPE any.

    DATA lt_rows TYPE z2ui5_cl_tcl_context=>ty_t_csv_rows.
    DATA lt_cols LIKE LINE OF lt_rows.
    FIELD-SYMBOLS <temp2> LIKE LINE OF lt_rows.
    DATA temp3 LIKE sy-tabix.
    DATA lv_last TYPE i.
    FIELD-SYMBOLS <temp8> LIKE LINE OF lt_cols.
    DATA temp9 LIKE sy-tabix.
    DATA temp10 LIKE LINE OF lt_cols.
    DATA lr_col LIKE REF TO temp10.
      DATA lv_tabix LIKE sy-tabix.
      DATA lv_name TYPE string.
      DATA temp11 LIKE sy-subrc.
      DATA temp12 LIKE sy-tabix.
        DATA lv_suffix TYPE i.
          DATA temp13 LIKE sy-subrc.
          DATA temp14 LIKE sy-tabix.
      DATA temp15 TYPE abap_componentdescr.
    DATA struc TYPE REF TO cl_abap_structdescr.
    DATA temp16 TYPE REF TO cl_abap_datadescr.
    DATA data LIKE temp16.
    DATA o_table_desc TYPE REF TO cl_abap_tabledescr.
    DATA temp17 LIKE LINE OF lt_rows.
    DATA lr_rows LIKE REF TO temp17.
      FIELD-SYMBOLS <row> TYPE data.
      DATA lv_index TYPE i.
    lt_rows = csv_split_rows( csv_strip_bom( val ) ).
    " no row, no header to build a table from
    IF lt_rows IS INITIAL.
      RETURN.
    ENDIF.




    temp3 = sy-tabix.
    READ TABLE lt_rows INDEX 1 ASSIGNING <temp2>.
    sy-tabix = temp3.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lt_cols = <temp2>.
    " a header written with a separator behind the last column

    lv_last = lines( lt_cols ).


    IF lv_last > 1.
      temp9 = sy-tabix.
      READ TABLE lt_cols INDEX lv_last ASSIGNING <temp8>.
      sy-tabix = temp9.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
    ENDIF.
    IF lv_last > 1 AND <temp8> IS INITIAL.
      DELETE lt_cols INDEX lv_last.
    ENDIF.



    LOOP AT lt_cols REFERENCE INTO lr_col.

      lv_tabix = sy-tabix.


      lv_name = csv_get_column_name( val   = lr_col->*
                                           index = lv_tabix ).
      " a name the header carries twice - and the fallback name may be
      " taken too (`A;COL3;A`), which made the structure creation below
      " raise CX_SY_STRUCT_COMP_NAME out of the method


      temp12 = sy-tabix.
      READ TABLE lt_names WITH KEY table_line = lv_name TRANSPORTING NO FIELDS.
      temp11 = sy-subrc.
      sy-tabix = temp12.
      IF temp11 = 0.
        lv_name = |COL{ lv_tabix }|.
        " DO with an EXIT, not WHILE line_exists( ): the 7.02 downport
        " evaluates a WHILE condition with a table expression once, in
        " front of the loop, and the loop never ended

        lv_suffix = 1.
        DO.


          temp14 = sy-tabix.
          READ TABLE lt_names WITH KEY table_line = lv_name TRANSPORTING NO FIELDS.
          temp13 = sy-subrc.
          sy-tabix = temp14.
          IF NOT temp13 = 0.
            EXIT.
          ENDIF.
          lv_suffix = lv_suffix + 1.
          lv_name = |COL{ lv_tabix }_{ lv_suffix }|.
        ENDDO.
      ENDIF.
      INSERT lv_name INTO TABLE lt_names.

      " a string per column - a fixed length cut every longer value

      CLEAR temp15.
      temp15-name = lv_name.
      temp15-type = cl_abap_elemdescr=>get_string( ).
      INSERT temp15 INTO TABLE lt_comp.
    ENDLOOP.


    struc = cl_abap_structdescr=>create( lt_comp ).

    temp16 ?= struc.

    data = temp16.

    o_table_desc = cl_abap_tabledescr=>create( p_line_type  = data
                                                     p_table_kind = cl_abap_tabledescr=>tablekind_std
                                                     p_unique     = abap_false ).

    CREATE DATA result TYPE HANDLE o_table_desc.
    ASSIGN result->* TO <tab>.



    LOOP AT lt_rows REFERENCE INTO lr_rows FROM 2.

      CREATE DATA lr_row TYPE HANDLE struc.

      ASSIGN lr_row->* TO <row>.


      lv_index = 0.
      LOOP AT lr_rows->* REFERENCE INTO lr_col.
        lv_index = lv_index + 1.
        UNASSIGN <field>.
        ASSIGN COMPONENT lv_index OF STRUCTURE <row> TO <field>.
        IF <field> IS NOT ASSIGNED.
          EXIT.
        ENDIF.
        <field> = lr_col->*.
      ENDLOOP.

      INSERT <row> INTO TABLE <tab>.
    ENDLOOP.
  ENDMETHOD.

  METHOD json_parse.
        DATA temp1 TYPE REF TO z2ui5_cl_tcl_ajs.
        DATA x TYPE REF TO cx_root.
    TRY.


        temp1 = z2ui5_cl_tcl_ajs=>parse( val ).
        temp1->to_abap( EXPORTING iv_corresponding = abap_true
                                               IMPORTING ev_container     = data ).


      CATCH cx_root INTO x.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val = x.
    ENDTRY.
  ENDMETHOD.

  METHOD json_stringify.
        DATA temp18 TYPE REF TO z2ui5_if_tcl_ajs.
        DATA li_ajson LIKE temp18.
        DATA x TYPE REF TO cx_root.
    TRY.


        temp18 ?= z2ui5_cl_tcl_ajs=>create_empty( ).

        li_ajson = temp18.
        result = li_ajson->set( iv_path = `/`
                                iv_val  = any )->stringify( ).


      CATCH cx_root INTO x.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val = x.
    ENDTRY.
  ENDMETHOD.

  METHOD rtti_check_ref_data.
        DATA lo_typdescr TYPE REF TO cl_abap_typedescr.
        DATA temp19 TYPE REF TO cl_abap_refdescr.
        DATA lo_referenced TYPE REF TO cl_abap_typedescr.
        DATA temp1 TYPE xsdboolean.

    TRY.
        " a kind comparison, not a CAST probe: the cast raised
        " CX_SY_MOVE_CAST_ERROR for every NON-reference value, and the
        " non-reference is the COMMON case on this path (every value routed
        " through conv_copy_ref_data asks) - deciding a type question by
        " exception is orders of magnitude more expensive than comparing.
        " cl_abap_refdescr covers data and object references alike, and so
        " does kind_ref

        lo_typdescr = cl_abap_typedescr=>describe_by_data( val ).
        IF lo_typdescr->kind <> cl_abap_typedescr=>kind_ref.
          RETURN.
        ENDIF.
        " kind_ref covers object references too, and the one caller that
        " dereferences on a true answer (conv_copy_ref_data: `from->*`)
        " cannot do that to an object reference. Only a reference to DATA
        " answers true

        temp19 ?= lo_typdescr.

        lo_referenced = temp19->get_referenced_type( ).

        temp1 = boolc( lo_referenced->kind <> cl_abap_typedescr=>kind_class AND lo_referenced->kind <> cl_abap_typedescr=>kind_intf ).
        result = temp1.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

  METHOD rtti_get_t_attri_by_include.

    " `type` IS the include's descriptor - the component the caller took it
    " from (as_include = abap_true) carries the structure descriptor, and
    " RTTI descriptors are singletons. It used to be re-described by name,
    " an RTTI lookup per include on the binding path that could only hand
    " back the object already in hand - or fail for a local include type
    " whose absolute name does not resolve, where the direct cast cannot
    DATA sdescr TYPE REF TO cl_abap_structdescr.
        DATA lx_cast TYPE REF TO cx_sy_move_cast_error.
    TRY.
        sdescr ?= type.

      CATCH cx_sy_move_cast_error INTO lx_cast.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val      = |Include type '{ type->absolute_name }' is not a structure|
            previous = lx_cast.
    ENDTRY.
    result = expand_components( val   = sdescr->get_components( )
                                depth = depth ).

  ENDMETHOD.

  METHOD expand_components.
    DATA temp20 LIKE LINE OF val.
    DATA lr_comp LIKE REF TO temp20.
        DATA lt_include TYPE abap_component_tab.
          DATA temp21 LIKE LINE OF lt_include.
          DATA lr_include LIKE REF TO temp21.

    " see the declaration: bounded so a cyclic include chain surfaces as a
    " readable error instead of a stack-overflow dump. 16 nested include
    " levels is far beyond any real DDIC structure
    IF depth > 16.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `RTTI_INCLUDE_RECURSION - include expansion exceeded 16 levels (cyclic include?)`.
    ENDIF.



    LOOP AT val REFERENCE INTO lr_comp.
      IF lr_comp->as_include = abap_true.
        " INCLUDE ... RENAMING WITH SUFFIX: the structure's components are
        " named <component><suffix>, and every nested level adds its own -
        " the bare include names do not exist on the structure, so a
        " binding path or ASSIGN COMPONENT built from them fails

        lt_include = rtti_get_t_attri_by_include( type  = lr_comp->type
                                                        depth = depth + 1 ).
        IF lr_comp->suffix IS NOT INITIAL.


          LOOP AT lt_include REFERENCE INTO lr_include.
            lr_include->name = lr_include->name && lr_comp->suffix.
          ENDLOOP.
        ENDIF.
        INSERT LINES OF lt_include INTO TABLE result.
      ELSE.
        INSERT lr_comp->* INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD rtti_get_t_attri_by_any.

    DATA lo_struct        TYPE REF TO cl_abap_structdescr.
    DATA lo_type          TYPE REF TO cl_abap_typedescr.
    " declared, not CONV string( ) - see error_get_attributes
    DATA lv_absolute_name TYPE string.
        DATA temp22 TYPE REF TO cl_abap_structdescr.
        DATA temp23 TYPE REF TO cl_abap_structdescr.
        DATA temp4 TYPE REF TO cl_abap_tabledescr.
    FIELD-SYMBOLS <ls_attri_cache> TYPE z2ui5_cl_tcl_context=>ty_s_attri_cache.
      DATA temp24 TYPE z2ui5_cl_tcl_context=>ty_s_attri_cache.

    " describe_by_data never fails for a data object, and the reference case
    " is the one branch. The fallback chain that used to sit here - a second
    " describe_by_data_ref, then describe_by_name( val ) - could rescue no
    " input: the first only re-raised what the branch above had raised, and
    " a data object is no type name
    lo_type = cl_abap_typedescr=>describe_by_data( val ).
    IF lo_type->kind = cl_abap_typedescr=>kind_ref.
      " REFERENCE_IS_INITIAL - see rtti_get_t_attri_by_oref
      cl_abap_typedescr=>describe_by_data_ref( EXPORTING  p_data_ref           = val
                                               RECEIVING p_descr_ref           = lo_type
                                               EXCEPTIONS reference_is_initial = 1
                                                          OTHERS               = 2 ).
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val = `RTTI_REFERENCE_IS_INITIAL`.
      ENDIF.
    ENDIF.

    CASE lo_type->kind.
      WHEN cl_abap_typedescr=>kind_struct.

        temp22 ?= lo_type.
        lo_struct = temp22.
      WHEN cl_abap_typedescr=>kind_table.


        temp4 ?= lo_type.
        temp23 ?= temp4->get_table_line_type( ).
        lo_struct = temp23.
      WHEN OTHERS.
        lo_struct ?= lo_type.
    ENDCASE.

    " descriptor instances are singletons per type, so the identity check
    " guards against absolute names reused by other (local/anonymous) types
    lv_absolute_name = lo_struct->absolute_name.

    READ TABLE mt_attri_cache WITH KEY absolute_name = lv_absolute_name ASSIGNING <ls_attri_cache>.
    IF <ls_attri_cache> IS ASSIGNED AND <ls_attri_cache>-o_struct = lo_struct.
      result = <ls_attri_cache>-t_attri.
      RETURN.
    ENDIF.

    result = expand_components( lo_struct->get_components( ) ).

    IF <ls_attri_cache> IS ASSIGNED.
      <ls_attri_cache>-o_struct = lo_struct.
      <ls_attri_cache>-t_attri  = result.
    ELSE.

      CLEAR temp24.
      temp24-absolute_name = lv_absolute_name.
      temp24-o_struct = lo_struct.
      temp24-t_attri = result.
      INSERT temp24 INTO TABLE mt_attri_cache.
    ENDIF.

  ENDMETHOD.

  METHOD xml_parse.
        DATA x TYPE REF TO cx_transformation_error.

    IF xml IS INITIAL.
      CLEAR any.
      RETURN.
    ENDIF.

    " a broken document, or one written for a type that has changed since,
    " raises a static transformation error - out of a method without RAISING
    " it reached the caller as CX_SY_NO_HANDLER, which no CATCH of this
    " repository's one exception class sees
    TRY.
        CALL TRANSFORMATION id
             SOURCE XML xml
             RESULT data = any.

      CATCH cx_transformation_error INTO x.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING val      = `XML_PARSE_ERROR - the XML does not fit the target`
                    previous = x.
    ENDTRY.

  ENDMETHOD.

  METHOD xml_stringify.

    CALL TRANSFORMATION id
         SOURCE data = any
         RESULT XML result
         OPTIONS data_refs = `heap-or-create`.

  ENDMETHOD.

  METHOD itab_corresponding.

    FIELD-SYMBOLS <row_in>  TYPE any.
    FIELD-SYMBOLS <row_out> TYPE any.

    LOOP AT val ASSIGNING <row_in>.
      INSERT INITIAL LINE INTO TABLE tab ASSIGNING <row_out>.
      MOVE-CORRESPONDING <row_in> TO <row_out>.
    ENDLOOP.

  ENDMETHOD.

  METHOD msg_get_t.

    result = msg_get_internal( val ).
    IF result IS INITIAL AND val2 IS NOT INITIAL.
      result = msg_get_internal( val2 ).
    ENDIF.

  ENDMETHOD.

  METHOD rtti_create_tab_by_name.

    " type_not_found is a classic exception: called functionally, an unknown
    " name ends in a short dump no CATCH stops - so it is handled here and
    " the caller gets an unbound reference instead
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA temp25 TYPE REF TO cl_abap_datadescr.
    DATA data_desc LIKE temp25.
    DATA gr_dyntable_typ TYPE REF TO cl_abap_tabledescr.
    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = val
                                         RECEIVING  p_descr_ref    = lo_type
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    " a class or an interface of that name is no data type - the kind, not
    " IS INSTANCE OF, which the 7.02 downport cannot express
    IF lo_type->kind = cl_abap_typedescr=>kind_class OR lo_type->kind = cl_abap_typedescr=>kind_intf.
      RETURN.
    ENDIF.

    temp25 ?= lo_type.

    data_desc = temp25.

    gr_dyntable_typ = cl_abap_tabledescr=>create( data_desc ).
    CREATE DATA result TYPE HANDLE gr_dyntable_typ.

  ENDMETHOD.

  METHOD db_get_table_name.

    DATA lv_name TYPE string.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    lv_name = to_upper( condense( val ) ).
    " letters, digits, underscore and the namespace slash only - no blank,
    " so nothing after the name reaches the statement
    IF lv_name IS INITIAL OR lv_name CN `ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_/`.
      RETURN.
    ENDIF.

    " type_not_found is a classic exception - see rtti_create_tab_by_name

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = lv_name
                                         RECEIVING  p_descr_ref    = lo_type
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF lo_type->kind <> cl_abap_typedescr=>kind_struct OR lo_type->is_ddic_type( ) = abap_false.
      RETURN.
    ENDIF.

    result = lv_name.

  ENDMETHOD.

  METHOD conv_decode_x_base64.
    DATA lv_web_http_name TYPE c LENGTH 19.
    DATA classname        TYPE c LENGTH 15.
    DATA lx_first         TYPE REF TO cx_root.

    TRY.

        lv_web_http_name = `CL_WEB_HTTP_UTILITY`.
        CALL METHOD (lv_web_http_name)=>(`DECODE_X_BASE64`)
          EXPORTING
            encoded = val
          RECEIVING
            decoded = result.
        RETURN.

      CATCH cx_root INTO lx_first ##NO_HANDLER.
        " the cause is chained below if the classic API fails too - the
        " two-TRY shape of conv_get_string_by_xstring, reasoning there
    ENDTRY.

    TRY.

        classname = `CL_HTTP_UTILITY`.
        CALL METHOD (classname)=>(`DECODE_X_BASE64`)
          EXPORTING
            encoded = val
          RECEIVING
            decoded = result.

      CATCH cx_root.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val      = `UNSUPPORTED_BASE64_API - neither CL_WEB_HTTP_UTILITY nor CL_HTTP_UTILITY could decode here`
            previous = lx_first.
    ENDTRY.

  ENDMETHOD.

  METHOD conv_encode_x_base64.
    DATA lv_web_http_name TYPE c LENGTH 19.
    DATA classname        TYPE c LENGTH 15.
    DATA lx_first         TYPE REF TO cx_root.

    TRY.

        lv_web_http_name = `CL_WEB_HTTP_UTILITY`.
        CALL METHOD (lv_web_http_name)=>(`ENCODE_X_BASE64`)
          EXPORTING
            unencoded = val
          RECEIVING
            encoded   = result.
        RETURN.

      CATCH cx_root INTO lx_first ##NO_HANDLER.
        " see conv_decode_x_base64
    ENDTRY.

    TRY.

        classname = `CL_HTTP_UTILITY`.
        CALL METHOD (classname)=>(`ENCODE_X_BASE64`)
          EXPORTING
            unencoded = val
          RECEIVING
            encoded   = result.

      CATCH cx_root.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val      = `UNSUPPORTED_BASE64_API - neither CL_WEB_HTTP_UTILITY nor CL_HTTP_UTILITY could encode here`
            previous = lx_first.
    ENDTRY.

  ENDMETHOD.

  METHOD conv_get_string_by_xstring.

    DATA lv_invalid TYPE abap_bool.

    " UTF-8 through the code-page method: one implementation of the two
    " conversion APIs and their fallback, not two
    conv_get_string_by_xstring_cp( EXPORTING val      = val
                                             codepage = `UTF-8`
                                             encoding = `UTF-8`
                                   IMPORTING result   = result
                                             invalid  = lv_invalid ).
    IF lv_invalid = abap_true.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `INVALID_UTF8 - the bytes are no valid UTF-8`.
    ENDIF.

  ENDMETHOD.

  METHOD conv_get_string_by_file.

    DATA lv_invalid TYPE abap_bool.

    conv_get_string_by_xstring_cp( EXPORTING val      = val
                                             codepage = `UTF-8`
                                             encoding = `UTF-8`
                                   IMPORTING result   = result
                                             invalid  = lv_invalid ).
    IF lv_invalid = abap_false.
      RETURN.
    ENDIF.

    " Not valid UTF-8: Excel's plain "CSV" export on Windows writes
    " Windows-1252 (SAP code page 1160), and an umlaut is then a single byte
    " no UTF-8 decoder accepts. Only a conversion error gets here - a
    " missing codepage API left conv_get_string_by_xstring_cp with its own
    " UNSUPPORTED_CODEPAGE_API above
    TRY.
        conv_get_string_by_xstring_cp( EXPORTING val      = val
                                                 codepage = `windows-1252`
                                                 encoding = `1160`
                                       IMPORTING result   = result
                                                 invalid  = lv_invalid ).
      CATCH z2ui5_cx_tcl_error.
        " neither API knows Windows-1252 here
        lv_invalid = abap_true.
    ENDTRY.

    IF lv_invalid = abap_true.
      CLEAR result.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = |UNSUPPORTED_ENCODING - the file is neither UTF-8 nor Windows-1252, | &&
                |save it as "CSV UTF-8" and upload it again|.
    ENDIF.

  ENDMETHOD.

  METHOD conv_get_string_by_xstring_cp.

    DATA conv          TYPE REF TO object.
    DATA conv_codepage TYPE c LENGTH 21.
    DATA conv_in_class TYPE c LENGTH 18.
    DATA lv_encoding   TYPE c LENGTH 20.
    DATA lx_first      TYPE REF TO cx_root.

    CLEAR result.
    invalid = abap_false.

    TRY.

        conv_codepage = `CL_ABAP_CONV_CODEPAGE`.
        CALL METHOD (conv_codepage)=>create_in
          EXPORTING
            codepage = codepage
          RECEIVING
            instance = conv.

        CALL METHOD conv->(`IF_ABAP_CONV_IN~CONVERT`)
          EXPORTING
            source = val
          RECEIVING
            result = result.
        RETURN.

      CATCH cx_sy_conversion_codepage.
        " the API is there and the bytes are not valid in this code page -
        " the classic API would reject them too
        CLEAR result.
        invalid = abap_true.
        RETURN.

      CATCH cx_root INTO lx_first ##NO_HANDLER.
        " deliberate: capturing the cause IS the handling - it is chained into
        " UNSUPPORTED_CODEPAGE_API below if the classic API fails too. Falling
        " through is the point; the modern class is absent on older releases,
        " which is the whole reason both paths exist. A code page the modern
        " class does not know (CX_PARAMETER_INVALID_RANGE) falls through too
    ENDTRY.

    " The classic API. Guarded by its own TRY since 2026-09: it used to be the
    " BODY of the CATCH above, so when it failed too the dynamic-call
    " exception left this method raw. On a release that has neither class -
    " and in any runtime that is not an SAP system, where a dynamic
    " CALL METHOD resolves nothing - that reached the caller as
    " CX_SY_DYN_CALL_ILLEGAL_CLASS, which nothing here catches by name.
    " The view builder is one of those callers and builds its
    " control-character set through this method, so a missing codepage class
    " took down every view render with an exception that named a kernel
    " class rather than the framework.
    TRY.

        conv_in_class = `CL_ABAP_CONV_IN_CE`.
        lv_encoding = encoding.
        CALL METHOD (conv_in_class)=>create
          EXPORTING
            encoding = lv_encoding
          RECEIVING
            conv     = conv.

        CALL METHOD conv->(`CONVERT`)
          EXPORTING
            input = val
          IMPORTING
            data  = result.

      CATCH cx_sy_conversion_codepage.
        CLEAR result.
        invalid = abap_true.

      CATCH cx_root.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val      = |UNSUPPORTED_CODEPAGE_API - neither CL_ABAP_CONV_CODEPAGE | &&
                       |nor CL_ABAP_CONV_IN_CE could convert here|
            previous = lx_first.
    ENDTRY.

  ENDMETHOD.

  METHOD conv_get_xstring_by_string.

    DATA conv           TYPE REF TO object.
    DATA conv_codepage  TYPE c LENGTH 21.
    DATA conv_out_class TYPE c LENGTH 19.
    DATA lx_first       TYPE REF TO cx_root.

    TRY.

        conv_codepage = `CL_ABAP_CONV_CODEPAGE`.
        CALL METHOD (conv_codepage)=>create_out
          RECEIVING
            instance = conv.

        CALL METHOD conv->(`IF_ABAP_CONV_OUT~CONVERT`)
          EXPORTING
            source = val
          RECEIVING
            result = result.
        RETURN.

      CATCH cx_root INTO lx_first ##NO_HANDLER.
        " deliberate, same as conv_get_string_by_xstring: the capture is the
        " handling, the fall-through is the point
    ENDTRY.

    " Guarded for the same reason as its counterpart above: an unguarded
    " fallback let a raw dynamic-call exception out of a utility method.
    TRY.

        conv_out_class = `CL_ABAP_CONV_OUT_CE`.
        CALL METHOD (conv_out_class)=>create
          EXPORTING
            encoding = `UTF-8`
          RECEIVING
            conv     = conv.

        CALL METHOD conv->(`CONVERT`)
          EXPORTING
            data   = val
          IMPORTING
            buffer = result.

      CATCH cx_root.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val      = |UNSUPPORTED_CODEPAGE_API - neither CL_ABAP_CONV_CODEPAGE | &&
                       |nor CL_ABAP_CONV_OUT_CE could convert here|
            previous = lx_first.
    ENDTRY.

  ENDMETHOD.

  METHOD sy_get.

    result-datum = sy-datum.
    result-uzeit = sy-uzeit.
    result-uname = sy-uname.
    result-sysid = sy-sysid.
    result-saprl = sy-saprl.

  ENDMETHOD.

  METHOD uuid_get_c32.
    DATA lv_uuid      TYPE c LENGTH 32.
    DATA lv_classname TYPE string.
    DATA lv_fm        TYPE string.
        DATA lx_uuid TYPE REF TO cx_root.

    TRY.

        TRY.

            lv_classname = `CL_SYSTEM_UUID`.
            CALL METHOD (lv_classname)=>if_system_uuid_static~create_uuid_c32
              RECEIVING
                uuid = lv_uuid.

          CATCH cx_root.

            lv_fm = `GUID_CREATE`.
            " error_message: a message the module sends would otherwise end
            " the request, which no CATCH reaches
            CALL FUNCTION lv_fm
              IMPORTING
                ev_guid_32    = lv_uuid
              EXCEPTIONS
                error_message = 1
                OTHERS        = 2.
            IF sy-subrc <> 0.
              RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
                EXPORTING
                  val = `GUID_CREATE_FAILED`.
            ENDIF.

        ENDTRY.

        result = lv_uuid.


      CATCH cx_root INTO lx_uuid.
        " both UUID mechanisms failed - raise the framework exception so the
        " consumer's single top-level catch can turn it into a handled error.
        " ASSERT would raise the uncatchable ASSERTION_FAILED and bypass that
        " catch (short dump instead of a handled error response).
        " z2ui5_cx_tcl_error reads a uuid when it renders its full report,
        " so a renderer running while the raise below is on its way would
        " re-enter this method. gv_uuid_failed makes that nested call return an
        " empty UUID instead of raising again.
        IF gv_uuid_failed = abap_true.
          RETURN.
        ENDIF.
        gv_uuid_failed = abap_true.
        TRY.
            RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
              EXPORTING
                val = lx_uuid.
          CLEANUP.
            CLEAR gv_uuid_failed.
        ENDTRY.
    ENDTRY.
  ENDMETHOD.

  METHOD msg_get_internal.
        FIELD-SYMBOLS <tab> TYPE ANY TABLE.
        DATA lt_attri TYPE abap_component_tab.
        DATA temp26 TYPE ty_s_msg.
        DATA ls_result LIKE temp26.
        DATA temp27 LIKE LINE OF lt_attri.
        DATA ls_attri LIKE REF TO temp27.
          FIELD-SYMBOLS <comp> TYPE any.
          DATA temp28 TYPE z2ui5_cl_tcl_context=>ty_s_msg.

    CASE rtti_get_type_kind( val ).

      WHEN cl_abap_datadescr=>typekind_table.

        " guarded like data_render_tab and data_get_headline - handing an
        " UNASSIGNED symbol to the method below is a GETWA_NOT_ASSIGNED
        " dump. No messages then, which is what "nothing in here is a
        " message" means to the caller: it falls back to the data renderer
        ASSIGN val TO <tab>.
        IF <tab> IS NOT ASSIGNED.
          RETURN.
        ENDIF.
        result = msg_get_internal_tab( <tab> ).

      WHEN cl_abap_datadescr=>typekind_struct1 OR cl_abap_datadescr=>typekind_struct2.

        IF val IS INITIAL.
          RETURN.
        ENDIF.

        IF iv_check_rap = abap_true AND check_is_rap_struct( val ) = abap_true.
          result = msg_get_rap( val ).
          RETURN.
        ENDIF.


        lt_attri = rtti_get_t_attri_by_any( val ).


        CLEAR temp26.

        ls_result = temp26.


        LOOP AT lt_attri REFERENCE INTO ls_attri.

          ASSIGN COMPONENT ls_attri->name OF STRUCTURE val TO <comp>.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.

          " only an ITEM that can HOLD messages is the envelope's payload -
          " a table, a structure or an object (the BALI item). A plain
          " ITEM field (a position number) became the whole message and
          " dropped the structure's other fields
          IF ls_attri->name = `ITEM` AND check_msg_container( <comp> ) = abap_true.
            result = msg_get_internal( <comp> ).
            RETURN.
          ENDIF.
          ls_result = msg_map( name = ls_attri->name
                               val  = <comp>
                               msg  = ls_result ).

        ENDLOOP.
        " a T100 message is a class AND a number. A component called ID
        " alone is the key column of any business row - built into a
        " message, it gave `I:0001:` (a missing class still answers a text)
        " and the data never reached the data renderer it was meant for
        IF ls_result-text IS INITIAL AND ls_result-id IS NOT INITIAL AND ls_result-no IS NOT INITIAL.
          ls_result-id = to_upper( ls_result-id ).
          MESSAGE ID ls_result-id TYPE `I` NUMBER ls_result-no
                  WITH ls_result-v1 ls_result-v2 ls_result-v3 ls_result-v4
                  INTO ls_result-text.
        ENDIF.
        INSERT ls_result INTO TABLE result.

      WHEN cl_abap_datadescr=>typekind_oref.
        " an unbound reference carries no message - guarded like the struct
        " and table branches guard theirs. Unguarded it fell through the
        " three handlers of msg_get_by_oref into a describe on the null
        " reference, and message_box_display( unbound ) ended in a 500
        " instead of the documented silence
        IF val IS NOT INITIAL.
          result = msg_get_by_oref( val ).
        ENDIF.

      WHEN OTHERS.

        " skip an empty character value like the struct branch does -
        " otherwise msg_get_t's val2 fallback can never take over and the
        " caller renders a message box with blank text
        IF rtti_check_clike( val ) IS NOT INITIAL AND val IS NOT INITIAL.

          CLEAR temp28.
          temp28-text = val.
          INSERT temp28 INTO TABLE result.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD msg_get_by_oref.
        DATA temp29 TYPE REF TO cx_root.
        DATA lx LIKE temp29.
        DATA temp30 TYPE z2ui5_cl_tcl_context=>ty_s_msg.
    DATA obj TYPE REF TO object.
    DATA lr_tab TYPE REF TO data.
    FIELD-SYMBOLS <tab> TYPE any.
    DATA temp31 TYPE z2ui5_cl_tcl_context=>ty_s_msg.

    " four shapes, tried in turn and each on its own level - the nested
    " TRY/CATCH pyramid this used to be carried the attribute mapping twice,
    " three CATCH blocks deep, one fix away from drifting. Every attempt
    " that fails falls through to the next; the last one cannot fail
    " quietly, it maps whatever public attributes the object has

    " 1. an exception: its text, and its public attributes over it
    TRY.

        temp29 ?= val.

        lx = temp29.

        CLEAR temp30.
        temp30-type = `E`.
        temp30-text = lx->get_text( ).
        INSERT msg_get_by_oref_attri( io_obj = lx
                                      is_msg = temp30 ) INTO TABLE result.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.


    obj = val.



    " 2. an application log (IF_BALI_LOG)
    TRY.
        CREATE DATA lr_tab TYPE (`if_bali_log=>ty_item_table`).
        ASSIGN lr_tab->* TO <tab>.
        CALL METHOD obj->(`IF_BALI_LOG~GET_ALL_ITEMS`)
          RECEIVING
            item_table = <tab>.
        INSERT LINES OF msg_get_internal( <tab> ) INTO TABLE result.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

    " 3. a logger (ZIF_LOGGER)
    TRY.
        CREATE DATA lr_tab TYPE (`BAPIRETTAB`).
        ASSIGN lr_tab->* TO <tab>.
        CALL METHOD obj->(`ZIF_LOGGER~EXPORT_TO_TABLE`)
          RECEIVING
            rt_bapiret = <tab>.
        INSERT LINES OF msg_get_internal( <tab> ) INTO TABLE result.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

    " 4. any object: whatever public attributes carry a message part

    CLEAR temp31.
    INSERT msg_get_by_oref_attri( io_obj = obj
                                  is_msg = temp31 ) INTO TABLE result.

  ENDMETHOD.

  METHOD msg_map.

    result = msg.

    " The value is a component of an ARBITRARY structure: msg_get_internal
    " walks whatever an app hands to message_box_display( ) and maps every
    " component BY NAME. A business structure with a component that happens
    " to be called TEXT, ID, TYPE or V1 and is a TABLE, a nested structure
    " or a reference is not a message part - and the assignments below are
    " no class-based exception for it, they are a MOVE type conflict
    " (OBJECTS_MOVE_NOT_SUPPORTED on a system, "table, no header line" in
    " the transpiled runtime). So the box that was supposed to REPORT a
    " problem was the crash: nothing between here and the app's own main( )
    " catches it, and the roundtrip ended as a 500.
    " Decided BEFORE anything is assigned, which is the same rule
    " z2ui5_cl_ui5_srv_model=>delta_apply_field follows for the same reason
    " - a runtime error cannot be caught after the fact. A skipped component
    " simply is not a message part: the entry ends up without a text,
    " ui5_msg_box_format drops it, and the caller falls back to the DATA
    " renderer, which shows the whole structure including that component
    IF rtti_check_printable( val ) = abap_false.
      RETURN.
    ENDIF.

    CASE name.
      WHEN `ID` OR `MSGID` OR `ARBGB`.
        result-id = val.
      WHEN `NO` OR `NUMBER` OR `MSGNO` OR `TXTNR`.
        result-no = val.
      WHEN `MESSAGE` OR `TEXT`.
        result-text = val.
      WHEN `TYPE` OR `MSGTY` OR `M_SEVERITY`.
        result-type = val.
      WHEN `MESSAGE_V1` OR `MSGV1` OR `V1`.
        result-v1 = val.
      WHEN `MESSAGE_V2` OR `MSGV2` OR `V2`.
        result-v2 = val.
      WHEN `MESSAGE_V3` OR `MSGV3` OR `V3`.
        result-v3 = val.
      WHEN `MESSAGE_V4` OR `MSGV4` OR `V4`.
        result-v4 = val.
      WHEN `TIME_STMP`.
        " the one target that is not a string: a printable but non-numeric
        " value (`2026-09-16 10:00` in a char field of that name) converts
        " into the packed timestamp with CX_SY_CONVERSION_NO_NUMBER, which
        " is catchable where the MOVE conflict above is not - caught, and
        " the entry keeps no timestamp rather than costing the whole box
        TRY.
            result-timestampl = val.
          CATCH cx_root ##NO_HANDLER.
        ENDTRY.
    ENDCASE.

  ENDMETHOD.

  METHOD check_is_rap_struct.

    DATA lt_attri TYPE abap_component_tab.
    DATA temp32 LIKE LINE OF lt_attri.
    DATA ls_attri LIKE REF TO temp32.
          DATA temp33 TYPE REF TO cl_abap_tabledescr.
          DATA lo_line TYPE REF TO cl_abap_datadescr.
          DATA temp34 TYPE REF TO cl_abap_structdescr.
          DATA lt_comps TYPE abap_component_tab.
          DATA temp35 LIKE LINE OF lt_comps.
          DATA ls_comp LIKE REF TO temp35.
    lt_attri = rtti_get_t_attri_by_any( val ).



    LOOP AT lt_attri REFERENCE INTO ls_attri.
      CASE ls_attri->name.
        WHEN `%MSG` OR `%FAIL` OR `%OTHER`.
          result = abap_true.
          RETURN.
      ENDCASE.
    ENDLOOP.

    LOOP AT lt_attri REFERENCE INTO ls_attri.
      " the component's descriptor is already in the attribute table - no
      " ASSIGN and no describe_by_data per component
      IF ls_attri->type->kind <> cl_abap_typedescr=>kind_table.
        CONTINUE.
      ENDIF.

      TRY.

          temp33 ?= ls_attri->type.

          lo_line = temp33->get_table_line_type( ).
          IF lo_line->kind <> cl_abap_typedescr=>kind_struct.
            CONTINUE.
          ENDIF.

          temp34 ?= lo_line.

          lt_comps = temp34->get_components( ).


          LOOP AT lt_comps REFERENCE INTO ls_comp.
            IF ls_comp->name = `%MSG` OR ls_comp->name = `%FAIL`.
              result = abap_true.
              RETURN.
            ENDIF.
          ENDLOOP.
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
    ENDLOOP.

  ENDMETHOD.

  METHOD msg_get_rap.

    DATA lv_kind TYPE string.
    DATA lv_is_row TYPE abap_bool.
    DATA lt_attri TYPE abap_component_tab.
    DATA temp36 LIKE LINE OF lt_attri.
    DATA ls_attri LIKE REF TO temp36.
      FIELD-SYMBOLS <tab> TYPE any.
      FIELD-SYMBOLS <ftab> TYPE ANY TABLE.
      DATA temp37 TYPE REF TO cl_abap_tabledescr.
      DATA lo_line TYPE REF TO cl_abap_datadescr.
      FIELD-SYMBOLS <row> TYPE ANY.
    lv_kind = rtti_get_type_kind( val ).
    IF lv_kind <> cl_abap_datadescr=>typekind_struct1
        AND lv_kind <> cl_abap_datadescr=>typekind_struct2.
      RETURN.
    ENDIF.


    msg_get_rap_row( EXPORTING val         = val
                               entity_name = entity_name
                     IMPORTING messages    = result
                               is_row      = lv_is_row ).
    IF lv_is_row = abap_true.
      RETURN.
    ENDIF.


    lt_attri = rtti_get_t_attri_by_any( val ).


    LOOP AT lt_attri REFERENCE INTO ls_attri.

      ASSIGN COMPONENT ls_attri->name OF STRUCTURE val TO <tab>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF rtti_get_type_kind( <tab> ) <> cl_abap_datadescr=>typekind_table.
        CONTINUE.
      ENDIF.

      " guarded like data_render_tab, msg_get_internal and
      " data_get_headline - and here the symbol is LOOP-CARRIED, so an
      " ASSIGN that fails leaves it on the PREVIOUS component's table and
      " the rows below would be read out of that one

      UNASSIGN <ftab>.
      ASSIGN <tab> TO <ftab>.
      IF <ftab> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      " the row kind is a property of the table TYPE - decided once per
      " table, not asked of every row (same idea as msg_get_internal_tab)

      temp37 ?= ls_attri->type.

      lo_line = temp37->get_table_line_type( ).

      LOOP AT <ftab> ASSIGNING <row>.
        IF lo_line->type_kind = cl_abap_datadescr=>typekind_oref.
          IF <row> IS NOT INITIAL.
            TRY.
                INSERT LINES OF msg_get_t( <row> ) INTO TABLE result.
              CATCH cx_root ##NO_HANDLER.
            ENDTRY.
          ENDIF.
        ELSE.
          INSERT LINES OF msg_get_rap( val         = <row>
                                       entity_name = ls_attri->name ) INTO TABLE result.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD msg_get_rap_row.
    DATA lv_meta_built TYPE abap_bool.
    DATA lt_meta TYPE ty_t_name_value.
    FIELD-SYMBOLS <msg> TYPE any.
            DATA lt_one TYPE z2ui5_cl_tcl_context=>ty_t_msg.
            FIELD-SYMBOLS <m> LIKE LINE OF lt_one.
    FIELD-SYMBOLS <fail> TYPE any.
      FIELD-SYMBOLS <cause> TYPE any.
        DATA lv_cause TYPE i.
        DATA lv_text TYPE string.
        DATA temp38 TYPE z2ui5_cl_tcl_context=>ty_s_msg.
    CLEAR messages.
    is_row = abap_false.

    " the meta block is built LAZILY: msg_get_rap_meta walks the row's
    " components three times over (element/action/tky scans), and the
    " common row in a RAP response table carries neither a filled %MSG nor
    " a %FAIL - building the block up front threw that work away per row




    ASSIGN COMPONENT `%MSG` OF STRUCTURE val TO <msg>.
    IF sy-subrc = 0.
      is_row = abap_true.
      IF <msg> IS NOT INITIAL.
        lt_meta = msg_get_rap_meta( val ).
        lv_meta_built = abap_true.
        TRY.

            lt_one = msg_get_t( <msg> ).

            LOOP AT lt_one ASSIGNING <m>.
              <m>-t_meta = lt_meta.
            ENDLOOP.
            INSERT LINES OF lt_one INTO TABLE messages.
          CATCH cx_root ##NO_HANDLER.
        ENDTRY.
      ENDIF.
    ENDIF.


    ASSIGN COMPONENT `%FAIL` OF STRUCTURE val TO <fail>.
    IF sy-subrc = 0.
      is_row = abap_true.

      ASSIGN COMPONENT `CAUSE` OF STRUCTURE <fail> TO <cause>.
      IF sy-subrc = 0.
        IF lv_meta_built = abap_false.
          lt_meta = msg_get_rap_meta( val ).
        ENDIF.
        " %FAIL-CAUSE is the enumeration IF_ABAP_BEHV=>T_FAIL_CAUSE (base
        " type i). An enumerated value does not convert to i - a plain MOVE
        " is the runtime error UC_OBJECTS_NOT_CONVERTIBLE - so it is read by
        " its name (a string template writes the name) and mapped to the
        " base value. Type kind `k` is the enumeration (literal: the
        " constant typekind_enum does not exist on 7.02).

        IF cl_abap_typedescr=>describe_by_data( <cause> )->type_kind = `k`.
          lv_cause = msg_get_rap_cause_value( |{ <cause> }| ).
        ELSE.
          lv_cause = <cause>.
        ENDIF.

        lv_text = msg_get_rap_fail_text( lv_cause ).
        IF entity_name IS NOT INITIAL.
          lv_text = |{ entity_name }: { lv_text }|.
        ENDIF.

        CLEAR temp38.
        temp38-type = `E`.
        temp38-text = lv_text.
        temp38-t_meta = lt_meta.
        INSERT temp38 INTO TABLE messages.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD get_comp_str.

    " printable first, then the assignment: the component comes out of a
    " structure this class did not declare, and a table or a nested
    " structure into a string is a MOVE type conflict, not an exception -
    " see msg_map, which learnt it the expensive way.
    " One chained AND and not the nested IFs z2ui5_cl_ui5_handler=>
    " request_context_info argues for: abaplint's if_in_if refuses the
    " nesting here (nothing sits between the two tests), and the second
    " operand is safe on a failed ASSIGN either way - ABAP evaluates a
    " logical expression left to right and stops once the result is decided
    FIELD-SYMBOLS <comp> TYPE any.
    ASSIGN COMPONENT comp OF STRUCTURE val TO <comp>.
    IF sy-subrc = 0 AND rtti_check_printable( <comp> ) = abap_true.
      result = <comp>.
    ENDIF.

  ENDMETHOD.

  METHOD scan_flag_prefix.

    DATA lv_kind TYPE string.
    DATA temp39 TYPE string.
    DATA lv_prefix LIKE temp39.
    DATA lv_off TYPE i.
      FIELD-SYMBOLS <sub> TYPE any.
    DATA lv_len TYPE i.
    DATA lt_attri TYPE abap_component_tab.
    DATA temp40 LIKE LINE OF lt_attri.
    DATA ls_attri LIKE REF TO temp40.
      FIELD-SYMBOLS <flag> TYPE any.
    lv_kind = rtti_get_type_kind( val ).
    IF lv_kind <> cl_abap_datadescr=>typekind_struct1
        AND lv_kind <> cl_abap_datadescr=>typekind_struct2.
      RETURN.
    ENDIF.

    " a `-` in the prefix is a path, not part of a component name - no
    " component name can contain one: %ELEMENT-<field> and
    " %OP-%ACTION-<name> are components of the NESTED structures %ELEMENT
    " and %OP-%ACTION. Compared against the row's own component names, the
    " two RAP prefixes never matched, and no message ever carried its
    " element or action

    temp39 = prefix.

    lv_prefix = temp39.

    lv_off = find( val = lv_prefix
                         sub = `-` ).
    IF lv_off >= 0.

      ASSIGN COMPONENT lv_prefix(lv_off) OF STRUCTURE val TO <sub>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      result = scan_flag_prefix( val    = <sub>
                                 prefix = substring( val = lv_prefix
                                                     off = lv_off + 1 ) ).
      RETURN.
    ENDIF.


    lv_len = strlen( lv_prefix ).

    lt_attri = rtti_get_t_attri_by_any( val ).


    LOOP AT lt_attri REFERENCE INTO ls_attri.
      IF strlen( ls_attri->name ) <= lv_len.
        CONTINUE.
      ENDIF.
      IF NOT ( lv_len = 0 OR ls_attri->name(lv_len) = lv_prefix ).
        CONTINUE.
      ENDIF.

      ASSIGN COMPONENT ls_attri->name OF STRUCTURE val TO <flag>.
      IF sy-subrc <> 0 OR <flag> IS INITIAL.
        CONTINUE.
      ENDIF.
      INSERT ls_attri->name+lv_len INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD msg_get_rap_element.

    DATA lt_suffix TYPE string_table.
    lt_suffix = scan_flag_prefix( val       = val
                                        prefix = `%ELEMENT-` ).
    result = concat_lines_of( table = lt_suffix
                              sep   = `, ` ).

  ENDMETHOD.

  METHOD msg_get_rap_state_area.

    result = get_comp_str( val     = val
                           comp = `%STATE_AREA` ).

  ENDMETHOD.

  METHOD msg_get_rap_action.

    DATA lt_suffix TYPE string_table.
    DATA temp41 TYPE string.
    DATA temp42 TYPE string.
    lt_suffix = scan_flag_prefix( val       = val
                                        prefix = `%OP-%ACTION-` ).

    CLEAR temp41.

    READ TABLE lt_suffix INTO temp42 INDEX 1.
    IF sy-subrc = 0.
      temp41 = temp42.
    ENDIF.
    result = temp41.

  ENDMETHOD.

  METHOD msg_get_rap_pid.

    result = get_comp_str( val     = val
                           comp = `%PID` ).

  ENDMETHOD.

  METHOD msg_get_rap_cid.

    result = get_comp_str( val     = val
                           comp = `%CID` ).

  ENDMETHOD.

  METHOD msg_get_rap_tky.

    FIELD-SYMBOLS <tky> TYPE any.
    ASSIGN COMPONENT `%TKY` OF STRUCTURE val TO <tky>.
    IF sy-subrc <> 0 OR <tky> IS INITIAL.
      RETURN.
    ENDIF.
    result = msg_get_rap_flatten( <tky> ).

  ENDMETHOD.

  METHOD msg_get_rap_flatten.

    DATA lv_kind TYPE string.
    DATA lt_attri TYPE abap_component_tab.
    DATA lt_part TYPE string_table.
    DATA temp43 LIKE LINE OF lt_attri.
    DATA ls_attri LIKE REF TO temp43.
      FIELD-SYMBOLS <comp> TYPE any.
      DATA lv_sub_kind TYPE string.
        DATA lv_sub TYPE string.
            DATA lv_str TYPE string.
            DATA temp44 LIKE LINE OF lt_part.
    lv_kind = rtti_get_type_kind( val ).
    IF lv_kind <> cl_abap_datadescr=>typekind_struct1
        AND lv_kind <> cl_abap_datadescr=>typekind_struct2.
      RETURN.
    ENDIF.


    lt_attri = rtti_get_t_attri_by_any( val ).




    LOOP AT lt_attri REFERENCE INTO ls_attri.

      ASSIGN COMPONENT ls_attri->name OF STRUCTURE val TO <comp>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.


      lv_sub_kind = rtti_get_type_kind( <comp> ).
      IF lv_sub_kind = cl_abap_datadescr=>typekind_struct1
          OR lv_sub_kind = cl_abap_datadescr=>typekind_struct2.

        lv_sub = msg_get_rap_flatten( <comp> ).
        IF lv_sub IS NOT INITIAL.
          INSERT lv_sub INTO TABLE lt_part.
        ENDIF.
      ELSEIF <comp> IS NOT INITIAL AND rtti_check_printable( <comp> ) = abap_true.
        " the printable test does what the TRY around this could not: a
        " TABLE component into the string below is a MOVE type conflict and
        " therefore a runtime error, which no CATCH takes (see msg_map). The
        " TRY stays for the conversions that ARE class-based - a character
        " value the packed/numeric target refuses
        TRY.

            lv_str = <comp>.

            temp44 = |{ ls_attri->name }={ lv_str }|.
            INSERT temp44 INTO TABLE lt_part.
          CATCH cx_root ##NO_HANDLER.
        ENDTRY.
      ENDIF.
    ENDLOOP.

    result = concat_lines_of( table = lt_part
                              sep   = `, ` ).

  ENDMETHOD.

  METHOD msg_get_rap_meta.

    DATA lv TYPE string.
      DATA temp45 TYPE z2ui5_cl_tcl_context=>ty_s_name_value.
      DATA temp46 TYPE z2ui5_cl_tcl_context=>ty_s_name_value.
      DATA temp47 TYPE z2ui5_cl_tcl_context=>ty_s_name_value.
      DATA temp48 TYPE z2ui5_cl_tcl_context=>ty_s_name_value.
      DATA temp49 TYPE z2ui5_cl_tcl_context=>ty_s_name_value.
      DATA temp50 TYPE z2ui5_cl_tcl_context=>ty_s_name_value.

    lv = msg_get_rap_element( val ).
    IF lv IS NOT INITIAL.

      CLEAR temp45.
      temp45-n = `element`.
      temp45-v = lv.
      INSERT temp45 INTO TABLE result.
    ENDIF.

    lv = msg_get_rap_state_area( val ).
    IF lv IS NOT INITIAL.

      CLEAR temp46.
      temp46-n = `state_area`.
      temp46-v = lv.
      INSERT temp46 INTO TABLE result.
    ENDIF.

    lv = msg_get_rap_action( val ).
    IF lv IS NOT INITIAL.

      CLEAR temp47.
      temp47-n = `action`.
      temp47-v = lv.
      INSERT temp47 INTO TABLE result.
    ENDIF.

    lv = msg_get_rap_pid( val ).
    IF lv IS NOT INITIAL.

      CLEAR temp48.
      temp48-n = `pid`.
      temp48-v = lv.
      INSERT temp48 INTO TABLE result.
    ENDIF.

    lv = msg_get_rap_cid( val ).
    IF lv IS NOT INITIAL.

      CLEAR temp49.
      temp49-n = `cid`.
      temp49-v = lv.
      INSERT temp49 INTO TABLE result.
    ENDIF.

    lv = msg_get_rap_tky( val ).
    IF lv IS NOT INITIAL.

      CLEAR temp50.
      temp50-n = `tky`.
      temp50-v = lv.
      INSERT temp50 INTO TABLE result.
    ENDIF.

  ENDMETHOD.

  METHOD msg_get_rap_fail_text.
    " the base values of IF_ABAP_BEHV=>T_FAIL_CAUSE, read on an S/4HANA
    " system (2026-11-13) - HTTP-like codes, not a running number
    DATA temp51 TYPE string.
    CASE cause.
      WHEN 0.
        temp51 = `Operation failed`.
      WHEN 401.
        temp51 = `Authorization failure`.
      WHEN 404.
        temp51 = `Entity not found`.
      WHEN 409.
        temp51 = `Concurrent modification`.
      WHEN 423.
        temp51 = `Entity is locked`.
      WHEN 424.
        temp51 = `Dependent operation failed`.
      WHEN 501.
        temp51 = `Operation not implemented`.
      WHEN 4221.
        temp51 = `Operation disabled`.
      WHEN 4222.
        temp51 = `Entity is read-only`.
      WHEN OTHERS.
        temp51 = |Operation failed (cause code { cause })|.
    ENDCASE.
    result = temp51.
  ENDMETHOD.

  METHOD file_get_mimetype.

    DATA lv_name TYPE string.
    TYPES temp4 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA lt_parts TYPE temp4.
    DATA lv_ext LIKE LINE OF lt_parts.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_parts.
    DATA temp6 LIKE sy-tabix.
    lv_name = to_lower( c_trim( val ) ).


    SPLIT lv_name AT `.` INTO TABLE lt_parts.
    " no name, no extension - an empty name splits into no part at all
    IF lt_parts IS INITIAL.
      result = `application/octet-stream`.
      RETURN.
    ENDIF.



    temp6 = sy-tabix.
    READ TABLE lt_parts INDEX lines( lt_parts ) ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lv_ext = <temp5>.

    CASE lv_ext.
      WHEN `txt` OR `text` OR `log` OR `md`.
        result = `text/plain`.
      WHEN `html` OR `htm`.
        result = `text/html`.
      WHEN `css`.
        result = `text/css`.
      WHEN `csv`.
        result = `text/csv`.
      WHEN `js` OR `mjs`.
        result = `text/javascript`.
      WHEN `json`.
        result = `application/json`.
      WHEN `xml`.
        result = `application/xml`.
      WHEN `pdf`.
        result = `application/pdf`.
      WHEN `zip`.
        result = `application/zip`.
      WHEN `png`.
        result = `image/png`.
      WHEN `jpg` OR `jpeg`.
        result = `image/jpeg`.
      WHEN `gif`.
        result = `image/gif`.
      WHEN `svg`.
        result = `image/svg+xml`.
      WHEN `webp`.
        result = `image/webp`.
      WHEN `ico`.
        result = `image/x-icon`.
      WHEN `mp3`.
        result = `audio/mpeg`.
      WHEN `mp4`.
        result = `video/mp4`.
      WHEN `woff`.
        result = `font/woff`.
      WHEN `woff2`.
        result = `font/woff2`.
      WHEN `ttf`.
        result = `font/ttf`.
      WHEN `otf`.
        result = `font/otf`.
      WHEN `xlsx`.
        result = `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`.
      WHEN `xls`.
        result = `application/vnd.ms-excel`.
      WHEN `docx`.
        result = `application/vnd.openxmlformats-officedocument.wordprocessingml.document`.
      WHEN `doc`.
        result = `application/msword`.
      WHEN `pptx`.
        result = `application/vnd.openxmlformats-officedocument.presentationml.presentation`.
      WHEN `ppt`.
        result = `application/vnd.ms-powerpoint`.
      WHEN OTHERS.
        result = `application/octet-stream`.
    ENDCASE.

  ENDMETHOD.

  METHOD check_msg_container.

    DATA lv_kind TYPE string.
    DATA temp2 TYPE xsdboolean.
    lv_kind = rtti_get_type_kind( val ).

    temp2 = boolc( lv_kind = cl_abap_datadescr=>typekind_table OR lv_kind = cl_abap_datadescr=>typekind_struct1 OR lv_kind = cl_abap_datadescr=>typekind_struct2 OR lv_kind = cl_abap_datadescr=>typekind_oref ).
    result = temp2.

  ENDMETHOD.

  METHOD msg_get_by_oref_attri.

    FIELD-SYMBOLS <comp> TYPE any.
    DATA lt_attri_o TYPE abap_attrdescr_tab.
    DATA temp52 LIKE LINE OF lt_attri_o.
    DATA ls_attri_o LIKE REF TO temp52.

    result = is_msg.

    lt_attri_o = rtti_get_t_attri_by_oref( io_obj ).


    LOOP AT lt_attri_o REFERENCE INTO ls_attri_o "#EC CI_SORTSEQ
         WHERE visibility = cv_objectdescr_public.
      " UNASSIGN + IS ASSIGNED, not sy-subrc - the loop-carried case (see
      " error_get_attributes). Here a stale 0 maps the PREVIOUS attribute's
      " value onto this one's name, i.e. a message id, number or placeholder
      " taken from the wrong attribute
      UNASSIGN <comp>.
      ASSIGN io_obj->(ls_attri_o->name) TO <comp>.
      IF <comp> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.
      result = msg_map( name = ls_attri_o->name
                        val  = <comp>
                        msg  = result ).
    ENDLOOP.

  ENDMETHOD.

  METHOD msg_get_internal_tab.

    " the RAP shape is a property of the ROW TYPE: decided on the first
    " structured row and handed down, not asked of every row - the check
    " describes every table component of a row, which a business table of a
    " few thousand rows paid a few thousand times before the box even
    " decided it carries no message at all
    DATA lv_rap LIKE abap_false.
    DATA lv_first LIKE abap_true.
    FIELD-SYMBOLS <row> TYPE ANY.
        DATA lv_row_kind TYPE string.
    lv_rap = abap_false.

    lv_first = abap_true.

    LOOP AT it_tab ASSIGNING <row>.
      IF lv_first = abap_true.
        lv_first = abap_false.

        lv_row_kind = rtti_get_type_kind( <row> ).
        IF lv_row_kind = cl_abap_datadescr=>typekind_struct1
            OR lv_row_kind = cl_abap_datadescr=>typekind_struct2.
          lv_rap = check_is_rap_struct( <row> ).
        ENDIF.
      ENDIF.
      IF lv_rap = abap_true AND <row> IS NOT INITIAL.
        INSERT LINES OF msg_get_rap( <row> ) INTO TABLE result.
      ELSE.
        INSERT LINES OF msg_get_internal( val          = <row>
                                          iv_check_rap = abap_false ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD csv_escape_cell.

    result = val.
    IF result NA |"\n\r| AND find( val = result
                                   sub = separator ) < 0.
      RETURN.
    ENDIF.
    result = replace( val  = result
                      sub  = `"`
                      with = `""`
                      occ  = 0 ).
    result = |"{ result }"|.

  ENDMETHOD.

  METHOD csv_split_rows.
    DATA lt_cells TYPE string_table.
    DATA lv_cell  TYPE string.
    " the cell was opened with a quote - an empty quoted cell is content
    DATA lv_was_quoted TYPE abap_bool.
    DATA lv_pos   TYPE i.
    DATA lv_next  TYPE string.
    " the next separator, CR and LF at or behind lv_pos, lv_len for none:
    " the text between two of them goes into the cell in one piece - one
    " concatenation per character made a long cell cost its length squared.
    " Each is searched again only when lv_pos has passed it
    DATA lv_next_sep TYPE i VALUE -1.
    DATA lv_next_cr  TYPE i VALUE -1.
    DATA lv_next_lf  TYPE i VALUE -1.

    DATA lv_len TYPE i.
    DATA lv_sep_len TYPE i.
      DATA lv_char TYPE string.
        DATA lv_end TYPE i.
    lv_len = strlen( val ).

    lv_sep_len = strlen( separator ).
    IF lv_sep_len = 0.
      RETURN.
    ENDIF.

    WHILE lv_pos < lv_len.


      lv_char = substring( val = val
                                 off = lv_pos
                                 len = 1 ).

      IF lv_char = `"` AND lv_cell IS INITIAL AND lv_was_quoted = abap_false.
        csv_read_quoted( EXPORTING val  = val
                         CHANGING  pos  = lv_pos
                                   cell = lv_cell ).
        lv_was_quoted = abap_true.
        CONTINUE.
      ENDIF.

      IF lv_next_sep < lv_pos.
        lv_next_sep = find( val = val
                            sub = separator
                            off = lv_pos ).
        IF lv_next_sep < 0.
          lv_next_sep = lv_len.
        ENDIF.
      ENDIF.
      IF lv_next_cr < lv_pos.
        lv_next_cr = find( val = val
                           sub = |\r|
                           off = lv_pos ).
        IF lv_next_cr < 0.
          lv_next_cr = lv_len.
        ENDIF.
      ENDIF.
      IF lv_next_lf < lv_pos.
        lv_next_lf = find( val = val
                           sub = |\n|
                           off = lv_pos ).
        IF lv_next_lf < 0.
          lv_next_lf = lv_len.
        ENDIF.
      ENDIF.

      IF lv_next_sep = lv_pos.
        INSERT lv_cell INTO TABLE lt_cells.
        CLEAR lv_cell.
        lv_was_quoted = abap_false.
        lv_pos = lv_pos + lv_sep_len.
        CONTINUE.
      ENDIF.

      IF lv_char <> |\n| AND lv_char <> |\r|.

        lv_end = nmin( val1 = lv_next_sep
                             val2 = nmin( val1 = lv_next_cr
                                          val2 = lv_next_lf ) ).
        lv_cell = lv_cell && substring( val = val
                                        off = lv_pos
                                        len = lv_end - lv_pos ).
        lv_pos = lv_end.
        CONTINUE.
      ENDIF.

      " the end of a row - CRLF is one line end. An empty row is left out
      lv_next = substring( val = val
                           off = lv_pos + 1
                           len = nmin( val1 = 1
                                       val2 = lv_len - lv_pos - 1 ) ).
      IF lv_char = |\r| AND lv_next = |\n|.
        lv_pos = lv_pos + 1.
      ENDIF.
      lv_pos = lv_pos + 1.
      IF lt_cells IS NOT INITIAL OR lv_cell IS NOT INITIAL OR lv_was_quoted = abap_true.
        INSERT lv_cell INTO TABLE lt_cells.
        INSERT lt_cells INTO TABLE result.
      ENDIF.
      CLEAR lt_cells.
      CLEAR lv_cell.
      lv_was_quoted = abap_false.

    ENDWHILE.

    IF lt_cells IS NOT INITIAL OR lv_cell IS NOT INITIAL OR lv_was_quoted = abap_true.
      INSERT lv_cell INTO TABLE lt_cells.
      INSERT lt_cells INTO TABLE result.
    ENDIF.
  ENDMETHOD.

  METHOD csv_read_quoted.

    " the text up to the next quote in one piece, not one concatenation
    " per character
    DATA lv_len TYPE i.
      DATA lv_quote TYPE i.
    lv_len = strlen( val ).
    pos = pos + 1.

    WHILE pos < lv_len.

      lv_quote = find( val = val
                             sub = `"`
                             off = pos ).
      " a quote that is never closed: the cell runs to the end of the text
      IF lv_quote < 0.
        cell = cell && substring( val = val
                                  off = pos ).
        pos = lv_len.
        RETURN.
      ENDIF.
      cell = cell && substring( val = val
                                off = pos
                                len = lv_quote - pos ).
      pos = lv_quote + 1.
      " a quote: doubled it is one quote of the text, alone it closes the cell
      IF pos >= lv_len OR substring( val = val
                                     off = pos
                                     len = 1 ) <> `"`.
        RETURN.
      ENDIF.
      cell = cell && `"`.
      pos = pos + 1.
    ENDWHILE.

  ENDMETHOD.

  METHOD csv_strip_bom.
        DATA temp53 TYPE xstring.
        DATA lv_bom TYPE string.

    " the UTF-8 decoding keeps the mark EF BB BF as the character U+FEFF in
    " front of the first column name. Built at run time from its bytes - a
    " literal U+FEFF in the source breaks the 7-bit rule and the downport.
    " Where the decoding drops it, it is empty
    result = val.
    TRY.

        temp53 = `EFBBBF`.

        lv_bom = conv_get_string_by_xstring( temp53 ).
        IF lv_bom IS NOT INITIAL AND find( val = result
                                           sub = lv_bom ) = 0.
          result = substring( val = result
                              off = strlen( lv_bom ) ).
        ENDIF.
      CATCH z2ui5_cx_tcl_error ##NO_HANDLER.
        " no codepage API: the text cannot have come through one either
    ENDTRY.

  ENDMETHOD.

  METHOD csv_get_column_name.

    DATA lv_pos TYPE i.

    DATA lv_name TYPE string.
    DATA lv_len TYPE i.
      DATA lv_char TYPE string.
    lv_name = c_trim_upper( val ).

    lv_len = strlen( lv_name ).

    WHILE lv_pos < lv_len.

      lv_char = substring( val = lv_name
                                 off = lv_pos
                                 len = 1 ).
      IF lv_char CA `ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_`.
        result = result && lv_char.
      ELSE.
        result = result && `_`.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.

    IF result IS INITIAL.
      result = |COL{ index }|.
    ELSEIF result(1) CA `0123456789`.
      result = `C_` && result.
    ENDIF.
    IF strlen( result ) > 30.
      result = result(30).
    ENDIF.

  ENDMETHOD.

  METHOD msg_get_rap_cause_value.

    " the name of an IF_ABAP_BEHV=>T_FAIL_CAUSE value to its base value;
    " -1 for a name this release does not know, which the text keeps
    " (the upper-case name in a variable first: the downport turns the
    " SWITCH into a CASE, whose operand takes no built-in function on 7.02)
    DATA lv_name TYPE string.
    DATA temp54 TYPE i.
    lv_name = to_upper( name ).

    CASE lv_name.
      WHEN `UNSPECIFIC`.
        temp54 = 0.
      WHEN `UNAUTHORIZED`.
        temp54 = 401.
      WHEN `NOT_FOUND`.
        temp54 = 404.
      WHEN `CONFLICT`.
        temp54 = 409.
      WHEN `LOCKED`.
        temp54 = 423.
      WHEN `DEPENDENCY`.
        temp54 = 424.
      WHEN `NOT_IMPLEMENTED`.
        temp54 = 501.
      WHEN `DISABLED`.
        temp54 = 4221.
      WHEN `READONLY`.
        temp54 = 4222.
      WHEN OTHERS.
        temp54 = -1.
    ENDCASE.
    result = temp54.

  ENDMETHOD.

  METHOD error_get_attributes.

    " declared, NOT `DATA(lv_name) = CONV string( lr_attri->name )`: a CONV
    " that is the whole right-hand side of an assignment is "Redundant
    " conversion for type STRING" in SLIN - the assignment converts by
    " itself. The variable stays a string on purpose: the RTTI name is a
    " CHAR field whose trailing blanks have no business in the rendered name
    DATA lv_name TYPE string.

    FIELD-SYMBOLS <comp> TYPE any.
        DATA lt_attri TYPE abap_attrdescr_tab.
    DATA temp55 LIKE LINE OF lt_attri.
    DATA lr_attri LIKE REF TO temp55.
      DATA temp56 TYPE z2ui5_cl_tcl_context=>ty_s_name_value.

    IF val IS NOT BOUND.
      RETURN.
    ENDIF.

    TRY.

        lt_attri = rtti_get_t_attri_by_oref( val ).
      CATCH cx_root.
        RETURN.
    ENDTRY.



    LOOP AT lt_attri REFERENCE INTO lr_attri "#EC CI_SORTSEQ
         WHERE visibility  = cv_objectdescr_public
           AND is_constant = abap_false
           AND is_class    = abap_false.

      CASE lr_attri->name.
          " rendered by the caller (PREVIOUS as the next chain entry,
          " KERNEL_ERRID as its own line) or without information value
        WHEN `PREVIOUS` OR `TEXTID` OR `IS_RESUMABLE` OR `KERNEL_ERRID`.
          CONTINUE.
      ENDCASE.

      lv_name = lr_attri->name.
      " UNASSIGN + IS ASSIGNED, not sy-subrc - see unassign_data for the
      " release behaviour (#1937). INSIDE A LOOP the stale-subrc reading is
      " not just "skipped one attribute": a failed ASSIGN leaves the symbol
      " on the PREVIOUS iteration's attribute, so a stale 0 renders that
      " value under this attribute's name - a wrong value in the error dump,
      " which is the one place a reader has nothing else to go by
      UNASSIGN <comp>.
      ASSIGN val->(lv_name) TO <comp>.
      IF <comp> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.
      IF rtti_check_printable( <comp> ) = abap_false OR <comp> IS INITIAL.
        CONTINUE.
      ENDIF.


      CLEAR temp56.
      temp56-n = lv_name.
      temp56-v = c_trim( |{ <comp> }| ).
      INSERT temp56 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD error_get_source_position.

    " typed like the EXPORTING parameters of get_source_position (syrepid is
    " CHAR40) - they are passed by reference, so a string would not be
    " type-compatible here
    DATA lv_program TYPE c LENGTH 40.
    DATA lv_include TYPE c LENGTH 40.
    DATA lv_line    TYPE i.

    IF val IS NOT BOUND.
      RETURN.
    ENDIF.

    " open-abap - the transpiled JS runtime behind the node tests - implements
    " get_source_position by reading a field that only the RAISE statement
    " writes, and fails with a JS TypeError for every other exception (a
    " runtime-thrown one, or one built with NEW). That error is not an ABAP
    " exception, so the TRY below cannot intercept it and the caller would go
    " down instead of reporting the error it was diagnosing. sy-saprl is
    " `OPEN` on that runtime and a real release everywhere else.
    IF sy_get( )-saprl = `OPEN`.
      RETURN.
    ENDIF.

    TRY.
        val->get_source_position( IMPORTING program_name = lv_program
                                            include_name = lv_include
                                            source_line  = lv_line ).
      CATCH cx_root ##NO_HANDLER.
        " never let the diagnostic be the reason a caller fails
    ENDTRY.

    IF lv_program IS INITIAL AND lv_line IS INITIAL.
      RETURN.
    ENDIF.

    result = c_trim( lv_program ).
    " the include is the interesting part for a class (...CM001 = the method
    " that raised); repeating it when it equals the program adds nothing
    IF lv_include IS NOT INITIAL AND lv_include <> lv_program.
      result = |{ result } / { c_trim( lv_include ) }|.
    ENDIF.
    IF lv_line IS NOT INITIAL.
      result = |{ result } / line { lv_line }|.
    ENDIF.

  ENDMETHOD.

  METHOD rtti_check_printable.
    DATA lv_type_kind TYPE string.
    DATA temp3 TYPE xsdboolean.

    IF rtti_check_clike( val ) = abap_true.
      result = abap_true.
      RETURN.
    ENDIF.


    lv_type_kind = rtti_get_type_kind( val ).

    temp3 = boolc( lv_type_kind = cl_abap_datadescr=>typekind_hex OR rtti_check_typekind_number( lv_type_kind ) = abap_true ).
    result = temp3.

  ENDMETHOD.

  METHOD rtti_check_typekind_number.

    CASE val.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_packed
          OR cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34
          OR `8`.
        result = abap_true.
    ENDCASE.

  ENDMETHOD.

  METHOD rtti_get_classname_by_ref.

    " an unbound reference has no class - answer with an empty name instead
    " of letting the RTTI call fail. Callers ask this while rendering (error
    " context, response header), where a half-built object graph is normal
    IF val IS NOT BOUND.
      RETURN.
    ENDIF.

    result = substring_after( val = cl_abap_classdescr=>get_class_name( val )
                              sub = `\CLASS=` ).

  ENDMETHOD.

  METHOD rtti_check_clike.

    CASE rtti_get_type_kind( val ).
      " typekind_clike/_csequence are generic kinds of formal parameters and
      " can never be returned for a concrete data object - list the concrete
      " character-like kinds (c, string, n, d, t) instead
      WHEN cl_abap_datadescr=>typekind_char OR
          cl_abap_datadescr=>typekind_string OR
          cl_abap_datadescr=>typekind_num OR
          cl_abap_datadescr=>typekind_date OR
          cl_abap_datadescr=>typekind_time.
        result = abap_true.
    ENDCASE.

  ENDMETHOD.

  METHOD rtti_get_t_attri_by_oref.

    DATA lo_descr TYPE REF TO cl_abap_typedescr.
    DATA temp57 TYPE REF TO cl_abap_classdescr.

    " describe_by_object_ref raises the classic exception REFERENCE_IS_INITIAL
    " for an initial reference - called functionally that is a runtime error no
    " CATCH reaches
    cl_abap_objectdescr=>describe_by_object_ref( EXPORTING  p_object_ref         = val
                                                 RECEIVING p_descr_ref           = lo_descr
                                                 EXCEPTIONS reference_is_initial = 1
                                                            OTHERS               = 2 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `RTTI_REFERENCE_IS_INITIAL`.
    ENDIF.

    temp57 ?= lo_descr.
    result = temp57->attributes.

  ENDMETHOD.

  METHOD rtti_get_type_kind.

    result = cl_abap_datadescr=>get_data_type_kind( val ).

  ENDMETHOD.

  METHOD rtti_get_type_name.
        DATA lo_descr TYPE REF TO cl_abap_typedescr.
        DATA temp58 TYPE REF TO cl_abap_elemdescr.
        DATA lo_ele LIKE temp58.
    TRY.


        lo_descr = cl_abap_elemdescr=>describe_by_data( val ).

        temp58 ?= lo_descr.

        lo_ele = temp58.
        result = lo_ele->get_relative_name( ).

      CATCH cx_root ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD rtti_create_tab_by_comps.

    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lo_table  TYPE REF TO cl_abap_tabledescr.

    lo_struct = cl_abap_structdescr=>create( val ).
    lo_table = cl_abap_tabledescr=>create( p_line_type  = lo_struct
                                           p_table_kind = cl_abap_tabledescr=>tablekind_std ).
    CREATE DATA result TYPE HANDLE lo_table.

  ENDMETHOD.

  METHOD rtti_create_tab_by_names.

    DATA lt_comp TYPE abap_component_tab.

    DATA lv_name LIKE LINE OF val.
      DATA temp59 TYPE abap_componentdescr.
    LOOP AT val INTO lv_name.
      " a string per column - a fixed length would cut every longer value

      CLEAR temp59.
      temp59-name = lv_name.
      temp59-type = cl_abap_elemdescr=>get_string( ).
      INSERT temp59 INTO TABLE lt_comp.
    ENDLOOP.
    result = rtti_create_tab_by_comps( lt_comp ).

  ENDMETHOD.

  METHOD boolean_check_by_name.

    CASE val.
      WHEN `ABAP_BOOL`
          OR `XSDBOOLEAN`
          OR `FLAG`
          OR `XFLAG`
          OR `XFELD`
          OR `ABAP_BOOLEAN`
          OR `WDY_BOOLEAN`
          OR `BOOLE_D`
          OR `OS_BOOLEAN`.
        result = abap_true.
    ENDCASE.

  ENDMETHOD.

  METHOD c_ends_with.

    DATA temp60 TYPE string.
    DATA lv_val LIKE temp60.
    DATA temp61 TYPE string.
    DATA lv_suffix LIKE temp61.
    DATA lv_len_suffix TYPE i.
    DATA lv_len_val TYPE i.
    DATA lv_off TYPE i.
    DATA temp4 TYPE xsdboolean.
    temp60 = val.

    lv_val = temp60.

    temp61 = suffix.

    lv_suffix = temp61.

    lv_len_suffix = strlen( lv_suffix ).

    lv_len_val = strlen( lv_val ).

    IF lv_len_val < lv_len_suffix.
      result = abap_false.
      RETURN.
    ENDIF.


    lv_off = lv_len_val - lv_len_suffix.

    temp4 = boolc( lv_val+lv_off(lv_len_suffix) = lv_suffix ).
    result = temp4.

  ENDMETHOD.

  METHOD conv_string_to_number.

    DATA temp62 TYPE string.
    DATA lv_val TYPE string.
    DATA lv_dot_count TYPE i.
    DATA lv_comma_count TYPE i.
    DATA lv_decimal TYPE string.
    DATA lv_i TYPE i.
    DATA lv_len TYPE i.
    DATA lv_last TYPE i.
    DATA lv_clean TYPE string.
      DATA lv_c TYPE string.
    DATA lv_point_count TYPE i.
    temp62 = val.

    lv_val = c_trim( temp62 ).

    " Which separator is the decimal one:
    " - both a dot and a comma occur: the one that occurs LAST
    "   (`1.234,56` and `1,234.56` are both 1234.56)
    " - only one kind, more than once: thousands separators, no decimals
    "   (`1.234.567`, `1,000,000`)
    " - only one kind, once: the decimal separator (`3,14`, `3.14`). So
    "   `1,000` is 1 (European convention) - a single separator cannot be
    "   told apart from a thousands separator, the decimal reading wins
    " Every other separator is a thousands separator and is skipped.




    lv_i = 0.

    lv_len = strlen( lv_val ).

    lv_last = lv_len - 1.
    WHILE lv_i < lv_len.
      CASE lv_val+lv_i(1).
        WHEN `.`.
          lv_dot_count = lv_dot_count + 1.
          lv_decimal = `.`.
        WHEN `,`.
          lv_comma_count = lv_comma_count + 1.
          lv_decimal = `,`.
      ENDCASE.
      lv_i = lv_i + 1.
    ENDWHILE.
    " lv_decimal holds the last separator - right when both kinds occur
    IF ( lv_dot_count = 0 OR lv_comma_count = 0 ) AND ( lv_dot_count > 1 OR lv_comma_count > 1 ).
      CLEAR lv_decimal.
    ENDIF.

    " Normalize: keep only digits, minus, and the decimal separator as `.`

    lv_clean = ``.
    lv_i = 0.
    WHILE lv_i < lv_len.

      lv_c = lv_val+lv_i(1).
      IF lv_c >= `0` AND lv_c <= `9`.
        lv_clean = lv_clean && lv_c.
      ELSEIF lv_c = `-` AND lv_i = 0.
        lv_clean = lv_clean && lv_c.
      ELSEIF lv_c = `-` AND lv_i = lv_last AND lv_val(1) <> `-`.
        " the sign behind the number, as a MOVE and WRITE put it
        lv_clean = `-` && lv_clean.
      ELSEIF lv_c = lv_decimal.
        lv_clean = lv_clean && `.`.
      ENDIF.
      " any other separator is a thousands separator - skipped
      lv_i = lv_i + 1.
    ENDWHILE.

    " Validate the normalized value explicitly: it needs at least one
    " digit and at most one decimal point (`1,234.5.6` keeps two). Return 0
    " for invalid input - the JS transpiler converts such strings leniently
    " instead of raising

    lv_point_count = count( val = lv_clean
                                  sub = `.` ).
    IF lv_point_count > 1 OR lv_clean NA `0123456789`.
      result = 0.
      RETURN.
    ENDIF.

    TRY.
        result = lv_clean.
      CATCH cx_root.
        result = 0.
    ENDTRY.

  ENDMETHOD.

  METHOD rtti_get_data_element_texts.

    DATA data_element_name TYPE string.
    DATA lv_do_fallback    TYPE abap_bool.

    data_element_name = val.

    TRY.
        rtti_get_dtel_texts_by_ddic( EXPORTING name        = data_element_name
                                     IMPORTING texts       = result
                                               do_fallback = lv_do_fallback ).
      CATCH cx_root.
        rtti_get_dtel_texts_by_xco( EXPORTING name        = data_element_name
                                    IMPORTING texts       = result
                                              do_fallback = lv_do_fallback ).
    ENDTRY.

    IF lv_do_fallback = abap_true AND result IS INITIAL.
      result-header = val.
      result-long = val.
      result-medium = val.
      result-short = val.
    ENDIF.

  ENDMETHOD.

  METHOD zip_pack.

    DATA lo_zip TYPE REF TO object.
        DATA ls_file LIKE LINE OF files.
        DATA x TYPE REF TO cx_root.

    TRY.

        CREATE OBJECT lo_zip TYPE ('CL_ABAP_ZIP').

        LOOP AT files INTO ls_file.
          CALL METHOD lo_zip->('ADD')
            EXPORTING
              name    = ls_file-name
              content = ls_file-content.
        ENDLOOP.
        CALL METHOD lo_zip->('SAVE')
          RECEIVING
            zip = result.


      CATCH cx_root INTO x.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error EXPORTING val = x.
    ENDTRY.

  ENDMETHOD.

  METHOD zip_unpack.

    CONSTANTS lc_signature TYPE x LENGTH 2 VALUE '504B'.
    DATA lo_zip    TYPE REF TO object.
    DATA lv_name   TYPE string.
    DATA lv_error  TYPE string.
    DATA ls_result LIKE LINE OF result.

    FIELD-SYMBOLS <files> TYPE ANY TABLE.
    FIELD-SYMBOLS <file>  TYPE any.
    FIELD-SYMBOLS <name>  TYPE any.
        DATA x TYPE REF TO cx_root.

    " every ZIP archive starts with PK. Checked here, for the same answer
    " on every runtime: what the ZIP class does with other bytes differs,
    " and the transpiled one takes them without a word
    IF xstrlen( val ) < 4 OR val(2) <> lc_signature.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = `ZIP_PARSE_ERROR - the data is no ZIP archive`.
    ENDIF.

    TRY.

        CREATE OBJECT lo_zip TYPE ('CL_ABAP_ZIP').
        " LOAD and GET report a broken archive with a classic exception -
        " not taken here, it ends the program with a dump, and a file a
        " user uploads is broken often enough (cut off, or damaged)
        CALL METHOD lo_zip->('LOAD')
          EXPORTING
            zip             = val
          EXCEPTIONS
            zip_parse_error = 1
            OTHERS          = 2.
        IF sy-subrc <> 0.
          lv_error = `ZIP_PARSE_ERROR - the data is no ZIP archive`.
        ELSE.
          ASSIGN lo_zip->('FILES') TO <files>.
          LOOP AT <files> ASSIGNING <file>.
            ASSIGN COMPONENT `NAME` OF STRUCTURE <file> TO <name>.
            lv_name = <name>.

            CLEAR ls_result.
            ls_result-name = lv_name.
            CALL METHOD lo_zip->('GET')
              EXPORTING
                name                    = lv_name
              IMPORTING
                content                 = ls_result-content
              EXCEPTIONS
                zip_index_error         = 1
                zip_decompression_error = 2
                OTHERS                  = 3.
            IF sy-subrc <> 0.
              lv_error = |ZIP_PARSE_ERROR - the file { lv_name } of the archive cannot be unpacked|.
              EXIT.
            ENDIF.
            INSERT ls_result INTO TABLE result.
          ENDLOOP.
        ENDIF.


      CATCH cx_root INTO x.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val      = `ZIP_PARSE_ERROR - the ZIP archive cannot be read`
            previous = x.
    ENDTRY.

    " raised behind the TRY: in it, the handler above would wrap it again
    IF lv_error IS NOT INITIAL.
      CLEAR result.
      RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
        EXPORTING
          val = lv_error.
    ENDIF.

  ENDMETHOD.

  METHOD xml_reader_create.
        DATA x TYPE REF TO cx_root.

    TRY.
        " no option set: as it comes, the reader reports a text of blanks
        " only where it is the whole content of an element and leaves out
        " the indentation between two elements - what a caller wants
        result = cl_sxml_string_reader=>create( val ).

      CATCH cx_root INTO x.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val      = `XML_READER_ERROR - the document cannot be read`
            previous = x.
    ENDTRY.

  ENDMETHOD.

  METHOD xml_reader_next.

    DATA lo_reader TYPE REF TO if_sxml_reader.
                DATA temp63 TYPE z2ui5_cl_tcl_context=>ty_s_xml_attribute.
        DATA x TYPE REF TO cx_root.

    CLEAR kind.
    CLEAR name.
    CLEAR value.
    CLEAR t_attribute.

    TRY.
        lo_reader ?= reader.
        lo_reader->next_node( ).

        CASE lo_reader->node_type.
          WHEN if_sxml_node=>co_nt_element_open.
            kind = cs_xml_node-open.
            name = lo_reader->name.
            IF t_attribute IS SUPPLIED.
              " next_attribute( ) walks the attributes of the element the
              " reader stands on and leaves the attribute kind behind the
              " last one - the way that is there since 7.02
              DO.
                lo_reader->next_attribute( ).
                IF lo_reader->node_type <> if_sxml_node=>co_nt_attribute.
                  EXIT.
                ENDIF.

                CLEAR temp63.
                temp63-name = lo_reader->name.
                temp63-value = lo_reader->value.
                INSERT temp63 INTO TABLE t_attribute.
              ENDDO.
            ENDIF.
          WHEN if_sxml_node=>co_nt_element_close.
            kind = cs_xml_node-close.
            name = lo_reader->name.
          WHEN if_sxml_node=>co_nt_value.
            kind = cs_xml_node-value.
            value = lo_reader->value.
          WHEN OTHERS.
            " co_nt_final, and whatever a later release may add
            kind = cs_xml_node-end.
        ENDCASE.


      CATCH cx_root INTO x.
        RAISE EXCEPTION TYPE z2ui5_cx_tcl_error
          EXPORTING
            val      = `XML_READER_ERROR - the document is not well-formed XML`
            previous = x.
    ENDTRY.

  ENDMETHOD.

  METHOD c_escape_xml.
          DATA temp64 TYPE xstring.
      DATA lv_off TYPE i.
      DATA lv_len TYPE i.

    " one CA scan up front: replace( occ = 0 ) copies the whole string on
    " every call even when nothing matches, and a value without any special
    " character is the COMMON case - that made every attribute value pay for
    " seven full copies. A value that does carry one still runs all seven
    " replaces below, unchanged
    IF gv_xml_escape_specials IS INITIAL.
      " the XML-illegal control characters as one string, so the CA scan
      " stays a single statement; built from their UTF-8 bytes. Behind them
      " the two non-characters U+FFFE and U+FFFF (EF BF BE, EF BF BF): a
      " legacy long text through a broken codepage conversion carries them,
      " and the XMLView parser refuses the whole document for one of them
      TRY.

          temp64 = `000102030405060708` && `0B0C` && `0E0F101112131415161718191A1B1C1D1E1F` && `EFBFBE` && `EFBFBF`.
          gv_xml_escape_controls = conv_get_string_by_xstring(
              temp64 ).
        CATCH z2ui5_cx_tcl_error.
          " No codepage API here (UNSUPPORTED_CODEPAGE_API). Degrade instead of
          " failing: the set stays empty, the CA scan below then matches no
          " control character and the drop loop never runs, while `&`, `<`, `>`,
          " `"`, newline, CR and tab are escaped exactly as before. Dropping
          " those 30 exotic bytes is a repair for legacy long texts, not a
          " correctness requirement of the view - so losing it must not cost
          " the render. Before this, a missing class raised out of the utility
          " and took down every view on the first escape of the process.
          CLEAR gv_xml_escape_controls.
      ENDTRY.
      gv_xml_escape_specials = `&<>"`
          && cv_char_util_newline
          && cv_char_util_cr_lf(1)
          && cv_char_util_horizontal_tab
          && gv_xml_escape_controls.
    ENDIF.
    result = val.
    IF result NA gv_xml_escape_specials.
      RETURN.
    ENDIF.

    result = replace( val  = result
                      sub  = `&`
                      with = `&amp;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = `<`
                      with = `&lt;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = `>`
                      with = `&gt;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = `"`
                      with = `&quot;`
                      occ  = 0 ).
    " whitespace as character references - a literal LF/CR/TAB in an attribute
    " value is turned into a plain space by XML attribute-value normalization,
    " so line breaks (e.g. a two-line noDataText) would silently disappear
    result = replace( val  = result
                      sub  = cv_char_util_newline
                      with = `&#xA;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = cv_char_util_cr_lf(1)
                      with = `&#xD;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = cv_char_util_horizontal_tab
                      with = `&#x9;`
                      occ  = 0 ).

    " what is left of the control range is illegal in XML 1.0 outright -
    " U+0000-U+0008, U+000B, U+000C, U+000E-U+001F cannot even be written
    " as character references, and UI5's XMLView parser rejects the whole
    " document over one such byte (a form feed or record separator out of a
    " legacy long text blanks the view). They carry no meaning in an
    " attribute value, so they are dropped. Only reached for a value that
    " passed the CA scan above - see gv_xml_escape_specials
    IF result CA gv_xml_escape_controls.
      " one replace per character, no regex: [[:cntrl:]] is not a class every
      " runtime this code runs on knows (the transpiled one left every byte
      " in place), and this branch is the rare one

      lv_off = 0.

      lv_len = strlen( gv_xml_escape_controls ).
      WHILE lv_off < lv_len.
        result = replace( val  = result
                          sub  = gv_xml_escape_controls+lv_off(1)
                          with = ``
                          occ  = 0 ).
        lv_off = lv_off + 1.
      ENDWHILE.
    ENDIF.

  ENDMETHOD.

  METHOD rtti_get_dtel_texts_by_ddic.

    DATA ddic_ref TYPE REF TO data.
    DATA: BEGIN OF ddic,
            reptext   TYPE string,
            scrtext_s TYPE string,
            scrtext_m TYPE string,
            scrtext_l TYPE string,
          END OF ddic.
    DATA struct_descr TYPE REF TO cl_abap_structdescr.
    FIELD-SYMBOLS <ddic> TYPE data.
    DATA lo_typedescr TYPE REF TO cl_abap_typedescr.

    CLEAR texts.
    do_fallback = abap_false.

    cl_abap_typedescr=>describe_by_name( `T100` ).

    struct_descr ?= cl_abap_structdescr=>describe_by_name( `DFIES` ).

    CREATE DATA ddic_ref TYPE HANDLE struct_descr.

    " IS ASSIGNED, not sy-subrc, and a RETURN rather than an ASSERT: the
    " symbol is the unassign_data shape (#1937), and an ASSERTION_FAILED
    " here is a short dump the caller's own TRY cannot take - so the XCO
    " fallback it exists for would never run. The two branches below answer
    " a failure the same way
    ASSIGN ddic_ref->* TO <ddic>.
    IF <ddic> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    cl_abap_elemdescr=>describe_by_name( EXPORTING  p_name     = name
                                         RECEIVING p_descr_ref = lo_typedescr
                                         EXCEPTIONS OTHERS     = 1 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CALL METHOD lo_typedescr->(`GET_DDIC_FIELD`)
      RECEIVING
        p_flddescr   = <ddic>
      EXCEPTIONS
        not_found    = 1
        no_ddic_type = 2
        OTHERS       = 3.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    MOVE-CORRESPONDING <ddic> TO ddic.
    texts-header = ddic-reptext.
    texts-short  = ddic-scrtext_s.
    texts-medium = ddic-scrtext_m.
    texts-long   = ddic-scrtext_l.
    do_fallback  = abap_true.

  ENDMETHOD.

  METHOD rtti_get_dtel_texts_by_xco.

    DATA data_element TYPE REF TO object.
    DATA content      TYPE REF TO object.
    DATA exists       TYPE abap_bool.
    DATA lv_xco_cp_abap_dictionary TYPE string.
    " A dynamic call checks its actual parameters against the formal ones at
    " runtime and converts nothing, so both sides are typed exactly as XCO
    " declares them. The name is sxco_ad_object_name (CHAR30), passed by
    " reference - a string there raised CX_SY_DYN_CALL_ILLEGAL_TYPE. Each
    " label is if_xco_dtel_content=>ts_field_label, a text (CHAR60) and its
    " length (NUMC2) - received into a string, every one raised the same.
    " Both ended in the CATCH below, so on ABAP Cloud every data element came
    " back with empty texts (or its own name, as the caller's fallback). The
    " shapes are written out because the XCO types exist on cloud only
    DATA lv_name TYPE c LENGTH 30.
    DATA: BEGIN OF ls_label,
            text   TYPE c LENGTH 60,
            length TYPE n LENGTH 2,
          END OF ls_label.

    CLEAR texts.
    do_fallback = abap_false.

    TRY.
        lv_name = name.
        lv_xco_cp_abap_dictionary = `XCO_CP_ABAP_DICTIONARY`.
        CALL METHOD (lv_xco_cp_abap_dictionary)=>(`DATA_ELEMENT`)
          EXPORTING
            iv_name         = lv_name
          RECEIVING
            ro_data_element = data_element.

        CALL METHOD data_element->(`IF_XCO_AD_DATA_ELEMENT~EXISTS`)
          RECEIVING
            rv_exists = exists.

        IF exists = abap_false.
          RETURN.
        ENDIF.

        CALL METHOD data_element->(`IF_XCO_AD_DATA_ELEMENT~CONTENT`)
          RECEIVING
            ro_content = content.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_HEADING_FIELD_LABEL`)
          RECEIVING
            rs_heading_field_label = ls_label.
        texts-header = ls_label-text.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_SHORT_FIELD_LABEL`)
          RECEIVING
            rs_short_field_label = ls_label.
        texts-short = ls_label-text.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_MEDIUM_FIELD_LABEL`)
          RECEIVING
            rs_medium_field_label = ls_label.
        texts-medium = ls_label-text.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_LONG_FIELD_LABEL`)
          RECEIVING
            rs_long_field_label = ls_label.
        texts-long = ls_label-text.

        do_fallback = abap_true.

      CATCH cx_root.
        do_fallback = abap_true.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
