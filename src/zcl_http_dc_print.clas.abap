CLASS zcl_http_dc_print DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: xt_dbnote  TYPE TABLE OF zstr_dc_data.

    INTERFACES if_http_service_extension .

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_HTTP_DC_PRINT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA: lv_action1 TYPE char10,
          lv_bukrs   TYPE char4,
          lv_belnr   TYPE char10,
          lv_gjahr   TYPE numc4,
          lv_budat   TYPE sy-datum,
          xt_acc     TYPE TABLE OF zstr_acc_data,
          xt_dcnote  TYPE TABLE OF zstr_dc_data,
          xs_dcnote  TYPE zstr_dc_data.

    DATA: lo_client TYPE REF TO zcl_dc_print,
          lo_ads    TYPE REF TO zcl_ads_service.

    DATA: ls_xml_base64   TYPE string,
          lv_access_token TYPE string,
          rv_response     TYPE string,
          miw_string      TYPE string.

    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action1 = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'accountingdocument'.
    IF sy-subrc EQ 0.
      lv_belnr = ls_input-value.
    ENDIF.
    lv_belnr = |{ lv_belnr ALPHA = IN }| .

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'companycode'.
    IF sy-subrc EQ 0.
      lv_bukrs = ls_input-value.
    ENDIF.

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'fiscalyear'.
    IF sy-subrc EQ 0.
      lv_gjahr = ls_input-value.
    ENDIF.

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'postingdate'.
    IF sy-subrc EQ 0.
      lv_budat = ls_input-value.
    ENDIF.

    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    IF lv_action1 = 'dcnote'. "AND lv_action2 = 'print'.

      lv_access_token = lo_ads->get_ads_access_token(  ).

      lo_client->get_dcnote_data(
        EXPORTING
          im_bukrs  = lv_bukrs
          im_belnr  = lv_belnr
          im_gjahr  = lv_gjahr
          im_action = lv_action1
        RECEIVING
          et_dcdata =  xt_dcnote
      ).

      ls_xml_base64 = lo_client->prep_xml_dcnote( it_dcnote = xt_dcnote[] im_action = lv_action1 ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZFI_FORM_DC_NOTE/ZFI_JUMPS_DC_NOTE'
        im_xml_base64    = ls_xml_base64 ).

*""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_response ).

    ENDIF.

    IF lv_action1 = 'payadv'.

      lv_access_token = lo_ads->get_ads_access_token(  ).

      lo_client->get_payadv_data(
        EXPORTING
          im_bukrs  = lv_bukrs
          im_belnr  = lv_belnr
          im_gjahr  = lv_gjahr
          im_action = lv_action1
        RECEIVING
          et_payadv =  xt_dbnote
      ).

      ls_xml_base64 = lo_client->prep_xml_payadv( it_payadv = xt_dbnote[] im_action = lv_action1 ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZFI_FORM_PAY_ADV/ZSD_JUMPS_FI_PAY_ADV'
        im_xml_base64    = ls_xml_base64 ).

*""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_response ).

    ENDIF.

  ENDMETHOD.
ENDCLASS.
