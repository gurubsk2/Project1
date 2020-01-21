VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_Platforms"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_Platforms
'* *******************************************************************************************
'* Purpose: Manages platforms managed by the ATS server
'* *******************************************************************************************
'* Modification History:
'* Author:              Nicole FLORIAN
'* Date:                August '12
'* Change:              All - CR ALPHA 270265

'* Author:              Eric Foissey
'* Date:                August '12
'* Change:              All - CR ALPHA 319513

'* Author:              Eric Foissey
'* Date:                September '13
'* Change:              CR Atcvm 176330 : add KP management.
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' -----------------------------------------------------

' Used to read the string (XML format) containing the list of platforms
Private Const c_strPlatformNode As String = "Platform"
Private Const c_strNameAttr As String = "Name"
Private Const c_strIDAttr As String = "ID"
Private Const c_strStationNameAttr As String = "StationName"
Private Const c_strStationIDAttr As String = "StationID"
Private Const c_strKMAttr As String = "KmPosition"

' Path of the OPC variable containing the list of platforms
Private Const c_strPlatformTag As String = "IconisHMI.PlatformsList.Information.Value"

' Class attributes
' ------------------------------------------------------
' Flag indicating if the value of the OPC variable containing the list of the platforms has been received
Private m_bPlatformsFlag As Boolean

' Local OPC variables
' ------------------------------------------------------
' Collection of the Iconis_CLS_Platform instances
Private m_Platforms As New Collection

' OPC server's variables
' ------------------------------------------------------
' OPC variable containing the list of the platforms
Private WithEvents m_OPC_PlatformList As Variable
Attribute m_OPC_PlatformList.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platforms::Class_Initialize
' Input:        nonr
' Output:       none
' Description:  Object constructor
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platforms", "Class_Initialize", "Begin Subroutine")
    
    Set m_OPC_PlatformList = Variables.Add(MOD_Deployment.Level2Cluster & c_strPlatformTag, fvVariableTypeText)
    If (m_OPC_PlatformList.EnableEvents = True) Then
        m_OPC_PlatformList_ValueChange
    Else
        m_OPC_PlatformList.EnableEvents = True
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "Class_Initialize", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platforms::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platforms", "Class_Terminate", "Begin Subroutine")
    
    Dim I As Integer
    If Not (m_Platforms Is Nothing) Then
        For I = 1 To m_Platforms.Count
            m_Platforms.Remove 1
        Next
        Set m_Platforms = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_PlatformList Is Nothing) Then
        Variables.Remove (m_OPC_PlatformList.Name)
        Set m_OPC_PlatformList = Nothing
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platforms::Get_PlatformItem
' Input:        strName [String] Name of the platform
' Output:       [Iconis_CLS_Platform] the Iconis_CLS_Platform instance
' Description:  Returns the Iconis_CLS_Platform instance
'-------------------------------------------------------------------------------
Public Property Get PlatformItem(ByVal strName As String) As Iconis_CLS_Platform
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platforms", "Get_PlatformItem", "Begin Property")

    If Not (m_Platforms Is Nothing) Then
        If (strName <> "") Then
            Set PlatformItem = m_Platforms.Item(strName)
        Else
            Set PlatformItem = Nothing
        End If
    Else
        Set PlatformItem = Nothing
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "Get_PlatformItem", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platforms::ReadPlatformXMLString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of platforms
'-------------------------------------------------------------------------------
Private Sub ReadPlatformXMLString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platforms", "ReadPlatformXMLString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oPlatformList As IXMLDOMNodeList
   Dim oPlatform As IXMLDOMElement
   Dim strName As String
   Dim strID As String
   Dim strStationName As String
   Dim strStationID As String
   Dim dKM As Double
   Dim PlatformManager As Iconis_CLS_Platform
   
   strXMLString = m_OPC_PlatformList.Value
   If (strXMLString <> "") Then
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Platform"
                    Set oPlatformList = oDoc.documentElement.selectNodes(c_strPlatformNode)
                    If Not (oPlatformList Is Nothing) Then
                        If (oPlatformList.length > 0) Then
                            For Each oPlatform In oPlatformList
                                ' Name attribute
                                strName = Format(oPlatform.getAttribute(c_strNameAttr))
                                ' ID attribute
                                strID = Format(oPlatform.getAttribute(c_strIDAttr))
                                ' StationName attribute
                                strStationName = Format(oPlatform.getAttribute(c_strStationNameAttr))
                                ' StationID attribute
                                strStationID = Format(oPlatform.getAttribute(c_strStationIDAttr))
                                ' KM attribute
                                dKM = oPlatform.getAttribute(c_strKMAttr)
                                
                                If ((strID <> "") And (strName <> "") And _
                                    (strStationID <> "") And (strStationName <> "")) Then
                                    ' Create an instance of Iconis_CLS_Platform class module
                                    Set PlatformManager = New Iconis_CLS_Platform
                                    If Not (PlatformManager Is Nothing) Then
                                        ' Init the instance
                                        PlatformManager.Init strID, strName, strStationID, strStationName, dKM
                                        ' Memorize the instance in a collection
                                        m_Platforms.Add PlatformManager, strName
                                    End If
                                End If
                            Next oPlatform
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "ReadPlatformXMLString", _
                                         "No platform has been defined in the OPC variable [" & m_OPC_PlatformList.Name & "]")
                        End If
                        Set oPlatformList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "ReadPlatformXMLString", _
                             "The content of the OPC variable [" & m_OPC_PlatformList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "ReadPlatformXMLString", _
                     "The OPC variable [" & m_OPC_PlatformList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "ReadPlatformXMLString", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platforms::m_OPC_PlatformList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of platforms
'-----------------------------------------------------------------------------------
Private Sub m_OPC_PlatformList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Platforms", "m_OPC_PlatformList_ValueChange", "Begin Subroutine")

    If (m_OPC_PlatformList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platforms", "m_OPC_PlatformList_ValueChange", "The status of " & m_OPC_PlatformList.Name & " is Waiting")
    ElseIf (m_OPC_PlatformList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "m_OPC_PlatformList_ValueChange", "The status of " & m_OPC_PlatformList.Name & " is Config Error")
    ElseIf (m_OPC_PlatformList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Platforms", "m_OPC_PlatformList_ValueChange", "The status of " & m_OPC_PlatformList.Name & " is Not Connected")
    ElseIf (m_OPC_PlatformList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Platforms", "m_OPC_PlatformList_ValueChange", "The Quality of " & m_OPC_PlatformList.Name & " is not good")
    Else
       If (m_bPlatformsFlag = False) Then
            ' Set the flag indicating that data have been received
            m_bPlatformsFlag = True
            ' Read the string
            ReadPlatformXMLString
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "m_OPC_PlatformList_ValueChange", Err.Description)
End Sub
