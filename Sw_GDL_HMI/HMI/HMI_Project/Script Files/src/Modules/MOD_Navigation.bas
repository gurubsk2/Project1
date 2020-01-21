Attribute VB_Name = "MOD_Navigation"

Public Const VIEW_GeneralView = 1
'Option Explicit

Public Sub OpenForm(strFormName As String)
On Error GoTo ErrorHandler
Select Case strFormName

    Case "LogON"
        Load FRM_LogOn
        FRM_LogOn.Show
        
End Select

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "OpenForm", Err.Description)
End Sub


Public Function Logoff(Optional bPerformLogoff As Boolean = True) As Boolean
    On Error GoTo ErrorHandler
   
        If bPerformLogoff Then
           Logoff = ThisProject.LogoffUser
           
        End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Navigation", "Logoff", Err.Description)
End Function

Private Function GetViewName(ByVal View As Integer) As String

    GetViewName = ""
    If (View = VIEW_GeneralView) Then
        GetViewName = "TGL_GeneralView"
    ElseIf (View = VIEW_DetailedView) Then
        GetViewName = "DETAILED_VIEW_SCROLL"
    ElseIf (View = VIEW_Depot) Then
        GetViewName = "TGL_Depot_Maintenance_Detailed_View"
    ElseIf (View = VIEW_TimeTable) Then
        GetViewName = "Timetable_view"
    ElseIf (View = VIEW_Alarms) Then
        GetViewName = "Alarms_view"
    End If
    
End Function

