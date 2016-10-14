Dim intInstance
Dim IntOldCSPerSec
Dim intOldProcesses
Dim intOldThreads
Dim strSQL
Dim strSQL2
Dim strOut
Dim strComputer
Dim sglUMTime(20)
Dim sglKMTime(20)
Dim sglWorkingSet(20)
Dim sglPageFileUsage(20)
Dim sglOUMTime(20)
Dim sglOKMTime(20)
Dim sglOldWorkingSet(20)
Dim sglOldPageFileUsage(20)
Dim objWMIService
Dim colItems
Dim objItem
Dim adsFile

Set adsFile = CreateObject("ADODB.Stream") 
adsFile.Type = 2 
adsFile.Charset = "iso-8859-1" 
adsFile.Open

strSQL = "SELECT * FROM Win32_PerfRawData_PerfOS_System"
strSQL2 = "SELECT * FROM Win32_Process Where Name like 'Oracle%'"

strComputer = "."  ' the . indicates the local computer 
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\CIMV2") 

IntOldCSPerSec = 0
For intInstance = 1 to 20
    sglOUMTime(intInstance) = 0
    sglOKMTime(intInstance) = 0
    sglOldWorkingSet(intInstance) = 0
    sglOldPageFileUsage(intInstance) = 0
Next

For i = 1 to 20
  Set colItems = objWMIService.ExecQuery(strSQL,"WQL",48)

  For Each objItem in colItems
    strOut = Now() & " Processes: " & objItem.Processes
    strOut = strOut & " Threads: " & objItem.Threads
    strOut = strOut & " C. Switches: " & objItem.ContextSwitchesPersec - IntOldCSPerSec
    strOut = strOut & " Q. Length: " & objItem.ProcessorQueueLength

    'Write to screen
    Wscript.Echo strOut

    'Write to log file
    adsFile.WriteText(strOut & vbCrLf)

    IntOldCSPerSec = objItem.ContextSwitchesPersec
    intOldProcesses = objItem.Processes
    intOldThreads = objItem.Threads
  Next

  Set colItems = Nothing
  Set colItems = objWMIService.ExecQuery(strSQL2,"WQL",48)

  intInstance = 0
  For Each objItem in colItems
    intInstance = intInstance + 1
    sglUMTime(intInstance) = Round(objItem.UserModeTime/10000000, 2)
    sglKMTime(intInstance) = Round(objItem.KernelModeTime/10000000, 2)
    sglWorkingSet(intInstance) = Round(objItem.WorkingSetSize/1048576, 2)
    sglPageFileUsage(intInstance) = Round(objItem.PageFileUsage/1048576, 2)

    strOut = "Instance: " & objItem.CommandLine & vbCrLf
    strOut = strOut & " User Time: " & Round(sglUMTime(intInstance) - sglOUMTime(intInstance),2) & "S"
    strOut = strOut & " Sys  Time: " & Round(sglKMTime(intInstance) - sglOKMTime(intInstance),2) & "S"
    strOut = strOut & " Memory: " & sglWorkingSet(intInstance) & "MB"
    strOut = strOut & " Page File: " & sglPageFileUsage(intInstance) & "MB" & vbCrLf

    'Write to screen
    Wscript.Echo strOut

    'Write to log file
    adsFile.WriteText(strOut & vbCrLf)

    sglOUMTime(intInstance) = Round(objItem.UserModeTime/10000000, 2)
    sglOKMTime(intInstance) = Round(objItem.KernelModeTime/10000000, 2)
    sglOldWorkingSet(intInstance) = Round(objItem.WorkingSetSize/1048576, 2)
    sglOldPageFileUsage(intInstance) = Round(objItem.PageFileUsage/1048576, 2)
  Next

  'Wait one second before sampling again
  Wscript.Sleep 1 * 1000
Next

adsFile.SaveToFile "C:\CPU Status.txt", 2  
adsFile.close 