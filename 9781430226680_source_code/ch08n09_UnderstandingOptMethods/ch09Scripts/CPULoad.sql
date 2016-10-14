DECLARE
  i NUMBER := 0;
  STime DATE := SYSDATE;
BEGIN
  WHILE (SYSDATE - STime) < 0.006945 LOOP
    i := i + + 0.000001;
  End Loop;
End;
/