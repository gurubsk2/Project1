VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_TPInfo_Manager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_TPInfo_Manager
'* *******************************************************************************************
'* Purpose: Manages a conversion between TP Ids and SD Ids
'* *******************************************************************************************
'* Modification History:
'* Author:              Eric FOISSEY
'* Date:                August '12
'* Change:              All - CR ALPHA 304990

'* Author:              Nicole FLORIAN
'* Date:                November '12
'* Change:              CR ALPHA 322784
'*                      Remove the trace displaying the content of the variable
'*                      IconisHMI.TrackPortionsList.Value in the "ReadTPinfo_XMLString"
'*                      subroutine
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
' Used to read the string (XML format) containing the list of Track Portion (TP) Infos and Track circuit ( TC = SD ) infos
Private Const c_strTPListNode As String = "TrackPortionsList"
Private Const c_strTPNode As String = "TrackPortion"
Private Const c_strTPNameAttr As String = "Name"
Private Const c_strTPIDAttr As String = "ID"
Private Const c_strSDNameAttr As String = "TrackSectionName"
Private Const c_strSDIDAttr As String = "TrackSectionID"


' Path of OPC variable containing the list of Track Portion
Private Const c_strTPListTag As String = "IconisHMI.TrackPortionsList.Value"

' Class attributes
' ------------------------------------------------------
' Flag indicating if the value of the OPC variable containing the list of the TPInfo has been received
Private m_bTPInfoListFlag As Boolean

' Class attributes
' ------------------------------------------------------
' current TP ID
Private m_strTPID As String
' current TP Name
Private m_strTPName As String
' current SD ID
Private m_strSDID As String
' current SD Name
Private m_strSDName As String
' Dictionary of TP infos
Private m_TPInfos As Object

' Local OPC variables
' ------------------------------------------------------
' Collection of the Iconis_CLS_TPInfo instances
Private m_TPInfo_List As New Collection

