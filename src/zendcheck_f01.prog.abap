*&---------------------------------------------------------------------*
*& 包含               ZENDCHECK_F01
*&---------------------------------------------------------------------*

FORM frm_init.
  IF s_datum[] IS INITIAL.
    APPEND VALUE #( sign = 'I'
                                  option = 'EQ'
                                  low = sy-datum )
                                  TO s_datum.
  ENDIF.


  SELECT * FROM zendcheck_group
  INTO TABLE gt_group.

  DATA: lt_list TYPE  vrm_values.
  lt_list = CORRESPONDING #( gt_group
                                MAPPING key = grp
                                                  text = name ).
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_GRP'
      values = lt_list.
  IF sy-subrc EQ 0.
    MODIFY SCREEN.
  ENDIF.
ENDFORM.

FORM frm_get_config.
  SELECT * FROM zendcheck_rule
    INTO TABLE gt_rule WHERE grp = p_grp.

  SELECT * FROM zendcheck_detail
    INTO TABLE gt_detail WHERE grp = p_grp.
ENDFORM.

FORM frm_define_data.
  LOOP AT gt_rule INTO DATA(ls_rule).
    APPEND INITIAL LINE TO gt_head ASSIGNING FIELD-SYMBOL(<head>).
    MOVE-CORRESPONDING ls_rule TO <head>.
    IF ls_rule-variant IS INITIAL.
      DATA(fcat) = zwft_common=>fcat_from_name( ls_rule-tabname ).
      LOOP AT fcat ASSIGNING FIELD-SYMBOL(<fcat>).
        READ TABLE gt_detail INTO DATA(ls_detail) WITH KEY object = ls_rule-object fieldname = <fcat>-fieldname.
        IF sy-subrc NE 0.
          <fcat>-tech = 'X'.
        ELSE.
          <fcat>-col_pos = ls_detail-dzaehk.
          <fcat>-tabname = ls_rule-tabname.
          APPEND |{ <fcat>-fieldname },| TO <head>-fieldlist.
        ENDIF.
      ENDLOOP.
      DELETE fcat WHERE tech = 'X'.
      SORT fcat BY col_pos.
      LOOP AT <head>-fieldlist ASSIGNING FIELD-SYMBOL(<fieldlist>).
      ENDLOOP.
      IF sy-subrc EQ 0.
        REPLACE ',' IN <fieldlist>  WITH ''.
      ENDIF.
      zwft_common=>create_table_fcat( EXPORTING it_fcat = fcat CHANGING ct_data = <head>-data ).
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM frm_get_data.

  LOOP AT gt_head ASSIGNING FIELD-SYMBOL(<head>).
    <head>-dzaehk = sy-tabix.
    IF <head>-variant IS INITIAL.
      READ TABLE <head>-twhere INTO DATA(ls_where) WITH KEY tablename = <head>-tabname.
      CHECK sy-subrc EQ 0.
      SELECT DISTINCT (<head>-fieldlist)
        FROM (<head>-tabname)
        WHERE (ls_where-where_tab)
        INTO CORRESPONDING FIELDS OF TABLE @<head>-data->*.
    ELSE.
      CREATE DATA <head>-alv_mate TYPE  zwft_common=>s_type_metadata.
      <head>-alv_mate->* = zwft_common=>get_report_alv_mate( EXPORTING tcode = <head>-tcode
                                                                                                                 variant = <head>-variant
                                                                                            IMPORTING data =  <head>-data ).
    ENDIF.

    <head>-count = lines( <head>-data->* ).
    IF <head>-count = 0.
      <head>-icon = icon_green_light.
      <head>-text = TEXT-003."'无异常'.
    ELSE.
      <head>-icon = icon_red_light.
      <head>-text = TEXT-004."'有异常,请双击查看'.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM frm_set_where.
  LOOP AT gt_head ASSIGNING FIELD-SYMBOL(<head>)."循环每个抬头结构
    CHECK <head>-variant IS INITIAL.
    APPEND INITIAL LINE TO <head>-tranges ASSIGNING FIELD-SYMBOL(<range>).
    <range>-tablename = <head>-tabname.
    LOOP AT gt_detail INTO DATA(l_detail)
      WHERE object = <head>-object
      AND ( ( sign <> '' AND opt <> '' ) OR ( low = 'DATE' ) )
      GROUP BY ( fieldname = l_detail-fieldname )
      INTO DATA(group_detail)."分组循环字段清单中有筛选条件的配置项
      APPEND INITIAL LINE TO <range>-frange_t ASSIGNING FIELD-SYMBOL(<frange>).
      <frange>-fieldname = group_detail-fieldname.
      LOOP AT GROUP group_detail INTO DATA(line_group_detail).
        IF line_group_detail-low = 'DATE'.
          <frange>-selopt_t = CORRESPONDING #( s_datum[] ).
          EXIT.
        ENDIF.
        APPEND INITIAL LINE TO <frange>-selopt_t ASSIGNING FIELD-SYMBOL(<selopt>).
        <selopt>-sign = line_group_detail-sign.
        <selopt>-option = line_group_detail-opt.
        PERFORM frm_set_default USING line_group_detail-low CHANGING <selopt>-low.
        PERFORM frm_set_default USING line_group_detail-high CHANGING <selopt>-high.
      ENDLOOP.
    ENDLOOP.
    <head>-twhere = zwft_common=>get_where_from_ranges( <head>-tranges ).
  ENDLOOP.
