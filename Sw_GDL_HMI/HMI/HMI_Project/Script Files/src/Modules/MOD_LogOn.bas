Attribute VB_Name = "MOD_LogOn"
Option Explicit
Public WinUserName   As String

'**********************************************************************************
'* Purpose: Function to check User unique login
'**********************************************************************************
Public Function UserUnique(UserName As String) As Boolean
On Error GoTo ErrorHandler

'* Get the Updated String which has list of users
'* String will be in the format iconis:iconis|dev:PBK01|dev:PBK01;
'* Get the lastest value again for Logged Users
ThisProject.OPC_LoggedUsers_ValueChange
If ThisProject.strLoggedUsers <> "" Then
    arr = Split(ThisProject.strLoggedUsers, "|")
    For I = 0 To UBound(arr) - 1
        users = Split(arr(I), ":")
        '* Users(0) will hold HMI Login, Users(1) will hold Machine Name
        If (users(0) = UserName) Then
            '* Then the User already loggen in some machine.
            UserUnique = True
            ThisProject.strWKSName = users(1)
            Exit For
        Else
            UserUnique = False
        End If
    Next
Else
    UserUnique = False
End If
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Mod_Logon", "CloseDefaultMimics", Err.Description)
End Function

'**********************************************************************************
'* Purpose: Function to Check the User is appropriate for correct WKS
'* To Be updated whenever there is a new User
'**********************************************************************************
Public Function CorrectUser(UserName As String) As Boolean
On Error GoTo ErrorHandler
Dim strWKSName As String
Dim PathConfigFiles As String
Dim PathSource As String
Dim WorkStation As IXMLDOMNodeList
Dim WKSName As IXMLDOMNode
Dim WKSSite As IXMLDOMNode
Dim XUserName As IXMLDOMNode
Dim oDoc As New DOMDocument
Dim strComputerName As Variant
Dim bflag As Boolean
'* Read configuration file and fill Cbx_FromStation & cbx_ToStation combobox
PathConfigFiles = ThisProject.Path & "\Working Files\"
PathSource = PathConfigFiles & "WorkStation_HMI.xml"
oDoc.Load PathSource
Set FileDocument = New FileSystemObject
'* Check the User is appropriate for the WKS.
strWKSName = ThisSystem.ComputerName


If FileDocument.FileExists(PathSource) = True Then
    oDoc.Load PathSource
    Set WorkStation = oDoc.getElementsByTagName("WKSName")
    '* List Of WorkStations defined in the XML
    For Each WKSName In WorkStation
        strComputerName = WKSName.Attributes.Item(0).nodeValue
        '*Check with the Current Computer
        If strWKSName = strComputerName Then
            '* Update the WKS Location Either Central or Local from the XML file
            ThisProject.strWKSsite = WKSName.lastChild.nodeTypedValue
            
            For Each XUserName In WKSName.childNodes
                '* Check the UserLogged In
                If UserName = XUserName.nodeTypedValue Then
                    bflag = True
                    Exit For
                Else
                    bflag = False
                End If
            Next
        End If
    Next
Else
    '* A ByPass to Login any user in any computer, Delete the WorkStations_HMI.xml file from Work
    bflag = True
End If

CorrectUser = bflag

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Mod_Logon", "CloseDefaultMimics", Err.Description)
End Function

'* Function to be called when Function Key F2 is pressed
'*******************************************************
Public Sub LogonusingKey()
On Error GoTo ErrorHandler
Dim blogoff As Boolean
'If UserUnique <> True Then
    If ThisProject.Security.UserName = "Default" Then
        Mod_General.GetMonitors
        CloseAllMimics
        Mod_General.OpenDefaultMimics
    Else
        CloseDefaultMimics
        OpenLoginMimics
    End If

    ShowUserProfile
  
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Mod_Logon", "CloseDefaultMimics", Err.Description)
End Sub
'* Close the Welcome mimic...
'* ***************************************************************************************
Public Sub CloseDefaultMimics()
On Error GoTo ErrorHandler
    '* Monitor 1
    If (Mimics.IsOpened("TGL_Initialization_Layout")) Then
        Mimics.Item("TGL_Initialization_Layout").Close fvDoNotSaveChanges
    End If
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Mod_Logon", "CloseDefaultMimics", Err.Description)
End Sub

