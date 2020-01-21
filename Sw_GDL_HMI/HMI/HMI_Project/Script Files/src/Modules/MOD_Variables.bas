Attribute VB_Name = "MOD_Variables"
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Project: SCMA-Amsterdam
'* *******************************************************************************************
'* Purpose: Module: MOD_Variables
'* *******************************************************************************************
'* Modification History:
'* Author:              Vinay CR
'* Description:         To Manage Functions Related to OPC Variable
'* Date:                Feb 2014

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION()
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (IRS_ATS_Human_interface_SCMA_2_2_D_0396_B)
'* *******************************************************************************************
Option Explicit

'* *************************************************************************************
'*  Author: Vinay CR
'*  Function: To Check the Status of the connected OPC Variable.
'* <parameter1 = Connected Variable to be checked >
'*  This param is the current OPC Variable Whose Quality to be checked
'* This Function Returns True if Quality of Variable is OK Else False.
'**************************************************************************************

Public Function Check_OPC_Variable(OPC_Variablename As Variable) As Boolean
On Error GoTo ErrorHandler

    Check_OPC_Variable = False
    Call CBTrace(CBTRACE_VBA, "MOD_Variables", "Check_OPC_Variable", "Begin Subroutine")
    '* Check the status and the quality of the variable
    If OPC_Variablename.Status = fvVariableStatusWaiting Then
        Call CBTrace(CBTRACE_VAR, "MOD_Variables", "Check_OPC_Variable", "The status of " & OPC_Variablename.Name & " is Waiting")
    ElseIf OPC_Variablename.Status = fvVariableStatusConfigError Then
        Call CBTrace(CBTRACE_VAR, "MOD_Variables", "Check_OPC_Variable", "The status of " & OPC_Variablename.Name & " is Config Error")
    ElseIf OPC_Variablename.Status = fvVariableStatusNotConnected Then
        Call CBTrace(CBTRACE_VAR, "MOD_Variables", "Check_OPC_Variable", "The status of " & OPC_Variablename.Name & " is Not Connected")
    ElseIf OPC_Variablename.Quality <> 192 Then
        Call CBTrace(CBTRACE_VAR, "MOD_Variables", "Check_OPC_Variable", "The quality of " & OPC_Variablename.Name & " is not good")
    Else
        Check_OPC_Variable = True
    End If
    
Exit Function
ErrorHandler:
Call CBTrace(CBTRACEF_ALWAYS, "MOD_Variables", "Check_OPC_Variable", Err.Description)
End Function

'* *************************************************************************************
'*  Author: Vinay CR
'*  Function: To Remove the OPC Variable .
'* <parameter1 = Connected Variable to be Removed>
'*  This param is the current OPC Variable Which has to be removed
'* This Function Doesnot Returns Any value.
'**************************************************************************************

Function Remove_OPC_Variable(OPC_Symbol As Variable)
On Error GoTo ErrorHandler
    If Not OPC_Symbol Is Nothing Then
        Variables.Remove (OPC_Symbol.Name)
        Set OPC_Symbol = Nothing
    End If
Exit Function
ErrorHandler:
Call CBTrace(CBTRACEF_ALWAYS, "MOD_Variables", "Remove_OPC_Variable", Err.Description)
End Function
