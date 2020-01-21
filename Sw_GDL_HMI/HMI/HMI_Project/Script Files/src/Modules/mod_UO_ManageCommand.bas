Attribute VB_Name = "mod_UO_ManageCommand"
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2015. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Project: UO - Urbalis Operation
'* *******************************************************************************************
'* Purpose: MOD_Manage_Command : manage the command that will be send
'* *******************************************************************************************
'* Modification History:
'*
'* Author:              Wagner Q.
'* Description:         First release
'* Date:                2016/01
'* Change:              All

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION()
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (2S&TDM-ATS-0007 - vA)
'* *******************************************************************************************
'=======================================================================================
Option Explicit

' Constant
' ------------------------------------------------------
Private Const c_strOPCPlatformCmdSetHold As String = "MainUO.HSMModule.HSMMgr.SetHoldPlatforms"             '[ATS_CF_UO_SyAD_1544]
Private Const c_strOPCPlatformCmdReleaseHold As String = "MainUO.HSMModule.HSMMgr.ReleaseHoldPlatforms"     '[ATS_CF_UO_SyAD_1545]
Private Const c_strOPCPlatformCmdGlobalHold As String = "MainUO.HSMModule.HSMMgr.GlobalHold"                '[ATS_CF_UO_SyAD_1546][ATS_CF_UO_SyAD_1547]
Private Const c_strOPCPlatformCmdOperHold As String = ".HoldSkip.HSMPoint.OperatorHold"                     '[ATS_CF_UO_SyAD_1730]
Private Const c_strOPCPlatformCmdSetSkip As String = "MainUO.HSMModule.HSMMgr.SetSkipPlatforms"             '[ATS_CF_UO_SyAD_1732]
Private Const c_strOPCPlatformCmdReleaseSkip As String = "MainUO.HSMModule.HSMMgr.ReleaseSkipPlatforms"     '[ATS_CF_UO_SyAD_1733]
Private Const c_strOPCPlatformCmdOperSkip As String = ".HoldSkip.HSMPoint.OperatorSkip"
Private Const c_strTrainInterposeCmdTag As String = "MainKernelBasic.TrainModule.BasicCmd.bstrInterposeBerth"
Private Const c_strIsServiceOrientedTag As String = "IconisHMI.UO.IsServiceOriented.Information.Value"
Private Const c_strDbLoaderProcessing As String = "MainKernelExtended.TTCModule.DBLoader.ProcessingSuccessfull"

Private Const c_strTrainControlMimic_NSO As String = "mmc_Train_NSO"
Private Const c_strTrainControlMimic_SO As String = "mmc_Train_SO"
Private Const c_strOnlineTTTripGeneral_NSO As String = "mmc_OnlineTTGenTripPlanServOriented"
Private Const c_strOnlineTTTripGeneral_SO As String = "mmc_OnlineTTGenTripPlanServOriented"
Private Const c_strOnlineTTTripDetailed_NSO As String = "mmc_DetailedTripPlanServOri"
Private Const c_strOnlineTTTripDetailed_SO As String = "mmc_DetailedTripPlanServOri"
Private Const c_strOnlineTTStation_SO As String = "mmc_OnlineTTStationServiceOriented"
Private Const c_strOnlineTTStation_NSO As String = "mmc_OnlineTTStationServiceOriented"

'mmc_OnlineTTStationServiceOriented
'mmc_OnlineTTStationNonServiceOriented

'-------------------------------------------------------------------------------
' Name:         MOD_Manage_Command::ButtonCommand
' Input:        button name, branch (variable that will receive the command)
' Output:       none
' Description:  Send command
'-------------------------------------------------------------------------------
Public Function ButtonCommand(ByVal p_sButtonName As String, ByVal p_sBranch As String, Optional ByVal p_CMDValue As String)
On Error GoTo ErrorHandler

Select Case p_sButtonName
'   >>> GLOBAL HOLD >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    Case "btnGlobalHoldSet"
    Variables.Item(c_strClusterLevel2 & c_strOPCPlatformCmdGlobalHold).Value = True
    
    Case "btnGlobalHoldRelease"
    Variables.Item(c_strClusterLevel2 & c_strOPCPlatformCmdGlobalHold).Value = False
  
'   >>> PLATFORM >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    Case "btnPlatformHold"
        If Check_OPC_Variable(Variables.Item(p_sBranch & c_strOPCPlatformCmdOperHold)) = False Then Exit Function
        If Variables.Item(p_sBranch & c_strOPCPlatformCmdOperHold).Value = False Then
            Variables.Add(c_strClusterLevel2 & c_strOPCPlatformCmdSetHold, fvVariableTypeText).Value = Split(p_sBranch, ":")(1) & ";"
        Else
            Variables.Add(c_strClusterLevel2 & c_strOPCPlatformCmdReleaseHold, fvVariableTypeText).Value = Split(p_sBranch, ":")(1) & ";"
        
        End If
        
    Case "btnPlatformSkip"
        If Check_OPC_Variable(Variables.Item(p_sBranch & c_strOPCPlatformCmdOperSkip)) = False Then Exit Function
        If Variables.Item(p_sBranch & c_strOPCPlatformCmdOperSkip).Value = False Then
            Variables.Add(c_strClusterLevel2 & c_strOPCPlatformCmdSetSkip, fvVariableTypeText).Value = Split(p_sBranch, ":")(1) & ";"
        Else
            Variables.Add(c_strClusterLevel2 & c_strOPCPlatformCmdReleaseSkip, fvVariableTypeText).Value = Split(p_sBranch, ":")(1) & ";"
        
        End If
        
        
        
