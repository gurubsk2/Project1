VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_TPinfo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_TPInfo
'* *******************************************************************************************
'* Purpose: Manages the informations of a Track Portion
'* *******************************************************************************************
'* Modification History:
'* Author:              Eric FOISSEY
'* Date:                August '12
'* Change:              All - CR ALPHA 304990
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

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


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo::Init
' Input:        [String]   ID of the Track Portion
'               [String]   Name of the Track Portion
'               [String]   ID of the Track Section
'               [String]   Name of the Track Section
' Output:       none
' Description:  Init variables
'-------------------------------------------------------------------------------
Public Sub Init(ByVal strTPID As String, ByVal strTPName As String, ByVal strSDID As String, ByVal strSDName As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo", "Init", "Begin Subroutine")
  
    ' Init attributes
    m_strTPID = strTPID
    m_strTPName = strTPName
    m_strSDID = strSDID
    m_strSDName = strSDName
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo", "Init", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo::Get_TPName
' Input:        none
' Output:       [String] The name of the Track Portion
' Description:  Returns the name of the Track Portion
'-------------------------------------------------------------------------------
Public Property Get TPName() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo", "Get_TPName", "Begin Property")

    TPName = m_strTPName

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo", "Get_TPName", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo::Get_SD_ID
' Input:        none
' Output:       [String] The ID of the Track circuit
' Description:  Returns the ID of the track circuit
'-------------------------------------------------------------------------------
Public Property Get SD_ID() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo", "Get_SD_ID", "Begin Property")

    SD_ID = m_strSDID

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo", "Get_SD_ID", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo::Get_SD_Name
' Input:        none
' Output:       [String] The name of the station
' Description:  Returns the name of the station to which the Platform belong
'-------------------------------------------------------------------------------
Public Property Get SD_Name() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo", "Get_SD_Name", "Begin Property")

    SD_Name = m_strSDName

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo", "Get_SD_Name", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TPInfo::TP_ID
'-------------------------------------------------------------------------------
' Get
' Input:        none
' Output:       [String] The ID of current Track Portion
' Description:  Returns the ID of the platform
'-------------------------------------------------------------------------------
Public Property Get TP_ID() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TPInfo", "Get_TP_ID", "Begin Property")

    TP_ID = m_strTPID

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TPInfo", "Get_TP_ID", Err.Description)
End Property
