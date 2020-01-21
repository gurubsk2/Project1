VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
'
'VERSION 1.0 CLASS
'BEGIN
'  MultiUse = -1  'True
'End
'Attribute VB_Name = "ThisProject"
'Attribute VB_GlobalNameSpace = False
'Attribute VB_Creatable = False
'Attribute VB_PredeclaredId = True
'Attribute VB_Exposed = True
Option Explicit

Public MyLogin As String
Private SectorMimic As String
Dim MyWindow As Window
Private Const ScreenWidth As Integer = 1920
Private Const MainMimicHeight As Integer = 940
Private sMyBranch As String
Public Monitors As Integer
Public WKSName As String
Public APPName As String
Public iRouteSelectionTimerCount As Integer

Dim WithEvents TIMER_HmiInOrder As S2KActiveXTimerCtl.Timer '* Initiate the Timer Class
Attribute TIMER_HmiInOrder.VB_VarHelpID = -1
'Attribute TIMER_HmiInOrder.VB_VarHelpID = -1
Dim WithEvents TIMER_HILCStatus As S2KActiveXTimerCtl.Timer '* Initiate the Timer Class
Attribute TIMER_HILCStatus.VB_VarHelpID = -1
'Attribute TIMER_HILCStatus.VB_VarHelpID = -1
Dim WithEvents TIMER_ThirdRail As S2KActiveXTimerCtl.Timer '* Initiate the Timer Class
Attribute TIMER_ThirdRail.VB_VarHelpID = -1
'Attribute TIMER_ThirdRail.VB_VarHelpID = -1
Public MainMimicName As String

Public ActualDate, ActualTime As Variant
Public strLoggedUsers As String '* String gets updated whenever there is a new user login
Public WithEvents OPC_LoggedUsers As Variable '* Variable which holds the list of users connected
Attribute OPC_LoggedUsers.VB_VarHelpID = -1
'Attribute OPC_LoggedUsers.VB_VarHelpID = -1
Public strWKSsite As String '* Variable to hold the ATS level ,depending on WKS from Working Files\WorkStation.xml
Const c_LoggedUsersOPCBranch As String = "OPCCluster:IconisS2K.Core.OPCServerConnection.Core.Monitor.Core.ConnectedUsers"
Public OptTab As ControlTabs
Public ClusterName As String
Public CreateTrain As Byte
Public strWKSName As String
Public Enum ControlTabs
    [Information Page] = 0
    [Control Page] = 1
    [Tag Page] = 2
End Enum


Public CurrentUser As String
Const strHeartBit As String = "OPCCluster:IconisHMI.HeartBit.Value%"
Dim HeartbitCounter As Integer

Private Const c_strOPCClusterName = "OPCCluster:"

'Territory variables
Public WithEvents m_AskTerritory As Variable
Attribute m_AskTerritory.VB_VarHelpID = -1

Public WithEvents m_Territory1_ControlledBy As Variable
Attribute m_Territory1_ControlledBy.VB_VarHelpID = -1
Public WithEvents m_Territory2_ControlledBy As Variable
Attribute m_Territory2_ControlledBy.VB_VarHelpID = -1
Public WithEvents m_Territory3_ControlledBy As Variable
Attribute m_Territory3_ControlledBy.VB_VarHelpID = -1
Public WithEvents m_Territory4_ControlledBy As Variable
Attribute m_Territory4_ControlledBy.VB_VarHelpID = -1
Public WithEvents m_Territory5_ControlledBy As Variable
Attribute m_Territory5_ControlledBy.VB_VarHelpID = -1
Public WithEvents m_Territory6_ControlledBy As Variable
Attribute m_Territory6_ControlledBy.VB_VarHelpID = -1

'* CATS ModeMGmt
''Public m_OPC_CATSMode As Variable
'Line Control Request
Public WithEvents m_LineControlRequest As Variable
Attribute m_LineControlRequest.VB_VarHelpID = -1

