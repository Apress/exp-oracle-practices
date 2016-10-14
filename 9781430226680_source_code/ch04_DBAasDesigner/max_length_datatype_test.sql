-- This script can be used for testing the code and results outlined in the section called "When Bigger Is Not Better".
-- Melanie Caffrey - November 29, 2009


create table example01 (col1 varchar2(4000), col2 varchar2(4000));


create index idx1_example01 on example01(col1);


create index idx2_example01 on example01(col1,col2);


show parameter db_block_size;














