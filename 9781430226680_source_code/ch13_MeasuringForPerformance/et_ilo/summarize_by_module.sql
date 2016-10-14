column ilo_module format a30
column count format 99999
set pages 50000
set lines 200

select ilo_module, count(ilo_module) count, 
       avg(elapsed_time) average, variance(elapsed_time) variance,
       round(variance(elapsed_time)/avg(elapsed_time),3) vmr,
       round(stddev(elapsed_time)/avg(elapsed_time),3) cov,
       avg(elapsed_cputime) cpu_average,
       variance(elapsed_cputime) cpu_variance,
       round(variance(elapsed_cputime)/avg(elapsed_time),3) cpu_vmr,
       round(stddev(elapsed_cputime)/avg(elapsed_time),3) cpu_cov
  from elapsed_time
 group by ilo_module
 order by vmr desc ;
