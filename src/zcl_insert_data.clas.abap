CLASS zcl_insert_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .

    METHODS:
      upload_sample_data.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_INSERT_DATA IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    upload_sample_data(  ).
  ENDMETHOD.


  METHOD upload_sample_data.

    DATA:
      xt_final      TYPE TABLE OF zi_bom_report,
      xt_final_disp TYPE TABLE OF zi_bom_report,
      gs_final      TYPE zi_bom_report.

    DATA: lv_date         TYPE sy-datum,
          lv_explod_matnr TYPE char40.
    lv_date = sy-datum.

    SELECT * FROM zi_bom_report( p_keydate = @lv_date )
             INTO TABLE @DATA(lt_bom).

    READ TABLE lt_bom INTO DATA(ls_bom) INDEX 1.
    ls_bom-explod_matnr = ''.
    MODIFY lt_bom FROM ls_bom TRANSPORTING explod_matnr WHERE explod_matnr NE ''.

    DATA(lt_mat_fert) = lt_bom[].
    DELETE lt_mat_fert WHERE ProductType NE 'FERT'.
    DELETE ADJACENT DUPLICATES FROM lt_mat_fert COMPARING material.
    "DELETE lt_mat_fert WHERE material NE 'FGSTMT401100235'.

    "========================================================================"
    DATA: lv_index TYPE sy-tabix.
    LOOP AT lt_mat_fert INTO DATA(ls_mat_fert).

      CLEAR: xt_final.

      DATA(lt_mat_halb) = lt_bom[].
      DELETE lt_mat_halb WHERE material NE ls_mat_fert-material.
      SORT lt_mat_halb by BILLOFMATERIALITEMNUMBER.
      APPEND LINES OF lt_mat_halb TO xt_final.

      DELETE lt_mat_halb WHERE comp_producttype NE 'HALB'.

      LOOP AT lt_mat_halb INTO DATA(ls_mat_halb).
        lv_index = sy-tabix.

        DATA(lt_mat_halb_n) = lt_bom[].
        DELETE lt_mat_halb_n WHERE material NE ls_mat_halb-billofmaterialcomponent.
        SORT lt_mat_halb_n by BILLOFMATERIALITEMNUMBER.
        APPEND LINES OF lt_mat_halb_n TO xt_final.
        DELETE lt_mat_halb_n WHERE comp_producttype NE 'HALB'.

        IF lt_mat_halb_n[] IS NOT INITIAL.
          APPEND LINES OF lt_mat_halb_n TO lt_mat_halb.
        ENDIF.
        DELETE lt_mat_halb INDEX lv_index.
      ENDLOOP.

      IF xt_final[] IS NOT INITIAL.
        READ TABLE xt_final INTO DATA(ls_final) INDEX 1.
        ls_final-explod_matnr = ls_mat_fert-material.
        MODIFY xt_final FROM ls_final TRANSPORTING explod_matnr WHERE explod_matnr eq ''.
        xt_final_disp[] = xt_final[].
        clear: xt_final.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
