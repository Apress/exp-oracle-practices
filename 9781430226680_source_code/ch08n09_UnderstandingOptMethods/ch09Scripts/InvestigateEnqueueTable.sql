CREATE TABLE T5(C1 NUMBER(10) PRIMARY KEY);
 
INSERT INTO T5 VALUES(1);
INSERT INTO T5 VALUES(2);
INSERT INTO T5 VALUES(3);
INSERT INTO T5 VALUES(4);
COMMIT;
 
CREATE TABLE T6(
  C1 NUMBER(10) PRIMARY KEY,
  C2 NUMBER(10),
  CONSTRAINT FK_T5_C1 FOREIGN KEY(C2) REFERENCES T5(C1) ENABLE);
 
INSERT INTO T6 VALUES(1,1);
INSERT INTO T6 VALUES(2,2);
INSERT INTO T6 VALUES(3,3);
INSERT INTO T6 VALUES(4,4);
COMMIT;
