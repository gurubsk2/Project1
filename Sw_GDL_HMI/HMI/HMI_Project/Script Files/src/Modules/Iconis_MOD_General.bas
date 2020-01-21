Attribute VB_Name = "Iconis_MOD_General"

'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Module:      Iconis_MOD_General
'* *******************************************************************************************
'* Purpose:     Utility class for the library IconisATSUrbalis
'*              It manages:
'*                  - the initialization of the framework
'*                  - the construction of objects (List, OPCSet)
'*                  - other services
'* *******************************************************************************************
'* Modification History:
'* Author:              Venkateshwar Vivek
'* Date:                January '14
'* Change:              Copied from Shared Library

'* Author:              Eric Foissey
'* Date:                April '14
'* Change:              CR atvcm533731 - Modification for code review

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION
'* *******************************************************************************************
Option Explicit

'* Types
'* ------------------------------------------------------
Type typeDepartureMode
    strID As String
    strMMGMode As String
    strParamID As String
End Type

Type typeTurnBack
    strID As String
    strMOPMode As String
    strParamID As String
End Type


'* Type to describe one boundary
Type BoundaryDescription
    ' ID
    strID As String
    ' UEID
    strUEID As String
    ' Name
    strName As String
    ' Block
    strBlock As String
    ' Destination
    strDestination As String
    ' Alias Name
    strAliasName As String
End Type

' Constants
' ------------------------------------------------------
' Version numbers
Const c_strHMIVersionLocalTag As String = "HMI.Configuration.HMIVersion%"
Const c_strICONISVersionLocalTag As String = "HMI.Configuration.IconisVersion%"
Const c_strCBVersionLocalTag As String = "HMI.Configuration.CBVersion%"

' Names
Const c_sS2KPatchPattern As String = "UninstallPatch"

' Name of keys of the [General] section (files .fvp and .fvl)
Public Const c_sCBINI_GeneralSection As String = "General"
Public Const c_sCBINI_VersionKey As String = "Version"
Public Const c_sCBINI_NameKey As String = "Name"

Public Const c_strUserNameLocalTag As String = "HMI.Security.UserName%"
Public Const c_strVBAHeartBitLocalTag As String = "HMI.HeartBit.Value%"
Public Const c_strUserProfileLocalTag As String = "UserProfile%"

' Module variables
' ------------------------------------------------------
Private m_UserRightsManager As Iconis_CLS_UserRights
Private m_AudibilityManager As Iconis_CLS_Audibility
'Private m_ServicePatternsManager As Iconis_CLS_ServicePatterns
Private m_PlatformsManager As Iconis_CLS_Platforms
Private m_Workzone_Manager As Iconis_CLS_WorkZones
Private m_Gama_Manager As Iconis_CLS_Gama
Private m_CalendarCommand_Manager As Iconis_CLS_CalendarCmd
Private m_TerminusModes_Manager As Iconis_CLS_TerminusMode
Private m_Signal_Manager As Iconis_CLS_Signals
Private m_TPInfoManager As Iconis_CLS_TPInfo_Manager
'Private m_RollingStocksManager As Iconis_CLS_RollingStocks
'Private m_DeviceCategoriesManager As Iconis_CLS_DeviceCategories
'Private m_RunningTimeTypesManager As Iconis_CLS_RunningTimeTypes
'Private m_RegulationModesManager As Iconis_CLS_RegulationModes
'Private m_RunningTypesManager As Iconis_CLS_RunningTypes
Private m_TerminusManager As Iconis_CLS_Terminus
Private m_TASManager As Iconis_CLS_TAS
'Private m_STAManager As Iconis_CLS_STA
'Private m_SectorisationManager As Iconis_CLS_Sectorisation
Private m_VersionsManager As Iconis_CLS_Versions
Private m_LineControl As CLS_LineControl
Private m_CommandSequence As GDL3_CLS_CST
Private m_BlockOverlapStatusManager As Iconis_CLS_BlockOverlap
' Name of the OPC Cluster (ATS server)
Private m_strOPCClusterName As String

