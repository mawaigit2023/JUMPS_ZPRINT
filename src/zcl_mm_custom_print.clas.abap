 CLASS zcl_mm_custom_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      gt_final TYPE TABLE OF zstr_grn_data.

    METHODS:
      get_grn_data
        IMPORTING
                  iv_mblnr        TYPE char10
                  iv_gjahr        TYPE numc4
                  iv_action       TYPE char10
        RETURNING VALUE(et_final) LIKE gt_final,

      prep_xml_grn_print
        IMPORTING
                  it_final             LIKE gt_final
                  iv_action            TYPE char10
        RETURNING VALUE(iv_xml_base64) TYPE string.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_MM_CUSTOM_PRINT IMPLEMENTATION.


  METHOD get_grn_data.

     DATA: gt_grn  TYPE TABLE OF zstr_grn_data,
           gs_grn  TYPE zstr_grn_data,
           gt_item TYPE TABLE OF zstr_grn_item,
           gs_item TYPE zstr_grn_item.

     SELECT * FROM zi_grn_detail
              WHERE MaterialDocument = @iv_mblnr AND MaterialDocumentYear = @iv_gjahr AND GoodsMovementType = '101'
              INTO TABLE @DATA(lt_grn).

     IF sy-subrc EQ 0.

       DATA(lt_hdr) = lt_grn[].
       SORT lt_hdr BY materialdocument materialdocumentyear.
       DELETE ADJACENT DUPLICATES FROM lt_hdr COMPARING materialdocument materialdocumentyear.

       LOOP AT lt_hdr INTO DATA(ls_hdr).

         SELECT SINGLE * FROM I_PurchaseOrderStatus
                         WHERE PurchaseOrder = @ls_hdr-PurchaseOrder
                         INTO @DATA(ls_postat).

         IF ls_postat-PurchaseOrderType = 'NB' OR ls_postat-PurchaseOrderType = 'UD'.

           gs_grn-po_num   = ls_hdr-PurchaseOrder.
           gs_grn-po_date  = ls_hdr-PurchaseOrderDate+6(2) && '.' && ls_hdr-PurchaseOrderDate+4(2) && '.' && ls_hdr-PurchaseOrderDate+0(4).

         ELSE.

           SELECT SINGLE * FROM I_SchedgagrmthdrApi01
                           WHERE SchedulingAgreement = @ls_hdr-PurchaseOrder
                           INTO @DATA(ls_schdagr).

           IF ls_schdagr-PurchasingDocumentType = 'LP' OR ls_schdagr-PurchasingDocumentType = 'LU'.
             gs_grn-po_num   = ls_hdr-PurchaseOrder.
             gs_grn-po_date  = ls_schdagr-PurchasingDocumentOrderDate+6(2) && '.' && ls_schdagr-PurchasingDocumentOrderDate+4(2) && '.' && ls_schdagr-PurchasingDocumentOrderDate+0(4).
           ENDIF.

           SELECT * FROM zi_schagr_qty
                    FOR ALL ENTRIES IN @lt_grn
                    WHERE SchedulingAgreement = @lt_grn-PurchaseOrder
                     AND  SchedulingAgreementItem = @lt_grn-PurchaseOrderItem
                     INTO TABLE @DATA(lt_schdl).

           SELECT * FROM I_SchedgAgrmtItmApi01
                    FOR ALL ENTRIES IN @lt_grn
                    WHERE SchedulingAgreement = @lt_grn-PurchaseOrder
                     AND  SchedulingAgreementItem = @lt_grn-PurchaseOrderItem
                     INTO TABLE @DATA(lt_schdl_itm).

         ENDIF.

         gs_grn-materialdocument     = ls_hdr-materialdocument.
         gs_grn-materialdocumentyear = ls_hdr-materialdocumentyear.
         gs_grn-documentdate         = ls_hdr-documentdate.
         gs_grn-postingdate          = ls_hdr-postingdate.
         gs_grn-recpt_no             = ls_hdr-MaterialDocument.
         gs_grn-recpt_date           = ls_hdr-PostingDate+6(2) && '.' && ls_hdr-PostingDate+4(2) && '.' && ls_hdr-PostingDate+0(4).
         gs_grn-suppl_code           = ls_hdr-Supplier.
         gs_grn-suppl_name           = ls_hdr-SupplierName.
         gs_grn-suppl_addl1          = ls_hdr-StreetPrefixName1 && ',' && ls_hdr-StreetPrefixName2.
         gs_grn-suppl_addl2          = ls_hdr-StreetName &&  ',' && ls_hdr-StreetSuffixName1 &&  ',' && ls_hdr-DistrictName.
         gs_grn-suppl_addl3          = ls_hdr-CityName &&  ',' && ls_hdr-PostalCode &&  ',' && ls_hdr-Country.
         gs_grn-ge_num               = ls_hdr-MaterialDocumentHeaderText.
         gs_grn-ge_date              = ''.
         gs_grn-inv_num              = ls_hdr-ReferenceDocument.
         gs_grn-inv_date             = ls_hdr-DocumentDate+6(2) && '.' && ls_hdr-DocumentDate+4(2) && '.' && ls_hdr-DocumentDate+0(4).
         gs_grn-sl_gate_reg          = ''.
         gs_grn-insp_date            = ''.
         gs_grn-length_os            = ''.
         gs_grn-length_us            = ''.
         gs_grn-currcy               = ''.
         gs_grn-uom                  = ''.

         LOOP AT lt_grn INTO DATA(ls_grn) WHERE materialdocument = ls_hdr-MaterialDocument
                                            AND materialdocumentyear = ls_hdr-MaterialDocumentYear.

           IF ls_schdagr-PurchasingDocumentType = 'LP' OR ls_schdagr-PurchasingDocumentType = 'LU'.

             READ TABLE lt_schdl INTO DATA(ls_schdl) WITH KEY
                                  SchedulingAgreement = ls_grn-PurchaseOrder
                                  SchedulingAgreementItem = ls_grn-PurchaseOrderItem.

             ls_grn-OrderQuantity = ls_schdl-ScheduleLineOrderQuantity.
             CLEAR: ls_schdl.

             READ TABLE lt_schdl_itm INTO DATA(ls_schdl_itm) WITH KEY
                                  SchedulingAgreement = ls_grn-PurchaseOrder
                                  SchedulingAgreementItem = ls_grn-PurchaseOrderItem.

             ls_grn-NetPriceAmount = ls_schdl_itm-NetPriceAmount.
             clear: ls_schdl_itm.

           ENDIF.


           gs_item-materialdocument      = ls_grn-materialdocument.
           gs_item-materialdocumentyear  = ls_grn-materialdocumentyear.
           gs_item-documentdate          = ls_grn-documentdate.
           gs_item-postingdate           = ls_grn-postingdate.
           gs_item-item_code             = ls_grn-Material.
           gs_item-item_name             = ls_grn-ProductDescription.
           gs_item-unit                  = ls_grn-EntryUnit.
           gs_item-po_qty                = ls_grn-OrderQuantity.
           gs_item-chaln_qty             = ls_grn-QuantityInDeliveryQtyUnit.
           gs_item-actual_qty            = ls_grn-QuantityInEntryUnit.
           gs_item-rej_qty               = ls_grn-InspLotQtyToBlocked.
           gs_item-short_qty             = gs_item-chaln_qty - gs_item-actual_qty. "Bill qty - Actual qty

           IF ls_schdagr-PurchasingDocumentType = 'LP' OR ls_schdagr-PurchasingDocumentType = 'LU'.
            clear: gs_item-short_qty.
           ENDIF.

           IF ls_grn-InventoryStockType EQ '02'.
             gs_item-accept_qty            = ls_grn-InspLotQtyToFree.
           ELSE.
             gs_item-accept_qty            = ls_grn-QuantityInEntryUnit.
           ENDIF.

           gs_item-rate_per_unit         = ls_grn-NetPriceAmount.
           gs_item-doscount              = ''.
           gs_item-amt_val               = ''.
           gs_item-excise_gst            = ''.
           gs_item-qc_date               = ls_grn-MatlDocLatestPostgDate+6(2) && '.'
                                           && ls_grn-MatlDocLatestPostgDate+4(2) && '.'
                                           && ls_grn-MatlDocLatestPostgDate+0(4).

