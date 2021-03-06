SET PAGESIZE 1000
COLUMN USERNAME FORMAT A15
COLUMN PROGRAM FORMAT A20
COLUMN PID FORMAT 99990

SELECT
  P.PID,
  P.SPID,
  S.USERNAME,
  S.PROGRAM
FROM
  V$PROCESS P,
  V$SESSION S
WHERE
  P.ADDR=S.PADDR
ORDER BY
  S.USERNAME,
  P.PROGRAM;

ORADEBUG SETORAPID 14
ORADEBUG UNLIMIT
ORADEBUG ORADEBUG EVENTDUMP session
ORADEBUG CLOSE_TRACE
