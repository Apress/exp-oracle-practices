CREATE OR REPLACE PACKAGE BODY Ilo_Task AS
------------------------------------------------------------------------------------
--   Contains procedures for defining tasks, setting the MODULE, ACTION, and CLIENT_ID, and for measuring tasks using SQL trace.
------------------------------------------------------------------------------------
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
--
--  Naming Standards
--    v_<>  Variables
--    c_<>  Constants
--    g_<>  Package Globals
--    ex_   User defined Exceptions
--    r_<>  Records
--    cs_<> Cursors
--    csp_<>   Cursor Parameters
--    <>_T  Types
--    <>_O  Object Types
--
---------------------------------------------------------------------

---------------------------------------------------------------------
--< PRIVATE TYPES AND GLOBALS >--------------------------------------
---------------------------------------------------------------------
   g_trace             BOOLEAN          DEFAULT FALSE;
   g_write_wall_time   BOOLEAN          DEFAULT FALSE;
   g_is_apps           BOOLEAN          DEFAULT FALSE;
   g_emit_rtime        BOOLEAN          DEFAULT FALSE;
   g_stack             stack_t          := stack_t ();   -- The global stack.
   g_module            VARCHAR2 (32767);
   g_action            VARCHAR2 (32767);
   g_client_id         VARCHAR2 (32767);

-- TODO: Trace file ID / Filename --
---------------------------------------------------------------------
--< PRIVATE METHODS >------------------------------------------------
---------------------------------------------------------------------

