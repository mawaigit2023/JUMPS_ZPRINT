CLASS zcl_bom_detail DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      xt_final TYPE TABLE OF zi_bom_report,
      gs_final TYPE zi_bom_report.

    METHODS:
      get_bom_data
        IMPORTING
                  im_input_str   TYPE string
        RETURNING VALUE(et_data) LIKE xt_final.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_BOM_DETAIL IMPLEMENTATION.


  METHOD get_bom_data.

    DATA:
      xt_final      TYPE TABLE OF zi_bom_report,
      xt_final_disp TYPE TABLE OF zi_bom_report,
      gs_final      TYPE zi_bom_report.

    DATA: lv_date         TYPE sy-datum,
          lv_explod_matnr TYPE char40.

    TYPES: BEGIN OF gty_mat,
             matnr_low TYPE char40,
           END OF gty_mat.

    TYPES: BEGIN OF gty_altbom,
             altbom_low TYPE char2,
           END OF gty_altbom.
    DATA:
      gt_alt TYPE TABLE OF gty_altbom,
      gs_alt TYPE gty_altbom,
      gt_mat TYPE TABLE OF gty_mat,
      gs_mat TYPE gty_mat.

    TYPES: BEGIN OF gty_input,
             matnr_high  TYPE char40,
             plant       TYPE char4,
             altbom_high TYPE char2,
             mat_low     LIKE gt_mat,
             alt_low     LIKE gt_alt,
           END OF gty_input.

    DATA:
      gt_input TYPE TABLE OF gty_input,
      gs_input TYPE gty_input.

    DATA : r_matnr  TYPE RANGE OF zi_bom_report-material,
           rw_matnr LIKE LINE OF  r_matnr,
           r_stlal  TYPE RANGE OF zi_bom_report-billofmaterialvariant,
           rw_stlal LIKE LINE OF r_stlal,
           lv_plant TYPE char4,
           r_ptype  TYPE RANGE OF zi_bom_report-comp_producttype,
           rw_ptype LIKE LINE OF  r_ptype.

    /ui2/cl_json=>deserialize(
      EXPORTING json = im_input_str
         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
         CHANGING data = gt_input
                                 ).

    IF gt_input[] IS NOT INITIAL.

      READ TABLE gt_input INTO gs_input INDEX 1.
      lv_plant = gs_input-plant.

      ""***Preparing Material Filter
      IF gs_input-matnr_high IS INITIAL.

        LOOP AT gs_input-mat_low INTO DATA(lss_matnr).

          rw_matnr-low     = lss_matnr-matnr_low.
          rw_matnr-high    = '' .
          rw_matnr-option  = 'EQ' .
          rw_matnr-sign    = 'I' .
          APPEND rw_matnr TO r_matnr.

          CLEAR: lss_matnr.
        ENDLOOP.

      ELSE.

        READ TABLE gs_input-mat_low INTO DATA(ls_matnr) INDEX 1.
        rw_matnr-low     = ls_matnr-matnr_low.
        rw_matnr-high    = gs_input-matnr_high.
        rw_matnr-option  = 'BT' .
        rw_matnr-sign    = 'I' .
        APPEND rw_matnr TO r_matnr.

      ENDIF.

      ""***Preparing BOM alternative Filter
      rw_stlal-low     = '01'.
      rw_stlal-high    = ''.
      rw_stlal-option  = 'EQ'.
      rw_stlal-sign    = 'I'.
      APPEND rw_stlal TO r_stlal.

      rw_stlal-low     = '02'.
      rw_stlal-high    = ''.
      rw_stlal-option  = 'EQ'.
      rw_stlal-sign    = 'I'.
      APPEND rw_stlal TO r_stlal.

