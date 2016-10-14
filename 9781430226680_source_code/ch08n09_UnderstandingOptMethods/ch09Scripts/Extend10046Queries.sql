ALTER SYSTEM FLUSH BUFFER_CACHE;
ALTER SYSTEM FLUSH BUFFER_CACHE;
SET ARRAYSIZE 15
SET AUTOTRACE TRACEONLY STATISTICS

VARIABLE N1 NUMBER
VARIABLE N2 NUMBER

EXEC :N1 := 1
EXEC :N2 := 2

EXEC DBMS_SESSION.SESSION_TRACE_ENABLE(WAITS=>TRUE,BINDS=>TRUE, PLAN_STAT=>'ALL_EXECUTIONS')

SELECT
  T3.C1, T4.C2
FROM
  T3, T4
WHERE
  T3.C1 BETWEEN :N1 AND :N2
  AND T3.C1=T4.C1; 

EXEC :N2 := 10000
SET ARRAYSIZE 100

SELECT
  T3.C1, T4.C2
FROM
  T3, T4
WHERE
  T3.C1 BETWEEN :N1 AND :N2
  AND T3.C1=T4.C1; 

SELECT SYSDATE FROM DUAL;

EXEC DBMS_SESSION.SESSION_TRACE_DISABLE;
