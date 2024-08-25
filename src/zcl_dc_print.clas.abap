CLASS zcl_dc_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA:
      gt_acc    TYPE TABLE OF zstr_acc_data,
      gt_dcnote TYPE TABLE OF zstr_dc_data,
      xt_item   TYPE TABLE OF zstr_dc_item,
      gt_dbnote TYPE TABLE OF zstr_dc_data,
      gs_dbnote TYPE zstr_dc_data,
      gt_item   TYPE TABLE OF zstr_dc_item,
      gs_item   TYPE zstr_dc_item.

    METHODS:
      get_accounting_data
        IMPORTING
                  im_bukrs         TYPE char4
                  im_belnr         TYPE char10
                  im_gjahr         TYPE numc4
                  im_date          TYPE sy-datum
        EXPORTING
                  rv_acc_data_json TYPE string

        RETURNING VALUE(et_acc)    LIKE gt_acc,

      get_dcnote_data
        IMPORTING
                  im_bukrs         TYPE char4
                  im_belnr         TYPE char10
                  im_gjahr         TYPE numc4
                  im_action        TYPE char10
        RETURNING VALUE(et_dcdata) LIKE gt_dcnote,

      prep_xml_dcnote
        IMPORTING
                  it_dcnote            LIKE gt_dcnote
                  im_action            TYPE char10
        RETURNING VALUE(iv_xml_base64) TYPE string,

      get_payadv_data
        IMPORTING
                  im_bukrs         TYPE char4
                  im_belnr         TYPE char10
                  im_gjahr         TYPE numc4
                  im_action        TYPE char10
        RETURNING VALUE(et_payadv) LIKE gt_dbnote,

      prep_xml_payadv
        IMPORTING
                  it_payadv            LIKE gt_dbnote
                  im_action            TYPE char10
        RETURNING VALUE(iv_xml_base64) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_DC_PRINT IMPLEMENTATION.


  METHOD get_accounting_data.

    IF im_date IS INITIAL.

      SELECT
        companycode,
        accountingdocument,
        fiscalyear,
        postingdate,
        documentdate
        FROM zi_dc_note
        WHERE companycode = @im_bukrs AND accountingdocument = @im_belnr AND fiscalyear = @im_gjahr
        INTO TABLE @DATA(lt_acc).

    ELSE.

      SELECT
       companycode,
       accountingdocument,
       fiscalyear,
       postingdate,
       documentdate
       FROM zi_dc_note
       WHERE postingdate = @im_date
       INTO TABLE @lt_acc.

    ENDIF.

    IF lt_acc[] IS NOT INITIAL.

      et_acc = CORRESPONDING #( lt_acc[] ).

      DATA(json) = /ui2/cl_json=>serialize(
        data             = lt_acc[]
        compress         = abap_true
        assoc_arrays     = abap_true
        assoc_arrays_opt = abap_true
        pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
        ).

      rv_acc_data_json = json.

    ENDIF.

  ENDMETHOD.


  METHOD get_dcnote_data.

    DATA:
      lt_dcnote TYPE TABLE OF zstr_dc_data,
      ls_dcnote TYPE zstr_dc_data,
      dc_item   TYPE TABLE OF zstr_dc_item.

    DATA:
      lo_amt_words  TYPE REF TO zcl_amt_words,
      tot_amt_gst   TYPE p LENGTH 16 DECIMALS 2,
      tot_amt_igst  TYPE p LENGTH 16 DECIMALS 2,
      lv_item_rate  TYPE p LENGTH 16 DECIMALS 2,
      lv_amt_rndf   TYPE p LENGTH 16 DECIMALS 2,
      lv_amount_neg TYPE char20.

    DATA:
      lv_total_value   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_frt_amt   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_cgst_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_sgst_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_igst_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_wit_amt   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_tcs_amt   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_load_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_rndf_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_other_amt TYPE p LENGTH 16 DECIMALS 2,
      lv_grand_total   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_gst_amt   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_dc_amt    TYPE p LENGTH 16 DECIMALS 2,
      region_desc      TYPE char20,
      gs_item          TYPE zstr_dc_item.

    CREATE OBJECT lo_amt_words.

    SELECT
      *
      FROM zi_dc_note
      WHERE companycode = @im_bukrs AND accountingdocument = @im_belnr AND fiscalyear = @im_gjahr
      INTO TABLE @DATA(lt_acc).

    SELECT
      *
      FROM zi_dc_note
      WHERE companycode = @im_bukrs AND accountingdocument = @im_belnr
         AND fiscalyear = @im_gjahr AND transactiontypedetermination IN ( 'WRX', 'BSX', 'EGK', 'PRD' )
         INTO TABLE @DATA(lt_wrx_bsx).

    DATA(xt_acc) = lt_acc[].
    SORT xt_acc BY companycode accountingdocument fiscalyear.
    DELETE ADJACENT DUPLICATES FROM xt_acc COMPARING companycode accountingdocument fiscalyear.

    LOOP AT xt_acc INTO DATA(xs_acc).

      ls_dcnote-companycode        = xs_acc-companycode.
      ls_dcnote-accountingdocument = xs_acc-accountingdocument.
      ls_dcnote-fiscalyear         = xs_acc-fiscalyear.
      ls_dcnote-postingdate        = xs_acc-postingdate.
      ls_dcnote-documentdate       = xs_acc-documentdate.

      ls_dcnote-heading1  = 'JUMPS AUTO INDUSTRIES LIMITED'.
      ls_dcnote-heading2  = '125, PACE CITY-1 SECTOR 37,'.
      ls_dcnote-heading3  = 'GURUGRAM - 122001, HARYANA'.
      ls_dcnote-heading4  = '06AAACJ9063D1ZQ'.
      ls_dcnote-heading5  = 'DEBIT NOTE'.

      ls_dcnote-invoice_no = xs_acc-documentreferenceid.

      READ TABLE lt_acc INTO DATA(ls_acc_k) WITH KEY financialaccounttype = 'K'. "AccountingDocumentItemType = 'K'.
      ls_dcnote-remark     = ls_acc_k-documentitemtext.

      READ TABLE lt_acc INTO DATA(ls_acc_kbs) WITH KEY transactiontypedetermination = 'KBS'
                                                       financialaccounttype         = 'K'.
      IF sy-subrc EQ 0.

        SELECT SINGLE * FROM zi_supplier_address
        WHERE supplier = @ls_acc_kbs-supplier INTO @DATA(ls_supplier).

        ls_dcnote-to_addrs1 = ls_acc_kbs-supplier && '-' && ls_supplier-suppliername.
        ls_dcnote-to_addrs2 = ls_supplier-streetprefixname1 && ',' && ls_supplier-streetprefixname2.
        ls_dcnote-to_addrs3 = ls_supplier-streetname &&  ',' && ls_supplier-districtname. "&& ls_supplier-StreetSuffixName1 &&  ','
        ls_dcnote-to_addrs4 = ls_supplier-cityname &&  ',' && ls_supplier-postalcode. "&&  ',' && ls_supplier-Country.
        ls_dcnote-to_addrs5 = ls_supplier-taxnumber3.

        ls_dcnote-total_val = ls_acc_kbs-amountincompanycodecurrency.

      ENDIF.

      READ TABLE lt_acc INTO DATA(ls_acc_egk) WITH KEY transactiontypedetermination = 'EGK'. " and K
      IF sy-subrc EQ 0.

        SELECT SINGLE * FROM zi_supplier_address
        WHERE supplier = @ls_acc_egk-supplier INTO @ls_supplier.

        ls_dcnote-to_addrs1 = ls_supplier-supplier && '-' && ls_supplier-suppliername.
        ls_dcnote-to_addrs2 = ls_supplier-streetprefixname1 && ',' && ls_supplier-streetprefixname2.
        ls_dcnote-to_addrs3 = ls_supplier-streetname &&  ',' && ls_supplier-districtname. "ls_supplier-StreetSuffixName1 &&  ','
        ls_dcnote-to_addrs4 = ls_supplier-cityname &&  ',' && ls_supplier-postalcode. "&&  ',' && ls_supplier-Country.
        ls_dcnote-to_addrs5 = ls_supplier-taxnumber3.

        ls_dcnote-total_val = ls_acc_egk-amountincompanycodecurrency.

      ENDIF.



      """******Item Data
      CLEAR: gs_item.
      LOOP AT lt_acc INTO DATA(ls_acc)
                     WHERE companycode  = xs_acc-companycode AND
                     accountingdocument = xs_acc-accountingdocument AND
                     fiscalyear = xs_acc-fiscalyear AND
                     ( transactiontypedetermination = 'JIC' OR transactiontypedetermination = 'JIS' OR
                       transactiontypedetermination = 'JII' OR transactiontypedetermination = 'FR1' OR
                       transactiontypedetermination = 'RND' OR transactiontypedetermination = 'LOD' OR
                       transactiontypedetermination = 'OTH' OR transactiontypedetermination = 'TCS' OR
                       transactiontypedetermination = 'JOC' OR transactiontypedetermination = 'JOS' OR
                       transactiontypedetermination = 'JOI' OR transactiontypedetermination = 'WIT'
                     ).


        gs_item-companycode            = ls_acc-companycode.
        gs_item-accountingdocument     = ls_acc-accountingdocument.
        gs_item-fiscalyear             = ls_acc-fiscalyear.
        gs_item-accountingdocumentitem = ls_acc-accountingdocumentitem.
        gs_item-taxitemgroup           = ls_acc-taxitemgroup.

        CLEAR: lv_amount_neg.
        lv_amount_neg = ls_acc-amountincompanycodecurrency.
        CONDENSE lv_amount_neg.
        IF lv_amount_neg CA '-'.
          ls_acc-amountincompanycodecurrency = ls_acc-amountincompanycodecurrency * -1.
        ENDIF.

        IF ls_acc-transactiontypedetermination = 'JIC'.

          gs_item-cgst_amt  = ls_dcnote-cgst_amt + ls_acc-amountincompanycodecurrency.
          lv_sum_cgst_amt   = lv_sum_cgst_amt  + ls_acc-amountincompanycodecurrency.

        ELSEIF ls_acc-transactiontypedetermination = 'JIS'.

          gs_item-sgst_amt  = ls_dcnote-sgst_amt + ls_acc-amountincompanycodecurrency.
          lv_sum_sgst_amt  = lv_sum_sgst_amt + ls_acc-amountincompanycodecurrency.

        ELSEIF ls_acc-transactiontypedetermination = 'JII'.

          gs_item-igst_amt  = ls_dcnote-igst_amt + ls_acc-amountincompanycodecurrency.
          lv_sum_igst_amt  = lv_sum_igst_amt + ls_acc-amountincompanycodecurrency.

        ELSEIF ls_acc-transactiontypedetermination = 'WIT'.

          gs_item-tcs_amt  = ls_dcnote-tcs_amt + ls_acc-amountincompanycodecurrency.
          lv_sum_wit_amt   = lv_sum_wit_amt + ls_acc-amountincompanycodecurrency.

        ENDIF.

        gs_item-utgst_amt = ''.
        gs_item-utgst_per = ''.

        APPEND gs_item TO xt_item.

        CLEAR: ls_acc, gs_item.
      ENDLOOP.


      CLEAR: ls_acc, gs_item.
      CLEAR: lv_sum_cgst_amt, lv_sum_sgst_amt, lv_sum_igst_amt.
      DATA(lt_bsx) = lt_wrx_bsx[].
      DATA(lt_prd) = lt_wrx_bsx[].
      DELETE lt_bsx WHERE transactiontypedetermination NE 'BSX'.
      DELETE lt_prd WHERE transactiontypedetermination NE 'PRD'.

      IF lt_wrx_bsx[] IS NOT INITIAL.
        DATA(lv_wrx_bsx_line) = lines( lt_wrx_bsx ).
        IF lv_wrx_bsx_line GT 1.

          READ TABLE lt_wrx_bsx INTO DATA(lvs_egk) WITH KEY transactiontypedetermination = 'EGK'.
          IF sy-subrc NE 0.

            READ TABLE lt_wrx_bsx INTO DATA(cs_wrx) WITH KEY transactiontypedetermination = 'WRX'.
            IF sy-subrc EQ 0.
              DELETE lt_wrx_bsx WHERE transactiontypedetermination NE 'WRX'.
            ELSE.
              DELETE lt_wrx_bsx WHERE transactiontypedetermination NE 'BSX'.
            ENDIF.

          ENDIF.

        ENDIF.
      ENDIF.

      DATA(xt_kbs_s) = lt_acc[].
      DELETE xt_kbs_s WHERE transactiontypedetermination NE 'KBS'.
      DELETE xt_kbs_s WHERE financialaccounttype NE 'S'.
      IF xt_kbs_s[] IS NOT INITIAL.
        APPEND LINES OF xt_kbs_s TO lt_wrx_bsx.
      ENDIF.

      CLEAR: gs_item.
      LOOP AT lt_wrx_bsx INTO ls_acc
                     WHERE companycode  = xs_acc-companycode AND
                     accountingdocument = xs_acc-accountingdocument AND
                     fiscalyear = xs_acc-fiscalyear.


        gs_item-companycode            = ls_acc-companycode.
        gs_item-accountingdocument     = ls_acc-accountingdocument.
        gs_item-fiscalyear             = ls_acc-fiscalyear.
        gs_item-accountingdocumentitem = ls_acc-accountingdocumentitem.

        SELECT SINGLE * FROM i_glaccounttext
                        WHERE glaccount = @ls_acc-glaccount AND language = 'E'
                        INTO @DATA(ls_gltext).


        SELECT SINGLE * FROM i_productdescription
                        WHERE product = @ls_acc-material AND language = 'E'
                        INTO @DATA(ls_maktx).

        SELECT SINGLE
        product,
        plant,
        consumptiontaxctrlcode
        FROM i_productplantbasic
        WHERE product = @ls_acc-material AND plant = @ls_acc-plant
        INTO @DATA(ls_hsn).


        READ TABLE lt_bsx INTO DATA(ls_bsx) INDEX 1.
        CLEAR: lv_amount_neg.
        lv_amount_neg = ls_bsx-amountincompanycodecurrency.
        CONDENSE lv_amount_neg.
        IF lv_amount_neg CA '-'.
          ls_bsx-amountincompanycodecurrency = ls_bsx-amountincompanycodecurrency * -1.
        ENDIF.


        READ TABLE lt_prd INTO DATA(ls_prd) INDEX 1.
        CLEAR: lv_amount_neg.
        lv_amount_neg = ls_prd-amountincompanycodecurrency.
        CONDENSE lv_amount_neg.
        IF lv_amount_neg CA '-'.
          ls_prd-amountincompanycodecurrency = ls_prd-amountincompanycodecurrency * -1.
        ENDIF.

        gs_item-matnr           = ls_acc-material.

        IF ls_acc-transactiontypedetermination = 'EGK'.

          LOOP AT lt_acc INTO DATA(cs_acc) WHERE companycode  = xs_acc-companycode AND
                                                 accountingdocument = xs_acc-accountingdocument AND
                                                         fiscalyear = xs_acc-fiscalyear AND
                                                         transactiontypedetermination = ''.
            SELECT SINGLE * FROM i_glaccounttext
                            WHERE glaccount = @cs_acc-glaccount AND language = 'E'
                            INTO @ls_gltext.


            "ls_acc-Plant        = cs_acc-plant.
            CLEAR: lv_amount_neg.
            lv_amount_neg = cs_acc-amountincompanycodecurrency.
            CONDENSE lv_amount_neg.
            IF lv_amount_neg CA '-'.
              cs_acc-amountincompanycodecurrency = cs_acc-amountincompanycodecurrency * -1.
            ENDIF.

            IF cs_acc-glaccount = '0041600150'.
              lv_amt_rndf = lv_amt_rndf + cs_acc-amountincompanycodecurrency.
            ENDIF.

            gs_item-dc_amount  = cs_acc-amountincompanycodecurrency.
            gs_item-maktx      = ls_gltext-glaccountname.
            gs_item-sgtxt      = cs_acc-documentitemtext.
            gs_item-hsn        = cs_acc-in_hsnorsaccode.

            LOOP AT xt_item INTO DATA(xs_item) WHERE taxitemgroup = cs_acc-taxitemgroup.

              IF xs_item-cgst_amt IS NOT INITIAL.
                gs_item-cgst_amt   = xs_item-cgst_amt.
                lv_sum_cgst_amt    = lv_sum_cgst_amt + gs_item-cgst_amt.
              ENDIF.

              IF xs_item-sgst_amt IS NOT INITIAL.
                gs_item-sgst_amt   = xs_item-sgst_amt.
                lv_sum_sgst_amt    = lv_sum_sgst_amt + gs_item-sgst_amt.
              ENDIF.

              IF xs_item-igst_amt IS NOT INITIAL.
                gs_item-igst_amt   = xs_item-igst_amt.
                lv_sum_igst_amt    = lv_sum_igst_amt + gs_item-igst_amt.
              ENDIF.

              CLEAR: xs_item.
            ENDLOOP.

            IF gs_item-cgst_amt IS NOT INITIAL AND gs_item-cgst_per IS INITIAL.
              gs_item-cgst_per    = ( gs_item-cgst_amt * 100 ) / gs_item-dc_amount.
              "*ls_dcnote-cgst_per  = gs_item-cgst_per.
            ENDIF.

            IF gs_item-sgst_amt IS NOT INITIAL AND gs_item-sgst_per IS INITIAL.
              gs_item-sgst_per    = ( gs_item-sgst_amt * 100 ) / gs_item-dc_amount.
              "*ls_dcnote-sgst_per  = gs_item-sgst_per.
            ENDIF.

            IF gs_item-igst_amt IS NOT INITIAL AND gs_item-igst_per IS INITIAL.
              gs_item-igst_per    = ( gs_item-igst_amt * 100 ) / gs_item-dc_amount.
              "*ls_dcnote-igst_per  = gs_item-igst_per.
            ENDIF.

            IF gs_item-tcs_amt IS NOT INITIAL AND gs_item-tcs_per IS INITIAL.
              gs_item-tcs_per   = ( gs_item-tcs_amt * 100 ) / gs_item-dc_amount.
              "*ls_dcnote-tcs_per = gs_item-tcs_per.
            ENDIF.

            IF cs_acc-glaccount NE '0041600150'.
              lv_sum_dc_amt = lv_sum_dc_amt + gs_item-dc_amount.
              APPEND gs_item TO dc_item.
            ENDIF.

            CLEAR: cs_acc.
          ENDLOOP.

        ELSE.

          CLEAR: lv_amount_neg.
          lv_amount_neg = ls_acc-amountincompanycodecurrency.
          CONDENSE lv_amount_neg.
          IF lv_amount_neg CA '-'.
            ls_acc-amountincompanycodecurrency = ls_acc-amountincompanycodecurrency * -1.
          ENDIF.

          IF gs_item-matnr IS INITIAL.
            gs_item-maktx           = ls_gltext-glaccountname.
          ELSE.
            gs_item-maktx           = ls_maktx-productdescription. "ls_gltext-GLAccountName.
          ENDIF.

          gs_item-hsn             = ls_acc-in_hsnorsaccode. "ls_hsn-ConsumptionTaxCtrlCode.
          gs_item-qty             = ls_acc-quantity.
          gs_item-sgtxt           = ls_acc-documentitemtext.

          IF ls_acc-transactiontypedetermination NE 'BSX'.
            gs_item-dc_amount           = ls_acc-amountincompanycodecurrency + ls_bsx-amountincompanycodecurrency + ls_prd-amountincompanycodecurrency.
          ELSE.
            gs_item-dc_amount           = ls_acc-amountincompanycodecurrency + ls_prd-amountincompanycodecurrency.
          ENDIF.

          IF ls_acc-glaccount EQ '0041600150'.
            lv_amt_rndf = lv_amt_rndf + ls_acc-amountincompanycodecurrency..
          ENDIF.

          SHIFT gs_item-qty LEFT DELETING LEADING space.
          IF gs_item-qty IS NOT INITIAL AND gs_item-qty NE '0.000'.
            gs_item-rate          = gs_item-dc_amount / gs_item-qty.
          ENDIF.

          CLEAR: xs_item.
          LOOP AT xt_item INTO xs_item WHERE taxitemgroup = ls_acc-taxitemgroup.

            IF xs_item-cgst_amt IS NOT INITIAL.
              gs_item-cgst_amt   = xs_item-cgst_amt.
              lv_sum_cgst_amt    = lv_sum_cgst_amt + gs_item-cgst_amt.
            ENDIF.

            IF xs_item-sgst_amt IS NOT INITIAL.
              gs_item-sgst_amt   = xs_item-sgst_amt.
              lv_sum_sgst_amt    = lv_sum_sgst_amt + gs_item-sgst_amt.
            ENDIF.

            IF xs_item-igst_amt IS NOT INITIAL.
              gs_item-igst_amt   = xs_item-igst_amt.
              lv_sum_igst_amt    = lv_sum_igst_amt + gs_item-igst_amt.
            ENDIF.

            CLEAR: xs_item.
          ENDLOOP.

          IF gs_item-cgst_amt IS NOT INITIAL.
            gs_item-cgst_per    = ( gs_item-cgst_amt * 100 ) / gs_item-dc_amount.
            "*ls_dcnote-cgst_per  = gs_item-cgst_per.
          ENDIF.

          IF gs_item-sgst_amt IS NOT INITIAL.
            gs_item-sgst_per    = ( gs_item-sgst_amt * 100 ) / gs_item-dc_amount.
            "*ls_dcnote-sgst_per  = gs_item-sgst_per.
          ENDIF.

          IF gs_item-igst_amt IS NOT INITIAL.
            gs_item-igst_per    = ( gs_item-igst_amt * 100 ) / gs_item-dc_amount.
            "*ls_dcnote-igst_per  = gs_item-igst_per.
          ENDIF.

          IF gs_item-tcs_amt IS NOT INITIAL.
            gs_item-tcs_per   = ( gs_item-tcs_amt * 100 ) / gs_item-dc_amount.
            "*ls_dcnote-tcs_per = gs_item-tcs_per.
          ENDIF.

          IF ls_acc-glaccount NE '0041600150'.
            lv_sum_dc_amt = lv_sum_dc_amt + gs_item-dc_amount.
            APPEND gs_item TO dc_item.
          ENDIF.

        ENDIF.

        CLEAR: ls_acc, gs_item.
      ENDLOOP.


      """***Start:GST % Calculation*****************************
      IF lv_sum_cgst_amt IS NOT INITIAL.
        ls_dcnote-cgst_per    = ( lv_sum_cgst_amt * 100 ) / lv_sum_dc_amt.
      ENDIF.

      IF lv_sum_sgst_amt IS NOT INITIAL.
        ls_dcnote-sgst_per    = ( lv_sum_sgst_amt * 100 ) / lv_sum_dc_amt.
      ENDIF.

      IF lv_sum_igst_amt IS NOT INITIAL.
        ls_dcnote-igst_per    = ( lv_sum_igst_amt * 100 ) / lv_sum_dc_amt.
      ENDIF.

      IF lv_sum_tcs_amt IS NOT INITIAL.
        ls_dcnote-tcs_per   = ( lv_sum_tcs_amt * 100 ) / lv_sum_dc_amt.
      ENDIF.
      """***End:GST % Calculation*****************************

      ls_dcnote-cgst_amt      = lv_sum_cgst_amt.
      ls_dcnote-sgst_amt      = lv_sum_sgst_amt.
      ls_dcnote-igst_amt      = lv_sum_igst_amt.
      ls_dcnote-tcs_amt       = lv_sum_tcs_amt.
      ls_dcnote-tot_rndf_amt  = lv_amt_rndf.

      ls_dcnote-dc_note_no   = xs_acc-accountingdocument.
      ls_dcnote-dc_note_date = xs_acc-postingdate+6(2) && '.' && xs_acc-postingdate+4(2) && '.' && xs_acc-postingdate+0(4).

      DATA: lv_grand_tot_word TYPE string.

      CLEAR: lv_amount_neg.
      lv_amount_neg = ls_dcnote-total_val.
      CONDENSE lv_amount_neg.

      IF lv_amount_neg CA '-'.
        lv_grand_tot_word = ls_dcnote-total_val * -1.
      ELSE.
        lv_grand_tot_word = ls_dcnote-total_val.
      ENDIF.

      lo_amt_words->number_to_words(
        EXPORTING
          iv_num   = lv_grand_tot_word
        RECEIVING
          rv_words = DATA(amt_words)
      ).

      REPLACE ALL OCCURRENCES OF 'Rupees' IN amt_words WITH ''.
      CONCATENATE 'Rupees:' amt_words 'Only' INTO amt_words SEPARATED BY space.
      ls_dcnote-amt_in_words = amt_words.

      INSERT LINES OF dc_item INTO TABLE ls_dcnote-dc_item.
      APPEND ls_dcnote TO et_dcdata.

      CLEAR: xs_acc.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_payadv_data.

    DATA:
      lo_amt_words    TYPE REF TO zcl_amt_words,
      lv_grand_total  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_bill_amt TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_tds_amt  TYPE p LENGTH 16 DECIMALS 2.

    DATA:
      lv_amount_neg TYPE char20.

    CREATE OBJECT lo_amt_words.

    IF im_belnr IS NOT INITIAL.

      SELECT
      *
      FROM zi_dc_note
      WHERE
      companycode = @im_bukrs AND clearingaccountingdocument = @im_belnr AND clearingdocfiscalyear = @im_gjahr
      INTO TABLE @DATA(lt_acc).

      IF lt_acc[] IS NOT INITIAL.

        SELECT
          *
          FROM zi_dc_note
          FOR ALL ENTRIES IN @lt_acc
          WHERE companycode = @lt_acc-companycode AND
          accountingdocument = @lt_acc-accountingdocument AND fiscalyear = @lt_acc-fiscalyear
          INTO TABLE @DATA(lt_acc_clear).

      ENDIF.

      SELECT * FROM zi_cheque_detail
      WHERE
      paymentcompanycode = @im_bukrs AND paymentdocument = @im_belnr AND fiscalyear = @im_gjahr
      INTO TABLE @DATA(lt_chq).

      DATA(xt_acc) = lt_acc[].
      DELETE xt_acc WHERE accountingdocument NE im_belnr.


      SELECT
        *
        FROM zi_dc_note
        WHERE companycode = @im_bukrs AND
        accountingdocument = @im_belnr AND fiscalyear = @im_gjahr
        AND invoicereference NE ''
        INTO TABLE @DATA(xt_part).

      IF xt_part[] IS NOT INITIAL.

        LOOP AT xt_part ASSIGNING FIELD-SYMBOL(<lfs_part>).
          <lfs_part>-accountingdocument = <lfs_part>-invoicereference.
        ENDLOOP.

        SELECT
          *
          FROM zi_dc_note
          FOR ALL ENTRIES IN @xt_part
          WHERE companycode = @xt_part-companycode AND
          accountingdocument = @xt_part-accountingdocument AND fiscalyear = @xt_part-fiscalyear
          INTO TABLE @DATA(xt_acc_part).

        APPEND LINES OF xt_part TO lt_acc.
      ENDIF.

      LOOP AT xt_acc INTO DATA(xs_acc).

        """******Header Data
        gs_dbnote-companycode          = xs_acc-companycode.
        gs_dbnote-accountingdocument   = xs_acc-accountingdocument.
        gs_dbnote-fiscalyear           = xs_acc-fiscalyear.
        gs_dbnote-postingdate          = xs_acc-postingdate.
        gs_dbnote-documentdate         = xs_acc-documentdate.

        gs_dbnote-voucher_no        = xs_acc-clearingaccountingdocument.
        gs_dbnote-voucher_date      = xs_acc-documentdate+6(2) && '.' && xs_acc-documentdate+4(2) && '.' && xs_acc-documentdate+0(4).

        READ TABLE lt_chq INTO DATA(ls_chq) WITH KEY paymentdocument = xs_acc-clearingaccountingdocument
                                                     chequestatus    = '10'.
        gs_dbnote-bank_name         = ls_chq-bankname.
        gs_dbnote-bank_det1         = ls_chq-housebankaccount.
        gs_dbnote-bank_det2         = ''.
        gs_dbnote-cheque_no         = ls_chq-outgoingcheque.
        gs_dbnote-cheque_date       = ls_chq-chequepaymentdate+6(2) && '.' && ls_chq-chequepaymentdate+4(2) && '.' && ls_chq-chequepaymentdate+0(4).
        gs_dbnote-po_num            = ''.

        IF gs_dbnote-bank_name IS INITIAL.
          gs_dbnote-bank_name  = xs_acc-housebank.
          gs_dbnote-bank_det1  = xs_acc-housebankaccount.
        ENDIF.

