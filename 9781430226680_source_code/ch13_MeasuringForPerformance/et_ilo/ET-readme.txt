Instrumentation Library for Oracle
Elapsed Time Recording Module

Frequently Asked Questions


What is the Instrumentation Library for Oracle?

  The Instrumentation Library for Oracle (ILO) is a set of
  PL/SQL packages containing functions that help developers of Oracle
  applications improve the performance diagnosability of their code.
  
  Originally developed at Hotsos, Method R now holds the copyright to the code. 
  http://www.prweb.com/releases/2008/05/prweb839554.htm
  
  All future maintenance and development of this software will be managed by
  Method R through the infrastructure at SourceForge. 
  http://sourceforge.net/projects/hotsos-ilo


Please refer to the readme.txt file in the full ILO install for information on
the overall package.
  

Why should I record the elapsed time of my database processes?

  The benefits of recording elapsed time include:

  - Some performance problems can be difficult to find because they occur at 
        random intervals, yet they can have a big impact on your overall system 
        performance.  Recording the elapsed time for every execution of a process
        can identify processes with highly variable run time.  Once identified,
        the issue causing the variability can be addressed which can reduce 
        resource contention on the system.    

  - Retaining elapsed time data for an extended period can assist in identifying
        increasing run times or variability, helping DBAs resolve small performance 
        issues before they become big performance issues.
        
  - Elapsed time data provides highly useful information yet requires much less 
        storage space than AWR or Staspack history data. This means it can be retained 
        longer.  Combining knowledge gained from recent AWR or Statpacks data with 
        historical process elapsed time data gives a more complete picture of the
        system's performance trends while keeping the performance data footprint
        small. 


What versions of Oracle will the ET ILO code work with?

  - ILO requires Oracle 9.2.0.1 or above.

  - Collecting the CPU elapsed time requires Oracle 10.1.0 or above. Calls to
        get the CPU elapsed time can be commented out if you would like to 
        use the elapsed time recording procedure on a version prior to 10.1.0.


How do you turn on tracing and/or elapsed time collection?

  The BEGIN_TASK call checks to see whether someone has expressed the intent 
  to trace a specific MODULE/ACTION pair by calling ILO_TIMER.GET_CONFIG. This 
  method determines which tasks should be traced.
  
  If ILO_TIMER.SET_MARK_ALL_TASKS_INTERESTING(TRUE,TRUE) has been called to 
  override the normal GET_CONFIG schedule, this will cause a trace file to be 
  generated AND the elapsed time to be recorded.

  If you would like to record the elapsed time for every execution of any
  instrumented code without generating a trace file, you should edit the 
  ILO_TIMER.GET_CONFIG to change the p_rtime variable to TRUE in the last 
  'ELSE' clause as shown:

   BEGIN
      --If the Module and Action are "interesting"  ...
      IF g_all_interesting AND g_ignore_schedule THEN
        p_trace := TRUE;
        p_walltime := TRUE;
        p_rtime := TRUE;

      ELSE
        IF g_all_interesting THEN
          p_trace := TRUE;
          p_walltime := TRUE;
          p_rtime := TRUE;
        ELSE
          p_trace := FALSE;
          p_walltime := FALSE;
          p_rtime := TRUE;
        END IF;
      END IF;


How do you use elapsed time data?

  A sample query has been included in this zip file, showing how Oracle's 
  analytic functions can be used to calculate the variability in processing times.


How do you get updates to the ILO or the timing code?

  The elapsed time recording code will be incorporated into the complete ILO build 
  at Method-R and Sourceforge.net. The next release of ILO will be version 2.4, 
  which is version 2.3, plus this package. A modification to allow trace and timing 
  configurations to be changed in a table will be available soon.  Please subscribe
  as a follower of the ILO package if you would like to hear when this or other 
  modifications become available.