---------------------------------------------------------------------
--< Process_String >
---------------------------------------------------------------------
--  Purpose: Since we enclose the passed strings with [], we need
--           to replace any ']' characters in the comment text with
--           '\]' so they won't be mistaken for the end of string
--           delimiter
--
--  comments
--
--  If we need to do any other "string processing" on the parameters
--  sent to us by the user, this is where we should do it.
--
---------------------------------------------------------------------
   FUNCTION process_string (p_string IN VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN REPLACE (p_string, ']', '\]');
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN NULL;
         end if;
   END process_string;

---------------------------------------------------------------------
--< set_is_apps >
--------------------------------------------------------------------
--  Purpose: This lets ILO know that the instrumented application is part of Oracle E-Business Suite.
--  In this instance, ILO should not change the current MODULE, ACTION, or CLIENT_ID in the V$* tables 
--  as this could interrupt the correct flow of Oracle Apps.
--
--
--   %param IS_APPS	  BOOLEAN Value that indicates whether the session is running as part of Oracle E-Business Suite.
--
--   %usage_notes
--   <li> The default for IS_APPS is FALSE, and therefore when BEGIN_TASK is called ILO will set the V$* values for MODULE, ACTION and CLIENT_ID
---------------------------------------------------------------------
   PROCEDURE set_is_apps(is_apps boolean)
   IS
   BEGIN
      g_is_apps := NVL (is_apps, g_is_apps);
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   END set_is_apps;

---------------------------------------------------------------------
--< get_is_apps >
---------------------------------------------------------------------
--  Return the current value for IS_APPS 
--
--   %param None
--
--   %return BOOLEAN
--
--   %usage_notes
--   <li> Returns the value of IS_APPS set by the user. If the user has not called the SET_IS_APP method, the default is FALSE.
--
---------------------------------------------------------------------
   FUNCTION get_is_apps RETURN boolean
      IS
   BEGIN
      RETURN g_is_apps;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN NULL;
         end if;
   END get_is_apps;
   
   ---------------------------------------------------------------------
   --< set_nesting_level >
   ---------------------------------------------------------------------
   --
   --  DEPRECATED AS OF 2.0 
   --
   --
   --  Purpose: This procedure was used to set the nesting level to be used by ILO to track statistics and emit trace data.
   --  ILO_TASK.BEGIN_TASK now calls ILO_TIMER.GET_CONFIG to determine the appropriate nesting level.
   --
   --  AS OF 2.0, this procedure has no effect.
   ---------------------------------------------------------------------
   PROCEDURE set_nesting_level (nesting_level IN NUMBER)
   IS
   BEGIN
     NULL;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   END set_nesting_level;

   ---------------------------------------------------------------------
   --< get_nesting_level >
   ---------------------------------------------------------------------
   --  Return the NESTING_LEVEL currently active.
   --
   --  DEPRECATED AS OF 2.0 
   --
   --   %param None
   --
   --   %return NUMBER
   --
   --   %usage_notes
   --   <li> Returns the value of NESTING_LEVEL set by the user. If the user has not called the SET_NESTING_LEVEL method, the default is 0.
   --   <li> DEPRECATED: AS OF 2.0, this function always returns 0.
   --
   ---------------------------------------------------------------------
   FUNCTION get_nesting_level
      RETURN NUMBER
   IS
   BEGIN
      RETURN 0;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN 0;
         end if;
   END get_nesting_level;

   ---------------------------------------------------------------------
   --< set_config >
   ---------------------------------------------------------------------
   --
   --  DEPRECATED AS OF 2.0 
   --
   --  Purpose: This procedure was used to express the user's intention to begin tracing. 
   --  ILO.BEGIN_TASK now calls ILO_TIMER.GET_CONFIG to determine whether to trace or not.
   --  
   --  AS OF 2.0, this procedure calls the new SET_MARK_ALL_TASKS_INTERESTING procedure.
   --  This is only temporary, and will be phased out in future release.
   ---------------------------------------------------------------------
   PROCEDURE set_config (TRACE IN BOOLEAN, write_wall_time IN BOOLEAN)
   IS
   BEGIN
     -- These don't really correspond, but this provides at least something of backward compatibility
     ILO_TIMER.SET_MARK_ALL_TASKS_INTERESTING(TRACE,TRACE);
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   END set_config;

---------------------------------------------------------------------
--< get_config >
---------------------------------------------------------------------
--
--  DEPRECATED AS OF 2.0 
--
--  Purpose: return the current values of the TRACE and WRITE_WALL_TIME
--           elements.
--
--  comments
--
--  Provided for convenience...
--  Should use functions get_trace and get_write_wall_time
--
---------------------------------------------------------------------
   PROCEDURE get_config (TRACE OUT BOOLEAN, write_wall_time OUT BOOLEAN)
   IS
   BEGIN
      TRACE := g_trace;
      write_wall_time := g_write_wall_time;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   END get_config;

---------------------------------------------------------------------
--< get_trace >
---------------------------------------------------------------------
--
--  DEPRECATED AS OF 2.0 
--
--  Purpose: return the current values of the TRACE element.
--
--  comments
--
--
---------------------------------------------------------------------
   FUNCTION get_trace
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN g_trace;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN NULL;
         end if;
   END get_trace;

---------------------------------------------------------------------
--< get_write_wall_time >
---------------------------------------------------------------------
--
--  DEPRECATED AS OF 2.0 
--
--  Purpose: return the current values of the write_wall_time element.
--
--  comments
--
--
---------------------------------------------------------------------
   FUNCTION get_write_wall_time
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN g_write_wall_time;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN NULL;
         end if;
   END get_write_wall_time;

   ---------------------------------------------------------------------
   --< begin_task >
   ---------------------------------------------------------------------
   --   Mark the beginning of an instrumented task.
   --
   --   %param module      The module name for the task, truncated to 48 bytes.
   --   %param action      The action name for the task, truncated to 32 bytes.
   --   %param client_id   The client identifier for the task, truncated to 64 bytes.
   --   %param comment     The comment for the task, truncated to 64 bytes.
   --   %param begin_time  The (optional) begin time for the task.
   --
   --   %usage_notes
   --   <li>Marks the beginning of a unit of work. Should be placed right after the "BEGIN" in a procedure or function definition.
   --   <li>Performs, at a minimum, a DBMS_APPLICATION_INFO.SET_MODULE(module, action).
   --   <li>Writes a line to the trace file in this format:
   --             ILO_TASK.BEGIN_TASK[Sequence][Module Name][Action Name][Client Id][Comments]
   --   <li>Pushes the MODULE/ACTION on to a stack along with whether tracing is needed for the MODULE/ACTION.
   --   <li>The MODULE could be name of Package.Procedure or the name of a form.
   --   <li>If the MODULE is NULL and the MODULE of the parent is currently set, then the MODULE will inherit its parent task's MODULE. If the MODULE is NULL and there is no parent task, then the MODULE will be set to "No Module Specified".
   --   <li>If the ACTION is NULL and the ACTION of the parent is currently set, then the ACTION will inherit its parent task's ACTION. If the ACTION is NULL and there is no parent task, then the ACTION will be 'No Action Specified'.
   --   <li>The ACTION should be the business event that is taking place. For example, 'Creating Sales Orders'. This policy makes trying to correlate database statistics to business functions much easier.
   --   <li>The CLIENT_IDENTIFIER should be more technical information or commentary that will be displayed in the V$SESSION view when this BEGIN_TASK is executed.
   --   <li>If the CLIENT_IDENTIFIER has not been set then a the default client_id will be set to: <Client's OS User>~<Client's IP Address>~<Client's program>~<Service being accessed>. For example, if JSmith is on a PC at IP address 192.168.1.40, using SQL*Plus to access the instance through the service name ORCL10G, then the default client identifier will be: <CODE>JSmith~192.168.1.40~SQLPLUS.exe~ORCL10G</CODE>
   --   <li>The BEGIN_TIME can be set explicitly to sync up with the application server rather than the database. Ensure that the time is also sent in END_TASK to avoid appearance of time travel...
   --
   --   %examples
   --   Here is an instrumented block from an HR application:<BR>
   --   <CODE>
   --     CREATE or replace PROCEDURE add_employee(
   --       name VARCHAR2,
   --       salary NUMBER,
   --       manager NUMBER,
   --       title VARCHAR2,
   --       commission NUMBER,
   --       department NUMBER) AS
   --     BEGIN
   --       ILO_TASK.BEGIN_TASK(module => 'Human Resources', action => 'Adding Employees');
   --       INSERT INTO emp
   --         (ename, empno, sal, mgr, job, hiredate, comm, deptno)
   --          VALUES (name, emp_seq.nextval, salary, manager, title, SYSDATE,
   --           commission, department);
   --       ILO_TASK.END_TASK;
   --     EXCEPTION
   --     WHEN OTHERS
   --     THEN
   --       dbms_output.put_line('Exception thrown');
   --       ILO_TASK.END_TASK(error_num =>SQLCODE);
   --     END;
   --   </CODE><BR>
   ---------------------------------------------------------------------
   PROCEDURE begin_task (
      module      IN   VARCHAR2  DEFAULT NULL,
      action      IN   VARCHAR2  DEFAULT NULL,
      client_id   IN   VARCHAR2  DEFAULT NULL,
      COMMENT     IN   VARCHAR2  DEFAULT NULL,
      begin_time  IN   TIMESTAMP default null)
   IS
      v_module           VARCHAR2 (500);
      v_action           VARCHAR2 (500);
      v_client_id        VARCHAR2 (2000);
      v_curr_client_id   VARCHAR2 (2000);
      v_set_client_id    BOOLEAN         := FALSE;
      v_trace            BOOLEAN         := FALSE;
      v_write_wall_time  BOOLEAN         := FALSE;
      v_emit_rtime       BOOLEAN         := FALSE;
      v_trace_text       VARCHAR2 (32767);
      
   BEGIN
      -- See if the schedule needs to be refreshed.
      ilo_timer.refresh_schedule;
      -- Get the Trace and rtime data for this Module/Action pair
      ilo_timer.GET_CONFIG(module, action, v_trace, v_write_wall_time, v_emit_rtime);
      
      -- If we're not already tracing then set the globals to the new trace value.
      if (g_trace = FALSE) then 
         g_trace := v_trace;
         g_write_wall_time := v_write_wall_time;
      end if;
      -- If we're not already emiting run-time data, set the global to the new rtime value.
      if (g_emit_rtime = FALSE) then 
         g_emit_rtime := v_emit_rtime;
      end if;
      

         -- If the call didn't have a MODULE specified, then set it to the same as the PREVIOUS
         IF module IS NULL
         THEN
            IF g_stack.COUNT > 0
            THEN
               v_module :=
                   NVL (g_stack (g_stack.LAST).module, 'No Module Specified');
            ELSE
               v_module := 'No Module Specified';
            END IF;
         ELSE
            v_module := module;
         END IF;

         -- If the call didn't have an ACTION specified, then set it to the same as the PREVIOUS
         IF action IS NULL
         THEN
            IF g_stack.COUNT > 0
            THEN
               v_action :=
                   NVL (g_stack (g_stack.LAST).action, 'No Action Specified');
            ELSE
               v_action := 'No Action Specified';
            END IF;
         ELSE
            v_action := action;
         END IF;

         -- If the call didn't have a CLIENT_ID specified and there isn't a value presently set,
         -- then set it to the DEFAULT using ilo_sysutil.get_client_id
         IF client_id IS NULL
         THEN
            -- If there is already a current value for client_id and we are not wanting to change it,
            -- then we should not waste time setting to the same value
            v_curr_client_id := SYS_CONTEXT ('USERENV', 'CLIENT_IDENTIFIER');

            IF v_curr_client_id IS NULL
            THEN
               -- Since we are not using the client id lets set the client id to the default one
               v_client_id := ilo_sysutil.get_client_id;
               v_set_client_id := TRUE;
            ELSE
               v_client_id := v_curr_client_id;
            END IF;
         ELSE
            v_client_id := client_id;
            v_set_client_id := TRUE;
         END IF;

         -- Push the current Module info onto the stack
         g_stack.EXTEND;
         g_stack (g_stack.LAST).module := v_module;
         g_stack (g_stack.LAST).action := v_action;
         g_stack (g_stack.LAST).client_id := v_client_id;
         g_stack (g_stack.LAST).COMMENT := COMMENT;
         g_stack (g_stack.LAST).trc_active := FALSE;
         g_stack (g_stack.LAST).rtime_active := FALSE;

         
          -- If we've been told to emit rtime data...  (Either by RTIME or TRACING)
          IF (g_emit_rtime or g_trace) THEN
              -- FORCE g_emit_rtime to be TRUE ... This may be because tracing was on, but r-time wasn't
              g_emit_rtime := TRUE;
              -- Get BEGIN the timed task 
              g_stack (g_stack.LAST).SEQUENCE := ilo_timer.begin_timed_task(begin_time);
              -- Set the RTIME_ACTIVE flag on the stack to true;
              g_stack(g_stack.LAST).rtime_active:=TRUE;
          END IF;
          
          -- If we've told the package that we want to trace
          IF (g_trace) THEN
               -- Set the TRC_ACTIVE flag in the stack to true.
               g_stack (g_stack.LAST).trc_active := TRUE;
               -- then turn tracing on with the appropriate procedure call
               ilo_sysutil.turn_trace_on;
               -- and write a line out to the trace file that denotes the beginning of this task
               v_trace_text := 'ILO_TASK.BEGIN_TASK['
                          || process_string (g_stack (g_stack.LAST).SEQUENCE)
                          || ']['
                          || process_string (g_stack (g_stack.LAST).module)
                          || ']['
                          || process_string (g_stack (g_stack.LAST).action)
                          || ']['
                          || process_string (g_stack (g_stack.LAST).client_id)
                          || ']['
                          || process_string (g_stack (g_stack.LAST).COMMENT)
                          || ']';
               ilo_sysutil.write_to_trace (v_trace_text);

               -- If we've told the package that we want to emit a date-time stamp
               IF (g_write_wall_time)
               THEN
                  -- then force timestamp to be emitted to trace file
                  ilo_sysutil.write_datestamp;
               END IF;
            END IF;

         
         -- Only process the following (Module, Action, Client ID) if we're not in an APPS system.
         IF G_IS_APPS = FALSE then
            -- tell ORACLE about our module and client_info values
             DBMS_APPLICATION_INFO.set_module (g_stack (g_stack.LAST).module,
                                               g_stack (g_stack.LAST).action
                                              );
            -- Tell Oracle who we are, using client identifier
            IF v_set_client_id
            THEN
               ilo_sysutil.set_client_id (g_stack (g_stack.LAST).client_id);
            ELSE
               -- No work. The client id is already set to the correct value
              NULL;
            END IF;
         END IF;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   END begin_task;

   ---------------------------------------------------------------------
   --< Get_current_task>
   ---------------------------------------------------------------------
   --   Return a record representing the current task context.
   --
   --   %usage_notes
   --   <li>If no value found for the task then a NULL is returned.
   --
   --   %examples
   --   To print out the value of the current record: <BR>
   --   <CODE>
   --   DECLARE
   --     l_record ILO_TASK.stack_rec_t;
   --   BEGIN
   --     l_record := ILO_TASK.GET_CURRENT_TASK();
   --     IF l_record.module IS NOT NULL THEN
   --         dbms_output.put_line('sequence =>'     || l_record.sequence
   --                         || ', module =>'       || l_record.module
   --                         || ', action =>'       || l_record.action
   --                         || ', client_id =>'    || l_record.client_id
   --                         || ', comment =>'      || l_record.comment
   --                         || ', widgets =>'      || l_record.widget_count);
   --     ELSE
   --       dbms_output.put_line('The record contains no values');
   --     END IF;
   --   END;
   --   </CODE><BR>
   --------------------------------------------------------------------
   FUNCTION get_current_task
      RETURN stack_rec_t
   IS
   BEGIN
      -- If we don't have a task in the stack
      IF g_stack.LAST IS NULL
      THEN
         -- Return a null stack
         RETURN NULL;
      ELSE
         -- otherwise return the last item in the stack (which is current)
         RETURN g_stack (g_stack.LAST);
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN NULL;
         end if;
   END get_current_task;

   ---------------------------------------------------------------------
   --< Get_task_stack>
   ---------------------------------------------------------------------
   --   Return a list of records representing all the currently active task contexts. There will be more than one record returned when nested tasks are active.
   --
   --   %usage_notes
   --   <li>The stack will be given in the order that the stack was created. Record 1 will contain the first record
   --   inserted. The last record will contains the record most recently added.
   --   <li>Because the return is a table type variable, its size is dynamically adjusted to the size of returned list.
   --
   --   %examples
   --   To print out all values in the current stack: <BR>
   --   <CODE>
   --   DECLARE
   --     l_list ILO_TASK.stack_t;
   --   BEGIN
   --     l_list := ILO_TASK.GET_TASK_STACK();
   --     IF l_list.count > 0 THEN
   --       FOR i in 1 .. l_list.count LOOP
   --         dbms_output.put_line('sequence =>'     || l_list(i).sequence
   --                         || ', module =>'       || l_list(i).module
   --                         || ', action =>'       || l_list(i).action
   --                         || ', client_id =>'    || l_list(i).client_id
   --                         || ', comment =>'      || l_list(i).comment
   --                         || ', widgets =>'      || l_list(i).widget_count);
   --       END LOOP;
   --     ELSE
   --       dbms_output.put_line('No elements in the collection');
   --     END IF;
   --   END;
   --   </CODE><BR>
   --
   --------------------------------------------------------------------
   FUNCTION get_task_stack
      RETURN ilo_task.stack_t
   IS
   BEGIN
      RETURN g_stack;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            RETURN NULL;
         end if;
   END get_task_stack;

   ---------------------------------------------------------------------
   --< end_task >
   ---------------------------------------------------------------------
   --   Mark the end of an instrumented task.
   --
   --   %param error_num      Any non-zero integer will be reflected in the timer table as an error.
   --   %param end_time       The (optional) end time for the task.
   --   %param widget_count   The (optional) widget count for the task.
   --
   --   %usage_notes
   --   <li>Expects that the BEGIN_TASK procedure had been run prior to execution.
   --   <li>Marks the end of a task begun by BEGIN_TASK.
   --   <li>In procedures, should be placed right before the "END" and "EXCEPTION" statements.
   --   <li>In "EXCEPTION" statements it would be best to pass the SQLCODE as the error_num.
   --   <li>In functions, should occur right before all "RETURN" statements (which should also be in the EXCEPTION blocks).
   --   <li>Pops the MODULE/ACTION off the stack created and pushed on too the stack created by the ILO_TASK.BEGIN_TASK to retrieve the previous MODULE/ACTION. If it is at the last END_TASK of the BEGIN_TASK/END_TASK pairs then it will perform a DBMS_APPLICATION_INFO.SET_MODULE(module=>NULL,action=>NULL).
   --   <li>Writes a line to the trace file in this format:
   --   ILO_TASK.END_TASK[Module Name][Action Name][Client Id][Comments][Widget Count]
   --   <li>The END_TIME can be set explicitly to sync up with the application server rather than the database. Ensure that the time is also sent in BEGIN_TASK to avoid appearance of time travel...
   --
   --   %examples
   --   An example would be a procedure used in the HR application to add employees: <BR>
   --   <CODE>
   --     CREATE or replace PROCEDURE add_employee(
   --       name VARCHAR2,
   --       salary NUMBER,
   --       manager NUMBER,
   --       title VARCHAR2,
   --       commission NUMBER,
   --       department NUMBER) AS
   --     BEGIN
   --       ILO_TASK.BEGIN_TASK(module => 'Human Resources', action => 'Adding Employees');
   --       INSERT INTO emp
   --         (ename, empno, sal, mgr, job, hiredate, comm, deptno)
   --          VALUES (name, emp_seq.nextval, salary, manager, title, SYSDATE,
   --           commission, department);
   --       ILO_TASK.END_TASK;
   --     EXCEPTION
   --     WHEN OTHERS
   --     THEN
   --       dbms_output.put_line('Exception thrown');
   --       ILO_TASK.END_TASK(error_num =>SQLCODE);
   --     END;
   --   </CODE><BR>
   ---------------------------------------------------------------------
   PROCEDURE end_task (error_num    IN PLS_INTEGER DEFAULT 0, 
                       end_time     IN TIMESTAMP DEFAULT NULL,
                       widget_count IN NUMBER DEFAULT NULL)
   IS
      v_curr_client_id   VARCHAR2 (64);
      v_trace_text       VARCHAR2 (32767);
   BEGIN
      -- If there is actually anything in the stack
      IF g_stack.COUNT > 0
      THEN
            g_stack (g_stack.LAST).widget_count := widget_count;
            -- If we're tracing
            IF (g_trace)
            THEN
               -- If we've been told to write out the wall time
               IF (g_write_wall_time)
               THEN
                  -- Force timestamp to be emitted to trace file
                  ilo_sysutil.write_datestamp;
               END IF;

               --write a line out to the trace file that denotes the END of this processing section
               v_trace_text := 'ILO_TASK.END_TASK['
                             || process_string (g_stack (g_stack.LAST).SEQUENCE
                                               )
                             || ']['
                             || process_string (g_stack (g_stack.LAST).module)
                             || ']['
                             || process_string (g_stack (g_stack.LAST).action)
                             || ']['
                             || process_string
                                              (g_stack (g_stack.LAST).client_id
                                              )
                             || ']['
                             || process_string (g_stack (g_stack.LAST).COMMENT)
                             || ']['
                             || process_string (g_stack (g_stack.LAST).widget_count)
                             || ']';
               ilo_sysutil.write_to_trace (v_trace_text);
            END IF;
            
         -- If we're emiting R to ILO_RUN, then do that now.   
         IF (g_stack(g_stack.LAST).rtime_active) THEN
            -- End the timed task (which writes the data to the collection and/or database table)
            ilo_timer.end_timed_task (g_stack (g_stack.LAST),
                                      error_num, 
                                      end_time,
                                      widget_count);
         END IF;

         -- get current client_id. We will see in a moment if we need to change it.
         v_curr_client_id := g_stack (g_stack.LAST).client_id;
         -- Pop the last value off the stack as we end it.
         g_stack.TRIM;

         -- Are there more elements in the stack?
         IF g_stack.LAST > 0
         THEN
            IF G_IS_APPS = FALSE then
              -- YES, Then set the current module to the parent module
              DBMS_APPLICATION_INFO.set_module (g_stack (g_stack.LAST).module,
                                                g_stack (g_stack.LAST).action
                                               );

              -- Make sure the the client id is set correctly.
              -- If there is already a current value for client_id and we are not wanting to change it,
              -- then we should not waste time setting to the same value
              IF v_curr_client_id != g_stack (g_stack.LAST).client_id
              THEN
                 ilo_sysutil.set_client_id (g_stack (g_stack.LAST).client_id );
              END IF;
            END IF;
         ELSE
          IF G_IS_APPS = FALSE then
            -- NO, then set module, action and client id to NULLs
            DBMS_APPLICATION_INFO.set_module (g_module, g_action);

            -- If there is already a current value for client_id and we are not wanting to change it,
            -- then we should not waste time setting to the same value
            IF v_curr_client_id != g_client_id OR g_client_id IS NULL
            THEN
               ilo_sysutil.set_client_id (g_client_id);
            END IF;
          END IF;
            -- Turn tracing off.
            ilo_sysutil.turn_trace_off;
            -- Flush the ILO-TIMER queue
            ilo_timer.flush_ilo_runs;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   END end_task;

   ---------------------------------------------------------------------
   --< end_all_tasks >
   ---------------------------------------------------------------------
   --   Mark the end of all tasks and subtasks.
   --
   --   %param p_error_num    Any non-zero integer will be reflected in the timer table as an error.
   --   %param p_end_time     The (optional) end time for the task.
   --
   --   %usage_notes
   --   <li>Deletes all tasks on the stack and marks the end of all tasks initiated with BEGIN_TASK.
   --   <li>In "EXCEPTION" statements it would be best to pass the SQLCODE as the error_num.
   ---------------------------------------------------------------------
   PROCEDURE end_all_tasks (p_error_num IN PLS_INTEGER DEFAULT 0,
                            p_end_time IN TIMESTAMP DEFAULT NULL)
   IS
   BEGIN
      -- If we've got anything in the stack...
      IF g_stack.COUNT > 0
      THEN
         -- For each one of those items...
         FOR i IN 1 .. g_stack.COUNT
         LOOP
            -- end the task
            end_task (p_error_num, p_end_time);
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         if ilo_util.get_raise_exceptions then 
            raise;
         else
            NULL;
         end if;
   END end_all_tasks;

   ---------------------------------------------------------------------
   --< Get_Version>
   ---------------------------------------------------------------------
   --   Returns the current version of the ILO Suite that is currently installed.
   --
   --   %usage_notes
   --   <li>You can call this directly to return the version of ILO_TASK.
   --
   --   %examples
   --   To get the current version of the ILO_TASK package <BR>
   --   <CODE>
   --   DECLARE
   --     v_version number;
   --   BEGIN
   --     v_version := ilo_task.get_version();
   --     DBMS_OUTPUT.PUT_LINE(to_char(v_version));
   --   END;
   --   </CODE><BR>
   --
   --------------------------------------------------------------------
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
   END;
---------------------------------------------------------------------
--< MAIN >
---------------------------------------------------------------------
--  Purpose: The Package Initialization code
--
--  comments
--
--
---------------------------------------------------------------------
BEGIN
   -- Remember Caller's Settings
   DBMS_APPLICATION_INFO.read_module (g_module, g_action);

   g_client_id := SYS_CONTEXT ('USERENV', 'CLIENT_IDENTIFIER');
EXCEPTION
   WHEN OTHERS
   THEN
      if ilo_util.get_raise_exceptions then 
         raise;
      else
         NULL;
      end if;
END Ilo_Task;
