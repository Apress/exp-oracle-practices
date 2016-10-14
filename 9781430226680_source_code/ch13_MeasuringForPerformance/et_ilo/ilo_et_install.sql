REM ILO
REM Copyright (c) 2006 - 2008 by Method R Corporation. All rights reserved.
REM
REM This library is free software; you can redistribute it and/or
REM modify it under the terms of the GNU Lesser General Public
REM License as published by the Free Software Foundation; either
REM version 2.1 of the License, or (at your option) any later version.
REM
REM This library is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
REM Lesser General Public License for more details.
REM
REM You should have received a copy of the GNU Lesser General Public
REM License along with this library; if not, write to the Free Software
REM Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
REM
PROMPT ========================================================================
PROMPT
PROMPT This script add elasped time recording to an existing intstallation of 
PROMPT the Instrumentation Library for Oracle (ILO), version 2.3.
PROMPT and its associated utilities.
PROMPT
PROMPT Objects Added:
PROMPT
PROMPT * Table ELAPSED_TIME
PROMPT 
PROMPT * Sequence EXECUTION_ID
PROMPT
PROMPT Objects Modified:
PROMPT
PROMPT * Package ILO_TASK
PROMPT * Package ILO_TIMER
PROMPT
PROMPT * Public Synonym ILO_TASK
PROMPT * Public Synonym ILO_TIMER
PROMPT
PROMPT * Execute privileges are granted to PUBLIC for both packages
PROMPT
PROMPT For more information, consult the ET-readme.txt file and the original ILO
PROMPT documentation.
PROMPT
PROMPT ========================================================================
PROMPT 
PROMPT Preparing to start. Hit enter to continue...
PAUSE
PROMPT

set define '&' 
REM set echo off heading off termout off feedback off verify off
set echo off heading off verify off

PROMPT =========================================================================
PROMPT
PROMPT ... Connect as the ILO schema owner
connect &&ilo_owner

set termout off
rem set the version variable for use in packages, must be NUMBER datatype, x.y
column iloversion new_value ilo_version
select '2.4' iloversion from dual;

set termout on
spool ilo_et_install.log

PROMPT ... Creating elapsed time table and execution id sequence
@elapsed_time_table.sql
@execution_id_sequence.sql

show errors;
PROMPT ... Modifying ILO_TASK Package Spec
@ilo_task.pks
/
show errors;
PROMPT ... Modifying ILO_TIMER Package Spec
@ilo_timer.pks
/
show errors;
PROMPT ... Modifying ILO_TIMER Package Body
@ilo_timer.pkb
/
show errors;
PROMPT ... Modifying ILO_TASK Package Body
@ilo_task.pkb
/
show errors;
PROMPT ... Granting EXECUTE privs on packages to PUBLIC
grant execute on ILO_TASK to PUBLIC;
grant execute on ILO_TIMER to PUBLIC;
PROMPT
PROMPT =========================================================================
PROMPT Installation of ILO modifications complete.
PROMPT =========================================================================
spool off
exit