'User report monitors
Public WithEvents m_OPC_UserReportLabelLV1      As Variable
Attribute m_OPC_UserReportLabelLV1.VB_VarHelpID = -1
Public WithEvents m_OPC_UserReportLabelLV2      As Variable
Attribute m_OPC_UserReportLabelLV2.VB_VarHelpID = -1

'-----------------------------------------------------------------------------
' <summary>
'     Sub Add Local Variables, Config Status Inicial Menu, Set initial Timers
' </summary>
' <Return>
'     Boolean:
' </Return>
' <remarks></remarks>
' <history>
'     [Vanderson]     12/12/2005   Created Documentary
' </history>
'-----------------------------------------------------------------------------


Private Sub fvProject_StartupComplete()
Dim sMachineName As String
Dim strWindowsUsername As String
On Error GoTo ErrorHandler

    'Set local variable if LATS
    Variables.Add "bLATSMachine%", fvVariableTypeBit
    [bLATSMachine%] = (ThisSystem.ComputerName Like "TLLIHMTTR1")

'* To set the username of windows to project user
'*****************************
strWindowsUsername = Environ("Username")
'If ThisProject.LogonUser(False, strWindowsUsername) Then
'    ThisProject.UserName = strWindowsUsername
    ''If setloginuser() = "" Then
    
   '' Else
   LoginWindowsuser
    'ThisProject.UserName = "Default"
'End If
    'MsgBox "Windows username and  HMI username does not match"
    'ThisProject.Quit fvDoNotSaveChanges, False
    'Exit Sub
'End If
ThisProject.SetProjectLanguage ("ESM")
Variables.Add "bStartingSystem%", fvVariableTypeBit
[bStartingSystem%] = True
m_layervalue = 65535
'* Module to Get Monitors connected to the Workstation
'*****************************

Dim iCount As Integer
    OpenMimicInCenter "mmc_HMIStartupLoading", "", GetmousepointerPossition
    Variables.Item("@Loading_Progress%").Value = 10
    
    Mod_General.GetMonitors
    Variables.Item("@Loading_Progress%").Value = 30
    
    
    '* Open the Welcome mimic
    Mod_General.OpenDefaultMimics
    Variables.Item("@Loading_Progress%").Value = 100

Variables.Add strHeartBit, fvVariableTypeRegister

'ThisProject.PresentationLanguage = ""
Variables.Add "WorkstationAlive%", fvVariableTypeRegister
Variables.Add "wksname%", fvVariableTypeText
Variables.Item("WorkstationAlive%") = 0

Variables.Add "@TSRMngtViewIsOpened%", fvVariableTypeBit


'* Update the LocalVariable for the WorkStationName
Variables.Item("wksname%").Value = ThisSystem.ComputerName



    Iconis_MOD_General.SetOPCCluster (c_strOPCClusterName)
    Iconis_MOD_General.Init (c_strOPCClusterName)

AddGeneralVariables
AddRouteVariables

mod_UO_General.AddVariables 'For line operating mode (headways)

'* Subscribe Territories using ShareadLibrary Class
ThisProject.ConfigureTerritories
'''
''''* Initiate the Users logged IN OPC Plug
'''Set ThisProject.OPC_LoggedUsers = Variables.Add(c_LoggedUsersOPCBranch, fvVariableTypeText)
'''If (ThisProject.OPC_LoggedUsers.EnableEvents = True) Then
'''    OPC_LoggedUsers_ValueChange
'''Else
'''    ThisProject.OPC_LoggedUsers.EnableEvents = True
'''End If


Set TIMER_HmiInOrder = New S2KActiveXTimerCtl.Timer
TIMER_HmiInOrder.Interval = 1000
TIMER_HmiInOrder.Enabled = True

    Read_UserNote

sMachineName = ThisSystem.ComputerName

