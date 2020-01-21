VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "GDL3_CLS_CST"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       CLS_CST
'* *******************************************************************************************
'* Purpose: Manages the opening of the Confirmation Dialog
'* *******************************************************************************************
'* Modification History:
'* Author:              Chaitra Purohit
'* Date:                April '17
'* Change:              All
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION()
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION ()
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
Private Const c_strUserDialogWaitingConf As String = "MainGDLL3.CSTModule.UserDialogCmdSeq.WaitingConfirmation"
Private Const c_strUserDialogConfirmation As String = "MainGDLL3.CSTModule.UserDialogCmdSeq.Confirmation"
Dim WithEvents m_OPC_UserDialogWaitingConf As Variable
Attribute m_OPC_UserDialogWaitingConf.VB_VarHelpID = -1
Dim m_OPC_Confirmation As Variable


Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "CLS_LineControl", "Class_Initialize", "Begin Subroutine")
    Set m_OPC_UserDialogWaitingConf = Variables.Add(c_strClusterLevel2 & c_strUserDialogWaitingConf)
    Set m_OPC_Confirmation = Variables.Add(c_strClusterLevel2 & c_strUserDialogConfirmation)
    If m_OPC_UserDialogWaitingConf.EnableEvents = True Then
            m_OPC_UserDialogWaitingConf_ValueChange
     Else
            m_OPC_UserDialogWaitingConf.EnableEvents = True
     End If
    
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Class_Initialize", Err.Description)
End Sub

Private Sub m_OPC_UserDialogWaitingConf_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "CLS_LineControl", "Class_Initialize", "Begin Subroutine")
    
    If Check_Variable(m_OPC_Confirmation) Then
    
        Call OpenMimicInCenter("GDL_CST_Confirmation_Dialog", c_strClusterLevel2, GetmousepointerPossition)
    
   End If
    
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Class_Initialize", Err.Description)
End Sub
