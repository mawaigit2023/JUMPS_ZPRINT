CLASS zcl_get_eway_detail DEFINITION
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
        RETURNING VALUE(r_irn_data) TYPE string.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_GET_EWAY_DETAIL IMPLEMENTATION.


  METHOD encrypt_logon_detail.

    DATA: url            TYPE string,
          lo_http_client TYPE REF TO if_web_http_client,
          miw_string     TYPE string.

    DATA:
      lv_secret TYPE string.

    CLEAR : url.
    IF ( sy-sysid = 'X81' or sy-sysid = 'XC7' ).

      url = 'https://demoapiewb.exactgst.com/eway/api/EncryptLoginPayload'.
      im_subs_id = 'aeb7ab5b-ee59-4c89-88c2-550d9b7a54fb'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/gstcore/api/EncryptLoginPayload'.
      im_subs_id = '16c2dd70-09dd-47e5-bfd1-ab55e406b5e2'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    TRY.
        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        DATA(lo_request11) = lo_http_client->get_http_request( ).
        lo_request11->set_content_type( 'application/json; charset=utf-8' ).

        CLEAR: miw_string.
        IF ( sy-sysid = 'X81' or sy-sysid = 'XC7' ).

          miw_string = '{'
             && '"username":' && '"JUMPS_HR_1",'
             && '"password":' && '"123@Excellon",'
             && '"app_key":' &&  '"' && im_app_key && '",'
             && '"action":' &&  '"ACCESSTOKEN"'
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
             status    TYPE string,
             authtoken TYPE string,
             sek       TYPE string,
           END OF lty_irp_data.

    TYPES: BEGIN OF lty_encypt_eway,
             status TYPE string,
             data   TYPE string,
             rek    TYPE string,
             hmac   TYPE string,
           END OF lty_encypt_eway.


    DATA:
      lt_irp TYPE TABLE OF lty_irp_data,
      ls_irp TYPE lty_irp_data,
      lt_encypt_eway TYPE TABLE of lty_encypt_eway,
      ls_encypt_eway TYPE lty_encypt_eway.

    /ui2/cl_json=>deserialize(
                    EXPORTING json = im_irp_data
                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                       CHANGING data = lt_irp
                 ).

    /ui2/cl_json=>deserialize(
                    EXPORTING json = im_irn_encrypt
                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                       CHANGING data = lt_encypt_eway
                 ).

    READ TABLE lt_irp INTO ls_irp INDEX 1.
    READ TABLE lt_encypt_eway INTO ls_encypt_eway INDEX 1.

    CLEAR : url, im_subs_id.
    IF ( sy-sysid = 'X81' or sy-sysid = 'XC7' ).

      url = 'https://demoapiewb.exactgst.com/eway/api/DecryptDataSEK'.
      im_subs_id = 'aeb7ab5b-ee59-4c89-88c2-550d9b7a54fb'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/gstcore/api/DecryptDataSEK'.
      im_subs_id = '16c2dd70-09dd-47e5-bfd1-ab55e406b5e2'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    TRY.
        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        DATA(lo_request11) = lo_http_client->get_http_request( ).
        lo_request11->set_content_type( 'application/json; charset=utf-8' ).

        CLEAR: miw_string.
        miw_string = '{'
           && '"Data":' && '"' && ls_encypt_eway-data && '",'
           && '"rek":' && '"' && ls_encypt_eway-rek && '",'
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
             status    TYPE string,
             authtoken TYPE string,
             sek       TYPE string,
           END OF lty_irp_data.

    DATA:
      lt_irp    TYPE TABLE OF lty_irp_data,
      ls_irp    TYPE lty_irp_data,
      user_name TYPE string.

    CLEAR : url.
    IF ( sy-sysid = 'X81' or sy-sysid = 'XC7' ).

      url = 'https://demoapiewb.exactgst.com/ewaybillapi/v1.03/ewayapi/GetEwayBillGeneratedByConsigner?'.
      im_subs_id = 'aeb7ab5b-ee59-4c89-88c2-550d9b7a54fb'.
      im_gstin   = '06AAACJ9063D1ZQ'.
      user_name  = 'AnandNVH_06_1'.

    ELSE.

      url = 'https://einv.exactgst.com/eicore/v1.03/Invoice/irnbydocdetails?'.
      im_subs_id = '16c2dd70-09dd-47e5-bfd1-ab55e406b5e2'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    /ui2/cl_json=>deserialize(
                    EXPORTING json = im_irp_data
                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                       CHANGING data = lt_irp
                 ).

    READ TABLE lt_irp INTO ls_irp INDEX 1.


    url = url
          && 'docType=' && im_doc_typ
          && '&docNo=' && im_doc_num.
    "&& '&docdate=' && im_doc_date.

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
            i_value = user_name
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