Public Sub OpenLoginMimics()
Dim WorkStationName As String
On Error GoTo ErrorHandler
'* Get the Workstation Station Name
Mod_General.GetWorkStationName
WorkStationName = ThisProject.WKSName

Mod_General.GetApplicationName
ApplicationName = ThisProject.APPName

OperationalMimic = "TGL_Operational_Mimic"
StationBanner = "TGL_Station_Banner"

'* Open the Mimics with respect to the monitors connected to the machine

    If Not (Mimics.IsOpened(OperationalMimic)) Then
        Mimics.Open OperationalMimic, , , , , , , , 0, 0, True
    End If
    
    If Not (Mimics.IsOpened(StationBanner)) Then
        Mimics.Open StationBanner, , , , , , , , 0, 100, True
    End If
   
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Mod_Logon", "OpenLoginMimics", Err.Description)
End Sub
'*  Function: CloseAllMimics
'* Closes all the currently opened mimics
'* ***************************************************************************************
Public Function CloseAllMimics()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_LogON", "CloseAllMimics", "Begin Function")
    
    Dim objMimic As Mimic
    For Each objMimic In Application.ActiveProject.Mimics
        objMimic.Close
    Next
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_LogON", "CloseAllMimics", Err.Description)
End Function
'* On successful logon show the user profile in the bottom banner User Profile
'* ***************************************************************************************
Public Function ShowUserProfile()
    Dim vProfiles  As Variant
    Dim sProfile As String
    
    On Error GoTo ErrorHandler
    
    Call CBTrace(CBTRACE_VBA, "Mod_Logon", "ShowUserProfile", "Begin Function")
    OpenUserView
    '* Show the User Profile/ Description in 1st Monitor
    If Variables.Item("@UserProfile%") Is Nothing Then Call Variables.Add("@UserProfile%", fvVariableTypeText)
    
    vProfiles = ThisProject.Security.users.GetProfiles(ThisProject.UserName)
    If IsArray(vProfiles) Then sProfile = vProfiles(0)
    Select Case sProfile
        Case "Line Supervisor", "SupervisorProfile"
            sProfile = "Supervisor de Linea"
        Case "Traffic Regulator"
            sProfile = "Regulador de Trafico"
        Case "Depot Traffic Regulator"
            sProfile = "Regulador de Trafico Talleres"
        Case "Signal Maintenance Engineer"
            sProfile = "Ingeniero de Mantenimiento de Senalizacion"
        Case "Personal Back Office Operation"
            sProfile = "Personal Back Office Operacion"
        Case "AdministrativeProfile"
            sProfile = "AdministrativeProfile"
    End Select
    Variables.Item("@UserProfile%").Value = ThisProject.UserName & " / " & sProfile
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Mod_Logon", "ShowUserProfile", Err.Description)
End Function


Public Sub OpenUserView()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_LogOn", "OpenUserView", "Begin Subroutine")
    
    Select Case ThisProject.UserName
        Case "administrator", "Dev", "Trainer", "T&C"
            ThisProject.ActiveKeyboardLayout = "GDL"
        Case Else
            ThisProject.ActiveKeyboardLayout = "GDL"
    End Select
    
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_LogOn", "OpenUserView", "KeyBoard Layout Set to " & ThisProject.ActiveKeyboardLayout _
                & " for the user " & ThisProject.UserName)
   Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_LogOn", "OpenUserView", Err.Description)
End Sub