' OPC server's variables
' ------------------------------------------------------
' OPC variable containing the list of the points reachable from the platform
Private WithEvents m_OPC_TPInfoList As Variable
Attribute m_OPC_TPInfoList.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo_Manager::Class_Initialize
' Input:        none
' Output:       none
' Description:  Init variables
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo_Manager", "Class_Initialize", "Begin Subroutine")
        
    ' Add OPC variable containing the list of TP infos
    Set m_OPC_TPInfoList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strTPListTag, fvVariableTypeText)
    If (m_OPC_TPInfoList.EnableEvents = True) Then
        m_OPC_TPInfoList_ValueChange
    Else
        m_OPC_TPInfoList.EnableEvents = True
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo_Manager", "Class_Initialize", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo_Manager::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo_Manager", "Class_Terminate", "Begin Subroutine")
    Dim I As Integer

    ' Empty dictionary
    If Not (m_TPInfo_List Is Nothing) Then
        For I = 1 To m_TPInfo_List.Count
            m_TPInfo_List.Remove 1
        Next
        Set m_TPInfo_List = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_TPInfoList Is Nothing) Then
        Variables.Remove (m_OPC_TPInfoList.Name)
        Set m_OPC_TPInfoList = Nothing
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo_Manager", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo_Manager::Get_PlatformItem
' Input:        strName [String] Name of the platform
' Output:       [Iconis_CLS_Platform] the Iconis_CLS_Platform instance
' Description:  Returns the Iconis_CLS_Platform instance
'-------------------------------------------------------------------------------
Public Property Get TPInfoItem(ByVal strTP_ID As String) As Iconis_CLS_TPinfo
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo_Manager", "Get_TPInfoItem", "Begin Property")

    If Not (m_TPInfo_List Is Nothing) Then
        If (strTP_ID <> "") Then
            Set TPInfoItem = m_TPInfo_List.Item(strTP_ID)
        Else
            Set TPInfoItem = Nothing
        End If
    Else
        Set TPInfoItem = Nothing
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo_Manager", "Get_TPInfoItem", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo_Manager::ReadTPinfo_XMLString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of TP Infos
'-------------------------------------------------------------------------------
Private Sub ReadTPinfo_XMLString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo_Manager", "ReadTPinfo_XMLString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oPointList As IXMLDOMNodeList
   Dim oPoint As IXMLDOMElement
   Dim strTPName As String
   Dim strTPID As String
   Dim strSDName As String
   Dim strSDID As String
   Dim l_TPInfo As Iconis_CLS_TPinfo
      
   strXMLString = m_OPC_TPInfoList.Value
   If (strXMLString <> "") Then
   
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Track Portion"
                    Set oPointList = oDoc.documentElement.selectNodes(c_strTPNode)
                    If Not (oPointList Is Nothing) Then
                        If (oPointList.length > 0) Then
                            For Each oPoint In oPointList
                                ' TP Name attribute
                                strTPName = Format(oPoint.getAttribute(c_strTPNameAttr))
                                ' TP ID attribute
                                strTPID = Format(oPoint.getAttribute(c_strTPIDAttr))
                                ' SD Name attribute
                                strSDName = Format(oPoint.getAttribute(c_strSDNameAttr))
                                ' SD ID attribute
                                strSDID = Format(oPoint.getAttribute(c_strSDIDAttr))
                                Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TPInfo_Manager", "ReadTPinfo_XMLString", _
                                             "TP Name=" & strTPName & "TP ID=" & strTPID & "SD Name=" & strSDName & "SD ID=" & strSDID)
                                
                                If ((strTPID <> "") And (strTPName <> "") And (strSDID <> "") And (strSDName <> "")) Then
                                    ' Create an instance of Iconis_CLS_Platform class module
                                    Set l_TPInfo = New Iconis_CLS_TPinfo
                                    If Not (l_TPInfo Is Nothing) Then
                                        ' Init the instance
                                        l_TPInfo.Init strTPID, strTPName, strSDID, strSDName
                                        ' Memorize the instance in a collection
                                        m_TPInfo_List.Add l_TPInfo, strTPID
                                    End If
                                End If
                                
                            Next oPoint
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo_Manager", "ReadTPinfo_XMLString", _
                                         "No point has been defined in the OPC variable [" & m_OPC_TPInfoList.Name & "]")
                        End If
                        Set oPointList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo_Manager", "ReadTPinfo_XMLString", _
                             "The content of the OPC variable [" & m_OPC_TPInfoList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo_Manager", "ReadTPinfo_XMLString", _
                     "The OPC variable [" & m_OPC_TPInfoList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo_Manager", "ReadTPinfo_XMLString", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo_Manager::m_OPC_TPInfoList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of Track Portion informations
'-----------------------------------------------------------------------------------
Private Sub m_OPC_TPInfoList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TPInfo_Manager", "m_OPC_TPInfoList_ValueChange", "Begin Subroutine")
        
    
    If (m_OPC_TPInfoList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo_Manager", "m_OPC_TPInfoList_ValueChange", "The status of " & m_OPC_TPInfoList.Name & " is Waiting")
    ElseIf (m_OPC_TPInfoList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo_Manager", "m_OPC_TPInfoList_ValueChange", "The status of " & m_OPC_TPInfoList.Name & " is Config Error")
    ElseIf (m_OPC_TPInfoList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TPInfo_Manager", "m_OPC_TPInfoList_ValueChange", "The status of " & m_OPC_TPInfoList.Name & " is Not Connected")
    ElseIf (m_OPC_TPInfoList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TPInfo_Manager", "m_OPC_TPInfoList_ValueChange", "The Quality of " & m_OPC_TPInfoList.Name & " is not good")
    Else
       If (m_bTPInfoListFlag = False) Then
            ' Set the flag indicating that data have been received
            m_bTPInfoListFlag = True
            ' Read the string
            ReadTPinfo_XMLString
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo_Manager", "m_OPC_TPInfoList_ValueChange", Err.Description)
End Sub


