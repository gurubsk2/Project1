Attribute VB_Name = "Iconis_MOD_Navigation"
'* Copyright, ALSTOM Transport Information Solutions, 2010. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* MODULE:      Iconis_CLS_Navigation
'* *******************************************************************************************
'* Purpose:     Manages a navigation system.
'*              A Navigation system seems to be a big complication for a CB Application,
'*              but it is MANDATORY if the regions need to be managed properly.
'*
'*              Services:
'*                  - "Navigate" to open a view
'*                  - "CloseView" to close a view
'*                  - "NotifyClosingView" to tell the navigation manager that a view is being
'*                  closed (use in the BeforeClose event)
'*                  - "SetLayers" to define the layers displayed in the views open (on all regions)
'*                  - "OpenPopup" to open a popup window in the current active region
'*              Other services:
'*                  - Managing a local OPC variable that can be catched for the application menu
'*                    The variable path is Iconis_MOD_Navigation.c_strNavigationNotificationLocalTag
'*                      The value sent is "<mimic filename>|<mimic branch>|<region>"
'*
'*              Note: the parameter to use in Client Builder functions is always the FILENAME:
'*                -    "/<library name>/<mimic filename>" (if the mimic belongs to a shared library)
'*                - or "<library name>/<mimic filename>" (if the mimic belongs to a project library)
'*                - or "<mimic filename>" (if the mimic belongs to the project)

'*              Developer's notes:
'*                  1) The public functions (Navigate, CloseView, NotifyClosingView) are high-level.
'*                   They shall not be called from the internal functions (declared as Private in this module)
'*                  2) Robustness:
'*                    a) every operation is tested on the internal data and on the CB mimics collection
'*                       - codes to manage the mimics and the views are never imbricated
'*                       - degraded case handled: one piece of information is missing
'*                    b) in every function accessible from outside this module, the VBA context is checked

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
Type typeMimicDescription
    strFilename As String
    StrBranch As String
End Type

Type typeRegionDescription
    ' Array of the open mimics, by order of appearance
    arrMimics() As typeMimicDescription
    ' Index of the navigation mimic, which is closed each time a new navigation view is open
    ' 0 if no navigation mimic open
    lNavigationMimic As Long
    ' Count in the array of mimics
    lCountMimics As Long
End Type


'* Constants
'* ------------------------------------------------------

' Location of the configuration file
Public Const c_sWorkspaceConfigFile As String = "\Config Files\paramws.dat"

' Name of the OPC tags
Public Const c_strLayersLocalTag As String = "HMI.Navigation.iLayers%"
Public Const c_strNavigationNotificationLocalTag As String = "HMI.Navigation.NavigateEvent%"
Public Const c_strTerritoriesToReleaseBeforeLogoff = "HMI.Navigation.TerritoriesToReleaseBeforeLogoff%"

'for automatic release when offline
Private Const c_strReleaseTag As String = ".TAS.DeAssignFromOperator"

' Default values for the description of the regions
Public Const c_lHorizontalResolution As Long = 1920
Public Const c_lVerticalResolution As Long = 1200
' Default values for the description of the navigation zone
Public Const c_lLeftNavigationView As Long = 0
Public Const c_lTopNavigationView As Long = 156

' Parameters for the navigation
' Number of regions
Dim m_iRegionsCount As Integer
' Width of a region (monitor's horizontal resolution)
Dim m_lRegionWidth As Long
' Coordinates of a navigation
Dim m_lLeftNavigationView As Long
Dim m_lTopNavigationView As Long
' Name of the default background mimic
Dim m_strDefaultNavigationMimic As String
Dim m_strDefaultNavigationBranch As String


'* Module variables
'* ------------------------------------------------------
' Description of each region
Dim m_arrRegion() As typeRegionDescription


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::Init
' Input:        none
' Output:       none
' Description:  Read the number of regions in the system
'-------------------------------------------------------------------------------
Public Sub Init()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "Init", "Begin Function")
    
    Dim strRegions As String
    Dim strPath As String
    Dim sRecord As String
    
    ' Default initialization
    m_iRegionsCount = 1
    ReDim m_arrRegion(0 To 0)
    
    ' Try to read the the configuration of the screen
    ' - in the file "Config Files\paramws.dat"
    ' - line to read: ScreenSystem,0,<horizontal regions count>,<vertical regions count>
    strPath = ThisProject.Path & c_sWorkspaceConfigFile
    
    Const ForReading = 1, ForWriting = 2, ForAppending = 3
    Const TristateUseDefault = -2, TristateTrue = -1, TristateFalse = 0
   
    Dim oFS As Object
    Dim oFile As Object
    Dim oStream As Object
    Dim I As Long

