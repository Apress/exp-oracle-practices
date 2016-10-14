SELECT
  NAME,
  VALUE
FROM
  V$SYSSTAT
WHERE 
  NAME IN ('physical reads', 'physical writes', 'physical read bytes',
           'physical write bytes', 'redo size', 'redo write time', 'consistent changes', 
           'user I/O wait time', 'user commits', 'user rollbacks',
           'sorts (memory)', 'sorts (disk)', 'workarea executions - optimal',
           'workarea executions - onepass', 'workarea executions - multipass');


SELECT
  FILE#,
  PHYRDS,
  PHYWRTS,
  PHYBLKRD,
  PHYBLKWRT,
  SINGLEBLKRDS,
  READTIM,
  WRITETIM,
  SINGLEBLKRDTIM,
  AVGIOTIM,
  LSTIOTIM,
  MINIOTIM,
  MAXIORTM,
  MAXIOWTM
FROM
  V$FILESTAT
WHERE
  FILE# IN (6,7);


SELECT /*+ ORDERED */
  DO.OWNER,
  DO.OBJECT_NAME,
  DO.OBJECT_TYPE,
  SS.VALUE
FROM
  V$DATAFILE D,
  V$SEGMENT_STATISTICS SS,
  DBA_OBJECTS DO
WHERE
  D.FILE#=7
  AND D.TS#=SS.TS#
  AND SS.STATISTIC_NAME='physical reads'
  AND SS.VALUE>1000000
  AND SS.OBJ#=DO.DATA_OBJECT_ID
  AND SS.DATAOBJ#=DO.DATA_OBJECT_ID;


SELECT
  DO.OBJECT_NAME,
  SS.STATISTIC_NAME,
  SS.VALUE
FROM
  DBA_OBJECTS DO,
  V$SEGSTAT SS
WHERE
  DO.OWNER='TESTUSER'
  AND DO.OBJECT_NAME='T1'
  AND DO.OBJECT_ID=SS.OBJ#
  AND DO.DATA_OBJECT_ID=SS.DATAOBJ#
ORDER BY
  DO.OBJECT_NAME,
  SS.STATISTIC_NAME;


SELECT /*+ ORDERED */
  TU.USERNAME,
  S.SID,
  S.SERIAL#,
  S.SQL_ID,
  S.SQL_ADDRESS,
  TU.SEGTYPE,
  TU.EXTENTS,
  TU.BLOCKS,
  SQL.SQL_TEXT
FROM
  V$TEMPSEG_USAGE TU,
  V$SESSION S,
  V$SQL SQL
WHERE
  TU.SESSION_ADDR=S.SADDR
  AND TU.SESSION_NUM=S.SERIAL#
  AND S.SQL_ID=SQL.SQL_ID
  AND S.SQL_ADDRESS=SQL.ADDRESS;


SELECT
  FILE#,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,1,SINGLEBLKRDS,0)) MILLI1,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,2,SINGLEBLKRDS,0)) MILLI2,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,4,SINGLEBLKRDS,0)) MILLI4,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,8,SINGLEBLKRDS,0)) MILLI8,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,16,SINGLEBLKRDS,0)) MILLI16,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,32,SINGLEBLKRDS,0)) MILLI32,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,64,SINGLEBLKRDS,0)) MILLI64,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,128,SINGLEBLKRDS,0)) MILLI128,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,256,SINGLEBLKRDS,0)) MILLI256,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,512,SINGLEBLKRDS,0)) MILLI512,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,1024,SINGLEBLKRDS,0)) MILLI1024,
  MAX(DECODE(SINGLEBLKRDTIM_MILLI,2048,SINGLEBLKRDS,0)) MILLI2048
FROM
  V$FILE_HISTOGRAM
GROUP BY
  FILE#
ORDER BY
  FILE#;
