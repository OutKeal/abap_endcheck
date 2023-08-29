*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZENDCHECK_DETAIL................................*
DATA:  BEGIN OF STATUS_ZENDCHECK_DETAIL              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZENDCHECK_DETAIL              .
CONTROLS: TCTRL_ZENDCHECK_DETAIL
            TYPE TABLEVIEW USING SCREEN '0003'.
*...processing: ZENDCHECK_GROUP.................................*
DATA:  BEGIN OF STATUS_ZENDCHECK_GROUP               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZENDCHECK_GROUP               .
CONTROLS: TCTRL_ZENDCHECK_GROUP
            TYPE TABLEVIEW USING SCREEN '0001'.
*...processing: ZENDCHECK_RULE..................................*
DATA:  BEGIN OF STATUS_ZENDCHECK_RULE                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZENDCHECK_RULE                .
CONTROLS: TCTRL_ZENDCHECK_RULE
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *ZENDCHECK_DETAIL              .
TABLES: *ZENDCHECK_GROUP               .
TABLES: *ZENDCHECK_RULE                .
TABLES: ZENDCHECK_DETAIL               .
TABLES: ZENDCHECK_GROUP                .
TABLES: ZENDCHECK_RULE                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