On Error GoTo ErrorFile
    Set oFS = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFS.GetFile(ThisProject.Path & c_sWorkspaceConfigFile)
    Set oStream = oFile.OpenAsTextStream(ForReading, TristateUseDefault)
    
    Do While Not oStream.AtEndOfStream
        sRecord = oStream.ReadLine
        If sRecord Like "ScreenSystem*" Then
            I = InStr(1, sRecord, ",")
            If I > 0 Then
                I = InStr(I + 1, sRecord, ",")
                If I > 0 Then
                    strRegions = Mid(sRecord, I + 1, 1)
                    m_iRegionsCount = CInt(strRegions)
                End If
            End If
            Exit Do
        End If
    Loop
    
    oStream.Close
    Set oStream = Nothing
    Set oFile = Nothing
    Set oFS = Nothing
    
ErrorFile:
    On Error GoTo ErrorHandler
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "Init", "Error during the initialization of the regions, while trying to read " & ThisProject.Path & c_sWorkspaceConfigFile)
    
    ' Prepare the number of regions
    ReDim m_arrRegion(1 To m_iRegionsCount)
    For I = 1 To m_iRegionsCount
        m_arrRegion(I).lNavigationMimic = -1
        m_arrRegion(I).lCountMimics = 0
    Next I
    m_lRegionWidth = Iconis_MOD_Win32API.GetHorizontalResolution() / m_iRegionsCount
    ' Default value in case of a problem
    If m_lRegionWidth = 0 Then
        m_lRegionWidth = c_lHorizontalResolution
    End If
    
    ' Default values for the navigation
    m_lLeftNavigationView = c_lLeftNavigationView
    m_lTopNavigationView = c_lTopNavigationView
    m_strDefaultNavigationMimic = ""

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "Init", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::CheckVBAContext
' Input:        none
' Output:       none
' Description:  Restore the VBA context if necessary
'               This ensures that a VBA context loss does not harm the function too much
'-------------------------------------------------------------------------------
Public Sub CheckVBAContext()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "CheckVBAContext", "Begin Function")
    
    If m_iRegionsCount = 0 Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "CheckVBAContext", "The VBA context was lost - reinitialization of the Navigation")
        Init
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "CheckVBAContext", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::Configure
' Input:        none
' Output:       none
' Description:  Configure the navigation system defaults
'-------------------------------------------------------------------------------
Public Sub Configure(Optional strDefaultNavigationMimic As String = "", _
                     Optional strDefaultNavigationBranch As String = "", _
                     Optional lLeftNavigationView As Long = c_lLeftNavigationView, _
                     Optional lTopNavigationView As Long = c_lTopNavigationView _
                     )
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "Init", "Begin Function")
    
    m_lLeftNavigationView = lLeftNavigationView
    m_lTopNavigationView = lTopNavigationView
    m_strDefaultNavigationMimic = strDefaultNavigationMimic
    m_strDefaultNavigationBranch = strDefaultNavigationBranch

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "Init", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::Navigate
' Input:        strFilename [String]        Name of the mimic
'               strBranch [String]          Branch to the mimic
'               iRegion [Integer]           Region where the mimic shall be open
'               bClosedByOperator [Boolean]
'                   True    The view will be closed by the operator
'                   False   This is a navigation view. It will be automatically
'                           closed if another navigation view is open.
' Output:       none
' Description:  Manage the navigation on each region
'-------------------------------------------------------------------------------
Public Sub Navigate(strFilename As String, StrBranch As String, iRegion As Integer, Optional bClosedByOperator As Boolean = False)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "Navigate", "Begin Function")
    
    Dim I As Long
    Dim iRegionAlreadyOpenView As Integer
    Dim bNavigation As Boolean
    Dim lNewNavigationIndex As Long
    
    ' Check VBA
    CheckVBAContext

    bNavigation = Not bClosedByOperator
    
    ' Is the view to open already in the current region?
    If GetViewIndex(strFilename, StrBranch, iRegion) <> -1 Then
        iRegionAlreadyOpenView = iRegion
    Else
        ' Is the view already displayed at the top in some region?
        iRegionAlreadyOpenView = WhereIsViewOnTop(strFilename, StrBranch, iRegion)
    End If

    If iRegionAlreadyOpenView > 0 Then
        ' Where is it opened?
        If iRegionAlreadyOpenView = iRegion Then
            ' The mimic is already opened in the same region

            ' If this is a navigation, close the current navigation view. Navigation means:
            ' - we are trying to open another Navigation View, i.e. (bClosedByOperator = False)
            ' - it is not the same view we want to open,
            If bNavigation And m_arrRegion(iRegion).lNavigationMimic <> GetViewIndex(strFilename, StrBranch, iRegion) Then
                Iconis_MOD_Navigation.CloseNavigationView iRegion
            End If
            ' Activate the View
            lNewNavigationIndex = Iconis_MOD_Navigation.SetTopMostView(strFilename, StrBranch, iRegion)

        Else
            ' The View is already opened, but in another region.
            If bNavigation Then
                ' In case of a navigation, switch the current view already in this region with the wanted view
                SwitchView strFilename, StrBranch, iRegionAlreadyOpenView, iRegion, True
            Else
                ' If this is not a navigation, grab the view
                SendViewToRegion strFilename, StrBranch, iRegionAlreadyOpenView, iRegion, False
            End If
            
            ' Make sure a default navigation view is open
            OpenDefaultNavigationView (iRegionAlreadyOpenView)

        End If
    Else
        ' The mimic is not yet opened
        ' In case of a navigation, close the current navigation mimic
        If bNavigation Then
            Iconis_MOD_Navigation.CloseNavigationView iRegion
        End If
        ' Open the view
        lNewNavigationIndex = Iconis_MOD_Navigation.OpenView(strFilename, StrBranch, iRegion)
    End If
    
    ' If it was a navigation, update the navigation mimic in the region
    If Not bClosedByOperator Then
        m_arrRegion(iRegion).lNavigationMimic = lNewNavigationIndex
    End If
    

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "Navigate", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::CloseView
' Input:        strFilename [String]    Name of the mimic
'               strBranch [String]      Branch to the mimic
'               iRegion [Integer]       Region where the mimic is opened
' Output:       none
' Description:  Close the view
'-------------------------------------------------------------------------------
Public Sub CloseView(strFilename As String, StrBranch As String, iRegion As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "CloseView", "Begin Function")
    
    ' Check VBA
    CheckVBAContext
    
    If Mimics.IsOpened(strFilename, StrBranch, , iRegion) Then
        ' Close the mimic
        Mimics(strFilename, StrBranch, , iRegion).Close fvDoNotSaveChanges
    
        ' Notify the Navigation
        NotifyClosingView strFilename, StrBranch, iRegion
        
        ' Make sure a default navigation view is open
        OpenDefaultNavigationView (iRegion)
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "CloseView", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::NotifyClosingView
' Input:        strFilename [String]        Name of the mimic closing
'               strBranch [String]          Branch
'               iRegion [Integer]           Region
' Output:       none
' Description:  Enable to indicate the Navigation system that a view is being closed
'-------------------------------------------------------------------------------
Public Sub NotifyClosingView(strFilename As String, StrBranch As String, iRegion As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "NotifyClosingView", "Begin Function")
    
    Dim I As Long
    Dim j As Long
    Dim lCount As Long
    
    ' Check VBA
    CheckVBAContext

    ' Loop to find the View that was closed
    lCount = m_arrRegion(iRegion).lCountMimics
    For I = 0 To lCount - 1
        If m_arrRegion(iRegion).arrMimics(I).strFilename = strFilename _
            And m_arrRegion(iRegion).arrMimics(I).StrBranch = StrBranch Then
            ' View found
            ' See if it was the navigation view
            If m_arrRegion(iRegion).lNavigationMimic = I Then
                m_arrRegion(iRegion).lNavigationMimic = -1
            End If
            ' Shift the list of mimics
            For j = I To lCount - 2
                m_arrRegion(iRegion).arrMimics(j) = m_arrRegion(iRegion).arrMimics(j + 1)
            Next j
            m_arrRegion(iRegion).lCountMimics = m_arrRegion(iRegion).lCountMimics - 1
            
            ' Job done
            Exit For
        End If
    Next I
    
    ' Send the navigation event
    lCount = m_arrRegion(iRegion).lCountMimics
    If lCount > 0 Then
        SendNavigationEvent m_arrRegion(iRegion).arrMimics(lCount - 1).strFilename, m_arrRegion(iRegion).arrMimics(lCount - 1).StrBranch, iRegion
    Else
        ' Make sure a view is open
        OpenDefaultNavigationView (iRegion)
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "NotifyClosingView", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::GetRegionsCount
' Input:        none
' Output:       [Integer]             Number of regions managed
' Description:  Get the number of regions
'-------------------------------------------------------------------------------
Public Function GetRegionsCount() As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "GetRegionsCount", "Begin Function")
    
    GetRegionsCount = m_iRegionsCount

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "GetRegionsCount", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::SetLayers
' Input:        lLayers     [Long]             Description of the layers
' Output:       none
' Description:  Set the layers for all regions
'-------------------------------------------------------------------------------
Public Function SetLayers(lLayers As Long)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "GetRegionsCount", "Begin Function")
    
    Dim iRegion As Integer
    Dim OPClocal_Layers As Variable

    For iRegion = 1 To m_iRegionsCount
        Dim currentMimic As Mimic

        ' Get the current mimic in the region
        With m_arrRegion(iRegion)
            Dim index As Long
            index = .lCountMimics - 1
        
            If index >= 0 Then
                ' Check the consistency of the data "arrMimics" by looking if the View is really opened
                If Mimics.IsOpened(.arrMimics(index).strFilename, m_arrRegion(iRegion).arrMimics(index).StrBranch, , iRegion) Then
                    ' OK, view is really open
                    Set currentMimic = Mimics(.arrMimics(index).strFilename, .arrMimics(index).StrBranch, , iRegion)
                Else
                    ' Inconsistent data: log an error and try to recover from error
                    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "SetLayers", _
                                 "The view " & .arrMimics(index).strFilename & " (" & .arrMimics(index).StrBranch & ") [" & iRegion & "] has been closed but the navigation system was not notified")
                    OpenView .arrMimics(index).strFilename, .arrMimics(index).StrBranch, iRegion
            
                    index = .lCountMimics - 1
                    If Mimics.IsOpened(.arrMimics(index).strFilename, m_arrRegion(iRegion).arrMimics(index).StrBranch, , iRegion) Then
                        Set currentMimic = Mimics(.arrMimics(index).strFilename, .arrMimics(index).StrBranch, , iRegion)
                    Else
                        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "SetLayers", _
                                 "Could not recover from error.")
                    End If
                End If
            End If
        End With

        ' Set the window's layers
        If Not currentMimic Is Nothing Then
            currentMimic.Windows(1).Layers = lLayers
        End If
    Next iRegion

    ' Store the representation of the layers in the variable
    Set OPClocal_Layers = Variables.Item(c_strLayersLocalTag)
    If OPClocal_Layers Is Nothing Then
        Set OPClocal_Layers = Variables.Add(c_strLayersLocalTag, fvVariableTypeRegister)
    End If
    OPClocal_Layers.Value = lLayers


Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "GetRegionsCount", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::OpenPopup
' Input:        strFilename [String]        Name of the mimic
'               strBranch [String]          Branch to the mimic
' Output:       [Long]                      Region where the popup window was open
' Description:  Display a popup in the current active region
'-------------------------------------------------------------------------------
Public Function OpenPopup(strFilename As String, StrBranch As String) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "OpenPopup", "Begin Function")
    
    Dim iRegion As Integer

    If Not ThisLibrary.Application.ActiveMimic Is Nothing Then
        iRegion = ThisLibrary.Application.ActiveMimic.Region
    Else
        iRegion = 1
    End If
    Mimics.OpenInCenter strFilename, StrBranch, , iRegion, , , , fvCenterOnRegion
    
    OpenPopup = iRegion

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "OpenPopup", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::WhereIsViewOnTop
' Input:        none
' Output:       [Integer]               0 if mimic not opened
'                                       else Region where the mimic is opened
' Description:  Get the region of the mimic
'-------------------------------------------------------------------------------
Private Function WhereIsViewOnTop(strFilename As String, StrBranch As String, iDefaultRegion As Integer) As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "WhereIsMimicOpened", "Begin Function")
    
    Dim iRegion As Integer

    WhereIsViewOnTop = 0
    
    ' First look for the view in the default region?
    Dim index As Long
    If IsViewOnTop(strFilename, StrBranch, iDefaultRegion) > -1 Then
        WhereIsViewOnTop = iDefaultRegion
    Else
        ' Then look for the mimic in other regions
        For iRegion = 1 To m_iRegionsCount
            If IsViewOnTop(strFilename, StrBranch, iRegion) > -1 Then
                WhereIsViewOnTop = iRegion
                Exit For
            End If
        Next iRegion
    End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "WhereIsViewOnTop", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::IsViewOnTop