*           IF ls_grn-InventoryStockType EQ '02'.
*            gs_item-qlty_inspect  = 'Applicable'.
*           ELSEIF ls_grn-InventoryStockType EQ '01'.
*            gs_item-qlty_inspect  = 'Not Applicable'.
*           ENDIF.

            gs_item-qlty_inspect  = ls_grn-InspectionLotQuantity - ( ls_grn-InspLotQtyToFree +  ls_grn-InspLotQtyToBlocked ).

           gs_item-tot_val               = ls_grn-TotalGoodsMvtAmtInCCCrcy.
           APPEND gs_item TO gt_item.

           gs_grn-sum_tot_val          = gs_grn-sum_tot_val   + gs_item-tot_val.
           gs_grn-sum_chaln_qty        = gs_grn-sum_chaln_qty + gs_item-chaln_qty.
           gs_grn-sum_actual_qty       = gs_grn-sum_actual_qty + gs_item-actual_qty.
           gs_grn-sum_rej_qty          = gs_grn-sum_rej_qty   + gs_item-rej_qty.
           gs_grn-sum_short_qty        = gs_grn-sum_short_qty + gs_item-short_qty.
           gs_grn-sum_accpt_qty        = gs_grn-sum_accpt_qty + gs_item-accept_qty.
           gs_grn-sum_po_qty           = gs_grn-sum_po_qty + gs_item-po_qty.

         ENDLOOP.

         gs_grn-tax_on_doc           = ''.
         gs_grn-addition_val         = ''.

         INSERT LINES OF gt_item INTO TABLE gs_grn-grn_item.
         APPEND gs_grn TO gt_grn.

       ENDLOOP.

     ENDIF.

     et_final[] = gt_grn[].

  ENDMETHOD.


  METHOD prep_xml_grn_print.

    DATA : heading     TYPE char100,
           sub_heading TYPE char200,
           lv_xml_final TYPE string.

    READ TABLE it_final INTO DATA(ls_final) INDEX 1.
    REPLACE ALL OCCURRENCES OF '&' IN ls_final-suppl_name WITH 'and'.
    REPLACE ALL OCCURRENCES OF '&' IN ls_final-suppl_addl1 WITH ''.
    REPLACE ALL OCCURRENCES OF '&' IN ls_final-suppl_addl2 WITH ''.
    REPLACE ALL OCCURRENCES OF '&' IN ls_final-suppl_addl3 WITH ''.

    DATA(lv_xml) =  |<Form>| &&
                    |<MaterialDocumentNode>| &&
                    |<heading>{ heading }</heading>| &&
                    |<sub_heading>{ sub_heading }</sub_heading>| &&
                    |<RECPT_NO>{ ls_final-recpt_no }</RECPT_NO>| &&
                    |<RECPT_DATE>{ ls_final-recpt_date  }</RECPT_DATE>| &&
                    |<SUPPL_CODE>{ ls_final-suppl_code }</SUPPL_CODE>| &&
                    |<SUPPL_NAME>{ ls_final-suppl_name }</SUPPL_NAME>| &&
                    |<SUPPL_ADDL1>{ ls_final-suppl_addl1 }</SUPPL_ADDL1>| &&
                    |<SUPPL_ADDL2>{ ls_final-suppl_addl2 }</SUPPL_ADDL2>| &&
                    |<SUPPL_ADDL3>{ ls_final-suppl_addl3 }</SUPPL_ADDL3>| &&
                    |<PO_NUM>{ ls_final-po_num }</PO_NUM>| &&
                    |<PO_DATE>{ ls_final-po_date }</PO_DATE>| &&
                    |<GE_NUM>{ ls_final-ge_num }</GE_NUM>| &&
                    |<GE_DATE>{ ls_final-ge_date }</GE_DATE>| &&
                    |<INV_NUM>{ ls_final-inv_num }</INV_NUM>| &&
                    |<INV_DATE>{ ls_final-inv_date }</INV_DATE>| &&
                    |<SL_GATE_REG>{ ls_final-sl_gate_reg }</SL_GATE_REG>| &&
                    |<SUM_TOT_VAL>{ ls_final-sum_tot_val }</SUM_TOT_VAL>| &&
                    |<TAX_ON_DOC>{ ls_final-tax_on_doc }</TAX_ON_DOC>| &&
                    |<ADDITION_VAL>{ ls_final-addition_val }</ADDITION_VAL>| &&
                    |<INSP_DATE>{ ls_final-insp_date }</INSP_DATE>| &&
                    |<LENGTH_OS>{ ls_final-length_os }</LENGTH_OS>| &&
                    |<LENGTH_US>{ ls_final-length_us }</LENGTH_US>| &&
                    |<SUM_CHALN_QTY>{ ls_final-sum_chaln_qty }</SUM_CHALN_QTY>| &&
                    |<SUM_ACTUAL_QTY>{ ls_final-sum_actual_qty }</SUM_ACTUAL_QTY>| &&
                    |<SUM_REJ_QTY>{ ls_final-sum_rej_qty }</SUM_REJ_QTY>| &&
                    |<SUM_PO_QTY>{ ls_final-sum_po_qty }</SUM_PO_QTY>| &&
                    |<SUM_SHORT_QTY>{ ls_final-sum_short_qty }</SUM_SHORT_QTY>| &&
                    |<SUM_ACCPT_QTY>{ ls_final-sum_accpt_qty }</SUM_ACCPT_QTY>| &&
                    |<ItemData>| .

    DATA : lv_item TYPE string .
    DATA : srn TYPE char3 .
    CLEAR : lv_item , srn .

    LOOP AT ls_final-grn_item INTO DATA(ls_item).

      srn = srn + 1 .

      REPLACE ALL OCCURRENCES OF '&' IN ls_item-item_name WITH ''.

      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<SL_NUM>{ srn }</SL_NUM>| &&
                |<ITEM_CODE>{ ls_item-item_code }</ITEM_CODE>| &&
                |<ITEM_NAME>{ ls_item-item_name }</ITEM_NAME>| &&
                |<UNIT>{ ls_item-unit }</UNIT>| &&
                |<PO_QTY>{ ls_item-po_qty }</PO_QTY>| &&
                |<CHALN_QTY>{ ls_item-chaln_qty }</CHALN_QTY>| &&
                |<ACTUAL_QTY>{ ls_item-actual_qty }</ACTUAL_QTY>| &&
                |<REJ_QTY>{ ls_item-rej_qty }</REJ_QTY>| &&
                |<SHORT_QTY>{ ls_item-short_qty }</SHORT_QTY>| &&
                |<ACCEPT_QTY>{ ls_item-accept_qty }</ACCEPT_QTY>| &&
                |<RATE_PER_UNIT>{ ls_item-rate_per_unit }</RATE_PER_UNIT>| &&
                |<DOSCOUNT>{ ls_item-doscount }</DOSCOUNT>| &&
                |<AMT_VAL>{ ls_item-amt_val }</AMT_VAL>| &&
                |<EXCISE_GST>{ ls_item-excise_gst }</EXCISE_GST>| &&
                |<QC_DATE>{ ls_item-qc_date }</QC_DATE>| &&
                |<QLTY_INSPECT>{ ls_item-qlty_inspect }</QLTY_INSPECT>| &&
                |<TOT_VAL>{ ls_item-tot_val }</TOT_VAL>| &&
                |</ItemDataNode>|  .

    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</MaterialDocumentNode>| &&
                       |</Form>|.

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.
ENDCLASS.