If (sMachineName Like "*LATS") Then
    Set m_LineControlRequest = Variables.Add(c_strClusterLevel2 & "LATS.MMGATSArea.NegociatedMode", fvVariableTypeRegister)
Else
    Set m_LineControlRequest = Variables.Add(c_strClusterLevel2 & "CATS.MMGATSArea.NegociatedMode", fvVariableTypeRegister)
End If
m_LineControlRequest.EnableEvents = True

[bStartingSystem%] = False

iRouteSelectionTimerCount = -1


    If Variables.Item("@UserReportLabel%") Is Nothing Then _
        Variables.Add "@UserReportLabel%", fvVariableTypeText

    If Variables.Item("@LastUserReportLabelLV1%") Is Nothing Then _
        Variables.Add "@LastUserReportLabelLV1%", fvVariableTypeText

    If Variables.Item("@LastUserReportLabelLV2%") Is Nothing Then _
        Variables.Add "@LastUserReportLabelLV2%", fvVariableTypeText
 
    Set ThisProject.m_OPC_UserReportLabelLV1 = Variables("OPCCluster:MainKernelBasic.AEModule.MgntUserReport.UserReportLabel")
    Set ThisProject.m_OPC_UserReportLabelLV2 = Variables("opcclusteratslv2:MainKernelBasic.AEModule.MgntUserReport.UserReportLabel")
    ThisProject.m_OPC_UserReportLabelLV1.EnableEvents = True
    ThisProject.m_OPC_UserReportLabelLV2.EnableEvents = True



Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, ThisProject.ProjectName, "fvProject_StartupComplete", Err.Description)
    [bStartingSystem%] = False
End Sub
'-----------------------------------------------------------------------------
' <summary>
'   Function:
'     Close all mimics opened with prefix name selected.
' </summary>
' <remarks></remarks>
'-----------------------------------------------------------------------------
Public Function CloseAllMyMimics(ByVal MimicPrefix As String)
    On Error GoTo ErrorHandler
    Dim objMimic As Mimic
    For Each objMimic In Application.ActiveProject.Mimics
        If (objMimic.FileName Like MimicPrefix) Then
            If ((objMimic.FileName <> "Timers") And Not (objMimic.FileName Like "VIEW_Overview*") And _
            Not (objMimic.FileName Like "WELCOME_VIEW*")) Then
                Mimics.Item(objMimic.index).Close fvDoNotSaveChanges
            End If
        End If
    Next
        
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Main.thisproject", "CloseAllMyMimics", Err.Description)
End Function


'-----------------------------------------------------------------------------
' <summary>
'     Function to close the Any Mimic.fvm that inserted in the variable "MainMimic%"
' </summary>
' <Return>
'     Boolean:
' </Return>
' <remarks></remarks>
'-----------------------------------------------------------------------------
Private Function fvProject_BeforeQuit() As Boolean
    On Error GoTo ErrorHandler
    Dim Item As Variable
    Dim MainMimic As String
    Dim objMimic As Mimic
    
    On Error Resume Next
    
    ThisProject.LogoffUser (False)
    
    If Not (Variables.Item("MainMimic%") Is Nothing) Then
        MainMimic = Variables.Item("MainMimic%")
        If (Mimics.IsOpened(MainMimic)) Then
            Mimics.Item(MainMimic).Close fvDoNotSaveChanges
        End If
    End If
    For Each objMimic In Mimics
        If Not (objMimic Is Nothing) Then
            objMimic.Close fvDoNotSaveChanges
        End If
    Next
    Set Item = Nothing
    Debug.Print Mimics.Count
    Debug.Print Variables.Count
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Main.thisproject", "fvProject_BeforeQuit", Err.Description)
End Function