Public Function OpenLoginusingKey()
'* Call Log On Module
On Error GoTo ErrorHandler
Call CBTrace(CBTRACEF_ALWAYS, "Nav_LogON", "Symbol_Click and Moving to Global Navigation Module", Err.Description)

  If (ThisProject.UserName <> "Default") Then
        '* Msg User already login
        MsgBox "The session is already opened. Please close the session", vbInformation, "Security - Log-on"
        'Unload Me
    Else
         MOD_Navigation.OpenForm ("LogON")
    End If
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_LogON", "CloseAllMimics", Err.Description)
End Function
Public Sub LoginWindowsuser()
On Error GoTo ErrorHandler
Dim fso  As FileSystemObject
Dim T As TextStream
Dim TextLine, strUser As String, strUserProfile As String
Dim LocalFound As Integer
Dim lResult As Long
Dim strDomainName As String

TextLine = ""
 WinUserName = ""
 WinUserName = Environ("username")
 strDomainName = WinUserName + " /domain"
Shell "C:\Windows\System32\cmd.exe /C net user " + strDomainName + " > groupname.txt", vbHide
Set fso = New Scripting.FileSystemObject
Set T = fso.OpenTextFile(ThisProject.Path & "\groupname.txt", ForReading)

Do While Not (T.AtEndOfStream Or LocalFound = 2) ' Loop until end of file.
    TextLine = T.ReadLine()
    If InStr(1, TextLine, "Local Group Memberships", vbTextCompare) > 0 Then
        LocalFound = 1
    ElseIf InStr(1, TextLine, "Global Group memberships", vbTextCompare) > 0 Then
        LocalFound = 2
    End If
    If LocalFound = 2 Then
        strUser = TextLine + strUser
    ElseIf LocalFound <> 1 And LocalFound <> 2 Then
        strUser = "None"
    End If
Loop

    If InStr(1, strUser, "Administrador", vbTextCompare) > 0 Then
        strUserProfile = "AdministrativeProfile"
    ElseIf InStr(1, strUser, "iconis", vbTextCompare) > 0 Then
        strUserProfile = "AdministrativeProfile"
    ElseIf InStr(1, strUser, "Supervisor de Linea", vbTextCompare) > 0 Then
        strUserProfile = "Line Supervisor"
    ElseIf InStr(1, strUser, "Regulador de Trafico", vbTextCompare) > 0 Then
        strUserProfile = "Traffic Regulator"
    ElseIf InStr(1, strUser, "Regulador de Trafico Talleres", vbTextCompare) > 0 Then
        strUserProfile = "Depot Traffic Regulator"
    ElseIf InStr(1, strUser, "Depot Traffic Regulat", vbTextCompare) > 0 Then
        strUserProfile = "Depot Traffic Regulator"
    ElseIf InStr(1, strUser, "Ingeniero de Mantenimiento de Senalizacion", vbTextCompare) > 0 Then
        strUserProfile = "Signal Maintenance Engineer"
    ElseIf InStr(1, strUser, "Ingeniero de Mantenimiento", vbTextCompare) > 0 Then
        strUserProfile = "Signal Maintenance Engineer"
    ElseIf InStr(1, strUser, "Personal Back Office Operacion", vbTextCompare) > 0 Then
        strUserProfile = "Personal Back Office Operation"
    ElseIf InStr(1, strUser, "None", vbTextCompare) > 0 Then
        strUserProfile = "Line Supervisor"
    Else
        strUserProfile = "Default"
    End If
    
    'Verify if the user exists already and remove
    strUser = ThisProject.Security.users.GetName(WinUserName)
    If strUser <> "" Then
        ThisProject.Security.users.Remove (WinUserName)
    End If
    
    'Add the user again
    lResult = ThisProject.Security.users.Add(WinUserName)
    'DoEvents
    If lResult Then
        ThisProject.Security.users.AddProfile WinUserName, strUserProfile
        ThisProject.Security.users.SetDescription WinUserName, strUserProfile
        ThisProject.Security.users.SetPresentationLocaleID WinUserName, 1033
        ThisProject.Security.users.SetProjectLocaleID WinUserName, 2058
        ThisProject.Security.users.SetDescription WinUserName, strUserProfile
        Call ThisProject.LogonUser(False, WinUserName)
    End If
    
   Set fso = Nothing
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ScreensManagement", "OpenViewOnSameScreen", Err.Description)
End Sub
''* *************************************************************
''*  Function: EnableBottomBannerButtons
''*  Enable/disable bottom banner buttons based on username
''* *************************************************************
Public Sub EnableTopBannerButtons()
    Dim vProfiles  As Variant
    Dim sProfile As String
    Dim str_User As String
    
    On Error GoTo ErrorHandler
    
    Call CBTrace(CBTRACE_VBA, "MOD_LogOn", "EnableTopButtons", "Begin Subroutine")
    
    vProfiles = ThisProject.Security.users.GetProfiles(ThisProject.UserName)
    If IsArray(vProfiles) Then sProfile = vProfiles(0)
    
    str_User = ""
    Call Variables.Add("@SystemViewButtonEnabled%")
    Call Variables.Add("@AlarmViewButtonEnabled%")
    Call Variables.Add("@EventViewButtonEnabled%")
    Call Variables.Add("@UsernoteButtonEnabled%")
    Call Variables.Add("@DisplayFilterButtonEnabled%")
    Call Variables.Add("@SystemHelpButtonEnabled%")
    Call Variables.Add("@GlobalControlsButtonEnabled%")
    Call Variables.Add("@OnlineTTButtonEnabled%")
    Call Variables.Add("@CommandSequnceEnabled%")
    Call Variables.Add("@ReportsButtonEnabled%")
    Call Variables.Add("@LineOperatingModeButtonEnabled%")
    Call Variables.Add("@CycleButtonEnabled%")
    Call Variables.Add("@LineControlModeEnabled%")
    Call Variables.Add("@StablingButtonEnabled%")
    Call Variables.Add("@TSRButtonEnabled%")
    Call Variables.Add("@TSGButtonEnabled%")
    Call Variables.Add("@CloseHMIButtonEnabled%")
    Call Variables.Add("@LogOffButtonEnabled%")
    
    
    Select Case sProfile
    
