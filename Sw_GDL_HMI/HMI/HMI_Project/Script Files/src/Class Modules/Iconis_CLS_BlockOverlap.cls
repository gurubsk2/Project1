VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_BlockOverlap"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_BlockOverlap
'* *******************************************************************************************
'* Purpose: Manages the Overlap status bit for all Blocks.
'* *******************************************************************************************
'* Modification History:
'* Author:              Aswini Kumar Padhy
'* Date:                May '17
'* Change:              All

'* *******************************************************************************************
'* Ref:             1. CR #atvcm00779217
'* *******************************************************************************************

Option Explicit

Dim WithEvents m_OPC_XML_BlocksList As Variable
Attribute m_OPC_XML_BlocksList.VB_VarHelpID = -1
Private Const c_BlocksListTag As String = "IconisHMI.FixedBlocksList.Information.Value"
Private Const c_strBlocksIdNode As String = "FixedBlock"
Private Const c_strBlocksIDAttr As String = "ID"
Private Const c_strBlocksNameAttr As String = "Name"

'used to Update the status of BlockOverlap Symbols
Private Const c_strBlocksOverlapStatusTag As String = ".OverlapStatus.Template.iEqpState"
Private Const c_strBlocksOverlapStatus As String = ".OverlapStatus.Template.iEqpState%"

'used to subscribe OPCSet
Private WithEvents m_OPCSet_BlocksIdData As Iconis_CLS_OPCSet
Attribute m_OPCSet_BlocksIdData.VB_VarHelpID = -1
Dim No_Of_Blocks As Integer

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_BlockOverlap::Class_Initialize
' Input:        none
' Output:       none
' Description:  Init variables, create dictionnaries
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_BlockOverlap", "Class_Initialize", "Begin Subroutine")

    Set m_OPCSet_BlocksIdData = Nothing
    
    ' Add OPC variable containing the list of Blocks
    Set m_OPC_XML_BlocksList = Variables.Add(MOD_Deployment.CBTCLevel1Cluster & c_BlocksListTag, fvVariableTypeText)
    If (m_OPC_XML_BlocksList.EnableEvents = True) Then
        m_OPC_XML_BlocksList_ValueChange
    Else
        m_OPC_XML_BlocksList.EnableEvents = True
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_BlockOverlap", "Class_Initialize", Err.Description)
End Sub
'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_BlockOverlap::m_OPC_XML_BlocksList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of Blocks definitions
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_BlocksList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_BlockOverlap", "m_OPC_XML_BlocksList_ValueChange", "Begin Subroutine")
    If (m_OPC_XML_BlocksList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_BlockOverlap", "m_OPC_XML_BlocksList_ValueChange", "The status of " & m_OPC_XML_BlocksList.Name & " is Waiting")
    ElseIf (m_OPC_XML_BlocksList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_BlockOverlap", "m_OPC_XML_BlocksList_ValueChange", "The status of " & m_OPC_XML_BlocksList.Name & " is Config Error")
    ElseIf (m_OPC_XML_BlocksList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_BlockOverlap", "m_OPC_XML_BlocksList_ValueChange", "The status of " & m_OPC_XML_BlocksList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_BlocksList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_BlockOverlap", "m_OPC_XML_BlocksList_ValueChange", "The Quality of " & m_OPC_XML_BlocksList.Name & " is not good")
    Else
       ' Read the string
        ReadXMLBlocksListString
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_BlockOverlap", "m_OPC_XML_BlocksList_ValueChange", Err.Description)
End Sub
'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_BlockOverlap::ReadXMLBlocksListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of Blocks
'-------------------------------------------------------------------------------
Private Sub ReadXMLBlocksListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_BlockOverlap", "ReadXMLBlocksListString", "Begin Subroutine")
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oBlocksList As IXMLDOMNodeList
   Dim oBlock As IXMLDOMElement
   Dim str_Temp As String
   Dim i As Integer
   
    strXMLString = m_OPC_XML_BlocksList.Value

    ' Empty the data lists
    ReDim m_strBlockID(0)
    ReDim m_strBlockName(0)
     
    If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Condition"
                    Set oBlocksList = oDoc.documentElement.getElementsByTagName(c_strBlocksIdNode)
                    If Not (oBlocksList Is Nothing) Then
                        If (oBlocksList.length > 0) Then
                            ReDim m_strBlockID(oBlocksList.length - 1)
                            ReDim m_strBlockName(oBlocksList.length - 1)
                           ' Find No of Blocks
                            No_Of_Blocks = oBlocksList.length - 1
                            
                            i = 0
                            Set m_OPCSet_BlocksIdData = Iconis_MOD_General.CreateNew_Iconis_CLS_OPCSet
                            For Each oBlock In oBlocksList
                                ' read the attributes
                                m_strBlockID(i) = oBlock.getAttribute(c_strBlocksIDAttr)
                                m_strBlockName(i) = oBlock.getAttribute(c_strBlocksNameAttr)
                                                                
                                m_OPCSet_BlocksIdData.AddItem GetOPCCluster & m_strBlockID(i) & c_strBlocksOverlapStatusTag, fvVariableTypeRegister, c_OPCReadAll
                                Call Variables.Add(c_strClusterLevel1 & m_strBlockID(i) & c_strBlocksOverlapStatus, fvVariableTypeBit)
                                                 
                                i = i + 1
                            Next oBlock
                            'To Connect all the Block vatiables
                            m_OPCSet_BlocksIdData.DoConnect "BlockOverlap"
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_BlockOverlap", "ReadXMLBlocksListString", _
                                         "No Block has been defined in the OPC variable [" & m_OPC_XML_BlocksList.Name & "]")
                        End If
                        Set oBlocksList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_BlockOverlap", "ReadXMLBlocksListString", _
                             "The content of the OPC variable [" & m_OPC_XML_BlocksList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_BlockOverlap", "ReadXMLBlocksListString", _
                     "The OPC variable [" & m_OPC_XML_BlocksList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_BlockOverlap", "ReadXMLBlocksListString", Err.Description)
End Sub
'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_BlockOverlap::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_BlockOverlap", "Class_Terminate", "Begin Subroutine")

    If Not (m_OPCSet_BlocksIdData Is Nothing) Then
        m_OPCSet_BlocksIdData.Destroy
        Set m_OPCSet_BlocksIdData = Nothing
    End If

    If Not (m_OPC_XML_BlocksList Is Nothing) Then
        Variables.Remove (m_OPC_XML_BlocksList.Name)
        Set m_OPC_XML_BlocksList = Nothing
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_BlockOverlap", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_BlockOverlap::m_OPCSet_BlockIdData_OnRefresh
' Input:        -
' Output:       -
' Description:  Used to update the change in state of overlap status symbol
'               for block animation
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_BlocksIdData_OnRefresh(lIndex As Long, Value As Variant, Status As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_BlockOverlap", "m_OPCSet_BlocksIdData_OnRefresh", "Begin Subroutine")

    Dim str_OriginSignal() As String
    Dim i As Long
    For i = 0 To No_Of_Blocks
        If m_OPCSet_BlocksIdData.Item(i).Value = 1 And Status = fvVariableStatusGood Then
            Variables.Item(m_OPCSet_BlocksIdData.Item(i).strPath & "%").Value = True
        Else
            Variables.Item(m_OPCSet_BlocksIdData.Item(i).strPath & "%").Value = False
        End If
    Next i
	
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_BlockOverlap", "m_OPCSet_BlocksIdData_OnRefresh", Err.Description)
End Sub


