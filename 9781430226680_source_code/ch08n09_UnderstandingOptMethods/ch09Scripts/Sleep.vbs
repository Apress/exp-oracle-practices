Const lngSleepSecondsDefault = 600
Dim lngSleepSeconds
Dim objScriptArguments
Dim strArgument

Set objScriptArguments = WScript.Arguments

If objScriptArguments.Count = 0 then
  lngSleepSeconds = lngSleepSecondsDefault
Else
  For Each strArgument in objScriptArguments
    If IsNumeric(strArgument) Then
      lngSleepSeconds = cLng(strArgument)
      Exit For
    End If
  Next
  If lngSleepSeconds <= 0 Then
    lngSleepSeconds = lngSleepSecondsDefault
  End If
End If

WScript.Sleep lngSleepSeconds * 1000
