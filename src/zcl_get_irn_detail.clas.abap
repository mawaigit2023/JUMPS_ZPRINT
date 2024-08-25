CLASS zcl_get_irn_detail DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA:
      im_subs_id TYPE string,
      im_gstin   TYPE string.

    METHODS:
      get_excelon_auth_token
        RETURNING VALUE(iv_access_token) TYPE string,

      get_excelon_app_key
        IMPORTING
                  im_access_token  TYPE string
        RETURNING VALUE(r_app_key) TYPE string,

      encrypt_logon_detail
        IMPORTING
                  im_app_key             TYPE string
                  im_auth_token          TYPE string
        RETURNING VALUE(r_encrypt_login) TYPE string,

      get_irp_token
        IMPORTING
                  im_auth_token     TYPE string
                  im_encrypt_login  TYPE string
        RETURNING VALUE(r_irp_data) TYPE string,

      get_encrypty_irn_detail
        IMPORTING
                  im_auth_token        TYPE string
                  im_irp_data          TYPE string
                  im_doc_num           TYPE string
                  im_doc_typ           TYPE string
                  im_doc_date          TYPE string
        RETURNING VALUE(r_irn_encrypt) TYPE string,

      get_decrypted_doc
        IMPORTING
                  im_auth_token     TYPE string
                  im_irp_data       TYPE string
                  im_irn_encrypt    TYPE string
                  im_app_key        TYPE string
        RETURNING VALUE(r_irn_data) TYPE string,

      get_encrypt_eway_detail
        IMPORTING
                  im_auth_token         TYPE string
                  im_irp_data           TYPE string
                  im_irn_num            TYPE string
                  im_app_key            TYPE string
        RETURNING VALUE(r_eway_encrypt) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_GET_IRN_DETAIL IMPLEMENTATION.


  METHOD encrypt_logon_detail.

    DATA: url            TYPE string,
          lo_http_client TYPE REF TO if_web_http_client,
          miw_string     TYPE string.

    DATA:
      lv_secret TYPE string.

    CLEAR : url.
    IF ( sy-sysid = 'X81' OR sy-sysid = 'XC7' ).

      url = 'https://demoapi.exactgst.com/gstcore/api/EncryptLoginPayload'.
      im_subs_id = '8172bd2a-4943-4e66-8f80-eecfc4576bdd'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/gstcore/api/EncryptLoginPayload'.
      im_subs_id = '93e69e2c-aaa1-4a9f-a2f7-cee210443808'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    TRY.
        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        DATA(lo_request11) = lo_http_client->get_http_request( ).
        lo_request11->set_content_type( 'application/json; charset=utf-8' ).

        CLEAR: miw_string.
        IF ( sy-sysid = 'X81' OR sy-sysid = 'XC7' ).

          miw_string = '{'
             && '"UserName":' && '"JUMPS_HR_1",'
             && '"Password":' && '"123@Excellon",'
             && '"AppKey":' &&  '"' && im_app_key && '",'
             && '"ForceRefreshAccessToken":' &&  '"false"'
             && '}'.

        ELSE.

          miw_string = '{'
             && '"UserName":' && '"API_JUMPS",'
             && '"Password":' && '"Jumps@12345",'
             && '"AppKey":' &&  '"' && im_app_key && '",'
             && '"ForceRefreshAccessToken":' &&  '"false"'
             && '}'.

        ENDIF.

        lo_request11->append_text(
          EXPORTING
            data = miw_string
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'AuthenticationToken'
            i_value = im_auth_token
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'ExactSubscriptionId'
            i_value = im_subs_id
        ).

