VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_CalendarCmd"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_CalendarCmd
'* *******************************************************************************************
'* Purpose: Manages a Command Definition
'* *******************************************************************************************
'* Modification History:
'* Author:              Eric FOISSEY
'* Date:                December '12
'* Change:              All - CR ALPHA 279336
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
' Used to read the string (XML format) containing the list of commands possible
Private Const c_strTableNode As String = "Table"
Private Const c_strTableIDValue As String = "Modules"
Private Const c_strTableIDAttr As String = "ID"

Private Const c_strRecordNode As String = "Record"
Private Const c_strAttributeNode As String = "Attribute"
Private Const c_strRecordIDNameValue As String = "module"
Private Const c_strRecordIDTextValue As String = "comment"
Private Const c_strRecordIDDisplayedValue As String = "HMIDisplay"
Private Const c_strRecordIDParamValue As String = "Param"
Private Const c_strRecordIDAttr As String = "ID"
Private Const c_strRecordValueAttr As String = "Value"

' Path of OPC variable containing the list of commands allowed from the platform
Private Const c_strXMLcmdListTag As String = "CMMGCalendar.MngtCalendar.bstrXmlLineMode"

' Used to read the string (XML format) containing the list of paramaters list
Private Const c_strParamTableNode As String = "Table"
Private Const c_strParamTableIDAttr As String = "ID"

Private Const c_strParamRecordNode As String = "Record"
Private Const c_strParamAttributeNode As String = "Attribute"
Private Const c_strParamIDNameValue As String = "ID"
Private Const c_strParamIDDicoValue As String = "Dico"
Private Const c_strParamIDMinValue As String = "Min"
Private Const c_strParamIDMaxValue As String = "Max"
Private Const c_strParamIDTypeValue As String = "Type"
Private Const c_strParamRecordIDAttr As String = "ID"
Private Const c_strParamRecordValueAttr As String = "Value"

Private Const c_strTypeInteger As String = "integer"
' Path of OPC variable containing the list of commands allowed from the platform
Private Const c_strXMLParamListTag As String = "CMMGCalendar.MngtCalendar.bstrCommandValue"

' Class attributes
' ------------------------------------------------------
' Command Names
Private m_strCmdNames() As String
' Command textes
Private m_strCmdTexts()  As String
' Command display indicators
Private m_bCmdDisplayed() As Boolean
' Command Parameters
Private m_strCmdParams() As String


Private Const c_iParamTypeCombo As Integer = 0
Private Const c_iParamTypeInteger As Integer = 1
Private Const c_iParamTypeText As Integer = 2

' Param Names
Private m_strParamNames() As String
' Command textes
Private m_iParamType()  As Integer
' Command display indicators
Private m_strCmdParamValues() As String
' Command Parameters
Private m_strCmdParamDico() As String

' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------
' OPC variable containing the list of the commands allowed
Private WithEvents m_OPC_XML_LineMode As Variable
Attribute m_OPC_XML_LineMode.VB_VarHelpID = -1
Private WithEvents m_OPC_XML_ParamList As Variable
Attribute m_OPC_XML_ParamList.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::Init
' Input:        none
' Output:       none
' Description:  Init variables, create dictionnaries
'-------------------------------------------------------------------------------
Public Sub Init()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Init", "Begin Subroutine")
     
    ReDim m_strCmdNames(0)
    ReDim m_strCmdTexts(0)
    ReDim m_bCmdDisplayed(0)
    ReDim m_strCmdParams(0)
    
    ReDim m_strParamNames(0)
    ReDim m_iParamType(0)
    ReDim m_strCmdParamValues(0)
    ReDim m_strCmdParamDico(0)
    
    ' Add OPC variable containing the list of points reachable from the platform
    Set m_OPC_XML_LineMode = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strXMLcmdListTag, fvVariableTypeText)
    If (m_OPC_XML_LineMode.EnableEvents = True) Then
        m_OPC_XML_LineMode_ValueChange
    Else
        m_OPC_XML_LineMode.EnableEvents = True
    End If
    
    ' Add OPC variable containing the list of parameters
    Set m_OPC_XML_ParamList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strXMLParamListTag, fvVariableTypeText)
    If (m_OPC_XML_ParamList.EnableEvents = True) Then
        m_OPC_XML_ParamList_ValueChange
    Else
        m_OPC_XML_ParamList.EnableEvents = True
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Init", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Class_Terminate", "Begin Subroutine")
    Dim I As Integer
    
    ' Empty the data lists
    ReDim m_strCmdNames(0)
    ReDim m_strCmdTextes(0)
    ReDim m_bCmdDisplayed(0)
    ReDim m_strCmdParams(0)
    
    
    ReDim m_strParamNames(0)
    ReDim m_iParamType(0)
    ReDim m_strCmdParamValues(0)
    ReDim m_strCmdParamDico(0)
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_LineMode Is Nothing) Then
        Variables.Remove (m_OPC_XML_LineMode.Name)
        Set m_OPC_XML_LineMode = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_ParamList Is Nothing) Then
        Variables.Remove (m_OPC_XML_ParamList.Name)
        Set m_OPC_XML_ParamList = Nothing
    End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_CmdCount
