VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_Signals"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_Signals
'* *******************************************************************************************
'* Purpose: Manages a Signals definitions - provides function to read the Signal lists and
'*          function to read XML for Exit Gate definitions
'* *******************************************************************************************
'* Modification History:
'* Author:              Eric FOISSEY
'* Date:                March '13
'* Change:              All - CR ALPHA 342079
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
' Used to read the string (XML format) containing the list of Exit Gate destination
Private Const c_strDestinationNode As String = "Destination_Signal"
Private Const c_strDestinationAttr As String = "Name"

' Used to read the string (XML format) containing the list of signals
Private Const c_strSignalNode As String = "Signal"
Private Const c_strSignalIDAttr As String = "ID"
Private Const c_strSignalNameAttr As String = "Name"
Private Const c_strSignalExitGateBlockableAttr As String = "ExitGateBlockable"

'used to read the current list of signals, and exit gate
Private Const c_strSignalListTag As String = "IconisHMI.SignalsList.Value"

' Class attributes
' ------------------------------------------------------
' signals IDs List
Private m_strSignalIDs() As String
Private m_strSignalNames() As String
Private m_strSignalExitGateBlockable() As Integer

' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------
' OPC variable containing the list of the commands allowed
Private WithEvents m_OPC_XML_SignalList As Variable
Attribute m_OPC_XML_SignalList.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Signals::Class_Initialize
' Input:        none
' Output:       none
' Description:  Init variables, create dictionnaries
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Signals", "Class_Initialize", "Begin Subroutine")
     
    ReDim m_strSignalIDs(0)
    ReDim m_strSignalNames(0)
    ReDim m_strSignalExitGateBlockable(0)

    ' Add OPC variable containing the list of blocks
    Set m_OPC_XML_SignalList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strSignalListTag, fvVariableTypeText)
    If (m_OPC_XML_SignalList.EnableEvents = True) Then
        m_OPC_XML_SignalList_ValueChange
    Else
        m_OPC_XML_SignalList.EnableEvents = True
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "Class_Initialize", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Signals::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Signals", "Class_Terminate", "Begin Subroutine")
    
    ' Empty the data lists
    ReDim m_strSignalIDs(0)
    ReDim m_strSignalNames(0)
    ReDim m_strSignalExitGateBlockable(0)
        
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_SignalList Is Nothing) Then
        Variables.Remove (m_OPC_XML_SignalList.Name)
        Set m_OPC_XML_SignalList = Nothing
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "Class_Terminate", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_Signals::m_OPC_XML_SignalList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of signals
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_SignalList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Signals", "m_OPC_XML_SignalList_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_SignalList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Signals", "m_OPC_XML_SignalList_ValueChange", "The status of " & m_OPC_XML_SignalList.Name & " is Waiting")
    ElseIf (m_OPC_XML_SignalList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "m_OPC_XML_SignalList_ValueChange", "The status of " & m_OPC_XML_SignalList.Name & " is Config Error")
    ElseIf (m_OPC_XML_SignalList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Signals", "m_OPC_XML_SignalList_ValueChange", "The status of " & m_OPC_XML_SignalList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_SignalList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Signals", "m_OPC_XML_SignalList_ValueChange", "The Quality of " & m_OPC_XML_SignalList.Name & " is not good")
    Else
       ' Read the string
        ReadSignalListString
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "m_OPC_XML_SignalList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Signals::ReadSignalListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of signals
'-------------------------------------------------------------------------------
Private Sub ReadSignalListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Signals", "ReadSignalListString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oSignalList As IXMLDOMNodeList
   Dim oSignal As IXMLDOMElement

   Dim I As Integer
   
   strXMLString = m_OPC_XML_SignalList.Value
   
    ' Empty the data lists
    ReDim m_strSignalIDs(0)
    ReDim m_strSignalNames(0)
    ReDim m_strSignalExitGateBlockable(0)
    
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Signal"
                    Set oSignalList = oDoc.documentElement.getElementsByTagName(c_strSignalNode)
                    If Not (oSignalList Is Nothing) Then
                        If (oSignalList.length > 0) Then
                            ReDim m_strSignalIDs(oSignalList.length - 1)
                            ReDim m_strSignalNames(oSignalList.length - 1)
                            ReDim m_strSignalExitGateBlockable(oSignalList.length - 1)
                            I = 0
                            For Each oSignal In oSignalList
                                ' Name attribute
                                m_strSignalIDs(I) = oSignal.getAttribute(c_strSignalIDAttr)
                                m_strSignalNames(I) = oSignal.getAttribute(c_strSignalNameAttr)
                                m_strSignalExitGateBlockable(I) = oSignal.getAttribute(c_strSignalExitGateBlockableAttr)
                                I = I + 1
                            Next oSignal
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "ReadSignalListString", _
                                         "No signal has been defined in the OPC variable [" & m_OPC_XML_SignalList.Name & "]")
                        End If
                        Set oSignalList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "ReadSignalListString", _
                             "The content of the OPC variable [" & m_OPC_XML_SignalList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "ReadSignalListString", _
                     "The OPC variable [" & m_OPC_XML_SignalList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "ReadSignalListString", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Signals::Get_SignalID