*      IF gs_input-altbom_high IS INITIAL.
*
*        LOOP AT gs_input-alt_low INTO DATA(lss_alt).
*
*          rw_stlal-low     = lss_alt-altbom_low.
*          rw_stlal-high    = ''.
*          rw_stlal-option  = 'EQ' .
*          rw_stlal-sign    = 'I' .
*          APPEND rw_stlal TO r_stlal.
*
*          CLEAR: lss_alt.
*        ENDLOOP.
*
*      ELSE.
*
*        READ TABLE gs_input-alt_low INTO DATA(ls_alt) INDEX 1.
*        rw_stlal-low     = ls_alt-altbom_low.
*        rw_stlal-high    = gs_input-altbom_high.
*        rw_stlal-option  = 'BT' .
*        rw_stlal-sign    = 'I' .
*        APPEND rw_stlal TO r_stlal.
*
*      ENDIF.

      """**Saytem Date
      lv_date = sy-datum.

      """**Preparing Material Type filter
      rw_ptype-low     = 'FERT'.
      rw_ptype-high    = '' .
      rw_ptype-option  = 'EQ' .
      rw_ptype-sign    = 'I' .
      APPEND rw_ptype TO r_ptype.

      rw_ptype-low     = 'HALB'.
      rw_ptype-high    = '' .
      rw_ptype-option  = 'EQ' .
      rw_ptype-sign    = 'I' .
      APPEND rw_ptype TO r_ptype.


      """***Fetching and preparing data
      SELECT * FROM zi_bom_report( p_keydate = @lv_date )
               WHERE material IN @r_matnr AND
                     plant = @lv_plant AND
                     producttype EQ 'ZFDP' AND
                     billofmaterialvariant IN @r_stlal
               INTO TABLE @DATA(lt_bom_fert).

      IF lt_bom_fert[] IS NOT INITIAL.

        SELECT * FROM zi_bom_report( p_keydate = @lv_date )
                 WHERE billofmaterialvariant IN @r_stlal
                 INTO TABLE @DATA(lt_bom).

        READ TABLE lt_bom INTO DATA(ls_bom) INDEX 1.
        ls_bom-explod_matnr = ''.
        ls_bom-new_material = ''.
        MODIFY lt_bom FROM ls_bom TRANSPORTING explod_matnr new_material WHERE explod_matnr NE ''.

        DATA(lt_mat_fert) = lt_bom_fert[].
*     DELETE lt_mat_fert WHERE producttype NE 'FERT'.
        SORT lt_mat_fert BY material.
        DELETE ADJACENT DUPLICATES FROM lt_mat_fert COMPARING material.
*     DELETE lt_mat_fert WHERE material NE 'FGSTMT401100235'.

      ENDIF.

    ENDIF.

    "========================================================================"
    DATA: lv_index      TYPE sy-tabix,
          lv_index_fert TYPE sy-tabix.

    LOOP AT lt_mat_fert INTO DATA(ls_mat_fert).
      lv_index_fert = sy-tabix.

      CLEAR: xt_final.

      DATA(lt_mat_halb) = lt_bom[].
      DELETE lt_mat_halb WHERE material NE ls_mat_fert-material.
      SORT lt_mat_halb BY billofmaterialitemnumber.
      DELETE ADJACENT DUPLICATES FROM lt_mat_halb COMPARING billofmaterialitemnumber.
      APPEND LINES OF lt_mat_halb TO xt_final.

      DELETE lt_mat_halb WHERE comp_producttype NOT IN r_ptype. "NE 'FERT'.

      LOOP AT lt_mat_halb INTO DATA(ls_mat_halb).
        lv_index = sy-tabix.

        DATA(lt_mat_halb_n) = lt_bom[].
        DATA(lt_mat_fert_n) = lt_bom[].
        DELETE lt_mat_halb_n WHERE material NE ls_mat_halb-billofmaterialcomponent.
        DELETE lt_mat_fert_n WHERE material NE ls_mat_halb-billofmaterialcomponent.

        APPEND LINES OF lt_mat_halb_n TO xt_final.
        DELETE lt_mat_halb_n WHERE comp_producttype NE 'HALB'.
        DELETE lt_mat_fert_n WHERE comp_producttype NE 'FERT'.

        IF lt_mat_halb_n[] IS NOT INITIAL.
          APPEND LINES OF lt_mat_halb_n TO lt_mat_halb.
        ENDIF.

        IF lt_mat_fert_n[] IS NOT INITIAL.
          READ TABLE lt_mat_fert_n INTO DATA(ls_fert_n) INDEX 1.
          ls_fert_n-new_material = ls_mat_fert-material.
          MODIFY lt_mat_fert_n FROM ls_fert_n TRANSPORTING new_material WHERE new_material EQ ''.
          APPEND LINES OF lt_mat_fert_n TO lt_mat_fert.
        ENDIF.

        DELETE lt_mat_halb INDEX lv_index.

      ENDLOOP.

      IF xt_final[] IS NOT INITIAL.
        READ TABLE xt_final INTO DATA(ls_final) INDEX 1.
        IF ls_mat_fert-new_material IS INITIAL.
          ls_final-explod_matnr = ls_mat_fert-material.
        ELSEIF ls_mat_fert-new_material IS NOT INITIAL.
          ls_final-explod_matnr = ls_mat_fert-new_material.
        ENDIF.
        MODIFY xt_final FROM ls_final TRANSPORTING explod_matnr WHERE explod_matnr EQ ''.
        APPEND LINES OF xt_final TO xt_final_disp.
        CLEAR: xt_final.
      ENDIF.

      DELETE lt_mat_fert INDEX lv_index_fert.

    ENDLOOP.

    IF xt_final_disp[] IS NOT INITIAL.
      et_data[] = xt_final_disp[].
    ENDIF.

  ENDMETHOD.
ENDCLASS.
