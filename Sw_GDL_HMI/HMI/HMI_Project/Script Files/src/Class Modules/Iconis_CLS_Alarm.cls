VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_Alarm"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_Alarm
'* *******************************************************************************************
'* Purpose: Manages an alarm which can be inhibited
'* *******************************************************************************************
'* Modification History:
'* Author:              Nicole FLORIAN
'* Date:                March '12
'* Change:              All - CR ALPHA 260897

'* Author:              Nicole FLORIAN
'* Date:                March '12
'* Change:              CR ALPHA 260900

'* Author:              Nicole FLORIAN
'* Date:                April '12
'* Change:              CR ALPHA 260900 - Complement2
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------

' Class attributes
' ------------------------------------------------------
' Key name of the alarm
Private m_strKeyName As String
' Date/time at which the alarm has been inhibited
Private m_strInhibitionDateTime As String
' Label of the alarm
Private m_strLabel As String
' Inhibition state (string) of the alarm
Private m_strInhibitionState As String
' Inhibition state (value) of the alarm
Private m_iInhibitionStateValue As Integer
' Path of the alarm
Private m_strPath As String
' Path of device (without root) to which the alarm belongs
Private m_strDevicePath As String

' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Init
' Input:        strKeyName              [String]    Name of the alarm key
'               strInhibitionDateTime   [String]    Inhibition date/time of alarm
'               strLabel                [String]    Label of the alarm
'               strState                [String]    Inhibition state of the alarm
'               iStateValue             [Integer]   Inhibition state value of the alarm
'               strPath                 [String]    Path of the alarm
'               strDevicePath           [String]    Path of the device (without root name)
'                                                   to which the alarm belongs
' Output:       none
' Description:  Init
'-------------------------------------------------------------------------------
Public Sub Init(ByVal strKeyName As String, ByVal strInhibitionDateTime As String, _
                ByVal strLabel As String, ByVal strState As String, _
                ByVal iStateValue As Integer, ByVal strPath As String, _
                ByVal strDevicePath As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Init", "Begin Subroutine")
    
    m_strKeyName = strKeyName
    ' Convert the inhibition date/time into the "mm/dd/yyyy hh:mm:ss" format
    If (strInhibitionDateTime <> "") Then
        m_strInhibitionDateTime = ConvertDateTime(strInhibitionDateTime)
    End If
    m_strLabel = strLabel
    m_strInhibitionState = strState
    m_iInhibitionStateValue = iStateValue
    ' <RootName>/<DeviceCategoryName>/<GeographicalAreaName>/<DeviceName>/<AlarmKeyName>
    m_strPath = strPath
    ' <DeviceCategoryName>/<GeographicalAreaName>/<DeviceName>
    m_strDevicePath = strDevicePath
   
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Init", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Get_Path
' Input:        none
' Output:       [String] the path
' Description:  Returns the path of the alarm
'-------------------------------------------------------------------------------
Public Property Get Path() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Get_Path", "Begin Property")
    
    Path = m_strPath

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Get_Path", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Get_DevicePath
' Input:        none
' Output:       [String] the device path (without root name)
' Description:  Returns the path (without root name) of the device to which
'               the alarm belongs
'-------------------------------------------------------------------------------
Public Property Get DevicePath() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Get_DevicePath", "Begin Property")
    
    DevicePath = m_strDevicePath

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Get_DevicePath", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Get_KeyName
' Input:        none
' Output:       [String] the key name
' Description:  Returns the key name of the alarm
'-------------------------------------------------------------------------------
Public Property Get KeyName() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Get_KeyName", "Begin Property")

    KeyName = m_strKeyName

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Get_KeyName", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Get_InhibitionDateTime
' Input:        none
' Output:       [String] the date/time of inhibition
' Description:  Returns the date/time at which the alarm has been inhibited
'-------------------------------------------------------------------------------
Public Property Get InhibitionDateTime() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Get_InhibitionDateTime", "Begin Property")

    InhibitionDateTime = m_strInhibitionDateTime

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Get_InhibitionDateTime", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Let_InhibitionDateTime
' Input:        strInhibitionDateTime [String]  the date/time of inhibition
' Output:       none
' Description:  Set the date/time of inhibition of the alarm
'-------------------------------------------------------------------------------
Public Property Let InhibitionDateTime(ByVal strInhibitionDateTime As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Let_InhibitionDateTime", "Begin Property")
   
    If (strInhibitionDateTime <> "") Then
        ' Convert the inhibition date/time into the "mm/dd/yyyy hh:mm:ss" format
        m_strInhibitionDateTime = ConvertDateTime(strInhibitionDateTime)
    Else
        m_strInhibitionDateTime = strInhibitionDateTime
    End If
    
Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Let_InhibitionDateTime", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Get_Label
' Input:        none
' Output:       [String] the label
' Description:  Returns the label of the alarm
'-------------------------------------------------------------------------------
Public Property Get Label() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Get_Label", "Begin Property")
        
    Label = m_strLabel

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Get_Label", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Get_State
' Input:        none
' Output:       [String] the inhibition state (string)
' Description:  Returns the inhibition state (string) of the alarm
'-------------------------------------------------------------------------------
Public Property Get State() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Get_State", "Begin Property")
        
    State = m_strInhibitionState

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Get_State", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Let_State
' Input:        strState [String]  the new inhibition state (string)
' Output:       none
' Description:  Set the inhibition state of the alarm
'-------------------------------------------------------------------------------
Public Property Let State(ByVal strState As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Let_State", "Begin Property")
    
    m_strInhibitionState = strState
    
Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Let_State", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Get_StateValue
' Input:        none
' Output:       [Integer] the inhibition state (value)
' Description:  Returns the inhibition state value of the alarm
'-------------------------------------------------------------------------------
Public Property Get StateValue() As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Get_StateValue", "Begin Property")
        
    StateValue = m_iInhibitionStateValue

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Get_StateValue", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::Let_StateValue
' Input:        iStateValue [Integer]  the new inhibition state (value)
' Output:       nono
' Description:  Set the inhibition state value of the alarm
'-------------------------------------------------------------------------------
Public Property Let StateValue(ByVal iStateValue As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "Let_StateValue", "Begin Property")
    
    m_iInhibitionStateValue = iStateValue
    
Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "Let_StateValue", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Alarm::ConvertDateTime
' Input:        none
' Output:       [String] Date/time to be converted
' Description:  Returns the date/time in the "mm/dd/yyyy hh:mm:ss" format
'-------------------------------------------------------------------------------
Private Function ConvertDateTime(ByVal strDateTime As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Alarm", "ConvertDateTime", "Begin Property")
    Dim sMonth, sDay As String
    
    sMonth = Mid(strDateTime, 4, 3)
    sDay = Mid(strDateTime, 1, 3)
    ConvertDateTime = sMonth & sDay & Mid(strDateTime, 7)
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Alarm", "ConvertDateTime", Err.Description)
End Function