'        Case "TrafficRegulator", "Supervisor"
        Case "Traffic Regulator", "SupervisorProfile"
        
            Variables.Item("@SystemViewButtonEnabled%").Value = 1
            Variables.Item("@AlarmViewButtonEnabled%").Value = 1
            Variables.Item("@EventViewButtonEnabled%").Value = 1
            Variables.Item("@UsernoteButtonEnabled%").Value = 1
            Variables.Item("@DisplayFilterButtonEnabled%").Value = 1
            Variables.Item("@SystemHelpButtonEnabled%").Value = 1
            Variables.Item("@GlobalControlsButtonEnabled%").Value = 1
            Variables.Item("@OnlineTTButtonEnabled%").Value = 1
            Variables.Item("@CommandSequnceEnabled%").Value = 1
            Variables.Item("@ReportsButtonEnabled%").Value = 1
            Variables.Item("@LineOperatingModeButtonEnabled%").Value = 1
            Variables.Item("@CycleButtonEnabled%").Value = 1
            Variables.Item("@LineControlModeEnabled%").Value = 1
            Variables.Item("@StablingButtonEnabled%").Value = 0
            Variables.Item("@TSRButtonEnabled%").Value = 1
            Variables.Item("@TSGButtonEnabled%").Value = 1
            Variables.Item("@CloseHMIButtonEnabled%").Value = 0
            Variables.Item("@LogOffButtonEnabled%").Value = 1

'        Case "Maintenance"
        Case "Signal Maintenance Engineer"
           Variables.Item("@SystemViewButtonEnabled%").Value = 1
            Variables.Item("@AlarmViewButtonEnabled%").Value = 1
            Variables.Item("@EventViewButtonEnabled%").Value = 1
            Variables.Item("@UsernoteButtonEnabled%").Value = 1
            Variables.Item("@DisplayFilterButtonEnabled%").Value = 0
            Variables.Item("@GlobalControlsButtonEnabled%").Value = 0
            Variables.Item("@OnlineTTButtonEnabled%").Value = 0
            Variables.Item("@CommandSequnceEnabled%").Value = 0
            Variables.Item("@ReportsButtonEnabled%").Value = 0
            Variables.Item("@LineOperatingModeButtonEnabled%").Value = 0
            Variables.Item("@CycleButtonEnabled%").Value = 0
            Variables.Item("@LineControlModeEnabled%").Value = 1
            Variables.Item("@StablingButtonEnabled%").Value = 0
            Variables.Item("@TSRButtonEnabled%").Value = 0
            Variables.Item("@TSGButtonEnabled%").Value = 0
            Variables.Item("@CloseHMIButtonEnabled%").Value = 1
            Variables.Item("@LogOffButtonEnabled%").Value = 1
            Variables.Item("@SystemHelpButtonEnabled%").Value = 1
                        
