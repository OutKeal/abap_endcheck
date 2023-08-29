*&---------------------------------------------------------------------*
*& 包含               ZENDCHECK_PBOPAI
*&---------------------------------------------------------------------*

MODULE status_0100 OUTPUT.
  READ TABLE gt_group INTO DATA(ls_group) WITH KEY grp = p_grp.
  DATA(title) = |{ ls_group-grp }-{ ls_group-name }|.
  SET PF-STATUS '100'.
  SET TITLEBAR '100' WITH title.
ENDMODULE.

MODULE create_object_0100 OUTPUT.
  PERFORM frm_set_head_falv.
  PERFORM frm_set_item_falv.
ENDMODULE.

MODULE exit_command INPUT.
  LEAVE TO SCREEN 0.
ENDMODULE.
MODULE user_command_0100 INPUT.
*  PERFORM frm_user_command_100.
ENDMODULE.
