CREATE OR REPLACE PACKAGE BODY Ilo_Timer AS
---------------------------------------------------------------------
--  Provides a mechanism for inserting task begin and end times into a local table.
---------------------------------------------------------------------
--
--  Instrumentation Library for Oracle
--  Copyright (C) 2006 - 2008  Method R Corporation. All rights reserved.
--
--  This library is free software; you can redistribute it and/or
--  modify it under the terms of the GNU Lesser General Public
--  License as published by the Free Software Foundation; either
--  version 2.1 of the License, or (at your option) any later version.
--
--  This library is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--  Lesser General Public License for more details.
--
--  You should have received a copy of the GNU Lesser General Public
--  License along with this library; if not, write to the Free Software
--  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
--
---------------------------------------------------------------------

--------------------------------------------------------------------
--
--  Naming Standards
--    v_<>   Variables
--    c_<>   Constants
--    g_<>   Package Globals
--    ex_    User defined Exceptions
--    r_<>   Records
--    cs_<>  Cursors
--    csp_<> Cursor Parameters
--    <>_T   Types
--    <>_O   Object Types
--
---------------------------------------------------------------------

   ---------------------------------------------------------------------
   --< PRIVATE TYPES AND GLOBALS >--------------------------------------
   ---------------------------------------------------------------------

   -- Used in GET_CONFIG for overriding schedule
   g_all_interesting BOOLEAN := FALSE;
   g_ignore_schedule BOOLEAN := FALSE;