'      Case "DepotTrafficRegulator"
      Case "Depot Traffic Regulator"
            Variables.Item("@SystemViewButtonEnabled%").Value = 1
            Variables.Item("@AlarmViewButtonEnabled%").Value = 1
            Variables.Item("@EventViewButtonEnabled%").Value = 1
            Variables.Item("@UsernoteButtonEnabled%").Value = 1
            Variables.Item("@DisplayFilterButtonEnabled%").Value = 1
            Variables.Item("@GlobalControlsButtonEnabled%").Value = 0
            Variables.Item("@OnlineTTButtonEnabled%").Value = 0
            Variables.Item("@CommandSequnceEnabled%").Value = 0
            Variables.Item("@ReportsButtonEnabled%").Value = 0
            Variables.Item("@LineOperatingModeButtonEnabled%").Value = 0
            Variables.Item("@CycleButtonEnabled%").Value = 0
            Variables.Item("@LineControlModeEnabled%").Value = 0
            Variables.Item("@StablingButtonEnabled%").Value = 1
            Variables.Item("@TSRButtonEnabled%").Value = 0
            Variables.Item("@TSGButtonEnabled%").Value = 0
            Variables.Item("@CloseHMIButtonEnabled%").Value = 0
            Variables.Item("@LogOffButtonEnabled%").Value = 1
            Variables.Item("@SystemHelpButtonEnabled%").Value = 1
        
                    
'        Case "Administrator"
        Case "AdministrativeProfile"
        
            Variables.Item("@SystemViewButtonEnabled%").Value = 1
            Variables.Item("@AlarmViewButtonEnabled%").Value = 1
            Variables.Item("@EventViewButtonEnabled%").Value = 1
            Variables.Item("@UsernoteButtonEnabled%").Value = 1
            Variables.Item("@DisplayFilterButtonEnabled%").Value = 1
            Variables.Item("@GlobalControlsButtonEnabled%").Value = 1
            Variables.Item("@OnlineTTButtonEnabled%").Value = 1
            Variables.Item("@CommandSequnceEnabled%").Value = 1
            Variables.Item("@ReportsButtonEnabled%").Value = 1
            Variables.Item("@LineOperatingModeButtonEnabled%").Value = 1
            Variables.Item("@CycleButtonEnabled%").Value = 1
            Variables.Item("@LineControlModeEnabled%").Value = 1
            Variables.Item("@StablingButtonEnabled%").Value = 1
            Variables.Item("@TSRButtonEnabled%").Value = 1
            Variables.Item("@CloseHMIButtonEnabled%").Value = 1
            Variables.Item("@TSGButtonEnabled%").Value = 1
            Variables.Item("@LogOffButtonEnabled%").Value = 1
            Variables.Item("@SystemHelpButtonEnabled%").Value = 1
        