'   >>> OTM >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    Case "btnOTMDetailed"
        Call Variables.Add(c_strClusterLevel2 & c_strDbLoaderProcessing, fvVariableTypeBit)
        If Check_OPC_Variable(Variables.Item(c_strClusterLevel2 & c_strDbLoaderProcessing)) Then
            
            'If Variables.Item(c_strClusterLevel2 & c_strIsServiceOrientedTag).Value Then
              If Variables.Item(c_strClusterLevel2 & c_strDbLoaderProcessing).Value Then
                'Mimics.OpenInCenter c_strOnlineTTTripDetailed_SO, p_sBranch, , , "", , , fvCenterOnParent
                Call OpenMimicInCenter(c_strOnlineTTTripDetailed_SO, p_sBranch, GetmousepointerPossition)
            'Else
            
                'Mimics.OpenInCenter c_strOnlineTTTripDetailed_NSO, p_sBranch, , , "", , , fvCenterOnParent
                'Call OpenMimicInCenter(c_strOnlineTTTripDetailed_NSO, p_sBranch, GetmousepointerPossition)
            ''End If
            End If
            
        End If
        
    Case "btnOTMGeneral"
        Call Variables.Add(c_strClusterLevel2 & c_strDbLoaderProcessing, fvVariableTypeBit)
        If Check_OPC_Variable(Variables.Item(c_strClusterLevel2 & c_strDbLoaderProcessing)) Then
            
            If Variables.Item(c_strClusterLevel2 & c_strDbLoaderProcessing).Value Then
                
                'Mimics.OpenInCenter c_strOnlineTTTripGeneral_SO, p_sBranch, , , "", , , fvCenterOnParent
                Call OpenMimicInCenter(c_strOnlineTTTripGeneral_SO, p_sBranch, GetmousepointerPossition)
            End If
                
        End If

    Case "btnOTMStationTT"
        
        If Check_OPC_Variable(Variables.Item(c_strClusterLevel2 & c_strIsServiceOrientedTag)) Then
            
            If Variables.Item(c_strClusterLevel2 & c_strIsServiceOrientedTag).Value Then
                
                'Mimics.OpenInCenter c_strOnlineTTStation_SO, p_sBranch, , , "", , , fvCenterOnParent
                Call OpenMimicInCenter(c_strOnlineTTStation_SO, p_sBranch, GetmousepointerPossition)
            Else
            
                'Mimics.OpenInCenter c_strOnlineTTStation_NSO, p_sBranch, , , "", , , fvCenterOnParent
                Call OpenMimicInCenter(c_strOnlineTTStation_NSO, p_sBranch, GetmousepointerPossition)
            End If
            
        End If

'   >>> TRAIN >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    Case "btnTrainOpenMimic"
        p_sBranch = Split(p_sBranch, ":")(0) & ":" & Train_GetIDFromBerth(p_sBranch, 1)
        If Check_OPC_Variable(Variables.Item(c_strClusterLevel2 & c_strIsServiceOrientedTag)) Then
            If Variables.Item(c_strClusterLevel2 & c_strIsServiceOrientedTag).Value Then
                
                Mimics.OpenInCenter c_strTrainControlMimic_SO, p_sBranch, , , "", , , fvCenterOnParent
                
            Else
            
                Mimics.OpenInCenter c_strTrainControlMimic_NSO, p_sBranch, , , "", , , fvCenterOnParent
            
            End If
            
        End If
    
    Case "btnTrainHoldSet"
        Variables.Item(c_strClusterLevel2 & c_strTrainInterposeCmdTag).Value = p_CMDValue
        
    Case "btnTrainHoldRelease"
        Variables.Item(c_strClusterLevel2 & c_strTrainInterposeCmdTag).Value = p_CMDValue
        
    Case "btnTrainSkipSet"
        Variables.Item(c_strClusterLevel2 & c_strTrainInterposeCmdTag).Value = p_CMDValue
        
    Case "btnTrainSkipRelease"
        Variables.Item(c_strClusterLevel2 & c_strTrainInterposeCmdTag).Value = p_CMDValue
    Case "btnTrainShuttle"
    
      If Check_OPC_Variable(Variables.Item(c_strClusterLevel2 & c_strTrainInterposeCmdTag)) Then
        Variables.Item(c_strClusterLevel2 & c_strTrainInterposeCmdTag).Value = p_CMDValue
      End If
        
    Case Else
    
End Select

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "mod_UO_manageCommand", "ButtonCommand", "EXCEPTION: " & Err.Description)
End Function