'* ******************************************************************************************
'*  SubRoutine: fvProject_UserChanged
'*    Manage the events when the logged users in the project change
'* ******************************************************************************************
Private Sub fvProject_UserChanged()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, ThisProject.ProjectName, "fvProject_UserChanged", "Begin Subroutine")
    Dim strPath As String
    Dim vProfile
    Call Variables.Add(Iconis_MOD_General.c_strUserNameLocalTag, fvVariableTypeText)
    Call Variables.Add(Iconis_MOD_General.c_strUserProfileLocalTag, fvVariableTypeText)
    Variables.Item(Iconis_MOD_General.c_strUserNameLocalTag).Value = ThisProject.Security.UserName

    vProfile = ThisProject.Security.users.GetProfiles(ThisProject.Security.UserName)

    'Update profile local variables
     Call Variables.Add("bAdmin%", fvVariableTypeText)
     Call Variables.Add("bSupervisor%", fvVariableTypeText)
     Call Variables.Add("bRegulator%", fvVariableTypeText)
     Call Variables.Add("bMaintenance%", fvVariableTypeText)
     Call Variables.Add("bDepotRegulator%", fvVariableTypeText)
     
    Variables("bAdmin%").Value = InStr(1, vProfile(0), "AdministrativeProfile", vbTextCompare) = 1
    Variables("bSupervisor%").Value = InStr(1, vProfile(0), "Line Supervisor", vbTextCompare) = 1
    Variables("bRegulator%").Value = InStr(1, vProfile(0), "Traffic Regulator", vbTextCompare) = 1
    Variables("bMaintenance%").Value = InStr(1, vProfile(0), "Signal Maintenance Engineer", vbTextCompare) = 1
    Variables("bDepotRegulator%").Value = InStr(1, vProfile(0), "Depot Traffic Regulator", vbTextCompare) = 1
   
    ' Initialize variable to display the user name and profile
    ShowUserProfile

    EnableTopBannerButtons
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, ThisProject.ProjectName, "fvProject_UserChanged", Err.Description)
End Sub

Private Sub m_AskTerritory_ValueChange()
    Dim sTerritoryOPC As String
    On Error GoTo ErrorHandler
    
    UpdateRequestedPlugs m_AskTerritory
        
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, ThisProject.ProjectName, "m_AskTerritory_ValueChange", Err.Description)
End Sub

Private Sub m_LineControlRequest_ValueChange()
    Dim sBranch As String
    
    On Error GoTo ErrorHandler

    If [bStartingSystem%] Then Exit Sub

    If (m_LineControlRequest.Value <> 0) Then
        sBranch = Split(m_LineControlRequest.Name, ".")(0)
        'Mimics.Open("LineControl_Handover_Request",,,,,*,,
        Mimics.OpenInCenter "LineControl_Handover_Request", sBranch, , , , , , True
    End If

    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, ThisProject.ProjectName, "m_LineControlRequest_ValueChange", Err.Description)
End Sub


Private Sub m_OPC_UserReportLabelLV1_ValueChange()
    On Error GoTo ErrorHandler
    
    If m_OPC_UserReportLabelLV1 <> "_" Then
        If m_OPC_UserReportLabelLV1 <> [@LastUserReportLabelLV1%] Then
            [@UserReportLabel%] = m_OPC_UserReportLabelLV1
            [@LastUserReportLabelLV1%] = m_OPC_UserReportLabelLV1
        End If
    ElseIf m_OPC_UserReportLabelLV2 = "_" Then
        [@UserReportLabel%] = "_"
    End If
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, ThisProject.ProjectName, "m_OPC_UserReportLabelLV1_ValueChange", Err.Description)
End Sub

Private Sub m_OPC_UserReportLabelLV2_ValueChange()
    On Error GoTo ErrorHandler
    
    If m_OPC_UserReportLabelLV2 <> "_" Then
        If m_OPC_UserReportLabelLV2 <> [@LastUserReportLabelLV2%] Then
            [@UserReportLabel%] = m_OPC_UserReportLabelLV2
            [@LastUserReportLabelLV2%] = m_OPC_UserReportLabelLV2
        End If
    ElseIf m_OPC_UserReportLabelLV1 = "_" Then
        [@UserReportLabel%] = "_"
    End If
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, ThisProject.ProjectName, "m_OPC_UserReportLabelLV2_ValueChange", Err.Description)
End Sub