'Public m_PlatformData() As PlatformData
'
' Type PlatformData
'    'Platform Name
'    strName As String
'    'Stopping Area Name
'    strStoppingAreaID As String
'End Type


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::Init
' Input:        none
' Output:       none
' Description:  Initialize the framework
'-------------------------------------------------------------------------------
Public Sub Init(Optional ByVal strOPCClusterName As String = "OPCCluster:")
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_General", "Init", "Begin Subroutine")
    
    m_strOPCClusterName = strOPCClusterName
    
    ' Create the local OPC variables
    Variables.Add c_strUserNameLocalTag, fvVariableTypeText
    Variables.Add c_strVBAHeartBitLocalTag, fvVariableTypeRegister
    Variables.Add c_strUserProfileLocalTag, fvVariableTypeText
    
' Obtain the version numbers and names
    GetVersionNumbersAndNames
    
    ' Obtain the number of regions
    Iconis_MOD_Navigation.Init

    'Enable the calendar command module
    Set m_CalendarCommand_Manager = New Iconis_CLS_CalendarCmd
    m_CalendarCommand_Manager.Init
    
    'Enable the TerminusModes module
    Set m_TerminusModes_Manager = New Iconis_CLS_TerminusMode
    
    'Enable the signals module
    Set m_Signal_Manager = New Iconis_CLS_Signals
    
    'Enable the workzones module
    Set m_Workzone_Manager = New Iconis_CLS_WorkZones
    m_Workzone_Manager.Init
    
    'Enable the Gama module
    Set m_Gama_Manager = New Iconis_CLS_Gama
    
    ' Enable the Platforms module
    Set m_PlatformsManager = New Iconis_CLS_Platforms

    ' Enable the TPInfo module
    Set m_TPInfoManager = New Iconis_CLS_TPInfo_Manager
            
    ' Enable the RollingStocks module
    'Set m_RollingStocksManager = New Iconis_CLS_RollingStocks
    
    ' Enable the DeviceCategories module
    'Set m_DeviceCategoriesManager = New Iconis_CLS_DeviceCategories
    
    ' Enable the RunningTimeTypes module
    'Set m_RunningTimeTypesManager = New Iconis_CLS_RunningTimeTypes

    ' Enable the RegulationModes module
    'Set m_RegulationModesManager = New Iconis_CLS_RegulationModes

    ' Enable the ServicePatterns module
   ' Set m_ServicePatternsManager = New Iconis_CLS_ServicePatterns
    
    ' Enable the RunningTypes module
    'Set m_RunningTypesManager = New Iconis_CLS_RunningTypes
    
    ' Enable the Terminus module
    Set m_TerminusManager = New Iconis_CLS_Terminus
    
    ' Enable the User Rights Management module
    Set m_UserRightsManager = New Iconis_CLS_UserRights
    
    ' Enable the Audibility module
    Set m_AudibilityManager = New Iconis_CLS_Audibility
    
    ' Enable the TAS module
    Set m_TASManager = New Iconis_CLS_TAS
    
    ' Enable the STA module
    'Set m_STAManager = New Iconis_CLS_STA
    
    ' Enable the Sectorisation module
    'Set m_SectorisationManager = New Iconis_CLS_Sectorisation
   
    ' Enable the Versions module
    Set m_VersionsManager = New Iconis_CLS_Versions

    ' Enable the HMI heartbit timer
