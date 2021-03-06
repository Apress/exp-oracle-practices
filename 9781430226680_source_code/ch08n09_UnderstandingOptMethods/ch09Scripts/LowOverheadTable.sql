CREATE GLOBAL TEMPORARY TABLE
  DATALOG.TS_SYSTEM_EVENT ON COMMIT DELETE ROWS AS
SELECT
  EVENT,
  TOTAL_WAITS,
  TOTAL_TIMEOUTS,
  TIME_WAITED,
  TIME_WAITED_MICRO
FROM
  V$SYSTEM_EVENT
WHERE
  0=1;

CREATE GLOBAL TEMPORARY TABLE
  DATALOG.TE_SYSTEM_EVENT ON COMMIT DELETE ROWS AS
SELECT
  EVENT,
  TOTAL_WAITS,
  TOTAL_TIMEOUTS,
  TIME_WAITED,
  TIME_WAITED_MICRO
FROM
  V$SYSTEM_EVENT
WHERE
  0=1;

CREATE GLOBAL TEMPORARY TABLE
  DATALOG.TS_OSSTAT ON COMMIT DELETE ROWS AS
SELECT
  STAT_NAME,
  VALUE
FROM
  V$OSSTAT
WHERE
  0=1;

CREATE GLOBAL TEMPORARY TABLE
  DATALOG.TE_OSSTAT ON COMMIT DELETE ROWS AS
SELECT
  STAT_NAME,
  VALUE
FROM
  V$OSSTAT
WHERE
  0=1;

CREATE GLOBAL TEMPORARY TABLE
  DATALOG.TS_SYS_TIME_MODEL ON COMMIT DELETE ROWS AS
SELECT
  STAT_NAME,
  VALUE
FROM
  V$SYS_TIME_MODEL
WHERE
  0=1;

CREATE GLOBAL TEMPORARY TABLE
  DATALOG.TE_SYS_TIME_MODEL ON COMMIT DELETE ROWS AS
SELECT
  STAT_NAME,
  VALUE
FROM
  V$SYS_TIME_MODEL
WHERE
  0=1;

CREATE GLOBAL TEMPORARY TABLE
  DATALOG.TS_SYSSTAT ON COMMIT DELETE ROWS AS
SELECT
  NAME,
  VALUE
FROM
  V$SYSSTAT
WHERE
  0=1;

CREATE GLOBAL TEMPORARY TABLE
  DATALOG.TE_SYSSTAT ON COMMIT DELETE ROWS AS
SELECT
  NAME,
  VALUE
FROM
  V$SYSSTAT
WHERE
  0=1;
