*&---------------------------------------------------------------------*
*& 包含               ZENDCHECK_TRE
*&---------------------------------------------------------------------*

FORM  frm_set_head_falv."创建屏幕框体
  IF g_splitter_100 IS INITIAL.
    g_splitter_100 = NEW cl_gui_splitter_container(
    parent = NEW cl_gui_docking_container( extension = '3000' )
    rows = 2 columns = 1 ).

    falv_up_100 = zwft_falv=>create( EXPORTING i_popup = ''
      i_handle = '1'
      i_parent = g_splitter_100->get_container( row = 1 column = 1 )
    CHANGING ct_table = gt_head[] ).

    PERFORM frm_set_layout USING falv_up_100.
    PERFORM frm_set_fieldcatalog USING falv_up_100.
    falv_up_100->display( ).
  ELSE.
    falv_up_100->soft_refresh( ).
  ENDIF.
ENDFORM.

FORM frm_set_item_falv.

  READ TABLE gt_head INTO DATA(ls_head) INDEX head_index.
  CHECK sy-subrc EQ 0.
  IF gs_head = ls_head.
    RETURN.
  ELSE.
    gs_head = ls_head.
  ENDIF.

  IF falv_down_100 IS BOUND.
    falv_down_100->free( ).
    FREE falv_down_100.
  ENDIF.

  falv_down_100 = zwft_falv=>create( EXPORTING i_popup = ''
    i_handle = '2'
    i_parent = g_splitter_100->get_container( row = 2 column = 1 )
  CHANGING ct_table = gs_head-data->* ).

  IF gs_head-alv_mate IS NOT INITIAL.
    ASSIGN COMPONENT 'T_FCAT' OF STRUCTURE gs_head-alv_mate->* TO FIELD-SYMBOL(<fcat>).
    IF sy-subrc EQ 0.
      falv_down_100->fcat = <fcat>.
    ENDIF.
    ASSIGN COMPONENT 'S_LAYOUT' OF STRUCTURE gs_head-alv_mate->* TO FIELD-SYMBOL(<layout>).
    IF sy-subrc EQ 0.
      falv_down_100->lvc_layout = <layout>.
    ENDIF.
  ELSE.
    PERFORM frm_set_layout USING falv_down_100.
    PERFORM frm_set_fieldcatalog USING falv_down_100.
  ENDIF.


  falv_down_100->display( ).

ENDFORM.



FORM frm_set_layout USING c_falv TYPE REF TO zwft_falv.
  CASE c_falv.
    WHEN falv_up_100.
    WHEN falv_down_100.
  ENDCASE.
  c_falv->layout->set_zebra( 'A' ) .
  c_falv->layout->set_cwidth_opt( 'A' ) .
  c_falv->layout->set_zebra( 'X' ).
ENDFORM.

FORM frm_set_fieldcatalog USING c_falv TYPE REF TO zwft_falv.
  CASE c_falv.
    WHEN falv_up_100.
      LOOP AT c_falv->fcat ASSIGNING FIELD-SYMBOL(<ls_fcat>).
        CASE <ls_fcat>-fieldname.
          WHEN 'ICON' .
            <ls_fcat>-scrtext_s = <ls_fcat>-scrtext_m =
            <ls_fcat>-scrtext_l = <ls_fcat>-reptext = TEXT-005."'状态'.
          WHEN 'TEXT'.
            <ls_fcat>-scrtext_s = <ls_fcat>-scrtext_m =
            <ls_fcat>-scrtext_l = <ls_fcat>-reptext = TEXT-006."''状态文本'.
          WHEN 'DZAEHK'.
            <ls_fcat>-scrtext_s = <ls_fcat>-scrtext_m =
            <ls_fcat>-scrtext_l = <ls_fcat>-reptext = TEXT-007."''序号'.
          WHEN 'COUNT'.
            <ls_fcat>-scrtext_s = <ls_fcat>-scrtext_m =
            <ls_fcat>-scrtext_l = <ls_fcat>-reptext = TEXT-008."''异常数量'.
            <ls_fcat>-hotspot = 'X'.
        ENDCASE.
      ENDLOOP.
      DELETE c_falv->fcat WHERE tech = 'X'.
    WHEN falv_down_100.
  ENDCASE.
ENDFORM.

FORM frm_double_click  USING c_falv TYPE REF TO zwft_falv
      e_row  TYPE lvc_s_row
      e_column TYPE lvc_s_col
      es_row_no TYPE lvc_s_roid.
  CASE c_falv.
    WHEN falv_up_100.
      head_index = e_row-index.
      CALL METHOD cl_gui_cfw=>update_view
        EXPORTING
          called_by_system = 'X'.
      CALL METHOD cl_gui_cfw=>set_new_ok_code
        EXPORTING
          new_code = 'ENTR'.
    WHEN falv_down_100.
  ENDCASE.
ENDFORM.


FORM frm_hotspot_click USING c_falv TYPE REF TO zwft_falv
      e_row_id TYPE lvc_s_row
      e_column_id TYPE lvc_s_col
      es_row_no TYPE lvc_s_roid .
  READ TABLE gt_head ASSIGNING FIELD-SYMBOL(<alv_line>) INDEX e_row_id-index.
  ASSIGN COMPONENT e_column_id-fieldname OF STRUCTURE <alv_line> TO FIELD-SYMBOL(<fs_value>).
  CHECK sy-subrc EQ 0.
  CASE e_column_id-fieldname.
    WHEN 'COUNT'.
      CHECK <fs_value> IS NOT INITIAL.
      head_index = e_row_id-index.
      PERFORM frm_call_transtion.
  ENDCASE.
ENDFORM.