'    ThisLibrary.InitTimer
      Set m_LineControl = New CLS_LineControl
    
    Set m_CommandSequence = New GDL3_CLS_CST
    
    Set m_BlockOverlapStatusManager = New Iconis_CLS_BlockOverlap
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_General", "Init", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetVersionNumbersAndNames
' Input:        none
' Output:       none
' Description:  Obtain the version number and the name for the project, the
'               system and subsystems (Library and Client Builder)
'-------------------------------------------------------------------------------
Public Sub GetVersionNumbersAndNames()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_General", "GetVersionNumbersAndNames", "Begin Subroutine")

    Dim sProjectPath As String
    
    ' Add the variables to be displayed in the About dialog box and
    ' in the "About" dialog box of the workstation ("Supervision" view)
    ' Version numbers
    Variables.Add c_strHMIVersionLocalTag, fvVariableTypeText
    Variables.Add c_strICONISVersionLocalTag, fvVariableTypeText
    Variables.Add c_strCBVersionLocalTag, fvVariableTypeText
    ' Names
 
    sProjectPath = ThisProject.Path & "\" & ThisProject.ProjectName & ".fvp"

    ' Read the version of the project
    ' from the key "Version" in the project's file (.fvp in the project's root)
    Variables.Item(c_strHMIVersionLocalTag).Value = Iconis_MOD_Win32API.Ini_Read(sProjectPath, c_sCBINI_GeneralSection, c_sCBINI_VersionKey)
    
    ' Subsystems -->
    ' Read the current version of the library
    ' from the library's file (.fvl in the Shared Libraries folder)
    Variables.Item(c_strICONISVersionLocalTag).Value = "-" 'Iconis_MOD_Win32API.Ini_Read(sLibraryPath, c_sCBINI_GeneralSection, c_sCBINI_VersionKey)
    
    ' Find the version of the S2K/Client Builder installed on the machine from the registry
    If Application.System.Version >= "6.0" Then
        ' Windows Seven
        Variables.Item(c_strCBVersionLocalTag).Value = CStr(Iconis_MOD_Win32API.WindowsRegistry_QueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\Wow6432Node\Alstom\ICONIS\S2K", "ProductVersion"))
    Else
        ' Windows XP
        Variables.Item(c_strCBVersionLocalTag).Value = CStr(Iconis_MOD_Win32API.WindowsRegistry_QueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\USDATA\S2K", "Version"))
    End If
   
    ' Find the version of the S2K/Client Builder patch installed on the machine from the directory hierarchy
    Dim sName As String
    Dim iS2KPatch As Integer
    Dim sS2KInstallationDirectory As String
    If Application.System.Version >= "6.0" Then
        ' Windows Seven
        sS2KInstallationDirectory = Application.Path & "\..\..\"
    Else
        ' Windows XP
        sS2KInstallationDirectory = Application.Path & "\..\..\..\"
    End If
    sName = Dir(sS2KInstallationDirectory, vbDirectory)    ' Retrieve the first entry.
    Do While sName <> ""    ' Start the loop.
        ' Ignore the current directory and the encompassing directory.
        If sName <> "." And sName <> ".." Then
            ' Use bitwise comparison to make sure MyName is a directory.
            If (GetAttr(sS2KInstallationDirectory & sName) And vbDirectory) = vbDirectory Then
                Dim pos As Long
                Dim pos2 As Long
                Dim patch As Integer
                pos = InStr(1, sName, c_sS2KPatchPattern)
                If pos > 0 Then
                    pos2 = InStr(pos, sName, "$")
                    patch = CLng(Mid(sName, pos + Len(c_sS2KPatchPattern), pos2 - pos - Len(c_sS2KPatchPattern)))
                    If patch > iS2KPatch Then
                        iS2KPatch = patch
                    End If
                End If
            End If    ' it represents a directory.
        End If
        sName = Dir    ' Get next entry.
    Loop

    ' Version of Client Builder, including the patch
    If iS2KPatch > 0 Then
        Variables.Item(c_strCBVersionLocalTag).Value = Variables.Item(c_strCBVersionLocalTag).Value & " SP" & CStr(iS2KPatch)
    End If
    
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_General", "GetVersionNumbersAndNames", Err.Description)
End Sub

'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::ParseCommandLine
' Input:        none
' Output:       none
' Description:  Manage the command line parameters
'               The command switch /playback asks to start the playback mimic
'---------------------------------------------------------------------------------------
Public Sub ParseCommandLine()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_General", "ParseCommandLine", "Begin Subroutine")
    
    Dim cmd() As String
    Dim subparam As String
    Dim subparams() As String
    Dim I As Long
    
    cmd = Iconis_MOD_Win32API.GetCommandLineParameters
    For I = 1 To UBound(cmd)
        Select Case StrConv(cmd(I), vbLowerCase)
            ' Run in playback mode
            Case "/playback"
                Mimics.Open "PlaybackMonitor", Iconis_MOD_General.GetOPCCluster()
            
            ' Non-documented switch: Logon at startup
            ' /user login#password
            Case "/user"
                If I + 1 <= UBound(cmd) Then
                    subparams = Split(cmd(I + 1), "#")
                    ReDim Preserve subparams(0 To 1)
                    ThisLibrary.Security.LogonUser False, subparams(0), subparams(1)
                    I = I + 1
                End If
            
            ' Non-documented switch: Open specific mimic at startup
            ' /mimic name#branch
            Case "/mimic"
                If I + 1 <= UBound(cmd) Then
                    subparams = Split(cmd(I + 1), "#")
                    ReDim Preserve subparams(0 To 1)
                    Iconis_MOD_Navigation.OpenMimicAt subparams(0), subparams(1), 1, c_lLeftNavigationView, c_lTopNavigationView
                    I = I + 1
                End If
            
            ' Non-documented switch: Open a view
            ' /navigate name#branch
            Case "/navigate"
                If I + 1 <= UBound(cmd) Then
                    subparams = Split(cmd(I + 1), "#")
                    ReDim Preserve subparams(0 To 1)
                    Iconis_MOD_Navigation.Navigate subparams(0), subparams(1), 1
                    I = I + 1
                End If
        
        End Select
    Next I

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_General", "ParseCommandLine", Err.Description)
End Sub

' Name:         Iconis_MOD_General::GetTASManager
' Input:        none
' Output:       [Iconis_CLS_TAS]   The TAS manager
' Description:  Returns the TAS Manager
'-------------------------------------------------------------------------------
Public Function GetTASManager() As Iconis_CLS_TAS
    Set GetTASManager = m_TASManager
End Function
'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetOPCCluster
' Input:        none
' Output:       [String]   The OPC Cluster
' Description:  Returns the OPC Cluster
'-------------------------------------------------------------------------------
Public Function GetOPCCluster() As String
    GetOPCCluster = m_strOPCClusterName
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::SetOPCCluster
' Input:        strOPCClusterName [String] The name of the OPC Cluster
' Output:       none
' Description:  Set the name of the OPC Cluster
'-------------------------------------------------------------------------------
Public Sub SetOPCCluster(ByVal strOPCClusterName As String)
    m_strOPCClusterName = strOPCClusterName
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetWorkzoneManager
' Input:        none
' Output:       [Iconis_CLS_WorkZones]   The workzone manager
' Description:  Returns the workzones Manager
'-------------------------------------------------------------------------------
Public Function GetWorkzoneManager() As Iconis_CLS_WorkZones
    Set GetWorkzoneManager = m_Workzone_Manager
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetGamaManager
' Input:        none
' Output:       [Iconis_CLS_Gama]   The Gama manager
' Description:  Returns the Gama Manager
'-------------------------------------------------------------------------------
Public Function GetGamaManager() As Iconis_CLS_Gama
    Set GetGamaManager = m_Gama_Manager
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetAudibilityManager
' Input:        none
' Output:       [Iconis_CLS_Audibility]   The Audibility manager
' Description:  Returns the Audibility Manager
'-------------------------------------------------------------------------------
Public Function GetAudibilityManager() As Iconis_CLS_Audibility
    Set GetAudibilityManager = m_AudibilityManager
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetUserRightsManager
' Input:        none
' Output:       [Iconis_CLS_UserRights]   The TAS manager
' Description:  Returns the TAS Manager
'-------------------------------------------------------------------------------
Public Function GetUserRightsManager() As Iconis_CLS_UserRights
    Set GetUserRightsManager = m_UserRightsManager
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetPlatformsManager
' Input:        none
' Output:       [Iconis_CLS_Platforms]   The Platforms manager
' Description:  Returns the Platforms Manager
'-------------------------------------------------------------------------------
Public Function GetPlatformsManager() As Iconis_CLS_Platforms
    Set GetPlatformsManager = m_PlatformsManager
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::CreateNew_Iconis_CLS_List
' Input:        none
' Output:       [Iconis_CLS_List]       The new instance
' Description:  Create and return a new instance of an Iconis_CLS_List
'-------------------------------------------------------------------------------
Public Function CreateNew_Iconis_CLS_List() As Iconis_CLS_List
    Set CreateNew_Iconis_CLS_List = New Iconis_CLS_List
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::CreateNew_Iconis_CLS_OPCSet
' Input:        none
' Output:       [Iconis_CLS_OPCSet]   The new instance
' Description:  Create and return a new instance of an Iconis_CLS_OPCSet
'-------------------------------------------------------------------------------
Public Function CreateNew_Iconis_CLS_OPCSet() As Iconis_CLS_OPCSet
    Set CreateNew_Iconis_CLS_OPCSet = New Iconis_CLS_OPCSet
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::AppendBranches
' Input:        strBranch1 [String] mother branch
'               strBranch2 [String] child branch
' Output:       [String]   Resulting branch
' Description:  Combines two OPC branches to return a new branch
'-------------------------------------------------------------------------------
Public Function AppendBranches(strBranch1 As String, strBranch2 As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_General", "AppendBranches", "Begin Subroutine")

    If (strBranch2 <> "*") Then
    
        Select Case Right(strBranch1, 1)
            Case "", ":", "."
                AppendBranches = strBranch1 & strBranch2
            Case Else
                Select Case Left(strBranch2, 1)
                    Case "", ":", "."
                        AppendBranches = strBranch1 & strBranch2
                    Case Else
                        AppendBranches = strBranch1 & "." & strBranch2
                End Select
        End Select
    Else
        AppendBranches = strBranch1
    End If
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_General", "AppendBranches", Err.Description)

End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetSymbolBranch
' Input:        theSymbol [Symbol] mother branch
' Output:       [String]   Branch
' Description:  Compute the relative branch of a symbol
'               even if it is nested within other symbols/groups/mimics
'-------------------------------------------------------------------------------
Public Function GetSymbolBranch(theSymbol As Symbol) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_General", "GetSymbolBranch", "Begin Subroutine")

    Dim MyParent As Object

    GetSymbolBranch = theSymbol.LocalBranch
    Set MyParent = theSymbol.Parent
    While TypeOf MyParent Is Symbol
        GetSymbolBranch = AppendBranches(MyParent.LocalBranch, GetSymbolBranch)
        Set MyParent = MyParent.Parent
    Wend
    GetSymbolBranch = AppendBranches(theSymbol.BranchContext, GetSymbolBranch)
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_General", "GetSymbolBranch", Err.Description)

End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetSymbolRegion
' Input:        theSymbol [Symbol] mother branch
' Output:       [String]   Branch
' Description:  Compute the relative branch of a symbol
'               even if it is nested within other symbols/mimics
'-------------------------------------------------------------------------------
Public Function GetSymbolRegion(theSymbol As Symbol) As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_General", "GetSymbolRegion", "Begin Subroutine")

    Dim MyParent As Object

    ' Default value
    GetSymbolRegion = 1
    ' Find the parent mimic
    Set MyParent = theSymbol.Parent
    While Not TypeOf MyParent Is Mimic
        Set MyParent = MyParent.Parent
    Wend
    GetSymbolRegion = MyParent.Region
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_General", "GetSymbolRegion", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetSymbolReferenceSet
' Input:        theSymbol [Symbol] mother branch
' Output:       [integer]   ReferenceSet
' Description:  retrieve the referenceSet associated with the mimic that contain the symbol
'-------------------------------------------------------------------------------
Public Function GetSymbolReferenceSet(theSymbol As Symbol) As fvRefSet
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_General", "GetSymbolReferenceSet", "Begin Subroutine")

    Dim MyParent As Object
    Dim MyMimic As Mimic
    
    ' Default value
    GetSymbolReferenceSet = 1
    ' Find the parent mimic
    Set MyParent = theSymbol.Parent
    While Not TypeOf MyParent Is Mimic
        Set MyParent = MyParent.Parent
    Wend
    Set MyMimic = MyParent
    
    GetSymbolReferenceSet = MyMimic.ReferenceSet
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_General", "GetSymbolReferenceSet", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetSymbolParentMimic
' Input:        theSymbol [Symbol] mother branch
' Output:       [integer]   ReferenceSet
' Description:  retrieve the referenceSet associated with the mimic that contain the symbol
'-------------------------------------------------------------------------------
Public Function GetSymbolParentMimic(theSymbol As Symbol) As Mimic
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_General", "GetSymbolParentMimic", "Begin Subroutine")

    Dim MyParent As Object
    Dim MyMimic As Mimic
    
    ' Default value
    ' Find the parent mimic
    Set MyParent = theSymbol.Parent
    While Not TypeOf MyParent Is Mimic
        Set MyParent = MyParent.Parent
    Wend
    Set MyMimic = MyParent
    
    Set GetSymbolParentMimic = MyMimic
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_General", "GetSymbolParentMimic", Err.Description)
End Function
''-------------------------------------------------------------------------------
'' Name:         Iconis_MOD_General::Getplatform
'' Description:  As per SPL comments we are converting platform data into like this reference CR atvcm01001013
'' Author:       Devaraj
'Public Sub GetPlatformDataFromXML()
'    On Error GoTo ErrorHandler
'    Call CBTrace(CBTRACE_VAR, "ThisMimic.Name", "GetPlatformDataFromXML", "Begin Subroutine")
'
'    Dim FileDocument As FileSystemObject
'    Dim strFilePath As String
'    Dim oDoc As DOMDocument
'    Dim iCounter As Integer
'
'    iCounter = 0
'
'    strFilePath = ThisProject.Path & "\Working Files\PlatformData.xml"
'
'    Set oDoc = New DOMDocument
'
'    Set FileDocument = New FileSystemObject
'
'    If FileDocument.FileExists(strFilePath) = True Then
'
'        oDoc.Load strFilePath
'
'        Dim oPlatformList As IXMLDOMNodeList
'        Dim oPlatform As IXMLDOMElement
'        Dim strCurrPlatformID As String
'
'        Set oPlatformList = oDoc.getElementsByTagName("Platform")
'
'        If (oPlatformList.length > 0) Then
'            ReDim m_PlatformData(oPlatformList.length - 1)
'            For Each oPlatform In oPlatformList
'                m_PlatformData(iCounter).strName = oPlatform.getAttribute("Name")
'                m_PlatformData(iCounter).strStoppingAreaID = oPlatform.getAttribute("Stopping_Area_ID")
'                iCounter = iCounter + 1
'            Next
'        End If
'    End If
'Exit Sub
'ErrorHandler:
'    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetPlatformDataFromXML", Err.Description)
'End Sub

'Public Function GetInterstoppingAreaName(strPFName As String) As String
'On Error GoTo ErrorHandler
'    Call CBTrace(CBTRACE_VAR, "ThisMimic.Name", "GetInterstoppingAreaName", "Begin Subroutine")
'    Dim iCounter As Long
'    iCounter = 0
'
'    For iCounter = 0 To UBound(m_PlatformData)
'        If (m_PlatformData(iCounter).strName = strPFName) Then
'            GetInterstoppingAreaName = m_PlatformData(iCounter).strStoppingAreaID
'        End If
'    Next
'    Exit Function
'ErrorHandler:
'    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetInterstoppingAreaName", Err.Description)
'End Function

'Public Function GetPlatformAreaName(strPFName As String) As String
'On Error GoTo ErrorHandler
'    Call CBTrace(CBTRACE_VAR, "ThisMimic.Name", "GetInterstoppingAreaName", "Begin Subroutine")
'    Dim iCounter As Long
'    iCounter = 0
'
'    For iCounter = 0 To UBound(m_PlatformData)
'        If (m_PlatformData(iCounter).strStoppingAreaID = strPFName) Then
'            GetPlatformAreaName = m_PlatformData(iCounter).strName
'        End If
'    Next
'    Exit Function
'ErrorHandler:
'    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetPlatformAreaName", Err.Description)
'End Function