*    CATCH cx_web_message_error.
        DATA(lo_response11) = lo_http_client->execute( i_method = if_web_http_client=>post ).
        DATA(response_body11) = lo_response11->get_text( ).

      CATCH cx_web_http_client_error.

      CATCH cx_http_dest_provider_error.

    ENDTRY.

    "*REPLACE ALL OCCURRENCES OF '"' IN response_body11 WITH space.
    r_encrypt_login = response_body11.

  ENDMETHOD.


  METHOD get_decrypted_doc.

    DATA: url            TYPE string,
          lo_http_client TYPE REF TO if_web_http_client,
          miw_string     TYPE string.

    DATA:
      lv_secret TYPE string.

    TYPES: BEGIN OF lty_irp_data,
             ClientId    TYPE string,
             UserName    TYPE string,
             AuthToken   TYPE string,
             Sek         TYPE string,
             TokenExpiry TYPE string,
           END OF lty_irp_data.

    DATA:
      lt_irp TYPE TABLE OF lty_irp_data,
      ls_irp TYPE lty_irp_data.

    /ui2/cl_json=>deserialize(
                    EXPORTING json = im_irp_data
                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                       CHANGING data = lt_irp
                 ).

    READ TABLE lt_irp INTO ls_irp INDEX 1.

    CLEAR : url, im_subs_id.
    IF ( sy-sysid = 'X81' OR sy-sysid = 'XC7' ).

      url = 'https://demoapi.exactgst.com/gstcore/api/DecryptDataSEK'.
      im_subs_id = '8172bd2a-4943-4e66-8f80-eecfc4576bdd'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/gstcore/api/DecryptDataSEK'.
      im_subs_id = '93e69e2c-aaa1-4a9f-a2f7-cee210443808'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    TRY.
        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        DATA(lo_request11) = lo_http_client->get_http_request( ).
        lo_request11->set_content_type( 'application/json; charset=utf-8' ).

        CLEAR: miw_string.
        miw_string = '{'
           && '"Data":' && im_irn_encrypt && ','
           && '"rek":' && 'null,'
           && '"status":' && '"1"'
           && '}'.

        lo_request11->append_text(
          EXPORTING
            data = miw_string
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'AuthToken'
            i_value = ls_irp-authtoken
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'AuthenticationToken'
            i_value = im_auth_token
        ).


        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'ExactSubscriptionId'
            i_value = im_subs_id
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'sek'
            i_value = ls_irp-sek
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'AppKey'
            i_value = im_app_key
        ).

*    CATCH cx_web_message_error.
        DATA(lo_response11) = lo_http_client->execute( i_method = if_web_http_client=>post ).
        DATA(response_body11) = lo_response11->get_text( ).

      CATCH cx_web_http_client_error.

      CATCH cx_http_dest_provider_error.

    ENDTRY.

    r_irn_data = '[' && response_body11 && ']'.

  ENDMETHOD.


  METHOD get_encrypty_irn_detail.

    DATA: url            TYPE string,
          url1           TYPE string,
          lo_http_client TYPE REF TO if_web_http_client,
          miw_string     TYPE string.

    DATA:
      lv_secret TYPE string.

    TYPES: BEGIN OF lty_irp_data,
             ClientId    TYPE string,
             UserName    TYPE string,
             AuthToken   TYPE string,
             Sek         TYPE string,
             TokenExpiry TYPE string,
           END OF lty_irp_data.

    DATA:
      lt_irp TYPE TABLE OF lty_irp_data,
      ls_irp TYPE lty_irp_data.

    CLEAR : url.
    IF ( sy-sysid = 'X81' OR sy-sysid = 'XC7' ).

      url = 'https://demoapi.exactgst.com/eicore/v1.03/Invoice/irnbydocdetails?'.
      im_subs_id = '8172bd2a-4943-4e66-8f80-eecfc4576bdd'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/eicore/v1.03/Invoice/irnbydocdetails?'.
      im_subs_id = '93e69e2c-aaa1-4a9f-a2f7-cee210443808'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    /ui2/cl_json=>deserialize(
                    EXPORTING json = im_irp_data
                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                       CHANGING data = lt_irp
                 ).

    READ TABLE lt_irp INTO ls_irp INDEX 1.

    url = url
          && 'doctype=' && im_doc_typ
          && '&docnum=' && im_doc_num
          && '&docdate=' && im_doc_date.

    TRY.
        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        DATA(lo_request11) = lo_http_client->get_http_request( ).
        lo_request11->set_content_type( 'application/json; charset=utf-8' ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'AuthenticationToken'
            i_value = im_auth_token
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'ExactSubscriptionId'
            i_value = im_subs_id
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'user_name'
            i_value = ls_irp-username
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'authtoken'
            i_value = ls_irp-authtoken
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'gstin'
            i_value = im_gstin
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'sup_gstin'
            i_value = ''
        ).

