VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_TerminusMode"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_TerminusMode
'* *******************************************************************************************
'* Purpose: Manages the definitions used for Terminus Mode - provide the function to extract
'* terminus modes list and other parameters related to the Terminus Mode
'* *******************************************************************************************
'* Modification History:
'* Author:              Eric FOISSEY
'* Date:                March '13
'* Change:              All - CR ALPHA 338780
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

'* Types
'* ------------------------------------------------------

Private Type typeTerminusMode
    strID As String
    strName As String
    bIsProvisionnal As Boolean
    bHasTTTripSource As Boolean
    strDefault_Departure_ModeID As String
    strDefault_Turnback_ModeID As String
    strDefault_Regulation_Strategy_ModeID As String
    
    AvailableDepartureMode() As typeDepartureMode
    AvailableTurnback() As typeTurnBack
End Type
' Constants
' ------------------------------------------------------
Private Const c_strTerminusSeparator As String = ";"

'used to read the terminus mode list
Private Const c_strTerminusModeListTag As String = "IconisHMI.TerminusModeList.Value"
Private Const c_strTerminusModeNode As String = "TerminusMode"
Private Const c_strDeparture_ModeNode As String = "Departure_Mode"
Private Const c_strTurnbackNode As String = "Turnback"

'used to read the attribute
Private Const c_strTerminusModeIDAttr As String = "ID"
Private Const c_strTeminusModeNameAttr As String = "Name"
Private Const c_strIsProvisionnalAttr As String = "Disabled_In_Provisionnal_Context"
Private Const c_strTripSourceAttr As String = "Trips_Source"
Private Const c_strDefaultDepartureModeAttr As String = "Default_Departure_ModeID"
Private Const c_strDefaultTurnbackAttr As String = "Default_Turnback_ModeID"
Private Const c_strDefaultRegulationStrategyAttr As String = "Default_Regulation_Strategy_ModeID"

Private Const c_strDepartureModeIDAttr As String = "ID"
Private Const c_strDepartureMMGModeAttr As String = "MMGMode"
Private Const c_strDepartureParamIDAttr As String = "ParamID"

Private Const c_strTurnbackIDAttr As String = "ID"
Private Const c_strTurnbackMOPModeAttr As String = "MOPMode"
Private Const c_strTurnbackParamIDAttr As String = "ParamID"

'* Constant associated to the terminus mode context
Private Const c_iNominalContextMode As Integer = 0      '* Nominal Context
Private Const c_iProvisionnalContextMode As Integer = 1 '* Provisional Context
Private Const c_iUnknownContextMode As Integer = 2      '* unknown Context

' Class attributes
' ------------------------------------------------------
' list of Terminus Mode read in the XML
Private TerminusModeList() As typeTerminusMode


' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------
' OPC variable containing the list of the Terminus mode
Private WithEvents m_OPC_XML_TerminusModeList As Variable
Attribute m_OPC_XML_TerminusModeList.VB_VarHelpID = -1



'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::Class_Initialize
' Input:        none
' Output:       none
' Description:  Init variables, create dictionnaries
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "Class_Initialize", "Begin Subroutine")

    ReDim TerminusModeList(0)
    
    ' Add OPC variable containing the list of terminus mode
    Set m_OPC_XML_TerminusModeList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strTerminusModeListTag, fvVariableTypeText)
    If (m_OPC_XML_TerminusModeList.EnableEvents = True) Then
        m_OPC_XML_TerminusModeList_ValueChange
    Else
        m_OPC_XML_TerminusModeList.EnableEvents = True
    End If
