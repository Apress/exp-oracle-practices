CREATE OR REPLACE PACKAGE Ilo_Task AS
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
   ------------------------------------------------------------------------------------
   --
   --   <b>Introduction</b>
   --
   --   Diagnosing and repairing performance problems in an Oracle environment can be
   --   a complicated and time-consuming job. However, you, the Application
   --   Developer, can make the job much simpler for everyone downstream (including
   --   yourself) by inserting a few extra lines of code--called
   --   <i>instrumentation</i>--into your applications. With the right
   --   instrumentation library, the job is easy. The Instrumentation Library
   --   for Oracle (ILO) gives you the lines of code that you're looking for.
   --
   --   <b>The Payoff</b>
   --
   --   Instrumentation makes your code faster, easier to maintain, and cheaper to
   --   write. Instrumentation makes your code faster because it shows you all your
   --   opportunities for making your code more efficient, right while you're writing
   --   it. Instrumentation makes your code easier to maintain because it shows you
   --   exactly what your customer or support analyst is talking about when she says
   --   your code is too slow. And instrumentation makes your code cheaper to write
   --   because it focuses your tuning efforts only upon the parts of your code where
   --   performance really matters. Good instrumentation is your immunization against
   --   premature optimization, "the root of all evil" (Hoare's Dictum).
   --
   --   <b>All You Have to Do is Mark Your Tasks</b>
   --
   --   A task is any unit of work whose duration you want to measure. ILO_TASK
   --   makes it very simple to define tasks within your application. You simply
   --   bracket the code path that constitutes a performance-measurable work unit (a
   --   task) with calls to BEGIN_TASK and END_TASK, like this:
   --   <code>
   --      ilo_task.begin_task(module, action, client, comment);
   --      -- The code path for your task goes here.
   --      ilo_task.end_task;
   --   </code>
   --   Using BEGIN_TASK and END_TASK does all the Oracle housekeeping your
   --   application needs. All that stuff you've ever heard about
   --   DBMS_APPLICATION_INFO and DBMS_SESSION. Now you can forget about it. All you
   --   have to remember is to mark your tasks.
   --
   --   <b>How to Name Your Tasks</b>
   --
   --   Here are a few guidelines to make instrumenting your tasks easier:
   --
   --   <li>Task names in ILO_TASK contain two hierarchical components:
   --   the MODULE and the ACTION. Think of the ACTION as the name of the task itself
   --   and the MODULE as a means of identifying what part of your application the
   --   task represents. For smaller applications, the module name could and probably
   --   should be also the name of the package that contains the code. The action
   --   name is the operation being performed for this module.
   --
   --   For example, the package INBOUND_SALES_ORDER_FEEDS contains many procedures
   --   and functions. One such procedure is called INSERT_BOM_SO; it inserts into
   --   several tables. A good task name for this procedure would be:
   --   <code>
   --     module=>'Sales Orders'
   --     action=>'Add BOM'
   --   </code></li><br>
   --
   --   <li>Name a task with a name that is recognizable to the business. Notice that
   --   we've done this in the prior example. The hierarchical name 'Sales
   --   Orders'.'Add BOM' refers to a unit of work that is easily recognizable by
   --   name to the business.
   --
   --   <li>Tasks can nest. This is an especially useful feature for long-running
   --   tasks. Imagine that a task consumes an hour of run time in a loop. Your
   --   customer wants to measure and manage the duration of each loop iteration. You
   --   can define each loop iteration as a (sub)task, as in the following example:
   --   <code>
   --     ilo_task.begin_task('Billing', 'Invoice customers', '', '');
   --     for i in 1 .. r.count loop
   --       ilo_task.begin_task('', 'Invoice one customer', '', i);
   --       -- Code to invoice a customer goes here.
   --       ilo_task.end_task;
   --     end loop;
   --     ilo_task.end_task;
   --   </code>
   --   Be careful how granular you get with your nesting. We've made every effort to
   --   make the Instrumentation Library for Oracle as fast and efficient as possible,
   --   but nested BEGIN_TASK calls can themselves become a performance problem if
   --   the tasks you're instrumenting have very tiny durations.
   --
   --   <li>At a minimum, there are two lines of instrumentation in each package that
   --   you will instrument. The first line is the call to BEGIN_TASK. It should come
   --   right after the "BEGIN" line in procedures and functions. For procedures,
   --   place a call to END_TASK immediately before the "EXCEPTION" line and in every
   --   EXCEPTION block before the "END". In functions, place a call to END_TASK
   --   before every RETURN, including RETURN statements in the EXCEPTION block.

   /*
   TODO: owner="dgault" category="Refactor" priority="3 - Low" created="04-Apr-06"
   text="See if we can implement a way to SET the trace file name specifically"
   */

   /*
   TODO: owner="dgault" category="Refactor" priority="3 - Low" created="04-Apr-06"
   text=" See if we can KNOW the name of the trace file and return it from a function"
   */

   -- ------------------------------------------------------------------
   --
   --  Naming Standards:
   --    v_ <> Variables
   --    c_<>  Constants
   --    g_<>  Package Globals
   --    ex_   User defined Exceptions
   --    r_<>  Records
   --    cs_<> Cursors
   --    csp_<>   Cursor Parameters
   --    <>_T  Types
   --    <>_O  Object Types
   --
   -----------------------------------------------------------------------
   --< PUBLIC TYPES AND GLOBALS >-----------------------------------------
   -----------------------------------------------------------------------

   --   This record type is used for the GET_CURRENT_TASK and GET_TASK_STACK procedures.
   --
   --   %param sequence      Internally generated sequence number used to track an occurance of a specific Module/Action. Will be NULL unless you are using the extended version (comming soon)
   --   %param trc_active    Is 10046 level trace currently activated for this task.
   --   %param module        Name of module that is currently running.
   --   %param action        Name of current action within the current module. If you do not want to specify an action, this value should be NULL.
   --   %param client_id     The client_id argument will also be used to set CLIENT_IDENTIFIER column. The CLIENT_IDENTIFIER column has 64 bytes.
   --   %param comment       A free form comment
   --   %param bnl           Beyond the currently set Nesting Level?
   --   %param widget_count  Count of widgets processed during the task
   TYPE stack_rec_t IS RECORD(
       SEQUENCE     NUMBER
      ,trc_active   BOOLEAN
      ,rtime_active BOOLEAN
      ,module       VARCHAR2(255)
      ,action       VARCHAR2(255)
      ,client_id    VARCHAR2(255)
      ,COMMENT      VARCHAR2(255)
      ,BNL          BOOLEAN
      ,widget_count NUMBER);

   -- STACK_T is a TYPE used to hold the calls stack returned from GET_TASK_STACK
   TYPE stack_t IS TABLE OF stack_rec_t;

   -----------------------------------------------------------------------
   --< PUBLIC METHODS >
   -----------------------------------------------------------------------

   ---------------------------------------------------------------------
   --< set_is_apps >
   ---------------------------------------------------------------------
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
   PROCEDURE set_is_apps(is_apps boolean);

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
   --   <li> Returns the value of IS_APPS set by the user. If the user has not called the SET_IS_APPS method, the default is FALSE.
   --
   ---------------------------------------------------------------------
   FUNCTION get_is_apps RETURN boolean;
   ---------------------------------------------------------------------
   --< set_nesting_level >
   ---------------------------------------------------------------------
   --
   --  DEPRECATED AS OF 1.6 
   --
   --
   --  Purpose: This procedure was used to set the nesting level to be used by ILO to track statistics and emit trace data.
   --  ILO_TASK.BEGIN_TASK now calls ILO_TIMER.GET_CONFIG to determine the appropriate nesting level.
   --
   --  AS OF 1.6, this procedure has no effect.
   ---------------------------------------------------------------------
   PROCEDURE set_nesting_level(nesting_level IN NUMBER);
   ---------------------------------------------------------------------
   --< get_nesting_level >
   ---------------------------------------------------------------------
   --  Return the NESTING_LEVEL currently active.
   --
   --  DEPRECATED AS OF 1.6 
   --
   --   %param None
   --
   --   %return NUMBER
   --
   --   %usage_notes
   --   <li> Returns the value of NESTING_LEVEL set by the user. If the user has not called the SET_NESTING_LEVEL method, the default is 0.
   --   <li> DEPRECATED: AS OF 1.6, this function always returns 0.
   --
   ---------------------------------------------------------------------
   FUNCTION get_nesting_level RETURN NUMBER;

   ---------------------------------------------------------------------
   --< get_config >
   ---------------------------------------------------------------------
   --
   --  DEPRECATED AS OF 1.6 
   --
   --  Return values for Trace and Write_wall_time
   --
   --   %param trace           Boolean value that indicates whether to write trace data for tasks.
   --   %param write_wall_time Boolean value that indicates whether to write the current execution time to the trace file at the beginning and ending of tasks
   --
   PROCEDURE get_config(TRACE OUT BOOLEAN, write_wall_time OUT BOOLEAN);

   ---------------------------------------------------------------------
   --< set_config >
   ---------------------------------------------------------------------
   --
   --  DEPRECATED AS OF 1.6 
   --
   --  Purpose: This procedure was used to express the user's intention to begin tracing. 
   --  ILO.BEGIN_TASK now calls ILO_TIMER.GET_CONFIG to determine whether to trace or not.
   --  
   --  AS OF 1.6, this procedure calls the new SET_MARK_ALL_TASKS_INTERESTING procedure.
   --  This is only temporary, and will be phased out in future release.
   ---------------------------------------------------------------------
   PROCEDURE set_config(TRACE IN BOOLEAN, write_wall_time IN BOOLEAN);

   ---------------------------------------------------------------------
   --< get_trace >
   ---------------------------------------------------------------------
   --
   --  DEPRECATED AS OF 1.6 
   --
   --  Return TRUE if and only if the intent to trace has been specified .
   --
   --   %param None
   --
   --   %return Boolean values TRUE or FALSE
   --
   --
   ---------------------------------------------------------------------
   FUNCTION get_trace RETURN BOOLEAN;

   ---------------------------------------------------------------------
   --< get_write_wall_time >
   ---------------------------------------------------------------------
   --
   --  DEPRECATED AS OF 1.6 
   --
   --  Return TRUE if and only if the intent to write the wall time to the trace file has been specified .
   --
   --   %param None
   --
   --   %return Boolean values TRUE or FALSE
   --
   --   %usage_notes
   --   <li>If SET_CONFIG(write_wall_time => TRUE) has been called, then GET_write_wall_time() returns TRUE.
   --
   ---------------------------------------------------------------------
   FUNCTION get_write_wall_time RETURN BOOLEAN;

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
   PROCEDURE begin_task(module IN VARCHAR2 DEFAULT NULL
                       ,action IN VARCHAR2 DEFAULT NULL
                       ,client_id IN VARCHAR2 DEFAULT NULL
                       ,COMMENT   IN VARCHAR2 DEFAULT NULL
                       ,begin_time in timestamp default null);

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
   PROCEDURE end_task(error_num IN PLS_INTEGER DEFAULT 0, end_time IN timestamp DEFAULT NULL, widget_count IN NUMBER DEFAULT NULL);

   ---------------------------------------------------------------------
   --< end_all_tasks >
   ---------------------------------------------------------------------
   --   Mark the end of all tasks and subtasks.
   --
   --   %param p_error_num   Any non-zero integer will be reflected in the timer table as an error.
   --   %param p_end_time    The (optional) end time for the task.
   --
   --   %usage_notes
   --   <li>Deletes all tasks on the stack and marks the end of all tasks initiated with BEGIN_TASK.
   --   <li>In "EXCEPTION" statements it would be best to pass the SQLCODE as the error_num.
   ---------------------------------------------------------------------
   PROCEDURE end_all_tasks (p_error_num IN PLS_INTEGER DEFAULT 0,
                            p_end_time in TIMESTAMP default null);

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
   FUNCTION get_current_task RETURN stack_rec_t;

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
   FUNCTION get_task_stack RETURN ilo_task.stack_t;
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
   FUNCTION get_version RETURN NUMBER;

END Ilo_Task;
