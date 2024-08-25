CLASS zcl_packing_list DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA: gt_item  TYPE TABLE OF zstr_pack_item,
          gs_item  LIKE LINE OF gt_item,
          gt_pack  TYPE TABLE OF zstr_pack_data,
          gs_pack  TYPE zstr_pack_data,
          gt_final TYPE TABLE OF zsd_pack_data,
          gs_final TYPE zsd_pack_data.

    METHODS:
      get_delivery_data
        IMPORTING
                  im_vbeln1      TYPE char10
                  im_vbeln2      TYPE char10
        RETURNING VALUE(et_item) LIKE gt_item,

      save_data_get_packnum
        IMPORTING
                  xt_pack            LIKE gt_pack
                  im_action          TYPE char10
        RETURNING VALUE(rv_pack_num) TYPE char120,

      get_pack_change_data
        IMPORTING
                  im_packnum     TYPE char10
        RETURNING VALUE(et_pack) LIKE gt_pack.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_PACKING_LIST IMPLEMENTATION.


  METHOD get_delivery_data.

    DATA:
      r_vbeln   TYPE RANGE OF I_DeliveryDocumentItem-DeliveryDocument,
      wr_vbeln  LIKE LINE OF r_vbeln,
      lv_vbeln1 TYPE char10,
      lv_vbeln2 TYPE char10.

    lv_vbeln1 = im_vbeln1.
    lv_vbeln2 = im_vbeln2.

    IF lv_vbeln2 IS INITIAL.
      lv_vbeln2 = lv_vbeln1.
    ENDIF.

    wr_vbeln-low  = lv_vbeln1.
    wr_vbeln-high = lv_vbeln2.
    wr_vbeln-sign = 'I'.
    wr_vbeln-option = 'BT'.
    APPEND wr_vbeln TO r_vbeln.

    "SELECT * FROM zi_delivery_data WHERE DeliveryDocument IN @r_vbeln INTO TABLE @DATA(lt_delv).
    SELECT * FROM zi_sale_reg WHERE BillingDocument IN @r_vbeln INTO TABLE @DATA(lt_delv).
    DATA(xt_delv) = lt_delv[].

    IF lt_delv[] IS NOT INITIAL.
      LOOP AT lt_delv INTO DATA(ls_delv).
        gs_item-vbeln        = ls_delv-BillingDocument.         "ls_delv-DeliveryDocument.
        gs_item-posnr        = ls_delv-BillingDocumentItem.     "ls_delv-DeliveryDocumentItem.
        gs_item-matnr        = ls_delv-ProductOldID.                 "ls_delv-Material., ls_delv-product.
        gs_item-kdmat        = ls_delv-MaterialByCustomer.      "ls_delv-MaterialByCustomer.
        gs_item-lfimg        = ls_delv-BillingQuantity.         "ls_delv-ActualDeliveryQuantity.
        gs_item-pallet_no    = ''.
        gs_item-type_pkg     = ''.
        gs_item-pkg_no       = ''.
        gs_item-pkg_length   = ''.
        gs_item-pkg_width    = ''.
        gs_item-pkg_height   = ''.
        gs_item-pkg_vol      = ls_delv-NetWeight.
        gs_item-uom          = ls_delv-BaseUnit.    "ls_delv-BaseUnit.
        APPEND gs_item TO gt_item.
      ENDLOOP.
    ENDIF.

    et_item[] = gt_item[].

  ENDMETHOD.


  METHOD get_pack_change_data.

    DATA:
      gt_final  TYPE TABLE OF zstr_pack_data,
      gs_final  TYPE zstr_pack_data,
      gs_item   TYPE zstr_pack_item,
      pack_item TYPE TABLE OF zstr_pack_item.

    SELECT * FROM zsd_pack_data WHERE pack_num = @im_packnum
             INTO TABLE @DATA(gt_pack).

    DATA(gt_pitem) = gt_pack[].
    SORT gt_pack BY pack_num.
    DELETE ADJACENT DUPLICATES FROM gt_pack COMPARING pack_num.

    LOOP AT gt_pack INTO DATA(gs_pack).

      MOVE-CORRESPONDING gs_pack TO gs_final.

      LOOP AT gt_pitem INTO DATA(gs_pitem) WHERE pack_num = gs_pack-pack_num.

        MOVE-CORRESPONDING gs_pitem TO gs_item.
        APPEND gs_item TO pack_item.

      ENDLOOP.

      INSERT LINES OF pack_item INTO TABLE gs_final-pack_item.
      APPEND gs_final TO et_pack.

    ENDLOOP.

