VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_Terminus"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2011. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_Terminus
'* *******************************************************************************************
'* Purpose: Manages termini ("End of line" termini and provisional termini) managed
'*          by the ATS server
'* *******************************************************************************************
'* Modification History:
'* Author:              Nicole FLORIAN
'* Date:                December '11
'* Change:              All - CRs ALPHA 256609, 256610, 256613, 256614, 256615, 256617,
'*                      258286
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
' Used to build the list of terminus IDs and the list of terminus names
Private Const c_strItemSeparator As String = ";"

' Used to read the string (XML format) containing the list of terminus
' and for each terminus, its data (ID and Name)
Private Const c_strTerminusNode As String = "Terminus"
Private Const c_strNameAttr As String = "Name"
Private Const c_strIDAttr As String = "ID"

' Path of the OPC variable containing the list of terminus
Private Const c_strTerminusTag As String = "IconisHMI.TerminusesList.Value"

' Class attributes
' ------------------------------------------------------

' Local OPC variables
' ------------------------------------------------------
' Number of the terminus
Private m_lCount As Integer
' Array containing the list of names of each terminus
Private m_TerminusNames() As String
' Array containing the list of IDs of each terminus
Private m_TerminusIDs() As String

' OPC server's variables
' ------------------------------------------------------
' OPC variable containing the list of the terminus
Private WithEvents m_OPC_TerminusList As Variable
Attribute m_OPC_TerminusList.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Terminus::Class_Initialize
' Input:        nonr
' Output:       none
' Description:  Object constructor
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Terminus", "Class_Initialize", "Begin Subroutine")
    
    Set m_OPC_TerminusList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strTerminusTag, fvVariableTypeText)
    If (m_OPC_TerminusList.EnableEvents = True) Then
        m_OPC_TerminusList_ValueChange
    Else
        m_OPC_TerminusList.EnableEvents = True
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "Class_Initialize", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Terminus::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Terminus", "Class_Terminate", "Begin Subroutine")
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_TerminusList Is Nothing) Then
        Variables.Remove (m_OPC_TerminusList.Name)
        Set m_OPC_TerminusList = Nothing
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Terminus::GetNumberOfTerminus
' Input:        none
' Output:       [Integer]   Number of terminus
' Description:  Returns the number of the terminus
'-------------------------------------------------------------------------------
Public Function GetNumberOfTerminus() As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Terminus", "GetNumberOfTerminus", "Begin Function")
    
    GetNumberOfTerminus = m_lCount
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "GetNumberOfTerminus", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Terminus::GetTerminusName
' Input:        [String]   ID (OPC variable name) of the terminus
' Output:       [String]   Name of the terminus
' Description:  Returns the name of the terminus
'-------------------------------------------------------------------------------
Public Function GetTerminusName(ByVal strTerminusID As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Terminus", "GetTerminusName", "Begin Function")
   
    Dim I As Integer
    Dim strTerminusName As String
    
    For I = 0 To m_lCount - 1
        If (StrComp(m_TerminusIDs(I), strTerminusID, vbTextCompare) = 0) Then
            strTerminusName = m_TerminusNames(I)
            Exit For
        End If
    Next
    
    GetTerminusName = strTerminusName
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "GetTerminusName", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Terminus::GetTerminusID
' Input:        [String]   Name of the terminus
' Output:       [String]   ID (OPC variable name) of the terminus
' Description:  Returns the ID (OPC variable name) of the terminus
'-------------------------------------------------------------------------------
Public Function GetTerminusID(ByVal strTerminusName As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Terminus", "GetTerminusID", "Begin Function")
   
    Dim I As Integer
    Dim strTerminusID As String
    
    For I = 0 To m_lCount - 1
        If (StrComp(m_TerminusNames(I), strTerminusName, vbTextCompare) = 0) Then
            strTerminusID = m_TerminusIDs(I)
            Exit For
        End If
    Next
    
    GetTerminusID = strTerminusID
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "GetTerminusID", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Terminus::GetListOfTerminusIDs
' Input:        None
' Output:       [String]   List of IDs (OPC variable name) of each terminus
' Description:  Returns the list of IDs (OPC variable name) of each terminus.
'               The format of the string is:
'               <Terminus1_ID>;<Terminus2_ID>;...;<TerminusN_ID>
'-------------------------------------------------------------------------------
Public Function GetListOfTerminusIDs() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Terminus", "GetListOfTerminusIDs", "Begin Function")
   
    Dim I As Integer
    Dim strList As String
    
    If (m_lCount > 0) Then
        strList = m_TerminusIDs(0)
        For I = 1 To m_lCount - 1
            strList = strList & c_strItemSeparator & m_TerminusIDs(I)
        Next
    End If
    
    GetListOfTerminusIDs = strList
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "GetListOfTerminusIDs", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Terminus::GetListOfTerminusNames
' Input:        None
' Output:       [String]   List of names of each terminus
' Description:  Returns the list of names of each terminus.
'               The format of the string is:
'               <Terminus1_Name>;<Terminus2_Name>;...;<TerminusN_Name>
'-------------------------------------------------------------------------------
Public Function GetListOfTerminusNames() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Terminus", "GetListOfTerminusNames", "Begin Function")
   
    Dim I As Integer
    Dim strList As String
    
    If (m_lCount > 0) Then
        strList = m_TerminusNames(0)
        For I = 1 To m_lCount - 1
            strList = strList & c_strItemSeparator & m_TerminusNames(I)
        Next
    End If
    
    GetListOfTerminusNames = strList
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "GetListOfTerminusNames", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Terminus::ReadTerminusXMLString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of terminus
'               and memorize data (Name and ID) of each terminus
'-------------------------------------------------------------------------------
Private Sub ReadTerminusXMLString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Terminus", "ReadTerminusXMLString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oTerminusList As IXMLDOMNodeList
   Dim oTerminus As IXMLDOMElement
   Dim strName As String
   Dim strID As String
   Dim I As Integer
   
   strXMLString = m_OPC_TerminusList.Value
   If (strXMLString <> "") Then
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Terminus"
                    Set oTerminusList = oDoc.documentElement.selectNodes(c_strTerminusNode)
                    If Not (oTerminusList Is Nothing) Then
                        If (oTerminusList.length > 0) Then
                            ' Store the number of termini
                            m_lCount = oTerminusList.length
                            
                            ' Redim arrays
                            ReDim m_TerminusNames(0 To m_lCount - 1)
                            ReDim m_TerminusIDs(0 To m_lCount - 1)
                            
                            For Each oTerminus In oTerminusList
                                ' Name attribute
                                strName = Format(oTerminus.getAttribute(c_strNameAttr))
                                ' ID attribute
                                strID = Format(oTerminus.getAttribute(c_strIDAttr))
                                ' Memorizes data in arrays
                                m_TerminusNames(I) = strName
                                m_TerminusIDs(I) = strID
                                I = I + 1
                            Next oTerminus
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "ReadTerminusXMLString", _
                                         "No terminus has been defined in the OPC variable [" & m_OPC_TerminusList.Name & "]")
                        End If
                        Set oTerminusList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "ReadTerminusXMLString", _
                             "The content of the OPC variable [" & m_OPC_TerminusList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "ReadTerminusXMLString", _
                     "The OPC variable [" & m_OPC_TerminusList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "ReadTerminusXMLString", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_Terminus::m_OPC_TerminusList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of terminus
'-----------------------------------------------------------------------------------
Private Sub m_OPC_TerminusList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Terminus", "m_OPC_TerminusList_ValueChange", "Begin Subroutine")

    If (m_OPC_TerminusList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Terminus", "m_OPC_TerminusList_ValueChange", "The status of " & m_OPC_TerminusList.Name & " is Waiting")
    ElseIf (m_OPC_TerminusList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "m_OPC_TerminusList_ValueChange", "The status of " & m_OPC_TerminusList.Name & " is Config Error")
    ElseIf (m_OPC_TerminusList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Terminus", "m_OPC_TerminusList_ValueChange", "The status of " & m_OPC_TerminusList.Name & " is Not Connected")
    ElseIf (m_OPC_TerminusList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Terminus", "m_OPC_TerminusList_ValueChange", "The Quality of " & m_OPC_TerminusList.Name & " is not good")
    Else
        ' Read the string (XML format) and memorize data
        ReadTerminusXMLString
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Terminus", "m_OPC_TerminusList_ValueChange", Err.Description)
End Sub
