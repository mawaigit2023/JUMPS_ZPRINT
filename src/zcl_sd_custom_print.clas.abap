    CLASS zcl_sd_custom_print DEFINITION
      PUBLIC
      FINAL
      CREATE PUBLIC .

      PUBLIC SECTION.
        DATA:
          gt_final  TYPE TABLE OF zi_sale_reg,
          gt_sodata TYPE TABLE OF zstr_so_data.

        METHODS:

          get_billing_data
            IMPORTING
                      iv_vbeln        TYPE char10
                      iv_action       TYPE char10
            RETURNING VALUE(et_final) LIKE gt_final,

          prep_xml_tax_inv
            IMPORTING
                      it_final             LIKE gt_final
                      iv_action            TYPE char10
                      im_prntval           TYPE char10
            RETURNING VALUE(iv_xml_base64) TYPE string,

          get_packing_data
            IMPORTING
                      im_pack         TYPE char10
                      iv_action       TYPE char10
            RETURNING VALUE(et_final) LIKE gt_final,

          prep_xml_pack_inv
            IMPORTING
                      it_final             LIKE gt_final
                      iv_action            TYPE char10
                      im_prntval           TYPE char10
                      im_pack              TYPE char10
            RETURNING VALUE(iv_xml_base64) TYPE string,

          get_sales_data
            IMPORTING
                      iv_vbeln        TYPE char10
                      iv_action       TYPE char10
            RETURNING VALUE(et_final) LIKE gt_sodata,

          prep_xml_so_prnt
            IMPORTING
                      it_final             LIKE gt_sodata
                      iv_action            TYPE char10
                      im_prntval           TYPE char10
            RETURNING VALUE(iv_xml_base64) TYPE string.

      PROTECTED SECTION.
      PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SD_CUSTOM_PRINT IMPLEMENTATION.


      METHOD get_billing_data.

        """*****************Start: Fetch & Prepare Data******************************

        DATA : lv_billtype TYPE RANGE OF zi_sale_reg-billingdocumenttype,
               wa_billtype LIKE LINE OF  lv_billtype,
               lv_distchnl TYPE RANGE OF zi_sale_reg-distributionchannel,
               wa_distchnl LIKE LINE  OF lv_distchnl.

        IF iv_action = 'taxinv' .

          wa_billtype-low  = 'F2' .
          wa_billtype-high  = '' .
          wa_billtype-option  = 'EQ' .
          wa_billtype-sign  = 'I' .
          APPEND  wa_billtype TO lv_billtype .

          wa_billtype-low  = 'F8' .
          wa_billtype-high  = '' .
          wa_billtype-option  = 'EQ' .
          wa_billtype-sign  = 'I' .
          APPEND  wa_billtype TO lv_billtype .

          wa_distchnl-low  = '30' .
          wa_distchnl-high  = '' .
          wa_distchnl-option  = 'EQ' .
          wa_distchnl-sign  = 'I' .
          APPEND wa_distchnl TO lv_distchnl .

        ELSEIF iv_action = 'oeminv' .

          wa_billtype-low  = 'F2' .
          wa_billtype-high  = '' .
          wa_billtype-option  = 'EQ' .
          wa_billtype-sign  = 'I' .
          APPEND  wa_billtype TO lv_billtype .

          wa_distchnl-low  = '10' .
          wa_distchnl-high  = '' .
          wa_distchnl-option  = 'EQ' .
          wa_distchnl-sign  = 'I' .
          APPEND wa_distchnl TO lv_distchnl .

          wa_distchnl-low  = '40' .
          wa_distchnl-high  = '' .
          wa_distchnl-option  = 'EQ' .
          wa_distchnl-sign  = 'I' .
          APPEND wa_distchnl TO lv_distchnl .

          wa_distchnl-low  = '50' .
          wa_distchnl-high  = '' .
          wa_distchnl-option  = 'EQ' .
          wa_distchnl-sign  = 'I' .
          APPEND wa_distchnl TO lv_distchnl .

          wa_distchnl-low  = '60' .
          wa_distchnl-high  = '' .
          wa_distchnl-option  = 'EQ' .
          wa_distchnl-sign  = 'I' .
          APPEND wa_distchnl TO lv_distchnl .

          wa_distchnl-low  = '70' .
          wa_distchnl-high  = '' .
          wa_distchnl-option  = 'EQ' .
          wa_distchnl-sign  = 'I' .
          APPEND wa_distchnl TO lv_distchnl .

        ELSEIF iv_action = 'dcnote' .

          wa_billtype-low  = 'G2' .
          wa_billtype-high  = '' .
          wa_billtype-option  = 'EQ' .
          wa_billtype-sign  = 'I' .
          APPEND  wa_billtype TO lv_billtype .

          wa_billtype-low  = 'CBRE' .
          wa_billtype-high  = '' .
          wa_billtype-option  = 'EQ' .
          wa_billtype-sign  = 'I' .
          APPEND  wa_billtype TO lv_billtype .

          wa_billtype-low  = 'L2' .
          wa_billtype-high  = '' .
          wa_billtype-option  = 'EQ' .
          wa_billtype-sign  = 'I' .
          APPEND  wa_billtype TO lv_billtype .

        ELSEIF iv_action = 'dchlpr' .

          wa_billtype-low  = 'JSN' .
          wa_billtype-high  = '' .
          wa_billtype-option  = 'EQ' .
          wa_billtype-sign  = 'I' .
          APPEND  wa_billtype TO lv_billtype .

          wa_billtype-low  = 'F8' .
          wa_billtype-high  = '' .
          wa_billtype-option  = 'EQ' .
          wa_billtype-sign  = 'I' .
          APPEND  wa_billtype TO lv_billtype .

        ELSEIF iv_action = 'aftinv' .

          wa_billtype-low  = 'F2' .
          wa_billtype-high  = '' .
          wa_billtype-option  = 'EQ' .
          wa_billtype-sign  = 'I' .
          APPEND  wa_billtype TO lv_billtype .

          wa_distchnl-low  = '20' .
          wa_distchnl-high  = '' .
          wa_distchnl-option  = 'EQ' .
          wa_distchnl-sign  = 'I' .
          APPEND wa_distchnl TO lv_distchnl .

        ENDIF.


        SELECT * FROM zi_sale_reg  WHERE billingdocument = @iv_vbeln
                                    AND billingdocumenttype IN @lv_billtype
                                    AND distributionchannel IN @lv_distchnl
                                        INTO TABLE @DATA(it_final) .

        IF it_final IS NOT INITIAL.

          et_final[] = it_final[].
          """*****************End: Fetch & Prepare Data********************************

          """*******Start: IRN Data processing******************************************************
          DATA: lo_irn  TYPE REF TO zcl_get_irn_detail,
                lo_eway TYPE REF TO zcl_get_eway_detail.

          TYPES: BEGIN OF lty_irn_data,
                   ackno         TYPE string,
                   ackdt         TYPE string,
                   irn           TYPE string,
                   signedinvoice TYPE string,
                   signedqrcode  TYPE string,
                   status        TYPE string,
                   ewbno         TYPE string,
                   ewbdt         TYPE string,
                   ewbvalidtill  TYPE string,
                   remarks       TYPE string,
                 END OF lty_irn_data.

          TYPES: BEGIN OF lty_eway_data,
                   ewaybillno   TYPE string,
                   ewaybilldate TYPE string,
                   validupto    TYPE string,
                   alert        TYPE string,
                 END OF lty_eway_data.

          DATA:
            lt_irn      TYPE TABLE OF lty_irn_data,
            ls_irn      TYPE lty_irn_data,
            gt_irn      TYPE TABLE OF zsd_einvoice,
            gs_irn      TYPE zsd_einvoice,
            gt_eway     TYPE TABLE OF zsd_eway_data,
            gs_eway     TYPE zsd_eway_data,
            lt_eway     TYPE TABLE OF lty_eway_data,
            ls_eway     TYPE lty_eway_data,
            lv_doc_num  TYPE string,
            lv_doc_typ  TYPE string,
            lv_doc_date TYPE string,
            lv_sysid    TYPE zsd_sysid-sysid.

          CREATE OBJECT lo_irn.
          CREATE OBJECT lo_eway.

          READ TABLE it_final INTO DATA(xs_final) INDEX 1.

          SELECT SINGLE * FROM zsd_sysid
                          WHERE objcode = 'IRN' AND sysid = @sy-sysid
                          INTO @DATA(ls_sysid).
          IF sy-subrc EQ 0.
            lv_sysid = ls_sysid-sysid.
          ENDIF.

          SELECT SINGLE * FROM zsd_einvoice WHERE billingdocument = @xs_final-billingdocument
            INTO @DATA(w_einvvoicex) .

          IF sy-subrc NE 0 AND sy-sysid = lv_sysid.

            "upload_sample_data(  ).
            DATA(lv_auth_token) = lo_irn->get_excelon_auth_token(  ).
            DATA(lv_app_key)    = lo_irn->get_excelon_app_key( im_access_token = lv_auth_token  ).
            DATA(lv_encypt_login_data) = lo_irn->encrypt_logon_detail( im_auth_token = lv_auth_token im_app_key = lv_app_key ).
            DATA(lv_irp_data) = lo_irn->get_irp_token( im_auth_token = lv_auth_token im_encrypt_login = lv_encypt_login_data ).

            lv_doc_num  = xs_final-documentreferenceid.
            lv_doc_typ  = xs_final-doc_type.
            lv_doc_date = xs_final-billingdocumentdate+6(2) && '/' && xs_final-billingdocumentdate+4(2) && '/' && xs_final-billingdocumentdate+0(4).

            DATA(lv_encrypt_irn_data) = lo_irn->get_encrypty_irn_detail(
                                        im_auth_token = lv_auth_token
                                        im_irp_data   = lv_irp_data
                                        im_doc_num    = lv_doc_num
                                        im_doc_typ    = lv_doc_typ
                                        im_doc_date   = lv_doc_date
                                         ).

            DATA(lv_irn_data) = lo_irn->get_decrypted_doc(
                                  im_auth_token  = lv_auth_token
                                  im_irp_data    = lv_irp_data
                                  im_irn_encrypt = lv_encrypt_irn_data
                                  im_app_key     = lv_app_key
                                ).

            /ui2/cl_json=>deserialize(
                            EXPORTING json = lv_irn_data
                               pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                               CHANGING data = lt_irn
                         ).

            DATA: lv_irn TYPE string.

            IF lt_irn[] IS NOT INITIAL.

              READ TABLE lt_irn INTO ls_irn INDEX 1.

              IF ls_irn-ackno IS NOT INITIAL.

                MOVE-CORRESPONDING ls_irn TO gs_irn.

                gs_irn-billingdocument = xs_final-billingdocument.
                gs_irn-plant_gstin     = '06AAACJ9063D1ZQ'.
                gs_irn-erdat     = sy-datum.
                gs_irn-uname     = sy-uname.
                gs_irn-ackdt     = sy-datum.
                gs_irn-uzeit     = sy-uzeit.

                APPEND gs_irn TO gt_irn.

              ENDIF.

              IF gt_irn[] IS NOT INITIAL.
                MODIFY zsd_einvoice FROM TABLE @gt_irn.
              ENDIF.

            ENDIF.


            ""***Start: Fetching eway Bill in case of Challan(i.e Without IRN)
            IF gt_irn[] IS INITIAL.

              CLEAR: lv_auth_token, lv_app_key, lv_encypt_login_data, lv_irp_data.
              lv_auth_token         = lo_eway->get_excelon_auth_token(  ).
              lv_app_key            = lo_eway->get_excelon_app_key( im_access_token = lv_auth_token  ).
              lv_encypt_login_data  = lo_eway->encrypt_logon_detail( im_auth_token = lv_auth_token im_app_key = lv_app_key ).
              lv_irp_data           = lo_eway->get_irp_token( im_auth_token = lv_auth_token im_encrypt_login = lv_encypt_login_data ).

              lv_doc_num  = xs_final-billingdocument.
              lv_doc_typ  = 'CHL'.

              DATA(lv_encrypt_eway_data) = lo_eway->get_encrypty_irn_detail(
                                          im_auth_token = lv_auth_token
                                          im_irp_data   = lv_irp_data
                                          im_doc_num    = lv_doc_num
                                          im_doc_typ    = lv_doc_typ
                                          im_doc_date   = lv_doc_date
                                           ).

              DATA(lv_eway_data) = lo_eway->get_decrypted_doc(
                                    im_auth_token  = lv_auth_token
                                    im_irp_data    = lv_irp_data
                                    im_irn_encrypt = lv_encrypt_eway_data
                                    im_app_key     = lv_app_key
                                  ).

              /ui2/cl_json=>deserialize(
                              EXPORTING json = lv_eway_data
                                 pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                                 CHANGING data = lt_eway
                           ).

              IF lt_eway[] IS NOT INITIAL.

                READ TABLE lt_eway INTO ls_eway INDEX 1.

                gs_irn-billingdocument = xs_final-billingdocument.
                gs_irn-plant_gstin     = '06AAACJ9063D1ZQ'.
                gs_irn-ewbno           = ls_eway-ewaybillno.
                gs_irn-ewbdt           = ls_eway-ewaybilldate.
                gs_irn-ewbvalidtill    = ls_eway-validupto.
                gs_irn-erdat     = sy-datum.
                gs_irn-uname     = sy-uname.
                gs_irn-ackdt     = sy-datum.
                gs_irn-uzeit     = sy-uzeit.

                APPEND gs_irn TO gt_irn.
                IF gt_irn[] IS NOT INITIAL.
                  MODIFY zsd_einvoice FROM TABLE @gt_irn.
                ENDIF.

              ENDIF.

            ENDIF.
            ""***End: Fetching eway Bill in case of Challan(i.e Without IRN)

          ELSE.

            IF w_einvvoicex-irn IS NOT INITIAL
               AND w_einvvoicex-ewbno IS INITIAL
               AND sy-sysid = lv_sysid.

              CLEAR: lv_auth_token,
                     lv_app_key ,
                     lv_encypt_login_data,
                     lv_irp_data,
                     lv_encrypt_irn_data,
                     lv_irn_data,
                     lt_irn,
                     lv_irn.

              lv_auth_token = lo_irn->get_excelon_auth_token(  ).
              lv_app_key    = lo_irn->get_excelon_app_key( im_access_token = lv_auth_token  ).
              lv_encypt_login_data = lo_irn->encrypt_logon_detail( im_auth_token = lv_auth_token im_app_key = lv_app_key ).
              lv_irp_data = lo_irn->get_irp_token( im_auth_token = lv_auth_token im_encrypt_login = lv_encypt_login_data ).

              lv_doc_num  = xs_final-documentreferenceid.
              lv_doc_typ  = xs_final-doc_type.
              lv_doc_date = xs_final-billingdocumentdate+6(2) && '/' && xs_final-billingdocumentdate+4(2) && '/' && xs_final-billingdocumentdate+0(4).

              lv_encrypt_irn_data = lo_irn->get_encrypty_irn_detail(
                                          im_auth_token = lv_auth_token
                                          im_irp_data   = lv_irp_data
                                          im_doc_num    = lv_doc_num
                                          im_doc_typ    = lv_doc_typ
                                          im_doc_date   = lv_doc_date
                                           ).

              lv_irn_data = lo_irn->get_decrypted_doc(
                                    im_auth_token  = lv_auth_token
                                    im_irp_data    = lv_irp_data
                                    im_irn_encrypt = lv_encrypt_irn_data
                                    im_app_key     = lv_app_key
                                  ).

              /ui2/cl_json=>deserialize(
                              EXPORTING json = lv_irn_data
                                 pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                                 CHANGING data = lt_irn
                           ).

              IF lt_irn[] IS NOT INITIAL.

                READ TABLE lt_irn INTO ls_irn INDEX 1.

                IF ls_irn-ackno IS NOT INITIAL.

                  MOVE-CORRESPONDING ls_irn TO gs_irn.

                  gs_irn-billingdocument = xs_final-billingdocument.
                  gs_irn-plant_gstin     = '06AAACJ9063D1ZQ'.
                  gs_irn-erdat     = sy-datum.
                  gs_irn-uname     = sy-uname.
                  gs_irn-ackdt     = sy-datum.
                  gs_irn-uzeit     = sy-uzeit.

*******************Start: Get Eway Detail in case not generated using IRN(DocType not equal to Challan)**
                  IF ls_irn-ewbno IS INITIAL.

                    CLEAR: lv_auth_token,
                    lv_app_key,
                    lv_encypt_login_data,
                    lv_irp_data,
                    lv_encrypt_eway_data,
                    lv_eway_data,
                    lt_eway.

                    lv_auth_token         = lo_eway->get_excelon_auth_token(  ).
                    lv_app_key            = lo_eway->get_excelon_app_key( im_access_token = lv_auth_token  ).
                    lv_encypt_login_data  = lo_eway->encrypt_logon_detail( im_auth_token = lv_auth_token im_app_key = lv_app_key ).
                    lv_irp_data           = lo_eway->get_irp_token( im_auth_token = lv_auth_token im_encrypt_login = lv_encypt_login_data ).

                    lv_doc_num  = xs_final-billingdocument.
                    lv_doc_typ  = xs_final-doc_type.

                    lv_encrypt_eway_data = lo_eway->get_encrypty_irn_detail(
                                                im_auth_token = lv_auth_token
                                                im_irp_data   = lv_irp_data
                                                im_doc_num    = lv_doc_num
                                                im_doc_typ    = lv_doc_typ
                                                im_doc_date   = lv_doc_date
                                                 ).

                    lv_eway_data = lo_eway->get_decrypted_doc(
                                          im_auth_token  = lv_auth_token
                                          im_irp_data    = lv_irp_data
                                          im_irn_encrypt = lv_encrypt_eway_data
                                          im_app_key     = lv_app_key
                                        ).

                    /ui2/cl_json=>deserialize(
                                    EXPORTING json = lv_eway_data
                                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                                       CHANGING data = lt_eway
                                 ).

                    IF lt_eway[] IS NOT INITIAL.

                      READ TABLE lt_eway INTO ls_eway INDEX 1.

                      gs_irn-ewbno           = ls_eway-ewaybillno.
                      gs_irn-ewbdt           = ls_eway-ewaybilldate.
                      gs_irn-ewbvalidtill    = ls_eway-validupto.

                    ENDIF.

                  ENDIF.
*******************Start: Get Eway Detail in case not generated using IRN(DocType not equal to Challan)**


                  APPEND gs_irn TO gt_irn.
                ENDIF.

                IF gt_irn[] IS NOT INITIAL.
                  MODIFY zsd_einvoice FROM TABLE @gt_irn.
                ENDIF.

              ENDIF.

            ENDIF.

          ENDIF .
          """*******End: IRN Data processing******************************************************

        ENDIF.

      ENDMETHOD.


      METHOD get_packing_data.

        """*****************Start: Fetch & Prepare Data******************************


        SELECT * FROM zsd_pack_data WHERE pack_num = @im_pack ORDER BY PRIMARY KEY
         INTO @DATA(wa_pack_data1)
         UP TO 1 ROWS .
        ENDSELECT.

        SELECT * FROM zi_sale_reg
        WHERE billingdocument    = @wa_pack_data1-vbeln AND
              "BillingDocumentType = 'F2' AND
              bill_to_party NE '' AND
              billingdocumentiscancelled = ''
        INTO TABLE @DATA(it_final) .


        et_final[] = it_final[].

        """*****************End: Fetch & Prepare Data********************************

      ENDMETHOD.


      METHOD get_sales_data.

        DATA: gt_sohdr     TYPE TABLE OF zstr_so_data,
              gs_sohdr     TYPE zstr_so_data,
              gt_item      TYPE TABLE OF zstr_so_item,
              gs_item      TYPE zstr_so_item,
              lv_grand_tot TYPE p LENGTH 16 DECIMALS 2,
              lv_sum_igst  TYPE p LENGTH 16 DECIMALS 2,
              lv_sum_qty   TYPE p LENGTH 16 DECIMALS 0,
              lv_itm_qty   TYPE p LENGTH 16 DECIMALS 0,
              lv_tot_amt   TYPE p LENGTH 16 DECIMALS 2.

        SELECT * FROM i_salesdocument
                 WHERE salesdocument = @iv_vbeln
                 INTO TABLE @DATA(lt_sohdr).

        IF lt_sohdr[] IS NOT INITIAL.

          SELECT * FROM i_salesdocumentitem
                   WHERE salesdocument = @iv_vbeln
                   INTO TABLE @DATA(lt_soitem).

          SELECT * FROM i_salesdocitempricingelement
                   WHERE salesdocument = @iv_vbeln
                   INTO TABLE @DATA(lt_soitem_price).

          SELECT * FROM zi_so_partner
                   WHERE salesdocument = @iv_vbeln
                   INTO TABLE @DATA(lt_sopart).

          SELECT * FROM i_product
                   FOR ALL ENTRIES IN @lt_soitem
                   WHERE product  = @lt_soitem-product
                   INTO TABLE @DATA(lt_product).

          SELECT * FROM i_salesdocumentscheduleline
                   WHERE salesdocument = @iv_vbeln
                   INTO TABLE @DATA(lt_schdl).

        ENDIF.

        LOOP AT lt_sohdr INTO DATA(ls_sohdr).

          gs_sohdr-saleorder = ls_sohdr-salesdocument.

          """"" plant address       hardcode .....
          gs_sohdr-exptr_code = '' .
          gs_sohdr-exptr_name = 'Jumps Auto Industries Limited' .
          gs_sohdr-exptr_addrs1 = '125, Pace City 1, ' .
          gs_sohdr-exptr_addrs2 = 'Sector 37 ' .
          gs_sohdr-exptr_addrs3 = 'Gurugram-122001' .
          gs_sohdr-exptr_addrs4 = 'India' .

          """" factory address
          gs_sohdr-fact_addrs1 = '125, Pace City 1, ' .
          gs_sohdr-fact_addrs2 = 'Sector 37 Gurugram-122001'.
          gs_sohdr-fact_addrs3 = 'India' .

          gs_sohdr-our_ref          = ls_sohdr-salesdocument.
          gs_sohdr-our_ref_date     = ls_sohdr-salesdocumentdate+6(2) && '.' && ls_sohdr-salesdocumentdate+4(2) && '.' && ls_sohdr-salesdocumentdate+0(4).
          gs_sohdr-cust_odr_ref     = ls_sohdr-purchaseorderbycustomer .
          gs_sohdr-cust_odr_date    = ls_sohdr-customerpurchaseorderdate+6(2) && '.' && ls_sohdr-customerpurchaseorderdate+4(2) && '.' && ls_sohdr-customerpurchaseorderdate+0(4).
          gs_sohdr-buyr_code        = ls_sohdr-soldtoparty .
          gs_sohdr-inco_term        = ls_sohdr-incotermsclassification.
          gs_sohdr-price_term       = ls_sohdr-incotermslocation1. "IncotermsClassification.
          gs_sohdr-amtount_curr     = ls_sohdr-transactioncurrency.

          SELECT SINGLE * FROM i_customerpaymenttermstext
                          WHERE customerpaymentterms = @ls_sohdr-customerpaymentterms
                            AND language = 'E'
                          INTO @DATA(ls_payterm_desc).

          gs_sohdr-pay_term   = ls_payterm_desc-customerpaymenttermsname.

          DATA : lv_shp_adr1 TYPE char100,
                 lv_shp_adr2 TYPE char100,
                 lv_shp_adr3 TYPE char100,
                 lv_shp_adr4 TYPE char100.

          DATA : lv_sold_adr1 TYPE char100,
                 lv_sold_adr2 TYPE char100,
                 lv_sold_adr3 TYPE char100,
                 lv_sold_adr4 TYPE char100.

          READ TABLE lt_sopart INTO DATA(ls_sopart) WITH KEY salesdocument = ls_sohdr-salesdocument.
          IF ls_sopart-we_street IS NOT INITIAL .
            IF lv_shp_adr1 IS NOT INITIAL   .
              lv_shp_adr1 = |{ lv_shp_adr1 } , { ls_sopart-we_street }, { ls_sopart-we_streetprefixname1 }, { ls_sopart-we_streetprefixname2 }, { ls_sopart-we_streetsuffixname1 }| .
            ELSE .
              lv_shp_adr1 = |{ ls_sopart-we_street }, { ls_sopart-we_streetprefixname1 }, { ls_sopart-we_streetprefixname2 }, { ls_sopart-we_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          IF ls_sopart-we_street1 IS NOT INITIAL .
            IF lv_shp_adr1 IS NOT INITIAL   .
              lv_shp_adr1 = |{ lv_shp_adr1 } , { ls_sopart-we_street1 }, { ls_sopart-we_streetprefixname1 }, { ls_sopart-we_streetprefixname2 }, { ls_sopart-we_streetsuffixname1 }| .
            ELSE .
              lv_shp_adr1 = |{ ls_sopart-we_street1 }, { ls_sopart-we_streetprefixname1 }, { ls_sopart-we_streetprefixname2 }, { ls_sopart-we_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          DATA(len) = strlen( lv_shp_adr1 ) .
          len = len - 40.
          IF strlen( lv_shp_adr1 ) GT 40 .
            lv_shp_adr2 = |{ lv_shp_adr1+40(len) },| .
            lv_shp_adr1 = lv_shp_adr1+0(40) .
          ENDIF .

          READ TABLE lt_sopart INTO DATA(ls_sopart_ag) WITH KEY salesdocument = ls_sohdr-salesdocument.
          IF ls_sopart_ag-ag_street IS NOT INITIAL .
            IF lv_sold_adr1 IS NOT INITIAL   .
              lv_sold_adr1 = |{ lv_sold_adr1 } , { ls_sopart_ag-ag_street }, { ls_sopart_ag-ag_streetprefixname1 }, { ls_sopart_ag-ag_streetprefixname2 }, { ls_sopart_ag-ag_streetsuffixname1 }| .
            ELSE .
              lv_sold_adr1 = |{ ls_sopart_ag-ag_street }, { ls_sopart_ag-ag_streetprefixname1 }, { ls_sopart_ag-ag_streetprefixname2 }, { ls_sopart_ag-ag_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          IF ls_sopart_ag-ag_street1 IS NOT INITIAL .
            IF lv_sold_adr1 IS NOT INITIAL   .
              lv_sold_adr1 = |{ lv_sold_adr1 } , { ls_sopart_ag-ag_street1 }, { ls_sopart_ag-ag_streetprefixname1 }, { ls_sopart_ag-ag_streetprefixname2 }, { ls_sopart_ag-ag_streetsuffixname1 }| .
            ELSE .
              lv_sold_adr1 = |{ ls_sopart_ag-ag_street1 }, { ls_sopart_ag-ag_streetprefixname1 }, { ls_sopart_ag-ag_streetprefixname2 }, { ls_sopart_ag-ag_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          DATA(len_ag) = strlen( lv_sold_adr1 ) .
          len_ag = len_ag - 40.
          IF strlen( lv_sold_adr1 ) GT 40 .
            lv_sold_adr2 = |{ lv_sold_adr1+40(len_ag) },| .
            lv_sold_adr1 = lv_sold_adr1+0(40) .
          ENDIF .

          SELECT SINGLE * FROM i_countrytext   WHERE country = @ls_sopart_ag-ag_country AND language = 'E'
          INTO @DATA(lv_cn_nm).

          SELECT SINGLE * FROM i_regiontext  WHERE region = @ls_sopart_ag-ag_region AND language = 'E' AND country = @ls_sopart_ag-ag_country
          INTO @DATA(lv_st_name_ag).

          lv_sold_adr3 = ls_sopart_ag-ag_city && '-' && ls_sopart_ag-ag_pin && ',' && lv_cn_nm-countryname.
          lv_sold_adr4 = lv_st_name_ag-RegionName. "ls_sopart_ag-ag_region && '(' && lv_st_name_ag-RegionName && ')'.
          gs_sohdr-buyr_name        = ls_sopart_ag-ag_name.
          gs_sohdr-buyr_addrs1      = lv_sold_adr1.
          gs_sohdr-buyr_addrs2      = lv_sold_adr2.
          gs_sohdr-buyr_addrs3      = lv_sold_adr3.
          gs_sohdr-buyr_addrs4      = ''. "lv_sold_adr4.

          SELECT SINGLE * FROM i_countrytext   WHERE country = @ls_sopart-we_country AND language = 'E'
          INTO @DATA(lv_cn_nm1).

          SELECT SINGLE * FROM i_regiontext  WHERE region = @ls_sopart-we_region AND language = 'E' AND country = @ls_sopart-we_country
          INTO @DATA(lv_st_name_we1).

          lv_shp_adr3 = ls_sopart-we_city && '-' && ls_sopart-we_pin && ',' && lv_cn_nm1-countryname.
          lv_shp_adr4 = lv_st_name_we1-RegionName. "ls_sopart-we_region && '(' && lv_st_name_we1-RegionName && ')'.

          gs_sohdr-cnsinee_code     = ''.
          gs_sohdr-cnsinee_name     = ls_sopart-we_name.
          gs_sohdr-cnsinee_addrs1   = lv_shp_adr1.
          gs_sohdr-cnsinee_addrs2   = lv_shp_adr2.
          gs_sohdr-cnsinee_addrs3   = lv_shp_adr3.
          gs_sohdr-cnsinee_addrs4   = ''. "lv_shp_adr4.

          IF ls_sopart_ag-ag_code EQ ls_sopart-ship_to_party.
            gs_sohdr-cnsinee_name = 'Same as buyer'.
            CLEAR: gs_sohdr-cnsinee_addrs1, gs_sohdr-cnsinee_addrs2, gs_sohdr-cnsinee_addrs3, gs_sohdr-cnsinee_addrs4.
          ENDIF.

          gs_sohdr-ship_mode        = ''.
          gs_sohdr-port_disch       = ''.
          gs_sohdr-port_delivry     = ''.
          gs_sohdr-pinst_box        = ''.
          gs_sohdr-pinst_stickr     = ''.
          gs_sohdr-pinst_make       = ''.
          gs_sohdr-made_in_india    = ''.
          gs_sohdr-making_inst      = ''.


          LOOP AT lt_soitem INTO DATA(ls_souitem) WHERE salesdocument = ls_sohdr-salesdocument.


            gs_item-saleorder       = ls_souitem-salesdocument.
            gs_item-saleitem        = ls_souitem-salesdocumentitem.
            gs_item-sr_num          = ls_souitem-salesdocumentitem.
            gs_item-byur_code       = ls_souitem-materialbycustomer .

            READ TABLE lt_product INTO DATA(ls_product) WITH KEY product = ls_souitem-product.
            gs_item-item_code       = ls_product-productoldid.
            CLEAR: ls_product.

            gs_item-item_desc       = ls_souitem-salesdocumentitemtext .
            lv_itm_qty = ls_souitem-orderquantity.
            gs_item-item_qty        = lv_itm_qty.
            SHIFT gs_item-item_qty LEFT DELETING LEADING ''.
            lv_sum_qty = lv_sum_qty + ls_souitem-orderquantity.

            gs_item-item_uom        = ls_souitem-orderquantityunit.

            IF gs_item-item_uom = 'ST'.
              gs_item-item_uom = 'PC'.
            ENDIF.

            READ TABLE lt_schdl INTO DATA(ls_schdl) WITH KEY salesdocument = ls_souitem-salesdocument
                                                             salesdocumentitem = ls_souitem-salesdocumentitem.

            gs_item-dispatch_date   = ls_schdl-deliverydate+6(2) && '.' && ls_schdl-deliverydate+4(2) && '.' && ls_schdl-deliverydate+0(4).

            READ TABLE lt_soitem_price INTO DATA(w_item_price)
             WITH KEY salesdocument = ls_sohdr-salesdocument
                      salesdocumentitem = ls_souitem-salesdocumentitem
                      conditiontype = 'PPR0'.

            IF sy-subrc = 0 .
              gs_item-price_usd_fob   = w_item_price-conditionratevalue / w_item_price-conditionquantity .
              gs_item-amt_usd_fob     = gs_item-price_usd_fob * ls_souitem-orderquantity .
              lv_tot_amt = lv_tot_amt + gs_item-amt_usd_fob.
            ENDIF .

            READ TABLE lt_soitem_price INTO w_item_price
            WITH KEY salesdocument = ls_sohdr-salesdocument
                     salesdocumentitem = ls_souitem-salesdocumentitem
                     conditiontype = 'ZDIS'.
            IF sy-subrc = 0 .
              gs_sohdr-disc_amt = gs_sohdr-disc_amt + w_item_price-conditionamount.
            ENDIF .

            READ TABLE lt_soitem_price INTO DATA(w_item_igst)
             WITH KEY salesdocument = ls_sohdr-salesdocument
                      salesdocumentitem = ls_souitem-salesdocumentitem
                      conditiontype = 'JOIG'.
            IF sy-subrc = 0 .
              IF w_item_igst-conditionratevalue EQ '0.100000000'.
                lv_sum_igst = lv_sum_igst + w_item_igst-conditionamount.
              ENDIF.
            ENDIF .

            lv_grand_tot = lv_grand_tot + ls_souitem-netamount .

            APPEND gs_item TO gt_item.
            CLEAR: ls_souitem , gs_item , w_item_price, w_item_igst.
          ENDLOOP.

          gs_sohdr-igst_amt = lv_sum_igst.
          gs_sohdr-sum_qty  = lv_sum_qty.

          gs_sohdr-grand_total      = lv_tot_amt + gs_sohdr-disc_amt + gs_sohdr-igst_amt.
          gs_sohdr-total_amt        = lv_tot_amt.
          gs_sohdr-disc_amt         = gs_sohdr-disc_amt .

          DATA : lv_grand_tot_word TYPE string,
                 lv_gst_tot_word   TYPE string.

          DATA:
            lo_amt_words TYPE REF TO zcl_amt_words.

          CREATE OBJECT lo_amt_words.

          lv_grand_tot_word = gs_sohdr-grand_total. "lv_grand_tot.

          lo_amt_words->number_to_words_export(
           EXPORTING
             iv_num   = lv_grand_tot_word
           RECEIVING
             rv_words = DATA(grand_tot_amt_words)
         ).

          gs_sohdr-amt_words        = |{ gs_sohdr-amtount_curr } | && grand_tot_amt_words.

          INSERT LINES OF gt_item INTO TABLE gs_sohdr-xt_item.
          APPEND gs_sohdr TO gt_sohdr.
          CLEAR: ls_sohdr.
        ENDLOOP.

        et_final[] = gt_sohdr[].

      ENDMETHOD.


      METHOD prep_xml_pack_inv.

        DATA: lv_vbeln_n  TYPE char10 .

        DATA:
*          tot_amt   TYPE p LENGTH 16 DECIMALS 2,
*          tot_dis   TYPE p LENGTH 16 DECIMALS 2,
          tot_oth       TYPE p LENGTH 16 DECIMALS 2,
          grand_tot     TYPE p LENGTH 16 DECIMALS 2,
          lv_unit_price TYPE p LENGTH 16 DECIMALS 4,
          lv_tot_qty    TYPE p LENGTH 16 DECIMALS 2.

        IF it_final[] IS NOT INITIAL.

          READ TABLE it_final INTO DATA(w_final) INDEX 1 .
          lv_vbeln_n = w_final-billingdocument.
          lv_vbeln_n = |{ lv_vbeln_n ALPHA = IN }| .
          """    SHIFT lv_vbeln_n LEFT DELETING LEADING '0'.

          SELECT * FROM zsd_pack_data WHERE pack_num = @im_pack
                   INTO TABLE @DATA(lt_pack).

          SELECT SINGLE * FROM zsd_pack_data WHERE pack_num =  @im_pack INTO @DATA(wa_pack_data).

          REPLACE ALL OCCURRENCES OF '&' IN  w_final-re_name WITH '' .
          REPLACE ALL OCCURRENCES OF '&' IN  w_final-we_name WITH '' .

          DATA : odte_text TYPE char20 , """"original duplicate triplicate ....
                 tot_qty   TYPE p LENGTH 16 DECIMALS 2,
                 tot_amt   TYPE p LENGTH 16 DECIMALS 2,
                 tot_dis   TYPE p LENGTH 16 DECIMALS 2.

          IF im_prntval = 'Original'.
            odte_text = odte_text = |White-Original            Pink-Duplicate          Yellow-Triplicate|.     "'Original Invoice'.     "'Original Invoice'.
          ELSEIF im_prntval = 'Duplicate'.
            odte_text = 'Pink-Duplicate'.     "'Duplicate Invoice'.
          ELSEIF im_prntval = 'Triplicate'.
            odte_text = 'Yellow-Triplicate'.  "'Triplicate Invoice'.
          ELSEIF im_prntval = 'Extra'.
            odte_text = 'Extra Copy'.
          ENDIF.

          DATA : heading     TYPE char100,
                 sub_heading TYPE char100,
                 for_sign    TYPE char100.


          IF iv_action = 'export' .
            heading = 'EXPORT INVOICE'  .
          ELSEIF iv_action = 'packls' .
            heading = 'PACKING LIST'  .
          ENDIF .


          for_sign  = 'Jumps Auto Industries Limited'.

          DATA : lv_bill_adr1 TYPE char100 .
          DATA : lv_bill_adr2 TYPE char100 .
          DATA : lv_bill_adr3 TYPE char100 .

          DATA : lv_shp_adr1 TYPE char100 .
          DATA : lv_shp_adr2 TYPE char100 .
          DATA : lv_shp_adr3 TYPE char100 .

          DATA : lv_sp_adr1 TYPE char100,
                 lv_sp_adr2 TYPE char100,
                 lv_sp_adr3 TYPE char100,
                 lv_es_adr1 TYPE char100,
                 lv_es_adr2 TYPE char100,
                 lv_es_adr3 TYPE char100.
          """"""" bill address set """"""""
          IF w_final-re_house_no IS NOT INITIAL .
            lv_bill_adr1 = |{ w_final-re_house_no }| .
          ENDIF .

          IF w_final-re_street IS NOT INITIAL .
            IF lv_bill_adr1 IS NOT INITIAL   .
              lv_bill_adr1 = |{ lv_bill_adr1 } , { w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ELSE .
              lv_bill_adr1 = |{ w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          IF w_final-re_street1 IS NOT INITIAL .
            IF lv_bill_adr1 IS NOT INITIAL   .
              lv_bill_adr1 = |{ lv_bill_adr1 }, { w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ELSE .
              lv_bill_adr1 = |{ w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          DATA(len) = strlen( lv_bill_adr1 ) .
          len = len - 40.
          IF strlen( lv_bill_adr1 ) GT 40 .
            lv_bill_adr2 = |{ lv_bill_adr1+40(len) },| .
            lv_bill_adr1 = lv_bill_adr1+0(40) .
          ENDIF .
          """"""" eoc bill address set """"""""


          """"""" ship address set """"""""
          IF w_final-we_house_no IS NOT INITIAL .
            lv_shp_adr1 = |{ w_final-we_house_no }| .
          ENDIF .

          IF w_final-we_street IS NOT INITIAL .
            IF lv_shp_adr1 IS NOT INITIAL   .
              lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ELSE .
              lv_shp_adr1 = |{ w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          IF w_final-we_street1 IS NOT INITIAL .
            IF lv_shp_adr1 IS NOT INITIAL   .
              lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ELSE .
              lv_shp_adr1 = |{ w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          len = strlen( lv_shp_adr1 ) .
          len = len - 40.
          IF strlen( lv_shp_adr1 ) GT 40 .
            lv_shp_adr2 = |{ lv_shp_adr1+40(len) },| .
            lv_shp_adr1 = lv_shp_adr1+0(40) .
          ENDIF .

*          """"""" sp address set """"""""
*          IF w_final-sp_house_no IS NOT INITIAL .
*            lv_sp_adr1 = |{ w_final-sp_house_no }| .
*          ENDIF .
*
*          IF w_final-sp_street IS NOT INITIAL .
*            IF lv_sp_adr1 IS NOT INITIAL   .
*              lv_sp_adr1 = |{ lv_sp_adr1 } , { w_final-sp_street }| .
*            ELSE .
*              lv_sp_adr1 = |{ w_final-sp_street }| .
*            ENDIF .
*          ENDIF .
*
*          IF w_final-sp_street1 IS NOT INITIAL .
*            IF lv_sp_adr1 IS NOT INITIAL   .
*              lv_sp_adr1 = |{ lv_sp_adr1 } , { w_final-sp_street1 }| .
*            ELSE .
*              lv_sp_adr1 = |{ w_final-sp_street1 }| .
*            ENDIF .
*          ENDIF .
*
*          len = strlen( lv_sp_adr1 ) .
*          IF len GT 40 .
*            lv_sp_adr2 = |{ lv_sp_adr1+40(len) },| .
*            lv_sp_adr1 = lv_sp_adr1+0(40) .
*          ENDIF .
*
*          """"""" ES address set """"""""
          IF w_final-es_house_no IS NOT INITIAL .
            lv_es_adr1 = |{ w_final-es_house_no }| .
          ENDIF .

          IF w_final-es_street IS NOT INITIAL .
            IF lv_es_adr1 IS NOT INITIAL   .
              lv_es_adr1 = |{ lv_es_adr1 } , { w_final-es_street }| .
            ELSE .
              lv_es_adr1 = |{ w_final-es_street }| .
            ENDIF .
          ENDIF .

          IF w_final-es_street1 IS NOT INITIAL .
            IF lv_es_adr1 IS NOT INITIAL   .
              lv_es_adr1 = |{ lv_es_adr1 } , { w_final-es_street1 }| .
            ELSE .
              lv_es_adr1 = |{ w_final-es_street1 }| .
            ENDIF .
          ENDIF .

          len = strlen( lv_es_adr1 ) .
          IF len GT 40 .
            lv_es_adr2 = |{ lv_es_adr1+40(len) },| .
            lv_es_adr1 = lv_es_adr1+0(40) .
          ENDIF .

          ""****Start:Logic to read text of Billing Header************
          DATA:
            lo_text           TYPE REF TO zcl_read_text,
            gt_text           TYPE TABLE OF zstr_billing_text,
            gt_item_text      TYPE TABLE OF zstr_billing_text,
            lo_amt_words      TYPE REF TO zcl_amt_words,
            lv_grand_tot_word TYPE string.

          DATA:
            inst_hsn_code    TYPE string,
            inst_sbno        TYPE string,
            inst_sb_date     TYPE string,
            inst_rcno        TYPE string,
            trans_mode       TYPE string,
            inst_date_accpt  TYPE string,
            inst_delv_date   TYPE string,
            inst_transipment TYPE string,
            inst_no_orginl   TYPE string,
            inst_frt_amt     TYPE string,
            inst_frt_pay_at  TYPE string,
            inst_destination TYPE string,
            inst_particular  TYPE string,
            inst_collect     TYPE string,
            inst_notif_prty  TYPE string,
            inst_bill_oflad  TYPE string.

          CREATE OBJECT lo_text.
          CREATE OBJECT lo_amt_words.

          ""****End:Logic to read text of Billing Header************

          lo_text->read_text_billing_header(
             EXPORTING
               iv_billnum = lv_vbeln_n
             RECEIVING
               xt_text    = gt_text "This will contain all text IDs data of given billing document
           ).


          DATA : lv_vessel TYPE char100 .
          DATA : lv_no_pck TYPE char100 .

          DATA : lv_gross TYPE char100 .

          DATA : lv_other_ref TYPE char100 .
          CLEAR : lv_vessel , lv_no_pck , lv_gross .
          READ TABLE gt_text INTO DATA(w_text) WITH KEY longtextid = 'Z004' .
          IF sy-subrc = 0 .
            lv_vessel = w_text-longtext .
          ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z011' .
          IF sy-subrc = 0 .
            lv_gross = w_text-longtext .
          ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'TX05' .
          IF sy-subrc = 0 .
            lv_other_ref = w_text-longtext .
          ENDIF .


          """***For Shipping Instruction****************
          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z005' .
          IF sy-subrc = 0 .
            inst_sbno = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z006' .
          IF sy-subrc = 0 .
            inst_rcno = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z013' .
          IF sy-subrc = 0 .
            inst_no_orginl = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z014' .
          IF sy-subrc = 0 .
            inst_particular = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z015' .
          IF sy-subrc = 0 .
            inst_date_accpt = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z002' .
          IF sy-subrc = 0 .
            trans_mode = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z020' .
          IF sy-subrc = 0 .
            inst_notif_prty = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z019' .
          IF sy-subrc = 0 .
            inst_bill_oflad = w_text-longtext .
          ENDIF .

          """***For Shipping Instruction****************



          ""   CLEAR : w_final , wa_pack_data , for_sign , sub_heading , heading , odte_text .
          "  FREE : it_final .

          DATA:
             lv_bill_date TYPE char10.

          lv_bill_date = w_final-billingdocumentdate+6(2) && '.' && w_final-billingdocumentdate+4(2) && '.' && w_final-billingdocumentdate+0(4).
          wa_pack_data-iec = ''.
          w_final-phoneareacodesubscribernumber = '+91-124-4710100'.
          wa_pack_data-country_org = 'India'.
          wa_pack_data-country_of_fdest = w_final-we_country.

          ""*****Start: Item XML*****************************************************
          DATA : lv_item      TYPE string,
                 lv_pallet_no TYPE string,
                 srn          TYPE char3,
                 lv_anp_part  TYPE string.

          IF w_final-item_igstrate EQ 0.
            sub_heading = 'SUPPLY MEANT FOR EXPORT UNDER LUT WITHOUT PAYMENT OF INTEGRATED TAX'.
          ELSE.
            sub_heading = 'SUPPLY MEANT FOR EXPORT WITH PAYMENT OF IGST'.
          ENDIF.

          IF iv_action = 'export' .

            DATA(xt_pack) = lt_pack[].
            SORT lt_pack BY vbeln posnr.
            DELETE ADJACENT DUPLICATES FROM lt_pack COMPARING vbeln posnr.

            LOOP AT lt_pack ASSIGNING FIELD-SYMBOL(<lfs_pack>).

              IF <lfs_pack> IS ASSIGNED.
                CLEAR: <lfs_pack>-qty_in_pcs, <lfs_pack>-pkg_vol, <lfs_pack>-pkg_length.
                LOOP AT xt_pack INTO DATA(xs_pack) WHERE vbeln = <lfs_pack>-vbeln AND posnr = <lfs_pack>-posnr.
                  "<lfs_pack>-qty_in_pcs = <lfs_pack>-qty_in_pcs + xs_pack-qty_in_pcs.
                  <lfs_pack>-pkg_vol    = <lfs_pack>-pkg_vol + xs_pack-pkg_vol.
                  <lfs_pack>-pkg_length = <lfs_pack>-pkg_length + xs_pack-pkg_length.
                  CLEAR: xs_pack.
                ENDLOOP.

                READ TABLE it_final INTO DATA(xw_final) WITH KEY billingdocument = <lfs_pack>-vbeln billingdocumentitem = <lfs_pack>-posnr.
                IF sy-subrc EQ 0.
                  <lfs_pack>-qty_in_pcs = xw_final-billingquantity.
                ENDIF.

              ENDIF.

            ENDLOOP.

          ENDIF.

          IF iv_action = 'packls'.
            SORT lt_pack BY pallet_no.
          ENDIF.

          CLEAR : lv_item , srn .
          CLEAR: tot_amt, tot_dis, tot_oth, grand_tot.
          LOOP AT lt_pack INTO DATA(w_pack) .

            READ TABLE it_final INTO DATA(w_item) WITH KEY
                                billingdocument     = w_pack-vbeln billingdocumentitem = w_pack-posnr.
            "DeliveryDocumentItem = w_pack-posnr.

            CLEAR: gt_item_text.
            lo_text->read_text_billing_item(
              EXPORTING
                im_billnum  = w_item-billingdocument
                im_billitem = w_item-billingdocumentitem
              RECEIVING
                xt_text     = gt_item_text
            ).

            IF gt_item_text[] IS NOT INITIAL.
              READ TABLE gt_item_text INTO DATA(gs_item_text) INDEX 1.
            ENDIF.

            srn = srn + 1 .
            lv_pallet_no =  |{ w_item-purchaseorderbycustomer } / { w_item-customerpurchaseorderdate+6(2) }.{ w_item-customerpurchaseorderdate+4(2) }.{ w_item-customerpurchaseorderdate+0(4) } / { gs_item_text-longtext }| .

            lv_tot_qty    =  w_pack-qty_in_pcs * w_pack-type_pkg.

            IF iv_action = 'export'.
              wa_pack_data-total_pcs      = wa_pack_data-total_pcs + w_pack-qty_in_pcs.
            ELSE.
              wa_pack_data-total_pcs      = wa_pack_data-total_pcs + lv_tot_qty.
            ENDIF.

            wa_pack_data-tot_net_wgt    = wa_pack_data-tot_net_wgt + w_pack-pkg_vol.
            wa_pack_data-tot_gross_wgt  = wa_pack_data-tot_gross_wgt +  w_pack-pkg_length.

            lv_anp_part  = w_pack-matnr. "w_item-ProductOldID.

            """""""""""""""""""""""""""""""""""
            SELECT SINGLE * FROM i_regiontext  WHERE region = @w_final-region AND language = 'E' AND country = 'IN'
             INTO @DATA(lv_st_nm1).

            SELECT SINGLE * FROM i_regiontext  WHERE region = @w_final-re_region AND language = 'E' AND country = 'IN'
            INTO @DATA(lv_st_name_re1).

            SELECT SINGLE * FROM i_regiontext  WHERE region = @w_final-we_region AND language = 'E' AND country = 'IN'
            INTO @DATA(lv_st_name_we1).


            SELECT SINGLE * FROM i_countrytext   WHERE country = @w_final-country AND language = 'E'
            INTO @DATA(lv_cn_nm1).

            SELECT SINGLE * FROM i_countrytext   WHERE country = @w_final-re_country AND language = 'E'
            INTO @DATA(lv_cn_name_re1).

            SELECT SINGLE * FROM i_countrytext   WHERE country = @w_final-we_country AND language = 'E'
            INTO @DATA(lv_cn_name_we1).

            SELECT SINGLE * FROM i_countrytext   WHERE country = @wa_pack_data-country_of_fdest
             AND language = 'E'  INTO @DATA(lv_cn_name_fdes).

            REPLACE ALL OCCURRENCES OF '&' IN  w_item-materialbycustomer WITH '' .
            REPLACE ALL OCCURRENCES OF '&' IN  lv_anp_part WITH '' .
            REPLACE ALL OCCURRENCES OF '&' IN  w_item-billingdocumentitemtext WITH '' .
            REPLACE ALL OCCURRENCES OF 'ü' IN  lv_cn_name_fdes-countryname WITH 'u'.
            REPLACE ALL OCCURRENCES OF 'ü' IN  lv_cn_name_re1-countryname WITH 'u'.
            REPLACE ALL OCCURRENCES OF 'ü' IN  lv_cn_name_we1-countryname WITH 'u'.

            IF w_item-conditionquantity IS NOT INITIAL .
              lv_unit_price = w_item-item_unitprice / w_item-conditionquantity.
            ELSE.
              lv_unit_price = w_item-item_unitprice.
            ENDIF.

            "w_item-item_unitprice = w_item-item_unitprice / w_item-ConditionQuantity.
            w_item-item_totalamount = w_item-billingquantity * lv_unit_price. "w_item-item_unitprice.

            tot_amt = tot_amt + w_item-item_totalamount.
            tot_dis = tot_dis + w_item-item_discountamount.
            tot_oth = tot_oth + w_item-item_freight + w_item-item_othercharge.

            lv_item = |{ lv_item }| && |<ItemDataNode>| &&

                      |<cust_pono> { lv_pallet_no }</cust_pono>| &&
                      |<pallet_no>{ w_pack-pallet_no }</pallet_no>| &&
                      |<pkgs_from_to>{ w_pack-pkg_no }</pkgs_from_to>| &&
                      |<buyer_code>{ w_pack-kdmat }</buyer_code>| &&
                      |<anp_part>{ lv_anp_part }</anp_part>| &&
                      |<item_code>{ lv_anp_part }</item_code>| &&
                      |<item_desc>{  w_item-billingdocumentitemtext }</item_desc>| &&
                      |<hsn_code>{  w_item-hsn }</hsn_code>| &&
                      |<qty>{ w_item-billingquantity }</qty>| &&
                      |<qty_pcs>{ w_pack-qty_in_pcs }</qty_pcs>| &&
                      |<net_wgt>{ w_pack-pkg_vol }</net_wgt>| &&
                      |<gross_wgt>{ w_pack-pkg_length }</gross_wgt>| &&
                      |<rate>{ lv_unit_price }</rate>| &&
                      |<amount>{ w_item-item_totalamount }</amount>| &&
                      |<no_of_pkg>{ w_pack-type_pkg }</no_of_pkg>| &&
                      |<tot_qty>{ lv_tot_qty }</tot_qty>| &&
*                    |<item_code>{ w_item-MaterialDescriptionByCustomer }</item_code>| &&
                      |</ItemDataNode>|  .

          ENDLOOP .

          IF iv_action = 'shpinst'.

            heading = 'SLI'.

            inst_delv_date     = ''.
            inst_transipment   = ''.
            inst_frt_amt       = ''.
            inst_frt_pay_at    = ''.
            inst_destination   = ''.

            IF w_final-incotermsclassification = 'FOB' OR w_final-incotermsclassification = 'FCA'.

              inst_collect       = 'FREIGHT COLLECT'.

            ELSE.

              inst_collect       = 'IHC COLLECT'.

            ENDIF.

            DATA(lt_inst) = it_final[].
            SORT lt_inst BY hsn.
            DELETE ADJACENT DUPLICATES FROM lt_inst COMPARING hsn.

            LOOP AT lt_inst INTO DATA(ls_inst).
             if sy-tabix = 1.
              inst_hsn_code  = inst_hsn_code && ls_inst-hsn.
             else.
              inst_hsn_code  = inst_hsn_code && ',' && ls_inst-hsn.
             ENDIF.
            ENDLOOP.

            CLEAR: lv_item.
            lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                      |<cust_pono> { lv_pallet_no }</cust_pono>| &&
                      |</ItemDataNode>|  .

          ENDIF.

          grand_tot = tot_amt - tot_dis + tot_oth.
          lv_grand_tot_word  = grand_tot.
          lo_amt_words->number_to_words_export(
           EXPORTING
             iv_num   = lv_grand_tot_word
           RECEIVING
             rv_words = DATA(grand_tot_amt_words)
         ).

          IF w_final-transactioncurrency EQ 'USD'.

          ELSEIF w_final-transactioncurrency EQ 'EUR'.
            REPLACE ALL OCCURRENCES OF 'Dollars' IN grand_tot_amt_words WITH 'Euro'.
          ENDIF.

          DATA : lv_declaration1 TYPE string .
          DATA : lv_declaration2 TYPE string .
          DATA : lv_declaration3 TYPE string .
          DATA : lv_declaration4 TYPE string .
          DATA : lv_declaration5 TYPE string .
          DATA : lv_declaration6  TYPE string.


          CASE w_final-we_country .

            WHEN
            'DE' OR 'ES' OR 'TR' OR 'CZ' OR 'FR' OR 'AT' OR 'HU' OR 'IT' OR 'SK' OR 'PL' OR 'RS' OR 'RU' OR
            'DK' OR 'FI' OR 'BE' OR 'IE' OR 'NL' OR 'RS' OR 'NO' OR 'GR' OR 'RO' OR 'BY' OR 'PT' OR 'SE'. "OR 'GB'

              "lv_declaration1 = 'Declaration :' .
              "lv_declaration2 = 'The exporter of the products covered by this document (Customs Authorisation No.' .
              "lv_declaration3 = 'INREX4101000174EC028) declares that, except where otherwise clearly indicated, these products' .
              "lv_declaration4 = 'are of Indian preferential origin. "IN" according to the rules of origin of the Generalized system'.
              "lv_declaration5 = 'of Preferences of the European Union and that the origin criterion met is "EU cumulation".'.
              " lv_declaration6 = 'last line' .

              lv_declaration1 = 'STATEMENT OF ORIGIN:' .
              lv_declaration2 = 'The exporter JUMPS AUTO INDUSTRIES LIMITED , REX REGISTRATION NO. - INREX0500066302EC028,' .
              lv_declaration3 = 'Date of Registration 03.11.2017,Date from which the registration is Valid : 01.11.2017, of the products covered by this document'.
              lv_declaration4 = 'declares that, except where otherwise clearly indicated, these products are of INDIA Preferential origin according to rules of' .
              lv_declaration5 = 'origin of the Generalised System of Preferences of the European Union and that the origin criterion met is (P).' .
              " lv_declaration6 = 'last line' .

            WHEN 'GB'.

              lv_declaration1 = 'STATEMENT OF ORIGIN:' .
              lv_declaration2 = 'The Exporter (JUMPS AUTO INDUSTRIES LIMITED) of products covered by this document declares that except where' .
              lv_declaration3 = 'otherwise clearly Indicated these products are of India preferential origin according to rules of the developing Countries'.
              lv_declaration4 = 'trading Scheme (DCTS) of the UK and that the origin criteria met is (P).' .
              lv_declaration5 = '' .

            WHEN OTHERS .
          ENDCASE .

          DATA : bank1 TYPE char100, bank2 TYPE char100, bank3 TYPE char100, bank4 TYPE char100  .
          CASE w_final-transactioncurrency .
            WHEN 'GBP' .
              bank1 = 'NATIONAL WESTMINSTER BANK PLC.' .
              bank2 = 'LONDON' .
              bank3 = 'NWBKGB2LXXX'.
              bank4 = '60000410001247' .

            WHEN 'USD' .
              bank1 = 'JPMORGAN CHASE BANK' .
              bank2 = 'NEW YORK' .
              bank3 = 'CHASUS33XXX'.
              bank4 = '0011427374' .

            WHEN 'EUR' .
              bank1 = 'J.P. MORGAN AG' .
              bank2 = 'FRANKFURT' .
              bank3 = 'CHASDEFXXX'.
              bank4 = '6231605970' .
            WHEN OTHERS .   """ india
              " bank1 = 'J.P. MORGAN AG' .
              " bank2 = 'FRANKFURT' .
              " bank3 = 'CHASDEFXXX'.
              " bank4 = '6231605970' .
          ENDCASE. .

          ""*****End: Item XML*****************************************************
          CLEAR : odte_text .
          ""*****Start: Header XML*****************************************************
          w_final-plantname = 'Jumps Auto Industries Limited'.
          w_final-phoneareacodesubscribernumber = '+91-124-4710100'.
          wa_pack_data-ad_code = '6390009-290009'.

          REPLACE ALL OCCURRENCES OF '&' IN w_final-incotermslocation1 WITH ''.

          DATA(lv_xml) = |<Form>| &&
                         |<BillingDocumentNode>| &&
                         |<heading>{ heading }</heading>| &&
                         |<sub_heading>{ sub_heading }</sub_heading>| &&
                         |<for_sign>{ for_sign }</for_sign>| &&
                         |<odte_text>{ odte_text }</odte_text>| &&


                          |<plant_code>{ w_final-plant }</plant_code>| &&
                          |<plant_name>{ w_final-plantname }</plant_name>| &&
                          |<plant_address_l1>125, Pace City 1</plant_address_l1>| &&
                          |<plant_address_l2>Sector 37</plant_address_l2>| &&
                          |<plant_address_l3>Gurugram - 122001 ,India</plant_address_l3>| &&
                          |<plant_cin>U29299DL1999PLC098434</plant_cin>| &&
                          |<plant_gstin>{ w_final-plant_gstin }</plant_gstin>| &&
                          |<plant_pan>{ w_final-plant_gstin+2(10) }</plant_pan>| &&
                          |<plant_state_code>{ w_final-region }</plant_state_code>| &&
                          |<plant_state_name>{ w_final-plantname }</plant_state_name>| &&
                          |<plant_phone>{ w_final-phoneareacodesubscribernumber }</plant_phone>| &&
                          |<plant_email>{ w_final-plant_email }</plant_email>| &&

                          |<consignee_code>{ w_final-ship_to_party }</consignee_code>| &&
                          |<consignee_name>{ w_final-we_name }</consignee_name>| &&
                          |<consignee_address_l1>{ lv_shp_adr1 }</consignee_address_l1>| &&
                          |<consignee_address_l2>{ lv_shp_adr2 }</consignee_address_l2>| &&
                          |<consignee_address_l3>{ w_final-we_pin } ({ lv_cn_name_we1-countryname })</consignee_address_l3>| &&
                          |<consignee_cin>{ w_final-plantname }</consignee_cin>| &&
                          |<consignee_gstin>{ w_final-we_tax }</consignee_gstin>| &&
                          |<consignee_pan>{ w_final-we_pan }</consignee_pan>| &&
                          |<consignee_state_code>{ w_final-we_region } ({ lv_st_name_we1-regionname })</consignee_state_code>| &&
                          |<consignee_state_name>{ w_final-we_city }</consignee_state_name>| &&
                          |<consignee_place_suply>{ w_final-we_region }</consignee_place_suply>| &&
                          |<consignee_phone>{ w_final-we_phone4 }</consignee_phone>| &&
                          |<consignee_email>{ w_final-we_email }</consignee_email>| &&


*                          |<shipto_code>{ w_final-sp_code }</shipto_code>| &&
*                          |<shipto_name>{ w_final-sp_name }</shipto_name>| &&
*                          |<shipto_addrs1>{ lv_sp_adr1 }</shipto_addrs1>| &&
*                          |<shipto_addrs2>{ lv_sp_adr2 }</shipto_addrs2>| &&
*                          |<shipto_addrs3>{ w_final-sp_pin }</shipto_addrs3>| &&

                          |<secnd_ntfy_code>{ w_final-es_code }</secnd_ntfy_code>| &&
                          |<secnd_ntfy_name>{ w_final-es_name }</secnd_ntfy_name>| &&
                          |<secnd_ntfy_addrs1>{ lv_es_adr1 }</secnd_ntfy_addrs1>| &&
                          |<secnd_ntfy_addrs2>{ lv_es_adr2 }</secnd_ntfy_addrs2>| &&
                          |<secnd_ntfy_addrs3>{ w_final-es_pin }</secnd_ntfy_addrs3>| &&

                          |<buyer_code>{ w_final-bill_to_party }</buyer_code>| &&
                          |<buyer_name>{ w_final-re_name }</buyer_name>| &&
                          |<buyer_address_l1>{ lv_bill_adr1 }</buyer_address_l1>| &&
                          |<buyer_address_l2>{ lv_bill_adr2 }</buyer_address_l2>| &&
                          |<buyer_address_l3>{ w_final-re_pin } ({ lv_cn_name_re1-countryname })</buyer_address_l3>| &&
                          |<buyer_cin></buyer_cin>| &&   """ { w_final-PlantName }
                          |<buyer_gstin>{ w_final-re_tax }</buyer_gstin>| &&
                          |<buyer_pan>{ w_final-re_pan }</buyer_pan>| &&
                          |<buyer_state_code>{ w_final-re_region } ({ lv_st_name_re1-regionname })</buyer_state_code>| &&
                          |<buyer_state_name>{ w_final-re_city }</buyer_state_name>| &&
                          |<buyer_place_suply>{ w_final-re_region }</buyer_place_suply>| &&
                          |<buyer_phone>{ w_final-re_phone4 }</buyer_phone>| &&
                          |<buyer_email>{ w_final-re_email }</buyer_email>| &&

                          |<inv_no>{ w_final-documentreferenceid }</inv_no>| &&
                          |<inv_date>{ lv_bill_date }</inv_date>| &&

                          |<iec_num>0500066302</iec_num>| &&
                          |<pan_num>{ wa_pack_data-ex_pan }</pan_num>| &&
                          |<ad_code>{ wa_pack_data-ad_code }</ad_code>| &&
                          |<pre_carig_by>{ wa_pack_data-pre_carig_by }</pre_carig_by>| &&
                          |<vessel>{ lv_vessel }</vessel>| &&
                          |<port_of_discg>{ wa_pack_data-port_of_discg }</port_of_discg>| &&
                          |<mark_no_of_cont>{ wa_pack_data-mark_no_of_cont }</mark_no_of_cont>| &&
                          |<pre_carrier>{ wa_pack_data-pre_carrier }</pre_carrier>| &&
                          |<port_of_load>{ wa_pack_data-port_of_load }</port_of_load>| &&
                          |<final_dest>{ wa_pack_data-final_dest }</final_dest>| &&
                          |<country_org>{ wa_pack_data-country_org }</country_org>| &&
                          |<country_of_fdest>{ lv_cn_name_fdes-countryname }</country_of_fdest>| &&

                          |<pay_term>{ w_final-incotermslocation1 } ({ w_final-incotermsclassification })</pay_term>| &&
                          |<payment>{ w_final-customerpaymenttermsname }</payment>| &&

                          |<des_of_goods>{ 'Auto Parts' }</des_of_goods>| &&
                          |<no_kind_pkg>{ wa_pack_data-no_kind_pkg }</no_kind_pkg>| &&

                          |<total_pcs>{ wa_pack_data-total_pcs }</total_pcs>| &&
                          |<tot_net_wgt>{ wa_pack_data-tot_net_wgt }</tot_net_wgt>| &&
                          |<tot_gross_wgt>{ wa_pack_data-tot_gross_wgt }</tot_gross_wgt>| &&
                          |<total_vol>{ wa_pack_data-box_size }</total_vol>| &&

                          |<other_ref> { lv_other_ref }</other_ref>| &&

                          |<lut_urn> { 'AD060323015122V' }</lut_urn>| &&
                          |<lut_date> { '09/03/2023' }</lut_date>| &&
                          |<end_use_code> { wa_pack_data-ad_code }</end_use_code>| &&
                          |<plant_website> { 'www.jumpsindia.com' }</plant_website>| &&

                          |<total_amt>{ tot_amt }</total_amt>| &&
                          |<other_charges>{ tot_oth }</other_charges>| &&
                          |<discount>{ tot_dis }</discount>| &&
                          |<grand_total>{ grand_tot }</grand_total>| &&

                          |<bank1>{ bank1 }</bank1>| &&
                          |<bank2>{ bank2 }</bank2>| &&
                          |<bank3>{ bank3 }</bank3>| &&
                          |<bank4>{ bank4 }</bank4>| &&


                          |<lv_dec1>{ lv_declaration1 }</lv_dec1>| &&
                          |<lv_dec2>{ lv_declaration2 }</lv_dec2>| &&
                          |<lv_dec3>{ lv_declaration3 }</lv_dec3>| &&
                          |<lv_dec4>{ lv_declaration4 }</lv_dec4>| &&
                          |<lv_dec5>{ lv_declaration5 }</lv_dec5>| &&
                          |<lv_dec6>{ lv_declaration6 }</lv_dec6>| &&
                          |<rate_curr>{ w_final-transactioncurrency }</rate_curr>| &&
                          |<amt_words>{ grand_tot_amt_words }</amt_words>| &&

                        |<inst_hsn_code>{ inst_hsn_code }</inst_hsn_code>| &&
                        |<inst_sbno>{ inst_sbno }</inst_sbno>| &&
                        |<inst_collect>{ inst_collect  }</inst_collect>| &&
                        |<inst_sb_date>{ inst_sb_date }</inst_sb_date>| &&
                        |<inst_rcno>{ inst_rcno }</inst_rcno>| &&
                        |<trans_mode>{ trans_mode }</trans_mode>| &&
                        |<inst_date_accpt>{ inst_date_accpt }</inst_date_accpt>| &&
                        |<inst_delv_date>{ inst_delv_date }</inst_delv_date>| &&
*                        |<inst_transipment>{ inst_transipment }</inst_transipment| &&
                        |<inst_no_orginl>{ inst_no_orginl }</inst_no_orginl>| &&
                        |<inst_frt_amt>{ inst_frt_amt }</inst_frt_amt>| &&
                        |<inst_frt_pay_at>{ inst_frt_pay_at }</inst_frt_pay_at>| &&
                        |<inst_destination>{ inst_destination }</inst_destination>| &&
                        |<inst_particular>{ inst_particular }</inst_particular>| &&
                        |<inst_notif_prty>{ inst_notif_prty }</inst_notif_prty>| &&
                        |<inst_bill_oflad>{ inst_bill_oflad }</inst_bill_oflad>| &&

                         |<ItemData>| .

          ""*****End: Header XML*****************************************************

          """****Merging Header & Item XML
          lv_xml = |{ lv_xml }{ lv_item }| &&
                             |</ItemData>| &&
                             |</BillingDocumentNode>| &&
                             |</Form>|.

          DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
          iv_xml_base64 = ls_data_xml_64.

        ENDIF.

      ENDMETHOD.


      METHOD prep_xml_so_prnt.

        DATA : heading      TYPE char100,
               sub_heading  TYPE char200,
               lv_xml_final TYPE string.

        heading = 'EXPORT ORDER CONFIRMATION'.

        READ TABLE it_final INTO DATA(ls_final) INDEX 1.
        SHIFT ls_final-sum_qty LEFT DELETING LEADING space.

        DATA(lv_xml) =  |<Form>| &&
                        |<SalesDocumentNode>| &&
                        |<heading>{ heading }</heading>| &&
                        |<sub_heading>{ sub_heading }</sub_heading>| &&
                        |<exptr_code>{ ls_final-exptr_code }</exptr_code>| &&
                        |<exptr_name>{ ls_final-exptr_name }</exptr_name>| &&
                        |<exptr_addrs1>{ ls_final-exptr_addrs1 }</exptr_addrs1>| &&
                        |<exptr_addrs2>{ ls_final-exptr_addrs2 }</exptr_addrs2>| &&
                        |<exptr_addrs3>{ ls_final-exptr_addrs3 }</exptr_addrs3>| &&
                        |<exptr_addrs4>{ ls_final-exptr_addrs4 }</exptr_addrs4>| &&
                        |<fact_addrs1>{ ls_final-fact_addrs1 }</fact_addrs1>| &&
                        |<fact_addrs2>{ ls_final-fact_addrs2 }</fact_addrs2>| &&
                        |<fact_addrs3>{ ls_final-fact_addrs3 }</fact_addrs3>| &&
                        |<our_ref>{ ls_final-our_ref }</our_ref>| &&
                        |<our_ref_date>{ ls_final-our_ref_date }</our_ref_date>| &&
                        |<cust_odr_ref>{ ls_final-cust_odr_ref }</cust_odr_ref>| &&
                        |<cust_odr_date>{ ls_final-cust_odr_date }</cust_odr_date>| &&
                        |<buyr_code>{ ls_final-buyr_code }</buyr_code>| &&
                        |<buyr_name>{ ls_final-buyr_name }</buyr_name>| &&
                        |<buyr_addrs1>{ ls_final-buyr_addrs1 }</buyr_addrs1>| &&
                        |<buyr_addrs2>{ ls_final-buyr_addrs2 }</buyr_addrs2>| &&
                        |<buyr_addrs3>{ ls_final-buyr_addrs3 }</buyr_addrs3>| &&
                        |<buyr_addrs4>{ ls_final-buyr_addrs4 }</buyr_addrs4>| &&
                        |<cnsinee_code>{ ls_final-cnsinee_code }</cnsinee_code>| &&
                        |<cnsinee_name>{ ls_final-cnsinee_name }</cnsinee_name>| &&
                        |<cnsinee_addrs1>{ ls_final-cnsinee_addrs1 }</cnsinee_addrs1>| &&
                        |<cnsinee_addrs2>{ ls_final-cnsinee_addrs2 }</cnsinee_addrs2>| &&
                        |<cnsinee_addrs3>{ ls_final-cnsinee_addrs3 }</cnsinee_addrs3>| &&
                        |<cnsinee_addrs4>{ ls_final-cnsinee_addrs4 }</cnsinee_addrs4>| &&
                        |<price_term>{ ls_final-price_term }</price_term>| &&
                        |<pay_term>{ ls_final-pay_term }</pay_term>| &&
                        |<inco_term>{ ls_final-inco_term }</inco_term>| &&
                        |<amount_curr>{ ls_final-amtount_curr }</amount_curr>| &&
                        |<ship_mode>{ ls_final-ship_mode }</ship_mode>| &&
                        |<port_disch>{ ls_final-port_disch }</port_disch>| &&
                        |<port_delivry>{ ls_final-port_delivry }</port_delivry>| &&
                        |<total_amt>{ ls_final-total_amt }</total_amt>| &&
                        |<disc_amt>{ ls_final-disc_amt }</disc_amt>| &&
                        |<amt_words>{ ls_final-amt_words }</amt_words>| &&
                        |<igst_amt>{ ls_final-igst_amt }</igst_amt>| &&
                        |<sum_qty>{ ls_final-sum_qty }</sum_qty>| &&
                        |<grand_total>{ ls_final-grand_total }</grand_total>| &&
                        |<pinst_box>{ ls_final-pinst_box }</pinst_box>| &&
                        |<pinst_stickr>{ ls_final-pinst_stickr }</pinst_stickr>| &&
                        |<pinst_make>{ ls_final-pinst_make }</pinst_make>| &&
                        |<made_in_india>{ ls_final-made_in_india }</made_in_india>| &&
                        |<making_inst>{ ls_final-making_inst }</making_inst>| &&
                        |<ItemData>| .

        DATA : lv_item TYPE string .
        DATA : srn TYPE char10.
        CLEAR : lv_item , srn .

        LOOP AT ls_final-xt_item INTO DATA(ls_item).

          srn = ls_item-sr_num. "srn + 1 .
          SHIFT srn LEFT DELETING LEADING '0'.

          lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                    |<sr_num>{ srn }</sr_num>| &&
                    |<saleorder>{ ls_item-saleorder }</saleorder>| &&
                    |<saleitem>{ ls_item-saleitem }</saleitem> | &&
                    |<byur_code>{ ls_item-byur_code }</byur_code>| &&
                    |<item_code>{ ls_item-item_code }</item_code>| &&
                    |<item_desc>{ ls_item-item_desc }</item_desc>| &&
                    |<item_qty>{ ls_item-item_qty }</item_qty>| &&
                    |<item_uom>{ ls_item-item_uom }</item_uom>| &&
                    |<dispatch_date>{ ls_item-dispatch_date }</dispatch_date>| &&
                    |<price_usd_fob>{ ls_item-price_usd_fob }</price_usd_fob>| &&
                    |<amt_usd_fob>{ ls_item-amt_usd_fob }</amt_usd_fob>| &&
                    |</ItemDataNode>|  .

        ENDLOOP.

        lv_xml = |{ lv_xml }{ lv_item }| &&
                           |</ItemData>| &&
                           |</SalesDocumentNode>| &&
                           |</Form>|.

        DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
        iv_xml_base64 = ls_data_xml_64.

      ENDMETHOD.


      METHOD prep_xml_tax_inv.

        DATA: lv_vbeln_n   TYPE char10,
              lv_qr_code   TYPE string,
              lv_irn_num   TYPE char64, "w_irn-irnno
              lv_ack_no    TYPE char20, "w_irn-ackno
              lv_ack_date  TYPE char10, "w_irn-ackdat
              lv_ref_sddoc TYPE char20. "w_item-ReferenceSDDocument

        ""****Start:Logic to convert amount in Words************
        DATA:
          lo_amt_words TYPE REF TO zcl_amt_words.
        CREATE OBJECT lo_amt_words.

*    lo_amt_words->number_to_words(
*      EXPORTING
*        iv_num   = '12233.5'
*      RECEIVING
*        rv_words = DATA(amt_words)
*    ).
        ""****End:Logic to convert amount in Words************

        ""****Start:Logic to read text of Billing Header************
        DATA:
          lo_text TYPE REF TO zcl_read_text,
          gt_text TYPE TABLE OF zstr_billing_text.

        CREATE OBJECT lo_text.


        ""****End:Logic to read text of Billing Header************

        lv_qr_code = |This is a demo QR code. So please keep patience... And do not scan it with bar code scanner till i say to scan #sumit| .

        READ TABLE it_final INTO DATA(w_final) INDEX 1 .
        lv_vbeln_n = w_final-billingdocument.


        lo_text->read_text_billing_header(
           EXPORTING
             iv_billnum = lv_vbeln_n
           RECEIVING
             xt_text    = gt_text "This will contain all text IDs data of given billing document
         ).

        SHIFT lv_vbeln_n LEFT DELETING LEADING '0'.

        DATA : odte_text TYPE string , """" original duplicate triplicate ....
               tot_qty   TYPE p LENGTH 16 DECIMALS 2,
               tot_amt   TYPE p LENGTH 16 DECIMALS 2,
               tot_dis   TYPE p LENGTH 16 DECIMALS 2.

        REPLACE ALL OCCURRENCES OF '&' IN  w_final-re_name WITH '' .
        REPLACE ALL OCCURRENCES OF '&' IN  w_final-we_name WITH '' .

        """"""""""""""""""" for total ...
        DATA : lv_qty          TYPE p LENGTH 16 DECIMALS 2,
               lv_netwt        TYPE p LENGTH 16 DECIMALS 2,
               lv_grosswt      TYPE p LENGTH 16 DECIMALS 2,
               lv_dis          TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_amt      TYPE p LENGTH 16 DECIMALS 2,
               lv_tax_amt      TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_sgst     TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_cgst     TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_igst     TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_igst1    TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_cgst1    TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_sgst1    TYPE p LENGTH 16 DECIMALS 2,
               lv_tcs          TYPE p LENGTH 16 DECIMALS 2,
               lv_other_chrg   TYPE p LENGTH 16 DECIMALS 2,
               sum_other_chrg  TYPE p LENGTH 16 DECIMALS 2,
               lv_round_off    TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_gst      TYPE p LENGTH 16 DECIMALS 2,
               lv_grand_tot    TYPE p LENGTH 16 DECIMALS 2,
               lv_item_urate   TYPE p LENGTH 16 DECIMALS 4,
               lv_item_amtinr  TYPE p LENGTH 16 DECIMALS 2,
               lv_item_amtexp  TYPE p LENGTH 16 DECIMALS 2,
               lv_mrp_of_goods TYPE p LENGTH 16 DECIMALS 2,
               lv_amt_expcurr  TYPE p LENGTH 16 DECIMALS 2,
               lv_net          TYPE p LENGTH 16 DECIMALS 2,
               lv_certify_1    TYPE string,
               lv_certify_2    TYPE string,
               lv_certify_3    TYPE string,
               lv_place_supply TYPE string.

        LOOP AT it_final INTO DATA(w_sum) .
          lv_qty = lv_qty + w_sum-billingquantity .
          lv_dis = lv_dis + w_sum-item_discountamount .
          lv_tot_amt = lv_tot_amt + w_sum-item_totalamount_inr .
          lv_tax_amt = lv_tax_amt + w_sum-item_assessableamount .
          lv_tot_igst = lv_tot_igst + w_sum-item_igstamount .
          lv_tot_igst1 = lv_tot_igst1 + w_sum-item_igstamount .
          lv_tot_sgst = lv_tot_sgst + w_sum-item_sgstamount .
          lv_tot_cgst = lv_tot_cgst + w_sum-item_cgstamount .
          lv_tcs = lv_tcs + w_sum-item_othercharge .
          lv_other_chrg = lv_other_chrg + w_sum-item_freight .
          lv_round_off = lv_round_off + w_sum-item_roundoff .
          """  lv_gross = lv_gross + w_sum-GrossWeight .
          lv_net = lv_net + w_sum-netweight .
        ENDLOOP. .

        lv_tot_amt = lv_tot_amt - lv_other_chrg .
        lv_tax_amt = lv_tax_amt - lv_other_chrg .

        lv_grand_tot =  lv_tax_amt + lv_tot_sgst + lv_tot_cgst + lv_tot_igst
                        + lv_other_chrg + lv_tcs + lv_round_off .
        lv_tot_gst = lv_tot_sgst + lv_tot_cgst + lv_tot_igst .

        """ IF w_final-DistributionChannel = '30' .
        CLEAR : lv_qty , lv_dis , lv_tot_amt , lv_tax_amt ,lv_tot_igst , lv_tot_igst1 ,lv_tot_gst ,
         lv_tcs , lv_other_chrg , lv_round_off ,  lv_tot_amt ,lv_tax_amt ,lv_grand_tot , lv_tot_sgst , lv_tot_cgst.
        "" ENDIF .

        """""""""""""""""""""

*        IF w_final-re_tax  = 'URP' .
*          CLEAR : w_final-re_tax .
*        ENDIF .
*        IF w_final-we_tax  = 'URP' .
*          CLEAR : w_final-we_tax .
*        ENDIF .

        DATA : lv_remarks TYPE char100 .

        DATA : lv_gsdb TYPE char100 .
        DATA : lv_cus_pl TYPE char100 .
        DATA :  vcode TYPE char100 .
        DATA : lv_vehicle TYPE char15 .
        DATA : lv_eway TYPE char15 .
        DATA : lv_eway_dt TYPE char10 .
        DATA : lv_transmode TYPE char10 .  """lv_exp_no
        DATA : lv_exp_no TYPE char100 .
        DATA : lv_no_pck TYPE char100 .
        DATA : lv_gross TYPE char100 .
        CLEAR : lv_remarks , lv_no_pck .

        READ TABLE gt_text INTO DATA(w_text) WITH KEY longtextid = 'Z001' .
        IF sy-subrc = 0 .
          lv_vehicle = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z002' .
        IF sy-subrc = 0 .
          lv_transmode = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z012' .
        IF sy-subrc = 0 .
          lv_remarks = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z007' .
        IF sy-subrc = 0 .
          lv_no_pck = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z011' .
        IF sy-subrc = 0 .
          lv_gross = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z016' .
        IF sy-subrc = 0 .
          vcode = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z017' .
        IF sy-subrc = 0 .
          lv_cus_pl = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z010' .
        IF sy-subrc = 0 .
          lv_exp_no = w_text-longtext .
        ENDIF .


        DATA : lv_bill_adr1 TYPE char100 .
        DATA : lv_bill_adr2 TYPE char100 .
        DATA : lv_bill_adr3 TYPE char100 .

        DATA : lv_shp_adr1 TYPE char100 .
        DATA : lv_shp_adr2 TYPE char100 .
        DATA : lv_shp_adr3 TYPE char100 .

        """"""" bill address set """"""""
        IF w_final-re_house_no IS NOT INITIAL .
          lv_bill_adr1 = |{ w_final-re_house_no }| .
        ENDIF .

        IF w_final-re_street IS NOT INITIAL .
          IF lv_bill_adr1 IS NOT INITIAL   .
            lv_bill_adr1 = |{ lv_bill_adr1 } , { w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
          ELSE .
            lv_bill_adr1 = |{ w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
          ENDIF .
        ENDIF .

        IF w_final-re_street1 IS NOT INITIAL .
          IF lv_bill_adr1 IS NOT INITIAL   .
            lv_bill_adr1 = |{ lv_bill_adr1 } , { w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
          ELSE .
            lv_bill_adr1 = |{ w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
          ENDIF .
        ENDIF .

        DATA(len) = strlen( lv_bill_adr1 ) .
        len = len - 40.
        IF strlen( lv_bill_adr1 ) GT 40 .
          lv_bill_adr2 = |{ lv_bill_adr1+40(len) },| .
          lv_bill_adr1 = lv_bill_adr1+0(40) .
        ENDIF .
        """""""eoc bill address set""""""""


        """"""" ship address set """"""""

        IF w_final-we_house_no IS NOT INITIAL .
          lv_shp_adr1 = |{ w_final-we_house_no }| .
        ENDIF .

        IF w_final-we_street IS NOT INITIAL .
          IF lv_shp_adr1 IS NOT INITIAL   .
            lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
          ELSE .
            lv_shp_adr1 = |{ w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
          ENDIF .
        ENDIF .

        IF w_final-we_street1 IS NOT INITIAL .
          IF lv_shp_adr1 IS NOT INITIAL   .
            lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
          ELSE .
            lv_shp_adr1 = |{ w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
          ENDIF .
        ENDIF .

        len = strlen( lv_shp_adr1 ) .
        len = len - 40.
        IF strlen( lv_shp_adr1 ) GT 40 .
          lv_shp_adr2 = |{ lv_shp_adr1+40(len) },| .
          lv_shp_adr1 = lv_shp_adr1+0(40) .
        ENDIF .




        """"""" ship bill address set """"""""
        DATA : heading     TYPE char100,
               sub_heading TYPE char255,
               for_sign    TYPE char100,
               head_lut    TYPE char100,
               curr        TYPE char100,
               exp_curr    TYPE char100,
               exc_rt      TYPE char100.
        DATA : lv_dt_bill TYPE char10 .
        DATA : lv_dt_po TYPE char10 .
        DATA : lv_dt_ack TYPE char10 .

        exc_rt = w_final-accountingexchangerate .
        SELECT SINGLE * FROM zsd_einvoice WHERE billingdocument = @w_final-billingdocument
          INTO @DATA(w_einvvoice) .
        CLEAR : lv_qr_code , lv_irn_num   , lv_ack_no ,lv_ack_date .

        lv_qr_code = w_einvvoice-signedqrcode .
        lv_irn_num = w_einvvoice-irn .
        lv_ack_no =  w_einvvoice-ackno .
        lv_ack_date =  w_einvvoice-ackdt .
        lv_eway     = w_einvvoice-ewbno.
        lv_eway_dt  = w_einvvoice-ewbdt. "w_einvvoice-ewbdt+6(2) && '/' && w_einvvoice-ewbdt+4(2) && '/' && w_einvvoice-ewbdt+0(4).
        """sub_heading = '(Issued Under Section 31 of Central Goods & Service Tax Act 2017 and HARYANA State Goods & Service Tax Act 2017)' .
        sub_heading = '' .
        for_sign  = 'Jumps Auto Industries Limited' .

        """""" Date conversion """"
        lv_dt_bill  = w_final-billingdocumentdate+6(2) && '/' && w_final-billingdocumentdate+4(2) && '/' && w_final-billingdocumentdate+0(4).
        lv_dt_ack = lv_ack_date+6(2) && '/' && lv_ack_date+4(2) && '/' && lv_ack_date+0(4).
        lv_dt_po = w_final-customerpurchaseorderdate+6(2) && '/' && w_final-customerpurchaseorderdate+4(2) && '/' && w_final-customerpurchaseorderdate+0(4).
        """""" Date Conversion """"

        IF im_prntval = 'Original'.
          odte_text = |Original                                   Duplicate                                 Triplicate                                      Extra|.     "'Original Invoice'.
        ELSEIF im_prntval = 'Duplicate'.
          odte_text = 'Pink-Duplicate'.     "'Duplicate Invoice'.
        ELSEIF im_prntval = 'Triplicate'.
          odte_text = 'Yellow-Triplicate'.  "'Triplicate Invoice'.
        ELSEIF im_prntval = 'Extra'.
          odte_text = 'Extra Invoice Copy'.
        ENDIF.

        IF iv_action = 'taxinv' .

          heading = 'TAX INVOICE'.

          IF w_final-distributionchannel = '30' .
            "heading = 'EXPORT INVOICE'  .
            IF w_final-item_igstrate IS INITIAL .
              sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017'.
              "*head_lut = 'Against LUT No.(ARN No. AD060323015122V DT. 29/03/23'.
            ELSE .
              sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017'.
              "" head_lut = 'Against LUT No.(ARN No. AD060323015122V DT. 21/03/23'.
            ENDIF .
          ELSE .
            "heading = 'TAX INVOICE'  .
            sub_heading = 'Under Section 31 of CGST Act and SGST Act read with section 20 of IGST Act'.
          ENDIF .

        ELSEIF iv_action = 'oeminv' .
          heading = 'TAX INVOICE'  .
          sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017'.

        ELSEIF iv_action = 'dchlpr' .
          heading     = 'DELIVERY CHALLAN'.
          IF w_final-billingdocumenttype = 'JSN'.
            sub_heading = 'RETURNABLE CHALLAN (JOB WORK)'.
          ENDIF.
          IF im_prntval = 'Original'.
            odte_text = |Original                                   Duplicate                                 Triplicate                                      Extra|.
          ELSEIF im_prntval = 'Duplicate'.
            odte_text = 'Duplicate Challan'.
          ELSEIF im_prntval = 'Triplicate'.
            odte_text = 'Triplicate Challan'.
          ELSEIF im_prntval = 'Extra'.
            odte_text = 'Extra Challan Copy'.
          ENDIF.

          """"""""""""""""""" bill to party equals ship to party in challan case .
          w_final-ship_to_party = w_final-bill_to_party .
          w_final-we_name  = w_final-re_name .
          lv_shp_adr1 = lv_bill_adr1 .
          lv_shp_adr2 = lv_bill_adr2 .
          w_final-we_city  = w_final-re_city .
          w_final-we_pin = w_final-re_pin   .
          w_final-we_tax  = w_final-re_tax  .
          w_final-we_pan = w_final-re_pan  .
          w_final-we_region = w_final-re_region  .
          w_final-we_city = w_final-re_city .
          w_final-we_city = w_final-re_city  .
          w_final-we_phone4  = w_final-re_phone4  .
          w_final-we_email = w_final-re_email .

          "w_final-PurchaseOrderByCustomer = w_final-PurchaseOrder .

          lv_dt_po = lv_dt_bill .


          CLEAR : exc_rt .  """" will add read text of nature of work ...
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z018' .
          IF sy-subrc = 0 .
            exc_rt = w_text-longtext .
          ENDIF .
          """"""""""""""""""" bill to party equals ship to party in challan case .

        ELSEIF iv_action = 'dcnote' .
          IF w_final-billingdocumenttype = 'G2' OR w_final-billingdocumenttype = 'CBRE'.
            heading = 'CREDIT NOTE'  .
            sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017'.
          ELSEIF w_final-billingdocumenttype = 'L2' .
            heading = 'DEBIT NOTE'  .
            sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017' .
          ENDIF .

        ELSEIF iv_action = 'aftinv'.
          heading = 'TAX INVOICE'.
          sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017'.
        ENDIF .

        curr     = w_final-transactioncurrency .
        exp_curr = w_final-transactioncurrency.

        CONDENSE : exc_rt , curr , heading , sub_heading , head_lut , for_sign ,  lv_shp_adr1 , lv_shp_adr2, exp_curr.


        SELECT SINGLE * FROM i_regiontext  WHERE region = @w_final-region AND language = 'E' AND country = 'IN'
         INTO @DATA(lv_st_nm).

        SELECT SINGLE * FROM i_regiontext  WHERE region = @w_final-re_region AND language = 'E' AND country = 'IN'
        INTO @DATA(lv_st_name_re).

        SELECT SINGLE * FROM i_regiontext  WHERE region = @w_final-we_region AND language = 'E' AND country = 'IN'
        INTO @DATA(lv_st_name_we).


        SELECT SINGLE * FROM i_countrytext   WHERE country = @w_final-country AND language = 'E'
        INTO @DATA(lv_cn_nm).

        SELECT SINGLE * FROM i_countrytext   WHERE country = @w_final-re_country AND language = 'E'
        INTO @DATA(lv_cn_name_re).

        SELECT SINGLE * FROM i_countrytext   WHERE country = @w_final-we_country AND language = 'E'
        INTO @DATA(lv_cn_name_we).

        IF iv_action = 'dchlpr' .
          w_final-purchaseorderbycustomer = w_final-purchaseorder .
          "" w_final-PurchaseOrderByCustomer
        ENDIF.

        w_final-plantname = 'Jumps Auto Industries Limited'.
        w_final-phoneareacodesubscribernumber = '+91-1244-710100'.
        lv_place_supply = w_final-we_city && '-' && lv_cn_name_we-countryname.

        DATA(lv_xml) = |<Form>| &&
                       |<BillingDocumentNode>| &&
                       |<heading>{ heading }</heading>| &&
                       |<sub_heading>{ sub_heading }</sub_heading>| &&
                       |<head_lut>{ head_lut }</head_lut>| &&
                       |<for_sign>{ for_sign }</for_sign>| &&
                       |<odte_text>{ odte_text }</odte_text>| &&
                       |<doc_curr>{ curr }</doc_curr>| &&
                       |<exp_curr>{ exp_curr }</exp_curr>| &&
                       |<plant_code>{ w_final-plant }</plant_code>| &&
                       |<plant_name>{ w_final-plantname }</plant_name>| &&
                        |<plant_address_l1>125, Pace City 1</plant_address_l1>| &&
                       |<plant_address_l2>Sector 37</plant_address_l2>| &&
                       |<plant_address_l3>Gurugram - 122001 , India</plant_address_l3>| &&
                        |<plant_cin>U29299DL1999PLC098434</plant_cin>| &&
                        |<plant_gstin>{ w_final-plant_gstin }</plant_gstin>| &&
                        |<plant_pan>{ w_final-plant_gstin+2(10) }</plant_pan>| &&
                        |<plant_state_code>{ w_final-region }</plant_state_code>| &&
                        |<plant_state_name></plant_state_name>| &&
                        |<plant_phone>{ w_final-phoneareacodesubscribernumber }</plant_phone>| &&
                        |<plant_email>{ w_final-plant_email }</plant_email>| &&

                        |<billto_code>{ w_final-bill_to_party }</billto_code>| &&
                        |<billto_name>{ w_final-re_name }</billto_name>| &&
                        |<billto_address_l1>{ lv_bill_adr1 }</billto_address_l1>| &&
                        |<billto_address_l2>{ lv_bill_adr2 }{ w_final-re_city }</billto_address_l2>| &&
                        |<billto_address_l3>{ w_final-re_pin } ({ lv_cn_name_re-countryname })</billto_address_l3>| &&
*                        |<billto_cin>{ W_FINAL-re }</billto_cin>| &&
                        |<billto_gstin>{ w_final-re_tax }</billto_gstin>| &&
                        |<billto_pan>{ w_final-re_pan }</billto_pan>| &&
                        |<billto_state_code>{ w_final-re_region } ({ lv_st_name_re-regionname })</billto_state_code>| &&
                        |<billto_state_name></billto_state_name>| &&
                        |<billto_place_suply>{ w_final-re_region }</billto_place_suply>| &&
                        |<billto_phone>{ w_final-re_phone4 }</billto_phone>| &&
                        |<billto_email>{ w_final-re_email }</billto_email>| &&

                        |<shipto_code>{ w_final-ship_to_party }</shipto_code>| &&
                        |<shipto_name>{ w_final-we_name }</shipto_name>| &&
                        |<shipto_address_l1>{ lv_shp_adr1 }</shipto_address_l1>| &&
                        |<shipto_address_l2>{ lv_shp_adr2 }{ w_final-we_city }</shipto_address_l2>| &&
                        |<shipto_address_l3>{ w_final-we_pin } ({ lv_cn_name_we-countryname })</shipto_address_l3>| &&
*                        |<shipto_cin>{ W_FINAL-PlantName }</shipto_cin>| &&
                        |<shipto_gstin>{ w_final-we_tax }</shipto_gstin>| &&
                        |<shipto_pan>{ w_final-we_pan }</shipto_pan>| &&
                        |<shipto_state_code>{ w_final-we_region } ({ lv_st_name_we-regionname })</shipto_state_code>| &&
                        |<shipto_state_name>{ lv_st_name_we-regionname }</shipto_state_name>| &&
                        |<shipto_place_suply>{ lv_place_supply }</shipto_place_suply>| &&
                        |<shipto_phone>{ w_final-we_phone4 }</shipto_phone>| &&
                        |<shipto_email>{ w_final-we_email }</shipto_email>| &&

                        |<inv_no>{ w_final-documentreferenceid }  </inv_no>| &&
                        |<inv_date>{ lv_dt_bill }</inv_date>| &&
                        |<inv_ref>{ w_final-billingdocument }</inv_ref>| &&
                        |<exchange_rate>{ exc_rt }</exchange_rate>| &&
                        |<currency>{ w_final-transactioncurrency }</currency>| &&
                        |<Exp_Inv_No>{ lv_exp_no }</Exp_Inv_No>| &&       """""""
                        |<IRN_num>{ lv_irn_num }</IRN_num>| &&
                        |<IRN_ack_No>{ lv_ack_no }</IRN_ack_No>| &&
                        |<irn_ack_date>{ lv_dt_ack }</irn_ack_date>| &&
                        |<irn_doc_type></irn_doc_type>| &&     """"""
                        |<irn_category></irn_category>| &&     """"""
                        |<qrcode>{ lv_qr_code }</qrcode>| &&
                        |<vcode>{ vcode }</vcode>| &&    """"" USING ZTABLE DATA TO BE MAINTAINED ...
                        |<vplant>{ lv_cus_pl }</vplant>| &&
                        |<pur_odr_no>{ w_final-purchaseorderbycustomer }</pur_odr_no>| &&
                        |<pur_odr_date>{ lv_dt_po }</pur_odr_date>| &&
                        |<Pay_term>{ w_final-customerpaymenttermsname }</Pay_term>| &&  """"
                        |<Veh_no>{ lv_vehicle }</Veh_no>| &&    """"" badi to save ewaybill & einvoice data from DRC
                        |<Trans_mode>{ lv_transmode }</Trans_mode>| &&
                        |<Ewaybill_no>{ lv_eway }</Ewaybill_no>| &&
                        |<Ewaybill_date>{ lv_eway_dt }</Ewaybill_date>| &&

                       |<ItemData>| .

        DATA : lv_item TYPE string .
        DATA : srn      TYPE char3,
               lv_matnr TYPE char120.
        CLEAR : lv_item , srn .

        LOOP AT it_final INTO DATA(w_item) .
          srn = srn + 1 .

*          IF iv_action = 'dchlpr' .
*            w_item-MaterialByCustomer = w_item-product .
*
*            IF w_item-item_pcip_amt IS NOT INITIAL .
*              w_item-item_unitprice = w_item-item_pcip_amt .
*            ELSEIF w_item-item_unitprice IS NOT INITIAL .
*              w_item-item_unitprice = w_item-item_unitprice .
*            ENDIF .
*
*          ENDIF .

          """          IF w_final-DistributionChannel = '30' .
*          IF iv_action NE 'aftinv' .
*            IF w_item-ConditionQuantity IS NOT INITIAL .
*              w_item-item_unitprice = w_item-item_unitprice / w_item-ConditionQuantity .
*            ENDIF .
*          ENDIF .

          IF iv_action = 'dchlpr' AND w_item-item_unitprice IS INITIAL.  ""IV_ACTION
            w_item-item_unitprice  = w_item-item_pcip_amt.
            w_item-item_totalamount_inr = w_item-item_pcip_amt * w_item-billingquantity.
          ENDIF.

          w_item-item_totalamount_inr = w_item-billingquantity * w_final-accountingexchangerate * w_item-item_unitprice .
          w_item-item_discountamount = w_item-item_discountamount *   w_final-accountingexchangerate  .

          if w_item-conditionquantity is NOT INITIAL.
           w_item-item_assessableamount = ( w_item-item_totalamount_inr / w_item-conditionquantity ) -  w_item-item_discountamount.
          ENDIF.

          w_item-item_sgstamount = w_item-item_assessableamount  *     w_item-item_cgstrate / 100  .
          w_item-item_cgstamount = w_item-item_assessableamount  *    w_item-item_cgstrate / 100    .
          w_item-item_igstamount = w_item-item_assessableamount  *   w_item-item_igstrate / 100   .
          w_item-item_amotization = w_item-item_amotization  *   w_final-accountingexchangerate  .

          lv_qty = lv_qty  +   w_item-billingquantity .

          lv_dis = lv_dis + w_item-item_discountamount .
          lv_tot_cgst = lv_tot_cgst  + w_item-item_cgstamount .
          lv_tot_sgst = lv_tot_sgst  + w_item-item_sgstamount .
          lv_tcs = lv_tcs +  w_item-item_othercharge .
          lv_other_chrg = lv_other_chrg + w_item-item_freight .
          lv_round_off = lv_round_off +  w_item-item_roundoff .
          sum_other_chrg = sum_other_chrg + w_item-item_fert_oth.

          """"       ENDIF

          DATA : lv_item_text TYPE string .
          CLEAR : lv_item_text .

          lv_item_text = w_item-billingdocumentitemtext. "|{ w_item-MaterialByCustomer } - { w_item-BillingDocumentItemText }|.
          "*w_item-MaterialByCustomer = w_item-ProductOldID .

          IF w_item-productoldid IS NOT INITIAL.
            lv_matnr = w_item-productoldid. "w_item-product && '(' && w_item-ProductOldID && ')'.
          ELSE.
            lv_matnr = w_item-product.
          ENDIF.

          lv_ref_sddoc = w_item-materialbycustomer.

          REPLACE ALL OCCURRENCES OF '&' IN lv_item_text WITH '' .
          REPLACE ALL OCCURRENCES OF '&' IN lv_ref_sddoc WITH '' .

          IF w_item-conditionquantity IS NOT INITIAL .
            lv_item_urate  = w_item-item_unitprice / w_item-conditionquantity .
            lv_item_amtinr = w_item-item_totalamount_inr / w_item-conditionquantity.
            lv_item_amtexp = lv_item_urate * w_item-billingquantity.
            "*w_item-item_assessableamount = w_item-item_assessableamount / w_item-conditionquantity.
            "*w_item-item_igstamount   = w_item-item_igstamount / w_item-conditionquantity.
          ELSE.
            lv_item_urate  = w_item-item_unitprice.
            lv_item_amtinr = w_item-item_totalamount_inr.
            lv_item_amtexp = w_item-item_unitprice * w_item-billingquantity.
          ENDIF.

          lv_amt_expcurr  = lv_amt_expcurr + lv_item_amtexp.
          lv_mrp_of_goods = w_item-item_zmrp_amount.
          lv_tot_amt      = lv_tot_amt +   lv_item_amtinr. "w_item-item_totalamount_inr .
          lv_tax_amt      = lv_tax_amt + w_item-item_assessableamount .
          lv_tot_igst     = lv_tot_igst  + w_item-item_igstamount .

          IF w_item-billingquantityunit EQ 'ST'.
            w_item-billingquantityunit = 'NOS'.
          ENDIF.

          lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                    |<sno>{ srn }</sno>| &&
                    |<item_code>{ lv_matnr }</item_code>| &&
                    |<item_cust_refno>{ lv_ref_sddoc }</item_cust_refno>| &&
                    |<item_desc>{ lv_item_text }</item_desc>| &&
                    |<item_hsn_code>{ w_item-hsn }</item_hsn_code>| &&
                    |<mrp_of_goods>{ lv_mrp_of_goods }</mrp_of_goods>| &&
                    |<item_uom>{ w_item-billingquantityunit }</item_uom>| &&
                    |<item_qty>{ w_item-billingquantity }</item_qty>| &&
                    |<item_unit_rate>{ lv_item_urate }</item_unit_rate>| &&
                    |<item_amt_inr>{ lv_item_amtinr }</item_amt_inr>| &&
                    |<item_amt_expcurr>{ lv_item_amtexp }</item_amt_expcurr>| &&
                    |<item_discount>{ w_item-item_discountamount }</item_discount>| &&
                    |<item_taxable_amt>{ w_item-item_assessableamount }</item_taxable_amt>| &&
                    |<item_sgst_rate>{ w_item-item_sgstrate }</item_sgst_rate>| &&
                    |<item_sgst_amt>{ w_item-item_sgstamount }</item_sgst_amt>| &&
                    |<item_cgst_amt>{ w_item-item_cgstamount }</item_cgst_amt>| &&
                    |<item_cgst_rate>{ w_item-item_cgstrate }</item_cgst_rate>| &&
                    |<item_igst_amt>{ w_item-item_igstamount }</item_igst_amt>| &&
                    |<item_igst_rate>{ w_item-item_igstrate }</item_igst_rate>| &&
                    |<item_amort_amt>{ w_item-item_amotization }</item_amort_amt>| &&

                    |</ItemDataNode>|  .


          lv_tot_igst1 = lv_tot_igst1 + ( ( w_item-item_assessableamount + w_item-item_freight + w_item-item_fert_oth ) * w_item-item_igstrate / 100 ) .
          lv_tot_cgst1 = lv_tot_cgst1 + ( ( w_item-item_assessableamount + w_item-item_freight + w_item-item_fert_oth ) * w_item-item_cgstrate / 100 ) .
          lv_tot_sgst1 = lv_tot_sgst1 + ( ( w_item-item_assessableamount + w_item-item_freight + w_item-item_fert_oth ) * w_item-item_sgstrate / 100 ) .

        ENDLOOP .

        IF w_final-distributionchannel = '30' .

          lv_other_chrg  = lv_other_chrg * w_final-accountingexchangerate .
          sum_other_chrg = sum_other_chrg * w_final-accountingexchangerate .

          "          lv_tot_igst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_igstrate / 100  .

          "" lv_tot_igst  = lv_tot_igst * w_final-AccountingExchangeRate .

          lv_grand_tot =  lv_tax_amt + lv_tot_sgst + lv_tot_cgst + lv_tot_igst1
                          + lv_other_chrg  + lv_round_off + sum_other_chrg.  "" + lv_tcs

          lv_tot_gst = lv_tot_sgst + lv_tot_cgst + lv_tot_igst1 .
        ELSE .

          lv_other_chrg  = lv_other_chrg * w_final-accountingexchangerate.
          sum_other_chrg = sum_other_chrg * w_final-accountingexchangerate.

          "         lv_tot_igst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_igstrate / 100  .

          "        lv_tot_cgst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_cgstrate / 100  .

          "       lv_tot_sgst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_sgstrate / 100  .

          "" lv_tot_igst  = lv_tot_igst * w_final-AccountingExchangeRate .

          lv_grand_tot =  lv_tax_amt + lv_tot_sgst1 + lv_tot_cgst1 + lv_tot_igst1
                          + lv_other_chrg  + lv_round_off  + lv_tcs + sum_other_chrg.

          lv_tot_gst = lv_tot_sgst1 + lv_tot_cgst1 + lv_tot_igst1 .

        ENDIF .

        DATA : lv_grand_tot_word TYPE string,
               lv_gst_tot_word   TYPE string.
        lv_grand_tot_word = lv_grand_tot .
        lv_gst_tot_word = lv_tot_gst .

        lo_amt_words->number_to_words(
         EXPORTING
           iv_num   = lv_grand_tot_word
         RECEIVING
           rv_words = DATA(grand_tot_amt_words)
       ).

        lo_amt_words->number_to_words(
          EXPORTING
            iv_num   = lv_gst_tot_word
          RECEIVING
            rv_words = DATA(gst_tot_amt_words)
        ).


        IF iv_action = 'dchlpr' .
          IF w_final-billingdocumenttype = 'F8'.

            lv_certify_1 = 'It is Certified that the particulars given above are true and correct and'
                        && 'amount indicated represents the price actually changed and that there'
                        && 'is no flow of additional consideration directly or indirectly from the buyer'.

          ELSEIF w_final-billingdocumenttype = 'JSN'.

            lv_certify_1 = 'Tax is payable under reverse charge: Yes / No'.
            lv_certify_2 = 'For JOB WORK / RETURNABLE MATERIAL DELIVERY CHALLAN, THE MATERIAL MUST BE SENT BACK'
                        && 'WITHIN 1 YEAR FOR CAPITAL GOODS LIKE FIXTURES, THE GOODS MUST BE SENT BACK WITHIN 3 YEAR'.

          ENDIF.
        ENDIF.

        lv_xml = |{ lv_xml }{ lv_item }| &&
                           |</ItemData>| &&

                        |<total_amount_words>(INR) { grand_tot_amt_words }</total_amount_words>| &&
                        |<gst_amt_words>(INR) { gst_tot_amt_words }</gst_amt_words>| &&
                        |<remark_if_any>{ lv_remarks }</remark_if_any>| &&
                        |<no_of_package>{ lv_no_pck }</no_of_package>| &&
                        |<total_Weight>{ lv_qty }</total_Weight>| &&
                        |<gross_Weight>{ lv_gross }</gross_Weight>| &&
                        |<net_Weight>{ lv_net }</net_Weight>| &&
                        |<tot_qty>{ lv_qty }</tot_qty>| &&  """ line item total quantity
                        |<total_amount>{ lv_tot_amt }</total_amount>| &&
                        |<total_discount>{ lv_dis }</total_discount>| &&
                        |<total_taxable_value>{ lv_tax_amt }</total_taxable_value>| &&
                        |<total_cgst>{ lv_tot_cgst }</total_cgst>| &&
                        |<total_sgst>{ lv_tot_sgst }</total_sgst>| &&
                        |<total_igst>{ lv_tot_igst }</total_igst>| &&
                        |<total_igst1>{ lv_tot_igst1 }</total_igst1>| &&  """ printing in total
                        |<total_sgst1>{ lv_tot_sgst1 }</total_sgst1>| &&  """ printing in total
                        |<total_cgst1>{ lv_tot_cgst1 }</total_cgst1>| &&  """ printing in total
                    ""    |<total_igst1>{ lv_tot_igst }</total_igst1>| &&
                        |<total_tcs>{ lv_tcs }</total_tcs>| &&
                        |<total_other_chrg>{ lv_other_chrg }</total_other_chrg>| &&
                        |<sum_other_chrg>{ sum_other_chrg }</sum_other_chrg>| &&
                        |<round_off>{ lv_round_off }</round_off>| &&
                        |<grand_total>{ lv_grand_tot }</grand_total>| &&
                        |<total_amt_expcurr>{ lv_amt_expcurr }</total_amt_expcurr>| &&

                        |<certify_1>{ lv_certify_1 }</certify_1>| &&
                        |<certify_2>{ lv_certify_2 }</certify_2>| &&
                        |<certify_3>{ lv_certify_3 }</certify_3>| &&

                           |</BillingDocumentNode>| &&
                           |</Form>|.

        DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
        iv_xml_base64 = ls_data_xml_64.

      ENDMETHOD.
ENDCLASS.
