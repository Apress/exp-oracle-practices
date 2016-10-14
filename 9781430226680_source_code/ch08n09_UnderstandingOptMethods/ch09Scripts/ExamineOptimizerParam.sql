SELECT
  CHILD_NUMBER CN,
  SUBSTR(NAME,25) NAME,
  VALUE,
  ISDEFAULT DEF
FROM
  V$SQL_OPTIMIZER_ENV
WHERE
  SQL_ID='f6rs5tka838kp'
  AND CHILD_NUMBER=3
ORDER BY
  NAME;


ALTER SESSION SET TRACEFILE_IDENTIFIER = 'sql_hard_parse_plans';
ALTER SESSION SET EVENTS '10132 TRACE NAME CONTEXT FOREVER, LEVEL 1';

VARIABLE N1 NUMBER
VARIABLE N2 NUMBER

EXEC :N1 := 1
EXEC :N2 := 100

SELECT
  T3.C1, T4.C2
FROM
  T3, T4
WHERE
  T3.C1 BETWEEN :N1 AND :N2
  AND T3.C1=T4.C1;

ALTER SESSION SET EVENTS '10132 TRACE NAME CONTEXT OFF';