*    CATCH cx_web_message_error.
        DATA(lo_response11) = lo_http_client->execute( i_method = if_web_http_client=>get ).
        DATA(response_body11) = lo_response11->get_text( ).

      CATCH cx_web_http_client_error.

      CATCH cx_http_dest_provider_error.

    ENDTRY.

    SPLIT response_body11 AT '"Data":' INTO DATA(split_1) DATA(split_2) .
    SPLIT split_2 AT ',' INTO DATA(irn_encrypt) DATA(split_3) .
    r_irn_encrypt = irn_encrypt.

  ENDMETHOD.


  METHOD get_encrypt_eway_detail.

    DATA: url            TYPE string,
          url1           TYPE string,
          lo_http_client TYPE REF TO if_web_http_client,
          miw_string     TYPE string.

    DATA:
      lv_secret TYPE string.

    TYPES: BEGIN OF lty_irp_data,
             ClientId    TYPE string,
             UserName    TYPE string,
             AuthToken   TYPE string,
             Sek         TYPE string,
             TokenExpiry TYPE string,
           END OF lty_irp_data.

    DATA:
      lt_irp TYPE TABLE OF lty_irp_data,
      ls_irp TYPE lty_irp_data.

    CLEAR : url.
    IF ( sy-sysid = 'X81' OR sy-sysid = 'XC7' ).

      url = 'https://demoapi.exactgst.com/eiewb/v1.03/ewaybill/?'.
      im_subs_id = '8172bd2a-4943-4e66-8f80-eecfc4576bdd'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/eiewb/v1.03/ewaybill/?irn='.
      im_subs_id = '93e69e2c-aaa1-4a9f-a2f7-cee210443808'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    /ui2/cl_json=>deserialize(
                    EXPORTING json = im_irp_data
                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                       CHANGING data = lt_irp
                 ).

    READ TABLE lt_irp INTO ls_irp INDEX 1.

    url = url
          && 'irn=' && im_irn_num.

    TRY.

        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        DATA(lo_request11) = lo_http_client->get_http_request( ).
        lo_request11->set_content_type( 'application/json; charset=utf-8' ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'AuthenticationToken'
            i_value = im_auth_token
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'user_name'
            i_value = ls_irp-username
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'authtoken'
            i_value = ls_irp-authtoken
        ).


        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'gstin'
            i_value = im_gstin
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'ExactSubscriptionId'
            i_value = im_subs_id
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'sup_gstin'
            i_value = ''
        ).

*    CATCH cx_web_message_error.
        DATA(lo_response11) = lo_http_client->execute( i_method = if_web_http_client=>get ).
        DATA(response_body11) = lo_response11->get_text( ).

      CATCH cx_web_http_client_error.

      CATCH cx_http_dest_provider_error.

    ENDTRY.

    SPLIT response_body11 AT '"Data":' INTO DATA(split_1) DATA(split_2) .
    SPLIT split_2 AT ',' INTO DATA(eway_encrypt) DATA(split_3) .
    r_eway_encrypt = eway_encrypt.

  ENDMETHOD.


  METHOD get_excelon_app_key.

    DATA: url            TYPE string,
          lo_http_client TYPE REF TO if_web_http_client,
          miw_string     TYPE string.

    DATA:
      lv_secret TYPE string.

    CLEAR : url.
    IF ( sy-sysid = 'X81' OR sy-sysid = 'XC7' ).

      url = 'https://demoapi.exactgst.com/gstcore/api/GenerateAppKeyString'.
      im_subs_id = '8172bd2a-4943-4e66-8f80-eecfc4576bdd'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/gstcore/api/GenerateAppKeyString'.
      im_subs_id = '93e69e2c-aaa1-4a9f-a2f7-cee210443808'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    TRY.
        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        DATA(lo_request11) = lo_http_client->get_http_request( ).
        lo_request11->set_content_type( 'application/json; charset=utf-8' ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'AuthenticationToken'
            i_value = im_access_token
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'ExactSubscriptionId'
            i_value = im_subs_id
        ).

