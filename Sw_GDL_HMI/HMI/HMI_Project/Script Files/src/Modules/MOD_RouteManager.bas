Attribute VB_Name = "MOD_RouteManager"
Option Explicit

'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2011. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* MODULE:  MOD_RouteManager
'* *******************************************************************************************
'* Purpose: Manages the funtions related with a route control
'* *******************************************************************************************
'* Requirements:
'* *******************************************************************************************
'* Authors:             Artur Valverde
'* Date:                Aug '11
'* *******************************************************************************************
'* *******************************************************************************************

'* Type of route
Public Const c_iNormalRoute As Integer = 1
Public Const c_iPermanentRoute As Integer = 2
Public Const c_iCallOnRoute As Integer = 3
Public Const c_strPermanentRoute As String = "1"
Public Const c_strCallOnRoute As String = "1"
Private Const c_strDestinationsTag As String = ".Destinations.Value"
Public m_strRouteCommandTag As String
Public m_iRouteCommandType As String
Public m_strSelectedOriginSignal As String
Public m_strCurrSelectedOriginSignal As String
Public m_strCurSelectedDestSignal As String
'* Route blocking
Public m_bRouteBlockingCmd As Boolean

Public Type m_OppositeSignal
    sID As String
    sName As String
    sRouteID As String
    sSignalID As String
End Type

Public Type m_Route
    SignalList() As m_OppositeSignal
End Type

Public m_Routes() As m_Route
Public m_DestinationList() As String
Public arrList_RoutesOPCTag() As String

'=======================================================================================
'=======================================================================================
'Procedures : ReadDestinations
'Type       : Sub
'Objective  : Read the XML string containing the list of destination signals
'Parameters : N/A
'Return     : N/A
'Obs        : The exception management will be realised into the AddCommandOPCVariable
'             function.
'=======================================================================================
' Rev       Date        Modified by       Description
'---------------------------------------------------------------------------------------
'  1     2011/08/11     Artur Valverde    Creation
'=======================================================================================
Public Function ReadDestinations(ByVal sDestinationsList As String)
    Dim xmlDoc              As DOMDocument
    Dim FirstNodeLevel      As IXMLDOMNodeList
    Dim oElementClass       As IXMLDOMElement
    Dim m_sPathSource       As String
    Dim iCounter            As Integer
    On Error GoTo ErrorHandler
    
    If sDestinationsList = "" Then Exit Function
     
    'Clear routes list variable
    ReDim m_Routes(3)
    ReDim m_Routes(c_iNormalRoute).SignalList(0)
    ReDim m_Routes(c_iPermanentRoute).SignalList(0)
    ReDim m_Routes(c_iCallOnRoute).SignalList(0)
    
    Set xmlDoc = New DOMDocument
    xmlDoc.loadXML sDestinationsList

    Set FirstNodeLevel = xmlDoc.documentElement.getElementsByTagName("Signal")
    ReDim m_DestinationList(FirstNodeLevel.length - 1) As String
    'Verify if there is a second string
    
    iCounter = 0
    For Each oElementClass In FirstNodeLevel
        If oElementClass.getAttribute("CallOn") = "1" Then
            'CallOnSignal
            If m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList)).sID <> "" Then _
                ReDim Preserve m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList) + 1)
            m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList)).sID = oElementClass.getAttribute("OppositeID")
            m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList)).sName = oElementClass.getAttribute("OppositeName")
            m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList)).sRouteID = oElementClass.getAttribute("RouteID")
            m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList)).sSignalID = oElementClass.getAttribute("ID")
        Else
            'NormalRouteSignal
            If m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList)).sID <> "" Then _
                ReDim Preserve m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList) + 1)
                
            m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList)).sID = oElementClass.getAttribute("OppositeID")
            m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList)).sName = oElementClass.getAttribute("OppositeName")
            m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList)).sRouteID = oElementClass.getAttribute("RouteID")
            m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList)).sSignalID = oElementClass.getAttribute("ID")
            If oElementClass.getAttribute("Auto") = "1" Then
                'AutoRouteSignal
                If m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList)).sID <> "" Then _
                    ReDim Preserve m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList) + 1)
                m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList)).sID = oElementClass.getAttribute("OppositeID")
                m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList)).sName = oElementClass.getAttribute("OppositeName")
                m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList)).sRouteID = oElementClass.getAttribute("RouteID")
                m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList)).sSignalID = oElementClass.getAttribute("ID")
            End If
        End If
        m_DestinationList(iCounter) = oElementClass.getAttribute("Name")
        
        iCounter = iCounter + 1
    Next oElementClass
    Exit Function
    
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_RouteManager", "ReadDestinations", Err.Description)
End Function