' Input:        none
' Output:       [Integer]               0 if mimic not opened
'                                       else Region where the mimic is opened
' Description:  Get the region of the mimic
'-------------------------------------------------------------------------------
Private Function IsViewOnTop(strFilename As String, StrBranch As String, iRegion As Integer) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "WhereIsMimicOpened", "Begin Function")
    
    Dim lCount As Long
    Dim index As Long
    
    IsViewOnTop = -1

    index = m_arrRegion(iRegion).lCountMimics - 1
    If index >= 0 Then
        If m_arrRegion(iRegion).arrMimics(index).strFilename = strFilename _
               And m_arrRegion(iRegion).arrMimics(index).StrBranch = StrBranch Then

            ' Check the consistency of the data "arrMimics" by looking if the View is really opened
            If Mimics.IsOpened(strFilename, StrBranch, , iRegion) Then
                ' View is really open: Return the index
                IsViewOnTop = index
            Else
                ' Inconsistent data: log an error and clean
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "IsViewOnTop", _
                             "The view " & strFilename & " (" & StrBranch & ") [" & iRegion & "] has been closed but the navigation system was not notified")
                CloseViewIndex index, iRegion
                IsViewOnTop = -1
            End If
        End If
    End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "IsViewOnTop", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::GetNavigationViewMimic