*    DATA:
*      gs_item   TYPE zstr_pack_item,
*      pack_item TYPE TABLE OF zstr_pack_item.
*
*    gs_pack-pack_num            = 'CI0000000220'.
*    gs_pack-iec                 = '0500066302'.
*    gs_pack-ex_pan              = 'AAACJ9063D'.
*    gs_pack-ad_code             = '6390009-2900009'.
*    gs_pack-pre_carig_by        = 'RAIL'.
*    gs_pack-vessel              = 'SEA'.
*    gs_pack-port_of_discg       = 'DUBLIN'.
*    gs_pack-mark_no_of_cont     = 'TO:QTP, FM: JUMPS AUTO, NOS.:1-5'.
*    gs_pack-pre_carrier         = 'ICD, TUGHLAKABAD, DELHI'.
*    gs_pack-port_of_load        = 'MUNDRA / MUMBAI'.
*    gs_pack-final_dest          = 'DUBLIN'.
*    gs_pack-country_org         = 'INDIA'.
*    gs_pack-country_of_fdest    = 'IRELAND'.
*    gs_pack-pay_term            = 'FOB NEW DELHI'.
*    gs_pack-pay_mode            = 'T/T THROUGH BANK AGAINST COPY OF INVOICE'.
*    gs_pack-des_of_goods        = 'Auto Parts'.
*    gs_pack-no_kind_pkg         = '05 PALLETS'.
*    gs_pack-total_pcs           = 347.
*    gs_pack-tot_net_wgt         = 3251.
*    gs_pack-tot_gross_wgt       = 3587.
*    gs_pack-total_vol           = 456.
*
*    gs_item-vbeln        = '1234567'.
*    gs_item-posnr        = 10.
*    gs_item-matnr        = 'MATNR123456'.
*    gs_item-kdmat        = 'KDMAT123456'.
*    gs_item-lfimg        = 40.
*    gs_item-pallet_no    = '1'.
*    gs_item-type_pkg     = 'pack'.
*    gs_item-pkg_no       = 48.
*    gs_item-pkg_length   = 23.
*    gs_item-pkg_width    = 56.
*    gs_item-pkg_height   = 234.
*    gs_item-pkg_vol      = 2344.
*    gs_item-uom          = 'KG'.
*    APPEND gs_item TO pack_item.
*
*    gs_item-vbeln        = '987654543'.
*    gs_item-posnr        = 20.
*    gs_item-matnr        = 'MATNR9876543'.
*    gs_item-kdmat        = 'KDMAT345678'.
*    gs_item-lfimg        = 90.
*    gs_item-pallet_no    = '2'.
*    gs_item-type_pkg     = 'pack12'.
*    gs_item-pkg_no       = 20.
*    gs_item-pkg_length   = 30.
*    gs_item-pkg_width    = 67.
*    gs_item-pkg_height   = 765.
*    gs_item-pkg_vol      = 6543.
*    gs_item-uom          = 'KG'.
*    APPEND gs_item TO pack_item.
*
*    INSERT LINES OF pack_item INTO TABLE gs_pack-pack_item.
*    APPEND gs_pack TO et_pack.

  ENDMETHOD.


  METHOD save_data_get_packnum.

    IF xt_pack[] IS NOT INITIAL.

      IF im_action = 'create'.

        TRY.

            CALL METHOD cl_numberrange_runtime=>number_get
              EXPORTING
                nr_range_nr = '10'
                object      = 'ZPACK_NUM'
              IMPORTING
                number      = DATA(pack_num)
                returncode  = DATA(rcode).
          CATCH cx_nr_object_not_found.
          CATCH cx_number_ranges.
        ENDTRY.

      ENDIF.

      DATA: lv_item         TYPE zstr_pack_item-pack_posnr,
            lv_splitted_qty TYPE zstr_pack_item-type_pkg,
            lv_billed_qty   TYPE zstr_pack_item-lfimg,
            lv_proceed_ok   TYPE c,
            lv_qty_err_msg  TYPE string.

      READ TABLE xt_pack INTO DATA(cs_pack) INDEX 1.
      DATA(xt_item) = cs_pack-pack_item[].
      SORT xt_item BY vbeln posnr.
      DELETE ADJACENT DUPLICATES FROM xt_item COMPARING vbeln posnr.

      CLEAR: lv_proceed_ok, lv_qty_err_msg.
      LOOP AT xt_item INTO DATA(cw_item).

        CLEAR: lv_billed_qty, lv_splitted_qty.
        lv_billed_qty = cw_item-lfimg.

        LOOP AT cs_pack-pack_item INTO DATA(xs_pack_item1) WHERE vbeln = cw_item-vbeln and posnr = cw_item-posnr.

          lv_splitted_qty = lv_splitted_qty + xs_pack_item1-type_pkg.

          CLEAR: xs_pack_item1.
        ENDLOOP.

        IF lv_splitted_qty GT lv_billed_qty.
          lv_proceed_ok = abap_true.
          CONCATENATE 'Splitted qty is greater than billed qty for item number' cw_item-posnr INTO lv_qty_err_msg SEPARATED BY space.
        ENDIF.

        CLEAR: cw_item.
      ENDLOOP.

      IF lv_proceed_ok IS INITIAL.

        LOOP AT xt_pack INTO DATA(xs_pack).
          MOVE-CORRESPONDING xs_pack TO gs_final.
          IF im_action = 'change'.
            pack_num = gs_final-pack_num.
          ENDIF.
          SHIFT pack_num LEFT DELETING LEADING '0'.
          gs_final-pack_num = pack_num.
          gs_final-erdate   = sy-datum.
          gs_final-uzeit    = sy-uzeit.
          gs_final-uname    = sy-uname.
          LOOP AT xs_pack-pack_item INTO DATA(xs_pack_item).

            MOVE-CORRESPONDING xs_pack_item TO gs_final.
            lv_item = lv_item + 1.
            gs_final-pack_posnr = lv_item.

            APPEND gs_final TO gt_final.
          ENDLOOP.

        ENDLOOP.

        IF gt_final[] IS NOT INITIAL.

          IF im_action = 'create'.

            INSERT zsd_pack_data FROM TABLE @gt_final.
            IF sy-subrc EQ 0.
              CONCATENATE 'Packing number' pack_num 'generated successfully' INTO rv_pack_num SEPARATED BY space.
            ENDIF.

          ELSEIF im_action = 'change'.

            MODIFY zsd_pack_data FROM TABLE @gt_final.
            IF sy-subrc EQ 0.
              CONCATENATE 'Packing number' pack_num 'updated successfully' INTO rv_pack_num SEPARATED BY space.
            ENDIF.

          ENDIF.

        ENDIF.

        ELSE.

        rv_pack_num = lv_qty_err_msg.
      ENDIF.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