''=======================================================================================
''=======================================================================================
''Procedures : ReadSignalsDestination
''Type       : Sub
''Objective  : Read the XML string containing the list of destination signals
''Parameters : N/A
''Return     : N/A
''Obs        : The exception management will be realised into the AddCommandOPCVariable
''             function.
''=======================================================================================
'' Rev       Date        Modified by       Description
''---------------------------------------------------------------------------------------
''  1     2011/09/20     Artur Valverde    Creation
''=======================================================================================
'Public Function ReadSignalsDestination(ByVal sDestinationsList As String)
'    Dim xmlDoc              As DOMDocument
'    Dim FirstNodeLevel      As IXMLDOMNodeList
'    Dim oElementClass       As IXMLDOMElement
'    Dim m_sPathSource       As String
'
'    On Error GoTo ErrorHandler
'
'    If sDestinationsList = "" Then Exit Function
'
'    'Clear routes list variable
'    ReDim m_Routes(3)
'    ReDim m_Routes(c_iNormalRoute).SignalList(0)
'    ReDim m_Routes(c_iPermanentRoute).SignalList(0)
'    ReDim m_Routes(c_iCallOnRoute).SignalList(0)
'
'    Set xmlDoc = New DOMDocument
'    xmlDoc.loadXML sDestinationsList
'
'    Set FirstNodeLevel = xmlDoc.documentElement.getElementsByTagName("Signal")
'
'    'Verify if there is a second string
'    For Each oElementClass In FirstNodeLevel
'        If oElementClass.getAttribute("CallOn") = "1" Then
'            'CallOnSignal
'            If m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList)).sID <> "" Then _
'                ReDim Preserve m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList) + 1)
'            m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList)).sID = oElementClass.getAttribute("OppositeID")
'            m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList)).sName = oElementClass.getAttribute("OppositeName")
'            m_Routes(c_iCallOnRoute).SignalList(UBound(m_Routes(c_iCallOnRoute).SignalList)).sRouteID = oElementClass.getAttribute("RouteID")
'
'        Else
'            'NormalRouteSignal
'            If m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList)).sID <> "" Then _
'                ReDim Preserve m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList) + 1)
'            m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList)).sID = oElementClass.getAttribute("OppositeID")
'            m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList)).sName = oElementClass.getAttribute("OppositeName")
'            m_Routes(c_iNormalRoute).SignalList(UBound(m_Routes(c_iNormalRoute).SignalList)).sRouteID = oElementClass.getAttribute("RouteID")
'
'            If oElementClass.getAttribute("Auto") = "1" Then
'                'AutoRouteSignal
'                If m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList)).sID <> "" Then _
'                    ReDim Preserve m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList) + 1)
'                m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList)).sID = oElementClass.getAttribute("OppositeID")
'                m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList)).sName = oElementClass.getAttribute("OppositeName")
'                m_Routes(c_iPermanentRoute).SignalList(UBound(m_Routes(c_iPermanentRoute).SignalList)).sRouteID = oElementClass.getAttribute("RouteID")
'            End If
'        End If
'    Next oElementClass
'    Exit Function
'
'ErrorHandler:
'    Call CBTrace(CBTRACEF_ALWAYS, "MOD_RouteManager", "ReadDestinations", Err.Description)
'End Function


Public Function AddRouteVariables()
    Dim I As Integer, InputData As String, sOPCCluster As String
    I = 0
    
    On Error GoTo ErrorHandler
    
    Open ThisProject.Path & "\JAR Files\RouteList.txt" For Input As #1    ' Open file for input.

    Do While Not EOF(1)                    'Check for end of file.
        Line Input #1, InputData           'Read line of data.
        ReDim Preserve arrList_RoutesOPCTag(I)
        arrList_RoutesOPCTag(I) = InputData   'Print to the Immediate window.
        I = I + 1
    Loop
    Close #1    'Close file.
    
    sOPCCluster = GetOPCCluster
   
    For I = 0 To UBound(arrList_RoutesOPCTag)
        'Variables to Block/Unblock command
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".Blocking.Status.Value", fvVariableTypeRegister
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".Blocking.Value", fvVariableTypeRegister
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".Detection.Template.bIsOn", fvVariableTypeRegister
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".Automatic.Template.bIsOn", fvVariableTypeRegister
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".Destinations.Value", fvVariableTypeRegister
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".Detection.Template.Security", fvVariableTypeRegister
                
        'Variables for HMI Events
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".HMIEvent.User_NewEvent", fvVariableTypeRegister
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".HMIEvent.User_EventCustomMessage1", fvVariableTypeText
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".HMIEvent.User_EventLabel", fvVariableTypeText
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".HMIEvent.User_EventLabelML", fvVariableTypeText
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".HMIEvent.User_EventSeverity", fvVariableTypeRegister
        
        'Variables. for route set
        
        Variables.Add sOPCCluster & arrList_RoutesOPCTag(I) & ".Detection.Template.iCommand", fvVariableTypeRegister
    Next I

    Exit Function
    
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_RouteManager", "AddRouteVariables", Err.Description)

End Function

Public Sub ResetDestinationAnimation()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_RouteManager", "ResetDestinationAnimation", "Begin subroutine")
    
    Dim I As Integer
    
    'If (m_strCurAnimatedSignalBranch = "" Or m_strPrevAnimatedSignalBranch = m_strTobeAnimatedSignalBranch) Then Exit Sub
    
    If VerifyVariable(Variables.Add(m_strSelectedOriginSignal & c_strDestinationsTag, fvVariableTypeText)) Then
            Call ReadDestinations(Variables.Item(m_strSelectedOriginSignal & c_strDestinationsTag).Value)
            For I = LBound(m_DestinationList) To UBound(m_DestinationList)
                Variables.Item("OPCCluster:" & m_DestinationList(I) & ".DestinationSelectable%").Value = False
            Next I
    
    m_strSelectedOriginSignal = ""
    
    End If
    
Exit Sub
ErrorHandler:

    Call CBTrace(CBTRACEF_ALWAYS, "MOD_RouteManager", "ResetDestinationAnimation", Err.Description)
End Sub
