CLASS zcl_ge_process DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      xt_final TYPE TABLE OF zstr_ge_po_f4_data,
      xt_data  TYPE TABLE OF zstr_ge_data,
      gt_final TYPE TABLE OF zmm_ge_data,
      gs_final TYPE zmm_ge_data.

    METHODS:
      get_po_f4_data
        IMPORTING
                  iv_lifnr       TYPE char10
                  iv_werks       TYPE char4
        RETURNING VALUE(et_data) LIKE xt_final,

      get_ge_change_data
        IMPORTING
                  iv_genum       TYPE char10
        RETURNING VALUE(et_data) LIKE xt_data,

      save_data_get_genum
        IMPORTING
                  xt_gedata        LIKE xt_data
                  im_action        TYPE char10
        RETURNING VALUE(rv_ge_num) TYPE char120.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_GE_PROCESS IMPLEMENTATION.


  METHOD get_ge_change_data.

    DATA:
      gs_change TYPE zstr_ge_data,
      gt_item   TYPE TABLE OF zstr_ge_item,
      gs_item   TYPE zstr_ge_item.

    SELECT * FROM zmm_ge_data WHERE gentry_num = @iv_genum
             INTO TABLE @DATA(gt_gedata).

    DATA(gt_pitem) = gt_gedata[].
    SORT gt_gedata BY gentry_num.
    DELETE ADJACENT DUPLICATES FROM gt_gedata COMPARING gentry_num.

    LOOP AT gt_gedata INTO DATA(gs_gedata).

      MOVE-CORRESPONDING gs_gedata TO gs_change.

      IF gs_change-check_rc EQ 'X'.
        gs_change-check_rc = 'true'.
      ENDIF.

      IF gs_change-check_pollt EQ 'X'.
        gs_change-check_pollt = 'true'.
      ENDIF.

      IF gs_change-check_tripal EQ 'X'.
        gs_change-check_tripal = 'true'.
      ENDIF.

      IF gs_change-check_insur EQ 'X'.
        gs_change-check_insur = 'true'.
      ENDIF.

      IF gs_change-check_dl EQ 'X'.
        gs_change-check_dl = 'true'.
      ENDIF.


      LOOP AT gt_pitem INTO DATA(gs_pitem) WHERE gentry_num = gs_gedata-gentry_num.

        MOVE-CORRESPONDING gs_pitem TO gs_item.
        gs_item-ebeln = gs_item-ponum.
        gs_item-ebelp = gs_item-poitem.
        APPEND gs_item TO gt_item.

      ENDLOOP.

      INSERT LINES OF gt_item INTO TABLE gs_change-ge_item.
      APPEND gs_change TO et_data.

    ENDLOOP.


  ENDMETHOD.


  METHOD get_po_f4_data.

    DATA:
      gt_data     TYPE TABLE OF zstr_ge_po_f4_data,
      gs_data     TYPE zstr_ge_po_f4_data,
      lv_open_qty TYPE p DECIMALS 2,
      gv_werks    TYPE char4,
      gv_lifnr    TYPE char10.

    gv_werks = iv_werks.
    gv_lifnr = iv_lifnr.
*      gv_werks = '1001'.
*      gv_lifnr = 'VDC00085'.

    SELECT * FROM zi_po_data WHERE Supplier = @gv_lifnr
                                  AND Plant = @gv_werks
                                  "AND PurchaseOrder = '4500000182'
                                  "AND ValidityStartDate GE @sy-datum AND ValidityEndDate LE @sy-datum
                                  INTO TABLE @DATA(lt_po).

    SELECT * FROM zi_po_hist FOR ALL ENTRIES IN @lt_po
             WHERE PurchaseOrder = @lt_po-PurchaseOrder AND PurchaseOrderItem = @lt_po-PurchaseOrderItem
             INTO TABLE @DATA(lt_hist).

    IF lt_po[] IS NOT INITIAL.

      LOOP AT lt_po INTO DATA(ls_po).

        READ TABLE lt_hist INTO DATA(ls_hist_201) WITH KEY PurchaseOrder     = ls_po-PurchaseOrder
                                                           PurchaseOrderItem = ls_po-PurchaseOrderItem
                                                           GoodsMovementType = '101'.

        READ TABLE lt_hist INTO DATA(ls_hist_202) WITH KEY PurchaseOrder     = ls_po-PurchaseOrder
                                                           PurchaseOrderItem = ls_po-PurchaseOrderItem
                                                           GoodsMovementType = '102'.

        SELECT SINGLE
               ponum,
               poitem,
               SUM( challnqty ) AS challnqty
               FROM zmm_ge_data
               WHERE ponum = @ls_po-PurchaseOrder AND poitem = @ls_po-PurchaseOrderItem
               GROUP BY ponum, poitem
               INTO @DATA(ls_ge).

        lv_open_qty = ls_po-OrderQuantity - ls_ge-challnqty. "( ls_hist_201-Quantity - ls_hist_202-Quantity ).

        IF lv_open_qty GT 0.

          CLEAR: gs_data.
          gs_data-ebeln    =  ls_po-PurchaseOrder.
          gs_data-ebelp    =  ls_po-PurchaseOrderItem.
          gs_data-matnr    =  ls_po-Material.
          gs_data-maktx    =  ls_po-ProductDescription.
          gs_data-doc_date =  sy-datum.
          gs_data-poqty    =  ls_po-OrderQuantity.
          gs_data-opqty    =  lv_open_qty.
          gs_data-uom      =  ls_po-BaseUnit.
          gs_data-overtol  =  ls_po-OverdelivTolrtdLmtRatioInPct.
          gs_data-netprice =  ls_po-NetAmount.
          gs_data-currency =  ls_po-OrderPriceUnit.
          gs_data-per      =  ''.
          APPEND gs_data TO gt_data.

        ENDIF.

        CLEAR: ls_po,  ls_hist_201, ls_hist_202, lv_open_qty.
      ENDLOOP.

      et_data[] = gt_data[].

    ENDIF.

