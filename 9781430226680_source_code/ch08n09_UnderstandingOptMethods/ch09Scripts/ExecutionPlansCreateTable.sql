CREATE TABLE T3 AS
SELECT
  ROWNUM C1,
  LPAD('A',100,'A') C2
FROM
  DUAL
CONNECT BY
  LEVEL<=10000;

CREATE TABLE T4 AS
SELECT
  ROWNUM C1,
  LPAD('A',100,'A') C2
FROM
  DUAL
CONNECT BY
  LEVEL<=10000;

CREATE INDEX IND_T4 ON T4(C1);

EXEC DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER,TABNAME=>'T3',CASCADE=>TRUE)
EXEC DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER,TABNAME=>'T4',CASCADE=>TRUE)