--- ELAPSED_TIME record and type added by RSands

   -- Record of the same start info as in the ELAPSED_TIME table
   TYPE r_TimeInfoRec IS RECORD(
       start_time ELAPSED_TIME.start_time%TYPE,
       go_time ELAPSED_TIME.go_time%TYPE,
       go_cputime ELAPSED_TIME.go_cputime%TYPE);

   -- Table of records that hold the ILO_RUN START_TIME info until its time to flush the buffer
   TYPE TimeInfoRec_T IS TABLE OF r_TimeInfoRec INDEX BY PLS_INTEGER;
   g_start_time_info TimeInfoRec_T;

   -- The buffer that holds trace configuration info - not using now, may add later
   -- TYPE config_T IS TABLE OF ILO_TRACE_CONFIG%ROWTYPE INDEX BY PLS_INTEGER;
   -- g_trace_config        config_T;

   -- The buffer that holds records until a "flush" is forced.
   TYPE runs_T IS TABLE OF ELAPSED_TIME%ROWTYPE INDEX BY PLS_INTEGER;
   g_elapsed_time        runs_T;
   g_last_dur_flush_time DATE := SYSDATE;

   -- BULK ERROR exception definition
   ex_bulk_errors EXCEPTION;
   PRAGMA EXCEPTION_INIT(ex_bulk_errors, -24381);

   ---------------------------------------------------------------------
   --< BEGIN_TIMED_TASK >
   ---------------------------------------------------------------------
   --
   --  Purpose: This is currently a null package which is called by BEGIN_TASK. 
   --  You may place logic in this package to track the "start time" of a given task.
   --
   --
   --   %return NUMBER	  This number is used as the "ID" of the Timed task and is output into the trace file as such.
   --
   --   Logic to collect start time added by RSands
   ---------------------------------------------------------------------
   FUNCTION begin_timed_task(p_begin_time timestamp) RETURN NUMBER IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      --
      v_sequence        NUMBER;
      v_start_time      DATE := SYSDATE;
      v_go_time         NUMBER := DBMS_UTILITY.get_time;
      v_go_cputime      NUMBER := DBMS_UTILITY.get_cpu_time;
   BEGIN
      SELECT execution_id.nextval INTO v_sequence FROM DUAL;

      g_start_time_info(v_sequence).start_time := v_start_time;
      g_start_time_info(v_sequence).go_time    := v_go_time;
      g_start_time_info(v_sequence).go_cputime := v_go_cputime;

      RETURN v_sequence;

   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN NULL;
         end if;
   END begin_timed_task;

   ---------------------------------------------------------------------
   --< END_TIMED_TASK >
   ---------------------------------------------------------------------
   --
   --  Purpose: This is currently a null package which is called by END_TASK. 
   --  You may place logic in this package to track the "END time" of a given task.
   --
   --
   --   %param p_stack_rec      The current ILO stack as it exists in the session.
   --   %param p_error_num      An arbitrary error number passed through from the END_TASK call.
   --   %param p_end_time       A timestamp that replaces the natural end time of the task.
   --   %param p_widget_count   The (optional) widget count for the task.
   --
   --   Logic to collect and save elapsed time data added by RSands
   ---------------------------------------------------------------------
   PROCEDURE end_timed_task (
      p_stack_rec    ilo_task.stack_rec_t
     ,p_error_num    PLS_INTEGER default 0
     ,p_end_time     timestamp DEFAULT NULL
     ,p_widget_count NUMBER DEFAULT NULL )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_curr_rec        PLS_INTEGER;
      v_curr_stack      ilo_task.stack_t;
      v_db_user         VARCHAR2(200);
      v_instance        VARCHAR2(200);
      v_parent_id       NUMBER;
      v_spid            VARCHAR2(12);
      v_start_time      TIMESTAMP;
      v_end_time        TIMESTAMP;
      v_go_time         NUMBER;
      v_stop_time       NUMBER;
      v_elapsed_time    NUMBER;
      v_go_cputime      NUMBER;
      v_stop_cputime    NUMBER;
      v_elapsed_cputime NUMBER;
   BEGIN
      -- Get the SPID, instance name, and database user
      v_db_user       := ilo_sysutil.get_session_user;
      v_instance      := ilo_sysutil.get_instance_name;
      v_spid          := ilo_sysutil.get_spid;

      -- Get the parent ID...
      -- To do that we need to get the current stack.
      v_curr_stack    := ilo_task.get_task_stack;

      -- If this is the first item on the stack then it has no parent
      IF v_curr_stack.count <= 1 THEN
         v_parent_id  := NULL;
      -- Otherwise we need to get the previous one.
      ELSE
         v_parent_id  := v_curr_stack(v_curr_stack.LAST - 1).sequence;
      END IF;

      -- Make sure that the task being ended has a sequence assigned.
      IF p_stack_rec.sequence IS NOT NULL THEN

         -- Get the start times that were set in begin_timed_task. Delete when done.
         v_start_time      := g_start_time_info(p_stack_rec.sequence).start_time;
         v_go_time         := g_start_time_info(p_stack_rec.sequence).go_time;
         v_go_cputime      := g_start_time_info(p_stack_rec.sequence).go_cputime;
         g_start_time_info.delete(p_stack_rec.sequence);

         -- Set the end time and prep for et calculation
         v_end_time        := nvl(p_end_time, current_timestamp);
         v_stop_time       := DBMS_UTILITY.get_time;
         v_stop_cputime    := DBMS_UTILITY.get_cpu_time;
         v_elapsed_time    := ((MOD (v_stop_time - v_go_time + POWER (2, 32), POWER (2, 32)))/100);
         v_elapsed_cputime := ((MOD (v_stop_cputime - v_go_cputime + POWER (2, 32), POWER (2, 32)))/100);

         -- Insert the values into ELAPSED_TIME
         v_curr_rec                                 := g_elapsed_time.count;
         g_elapsed_time(v_curr_rec).id              := p_stack_rec.sequence;
         g_elapsed_time(v_curr_rec).spid            := v_spid;
         g_elapsed_time(v_curr_rec).ilo_module      := p_stack_rec.module;
         g_elapsed_time(v_curr_rec).ilo_action      := p_stack_rec.action;
         g_elapsed_time(v_curr_rec).ilo_client_id   := p_stack_rec.client_id;
         g_elapsed_time(v_curr_rec).ilo_comment     := p_stack_rec.comment;
         g_elapsed_time(v_curr_rec).start_time      := v_start_time;
         g_elapsed_time(v_curr_rec).end_time        := v_end_time;
         g_elapsed_time(v_curr_rec).go_time         := v_go_time;
         g_elapsed_time(v_curr_rec).stop_time       := v_stop_time;
         g_elapsed_time(v_curr_rec).elapsed_time    := v_elapsed_time;
         g_elapsed_time(v_curr_rec).go_cputime      := v_go_cputime;
         g_elapsed_time(v_curr_rec).stop_cputime    := v_stop_cputime;
         g_elapsed_time(v_curr_rec).elapsed_cputime := v_elapsed_cputime;
         g_elapsed_time(v_curr_rec).error_num       := p_error_num;
         g_elapsed_time(v_curr_rec).parent_id       := v_parent_id;
         g_elapsed_time(v_curr_rec).instance        := v_instance;
         g_elapsed_time(v_curr_rec).db_user         := v_db_user;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   END end_timed_task;
   ---------------------------------------------------------------------
   --< get_version >
   ---------------------------------------------------------------------
   --
   --  Purpose: Returns the version of the ILO_TIMER PACKAGE
   --
   --   %return NUMBER	  NUMBER value that indicates version of ILO
   ---------------------------------------------------------------------
   FUNCTION get_version 
      RETURN NUMBER
   IS
   BEGIN
      RETURN &&ilo_version;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN NULL;
         end if;
   END get_version;

   ---------------------------------------------------------------------
   --< FLUSH_ILO_RUNS >
   ---------------------------------------------------------------------
   --
   --  Purpose: This is currently a null package that is called at the very end of the "end_task" once the stack is empty.
   --
   --  Clause to insert time record into elasped time table added by RSands
   ---------------------------------------------------------------------
   PROCEDURE flush_ilo_runs 
   IS
     PRAGMA AUTONOMOUS_TRANSACTION;
     l_elapsed_time_count NUMBER := g_elapsed_time.COUNT;
   BEGIN
     IF l_elapsed_time_count > 0 THEN	
        FORALL indx IN g_elapsed_time.FIRST .. g_elapsed_time.LAST SAVE EXCEPTIONS
        INSERT INTO elapsed_time VALUES g_elapsed_time (indx);
	
   END IF;
     COMMIT;
     g_elapsed_time.DELETE;

   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   end flush_ilo_runs;
   ---------------------------------------------------------------------
   --< get_config >
   ---------------------------------------------------------------------
   --  Purpose: is used by ILO.BEGIN_TASK to determine whether a MODULE/ACTION pair
   --  Should be traced, and to what nesting level it should store detail.
   --
   --   %param p_module         IN  VARCHAR2 - The module passed into BEGIN_TASK
   --   %param p_action         IN  VARCHAR2 - The action passed into BEGIN_TASK
   --   %param p_trace          OUT BOOLEAN  - Whether or not to trace the current MODULE/ACTION pair
   --   %param p_walltime       OUT BOOLEAN  - Whether or not to write the WALL TIME out to the trace file for a TRACED task
   --   %param p_rtimer         OUT BOOLEAN  - Whether or not to call the BEGIN_TIMED_TASK/END_TIMED_TASK ILO_TIMER methods.
   --
   --   %usage_notes
   --   <li> Currently all of the OUT values are hardcoded. Please see the package body for defaults
   --   <li> This package body can be changed to read the value of the OUT variables from tables, functions, or emit other defaults based upon your need.
   --
   --   Logic to get the trace, wall time and run time values from a MODULE_CONFIG table added by RSands.
   ---------------------------------------------------------------------      
   PROCEDURE GET_CONFIG (p_module        IN VARCHAR2
                        ,p_action        IN VARCHAR2
                        ,p_trace         OUT BOOLEAN
                        ,p_walltime      OUT BOOLEAN
                        ,p_rtime         OUT BOOLEAN)  
   IS 

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
          p_rtime := FALSE;
        END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN;
         end if;
   END GET_CONFIG;
  
   ---------------------------------------------------------------------
   --< Refresh_Schedule >
   ---------------------------------------------------------------------
   --  Purpose: Used as a placeholder for a method that refreshes an 
   --  in memory schedule that might be used to determine whether or 
   --  not to trace and/or gather response time for a MODULE/ACTION pair.
   --
   --  Comments:
   --
   ---------------------------------------------------------------------
   PROCEDURE refresh_schedule IS
   BEGIN
     NULL;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   END refresh_schedule;  

   ---------------------------------------------------------------------
   --< set_mark_all_tasks_interesting >
   ---------------------------------------------------------------------
   --  Purpose: This function can be used to override the schedule of tasks marked as interesting.
   --  This should normally be used only for testing during setup and configuration. The two boolean 
   --  parameters indicate one of the following three paths.
   --
   --  1) MARK_ALL_TASKS_INTERESTING FALSE, IGNORE_SCHEDULE TRUE or FALSE 
   --       The schedule is used exclusively.
   --  2) MARK_ALL_TASKS_INTERESTING TRUE, IGNORE_SCHEDULE FALSE
   --       The schedule is consulted first. Any task found within the schedule is marked as interesting based on trace and response time parameters in the schedule. Any task not found in the schedule is marked as interesting.
   --  3) MARK_ALL_TASKS_INTERESTING TRUE, IGNORE_SCHEDULE TRUE
   --       The schedule is ignored. All tasks are marked as interesting.
   --  
   --   %param MARK_ALL_TASKS_INTERESTING	  BOOLEAN Value
   --   %param IGNORE_SCHEDULE           	  BOOLEAN Value 
   --
   --   %usage_notes
   --   <li> The default for MARK_ALL_TASKS_INTERESTING and IGNORE_SCHEDULE is FALSE.
   ---------------------------------------------------------------------
   PROCEDURE set_mark_all_tasks_interesting(mark_all_tasks_interesting boolean, ignore_schedule boolean DEFAULT FALSE)
   IS
   BEGIN
      g_all_interesting := NVL (mark_all_tasks_interesting, g_all_interesting);
      g_ignore_schedule := NVL (ignore_schedule, g_ignore_schedule);
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
	    raise;
	 else
            NULL;
	 end if;
   END set_mark_all_tasks_interesting;

   ---------------------------------------------------------------------
   --< get_mark_all_tasks_interesting >
   ---------------------------------------------------------------------
   --  Return the current value for MARK_ALL_TASKS_INTERESTING. 
   --
   --   %param None
   --
   --   %return BOOLEAN
   --
   --   %usage_notes
   --   <li> Returns the value of MARK_ALL_TASKS_INTERESTING set by the user. If the user has not called the SET_MARK_ALL_TASKS_INTERESTING method, the default is FALSE.
   --
   ---------------------------------------------------------------------
   FUNCTION get_mark_all_tasks_interesting
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN g_all_interesting;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
	    raise;
	 else
            RETURN NULL;
	 end if;
   END get_mark_all_tasks_interesting;

   ---------------------------------------------------------------------
   --< get_ignore_schedule >
   ---------------------------------------------------------------------
   --  Return the current value for IGNORE_SCHEDULE. 
   --
   --   %param None
   --
   --   %return BOOLEAN
   --
   --   %usage_notes
   --   <li> Returns the value of IGNORE_SCHEDULE set by the user. If the user has not called the SET_MARK_ALL_TASKS_INTERESTING method, the default is FALSE.
   --
   ---------------------------------------------------------------------
   FUNCTION get_ignore_schedule
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN g_ignore_schedule;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
	    raise;
	 else
            RETURN NULL;
	 end if;
   END get_ignore_schedule;

BEGIN 
    refresh_schedule;
EXCEPTION
   WHEN OTHERS THEN
      if ilo_util.get_raise_exceptions then 
         raise;
      else
         NULL;
      end if;
END Ilo_Timer;