ENDFORM.
FORM frm_set_default USING source CHANGING value.

  value = COND #(  WHEN source = 'DAY' THEN sy-datum
                              WHEN source = 'YEAR' THEN sy-datum+0(4)
                              WHEN source = 'MOUTH' THEN sy-datum+4(2)
                              ELSE source
                            ).
ENDFORM.

FORM frm_call_transtion.
  DATA:lt_ranges TYPE TABLE OF rsparams.
  DATA:lt_rsparams TYPE TABLE OF rsparams.
  DATA:l_dynnr TYPE sy-dynnr.
  READ TABLE gt_head INTO gs_head INDEX head_index.
  CHECK sy-subrc EQ 0.
  CHECK gs_head-tcode IS NOT INITIAL.

  SELECT SINGLE * FROM tstc
  WHERE tcode = @gs_head-tcode
  INTO @DATA(l_tstc).
  CHECK sy-subrc EQ 0.

  IF gs_head-variant IS NOT INITIAL.
    SUBMIT (l_tstc-pgmna)  USING SELECTION-SET gs_head-variant AND RETURN.
    RETURN.
  ENDIF.
  l_dynnr = l_tstc-dypno.
  zwft_common=>get_dynnr_field( EXPORTING program = l_tstc-pgmna
                                                                                       dynnr = l_dynnr
                                                                 IMPORTING screen_sscr = DATA(lt_rsscr1)
                                                                                      global_sscr = DATA(lt_rsscr) ).
  APPEND LINES OF lt_rsscr1 TO lt_rsscr.
  SORT lt_rsscr BY name.
  DELETE ADJACENT DUPLICATES FROM lt_rsscr.

  LOOP AT gt_detail INTO DATA(l_detail)
                                WHERE object = gs_head-object
                                AND option_name <> ''
                                GROUP BY ( fieldname = l_detail-fieldname
                                                    option_name = l_detail-option_name )
                                INTO DATA(group_detail).
    READ TABLE lt_rsscr INTO DATA(ls_rsscr) WITH KEY name = group_detail-option_name.
    CHECK sy-subrc EQ 0.
    LOOP AT gs_head-data->* ASSIGNING FIELD-SYMBOL(<data>).
      ASSIGN COMPONENT group_detail-fieldname OF STRUCTURE <data> TO FIELD-SYMBOL(<fs_value>).
      APPEND INITIAL LINE TO lt_ranges ASSIGNING FIELD-SYMBOL(<ranges>).
      <ranges>-selname  = group_detail-option_name.
      <ranges>-kind  = ls_rsscr-kind.
      <ranges>-sign = 'I'.
      <ranges>-option = 'EQ'.
      <ranges>-low = <fs_value>.
    ENDLOOP.
  ENDLOOP.
  IF lt_ranges IS NOT INITIAL.
    SORT lt_ranges.
    DELETE ADJACENT DUPLICATES FROM lt_ranges.
    SUBMIT (l_tstc-pgmna)  WITH SELECTION-TABLE lt_ranges AND RETURN.
  ELSE.
    DATA rc TYPE sy-subrc.
    CALL FUNCTION 'RS_VARIANT_EXISTS'
      EXPORTING
        report              = l_tstc-pgmna
        variant             = 'ERROR'
      IMPORTING
        r_c                 = rc
      EXCEPTIONS
        not_authorized      = 1
        no_report           = 2
        report_not_existent = 3
        report_not_supplied = 4
        OTHERS              = 5.

    IF rc EQ 0 AND sy-subrc EQ 0.
      SUBMIT (l_tstc-pgmna)  USING SELECTION-SET 'ERROR' AND RETURN.
    ELSE.
      SUBMIT (l_tstc-pgmna) AND RETURN.
    ENDIF.
  ENDIF.
ENDFORM.
