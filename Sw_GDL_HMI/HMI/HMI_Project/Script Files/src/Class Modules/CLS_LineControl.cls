VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CLS_LineControl"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       CLS_LineControl
'* *******************************************************************************************
'* Purpose: Manages Line Control is in CATS or LATS
'* *******************************************************************************************
'* Modification History:
'* Author:              Chaitra Purohit
'* Date:                October '16
'* Change:              All
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------

' Path to the OPC server variables
Private Const c_strLineCtrlNegociated As String = ".MMGATSArea.NegociatedMode"
Private Const c_strLineCtrlForced As String = ".MMGATSArea.ForcedMode"
Private Const c_strLineCtrlConfirmation As String = ".MMGATSArea.Confirmation"
Private Const c_strLineCtrlSecurity As String = ".MMGATSArea.Security"
Private Const c_Line_Control_Request As String = "LineControl_Handover_Request"
Private Const c_LineControlMode As String = ".MMGATSArea.Mode"
Dim sMachine_Name As String
Dim WithEvents m_OPC_LineCtrlNegociatedCATS As Variable
Attribute m_OPC_LineCtrlNegociatedCATS.VB_VarHelpID = -1
Dim WithEvents m_OPC_LineCtrlNegociatedLATS As Variable
Attribute m_OPC_LineCtrlNegociatedLATS.VB_VarHelpID = -1
Dim WithEvents m_OPC_LineControlMode As Variable
Attribute m_OPC_LineControlMode.VB_VarHelpID = -1
Dim strCATSATSArea As String
Dim strLATSATSArea As String
Dim strLineCtrlWithAck As String

Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "CLS_LineControl", "Class_Initialize", "Begin Subroutine")

'sMachine_Name = ThisSystem.ComputerName
sMachine_Name = "*CATS"
strCATSATSArea = Iconis_MOD_General.GetOPCCluster & "CATS"
strLATSATSArea = Iconis_MOD_General.GetOPCCluster & "LATS"
Set m_OPC_LineCtrlNegociatedCATS = Variables.Add(strCATSATSArea & c_strLineCtrlNegociated, fvVariableTypeRegister)
Set m_OPC_LineCtrlNegociatedLATS = Variables.Add(strLATSATSArea & c_strLineCtrlNegociated, fvVariableTypeRegister)
Set m_OPC_LineControlMode = Variables.Add(strCATSATSArea & c_LineControlMode, fvVariableTypeRegister)

If (sMachine_Name Like "*CATS*") Then
      If m_OPC_LineCtrlNegociatedCATS.EnableEvents = True Then
            m_OPC_LineCtrlNegociatedCATS_ValueChange
     Else
            m_OPC_LineCtrlNegociatedCATS.EnableEvents = True
     End If
ElseIf (sMachine_Name Like "*LATS*") Then
    If m_OPC_LineCtrlNegociatedLATS.EnableEvents = True Then
            m_OPC_LineCtrlNegociatedLATS_ValueChange
     Else
            m_OPC_LineCtrlNegociatedLATS.EnableEvents = True
     End If
End If
If m_OPC_LineControlMode.EnableEvents = True Then
            m_OPC_LineControlMode_ValueChange
     Else
            m_OPC_LineControlMode.EnableEvents = True
     End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Class_Initialize", Err.Description)
End Sub

Private Sub m_OPC_LineControlMode_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "CLS_LineControl", "m_OPC_LineCtrlNegociatedCATS_ValueChange", "Begin Subroutine")

    If (Check_Variable(m_OPC_LineControlMode)) Then
        If ((m_OPC_LineControlMode.Value = 1) And sMachine_Name Like "*CATS") Then
            Variables.Item("@LineControlledByMe%").Value = True
            ElseIf ((m_OPC_LineControlMode.Value = 2) And sMachine_Name Like "*LATS") Then
            Variables.Item("@LineControlledByMe%").Value = True
            Else
            Variables.Item("@LineControlledByMe%").Value = False
            
          End If
     End If
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "CLS_LineControl", "m_OPC_LineCtrlNegociatedCATS_ValueChange", Err.Description)
End Sub

Private Sub m_OPC_LineCtrlNegociatedCATS_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "CLS_LineControl", "m_OPC_LineCtrlNegociatedCATS_ValueChange", "Begin Subroutine")
  
    If (Check_Variable(m_OPC_LineCtrlNegociatedCATS)) Then
           
        If (sMachine_Name Like "*CATS*" And m_OPC_LineCtrlNegociatedCATS.Value <> 0 And m_OPC_LineControlMode.Value = 1) Then
            Variables.Item("LineControlRequested%") = True
            Mimics.OpenInCenter c_Line_Control_Request, strCATSATSArea, , , "", , fvCenterOnRegion
        End If
  End If
      
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "CLS_LineControl", "m_OPC_LineCtrlNegociatedCATS_ValueChange", Err.Description)
End Sub
Private Sub m_OPC_LineCtrlNegociatedLATS_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "CLS_LineControl", "m_OPC_LineCtrlNegociatedLATS_ValueChange", "Begin Subroutine")
    
    If (Check_Variable(m_OPC_LineCtrlNegociatedLATS) And m_OPC_Security < 63) Then
           
        If (sMachine_Name Like "*LATS*" And m_OPC_LineCtrlNegociatedLATS.Value <> 0 And m_OPC_LineControlMode.Value = 0) Then
            Variables.Item("LineControlRequested%") = True
            Mimics.OpenInCenter c_Line_Control_Request, strLATSATSArea, ThisMimic.ReferenceSet, ThisMimic.Region, "", , fvCenterOnRegion
        End If
  End If
      
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "CLS_LineControl", "m_OPC_LineCtrlNegociatedCATS_ValueChange", Err.Description)
End Sub
