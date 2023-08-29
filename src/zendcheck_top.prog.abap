*&---------------------------------------------------------------------*
*& 包含               ZENDCHECK_TOP
*&---------------------------------------------------------------------*
DATA gt_group TYPE TABLE OF zendcheck_group.
DATA gt_rule TYPE TABLE OF zendcheck_rule.
DATA gt_detail TYPE TABLE OF zendcheck_detail.

TYPES:BEGIN OF ty_head ,
        icon        TYPE icon_d,
        text        TYPE text,
        dzaehk      TYPE dzaehk,
        object      LIKE zendcheck_rule-object,
        object_name LIKE zendcheck_rule-object_name,
        tabname     TYPE tabname,
        tcode       TYPE tcode,
        count       TYPE int4,
        data        TYPE REF TO data,
        fieldlist   TYPE fieldname_tab,
        tranges     TYPE rsds_trange,
        twhere      TYPE rsds_twhere,
      END OF ty_head.

DATA gt_head TYPE TABLE OF ty_head.
DATA gs_head TYPE  ty_head.


DATA:falv_up_100    TYPE REF TO zwft_falv,
     falv_down_100  TYPE REF TO zwft_falv,
     g_splitter_100 TYPE REF TO cl_gui_splitter_container.
DATA:head_index TYPE sy-index VALUE 1.
