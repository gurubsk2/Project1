VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_Audibility"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2008. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_Audibility
'* *******************************************************************************************
'* Purpose:     Manage the Audibility of Alarms for the territories owned by the operator
'* *******************************************************************************************
'* Modification History:
'* Author:              Olivier TAYEG
'* Date:                July '09
'* Change:              CR 142724 - Audibility module

'* Author:              Nicole FLORIAN
'* Date:                October '10
'* Change:              CR ALPHA 200872
'*                      Remove the constant c_strClusterName and replace it by the
'*                      call to the Iconis_MOD_General.GetOPCCluster() function in the
'*                      Class_Initialize() subroutine

'* Author:              Olivier Tayeg
'* Date:                May '11
'* Change:              CR ALPHA 230623
'*                      With S2K 7.0.3Patch2 the object ThisLibrary gives data on the current library

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

'* Constants
'* -----------------------------------------------------

' Maximum number of sound levels supported
Private Const c_nMaxLevels As Integer = 4
' List of the levels
Private Const c_iLevelHH As Integer = 3
Private Const c_iLevelH As Integer = 2
Private Const c_iLevelL As Integer = 1
Private Const c_iLevelLL As Integer = 0
Private Const c_iLevelNone As Integer = -1
' Path to the local variables
Private Const c_strBuzzerEnabledTag As String = "ICONIS.APPLICATION.MENU.BUZZER.ENABLED%"

' Path to the OPC server variables
Private Const c_strMainAlarmAudibleTag As String = "IconisS2K.Core.TerritoryManagement.Core.Monitor.Core.OperatorAudible"
Private Const c_strMainAlarmSeverityTag As String = "IconisS2K.Core.TerritoryManagement.Core.Monitor.Core.OperatorAudibleSev"

'* Class attributes
'* ------------------------------------------------------
' Configured name of the sound files to play.
Private m_strFilename(c_nMaxLevels) As String
' The current level being played, it is c_iLevelNone if nothing is being played
Private m_iPlayingLevel As Integer

'* Local OPC variables
'* ------------------------------------------------------
' To get the status of the buzzer
Dim WithEvents m_OPClocal_BuzzerEnabled As Variable
Attribute m_OPClocal_BuzzerEnabled.VB_VarHelpID = -1

'* OPC server's variables
'* ------------------------------------------------------
' True if an Alarm is audible for the current territory
Dim WithEvents m_OPC_MainAlarmAudible As Variable
Attribute m_OPC_MainAlarmAudible.VB_VarHelpID = -1
' Severity of the Main Alarm for the current territory
Dim WithEvents m_OPC_MainAlarmSeverity As Variable
Attribute m_OPC_MainAlarmSeverity.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Audibility::Class_Initialize
' Input:        none
' Output:       none
' Description:  Object constructor.
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "Class_Initialize", "Begin Subroutine")
    
    m_iPlayingLevel = c_iLevelNone
    
    ' Read the configuration
    Configuration
    
    '* Add and reset the variable used for the buzzer status
    Set m_OPClocal_BuzzerEnabled = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strBuzzerEnabledTag, fvVariableTypeBit)
    m_OPClocal_BuzzerEnabled.Value = False
    m_OPClocal_BuzzerEnabled.EnableEvents = True

    '* Adding the server variables to the collection of subscribed variables
    Set m_OPC_MainAlarmAudible = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strMainAlarmAudibleTag, fvVariableTypeBit)
    If (m_OPC_MainAlarmAudible.EnableEvents = True) Then
        m_OPC_MainAlarmAudible_ValueChange
    Else
        m_OPC_MainAlarmAudible.EnableEvents = True
    End If
    
    Set m_OPC_MainAlarmSeverity = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strMainAlarmSeverityTag, fvVariableTypeRegister)
    If (m_OPC_MainAlarmSeverity.EnableEvents = True) Then
        m_OPC_MainAlarmSeverity_ValueChange
    Else
        m_OPC_MainAlarmSeverity.EnableEvents = True
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "Class_Initialize", Err.Description)