*    CLEAR: gs_data.
*    gs_data-ebeln    =  '1234567890'.
*    gs_data-ebelp    =  '10'.
*    gs_data-matnr    =  'MAT12345'.
*    gs_data-maktx    =  'Test Material-1'.
*    gs_data-doc_date =  sy-datum.
*    gs_data-poqty    =  40.
*    gs_data-opqty    =  20.
*    gs_data-uom      =  'EA'.
*    gs_data-overtol  =  0.
*    gs_data-netprice =  324.
*    gs_data-currency =  'INR'.
*    gs_data-per      =  1.
*    APPEND gs_data TO gt_data.
*
*    gs_data-ebeln    =  '1234567890'.
*    gs_data-ebelp    =  '20'.
*    gs_data-matnr    =  'MAT45678'.
*    gs_data-maktx    =  'Test Material-2'.
*    APPEND gs_data TO gt_data.
*
*    CLEAR: gs_data.
*    gs_data-ebeln    =  '9876544321'.
*    gs_data-ebelp    =  '10'.
*    gs_data-matnr    =  'MAT1876543'.
*    gs_data-maktx    =  'Test Material-21'.
*    gs_data-doc_date =  sy-datum.
*    gs_data-poqty    =  50.
*    gs_data-opqty    =  30.
*    gs_data-uom      =  'EA'.
*    gs_data-overtol  =  0.
*    gs_data-netprice =  324.
*    gs_data-currency =  'INR'.
*    gs_data-per      =  1.
*    APPEND gs_data TO gt_data.
*
*    CLEAR: gs_data.
*    gs_data-ebeln    =  '6645313455'.
*    gs_data-ebelp    =  '10'.
*    gs_data-matnr    =  'MAT766453'.
*    gs_data-maktx    =  'Test Material-31'.
*    gs_data-doc_date =  sy-datum.
*    gs_data-poqty    =  80.
*    gs_data-opqty    =  70.
*    gs_data-uom      =  'EA'.
*    gs_data-overtol  =  0.
*    gs_data-netprice =  324.
*    gs_data-currency =  'INR'.
*    gs_data-per      =  1.
*    APPEND gs_data TO gt_data.
*
*    et_data[] = gt_data[].

  ENDMETHOD.


  METHOD save_data_get_genum.

    IF xt_gedata[] IS NOT INITIAL.

      IF im_action = 'create'.

        TRY.

            CALL METHOD cl_numberrange_runtime=>number_get
              EXPORTING
                nr_range_nr = '10'
                object      = 'ZGATE_NUM'
              IMPORTING
                number      = DATA(ge_num)
                returncode  = DATA(rcode).
          CATCH cx_nr_object_not_found.
          CATCH cx_number_ranges.
        ENDTRY.

      ENDIF.

      LOOP AT xt_gedata INTO DATA(xs_gedata).

        MOVE-CORRESPONDING xs_gedata TO gs_final.
        IF im_action = 'change'.
          ge_num = gs_final-gentry_num.
        ENDIF.

        SHIFT ge_num LEFT DELETING LEADING '0'.
        gs_final-gentry_num  = ge_num.
        gs_final-gentry_year = sy-datum+0(4).
        gs_final-erdat    = sy-datum.
        gs_final-uzeit    = sy-uzeit.
        gs_final-uname    = sy-uname.

        LOOP AT xs_gedata-ge_item INTO DATA(xs_ge_item).
          MOVE-CORRESPONDING xs_ge_item TO gs_final.
          gs_final-ponum  = xs_ge_item-ebeln.
          gs_final-poitem = xs_ge_item-ebelp.
          APPEND gs_final TO gt_final.
        ENDLOOP.

      ENDLOOP.

      IF gt_final[] IS NOT INITIAL.

        IF im_action = 'create'.

          INSERT zmm_ge_data FROM TABLE @gt_final.
          IF sy-subrc EQ 0.
            CONCATENATE 'Gate entry number' ge_num 'generated successfully' INTO rv_ge_num SEPARATED BY space.
          ENDIF.

        ELSEIF im_action = 'change'.

          MODIFY zmm_ge_data FROM TABLE @gt_final.
          IF sy-subrc EQ 0.
            CONCATENATE 'Gate entry number' ge_num 'updated successfully' INTO rv_ge_num SEPARATED BY space.
          ENDIF.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