' Input:        iRegion [Integer]   Region
' Output:       [Mimic]             Active mimic
' Description:  Get the active view in a region
'-------------------------------------------------------------------------------
Private Function GetNavigationViewMimic(iRegion As Integer) As Mimic
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "GetNavigationViewMimic", "Begin Function")
    
    Set GetNavigationViewMimic = Nothing

    With m_arrRegion(iRegion)
        If .lNavigationMimic <> -1 Then
            ' Check the consistency of the data "arrMimics" by looking if the View is really opened
            If Mimics.IsOpened(.arrMimics(.lNavigationMimic).strFilename, _
                               .arrMimics(.lNavigationMimic).StrBranch, _
                               , iRegion) Then
                Set GetNavigationViewMimic = Mimics(.arrMimics(.lNavigationMimic).strFilename, _
                                                    .arrMimics(.lNavigationMimic).StrBranch, _
                                                    , iRegion)
            Else
                ' Inconsistent data: log an error and clean
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "GetNavigationViewMimic", _
                             "The view " & .arrMimics(.lNavigationMimic).strFilename & " (" & .arrMimics(.lNavigationMimic).StrBranch & ") [" & iRegion & "] has been closed but the navigation system was not notified")
                CloseViewIndex .lNavigationMimic, iRegion
                Set GetNavigationViewMimic = Nothing
            End If
        End If
    End With

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "GetNavigationViewMimic", Err.Description)
End Function