Exit Sub

ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "Class_Initialize", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "Class_Terminate", "Begin Subroutine")
    
    ' Empty the data lists
    ReDim TerminusModeList(0)
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_TerminusModeList Is Nothing) Then
        Variables.Remove (m_OPC_XML_TerminusModeList.Name)
        Set m_OPC_XML_TerminusModeList = Nothing
    End If
    
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "Class_Terminate", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::m_OPC_XML_TerminusModeList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of block definitions
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_TerminusModeList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TerminusMode", "m_OPC_XML_TerminusModeList_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_TerminusModeList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "m_OPC_XML_TerminusModeList_ValueChange", "The status of " & m_OPC_XML_TerminusModeList.Name & " is Waiting")
    ElseIf (m_OPC_XML_TerminusModeList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "m_OPC_XML_TerminusModeList_ValueChange", "The status of " & m_OPC_XML_TerminusModeList.Name & " is Config Error")
    ElseIf (m_OPC_XML_TerminusModeList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TerminusMode", "m_OPC_XML_TerminusModeList_ValueChange", "The status of " & m_OPC_XML_TerminusModeList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_TerminusModeList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TerminusMode", "m_OPC_XML_TerminusModeList_ValueChange", "The Quality of " & m_OPC_XML_TerminusModeList.Name & " is not good")
    Else
       ' Read the string
        ReadXMLTerminusModeString
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "m_OPC_XML_BlockList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::ReadXMLTerminusModeString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of blocks
'-------------------------------------------------------------------------------
Private Sub ReadXMLTerminusModeString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "ReadXMLTerminusModeString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oTerminusModeList As IXMLDOMNodeList
   Dim oTerminusMode As IXMLDOMElement
   Dim oDepartureModeList As IXMLDOMNodeList
   Dim oDepartureMode As IXMLDOMElement
   Dim oTurnbackList As IXMLDOMNodeList
   Dim oTurnback As IXMLDOMElement
   
   Dim I As Integer
   Dim j As Integer

   strXMLString = m_OPC_XML_TerminusModeList.Value
   
   ' Empty the list
   ReDim TerminusModeList(0)
    
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "TerminusMode"
                    Set oTerminusModeList = oDoc.documentElement.getElementsByTagName(c_strTerminusModeNode)
                    If Not (oTerminusModeList Is Nothing) Then
                        If (oTerminusModeList.length > 0) Then
                            ReDim TerminusModeList(oTerminusModeList.length - 1)
                            
                            I = 0
                            For Each oTerminusMode In oTerminusModeList
                                ' read the attributes
                                TerminusModeList(I).strID = oTerminusMode.getAttribute(c_strTerminusModeIDAttr)
                                TerminusModeList(I).strName = oTerminusMode.getAttribute(c_strTeminusModeNameAttr)
                                TerminusModeList(I).bIsProvisionnal = (Val(oTerminusMode.getAttribute(c_strIsProvisionnalAttr)) = 0)     'if 0, then should appear in provisionnal context
                                TerminusModeList(I).bHasTTTripSource = (Val(oTerminusMode.getAttribute(c_strTripSourceAttr)) = 1)   'if 1, then trip source uses TimeTables
                                TerminusModeList(I).strDefault_Departure_ModeID = oTerminusMode.getAttribute(c_strDefaultDepartureModeAttr)
                                TerminusModeList(I).strDefault_Turnback_ModeID = oTerminusMode.getAttribute(c_strDefaultTurnbackAttr)
                                TerminusModeList(I).strDefault_Regulation_Strategy_ModeID = oTerminusMode.getAttribute(c_strDefaultRegulationStrategyAttr)
                                 
                                Set oDepartureModeList = oTerminusMode.getElementsByTagName(c_strDeparture_ModeNode)
                                
                                ReDim TerminusModeList(I).AvailableDepartureMode(oDepartureModeList.length - 1)
                                j = 0
                                For Each oDepartureMode In oDepartureModeList
                                    ' read the attributes
                                    TerminusModeList(I).AvailableDepartureMode(j).strID = oDepartureMode.getAttribute(c_strDepartureModeIDAttr)
                                    TerminusModeList(I).AvailableDepartureMode(j).strMMGMode = oDepartureMode.getAttribute(c_strDepartureMMGModeAttr)
                                    TerminusModeList(I).AvailableDepartureMode(j).strParamID = oDepartureMode.getAttribute(c_strDepartureParamIDAttr)
                                    
                                    j = j + 1
                                Next oDepartureMode
                                Set oDepartureModeList = Nothing
                                
                                Set oTurnbackList = oTerminusMode.getElementsByTagName(c_strTurnbackNode)
                                ReDim TerminusModeList(I).AvailableTurnback(oTurnbackList.length - 1)
                                j = 0
                                For Each oTurnback In oTurnbackList
                                    ' read the attributes
                                    TerminusModeList(I).AvailableTurnback(j).strID = oTurnback.getAttribute(c_strTurnbackIDAttr)
                                    TerminusModeList(I).AvailableTurnback(j).strMOPMode = oTurnback.getAttribute(c_strTurnbackMOPModeAttr)
                                    TerminusModeList(I).AvailableTurnback(j).strParamID = oTurnback.getAttribute(c_strTurnbackParamIDAttr)
                                    
                                    j = j + 1
                                Next oTurnback
                                Set oTurnbackList = Nothing
                                
                                I = I + 1
                            Next oTerminusMode
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "ReadXMLTerminusModeString", _
                                         "No Terminus Modes has been defined in the OPC variable [" & m_OPC_XML_TerminusModeList.Name & "]")
                        End If
                        Set oTerminusModeList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "ReadXMLTerminusModeString", _
                             "The content of the OPC variable [" & m_OPC_XML_TerminusModeList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "ReadXMLTerminusModeString", _
                     "The OPC variable [" & m_OPC_XML_TerminusModeList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "ReadXMLTerminusModeString", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::GetModeList