Private Sub m_Territory1_ControlledBy_ValueChange()
    IsControlledByMe m_Territory1_ControlledBy
End Sub

Private Sub m_Territory2_ControlledBy_ValueChange()
    IsControlledByMe m_Territory2_ControlledBy
End Sub

Private Sub m_Territory3_ControlledBy_ValueChange()
    IsControlledByMe m_Territory3_ControlledBy
End Sub

Private Sub m_Territory4_ControlledBy_ValueChange()
    IsControlledByMe m_Territory4_ControlledBy
End Sub

Private Sub m_Territory5_ControlledBy_ValueChange()
    IsControlledByMe m_Territory5_ControlledBy
End Sub

Private Sub m_Territory6_ControlledBy_ValueChange()
    IsControlledByMe m_Territory6_ControlledBy
End Sub


Public Sub OPC_LoggedUsers_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, ThisProject.ProjectName, "OPC_LoggedUsers_ValueChange", "Begin Subroutine")
    '* Check the status and the quality of the variable
    If ThisProject.OPC_LoggedUsers.Status = fvVariableStatusWaiting Then
        Call CBTrace(CBTRACE_VAR, ThisProject.ProjectName, "OPC_LoggedUsers_ValueChange", "The status of OPC_LoggedUsers is Waiting")
    ElseIf ThisProject.OPC_LoggedUsers.Status = fvVariableStatusConfigError Then
        Call CBTrace(CBTRACE_VAR, ThisProject.ProjectName, "OPC_LoggedUsers_ValueChange", "The status of OPC_LoggedUsers is Config Error")
    ElseIf ThisProject.OPC_LoggedUsers.Status = fvVariableStatusNotConnected Then
        Call CBTrace(CBTRACE_VAR, ThisProject.ProjectName, "OPC_LoggedUsers_ValueChange", "The status of OPC_LoggedUsers is Not Connected")
    ElseIf ThisProject.OPC_LoggedUsers.Quality <> 192 Then
        Call CBTrace(CBTRACE_VAR, ThisProject.ProjectName, "OPC_LoggedUsers_ValueChange", "The Quality of OPC_LoggedUsers is not good")
    Else
    '* Quality is good
    '* Update the Logged users in the Public variable to use Mod_LogON loop
    ThisProject.strLoggedUsers = ThisProject.OPC_LoggedUsers.Value
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, ThisProject.ProjectName, "OPC_LoggedUsers_ValueChange", Err.Description)
End Sub




Private Sub TIMER_HmiInOrder_Timer()
'CBTrace is removed since it is frequently called.
On Error GoTo ErrorHandler
    'CBTrace is removed since it will be called frequently.
    
    If iRouteSelectionTimerCount = -1 Then
        'DoNothing
        
    ElseIf (iRouteSelectionTimerCount > 5) Then
    
        iRouteSelectionTimerCount = -1
        MOD_RouteManager.ResetDestinationAnimation
    Else
        iRouteSelectionTimerCount = iRouteSelectionTimerCount + 1
    End If
    
