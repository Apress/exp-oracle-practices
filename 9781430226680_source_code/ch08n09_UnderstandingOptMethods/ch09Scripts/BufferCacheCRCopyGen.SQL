/* CREATE TABLE T9 (C1 VARCHAR2(4000)); */
/* Start 100 sessions all executing this script simultaneously */
DECLARE
  i NUMBER := 0;
BEGIN
  WHILE i<100 LOOP
    INSERT INTO
      T9
    VALUES
      (LPAD('A',4000,'B'));

    i := i + 1;
  END LOOP;
END;
/

SELECT
  *
FROM
  T9;

EXEC DBMS_LOCK.SLEEP(180);

COMMIT;
