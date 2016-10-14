-- This script can be used for testing the code and results outlined in the section called "Choose Your Datatypes Carefully".
-- Melanie Caffrey - November 22, 2009


create table num_string_test
    (num_string varchar2(10),
     num_num    number);


declare
    begin
    for i in 1 .. 10046
    loop
       insert into num_string_test
       values (to_char(i), i);
    end loop;
    commit;
    end;
 /


select count(*) from num_string_test;


create index nst_num_str_idx on num_string_test(num_string);


create index nst_num_num_idx on num_string_test(num_num);


exec dbms_stats.gather_table_stats( user, 'NUM_STRING_TEST',
   method_opt => 'for all indexed columns', estimate_percent => 100 );


-- The below methodology of setting autotrace can generally only be used with SQL*Plus.

 
set autot trace exp


select *
      from num_string_test
     where num_string between 2 and 10042;


select *
      from num_string_test
     where num_num between 2 and 10042;


select *
      from num_string_test
     where num_string between 2 and 42;


select *
      from num_string_test
     where num_num between 2 and 42;













