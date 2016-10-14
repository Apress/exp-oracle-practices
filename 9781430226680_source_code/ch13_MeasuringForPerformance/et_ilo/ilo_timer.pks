CREATE OR REPLACE PACKAGE Ilo_Timer AS
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
--    v_ <>         Variables
--    c_<>          Constants
--    g_<>          Package Globals
--    ex_           User defined Exceptions
--    r_<>          Records
--    cs_<>         Cursors
--    csp_<>        Cursor Parameters
--    <>_T          Types
--    <>_O          Object Types
--

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
   ---------------------------------------------------------------------
   FUNCTION begin_timed_task(p_begin_time timestamp) RETURN NUMBER;
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
   ---------------------------------------------------------------------
   PROCEDURE end_timed_task (p_stack_rec    ilo_task.stack_rec_t
                            ,p_error_num    PLS_INTEGER default 0
                            ,p_end_time     timestamp DEFAULT NULL
                            ,p_widget_count NUMBER DEFAULT NULL);
   ---------------------------------------------------------------------
   --< get_version >
   ---------------------------------------------------------------------
   --
   --  Purpose: Returns the version of the ILO_TIMER PACKAGE
   --
   --   %return NUMBER	  NUMBER value that indicates version of ILO
   ---------------------------------------------------------------------
   FUNCTION get_version RETURN NUMBER;
   ---------------------------------------------------------------------
   --< FLUSH_ILO_RUNS >
   ---------------------------------------------------------------------
   --
   --  Purpose: This is currently a null package that is called at the very end of the "end_task" once the stack is empty.
   ---------------------------------------------------------------------
   PROCEDURE flush_ilo_runs;
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
   --   %param p_rtime          OUT BOOLEAN  - Whether or not to call the BEGIN_TIMED_TASK/END_TIMED_TASK ILO_TIMER methods.
   --
   --   %usage_notes
   --   <li> Currently all of the OUT values are hardcoded. Please see the package body for defaults
   --   <li> This package body can be changed to read the value of the OUT varables from tables, functions, or emit other defaults based upon your need.
   ---------------------------------------------------------------------      
   PROCEDURE GET_CONFIG (p_module        IN VARCHAR2
                        ,p_action        IN VARCHAR2
                        ,p_trace         OUT BOOLEAN
                        ,p_walltime      OUT BOOLEAN
                        ,p_rtime         OUT BOOLEAN); 
   ---------------------------------------------------------------------
   --< Refresh_Schedule >
   ---------------------------------------------------------------------
   --  Purpose: Used as a placeholder for a method that refreshes an 
   --  in memory schedule that might be used to determine whether or 
   --  not to trace and/or gather response time for a MODULE/ACTION pair.
   --
   --  Comments:
   --
   --
   ---------------------------------------------------------------------
   PROCEDURE refresh_schedule ;                    
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
   PROCEDURE set_mark_all_tasks_interesting(mark_all_tasks_interesting boolean, ignore_schedule boolean DEFAULT FALSE);
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
   FUNCTION get_mark_all_tasks_interesting RETURN BOOLEAN;
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
   FUNCTION get_ignore_schedule RETURN BOOLEAN;

END Ilo_Timer;
