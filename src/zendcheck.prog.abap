*&---------------------------------------------------------------------*
*& Report ZENDCHECK
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zendcheck MESSAGE-ID zendcheck.

INCLUDE zendcheck_top.

INCLUDE zendcheck_sel.

INCLUDE zendcheck_f01.

INCLUDE zendcheck_alv.

INCLUDE zendcheck_pbopai.

INITIALIZATION.
  PERFORM frm_init.

START-OF-SELECTION.

  IF p_grp IS INITIAL.
    MESSAGE s000 WITH TEXT-001 DISPLAY LIKE 'E'."请选择检查组
    STOP.
  ENDIF.

  PERFORM frm_get_config."读取配置

  PERFORM frm_define_data."定义接受内表字段清单,填充HEAD值

  PERFORM frm_set_where."设置筛选条件

  PERFORM frm_get_data."读取错误数据

  IF gt_head IS INITIAL.
    MESSAGE s000 WITH TEXT-002 DISPLAY LIKE 'E'.
    STOP.
  ENDIF.

  CALL SCREEN 100.
