VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_Versions"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2011. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_Versions
'* *******************************************************************************************
'* Purpose:     Send version numbers and names of project, urbalis system, subsystems
'*              associated to the operator workstation to the ATS server
'* *******************************************************************************************
'* Modification History:
'* Author:              Nicole FLORIAN
'* Date:                January '11
'* Change:              All - CR ALPHA 214278
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
' Used to read the XML format string
Private Const c_strIDAttr As String = "ID"

' Path to the OPC server variables
Private Const c_strATSListTag As String = "IconisHMI.ATSsList.Value"
Private Const c_strWorkstationTag As String = ".WKS."
Private Const c_strVersionTag As String = ".Version.Value"

' Used to build the XML format string
Private Const c_strSystemNode As String = "System"
Private Const c_strSubSystemNode As String = "SubSystem"
Private Const c_strProjectNameAttr As String = "ProjectName"
Private Const c_strProjectVersionAttr As String = "ProjectVersion"
Private Const c_strSystemNameAttr As String = "SystemName"
Private Const c_strSystemVersionAttr As String = "SystemVersion"
Private Const c_strSubSystemNameAttr As String = "Name"
Private Const c_strSubSystemVersionAttr As String = "Version"

' Version numbers
Private Const c_strProjectVersionLocalTag As String = "HMI.Configuration.HMIVersion%"
Private Const c_strUrbalisVersionLocalTag As String = "HMI.Configuration.UrbalisVersion%"
Private Const c_strICONISVersionLocalTag As String = "HMI.Configuration.IconisVersion%"
Private Const c_strCBVersionLocalTag As String = "HMI.Configuration.CBVersion%"
' Names
Private Const c_strProjectNameLocalTag As String = "HMI.Configuration.ProjectName%"
Private Const c_strUrbalisNameLocalTag As String = "HMI.Configuration.UrbalisName%"
Private Const c_strICONISNameLocalTag As String = "HMI.Configuration.IconisName%"
Private Const c_strCBNameLocalTag As String = "HMI.Configuration.CBName%"

' Class attributes
' ------------------------------------------------------

' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------
' List of the ATS
Private WithEvents m_OPC_ATSList As Variable
Attribute m_OPC_ATSList.VB_VarHelpID = -1
' Variable in wich data (version numbers and names) will be sent
Private WithEvents m_OPC_WorkstationVersion As Variable
Attribute m_OPC_WorkstationVersion.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Versions::Class_Initialize
' Input:        nonr
' Output:       none
' Description:  Object constructor
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Versions", "Class_Initialize", "Begin Subroutine")
    
    Set m_OPC_ATSList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strATSListTag, fvVariableTypeText)
    If (m_OPC_ATSList.EnableEvents = True) Then
        m_OPC_ATSList_ValueChange
    Else
        m_OPC_ATSList.EnableEvents = True
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "Class_Initialize", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Versions::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Versions", "Class_Terminate", "Begin Subroutine")
    
    ' Unsubscribe all the variables previously subscribed
    If Not (m_OPC_ATSList Is Nothing) Then
        Variables.Remove (m_OPC_ATSList.Name)
        Set m_OPC_ATSList = Nothing
    End If
    
    If Not (m_OPC_WorkstationVersion Is Nothing) Then
        Variables.Remove (m_OPC_WorkstationVersion.Name)
        Set m_OPC_WorkstationVersion = Nothing
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Versions::ReadXmlString
' Input:        none
' Output:       none
' Description:  - Retrieve the ID of the current ATS from the XML format string
'               - Add the OPC variable in which data (version numbers and names)
'                 will be sent to the list of variables
'-------------------------------------------------------------------------------
Private Sub ReadXMLString()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Versions", "ReadXmlString", "Begin Subroutine")
   
    If (m_OPC_ATSList.Value <> "") Then
        Dim oDoc As DOMDocument
    
        Set oDoc = New DOMDocument
        If (oDoc.loadXML(m_OPC_ATSList.Value)) Then
            Dim rootNode As IXMLDOMElement

            Set rootNode = oDoc.documentElement
            If Not (rootNode Is Nothing) Then
                Dim strATSID As String
                
                ' Retrieve the ID of the current ATS
                strATSID = Format(rootNode.getAttribute(c_strIDAttr))
                If (strATSID <> "") Then
                    Dim strPath As String
                    
                    ' Add OPC variable associated to the version of the current workstation (connected to the current ATS)
                    strPath = Iconis_MOD_General.GetOPCCluster & strATSID & c_strWorkstationTag & _
                              ThisSystem.ComputerName & c_strVersionTag
                    Set m_OPC_WorkstationVersion = Variables.Add(strPath, fvVariableTypeText)
                    If (m_OPC_WorkstationVersion.EnableEvents = True) Then
                        m_OPC_WorkstationVersion_ValueChange
                    Else
                        m_OPC_WorkstationVersion.EnableEvents = True
                    End If
                Else
                    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "ReadXmlString", "ID of the current ATS is empty")
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "ReadXmlString", "ID of the current ATS has not been found")
            End If
            Set rootNode = Nothing
        Else
            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "ReadXmlString", "ID of the current ATS has not been found")
        End If
        Set oDoc = Nothing
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "ReadXmlString", "The OPC variable (" & m_OPC_ATSList.Name & ") is empty")
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "ReadXmlString", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Versions::SendData
' Input:        none
' Output:       none
' Description:  Send data (version numbers and names) to the ATS server
'-------------------------------------------------------------------------------
Private Sub SendData()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Versions", "SendData", "Begin Subroutine")
   
    Dim oDoc As DOMDocument
    Dim System_Node As IXMLDOMElement
    Dim IconisHMISubSystem_Node As IXMLDOMElement
    Dim CBSubSystem_Node As IXMLDOMElement
    
    ' Create an instance of DOMDocument
    Set oDoc = New DOMDocument
        
    ' Make the <System...> root node
    Set System_Node = oDoc.createElement(c_strSystemNode)
    oDoc.appendChild System_Node
        
    ' Add the "ProjectName" attribute
    System_Node.setAttribute c_strProjectNameAttr, Variables.Item(c_strProjectNameLocalTag).Value
    ' Add the "ProjectVersion" attribute
    System_Node.setAttribute c_strProjectVersionAttr, Variables.Item(c_strProjectVersionLocalTag).Value
    ' Add the "SystemName" attribute
    System_Node.setAttribute c_strSystemNameAttr, Variables.Item(c_strUrbalisNameLocalTag).Value
    ' Add the "SystemVersion" attribute
    System_Node.setAttribute c_strSystemVersionAttr, Variables.Item(c_strUrbalisVersionLocalTag).Value
    
    ' Make the 1st child node <SubSystem> of the root node
    Set IconisHMISubSystem_Node = System_Node.ownerDocument.createElement(c_strSubSystemNode)
    System_Node.appendChild IconisHMISubSystem_Node
    ' Add the "Name" attribute
    IconisHMISubSystem_Node.setAttribute c_strSubSystemNameAttr, Variables.Item(c_strICONISNameLocalTag).Value
    ' Add the "Version" attribute
    IconisHMISubSystem_Node.setAttribute c_strSubSystemVersionAttr, Variables.Item(c_strICONISVersionLocalTag).Value
    
    ' Make the 2nd child node <SubSystem> of the root node
    Set CBSubSystem_Node = System_Node.ownerDocument.createElement(c_strSubSystemNode)
    System_Node.appendChild CBSubSystem_Node
    ' Add the "Name" attribute
    CBSubSystem_Node.setAttribute c_strSubSystemNameAttr, Variables.Item(c_strCBNameLocalTag).Value
    ' Add the "Version" attribute
    CBSubSystem_Node.setAttribute c_strSubSystemVersionAttr, Variables.Item(c_strCBVersionLocalTag).Value
        
    If ((m_OPC_WorkstationVersion.Status = fvVariableStatusGood) And (m_OPC_WorkstationVersion.Quality = 192)) Then
        ' Sending of data
        m_OPC_WorkstationVersion.Value = System_Node.xml

        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "SendData", _
                     "Data (versions and names) have been sent - OPC variable : " & m_OPC_WorkstationVersion.Name)
    Else
        ' Status or quality are not good : no sending of data
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "SendData", "Data (versions and names) have not been sent")
    End If
    
    Set IconisHMISubSystem_Node = Nothing
    Set CBSubSystem_Node = Nothing
    Set System_Node = Nothing
    Set oDoc = Nothing
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "SendData", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Versions::m_OPC_ATSList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the ID of the current ATS
'-------------------------------------------------------------------------------
Private Sub m_OPC_ATSList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Versions", "m_OPC_ATSList_ValueChange", "Begin Subroutine")

    ' Check the status and the quality of the variable
    If (m_OPC_ATSList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Versions", "m_OPC_ATSList_ValueChange", "The status of " & m_OPC_ATSList.Name & " is Waiting")
    ElseIf (m_OPC_ATSList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "m_OPC_ATSList_ValueChange", "The status of " & m_OPC_ATSList.Name & " is Config Error")
    ElseIf (m_OPC_ATSList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Versions", "m_OPC_ATSList_ValueChange", "The status of " & m_OPC_ATSList.Name & " is Not Connected")
    ElseIf (m_OPC_ATSList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Versions", "m_OPC_ATSList_ValueChange", "The Quality of " & m_OPC_ATSList.Name & " is not good")
    Else
        ' Read the XML format string and retrieve the ID of the current ATS
        ReadXMLString
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "m_OPC_ATSList_ValueChange", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Versions::m_OPC_WorkstationVersion_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable in which data (version numbers and names)
'               will be sent
'-------------------------------------------------------------------------------
Private Sub m_OPC_WorkstationVersion_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Versions", "m_OPC_WorkstationVersion_ValueChange", "Begin Subroutine")

    ' Check the status and the quality of the variable
    If (m_OPC_WorkstationVersion.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Versions", "m_OPC_WorkstationVersion_ValueChange", "The status of " & m_OPC_WorkstationVersion.Name & " is Waiting")
    ElseIf (m_OPC_WorkstationVersion.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "m_OPC_WorkstationVersion_ValueChange", "The status of " & m_OPC_WorkstationVersion.Name & " is Config Error")
    ElseIf (m_OPC_WorkstationVersion.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Versions", "m_OPC_WorkstationVersion_ValueChange", "The status of " & m_OPC_WorkstationVersion.Name & " is Not Connected")
    ElseIf (m_OPC_WorkstationVersion.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Versions", "m_OPC_WorkstationVersion_ValueChange", "The Quality of " & m_OPC_WorkstationVersion.Name & " is not good")
    Else
        ' Send data (version numbers and names)
        SendData
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Versions", "m_OPC_WorkstationVersion_ValueChange", Err.Description)
End Sub