*    CATCH cx_web_message_error.
        DATA(lo_response11) = lo_http_client->execute( i_method = if_web_http_client=>post ).
        DATA(response_body11) = lo_response11->get_text( ).

      CATCH cx_web_http_client_error.

      CATCH cx_http_dest_provider_error.

    ENDTRY.

    REPLACE ALL OCCURRENCES OF '"' IN response_body11 WITH space.
    r_app_key = response_body11.

  ENDMETHOD.


  METHOD get_excelon_auth_token.

    DATA: url            TYPE string,
          lo_http_client TYPE REF TO if_web_http_client,
          miw_string     TYPE string.

    DATA:
      lv_secret TYPE string.

    CLEAR : url.
    IF ( sy-sysid = 'X81' OR sy-sysid = 'XC7' ).

      url = 'https://demoapi.exactgst.com/api/authentication/getAuthenticationToken'.
      im_subs_id = '8172bd2a-4943-4e66-8f80-eecfc4576bdd'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/api/authentication/getAuthenticationToken'.
      im_subs_id = '93e69e2c-aaa1-4a9f-a2f7-cee210443808'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    TRY.
        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        IF ( sy-sysid = 'X81' OR sy-sysid = 'XC7' ).

          lv_secret = '"H/T15rxDX7W9nPDo6gmoVwLff1Cjhd2RjxzA/A27Uu5k6XwgXvi5PZFp/Ne/TBEDK5CdtiP3jDColp1dAv4C'
          && 'DHA4uT0phasP+l5zxf+sEM6VGODk30MrDNl7PhCg5KgEihg24vpyeXGqMJ2+3WXx5dEhinFw8HTPnLHb4Xpylo'
          && 'YhaScVnMSwViUU7xvY1K6k8NaQdBkIhGkI2pf4bdB+m3YCk4398LZCLpscEZDHKrwp1dQfno2w19EoiWthfKTT0'
          && '7p3xtlrAnOdV2vZ7qEC+LPCdR7BVvyrOffMyKIBaV/eESBpp/KgnyLy6xEyLCxyMvl7ofdJqhD+0pxvnhDODQ=="'.

          CLEAR: miw_string.
          miw_string = '{'
                  && '"ClientId":' && '"c68e3816-4adf-428a-a2ee-7455bd2a2c44",'
                  && '"ClientSecret":' && lv_secret
                  && '}'.

        ELSE.

          lv_secret = '"ghYSOAxs6+FYikFaVSx7W/HpOVx83T5iw/kk0v6K1F0hHwEltWbOGVXLe0kdojpgCmvj/NsrwwEj1bwbtcaL3q'
                   && 'rgilWPwLMsSIMcJHFbTB7doxen06i2/9rUwBJeQbPOC7iNB3x63fqlxnGEvUoHWfOioHLeyKOcWkgDTz3La8a+MFX'
                   && 'YA08R+C04LjjFqal0zc2bpsLIMBHR1s8OUx1zd5PJXQ2I4Em/G3ryTa7M9PM4n9uKsolJo2zFU+qv2v+7de4Ndohl'
                   && 'LM/Ka/lJ/M9Lf3IWmBeLX099CCrGvNQCZDkz009wNU1m9MLVYSy96CYE3cYnwfEAG3R595SomsJITw=="'.

          CLEAR: miw_string.
          miw_string = '{'
                  && '"ClientId":' && '"1ede4858-1bd4-4c2d-940a-d09f5a0188c7",'
                  && '"ClientSecret":' && lv_secret
                  && '}'.

        ENDIF.

        DATA(lo_request11) = lo_http_client->get_http_request( ).
        lo_request11->set_content_type( 'application/json; charset=utf-8' ).

        lo_request11->append_text(
          EXPORTING
            data = miw_string
        ).

        DATA(lo_response11) = lo_http_client->execute( i_method = if_web_http_client=>post ).
        DATA(response_body11) = lo_response11->get_text( ).

      CATCH cx_web_http_client_error.

      CATCH cx_http_dest_provider_error.

    ENDTRY.

    SPLIT response_body11 AT '"AuthenticationToken": ' INTO DATA(split_1) DATA(split_2) .
    SPLIT split_2 AT ',' INTO DATA(token) DATA(split_3) .
    REPLACE ALL OCCURRENCES OF '"' IN token WITH space.
    iv_access_token = token.

  ENDMETHOD.


  METHOD get_irp_token.

    DATA: url            TYPE string,
          lo_http_client TYPE REF TO if_web_http_client,
          miw_string     TYPE string.

    DATA:
      lv_secret TYPE string.

    CLEAR : url.
    url = ''.

    IF ( sy-sysid = 'X81' OR sy-sysid = 'XC7' ).

      url = 'https://demoapi.exactgst.com/eivital/v1.04/auth'.
      im_subs_id = '8172bd2a-4943-4e66-8f80-eecfc4576bdd'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/eivital/v1.04/auth'.
      im_subs_id = '93e69e2c-aaa1-4a9f-a2f7-cee210443808'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    TRY.
        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        DATA(lo_request11) = lo_http_client->get_http_request( ).
        lo_request11->set_content_type( 'application/json; charset=utf-8' ).

        CLEAR: miw_string.
        miw_string = '{'
           && '"Data":' && im_encrypt_login
           && '}'.

        lo_request11->append_text(
          EXPORTING
            data = miw_string
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'AuthenticationToken'
            i_value = im_auth_token
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'ExactSubscriptionId'
            i_value = im_subs_id
        ).

        lo_request11->set_header_field(
          EXPORTING
            i_name  = 'gstin'
            i_value = im_gstin
        ).

*    CATCH cx_web_message_error.
        DATA(lo_response11) = lo_http_client->execute( i_method = if_web_http_client=>post ).
        DATA(response_body11) = lo_response11->get_text( ).

      CATCH cx_web_http_client_error.

      CATCH cx_http_dest_provider_error.

    ENDTRY.

    SPLIT response_body11 AT '"Data":' INTO DATA(split_1) DATA(split_2) .
    SPLIT split_2 AT '},' INTO DATA(token) DATA(split_3) .
    r_irp_data = '[' && token && '}]'.

  ENDMETHOD.
ENDCLASS.
