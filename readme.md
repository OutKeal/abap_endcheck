# 概述

SAP日常运维中,需要检查各种接口的错误,或者某些其它异常.

这里提供一个公共页面可以检查各类异常的条目,并可以支持跳转到对应的处理程序.

功能设计如下:

```mermaid
graph LR
定义检查组-->定义检查项目-->定义检查项目的查询条件-->定义检查项目的跳转
```

# 操作页面简介

事务码/程序 ZENDCHECK

<img src="https://gitee.com/outlookfox/blog-pic/raw/master/Pic/image-20230829094806802.png" alt="image-20230829094806802" style="zoom:33%;" />

选择检查组,设定关键日期.

关键日期详见配置教程中```DATE```的用法.

<img src="https://gitee.com/outlookfox/blog-pic/raw/master/Pic/image-20230829095008749.png" alt="image-20230829095008749" style="zoom:33%;" />

抬头行显示配置过程和异常的条目数.

双击抬头行子表内显示符合异常条件的数据.

单机条目数列,触发按跳转条件跳转到指定目标程序.

# 配置教程

配置视图簇 事务SM34->ZENDCHECK

## 定义检查组

定义一个检查组并命名.

例如这里定义检查组MM检查.

<img src="https://gitee.com/outlookfox/blog-pic/raw/master/Pic/image-20230829092519837.png" alt="image-20230829092519837" style="zoom: 33%;" />

## 为检查组定义检查项目

<img src="https://gitee.com/outlookfox/blog-pic/raw/master/Pic/image-20230829092901118.png" alt="image-20230829092901118" style="zoom:33%;" />

定义检查项目的编码,名称,要检查的表名,跳转的事务代码.

这里以IDOC_IN(入站IDOC)检查为例说明:

-   定义检查项目IDOC_IN,描述为入站IDOC
-   检查表为EDIDC,IDOC的控制抬头表
-   跳转事务为WE02,IDOC查看的标准事务.

## 为检查项目定义检查字段及条件

<img src="https://gitee.com/outlookfox/blog-pic/raw/master/Pic/image-20230829093323797.png" alt="image-20230829093323797" style="zoom:33%;" />

-   字段名
    -   需要返回显示或者作为跳转条件的字段名称
    -   可以配置多行,只显示为一列,主要来区分查询条件
    -   示例:此处配置返回EDIDC的IDOC编号,方向,状态,消息类型,基本类型,创建日期
-   包含/选项/选择LOW/选择HIGH.
    -   参考选择屏幕或者SE16N的RANGE结构,实现对检查表的查询条件
    -   一般配置为异常错误数据的查询条件
    -   特殊配置选择LOW为```DATE```,则代表使用程序选择屏幕的范围框选目标表.
    -   示例:此处配置条件为方向为2(代表入站),状态为64(未处理)或者51(错误),创建日期配置DATE,采用动态的日期筛选条件.
-   跳转条件
    -   配置目标选择条件的名称,一般用SELECT-OPTIONS,将本列的值日通过I EQ LOW的形式传入目标程序的选择条件.
    -   示例:WE02选择屏幕IDOC号的屏幕字段为DOCNUM,此处配置将DOCNUM列的值,以I EQ LOW的方式传入目标程序WE02.
-   特殊跳转条件
    -   可以不配置跳转条件,为指定事务创建变式```ERROR```,跳转时自动调用此变式.



# 程序说明

```mermaid
graph LR
获取配置-->定义数据接受结构,定义字段列表-->定义选择条件-->读取数据-->ALV显示
```

## 获取配置

```ABAP
FORM frm_get_config.
  SELECT * FROM zendcheck_rule
    INTO TABLE gt_rule WHERE grp = p_grp.

  SELECT * FROM zendcheck_detail
    INTO TABLE gt_detail WHERE grp = p_grp.
ENDFORM.
```

## 定义数据接受结构,定义字段列表

