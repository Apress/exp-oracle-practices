rem
rem	Script:		10053OptimizerTrace.sql
rem	Author:		Randolf Geist
rem	Dated:		October 2009
rem	Purpose:	Demonstrate most features of an 10053 optimizer debug trace file
rem
rem	Versions tested
rem		11.1.0.7
rem		10.2.0.4
rem
rem This script uses an anonymous PL/SQL block
rem because SQL*Plus doesn't support bind variables
rem of TIMESTAMP type

alter session set nls_language = 'AMERICAN';

set echo on linesize 130 pagesize 100 trimspool on

spool oaktable_10053_optimizer_trace_testcase.log

drop table t_opt_10053_trace1 purge;
drop table t_opt_10053_trace2 purge;

create table t_opt_10053_trace1
(
id constraint pk_opt_10053_trace1 primary key,
val1,
padding
)
partition by range (val1)
(
partition p_1 values less than (100),
partition p_2 values less than (200)
)
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects
	where	rownum <= 3000
)
select
        *
from
        (
select
	/*+ ordered use_nl(v2) */
	rownum               as id,
	mod(rownum, 200)     as val1,
	rpad('x',100)        as padding
from
	generator	v1,
	generator	v2
where
	rownum <= 10000
        )
order by
        val1;
;

create index idx_opt_10053_trace1 on t_opt_10053_trace1(val1);

exec dbms_stats.gather_table_stats(null, 't_opt_10053_trace1')

create table t_opt_10053_trace2
(
id constraint pk_opt_10053_trace2 primary key,
name,
timestamp_val,
nvarchar_val
)
as
select
         id
       , 'VAL' || mod(id, 10) as name
       , to_timestamp('01-01-2005', 'DD-MM-YYYY') as timestamp_val
       , cast(N'NVARCHAR' as nvarchar2(20)) as nvarchar_val
from
        (
        select
                level as id
        from
                dual
        connect by
                level <= 50
        );

-- create index idx_opt_10053_trace2 on t_opt_10053_trace2(name, timestamp_val);

-- Create a suitable index
-- that is a candidate for
-- dynamic sampling of the predicates applied
-- to table T_OPT_10053_TRACE2
create index idx_opt_10053_trace2 on t_opt_10053_trace2(timestamp_val, name);

-- Note that dynamic sampling
-- may overwrite existing index blocks statistics:
-- If the table blocks are taken from dynamic sampling
-- the index statistics for all indexes on this table
-- are also taken from the segment statistics
exec dbms_stats.set_index_stats(null, 'idx_opt_10053_trace2', numlblks=>10000)

-- Odd: Oracle does not perform the additional
-- index range scan when adding a second index
--
-- create index idx2_opt_10053_trace2 on t_opt_10053_trace2(name);

alter session set tracefile_identifier = '10053_sample_query';

alter session set events '10053 trace name context forever, level 1';

-- The following query can be used
-- to reproduce most of the aspects
-- mentioned in the "Generating 10053 Cost-Based Optimizer Traces"
-- section of the book "Oak Table: Expert Oracle Practices",
-- chapter "Choosing a Performance Optimization Method"
declare
  string_val varchar2(50) := 'VAL3';
  ts_val timestamp := to_timestamp('01-01-2005', 'DD-MM-YYYY');
  -- NCHAR/NVARCHAR also show an odd behaviour
  -- in 10053 trace file
  -- The VALUE is not shown/blank in the "Peeked Binds" section
  -- but at the end of the trace in the PLAN_TABLE section
  -- the "Peeked Binds" sub-section shows the value
  -- nc_val nvarchar2(20) := 'NVARCHAR';
begin
-- Note that the correctly recognized DYNAMIC_SAMPLING hint
-- will show up in the "Dumping Hints" section at the end of the
-- 10053 trace file as "ERROR" (ERR=5) in both version 10.2.0.4 and 11.1.0.7 Win32
-- If you replace the correct DYNAMIC_SAMPLING hint with the
-- following incorrect one
-- DYNAMIC_SAMPLING()
-- the OPT_PARAM hint will also be ignored in 10.2.0.4 and 11.1.0.7 Win32
-- and the "Dumping Hints" section will be missing from the trace file
  for rec in (
  select  /*+
              dynamic_sampling(4)
              opt_param('optimizer_index_caching', 75)
              */
          t1.*
  from
          (
          select
                  *
          from
                  t_opt_10053_trace1
          ) t1
        , t_opt_10053_trace2 t2
  where
          t2.name = string_val
  and     t2.timestamp_val = ts_val
  -- and     t2.nvarchar_val = nc_val
  and     t1.val1 = t2.id
  ) loop
    null;
  end loop;
end;
/

alter session set events '10053 trace name context off';

spool off

set doc off
doc
See comments at the top of the script and inline for explanations
#