'        Case "iconis"
        Case "Line Supervisor"
        
            Variables.Item("@SystemViewButtonEnabled%").Value = 1
            Variables.Item("@AlarmViewButtonEnabled%").Value = 1
            Variables.Item("@EventViewButtonEnabled%").Value = 1
            Variables.Item("@UsernoteButtonEnabled%").Value = 1
            Variables.Item("@DisplayFilterButtonEnabled%").Value = 1
            Variables.Item("@GlobalControlsButtonEnabled%").Value = 1
            Variables.Item("@OnlineTTButtonEnabled%").Value = 1
            Variables.Item("@CommandSequnceEnabled%").Value = 1
            Variables.Item("@ReportsButtonEnabled%").Value = 1
            Variables.Item("@LineOperatingModeButtonEnabled%").Value = 1
            Variables.Item("@CycleButtonEnabled%").Value = 1
            Variables.Item("@LineControlModeEnabled%").Value = 1
            Variables.Item("@StablingButtonEnabled%").Value = 1
            Variables.Item("@TSRButtonEnabled%").Value = 1
            Variables.Item("@CloseHMIButtonEnabled%").Value = 1
            Variables.Item("@TSGButtonEnabled%").Value = 1
            Variables.Item("@LogOffButtonEnabled%").Value = 1
            Variables.Item("@SystemHelpButtonEnabled%").Value = 1
            
        Case "Default"
             Variables.Item("@SystemViewButtonEnabled%").Value = 1
            Variables.Item("@AlarmViewButtonEnabled%").Value = 1
            Variables.Item("@EventViewButtonEnabled%").Value = 1
            Variables.Item("@UsernoteButtonEnabled%").Value = 1
            Variables.Item("@DisplayFilterButtonEnabled%").Value = 1
            Variables.Item("@GlobalControlsButtonEnabled%").Value = 1
            Variables.Item("@OnlineTTButtonEnabled%").Value = 1
            Variables.Item("@CommandSequnceEnabled%").Value = 1
            Variables.Item("@ReportsButtonEnabled%").Value = 1
            Variables.Item("@LineOperatingModeButtonEnabled%").Value = 1
            Variables.Item("@CycleButtonEnabled%").Value = 1
            Variables.Item("@LineControlModeEnabled%").Value = 1
            Variables.Item("@StablingButtonEnabled%").Value = 1
            Variables.Item("@TSRButtonEnabled%").Value = 1
            Variables.Item("@CloseHMIButtonEnabled%").Value = 1
            Variables.Item("@TSGButtonEnabled%").Value = 1
            Variables.Item("@LogOffButtonEnabled%").Value = 1
            Variables.Item("@SystemHelpButtonEnabled%").Value = 1
        
         
        
        Case Else
        
            Variables.Item("@SystemViewButtonEnabled%").Value = 0
            Variables.Item("@AlarmViewButtonEnabled%").Value = 0
            Variables.Item("@EventViewButtonEnabled%").Value = 0
            Variables.Item("@UsernoteButtonEnabled%").Value = 0
            Variables.Item("@DisplayFilterButtonEnabled%").Value = 0
            Variables.Item("@GlobalControlsButtonEnabled%").Value = 0
            Variables.Item("@OnlineTTButtonEnabled%").Value = 0
            Variables.Item("@CommandSequnceEnabled%").Value = 0
            Variables.Item("@ReportsButtonEnabled%").Value = 0
            Variables.Item("@LineOperatingModeButtonEnabled%").Value = 0
            Variables.Item("@CycleButtonEnabled%").Value = 0
            Variables.Item("@LineControlModeEnabled%").Value = 0
            Variables.Item("@StablingButtonEnabled%").Value = 0
            Variables.Item("@TSRButtonEnabled%").Value = 0
            Variables.Item("@CloseHMIButtonEnabled%").Value = 0
            Variables.Item("@LogOffButtonEnabled%").Value = 0
            Variables.Item("@SystemHelpButtonEnabled%").Value = 0
            Variables.Item("@TSGButtonEnabled%").Value = 0
    End Select
   
    If ((LCase(ThisSystem.ComputerName) Like "*_lats")) Then
        Variables.Item("@LineOperatingModeButtonEnabled%").Value = 0
        Variables.Item("@CommandSequnceEnabled%").Value = 0
        Variables.Item("@ReportsButtonEnabled%").Value = 0
        Variables.Item("@OnlineTTButtonEnabled%").Value = 0
        Variables.Item("@TSGButtonEnabled%").Value = 0
        
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_LogON", "EnableBottomBannerButtons", Err.Description)
End Sub
