VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_DeviceAlarms"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_DeviceAlams
'* *******************************************************************************************
'* Purpose: Manages alarms (which can be inhibited/un-inhibit) of a device
'* *******************************************************************************************
'* Modification History:
'* Author:              Nicole FLORIAN
'* Date:                March '12
'* Change:              All - CR ALPHA 260897

'* Author:              Nicole FLORIAN
'* Date:                March '12
'* Change:              CR ALPHA 260897 - Complement1

'* Author:              Nicole FLORIAN
'* Date:                March '12
'* Change:              CR ALPHA 260900

'* Author:              Nicole FLORIAN
'* Date:                April '12
'* Change:              CR ALPHA 260900 - Complement1
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
Private Const c_strItemSeparator As String = ";"
Private Const c_strCoupleSeparator As String = ","

' Value associated to inhibited state value
Private Const c_iInhibitedStateValue As Integer = 0

' Value associated to commands
Private Const c_iInhibitCmd As Integer = 1      ' Inhibition of one alarm
Private Const c_iUninhibitCmd As Integer = 2    ' Un-inhibition of one alarm
Private Const c_iInhibitAllCmd As Integer = 3   ' Inhibition of all alarms
Private Const c_iUninhibitAllCmd As Integer = 4 ' Un-inhibition of all alarms

' Used to read the strings (XML format) containing the list of alarms
Private Const c_strKeyNode As String = "Key"
Private Const c_strDateTimeAttr As String = "DateTime"
Private Const c_strNameAttr As String = "Name"
Private Const c_strLabelAttr As String = "Label"
Private Const c_strStateValueAttr As String = "StateValue"
Private Const c_strStateAttr As String = "State"

' Path of OPC variables
Private Const c_strXmlKeys As String = ".AlarmInhibition.XmlKeys"
Private Const c_strInhibitKeyCtrl As String = ".AlarmInhibition.InhibitKey"
Private Const c_strActivateKeyCtrl As String = ".AlarmInhibition.ActivateKey"
Private Const c_strInhibitedAllCtrl As String = ".AlarmInhibition.InhibitedAll"

' Path of the variable containing alarms of a device for whose the inhibition state has changed
Private Const c_strAlarmsInhibitionStateTag As String = "@AlarmsInhibitionState%"

' Class attributes
' ------------------------------------------------------
' Device name
Private m_strDeviceName As String
' Path of device
Private m_strPath As String
' Path of device without the root
Private m_strPathWithoutRoot As String
' Collection of all alarms of the device
Private m_DeviceAlarms As New Collection
' Boolean indicating if it exists at least one inhibited alarm for the device
Private m_OneInhibitedAlarm As Boolean
' Flag indicating if data of alarms have been received
Private m_bDataInitFlag As Boolean
' Separator used to separate items in the path
Private m_strPathSeparator As String

' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------
Dim WithEvents m_OPCSet_DeviceVariables As Iconis_CLS_OPCSet
Attribute m_OPCSet_DeviceVariables.VB_VarHelpID = -1
Dim WithEvents m_OPCItem_txtXmlKeys As Iconis_CLS_OPCSet_Item
Attribute m_OPCItem_txtXmlKeys.VB_VarHelpID = -1
Dim WithEvents m_OPCItem_txtActivateKeyCtrl As Iconis_CLS_OPCSet_Item
Attribute m_OPCItem_txtActivateKeyCtrl.VB_VarHelpID = -1
Dim WithEvents m_OPCItem_txtInhibitKeyCtrl As Iconis_CLS_OPCSet_Item
Attribute m_OPCItem_txtInhibitKeyCtrl.VB_VarHelpID = -1
Dim WithEvents m_OPCItem_txtInhibitedAllCtrl As Iconis_CLS_OPCSet_Item
Attribute m_OPCItem_txtInhibitedAllCtrl.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_DeviceAlams::Init
' Input:        [String]   Area name
'               [String]   ID of the device
'               [String]   Name of the device
' Output:       none
' Description:  Init OPC and local variables
'-------------------------------------------------------------------------------
Public Sub Init(ByVal strDeviceCategoryName As String, ByVal strAreaName As String, _
                ByVal strDeviceID As String, ByVal strDeviceName As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlams", "Init", "Begin Subroutine")
    Dim strCommonPath As String
    
    ' Retrieve the separator used to separate items in the path
    m_strPathSeparator = Iconis_MOD_General.GetDeviceCategoriesManager.PathSeparator
    
    ' Init class attributes
    m_strDeviceName = strDeviceName
    ' Content of the device path (without the root) is:
    ' <DeviceCategoryName>/<GeographicalAreaName>/<DeviceName>
    m_strPathWithoutRoot = strDeviceCategoryName & m_strPathSeparator & _
                           strAreaName & m_strPathSeparator & _
                           strDeviceName
    ' Content of the device path (with root name) is:
    ' <RootName>/<DeviceCategoryName>/<GeographicalAreaName>/<DeviceName>
    m_strPath = Iconis_MOD_General.GetDeviceCategoriesManager.RootName & m_strPathSeparator & _
                m_strPathWithoutRoot
    
    ' Connect to the server OPC variables
    strCommonPath = Iconis_MOD_General.GetOPCCluster & strDeviceID
    Set m_OPCSet_DeviceVariables = Iconis_MOD_General.CreateNew_Iconis_CLS_OPCSet
    Set m_OPCItem_txtXmlKeys = m_OPCSet_DeviceVariables.AddItem(strCommonPath & c_strXmlKeys, fvVariableTypeText, c_OPCReadOnly)
    Set m_OPCItem_txtActivateKeyCtrl = m_OPCSet_DeviceVariables.AddItem(strCommonPath & c_strActivateKeyCtrl, fvVariableTypeText, c_OPCWriteOnly)
    Set m_OPCItem_txtInhibitKeyCtrl = m_OPCSet_DeviceVariables.AddItem(strCommonPath & c_strInhibitKeyCtrl, fvVariableTypeText, c_OPCWriteOnly)
    Set m_OPCItem_txtInhibitedAllCtrl = m_OPCSet_DeviceVariables.AddItem(strCommonPath & c_strInhibitedAllCtrl, fvVariableTypeBit, c_OPCWriteOnly)
   
    ' Connect the variables
    m_OPCSet_DeviceVariables.DoConnect (strDeviceID)
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlams", "Init", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_DeviceAlams::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlams", "Class_Terminate", "Begin Subroutine")
    Dim I As Long
    
    If Not (m_DeviceAlarms Is Nothing) Then
        For I = 1 To m_DeviceAlarms.Count
            m_DeviceAlarms.Remove 1
        Next
        Set m_DeviceAlarms = Nothing
    End If
    
    If Not (m_OPCSet_DeviceVariables Is Nothing) Then
        m_OPCSet_DeviceVariables.Destroy
        Set m_OPCSet_DeviceVariables = Nothing
    End If
    Set m_OPCItem_txtXmlKeys = Nothing
    Set m_OPCItem_txtActivateKeyCtrl = Nothing
    Set m_OPCItem_txtInhibitKeyCtrl = Nothing
    Set m_OPCItem_txtInhibitedAllCtrl = Nothing
        
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlams", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_DeviceAlams::Get_Name
' Input:        none
' Output:       [String] The device name
' Description:  Returns the device name
'-------------------------------------------------------------------------------
Public Property Get Name() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlams", "Get_Name", "Begin Property")

    Name = m_strDeviceName

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlams", "Get_Name", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_DeviceAlams::Get_Path
' Input:        none
' Output:       [String] The device path
' Description:  Returns the device path
'-------------------------------------------------------------------------------
Public Property Get Path() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlams", "Get_Path", "Begin Property")

    Path = m_strPath

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlams", "Get_Path", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_DeviceAlams::Get_ExistInhibitedAlarm
' Input:        none
' Output:       [Boolean] at least one inhibited alarm exists
' Description:  Returns a boolean indicating if at least inhibited alarm exists
'-------------------------------------------------------------------------------
Public Property Get ExistInhibitedAlarm() As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlams", "Get_ExistInhibitedAlarm", "Begin Property")
        
   ExistInhibitedAlarm = m_OneInhibitedAlarm

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlams", "Get_ExistInhibitedAlarm", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_DeviceAlams::GetAlarms
' Input:        none
' Output:       [Collection]   Collection of all alarms of the device
' Description:  Returns the collection of all alarms of the device
'-------------------------------------------------------------------------------
Public Function GetAlarms() As Collection
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlams", "GetAlarms", "Begin Function")
    
    If Not (m_DeviceAlarms Is Nothing) Then
        Set GetAlarms = m_DeviceAlarms
    Else
        Set GetAlarms = Nothing
    End If
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlams", "GetAlarms", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:        Iconis_CLS_DeviceAlams::SendCommand
' Input:       iCmdType     [Integer] Type of the command
'              strKeyName   [String, Optional]  Name of the alarm key
' Output:      none
' Description: Send a command
'-------------------------------------------------------------------------------
Public Sub SendCommand(ByVal iCmdType As Integer, Optional ByVal strKeyName As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlams", "SendCommand", "Begin Subroutine")
    
    If (iCmdType = c_iInhibitCmd) Then ' Inhibit one alarm
        If (m_OPCItem_txtInhibitKeyCtrl.Status = fvVariableStatusGood) Then
            m_OPCItem_txtInhibitKeyCtrl.Value = strKeyName
            
            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "SendCommand", _
                         "The alarm inhibition command has been sent - OPC variable->" & _
                         m_OPCItem_txtInhibitKeyCtrl.strPath & " - Key name->" & strKeyName)
        Else
            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "SendCommand", _
                         "The alarm inhibition command has not been sent - OPC variable->" & _
                         m_OPCItem_txtInhibitKeyCtrl.strPath & " - Key name->" & strKeyName)
        End If
    ElseIf (iCmdType = c_iInhibitAllCmd) Then ' Inhibit all alarms
        If (m_OPCItem_txtInhibitedAllCtrl.Status = fvVariableStatusGood) Then
            m_OPCItem_txtInhibitedAllCtrl.Value = 1 ' True
            
            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "SendCommand", _
                         "The inhibition command of all alarms has been sent - OPC variable->" & _
                         m_OPCItem_txtInhibitedAllCtrl.strPath)
        Else
            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "SendCommand", _
                         "The inhibition command of all alarms has not been sent - OPC variable->" & _
                         m_OPCItem_txtInhibitedAllCtrl.strPath)
        End If
    ElseIf (iCmdType = c_iUninhibitCmd) Then ' Un-inhibit one alarm
        If (m_OPCItem_txtActivateKeyCtrl.Status = fvVariableStatusGood) Then
            m_OPCItem_txtActivateKeyCtrl.Value = strKeyName
            
            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "SendCommand", _
                         "The alarm un-inhibition command has been sent - OPC variable->" & _
                         m_OPCItem_txtActivateKeyCtrl.strPath & " - Key name->" & strKeyName)
        Else
             Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "SendCommand", _
                         "The alarm un-inhibition command has not been sent - OPC variable->" & _
                         m_OPCItem_txtActivateKeyCtrl.strPath & " - Key name->" & strKeyName)
        End If
    ElseIf (iCmdType = c_iUninhibitAllCmd) Then ' Un-inhibit all alarms
        If (m_OPCItem_txtInhibitedAllCtrl.Status = fvVariableStatusGood) Then
            m_OPCItem_txtInhibitedAllCtrl.Value = 0 ' False
            
            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "SendCommand", _
                         "The un-inhibition command of all alarms has been sent - OPC variable->" & _
                         m_OPCItem_txtInhibitedAllCtrl.strPath)
        Else
             Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "SendCommand", _
                         "The un-inhibition command of all alarms has not been sent - OPC variable->" & _
                         m_OPCItem_txtInhibitedAllCtrl.strPath)
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlams", "SendCommand", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_DeviceAlarms::m_OPCItem_txtXmlKeys_OnRefresh
' Input:        Value [Variant]                The value
'               Quality [fvVariableStatus]     The corresponding quality
' Output:       none
' Description:  Read the XML format string
'-------------------------------------------------------------------------------
Private Sub m_OPCItem_txtXmlKeys_OnRefresh(Value As Variant, Quality As Integer)
    On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlarms", "m_OPCItem_txtXmlKeys_OnRefresh", "Begin Subroutine")
    
    ReadXMLString
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "m_OPCItem_txtXmlKeys_OnRefresh", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_DeviceAlams::CheckAlarmInhibitionState
' Input:        strKeyName              [String]  Alarm key name
'               strInhibitionDateTime   [String]  Inhibition date and time
'               strState                [String]  Inhibition state (string)
'               iStateValue             [Integer] Inhibition state (value)
'               strModifiedAlarms       [String]  List of modified alarms
' Output:       none
' Description:  If the inhibition state of the alarm has been modified,
'               memorizes path and the inhibition state of the alarm in the
'               temporary string
'-------------------------------------------------------------------------------
Private Sub CheckAlarmInhibitionState(ByVal strKeyName As String, ByVal strInhibitionDateTime As String, _
                                      ByVal strState As String, ByVal strStateValue As Integer, _
                                      ByRef strModifiedAlarms As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlams", "CheckAlarmInhibitionState", "Begin Subroutine")
    Dim Alarm As Iconis_CLS_Alarm
    
    ' Check if the inhibition state of the alarm has been modified
    Set Alarm = m_DeviceAlarms.Item(strKeyName)
    If Not (Alarm Is Nothing) Then
        If (Alarm.StateValue <> Val(strStateValue)) Then
            ' Update the inhibition date/time
            Alarm.InhibitionDateTime = strInhibitionDateTime
            ' Update the inhibition state (value)
            Alarm.StateValue = Val(strStateValue)
            ' Update the inhibition state (string)
            Alarm.State = strState
        
            ' Memorize the path and the inhibition state (value and string) of the alarm in the temporary string
            strModifiedAlarms = strModifiedAlarms & Alarm.Path & c_strCoupleSeparator & _
                                strState & c_strCoupleSeparator & _
                                strStateValue & c_strItemSeparator
                            
            If (Val(strStateValue) = c_iInhibitedStateValue) Then ' Inhibited alarm
                ' Add the instance in the collection of all inhibited alarms
                Iconis_MOD_General.GetDeviceCategoriesManager.AddInhibitedAlarm Alarm
            Else ' Un-inhibited alarm
                ' Remove the instance from the collection of all inhibited alarms
                Iconis_MOD_General.GetDeviceCategoriesManager.RemoveInhibitedAlarm Alarm
            End If
        End If
    End If
           
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlams", "CheckAlarmInhibitionState", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_DeviceAlarms::ReadXMLString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of alarms
'-------------------------------------------------------------------------------
Private Sub ReadXMLString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_DeviceAlarms", "ReadXMLString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oKeysList As IXMLDOMNodeList
   Dim oKey As IXMLDOMElement
   Dim strKeyName As String
   Dim strDateTime As String
   Dim strLabel As String
   Dim strState As String
   Dim strStateValue As String
   Dim AlarmManager As Iconis_CLS_Alarm
   Dim strModifiedAlarms As String
   
   strXMLString = m_OPCItem_txtXmlKeys.Value
   If (strXMLString <> "") Then
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Key"
                    Set oKeysList = oDoc.documentElement.selectNodes(c_strKeyNode)
                    If Not (oKeysList Is Nothing) Then
                        If (oKeysList.length > 0) Then
                            ' reset variable indicating if it exists at least one inhibited alarm for the device
                            m_OneInhibitedAlarm = False
                            For Each oKey In oKeysList
                                ' Name attribute
                                strKeyName = Format(oKey.getAttribute(c_strNameAttr))
                                ' DateTime attribute
                                strDateTime = oKey.getAttribute(c_strDateTimeAttr)
                                ' StateValue attribute
                                strStateValue = Format(oKey.getAttribute(c_strStateValueAttr))
                                ' State attribute
                                strState = Format(oKey.getAttribute(c_strStateAttr))
                                ' Label attribute
                                strLabel = Format(oKey.getAttribute(c_strLabelAttr))
                                If (strKeyName <> "") And (strLabel <> "") And (strState <> "") And (strStateValue <> "") Then
                                    If (Val(strStateValue) = c_iInhibitedStateValue) Then
                                        ' At least one inhibited alarm exists for the device
                                        m_OneInhibitedAlarm = True
                                    End If
                                    If (m_bDataInitFlag = False) Then
                                        ' Create an instance of Iconis_CLS_Alarm class module
                                        Set AlarmManager = New Iconis_CLS_Alarm
                                        If Not (AlarmManager Is Nothing) Then
                                            ' Init the instance
                                            AlarmManager.Init strKeyName, strDateTime, strLabel, strState, Val(strStateValue), _
                                                              m_strPath & m_strPathSeparator & strKeyName, _
                                                              m_strPathWithoutRoot
                                            ' Memorize the instance in the collection of all alarms of the device
                                            m_DeviceAlarms.Add AlarmManager, strKeyName
                                            If (Val(strStateValue) = c_iInhibitedStateValue) Then
                                                ' Memorize the instance in the collection of all inhibited alarms
                                                Iconis_MOD_General.GetDeviceCategoriesManager.AddInhibitedAlarm AlarmManager
                                            End If
                                        End If
                                    Else
                                        ' Check if the inhibition state of the alarm has changed
                                        CheckAlarmInhibitionState strKeyName, strDateTime, strState, strStateValue, strModifiedAlarms
                                    End If
                                End If
                            Next oKey
                            
                            If (m_bDataInitFlag = False) Then
                                ' Set flag indicating data have been received
                                m_bDataInitFlag = True
                            ElseIf (strModifiedAlarms <> "") Then
                                ' Update variable containing alarms of a device for whose the inhibition state has changed
                                Variables.Item(c_strAlarmsInhibitionStateTag).Value = strModifiedAlarms
                            End If
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "ReadXMLString", _
                                         "No alarm key has been defined in the OPC variable [" & m_OPCItem_txtXmlKeys.strPath & "]")
                        End If
                        Set oKeysList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "ReadXMLString", _
                             "The content of the OPC variable [" & m_OPCItem_txtXmlKeys.strPath & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "ReadXMLString", _
                     "The OPC variable [" & m_OPCItem_txtXmlKeys.strPath & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_DeviceAlarms", "ReadXMLString", Err.Description)
End Sub