```ABAP
FORM frm_define_data.
  LOOP AT gt_rule INTO DATA(ls_rule).
    APPEND INITIAL LINE TO gt_head ASSIGNING FIELD-SYMBOL(<head>)."初始化HEAD行
    DATA(fcat) = zwft_common=>fcat_from_name( ls_rule-tabname )."获取检查表名的字段清单
    LOOP AT fcat ASSIGNING FIELD-SYMBOL(<fcat>).
      READ TABLE gt_detail INTO DATA(ls_detail) WITH KEY object = ls_rule-object fieldname = <fcat>-fieldname.
      IF sy-subrc NE 0."非配置字段则隐藏
        <fcat>-tech = 'X'.
      ELSE.
        <fcat>-col_pos = ls_detail-dzaehk.
        <fcat>-tabname = ls_rule-tabname.
        APPEND |{ <fcat>-fieldname },| TO <head>-fieldlist."拼接需要查询的字段清单,逗号分隔
      ENDIF.
    ENDLOOP.
    DELETE fcat WHERE tech = 'X'."删除隐藏字段
    SORT fcat BY col_pos."排序隐藏字段
    LOOP AT <head>-fieldlist ASSIGNING FIELD-SYMBOL(<fieldlist>).
    ENDLOOP.
    IF sy-subrc EQ 0.
      REPLACE ',' IN <fieldlist>  WITH ''."去除最后一个字段清单行后面的逗号,SQL需要
    ENDIF.
    MOVE-CORRESPONDING ls_rule TO <head>."
    zwft_common=>create_table_fcat( EXPORTING it_fcat = fcat CHANGING ct_data = <head>-data )."用修改过的字段清单生成返回的动态数据表
  ENDLOOP.
ENDFORM.
```

## 定义选择条件

```ABAP
FORM frm_set_where.
  LOOP AT gt_head ASSIGNING FIELD-SYMBOL(<head>)."循环每个抬头结构
    APPEND INITIAL LINE TO <head>-tranges ASSIGNING FIELD-SYMBOL(<range>).
    <range>-tablename = <head>-tabname.
    LOOP AT gt_detail INTO DATA(l_detail)
      WHERE object = <head>-object
      AND ( ( sign <> '' AND opt <> '' ) OR ( low = 'DATE' ) )
      GROUP BY ( fieldname = l_detail-fieldname )
      INTO DATA(group_detail)."分组循环字段清单中有筛选条件的配置项
      APPEND INITIAL LINE TO <range>-frange_t ASSIGNING FIELD-SYMBOL(<frange>)."初始化条件RANGE
      <frange>-fieldname = group_detail-fieldname.
      LOOP AT GROUP group_detail INTO DATA(line_group_detail).
        IF line_group_detail-low = 'DATE'."日期特殊处理,配置为DATE则使用选择屏幕上的日期条件
          <frange>-selopt_t = CORRESPONDING #( s_datum[] ).
          EXIT.
        ENDIF.
        APPEND INITIAL LINE TO <frange>-selopt_t ASSIGNING FIELD-SYMBOL(<selopt>)."初始化内部选择条件,将配置的选择条件填充到RANGE中.
        <selopt>-sign = line_group_detail-sign.
        <selopt>-option = line_group_detail-opt.
        PERFORM frm_set_default USING line_group_detail-low CHANGING <selopt>-low.
        PERFORM frm_set_default USING line_group_detail-high CHANGING <selopt>-high.
      ENDLOOP.
    ENDLOOP.
    IF lines( <head>-tranges ) > 0."将选择条件RANGES转换为SQL.
      TRY.
          CALL FUNCTION 'FREE_SELECTIONS_RANGE_2_WHERE'
            EXPORTING
              field_ranges  = <head>-tranges
            IMPORTING
              where_clauses = <head>-twhere.
        CATCH cx_root INTO DATA(lx_fm_error).
      ENDTRY.
    ENDIF.
  ENDLOOP.
ENDFORM.
```

## 获取数据

```ABAP
FORM frm_get_data.
  LOOP AT gt_head ASSIGNING FIELD-SYMBOL(<head>).
    <head>-dzaehk = sy-tabix.
    READ TABLE <head>-twhere INTO DATA(ls_where) WITH KEY tablename = <head>-tabname."读取选择条件WHERE
    CHECK sy-subrc EQ 0.
    SELECT DISTINCT (<head>-fieldlist)
      FROM (<head>-tabname)
      WHERE (ls_where-where_tab)
      INTO CORRESPONDING FIELDS OF TABLE @<head>-data->*."动态SQL获取数据
    <head>-count = lines( <head>-data->* )."条目数等于获取的行数
    IF <head>-count = 0."初始化状态图标和文本
      <head>-icon = icon_green_light.
      <head>-text = '无异常'.
    ELSE.
      <head>-icon = icon_red_light.
      <head>-text = '有异常,请双击查看'.
    ENDIF.
  ENDLOOP.
ENDFORM.
```

## ALV显示

这里调用FALV显示结果,双击抬头行则重新加载对应的项目数据.

```ABAP
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

  PERFORM frm_set_layout USING falv_down_100.
  PERFORM frm_set_fieldcatalog USING falv_down_100.
  falv_down_100->display( ).

ENDFORM.
```