' Input:        none
' Output:       [int] Count of the allowed command
' Description:  Returns the count of the allowed command
'-------------------------------------------------------------------------------
Public Property Get Get_CmdCount() As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_CmdCount", "Begin Property")

    Get_CmdCount = UBound(m_strCmdNames) + 1
    
Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_CmdCount", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_CmdNames
' Input:        none
' Output:       [String()] The names of the commands
' Description:  Returns the names of the commands
'-------------------------------------------------------------------------------
Public Property Get Get_CmdNames() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_CmdNames", "Begin Property")

    Get_CmdNames = m_strCmdNames

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_CmdNames", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_CmdTextes
' Input:        none
' Output:       [String()] The texts of the commands
' Description:  Returns the texts of the commands
'-------------------------------------------------------------------------------
Public Property Get Get_CmdTexts() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_CmdTextes", "Begin Property")

    Get_CmdTexts = m_strCmdTexts

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_CmdTextes", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_CmdDisplayed
' Input:        none
' Output:       [bool()] The displayed status of the commands
' Description:  Returns the displayed status of the commands
'-------------------------------------------------------------------------------
Public Property Get Get_CmdDisplayed() As Boolean()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_CmdDisplayed", "Begin Property")

    Get_CmdDisplayed = m_bCmdDisplayed

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_CmdDisplayed", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_CmdParam
' Input:        none
' Output:       [bool()] The params of the commands
' Description:  Returns the params of the commands
'-------------------------------------------------------------------------------
Public Property Get Get_CmdParams() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_CmdParams", "Begin Property")

    Get_CmdParams = m_strCmdParams

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_CmdParams", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::ReadXMLString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of platforms
'-------------------------------------------------------------------------------
Private Sub ReadXMLString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "ReadXMLString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oTableList As IXMLDOMNodeList
   Dim oTable As IXMLDOMElement
   Dim strTableType As String
   Dim oCmdList As IXMLDOMNodeList
   Dim iCmdCount As Integer
   Dim oCmdDef As IXMLDOMElement
   Dim oAttributeList As IXMLDOMNodeList
   Dim oAttrDef As IXMLDOMElement
      
   Dim tmp_text As String
   
   Dim cmdName As String
   Dim cmdText As String
   Dim cmdDisplayed As String
   Dim cmdParam As String
   
   strXMLString = m_OPC_XML_LineMode.Value
   
    ' Empty the data lists
    ReDim m_strCmdNames(0)
    ReDim m_strCmdTexts(0)
    ReDim m_bCmdDisplayed(0)
    ReDim m_strCmdParams(0)
    iCmdCount = 0
    
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Table"
                    Set oTableList = oDoc.documentElement.getElementsByTagName(c_strTableNode)
                    If Not (oTableList Is Nothing) Then
                        If (oTableList.length > 0) Then
                            For Each oTable In oTableList
                                ' Name attribute
                                strTableType = Format(oTable.getAttribute(c_strTableIDAttr))

                                             
                                If (strTableType = c_strTableIDValue) Then
                                    ' the table is the command definition table
                                    Set oCmdList = oTable.getElementsByTagName(c_strRecordNode)
                                    If Not (oCmdList Is Nothing) Then
                                        If (oCmdList.length > 0) Then
                                                                    
                                        ReDim Preserve m_strCmdNames(iCmdCount + oCmdList.length)
                                        ReDim Preserve m_strCmdTexts(iCmdCount + oCmdList.length)
                                        ReDim Preserve m_bCmdDisplayed(iCmdCount + oCmdList.length)
                                        ReDim Preserve m_strCmdParams(iCmdCount + oCmdList.length)
                                        
                                        For Each oCmdDef In oCmdList
                                            'attributes of the command
                                            Set oAttributeList = oCmdDef.selectNodes(c_strAttributeNode)
                                            cmdName = ""
                                            cmdText = ""
                                            cmdDisplayed = ""
                                            cmdParam = ""
                                        
                                            For Each oAttrDef In oAttributeList
                                                tmp_text = oAttrDef.getAttribute(c_strRecordIDAttr)
                                                
                                                If (tmp_text = c_strRecordIDNameValue) Then
                                                    cmdName = oAttrDef.getAttribute(c_strRecordValueAttr)
                                                End If
                                                
                                                If (tmp_text = c_strRecordIDTextValue) Then
                                                    cmdText = oAttrDef.getAttribute(c_strRecordValueAttr)
                                                End If
                                                
                                                If (tmp_text = c_strRecordIDDisplayedValue) Then
                                                    cmdDisplayed = oAttrDef.getAttribute(c_strRecordValueAttr)
                                                End If
                                                
                                                If (tmp_text = c_strRecordIDParamValue) Then
                                                    cmdParam = oAttrDef.getAttribute(c_strRecordValueAttr)
                                                End If
                                            Next oAttrDef
                                            
                                            m_strCmdNames(iCmdCount) = cmdName
                                            
                                            If (cmdText = "") Then
                                                m_strCmdTexts(iCmdCount) = cmdName
                                            Else
                                                m_strCmdTexts(iCmdCount) = cmdText
                                            End If
                                                
                                            If ((cmdName = "") Or (cmdDisplayed <> "True")) Then
                                                m_bCmdDisplayed(iCmdCount) = False
                                            Else
                                                m_bCmdDisplayed(iCmdCount) = True
                                            End If
 
                                            m_strCmdParams(iCmdCount) = cmdParam
                                                                                        
                                            iCmdCount = iCmdCount + 1
                                        Next oCmdDef
                                        
                                        End If
                                    End If
                                End If
                                
                            Next oTable
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "ReadXMLString", _
                                         "No point has been defined in the OPC variable [" & m_OPC_XML_LineMode.Name & "]")
                        End If
                        Set oTableList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "ReadXMLString", _
                             "The content of the OPC variable [" & m_OPC_XML_LineMode.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "ReadXMLString", _
                     "The OPC variable [" & m_OPC_XML_LineMode.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "ReadXMLString", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::m_OPC_XML_LineMode_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of commands allowed
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_LineMode_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_CalendarCmd", "m_OPC_XML_LineMode_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_LineMode.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "m_OPC_XML_LineMode_ValueChange", "The status of " & m_OPC_XML_LineMode.Name & " is Waiting")
    ElseIf (m_OPC_XML_LineMode.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "m_OPC_XML_LineMode_ValueChange", "The status of " & m_OPC_XML_LineMode.Name & " is Config Error")
    ElseIf (m_OPC_XML_LineMode.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_CalendarCmd", "m_OPC_XML_LineMode_ValueChange", "The status of " & m_OPC_XML_LineMode.Name & " is Not Connected")
    ElseIf (m_OPC_XML_LineMode.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_CalendarCmd", "m_OPC_XML_LineMode_ValueChange", "The Quality of " & m_OPC_XML_LineMode.Name & " is not good")
    Else
       ' Read the string
        ReadXMLString
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "m_OPC_XML_LineMode_ValueChange", Err.Description)
End Sub


'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::m_OPC_XML_ParamList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of parameters
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_ParamList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_CalendarCmd", "m_OPC_XML_ParamList_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_ParamList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "m_OPC_XML_ParamList_ValueChange", "The status of " & m_OPC_XML_ParamList.Name & " is Waiting")
    ElseIf (m_OPC_XML_ParamList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "m_OPC_XML_ParamList_ValueChange", "The status of " & m_OPC_XML_ParamList.Name & " is Config Error")
    ElseIf (m_OPC_XML_ParamList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_CalendarCmd", "m_OPC_XML_ParamList_ValueChange", "The status of " & m_OPC_XML_ParamList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_ParamList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_CalendarCmd", "m_OPC_XML_ParamList_ValueChange", "The Quality of " & m_OPC_XML_ParamList.Name & " is not good")
    Else
       ' Read the string
        ReadXMLParamString
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "m_OPC_XML_ParamList_ValueChange", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_Text
' Input:        [String] command Name
' Output:       [String] text displayed for the command
' Description:  Returns the text of the command
'-------------------------------------------------------------------------------
Public Function Get_Text(ByVal cmd_Name As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_Text", "Begin Property")
    
    Dim Res_txt As String
    Dim I As Integer
    
    Res_txt = ""
    For I = 0 To UBound(m_strCmdNames)
        If (m_strCmdNames(I) = cmd_Name) Then
            Res_txt = m_strCmdTexts(I)
        End If
    Next I
    
    Get_Text = Res_txt

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_Text", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_cmdParam
' Input:        [String] command Name
' Output:       [String] list of parameters
' Description:  Returns the text of the list of parameters
'-------------------------------------------------------------------------------
Public Function Get_cmdParam(ByVal cmd_Name As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_cmdParam", "Begin Property")
    
    Dim Res_txt As String
    Dim I As Integer
    
    Res_txt = ""
    For I = 0 To UBound(m_strCmdNames)
        If (m_strCmdNames(I) = cmd_Name) Then
            Res_txt = m_strCmdParams(I)
        End If
    Next I
    
    Get_cmdParam = Res_txt

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_cmdParam", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_DisplayedStatus
' Input:        [String] command Name
' Output:       [String] displayed status for the command
' Description:  Returns the text of the command
'-------------------------------------------------------------------------------
Public Function Get_DisplayedStatus(ByVal cmd_Name As String) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_DisplayedStatus", "Begin Property")

    Dim Res_bool As Boolean
    Dim I As Integer
    
    Res_bool = False
    For I = 0 To UBound(m_strCmdNames)
        If (m_strCmdNames(I) = cmd_Name) Then
            Res_bool = m_bCmdDisplayed(I)
        End If
    Next I
    
    Get_DisplayedStatus = Res_bool

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_DisplayedStatus", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::ReadXMLParamString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of parameters
'-------------------------------------------------------------------------------
Private Sub ReadXMLParamString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "ReadXMLParamString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oTableList As IXMLDOMNodeList
   Dim oTable As IXMLDOMElement
   Dim strTableType As String
   Dim oParamList As IXMLDOMNodeList
   Dim iParamCount As Integer
   Dim oParamDef As IXMLDOMElement
   Dim oAttributeList As IXMLDOMNodeList
   Dim oAttrDef As IXMLDOMElement
      
   Dim tmp_text As String
   
   Dim ParamType As Integer
   Dim MinText As String
   Dim MaxText As String
   Dim ParamText As String
   Dim DicoText As String
   
   strXMLString = m_OPC_XML_ParamList.Value
   
   ' Empty the data lists
   ReDim m_strParamNames(0)
   ReDim m_iParamType(0)
   ReDim m_strCmdParamValues(0)
   ReDim m_strCmdParamDico(0)
   iParamCount = 0
    
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Table"
                    Set oTableList = oDoc.documentElement.getElementsByTagName(c_strParamTableNode)
                    If Not (oTableList Is Nothing) Then
                        If (oTableList.length > 0) Then
                            For Each oTable In oTableList
                                ' Name attribute
                                strTableType = Format(oTable.getAttribute(c_strParamTableIDAttr))
                                
                                ReDim Preserve m_strParamNames(iParamCount)
                                ReDim Preserve m_iParamType(iParamCount)
                                ReDim Preserve m_strCmdParamValues(iParamCount)
                                ReDim Preserve m_strCmdParamDico(iParamCount)
                                
                                m_strParamNames(iParamCount) = strTableType
                                m_iParamType(iParamCount) = 0
                                m_strCmdParamValues(iParamCount) = ""
                                m_strCmdParamDico(iParamCount) = ""
                                
                                'read the parameter list
                                Set oParamList = oTable.getElementsByTagName(c_strParamRecordNode)
                                If Not (oParamList Is Nothing) Then
                                    If (oParamList.length > 1) Then
                                        ParamType = c_iParamTypeCombo
                                        ParamText = ""
                                        DicoText = ""
                                        
                                        For Each oParamDef In oParamList
                                            'attributes of the command
                                            Set oAttributeList = oParamDef.selectNodes(c_strParamAttributeNode)
                                        
                                            For Each oAttrDef In oAttributeList
                                                tmp_text = oAttrDef.getAttribute(c_strParamRecordIDAttr)
                                                                                                
                                                If (tmp_text = c_strParamIDNameValue) Then
                                                    If (ParamText = "") Then
                                                        ParamText = oAttrDef.getAttribute(c_strRecordValueAttr)
                                                    Else
                                                        ParamText = ParamText + ";" + oAttrDef.getAttribute(c_strRecordValueAttr)
                                                    End If
                                                End If
                                                    
                                                If (tmp_text = c_strParamIDDicoValue) Then
                                                    If (DicoText = "") Then
                                                        DicoText = oAttrDef.getAttribute(c_strRecordValueAttr)
                                                    Else
                                                        DicoText = DicoText + ";" + oAttrDef.getAttribute(c_strRecordValueAttr)
                                                    End If

                                                End If
                                            Next oAttrDef
                                        Next oParamDef
                                        m_iParamType(iParamCount) = ParamType
                                        m_strCmdParamValues(iParamCount) = ParamText
                                        m_strCmdParamDico(iParamCount) = DicoText

                                    Else
                                        Set oParamDef = oParamList(0)
                                        
                                        'attributes of the command
                                        Set oAttributeList = oParamDef.selectNodes(c_strParamAttributeNode)
                                        
                                        ParamType = 0
                                        MinText = ""
                                        MaxText = ""
                                        
                                        For Each oAttrDef In oAttributeList
                                            tmp_text = oAttrDef.getAttribute(c_strParamRecordIDAttr)
                                                
                                            If (tmp_text = c_strParamIDTypeValue) Then
                                                If (StrComp(oAttrDef.getAttribute(c_strParamRecordValueAttr), c_strTypeInteger) = 0) Then
                                                    ParamType = c_iParamTypeInteger
                                                Else
                                                    ParamType = c_iParamTypeText
                                                End If
                                            End If
                                                
                                            If (tmp_text = c_strParamIDMinValue) Then
                                               MinText = oAttrDef.getAttribute(c_strRecordValueAttr)
                                            End If
                                                
                                            If (tmp_text = c_strParamIDMaxValue) Then
                                                MaxText = oAttrDef.getAttribute(c_strRecordValueAttr)
                                            End If
                                        Next oAttrDef
                                        
                                        m_iParamType(iParamCount) = ParamType
                                        m_strCmdParamValues(iParamCount) = MinText + ";" + MaxText
                                        m_strCmdParamDico(iParamCount) = MinText + ";" + MaxText
                                        
                                    End If
                                        
                                End If
                                
                                iParamCount = iParamCount + 1
                            Next oTable
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "ReadXMLParamString", _
                                         "No point has been defined in the OPC variable [" & m_OPC_XML_ParamList.Name & "]")
                        End If
                        Set oTableList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "ReadXMLParamString", _
                             "The content of the OPC variable [" & m_OPC_XML_ParamList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "ReadXMLParamString", _
                     "The OPC variable [" & m_OPC_XML_ParamList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "ReadXMLParamString", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_ParamType
' Input:        [String] Param Name
' Output:       [int] parameter type
' Description:  Returns the type of the parameter
'-------------------------------------------------------------------------------
Public Function Get_ParamType(ByVal Param_Name As String) As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_ParamType", "Begin Property")

    Dim Res_int As Integer
    Dim I As Integer
    
    Res_int = 2
    For I = 0 To UBound(m_strParamNames)
        If (m_strParamNames(I) = Param_Name) Then
            Res_int = m_iParamType(I)
        End If
    Next I
    
    Get_ParamType = Res_int

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_ParamType", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_ParamValue
' Input:        [String] Param Name
' Output:       [String] parameter value
' Description:  Returns the value of the parameter
'-------------------------------------------------------------------------------
Public Function Get_ParamValue(ByVal Param_Name As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_ParamValue", "Begin Property")

    Dim Res_String As String
    Dim I As Integer
    
    Res_String = ""
    For I = 0 To UBound(m_strParamNames)
        If (m_strParamNames(I) = Param_Name) Then
            Res_String = m_strCmdParamValues(I)
        End If
    Next I
    
    Get_ParamValue = Res_String

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_ParamValue", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_CalendarCmd::Get_ParamDico
' Input:        [String] Param Name
' Output:       [String] parameter dico
' Description:  Returns the dico of the parameter
'-------------------------------------------------------------------------------
Public Function Get_ParamDico(ByVal Param_Name As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_CalendarCmd", "Get_ParamDico", "Begin Property")

    Dim Res_String As String
    Dim I As Integer
    
    Res_String = ""
    For I = 0 To UBound(m_strParamNames)
        If (m_strParamNames(I) = Param_Name) Then
            Res_String = m_strCmdParamDico(I)
        End If
    Next I
    
    Get_ParamDico = Res_String

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_CalendarCmd", "Get_ParamDico", Err.Description)
End Function
