break on sample_time skip 1 
col name format a30 
col sample_time format a30 

select /*+ index(ash) */ 
       sample_time, name, sql_id, p1, p2, p3, count(*) 
  from dba_hist_active_sess_history ash
 where ash.name            = 'row cache lock'
   and ash.instance_number = &inst_id
   and ash.dbid            = &dbid
   and ash.sample_time     < to_date('&end_date','YYYY-MM-DD HH24:MI:SS')
   and ash.sample_time     > to_date('&begin_date','YYYY-MM-DD HH24:MI:SS')
   and ash.snap_id   between &bsnap_id and &esnap_id 
   and ash.wait_time       = 0
 group by sample_time, name, sql_id, p1, p2, p3
 order by sample_time; 