' Input:        [String] Signal Name
' Output:       [String] signal ID
' Description:  Returns the ID for a signal Name
'-------------------------------------------------------------------------------
Public Function Get_SignalID(ByVal SignalName As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Signals", "Get_SignalID", "Begin Function")
    
    Dim str_ID As String
    Dim I As Integer
    
    str_ID = ""
    For I = 0 To UBound(m_strSignalNames)
        If (m_strSignalNames(I) = SignalName) Then
            str_ID = m_strSignalIDs(I)
            Exit For
        End If
    Next I
    
    Get_SignalID = str_ID
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "Get_SignalID", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Signals::Get_SignalExitGateSignals
' Input:
' Output:       [String ()] list of Signals that have blockable Exit Gate
' Description:  Returns the list of Signals that have blockable Exit Gate
'-------------------------------------------------------------------------------
Public Function Get_SignalExitGateSignals() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Signals", "Get_SignalID", "Begin Function")
    
    Dim str_result() As String
    Dim I As Integer
    Dim result_size As Integer
    
    result_size = 0
    For I = 0 To UBound(m_strSignalNames)
        If (m_strSignalExitGateBlockable(I) = 1) Then
            ReDim Preserve str_result(result_size)
            str_result(result_size) = m_strSignalNames(I)
            result_size = result_size + 1
        End If
    Next I
    
    Get_SignalExitGateSignals = result_size
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "Get_SignalID", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         ReadDestinationExitGate
' Input:        [String] ExitGateXML : containing the list of Exit Gates for a signal
' Output:       none
' Description:  Extract the Destination Exit Gate of the Exit Gate List
'-------------------------------------------------------------------------------
Public Function ReadDestinationExitGate(ExitGateXML As String) As String
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Signals", "ReadDestinationExitGate", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim strResult As String
   
   Dim oDoc As DOMDocument
   Dim oDestList As IXMLDOMNodeList
   Dim oDest As IXMLDOMElement
   
   strResult = ""
   strXMLString = ExitGateXML

   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Table"
                    Set oDestList = oDoc.documentElement.getElementsByTagName(c_strDestinationNode)
                    If Not (oDestList Is Nothing) Then
                        If (oDestList.length > 0) Then
                            For Each oDest In oDestList
                                ' Name attribute
                                If (strResult = "") Then
                                    strResult = oDest.getAttribute(c_strDestinationAttr)
                                Else
                                    strResult = strResult + " - " + oDest.getAttribute(c_strDestinationAttr)
                                End If
                            Next oDest
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "ReadDestinationExitGate", _
                                         "No Destination Exit Gate has been defined in the  variable [ExitGateXML]")
                        End If
                        Set oDestList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "ReadDestinationExitGate", _
                             "The content of the variable [ExitGateXML] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "ReadDestinationExitGate", _
                     "The variable [ExitGateXML] is empty")
    End If
       
    If (strResult <> "") Then
        ReadDestinationExitGate = strResult
    Else
        ReadDestinationExitGate = "-"
    End If
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Signals", "ReadDestinationExitGate", Err.Description)
End Function

