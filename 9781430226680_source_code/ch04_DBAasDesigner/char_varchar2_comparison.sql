-- This script can be used for testing the code and results outlined in the section called "Watch Your Comparison Semantics".
-- Melanie Caffrey - November 29, 2009


create table varchar_char_test
    (variable varchar2(50),
     fixed    char(100));


declare
    begin
       insert into varchar_char_test
       select object_name, object_name
         from all_objects;
    commit;
    end;
    /


select variable, length(variable) vlength, fixed,
                 length(fixed) flength
    from varchar_char_test
    where variable = 'ACL_ACE';


select variable, fixed from varchar_char_test
    where fixed = 'ACL_ACE';


select variable, fixed from varchar_char_test
    where variable = 'ACL_ACE;


insert into varchar_char_test values ('  ABC  ', '  ABC  ');


commit;

 
select variable, fixed from varchar_char_test
    where fixed = 'ABC';


select variable, fixed from varchar_char_test
    where fixed = '  ABC';


select variable, fixed from varchar_char_test
    where variable  = 'ACL_ACE'
      and variable  = fixed;


select variable, fixed from varchar_char_test
    where variable  = 'ACL_ACE'
      and variable  = rtrim(fixed);


select variable, fixed from varchar_char_test
    where variable  = 'ACL_ACE'
      and rpad(variable, 100, ' ')  = fixed;