'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::GetViewIndex
' Input:        iRegion [Integer]   Region
' Output:       [Long]              Index of the view in the region
'                                   -1 if not found
' Description:  Get the view index
'-------------------------------------------------------------------------------
Private Function GetViewIndex(strFilename As String, StrBranch As String, iRegion As Integer) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "GetViewIndex", "Begin Function")
    
    Dim I As Long
    
    GetViewIndex = -1
    
    ' Loop to find the View requested
    With m_arrRegion(iRegion)
        For I = 0 To .lCountMimics - 1
            If .arrMimics(I).strFilename = strFilename _
                And .arrMimics(I).StrBranch = StrBranch Then
                ' Check the consistency of the data "arrMimics" by looking if the View is really opened
                If Mimics.IsOpened(strFilename, StrBranch, , iRegion) Then
                    ' Return the index
                    GetViewIndex = I
                Else
                    ' Inconsistent data: log an error and clean
                    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "GetViewIndex", _
                                 "The view " & strFilename & " (" & StrBranch & ") [" & iRegion & "] has been closed but the navigation system was not notified")
                    CloseViewIndex I, iRegion
                    GetViewIndex = -1
                End If
                
                ' Search ended
                Exit For
            End If
        Next I
    End With
        

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "GetViewIndex", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::CloseView
' Input:        lIndex [Long]
'               iRegion [Integer]       Region where the mimic is opened
' Output:       none
' Description:  Close the view
'-------------------------------------------------------------------------------
Private Sub CloseViewIndex(lIndex As Long, iRegion As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "CloseView", "Begin Function")
    
    Dim j As Long
    Dim lCount As Long
    
    With m_arrRegion(iRegion)

        ' Close the mimic
        If Mimics.IsOpened(.arrMimics(lIndex).strFilename, .arrMimics(lIndex).StrBranch, , iRegion) Then
            Mimics(.arrMimics(lIndex).strFilename, .arrMimics(lIndex).StrBranch, , iRegion).Close fvDoNotSaveChanges
        End If
        
        ' We shift the list of mimics
        For j = lIndex To .lCountMimics - 2
            .arrMimics(j) = .arrMimics(j + 1)
        Next j
        .lCountMimics = .lCountMimics - 1
        
        ' Manage the navigation mimic index
        If .lNavigationMimic > lIndex Then
            .lNavigationMimic = .lNavigationMimic - 1
        ElseIf .lNavigationMimic = lIndex Then
            .lNavigationMimic = -1
        End If
        
        ' Send the navigation event
        If .lCountMimics > 1 Then
            SendNavigationEvent .arrMimics(.lCountMimics - 1).strFilename, .arrMimics(.lCountMimics - 1).StrBranch, iRegion
        Else
            SendNavigationEvent "", "", iRegion
        End If
    End With

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "CloseView", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::SwitchView
' Input:        strFilename [String]    Name of the mimic to put in target region
'               strBranch [String]      Branch to the mimic to put in target region
'               iOriginRegion [Integer] Region
'               iTargetRegion [Integer] Region
'               bNavigation [Boolean]   Whether this is a navigation in the target region
' Output:       none
' Description:  Get the wanted view in the target region, by swapping with the
'               top-level view in the origin region.
'-------------------------------------------------------------------------------
Private Function SwitchView(strFilename As String, StrBranch As String, iOriginRegion As Integer, iTargetRegion As Integer, bNavigation As Boolean) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "SwitchView", "Begin Function")
    
    Dim I As Long
    Dim j As Long
    Dim CurrentTargetView As typeMimicDescription
    Dim strViewFromTargetFilename As String
    Dim strViewFromTargetBranch As String
    Dim bViewFromTargetCausesNavigation As Boolean
    
    SwitchView = -1
    
    With m_arrRegion(iTargetRegion)
        If .lCountMimics - 1 > -1 Then
            strViewFromTargetFilename = .arrMimics(.lCountMimics - 1).strFilename
            strViewFromTargetBranch = .arrMimics(.lCountMimics - 1).StrBranch
            ' Means that the view in the target region is a navigation view
            bViewFromTargetCausesNavigation = (.lNavigationMimic = .lCountMimics - 1)
        Else
            strViewFromTargetFilename = ""
            strViewFromTargetBranch = ""
            bViewFromTargetCausesNavigation = False
        End If
    End With
    
    ' Lookup in the region of origin to find the View to transfer
    With m_arrRegion(iOriginRegion)
        ' Assumption: The view to transfer is at the top-level
        If .arrMimics(.lCountMimics - 1).strFilename = strFilename _
            And .arrMimics(.lCountMimics - 1).StrBranch = StrBranch Then
            ' Switch with the view at the top of the region of destination
            If strViewFromTargetFilename <> "" Then
                ' Is the view transferred causing a navigation?
                If bViewFromTargetCausesNavigation Then
                    ' Close the current navigation view in this region, if it is not the view replaced
                    If .lNavigationMimic <> .lCountMimics - 1 Then
                        CloseNavigationView iOriginRegion
                        ' The following check (made for robustness) is normally useless
                        If .lCountMimics - 1 > -1 Then
                            ' Set the navigation view (defined just after)
                            .lNavigationMimic = .lCountMimics - 1
                        End If
                    End If
                End If
                
                ' Replace the top-level view in this region
                With .arrMimics(.lCountMimics - 1)
                    .strFilename = strViewFromTargetFilename
                    .StrBranch = strViewFromTargetBranch
                End With

                ' Mimic region transfer
                Mimic_SendToRegion strViewFromTargetFilename, strViewFromTargetBranch, iTargetRegion, iOriginRegion
            Else
                If .lNavigationMimic = .lCountMimics - 1 Then
                    CloseNavigationView iOriginRegion
                Else
                    ' If no view to receive from the target region, the view is removed
                    .lCountMimics = .lCountMimics - 1
                End If
            End If
        End If
    End With

    ' Look in the region of destination
    With m_arrRegion(iTargetRegion)
        ' If no view was taken from the region of destination, a new view is added
        If strViewFromTargetFilename = "" Then
            ReDim Preserve .arrMimics(0 To .lCountMimics)
            .lCountMimics = .lCountMimics + 1
        End If

        ' If this is a navigation, the current navigation view shall be replaced
        If bNavigation Then
            ' Close the current navigation view in this region, if it is not the view replaced
            If .lNavigationMimic <> .lCountMimics - 1 Then
                CloseNavigationView iTargetRegion
                ' The following check (made for robustness) is normally useless
                If .lCountMimics - 1 > -1 Then
                    ' Set the navigation view (defined just after)
                    .lNavigationMimic = .lCountMimics - 1
                End If
            End If
        End If

        ' Replace the top-level view in this region
        With .arrMimics(.lCountMimics - 1)
            .strFilename = strFilename
            .StrBranch = StrBranch
        End With
        ' Return the index
        SwitchView = .lCountMimics - 1

        ' Mimic region transfer
        Mimic_SendToRegion strFilename, StrBranch, iOriginRegion, iTargetRegion

    End With

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "SwitchView", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::SendViewToRegion
' Input:        strFilename [String]    Name of the view
'               strBranch [String]      Branch to the view
'               iOriginRegion [Integer] Region where the view is
'               iTargetRegion [Integer] Region where the view shall be put
'               bNavigation [Boolean]   Whether this is a navigation in the target region
' Output:       none
' Description:  Send the view from a region to another. This becomes the navigation view
'               in the target region if required.
'-------------------------------------------------------------------------------
Private Function SendViewToRegion(strFilename As String, StrBranch As String, iOriginRegion As Integer, iTargetRegion As Integer, bNavigation As Boolean) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "SwitchView", "Begin Function")
    
    Dim I As Long
    Dim j As Long
    Dim CurrentTargetView As typeMimicDescription

    SendViewToRegion = -1
    
    ' Lookup in the region of origin to find the View to transfer
    With m_arrRegion(iOriginRegion)
        ' Assumption: The view to transfer is at the top-level
        If .arrMimics(.lCountMimics - 1).strFilename = strFilename _
            And .arrMimics(.lCountMimics - 1).StrBranch = StrBranch Then
            ' If the view is the navigation, close the current navigation
            If .lNavigationMimic = .lCountMimics - 1 Then
                .lNavigationMimic = -1
            End If
            ' Remove the view
            .lCountMimics = .lCountMimics - 1
        End If
    End With

    ' Look in the region of destination
    With m_arrRegion(iTargetRegion)
        ' If this is a navigation, replace the current navigation view
        If bNavigation Then
            CloseNavigationView iTargetRegion
        End If
        
        ' Put the view at the top of the region's current list of mimics
        ReDim Preserve .arrMimics(0 To .lCountMimics)
        With .arrMimics(.lCountMimics)
            .strFilename = strFilename
            .StrBranch = StrBranch
        End With
        .lCountMimics = .lCountMimics + 1
        
        ' Return the index
        SendViewToRegion = .lCountMimics - 1
        
        ' If this is a navigation, store the index
        If bNavigation Then
            .lNavigationMimic = .lCountMimics - 1
        End If
    End With
    
    ' Mimic region transfer
    Mimic_SendToRegion strFilename, StrBranch, iOriginRegion, iTargetRegion

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "SwitchView", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::CloseNavigationView
' Input:        iRegion [Integer]       Region
' Output:       none
' Description:  Close the current navigation view in the region
'-------------------------------------------------------------------------------
Private Function CloseNavigationView(iRegion As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "CloseNavigationView", "Begin Function")
    
    With m_arrRegion(iRegion)
        If .lNavigationMimic <> -1 Then
            CloseViewIndex .lNavigationMimic, iRegion
        End If
    End With

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "CloseNavigationView", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::OpenDefaultNavigationView
' Input:        iRegion [Integer]       Region
' Output:       none
' Description:  If the region is empty, open the default navigation view
'-------------------------------------------------------------------------------
Private Function OpenDefaultNavigationView(iRegion As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "OpenDefaultNavigationView", "Begin Function")
    
    With m_arrRegion(iRegion)
        If .lCountMimics = 0 Then
            If m_strDefaultNavigationMimic <> "" Then
                .lNavigationMimic = OpenView(m_strDefaultNavigationMimic, m_strDefaultNavigationBranch, iRegion)
            Else
                ' No default view, send an empty navigation event
                SendNavigationEvent "", "", iRegion
            End If
        End If
    End With

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "OpenDefaultNavigationView", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::OpenView
' Input:        strFilename [String]    Name of the mimic
'               strBranch [String]      Branch to the mimic
'               iRegion [Integer]       Region
' Output:       none
' Description:  Open a view in a region
'-------------------------------------------------------------------------------
Private Function OpenView(strFilename As String, StrBranch As String, iRegion As Integer) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "OpenView", "Begin Function")
    
    Dim lCount As Long
    Dim theMimic As Mimic

    OpenView = -1
    Set theMimic = OpenMimicAt(strFilename, StrBranch, iRegion, m_lLeftNavigationView, m_lTopNavigationView)
    
    ' Set the window's layers
    If Not Variables.Item(c_strLayersLocalTag) Is Nothing Then
        theMimic.Windows(1).Layers = Variables.Item(c_strLayersLocalTag)
    Else
        Dim OPClocal_Layers As Variable
        Set OPClocal_Layers = Variables.Add(c_strLayersLocalTag, fvVariableTypeRegister)
        OPClocal_Layers.Value = theMimic.Windows(1).Layers
    End If
    
    ' Put the view at the top of the region's current list of mimics
    lCount = m_arrRegion(iRegion).lCountMimics
    ReDim Preserve m_arrRegion(iRegion).arrMimics(0 To lCount)
    With m_arrRegion(iRegion).arrMimics(lCount)
        .strFilename = strFilename
        .StrBranch = StrBranch
    End With
    OpenView = lCount
    m_arrRegion(iRegion).lCountMimics = lCount + 1

    ' Send the navigation event
    SendNavigationEvent strFilename, StrBranch, iRegion

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "OpenView", Err.Description)
End Function