End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Audibility::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor.
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "Class_Terminate", "Begin Subroutine")
    
    ' Stop any sound
    StopSound
    
    '* Unsubscribe all the variables previously subscribed
    If Not (m_OPClocal_BuzzerEnabled Is Nothing) Then
        Variables.Remove (m_OPClocal_BuzzerEnabled.Name)
        Set m_OPClocal_BuzzerEnabled = Nothing
    End If
    If Not (m_OPC_MainAlarmAudible Is Nothing) Then
        Variables.Remove (m_OPC_MainAlarmAudible.Name)
        Set m_OPC_MainAlarmAudible = Nothing
    End If
    If Not (m_OPC_MainAlarmSeverity Is Nothing) Then
        Variables.Remove (m_OPC_MainAlarmSeverity.Name)
        Set m_OPC_MainAlarmSeverity = Nothing
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "Class_Terminate", Err.Description)

End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Audibility::Configuration
' Input:        none
' Output:       none
' Description:  Read the configuration of the audibility.
'-------------------------------------------------------------------------------
Private Sub Configuration()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "Configuration", "Begin Subroutine")
    
    ' Currently the names of the sounds is hard-coded
    Dim strPath As String
    Dim I As Integer
    Dim strName(c_nMaxLevels) As String
    
    strPath = ThisProject.Path & "\Resource Files\Sounds\"
    strName(0) = strPath & "Alarm_LL.wav"
    strName(1) = strPath & "Alarm_L.wav"
    strName(2) = strPath & "Alarm_H.wav"
    strName(3) = strPath & "Alarm_HH.wav"
    
    For I = 0 To 3
        If Iconis_MOD_Win32API.FileExists(strName(I)) Then
            m_strFilename(I) = strName(I)
        Else
            m_strFilename(I) = ""
        End If
    Next I

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "Configuration", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Audibility::m_OPC_MainAlarmAudible_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the alarm becoming audible/inaudible
'-------------------------------------------------------------------------------
Private Sub m_OPC_MainAlarmAudible_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "m_OPC_MainAlarmAudible_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_MainAlarmAudible.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "m_OPC_MainAlarmAudible_ValueChange", "The status of " & m_OPC_MainAlarmAudible.Name & " is Waiting")
    ElseIf (m_OPC_MainAlarmAudible.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "m_OPC_MainAlarmAudible_ValueChange", "The status of " & m_OPC_MainAlarmAudible.Name & " is Config Error")
    ElseIf (m_OPC_MainAlarmAudible.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Audibility", "m_OPC_MainAlarmAudible_ValueChange", "The status of " & m_OPC_MainAlarmAudible.Name & " is Not Connected")
    ElseIf (m_OPC_MainAlarmAudible.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Audibility", "m_OPC_MainAlarmAudible_ValueChange", "The Quality of " & m_OPC_MainAlarmAudible.Name & " is not good")
    Else '* Status and quality of the variable are good
        ManageSound
    End If
    
    Exit Sub
ErrorHandler:
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "m_OPC_MainAlarmAudible_ValueChange", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Audibility::m_OPC_MainAlarmSeverity_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the change of severity
'-------------------------------------------------------------------------------
Private Sub m_OPC_MainAlarmSeverity_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "m_OPC_MainAlarmSeverity_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_MainAlarmSeverity.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "m_OPC_MainAlarmSeverity_ValueChange", "The status of " & m_OPC_MainAlarmSeverity.Name & " is Waiting")
    ElseIf (m_OPC_MainAlarmSeverity.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "m_OPC_MainAlarmSeverity_ValueChange", "The status of " & m_OPC_MainAlarmSeverity.Name & " is Config Error")
    ElseIf (m_OPC_MainAlarmSeverity.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Audibility", "m_OPC_MainAlarmSeverity_ValueChange", "The status of " & m_OPC_MainAlarmSeverity.Name & " is Not Connected")
    ElseIf (m_OPC_MainAlarmSeverity.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Audibility", "m_OPC_MainAlarmSeverity_ValueChange", "The Quality of " & m_OPC_MainAlarmSeverity.Name & " is not good")
    Else '* Status and quality of the variable are good
        ' Manage the sound
        ManageSound
    End If
    
    Exit Sub
ErrorHandler:
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "m_OPC_MainAlarmSeverity_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Audibility::m_OPClocal_BuzzerEnabled_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the buzzer activation/disactivation
'-------------------------------------------------------------------------------
Private Sub m_OPClocal_BuzzerEnabled_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "m_OPClocal_BuzzerEnabled_ValueChange", "Begin Subroutine")
    
    ManageSound

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "m_OPClocal_BuzzerEnabled_ValueChange", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Audibility::ManageSound
' Input:        none
' Output:       none
' Description:  Manage the logic of the audibility.
'               A sound is played if the buzzer is enabled
'               or if the severity level of the main alarm is HH.
'-------------------------------------------------------------------------------
Public Sub ManageSound()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "ManageSound", "Begin Subroutine")
    
    If (m_OPC_MainAlarmAudible Is Nothing Or m_OPC_MainAlarmSeverity Is Nothing) Then
        StopSound
    Else
        ' Check the variables to use
        ' If the quality is bad, stop the sound
        If (m_OPC_MainAlarmAudible.Status <> fvVariableStatusGood) Then
            Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Audibility", "ManageSound", "The Quality of m_OPC_MainAlarmAudible is not good")
            StopSound
        End If
        If (m_OPC_MainAlarmSeverity.Status <> fvVariableStatusGood) Then
            Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Audibility", "ManageSound", "The Quality of m_OPC_MainAlarmSeverity is not good")
            StopSound
        End If
      
        ' The sound is enabled only if the main alarm is audible and the buzzer is enabled
        If m_OPC_MainAlarmAudible.Value = True _
            And (m_OPClocal_BuzzerEnabled.Value = True Or m_OPC_MainAlarmSeverity.Value >= 749) Then
            StartSound (m_OPC_MainAlarmSeverity.Value)
        Else
            ' In any other case, the sound is stopped
            StopSound
        End If
    End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "ManageSound", Err.Description)
    ' In case of any error, the sound is stopped
    StopSound
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Audibility::StartSound
' Input:        @param  iSeverityLevel The severity level to play.
' Output:       none
' Description:  Start playing the sound file corresponding to the given severity,
'               if the sound file exists.
'-------------------------------------------------------------------------------
Public Sub StartSound(ByVal iSeverityLevel As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "StartSound", "Begin Subroutine")

    Dim iLevel As Integer

    Select Case iSeverityLevel
        Case 0 To 249
            iLevel = c_iLevelLL
        Case 250 To 499
            iLevel = c_iLevelL
        Case 500 To 749
            iLevel = c_iLevelH
        Case 750 To 1000
            iLevel = c_iLevelHH
        Case Else
            iLevel = c_iLevelNone
    End Select

    ' The sound is started only if it is not already playing
    If (iLevel <> m_iPlayingLevel And m_strFilename(iLevel) <> "") Then
        Iconis_MOD_Win32API.sndPlaySound m_strFilename(iLevel), SND_FILENAME Or SND_ASYNC Or SND_LOOP
        m_iPlayingLevel = iLevel
    End If
  
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "StartSound", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Audibility::StopSound
' Input:        none
' Output:       none
' Description:  Stop playing any sound.
'-------------------------------------------------------------------------------
Private Sub StopSound()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "StopSound", "Begin Subroutine")

    If (m_iPlayingLevel <> c_iLevelNone) Then
        Iconis_MOD_Win32API.sndMuteSound
        m_iPlayingLevel = c_iLevelNone
    End If
  
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "StopSound", Err.Description)
End Sub