' Input:        [boolean] IsProvisionnal indicator if list of provisionnal terminus list is needed
'               [boolean] TTLoaded indicator if a TimeTable is loaded
' Output:       [String()] list of names of the terminus mode
' Description:  Returns the list of names of the terminus mode for the current context
'-------------------------------------------------------------------------------
Public Function GetModeList(ByVal IsProvisionnal As Boolean, ByVal TTLoaded As Boolean) As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "GetModeList", "Begin Function")
    
    Dim TerminusResult As String
    Dim I As Integer
    
    TerminusResult = ""
    
    For I = 0 To UBound(TerminusModeList)
        If (TerminusModeList(I).bIsProvisionnal = IsProvisionnal) Then
            If ((TTLoaded = True) Or (TerminusModeList(I).bHasTTTripSource = False)) Then
                If (TerminusResult = "") Then
                    TerminusResult = TerminusModeList(I).strName
                Else
                    TerminusResult = TerminusResult + c_strTerminusSeparator + TerminusModeList(I).strName
                End If
            End If
        End If
    Next I
    
    GetModeList = Split(TerminusResult, c_strTerminusSeparator)
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "GetModeList", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::GetAvailableTurnback
' Input:        [String] TerminusModeName
' Output:       [String()] list of Turnback available for the current terminus mode
' Description:  Returns the list of Turnback available for the current terminus mode
'-------------------------------------------------------------------------------
Public Function GetAvailableTurnback(ByVal TerminusModeName As String) As typeTurnBack()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "GetAvailableTurnback", "Begin Function")
    
    Dim I As Integer
    Dim index As Integer
    Dim arrEmpty() As typeTurnBack
    
    index = -1
    For I = 0 To UBound(TerminusModeList)
        If (TerminusModeList(I).strName = TerminusModeName) Then
            index = I
            Exit For
        End If
    Next I
    
    If (index <> -1) Then
        GetAvailableTurnback = TerminusModeList(index).AvailableTurnback
    Else
        GetAvailableTurnback = arrEmpty
    End If
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "GetAvailableTurnback", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::GetAvailableDepartureMode
' Input:        [String] TerminusModeName
' Output:       [String()] list of Departure Mode available for the current terminus mode
' Description:  Returns the list of Departure Mode available for the current terminus mode
'-------------------------------------------------------------------------------
Public Function GetAvailableDepartureMode(ByVal TerminusModeName As String) As typeDepartureMode()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "GetAvailableDepartureMode", "Begin Function")
    
    Dim I As Integer
    Dim index As Integer
    Dim arrEmpty() As typeDepartureMode
    
    index = -1
    For I = 0 To UBound(TerminusModeList)
        If (TerminusModeList(I).strName = TerminusModeName) Then
            index = I
            Exit For
        End If
    Next I
    
    If (index <> -1) Then
        GetAvailableDepartureMode = TerminusModeList(index).AvailableDepartureMode
    Else
        GetAvailableDepartureMode = arrEmpty
    End If
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "GetAvailableDepartureMode", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::GetContextForMode
' Input:        [String] MMGID text corresponding to the Mode management ID
' Output:       [Integer] the current context identifier for the mode
' Description:  Returns the current context identifier for the mode
'-------------------------------------------------------------------------------
Public Function GetContextForMode(ByVal MMGID As String) As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "GetContextForMode", "Begin Function")
    
    Dim I As Integer
    Dim j As Integer
    Dim result As Integer
    Dim l_found As Boolean
    
    l_found = False
    result = c_iUnknownContextMode
    For I = 0 To UBound(TerminusModeList)
        For j = 0 To UBound(TerminusModeList(I).AvailableDepartureMode)
            If (TerminusModeList(I).AvailableDepartureMode(j).strMMGMode = MMGID) Then
                If (TerminusModeList(I).bIsProvisionnal) Then
                    result = c_iProvisionnalContextMode
                Else
                    result = c_iNominalContextMode
                End If
                l_found = True
                Exit For
            End If
        Next j
        If (l_found) Then
            Exit For
        End If
    Next I

    GetContextForMode = result
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "GetContextForMode", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::GetTerminusModeNameForMode
' Input:        [String] MMGID text corresponding to the Mode management ID
' Output:       [String] the current terminus mode name for the mode
' Description:  Returns the current terminus mode name for the mode
'-------------------------------------------------------------------------------
Public Function GetTerminusModeNameForMode(ByVal MMGID As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "GetTerminusModeNameForMode", "Begin Function")
    
    Dim I As Integer
    Dim j As Integer
    Dim result As String
    Dim l_found As Boolean
    
    l_found = False
    result = ""
    For I = 0 To UBound(TerminusModeList)
        For j = 0 To UBound(TerminusModeList(I).AvailableDepartureMode)
            If (TerminusModeList(I).AvailableDepartureMode(j).strMMGMode = MMGID) Then
                result = TerminusModeList(I).strName
                l_found = True
                Exit For
            End If
        Next j
        If (l_found) Then
            Exit For
        End If
    Next I

    GetTerminusModeNameForMode = result
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "GetTerminusModeNameForMode", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::GetDepartureModeNameForMode
' Input:        [String] MMGID text corresponding to the Mode management ID
' Output:       [String] the current Departure mode name for the mode
' Description:  Returns the current Departure mode name for the mode
'-------------------------------------------------------------------------------
Public Function GetDepartureModeNameForMode(ByVal MMGID As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "GetDepartureModeNameForMode", "Begin Function")
    
    Dim I As Integer
    Dim j As Integer
    Dim result As String
    Dim l_found As Boolean
    
    l_found = False
    result = ""
    For I = 0 To UBound(TerminusModeList)
        For j = 0 To UBound(TerminusModeList(I).AvailableDepartureMode)
            If (TerminusModeList(I).AvailableDepartureMode(j).strMMGMode = MMGID) Then
                result = TerminusModeList(I).AvailableDepartureMode(j).strID
                l_found = True
                Exit For
            End If
        Next j
        If (l_found) Then
            Exit For
        End If
    Next I

    GetDepartureModeNameForMode = result
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "GetDepartureModeNameForMode", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::GetTerminusTripSourceForMode
' Input:        [String] MMGID text corresponding to the Mode management ID
' Output:       [boolean] indicator of the timetable tripsource for the mode
' Description:  Returns the current terminus mode name for the mode
'-------------------------------------------------------------------------------
Public Function GetTerminusTripSourceForMode(ByVal MMGID As String) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "GetTerminusTripSourceForMode", "Begin Function")
    
    Dim I As Integer
    Dim j As Integer
    Dim result As Boolean
    Dim l_found As Boolean
    
    l_found = False
    result = False
    For I = 0 To UBound(TerminusModeList)
        For j = 0 To UBound(TerminusModeList(I).AvailableDepartureMode)
            If (TerminusModeList(I).AvailableDepartureMode(j).strMMGMode = MMGID) Then
                result = TerminusModeList(I).bHasTTTripSource
                l_found = True
                Exit For
            End If
        Next j
        If (l_found) Then
            Exit For
        End If
    Next I

    GetTerminusTripSourceForMode = result
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "GetTerminusTripSourceForMode", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::GetTerminusDepartureMode
' Input:        [String] MMGID text corresponding to the Mode management ID
' Output:       [typeDepartureMode] descritptor of the departure mode
' Description:  Returns the current terminus departure mode description for the mode ID
'-------------------------------------------------------------------------------
Public Function GetTerminusDepartureMode(ByVal MMGID As String) As typeDepartureMode
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "GetTerminusDepartureMode", "Begin Function")
    
    Dim I As Integer
    Dim j As Integer
    Dim result As typeDepartureMode
    Dim l_found As Boolean
    
    l_found = False
    For I = 0 To UBound(TerminusModeList)
        For j = 0 To UBound(TerminusModeList(I).AvailableDepartureMode)
            If (TerminusModeList(I).AvailableDepartureMode(j).strMMGMode = MMGID) Then
                result = TerminusModeList(I).AvailableDepartureMode(j)
                l_found = True
                Exit For
            End If
        Next j
        If (l_found) Then
            Exit For
        End If
    Next I

    GetTerminusDepartureMode = result
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "GetTerminusDepartureMode", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TerminusMode::GetDefaultDepartureMode
' Input:        [String] TerminusModeName
' Output:       [String] Value of the Default Departure Mode
' Description:  Returns the list of Departure Mode available for the current terminus mode
'-------------------------------------------------------------------------------
Public Function GetDefaultDepartureMode(ByVal TerminusModeName As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TerminusMode", "GetDefaultDepartureMode", "Begin Function")

    Dim I As Integer
    Dim index As Integer
    
    index = -1
    For I = 0 To UBound(TerminusModeList)
        If (TerminusModeList(I).strName = TerminusModeName) Then
            index = I
            Exit For
        End If
    Next I
    
    If (index <> -1) Then
        GetDefaultDepartureMode = TerminusModeList(index).strDefault_Departure_ModeID
    Else
        GetDefaultDepartureMode = ""
    End If
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TerminusMode", "GetDefaultDepartureMode", Err.Description)
End Function