*        DATA(lt_acc_plant) = lt_acc[].
*        DELETE lt_acc_plant WHERE Plant EQ ''.
*        READ TABLE lt_acc_plant INTO DATA(ls_acc_plant) INDEX 1.
*        IF sy-subrc EQ 0.
*
*          SELECT SINGLE * FROM zi_plant_address
*          WHERE plant = @ls_acc_plant-Plant INTO @DATA(ls_plant_adrs).
*
*          gs_dbnote-suppl_code         = ls_acc_plant-Plant.
*          gs_dbnote-suppl_name         = ls_plant_adrs-PlantName.
*          gs_dbnote-suppl_addr1        = ls_plant_adrs-StreetPrefixName1 && ',' && ls_plant_adrs-StreetPrefixName2.
*          gs_dbnote-suppl_addr2        = ls_plant_adrs-StreetName &&  ',' && ls_plant_adrs-StreetSuffixName1 &&  ',' && ls_plant_adrs-DistrictName.
*          gs_dbnote-suppl_addr3        = ls_plant_adrs-CityName &&  ',' && ls_plant_adrs-PostalCode .
*          gs_dbnote-suppl_cin          = 'U74899DL1988PTC031984'.
*          gs_dbnote-suppl_gstin        = '06AAECA0297J1ZO'. "for plant 1001
*          gs_dbnote-suppl_pan          = gs_dbnote-suppl_gstin+0(10).
*          gs_dbnote-suppl_stat_code    = ls_plant_adrs-Region.
*          gs_dbnote-suppl_phone        = ''.
*          gs_dbnote-suppl_email        = 'info@anandnvh.com'.
*
*        ENDIF.

        DATA(lt_acc_suppl) = lt_acc[].
        DELETE lt_acc_suppl WHERE supplier EQ ''.
        READ TABLE lt_acc_suppl INTO DATA(ls_acc_suppl) INDEX 1.
        IF sy-subrc EQ 0.

          SELECT SINGLE * FROM zi_supplier_address
          WHERE supplier = @ls_acc_suppl-supplier INTO @DATA(ls_supplier).

          gs_dbnote-suppl_code         = ls_supplier-supplier.
          gs_dbnote-suppl_name         = ls_supplier-suppliername.
          gs_dbnote-suppl_addr1        = ls_supplier-streetprefixname1 && ',' && ls_supplier-streetprefixname2.
          gs_dbnote-suppl_addr2        = ls_supplier-streetname &&  ',' && ls_supplier-streetsuffixname1 &&  ',' && ls_supplier-districtname.
          gs_dbnote-suppl_addr3        = ls_supplier-cityname &&  ',' && ls_supplier-postalcode .
          gs_dbnote-suppl_cin          = 'U74899DL1988PTC031984'.
          gs_dbnote-suppl_gstin        = '06AAECA0297J1ZO'. "for plant 1001
          gs_dbnote-suppl_pan          = gs_dbnote-suppl_gstin+0(10).
          gs_dbnote-suppl_stat_code    = ls_supplier-region.
          gs_dbnote-suppl_phone        = ''.
          gs_dbnote-suppl_email        = 'info@anandnvh.com'.

        ENDIF.

        """******Item Data


        CLEAR: gs_item.
        LOOP AT lt_acc INTO DATA(ls_acc)
                       WHERE accountingdocument NE xs_acc-accountingdocument.


          gs_item-companycode            = ls_acc-companycode.
          gs_item-accountingdocument     = ls_acc-accountingdocument.
          gs_item-fiscalyear             = ls_acc-fiscalyear.
          gs_item-accountingdocumentitem = ls_acc-accountingdocumentitem.

          gs_item-bill_num        = ls_acc-documentreferenceid.
          gs_item-bill_date       = ls_acc-postingdate+6(2) && '.' && ls_acc-postingdate+4(2) && '.' && ls_acc-postingdate+0(4).
          gs_item-debit_note_no   = ''.
          gs_item-debit_date      = ''.
          gs_item-debit_amt       = ''.

          READ TABLE xt_acc_part INTO DATA(xs_acc_part) WITH KEY
                                       companycode = ls_acc-companycode
                                       accountingdocument =  ls_acc-accountingdocument
                                       fiscalyear = ls_acc-fiscalyear.

          IF sy-subrc NE 0.

            READ TABLE lt_acc_clear INTO DATA(ls_acc_wit) WITH KEY
                                         companycode = ls_acc-companycode
                                         accountingdocument =  ls_acc-accountingdocument
                                         fiscalyear = ls_acc-fiscalyear
                                         transactiontypedetermination = 'WIT'.

            IF sy-subrc EQ 0.

              CLEAR: lv_amount_neg.
              lv_amount_neg = ls_acc_wit-amountincompanycodecurrency .
              CONDENSE lv_amount_neg.
              IF lv_amount_neg CA '-'.
                ls_acc_wit-amountincompanycodecurrency =  ls_acc_wit-amountincompanycodecurrency * -1.
              ENDIF.

              gs_item-tds_amt         = ls_acc_wit-amountincompanycodecurrency .
              lv_sum_tds_amt          = lv_sum_tds_amt + ls_acc_wit-amountincompanycodecurrency .

              CLEAR: lv_amount_neg.
              lv_amount_neg = ls_acc-cashdiscountbaseamount.
              CONDENSE lv_amount_neg.
              IF lv_amount_neg CA '-'.
                gs_item-bill_amt        = ls_acc-cashdiscountbaseamount * -1.
              ELSE.
                gs_item-bill_amt        = ls_acc-cashdiscountbaseamount.
              ENDIF.

            ELSE.

              CLEAR: lv_amount_neg.
              lv_amount_neg = ls_acc-amountincompanycodecurrency. "ls_acc-CashDiscountBaseAmount.
              CONDENSE lv_amount_neg.
              IF lv_amount_neg CA '-'.
                gs_item-bill_amt        = ls_acc-amountincompanycodecurrency * -1.
              ELSE.
                gs_item-bill_amt        = ls_acc-amountincompanycodecurrency.
              ENDIF.

            ENDIF.



            gs_item-net_amt         = gs_item-bill_amt + ( gs_item-tds_amt * -1 ).

            IF ls_acc-debitcreditcode EQ 'S'.
              gs_item-dr_cr           = 'Dr'.
              lv_grand_total          = lv_grand_total + ( gs_item-net_amt * -1 ).
              lv_sum_bill_amt         = lv_sum_bill_amt + ( gs_item-bill_amt * -1 ).
            ELSE.
              gs_item-dr_cr           = 'Cr'.
              lv_grand_total          = lv_grand_total + gs_item-net_amt.
              lv_sum_bill_amt         = lv_sum_bill_amt + gs_item-bill_amt.
            ENDIF.

          ELSE.

            READ TABLE xt_acc_part INTO DATA(xs_acc_egk) WITH KEY
                                         companycode = ls_acc-companycode
                                         accountingdocument =  ls_acc-accountingdocument
                                         fiscalyear = ls_acc-fiscalyear
                                         transactiontypedetermination = 'EGK'.

            gs_item-bill_num        = xs_acc_egk-documentreferenceid.
            gs_item-bill_date       = xs_acc_egk-postingdate+6(2) && '.' && xs_acc_egk-postingdate+4(2) && '.' && xs_acc_egk-postingdate+0(4).

            READ TABLE xt_acc_part INTO DATA(xs_acc_wit) WITH KEY
                                         companycode = ls_acc-companycode
                                         accountingdocument =  ls_acc-accountingdocument
                                         fiscalyear = ls_acc-fiscalyear
                                         transactiontypedetermination = 'WIT'.

            IF sy-subrc EQ 0.

              CLEAR: lv_amount_neg.
              lv_amount_neg = xs_acc_wit-amountincompanycodecurrency .
              CONDENSE lv_amount_neg.
              IF lv_amount_neg CA '-'.
                xs_acc_wit-amountincompanycodecurrency =  xs_acc_wit-amountincompanycodecurrency * -1.
              ENDIF.

              gs_item-tds_amt         = xs_acc_wit-amountincompanycodecurrency .
              lv_sum_tds_amt          = lv_sum_tds_amt + xs_acc_wit-amountincompanycodecurrency .

              CLEAR: lv_amount_neg.
              lv_amount_neg = xs_acc_egk-amountincompanycodecurrency. "xs_acc_egk-CashDiscountBaseAmount.
              CONDENSE lv_amount_neg.
              IF lv_amount_neg CA '-'.
                gs_item-bill_amt        = xs_acc_egk-amountincompanycodecurrency * -1.
              ELSE.
                gs_item-bill_amt        = xs_acc_egk-amountincompanycodecurrency.
              ENDIF.

            ELSE.

              CLEAR: lv_amount_neg.
              lv_amount_neg = xs_acc_egk-cashdiscountbaseamount.
              CONDENSE lv_amount_neg.
              IF lv_amount_neg CA '-'.
                gs_item-bill_amt        = xs_acc_egk-cashdiscountbaseamount * -1.
              ELSE.
                gs_item-bill_amt        = xs_acc_egk-cashdiscountbaseamount.
              ENDIF.

            ENDIF.




            READ TABLE xt_part INTO DATA(cs_part)
                                       WITH KEY companycode = ls_acc-companycode
                                         accountingdocument =  ls_acc-accountingdocument
                                         fiscalyear = ls_acc-fiscalyear.
            IF sy-subrc EQ 0.

              CLEAR: lv_amount_neg.
              lv_amount_neg = cs_part-amountincompanycodecurrency.
              CONDENSE lv_amount_neg.

              IF lv_amount_neg CA '-'.
                gs_item-net_amt         = cs_part-amountincompanycodecurrency * -1.
              ELSE.
                gs_item-net_amt         = cs_part-amountincompanycodecurrency.
              ENDIF.

            ELSE.

              gs_item-net_amt         = gs_item-bill_amt + ( gs_item-tds_amt * -1 ).

            ENDIF.

            IF xs_acc_egk-debitcreditcode EQ 'S'.
              gs_item-dr_cr           = 'Dr'.
              lv_grand_total          = lv_grand_total + ( gs_item-net_amt * -1 ).
              lv_sum_bill_amt         = lv_sum_bill_amt + ( gs_item-bill_amt * -1 ).
            ELSE.
              gs_item-dr_cr           = 'Cr'.
              lv_grand_total          = lv_grand_total + gs_item-net_amt.
              lv_sum_bill_amt         = lv_sum_bill_amt + gs_item-bill_amt.
            ENDIF.


            CLEAR: xs_acc_egk, xs_acc_wit.

          ENDIF.


          APPEND gs_item TO gt_item.

          CLEAR: ls_acc, ls_acc_wit, gs_item.
        ENDLOOP.


        gs_dbnote-grand_total     = lv_grand_total.
        gs_dbnote-chq_amt         = ''.
        gs_dbnote-sum_bil_amt     = lv_sum_bill_amt.
        gs_dbnote-sum_tds_amt     = lv_sum_tds_amt.
        gs_dbnote-sum_debit_amt   = ''.
        gs_dbnote-sum_net_amt     = lv_grand_total.

        CLEAR: lv_amount_neg.
        lv_amount_neg = lv_grand_total.
        CONDENSE lv_amount_neg.
        CONCATENATE 'Being amount of INR'
                    lv_amount_neg
                    'Paid To'
                    gs_dbnote-suppl_name
*                    'against bill no'
*                    im_belnr
                    INTO gs_dbnote-narration SEPARATED BY space.


        DATA: lv_grand_tot_word TYPE string,
              lv_gst_amt_word   TYPE string.

        IF gs_dbnote-grand_total IS NOT INITIAL.

          lv_grand_tot_word = gs_dbnote-grand_total.
          lo_amt_words->number_to_words(
            EXPORTING
              iv_num   = lv_grand_tot_word
            RECEIVING
              rv_words = DATA(amt_words)
          ).

        ENDIF.

        gs_dbnote-tot_amt_words = amt_words.

        INSERT LINES OF gt_item INTO TABLE gs_dbnote-dc_item.
        APPEND gs_dbnote TO et_payadv.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.


  METHOD prep_xml_dcnote.

    DATA : heading     TYPE char100,
           sub_heading TYPE char200.

    READ TABLE it_dcnote INTO DATA(ls_dcnote) INDEX 1.

    CONDENSE: ls_dcnote-heading2,
              ls_dcnote-heading3,
              ls_dcnote-heading4.

    CONDENSE ls_dcnote-dc_note_no.
    CONDENSE ls_dcnote-invoice_no.

    DATA(lv_xml) =  |<Form>| &&
                    |<DebitCreditNode>| &&
                    |<heading1>     { ls_dcnote-heading1 }  </heading1>| &&
                    |<heading2>{ ls_dcnote-heading2 } </heading2>| &&
                    |<heading3>{ ls_dcnote-heading3 }</heading3>| &&
                    |<heading4>{ ls_dcnote-heading4 }</heading4>| &&
                    |<heading5>{ ls_dcnote-heading5 }</heading5>| &&
                    |<to_addrs1>{ ls_dcnote-to_addrs1 }</to_addrs1>| &&
                    |<to_addrs2>{ ls_dcnote-to_addrs2 }</to_addrs2>| &&
                    |<to_addrs3>{ ls_dcnote-to_addrs3 }</to_addrs3>| &&
                    |<to_addrs4>{ ls_dcnote-to_addrs4 }</to_addrs4>| &&
                    |<to_addrs5>{ ls_dcnote-to_addrs5 }</to_addrs5>| &&
                    |<dc_note_no>{ ls_dcnote-dc_note_no }</dc_note_no>    | &&
                    |<dc_note_date>{ ls_dcnote-dc_note_date }</dc_note_date>| &&
                    |<amt_in_words>{ ls_dcnote-amt_in_words }</amt_in_words>| &&
                    |<cgst_amt>     { ls_dcnote-cgst_amt }  </cgst_amt>| &&
                    |<cgst_per>     { ls_dcnote-cgst_per }  </cgst_per>| &&
                    |<sgst_amt>     { ls_dcnote-sgst_amt }  </sgst_amt>| &&
                    |<sgst_per>     { ls_dcnote-sgst_per }  </sgst_per>| &&
                    |<igst_amt>     { ls_dcnote-igst_amt }  </igst_amt>| &&
                    |<igst_per>     { ls_dcnote-igst_per }  </igst_per>| &&
                    |<utgst_amt>    { ls_dcnote-utgst_amt }  </utgst_amt>| &&
                    |<utgst_per>    { ls_dcnote-utgst_per }  </utgst_per>| &&
                    |<tcs_amt>      { ls_dcnote-tcs_amt }  </tcs_amt>| &&
                    |<tcs_per>      { ls_dcnote-tcs_per }  </tcs_per>| &&
                    |<total_val>    { ls_dcnote-total_val }  </total_val>| &&
                    |<invoice_no>{ ls_dcnote-invoice_no }</invoice_no>| &&
                    |<round_off>{ ls_dcnote-tot_rndf_amt }</round_off>| &&
                    |<remark>{ ls_dcnote-remark }</remark>| &&
                    |<ItemData>| .

    DATA : lv_item TYPE string .
    DATA : srn      TYPE char3,
           lv_descr TYPE string.
    CLEAR : lv_item , srn .

    LOOP AT ls_dcnote-dc_item INTO DATA(ls_item).

      srn = srn + 1 .
      lv_descr = ls_item-maktx. "&& ls_item-sgtxt.
      REPLACE ALL OCCURRENCES OF '&' IN lv_descr WITH ''.

      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sr_num>{ srn }</sr_num>| &&
                |<material> { ls_item-matnr } </material>| &&
                |<description1> { lv_descr } </description1>| &&
                |<description2> { ls_item-hsn } </description2>| &&
                |<hsn> { ls_item-hsn } </hsn>| &&
                |<qty> { ls_item-qty } </qty>| &&
                |<rate> { ls_item-rate } </rate>| &&
                |<amt_in_rs>    { ls_item-dc_amount } </amt_in_rs>| &&
                |</ItemDataNode>|  .

    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</DebitCreditNode>| &&
                       |</Form>|.

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.


  METHOD prep_xml_payadv.

    DATA : heading      TYPE char100,
           sub_heading  TYPE char200,
           lv_xml_final TYPE string.

    heading      = 'ANAND NVH PRODUCTS PVT. LTD'.
    sub_heading  = 'BANK PAYMENT ADVICE'.

    READ TABLE it_payadv INTO DATA(ls_payadv) INDEX 1.
    ls_payadv-bank_name = ls_payadv-bank_name && '-' && ls_payadv-bank_det1.

    DATA(lv_xml) =  |<Form>| &&
                    |<AccountDocumentNode>| &&
                    |<heading>{ heading }</heading>| &&
                    |<sub_heading>{ sub_heading }</sub_heading>| &&
                    |<suppl_code>{ ls_payadv-suppl_code }</suppl_code>| &&
                    |<suppl_name>{ ls_payadv-suppl_name }</suppl_name>| &&
                    |<suppl_addrs1>{ ls_payadv-suppl_addr1 }</suppl_addrs1>| &&
                    |<suppl_addrs2>{ ls_payadv-suppl_addr2 }</suppl_addrs2>| &&
                    |<suppl_addrs3>{ ls_payadv-suppl_addr3 }</suppl_addrs3>| &&
                    |<suppl_addrs4>{ ls_payadv-suppl_addr4 }</suppl_addrs4>| &&
                    |<voucher_no>{ ls_payadv-voucher_no }</voucher_no>| &&
                    |<voucher_date>{ ls_payadv-voucher_date }</voucher_date>| &&
                    |<bank_name>{ ls_payadv-bank_name }</bank_name>| &&
                    |<bank_det1>{ ls_payadv-bank_det1 }</bank_det1>| &&
                    |<bank_det2>{ ls_payadv-bank_det2 }</bank_det2>| &&
                    |<cheque_no>{ ls_payadv-cheque_no }</cheque_no>| &&
                    |<cheque_date>{ ls_payadv-cheque_date }</cheque_date>| &&
                    |<po_num>{ ls_payadv-po_num }</po_num>| &&
                    |<chq_amt>{ ls_payadv-chq_amt }</chq_amt>| &&
                    |<amt_words>{ ls_payadv-tot_amt_words }</amt_words>| &&
                    |<narration>{ ls_payadv-narration }</narration>| &&
                    |<sum_bil_amt>{ ls_payadv-sum_bil_amt }</sum_bil_amt>| &&
                    |<sum_tds_amt>{ ls_payadv-sum_tds_amt }</sum_tds_amt>| &&
                    |<sum_debit_amt>{ ls_payadv-sum_debit_amt }</sum_debit_amt>| &&
                    |<sum_net_amt>{ ls_payadv-sum_net_amt }</sum_net_amt>| &&
                    |<ItemData>| .

    DATA : lv_item TYPE string .
    DATA : srn TYPE char3 .
    CLEAR : lv_item , srn .

    LOOP AT ls_payadv-dc_item INTO DATA(w_item) .

      srn = srn + 1 .

      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sr_num>{ srn }</sr_num>| &&
                |<doc_num>{ w_item-accountingdocument }</doc_num>| &&
                |<bill_num>{ w_item-bill_num }</bill_num>| &&
                |<bill_date>{ w_item-bill_date }</bill_date>| &&
                |<bill_amt>{ w_item-bill_amt }</bill_amt>| &&
                |<tds_amt>{ w_item-tds_amt }</tds_amt>| &&
                |<debit_note_no>{ w_item-debit_note_no }</debit_note_no>| &&
                |<debit_date>{ w_item-debit_date }</debit_date>| &&
                |<debit_amt>{ w_item-debit_amt }</debit_amt>| &&
                |<net_amt>{ w_item-net_amt }</net_amt>| &&
                |<dr_cr>{ w_item-dr_cr }</dr_cr>| &&
                |</ItemDataNode>|  .

    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</AccountDocumentNode>| &&
                       |</Form>|.

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.
ENDCLASS.