'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::SetTopMostView
' Input:        strFilename [String]    Name of the mimic
'               strBranch [String]      Branch to the mimic
'               iRegion [Integer]       Region where the mimic shall be activated
' Output:       none
' Description:  Activate the view in a region
'-------------------------------------------------------------------------------
Private Function SetTopMostView(strFilename As String, StrBranch As String, iRegion As Integer) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "SetTopMostView", "Begin Function")
    
    Dim I As Long
    Dim j As Long
    Dim lCount As Long
    
    ' Activate the window
    If Mimics.IsOpened(strFilename, StrBranch, , iRegion) Then
        Mimics(strFilename, StrBranch, , iRegion).Activate
    Else
        ' Inconsistent data: log an error and try to recover from error
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "SetTopMostView", _
                     "The view " & strFilename & " (" & StrBranch & ") [" & iRegion & "] has been closed but the navigation system was not notified")
        OpenView strFilename, StrBranch, iRegion
    End If

    ' Loop to find the View requested
    lCount = m_arrRegion(iRegion).lCountMimics
    For I = 0 To lCount - 1
        If m_arrRegion(iRegion).arrMimics(I).strFilename = strFilename _
            And m_arrRegion(iRegion).arrMimics(I).StrBranch = StrBranch Then
            ' View found, shift the list of mimics
            For j = I To lCount - 2
                m_arrRegion(iRegion).arrMimics(j) = m_arrRegion(iRegion).arrMimics(j + 1)
            Next j
            ' Now put the view at the top of the list
            m_arrRegion(iRegion).arrMimics(lCount - 1).strFilename = strFilename
            m_arrRegion(iRegion).arrMimics(lCount - 1).StrBranch = StrBranch
            ' Job done
            Exit For
        End If
    Next I

    ' Send the navigation event
    SendNavigationEvent strFilename, StrBranch, iRegion
    ' Return the index
    SetTopMostView = lCount - 1

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "SetTopMostView", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::SendNavigationEvent
' Input:        none
' Output:       none
' Description:  Set a local OPC variable that can be used to animate the menu of
'               the application
'               The variable path is c_strNavigationNotificationLocalTag
'               The value sent is "<mimic filename>|<mimic branch>|<region>"
'-------------------------------------------------------------------------------
Private Function SendNavigationEvent(strFilename As String, StrBranch As String, iRegion As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "SendNavigationEvent", "Begin Function")

    CBTrace CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "SendNavigationEvent", "Navigation to " & strFilename & " (" & StrBranch & ") [" & iRegion & "]"

    If Variables.Item(c_strNavigationNotificationLocalTag) Is Nothing Then
        Variables.Add c_strNavigationNotificationLocalTag, fvVariableTypeText
    End If
    Variables.Item(c_strNavigationNotificationLocalTag) = strFilename & "|" & StrBranch & "|" & CStr(iRegion)

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "SendNavigationEvent", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::OpenMimicAt
' Input:        strFilename [String]    Name of the mimic
'               strBranch [String]      Branch to the mimic
'               iRegion [Integer]       Region where the mimic shall be opened
'               lLeftPos [Long]         Left coordinate of the mimic
'               lTopPos [Long]          Top coordinate of the mimic
' Output:       none
' Description:  Open a mimic at the specified location
'-------------------------------------------------------------------------------
Public Function OpenMimicAt(strFilename As String, StrBranch As String, iRegion As Integer, lLeftPos As Long, lTopPos As Long) As Mimic
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "OpenMimicAt", "Begin Function")
    
    ' Check VBA
    CheckVBAContext

    ' Open the mimic
    Set OpenMimicAt = Mimics.Open(strFilename, StrBranch, , iRegion, , , , , lLeftPos, lTopPos, True)
    
    ' Adjust the mimic's window coordinates
    ' Sometimes, esp. when the view is scrolled, the open coordinates are wrong
    OpenMimicAt.Windows(1).Left = (iRegion - 1) * m_lRegionWidth + lLeftPos
    OpenMimicAt.Windows(1).Top = lTopPos

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "OpenMimicAt", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::CloseAllMimics
' Input:        none
' Output:       none
' Description:  Close all the opened mimics
'-------------------------------------------------------------------------------
Public Function CloseAllMimics()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "CloseAllMimics", "Begin Function")
    
    Dim objMimic As Mimic
    Dim iRegion As Integer
    
    ' Check VBA
    CheckVBAContext

    For Each objMimic In Application.ActiveProject.Mimics
        objMimic.Close
    Next
    
    For iRegion = 1 To m_iRegionsCount
        m_arrRegion(iRegion).lNavigationMimic = -1
        m_arrRegion(iRegion).lCountMimics = 0
    Next iRegion

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "CloseAllMimics", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::Mimic_SendToRegion
' Input:        strFilename [String]    Name of the mimic
'               strBranch [String]      Branch to the mimic
'               iOriginRegion [Integer] Region
'               iTargetRegion [Integer] Region
' Output:       none
' Description:  Change the region for a mimic
'-------------------------------------------------------------------------------
Private Function Mimic_SendToRegion(strFilename As String, StrBranch As String, iOriginRegion As Integer, iTargetRegion As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "Mimic_SendToRegion", "Begin Function")
    
    ' Close the mimic in the first region
    If Mimics.IsOpened(strFilename, StrBranch, , iOriginRegion) Then
        Mimics(strFilename, StrBranch, , iOriginRegion).Close
    End If
    ' Open the mimic in the new region
    Mimics.Open strFilename, StrBranch, , iTargetRegion
    
    ' Send the navigation event
    SendNavigationEvent strFilename, StrBranch, iTargetRegion

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "Mimic_SendToRegion", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Navigation::WhereIsMimicOpened
' Input:        none
' Output:       [Integer]               0 if mimic not opened
'                                       else Region where the mimic is opened
' Description:  Get the region of the mimic
'-------------------------------------------------------------------------------
Public Function Mimic_WhereIsOpened(strFilename As String, StrBranch As String, iDefaultRegion As Integer) As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Navigation", "Mimic_WhereIsOpened", "Begin Function")
    
    Dim iRegion As Integer

    ' Check VBA
    CheckVBAContext

    Mimic_WhereIsOpened = 0
    
    ' First test: is the mimic opened in the default region?
    If Mimics.IsOpened(strFilename, StrBranch, , iDefaultRegion) Then
        Mimic_WhereIsOpened = iDefaultRegion
    Else
        ' Look for the mimic in other regions
        For iRegion = 1 To m_iRegionsCount
            If Mimics.IsOpened(strFilename, StrBranch, , iRegion) Then
                Mimic_WhereIsOpened = iRegion
                Exit For
            End If
        Next iRegion
    End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Navigation", "Mimic_WhereIsOpened", Err.Description)
End Function


'* ******************************************************************************************
'*  SubRoutine: OpenForm
'*    Load the form to perform the log in function
'* ******************************************************************************************
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

'* ******************************************************************************************
'*  Function: Logoff
'*    Function the perform log off
'* ******************************************************************************************
Public Function Logoff(Optional bPerformLogoff As Boolean = True) As Boolean
    On Error GoTo ErrorHandler
   
        If bPerformLogoff Then
           Logoff = ThisProject.LogoffUser
           
        End If
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Navigation", "Logoff", Err.Description)
End Function