*    SPLIT response_body11 AT '"data":' INTO DATA(split_1) DATA(split_2) .
*    SPLIT split_2 AT ',' INTO DATA(irn_encrypt) DATA(split_3) .
    r_irn_encrypt = '[' && response_body11 && ']'. "irn_encrypt.

  ENDMETHOD.


  METHOD get_excelon_app_key.

    DATA: url            TYPE string,
          lo_http_client TYPE REF TO if_web_http_client,
          miw_string     TYPE string.

    DATA:
      lv_secret TYPE string.

    CLEAR : url.
    IF ( sy-sysid = 'X81' or sy-sysid = 'XC7' ).

      url = 'https://demoapiewb.exactgst.com/eway/api/GenerateAppKeyString'.
      im_subs_id = 'aeb7ab5b-ee59-4c89-88c2-550d9b7a54fb'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/gstcore/api/GenerateAppKeyString'.
      im_subs_id = '16c2dd70-09dd-47e5-bfd1-ab55e406b5e2'.
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
    IF ( sy-sysid = 'X81' or sy-sysid = 'XC7' ).

      url = 'https://demoapiewb.exactgst.com/api/authentication/getAuthenticationToken'.
      im_subs_id = 'aeb7ab5b-ee59-4c89-88c2-550d9b7a54fb'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/api/authentication/getAuthenticationToken'.
      im_subs_id = '16c2dd70-09dd-47e5-bfd1-ab55e406b5e2'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ENDIF.

    TRY.
        DATA(dest11) = cl_http_destination_provider=>create_by_url( url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest11 ).

        IF ( sy-sysid = 'X81' or sy-sysid = 'XC7' ).

          lv_secret = '"9PNnAXaM4oUGvfWrWala8k3nI9IB54urwjxzek2WDagD3StZHU2ItCudzwUsJdST6v/EHipER5TeWvcfir3U390F7WP5pthK'
                   && 'sLjEMfWRtXQJiatX/sVeSJGyYkxed/tsR0WoWGkzgicPdsdW2LI55w5i1MereSY+3kqiluZ7540lVJ5PmIE0tAqhbPY/ySI'
                   && 'iyG2phT4pq+ZnoV4LeRlOAq9v4YIcflIAROYOb/S65P0EEpy0QV7DpQmjKJ6jj+ye/tiE5REQMb4tuc8YyBlHVfVF76Mg13j'
                   && '1X2ircJXEJ1QDlx4HGcoBzNdo9E3KCK1As4+5cObP0BcvECqDrYjB2w=="'.

          CLEAR: miw_string.
          miw_string = '{'
                  && '"ClientId":' && '"bec861ce-11ea-4eae-9b6b-a9bde8c2cd88",'
                  && '"ClientSecret":' && lv_secret
                  && '}'.

        ELSE.

          lv_secret = '"OGVIyux2QoNgbYWlirgM+Vv+1ALSPZ02qV1B7xozz5ipn7/BXBwYFaholOUC8RlcbFAu+Nc9XQnSQlSyqIs978GbUrg+9NJ'
                   && 'zlo8yX1T4euYAFk+gFHQfv+a+wExbEYaQIK9w1xPdMOmCJT70+cd8xxbPmzddTOdqcZU12jRfNFmfkHYhWVOO7CePouwX62eh'
                   && 'BBdnlwsslZGud6ve0efwWMDx06sWdVFJhQiOtoSJQ5xFCY6CwExKDeUOkoBy4jnPTIHYV1tpivftZPTrNJ+tNLglpDiaoYUF7K'
                   && 'gJ7FR4+DfEQOaInD7WrWIuezIWiWwm4ukFETHWFQkVIO5LX06uhQ=="'.

          CLEAR: miw_string.
          miw_string = '{'
                  && '"ClientId":' && '"b0264502-24ac-4983-8461-92dfd1481f12",'
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

    IF ( sy-sysid = 'X81' or sy-sysid = 'XC7' ).

      url = 'https://demoapiewb.exactgst.com/ewaybillapi/v1.03/Auth'.
      im_subs_id = 'aeb7ab5b-ee59-4c89-88c2-550d9b7a54fb'.
      im_gstin   = '06AAACJ9063D1ZQ'.

    ELSE.

      url = 'https://einv.exactgst.com/eivital/v1.04/auth'.
      im_subs_id = '16c2dd70-09dd-47e5-bfd1-ab55e406b5e2'.
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

*    SPLIT response_body11 AT '"Data":' INTO DATA(split_1) DATA(split_2) .
*    SPLIT split_2 AT '},' INTO DATA(token) DATA(split_3) .
    r_irp_data = '[' && response_body11 && ']'.

  ENDMETHOD.
ENDCLASS.