Dim objMimic As Mimic
'    If Not Variables("WorkstationAlive%") Is Nothing Then
'        If Variables("WorkstationAlive%").Value = 0 Then
'            Variables("Red%").Value = 1
'            Variables("Blue%").Value = 0
'            Variables("Green%").Value = 0
'            Variables("WorkstationAlive%").Value = 1
'        ElseIf Variables("WorkstationAlive%").Value = 1 Then
'                Variables("Red%").Value = 0
'            Variables("Blue%").Value = 0
'            Variables("Green%").Value = 1
'            Variables("WorkstationAlive%").Value = 2
'        ElseIf Variables("WorkstationAlive%").Value = 2 Then
'            Variables("Red%").Value = 0
'            Variables("Blue%").Value = 1
'            Variables("Green%").Value = 0
'            Variables("WorkstationAlive%").Value = 0
'        End If
'    End If

   If Variables(Iconis_MOD_General.c_strVBAHeartBitLocalTag).Value = 7 Then
        Variables(Iconis_MOD_General.c_strVBAHeartBitLocalTag).Value = 1
    Else
        Variables(Iconis_MOD_General.c_strVBAHeartBitLocalTag).Value = Variables(Iconis_MOD_General.c_strVBAHeartBitLocalTag).Value + 1
    End If

    ' Close contextual menu mimics when clicking outside the mimic area
    For Each objMimic In Application.ActiveProject.Mimics
        If (objMimic.FileName Like "*_ContextualMenu*") Then
            If (ThisProject.ActiveMimic.FileName <> objMimic.FileName) Then
                If Not (objMimic.FileName Like "*TrainIndicator_ContextualMenu*") Then
                    objMimic.Close
                Else
                    If Not ((ThisProject.ActiveMimic.FileName Like "*TrainIndicator_RegulationControl_ContextualMenu*") Or (ThisProject.ActiveMimic.FileName Like "*TrainIndicator_IdentificationControl_ContextualMenu*")) Then
                        objMimic.Close
                    End If
                End If
            End If
        End If
    Next
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, ThisProject.ProjectName, "TIMER_HmiInOrder_Timer", Err.Description)
End Sub

Public Sub ConfigureTerritories()
    Dim iLoop As Integer, sClusterName As String
    
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, ThisProject.ProjectName, "ConfigureTerritories", "Begin Subroutine")
    
    sClusterName = GetOPCCluster

    For iLoop = 1 To 6
        Variables.Add sClusterName & "Territory_" & iLoop & ".TAS.AssignToOperator", fvVariableTypeText
        Variables.Add sClusterName & "Territory_" & iLoop & ".TAS.DeassignFromOperator", fvVariableTypeText
        Variables.Add sClusterName & "Territory_" & iLoop & ".TAS.GiveToOperator", fvVariableTypeText
        Variables.Add sClusterName & "Territory_" & iLoop & ".TAS.bControlledByMe%", fvVariableTypeText
    Next iLoop
        
    'Variables used to animate the Station buttons
    Set m_Territory1_ControlledBy = Variables.Add(sClusterName & "Territory_1.TAS.ControlledBy", fvVariableTypeText)
    Set m_Territory2_ControlledBy = Variables.Add(sClusterName & "Territory_2.TAS.ControlledBy", fvVariableTypeText)
    Set m_Territory3_ControlledBy = Variables.Add(sClusterName & "Territory_3.TAS.ControlledBy", fvVariableTypeText)
    Set m_Territory4_ControlledBy = Variables.Add(sClusterName & "Territory_4.TAS.ControlledBy", fvVariableTypeText)
    Set m_Territory5_ControlledBy = Variables.Add(sClusterName & "Territory_5.TAS.ControlledBy", fvVariableTypeText)
    Set m_Territory6_ControlledBy = Variables.Add(sClusterName & "Territory_6.TAS.ControlledBy", fvVariableTypeText)
    
    m_Territory1_ControlledBy.EnableEvents = True
    m_Territory2_ControlledBy.EnableEvents = True
    m_Territory3_ControlledBy.EnableEvents = True
    m_Territory4_ControlledBy.EnableEvents = True
    m_Territory5_ControlledBy.EnableEvents = True
    m_Territory6_ControlledBy.EnableEvents = True

    'Variable used to ask the territory for another user
    Set m_AskTerritory = Variables.Add(sClusterName & "AskTerritory.HMIRequest.Value.bstrValue", fvVariableTypeText)
    m_AskTerritory.EnableEvents = True
    

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, ThisProject.ProjectName, "ConfigureTerritories", Err.Description)
End Sub

















