Attribute VB_Name = "mod_UO_General"
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2015. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Project: Riyad
'* *******************************************************************************************
'* Purpose: MOD_General : initialise every classes used for VBA controled data
'* *******************************************************************************************
'* Modification History:
'*
'* Author:              Eric Foissey
'* Description:         clean up from Riyadh Mock up
'* Date:                September 2015
'* Change:              All

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION()
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (2S&TDM-ATS-0007 - vA)
'* *******************************************************************************************

Option Explicit

' Constant
' ------------------------------------------------------

Private Const c_StrOPCClusterSeparator As String = ":"
'
''* ***************************************************************************************
''*  Function: GetOPCClusterFromBranch
''* ***************************************************************************************
''*  Parameters :
''*      strBranch [String]: Branch to read and parse
''* ***************************************************************************************
''* the function parses the branch to extract the OPC Cluster name used
''* ***************************************************************************************
'Public Function GetOPCClusterFromBranch(StrBranch As String) As String
'On Error GoTo ErrorHandler
'    Call CBTrace(CBTRACE_VBA, "MOD_General", "GetOPCClusterFromBranch", "Begin Function")
'
'        Dim arrBranchInfo() As String
'
'        ' Extract the cluster name from the branch of the mimic
'        arrBranchInfo = Split(StrBranch, c_StrOPCClusterSeparator)
'        If (UBound(arrBranchInfo) > 0) Then
'            GetOPCClusterFromBranch = arrBranchInfo(0) & c_StrOPCClusterSeparator
'        Else
'            GetOPCClusterFromBranch = ""
'        End If
'
'**************************************************************************************
'*  Function: VerifyVariableStatus
'*  Purpose : Verify if we can use the variable
'**************************************************************************************
Public Function VerifyOPCVariableStatus(ByRef p_OPC_Var As Variable) As Boolean
On Error GoTo ErrorHandler
'* Check the status and the quality of the variable
    If (p_OPC_Var.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "mod_UO_General", "p_OPC_Var_ValueChange", "The status of " & p_OPC_Var.Name & " is Waiting")
    ElseIf (p_OPC_Var.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "mod_UO_General", "p_OPC_Var_ValueChange", "The status of " & p_OPC_Var.Name & " is Config Error")
    ElseIf (p_OPC_Var.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "mod_UO_General", "p_OPC_Var_ValueChange", "The status of " & p_OPC_Var.Name & " is Not Connected")
    ElseIf (p_OPC_Var.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "mod_UO_General", "p_OPC_Var_ValueChange", "The Quality of " & p_OPC_Var.Name & " is not good")
    Else '* Status and quality of the variable are good
        VerifyOPCVariableStatus = True
    End If
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "mod_UO_General", "VerifyOPCVariableStatus", "EXCEPTION: " & Err.Description)
End Function

'***********************************************************************************
' Name:         AddVariables
' Input:        none
' Output:       non
' Description:  Create all the variables according with the document SyAD
'***********************************************************************************
Public Sub AddVariables()
On Error GoTo ErrorHandler

    'MainKernel =========================================================================================================================
    Variables.Add c_strClusterLevel2 & "MainKernelBasic.TrainModule.BasicCmd.bstrInterposeBerth", fvVariableTypeText
    Variables.Add c_strClusterLevel2 & "MainKernelBasic.TrainModule.HMITrainManager.bstrListHMITrain", fvVariableTypeText
    Variables.Add c_strClusterLevel1 & "MainKernelBasic.TrainModule.HMITrainManager.bstrListHeadTrain", fvVariableTypeText
    
    'HSM =========================================================================================================================
    Variables.Add c_strClusterLevel2 & "MainUO.HSMModule.HSMMgr.SetHoldPlatforms", fvVariableTypeText       '[ATS_CF_UO_SyAD_1544]
    Variables.Add c_strClusterLevel2 & "MainUO.HSMModule.HSMMgr.ReleaseHoldPlatforms", fvVariableTypeText   '[ATS_CF_UO_SyAD_1545]
    Variables.Add c_strClusterLevel2 & "MainUO.HSMModule.HSMMgr.SetSkipPlatforms", fvVariableTypeText       '[ATS_CF_UO_SyAD_1732]
    Variables.Add c_strClusterLevel2 & "MainUO.HSMModule.HSMMgr.ReleaseSkipPlatforms", fvVariableTypeText   '[ATS_CF_UO_SyAD_1733]
    Variables.Add c_strClusterLevel2 & "MainUO.HSMModule.HSMMgr.GlobalHold", fvVariableTypeBit              '[ATS_CF_UO_SyAD_1546][ATS_CF_UO_SyAD_1547]
    
    'Line Operating Mode =========================================================================================================================
    Variables.Add c_strClusterLevel2 & "MainUO.CarouselsConfiguration.NextOperatingModesList", fvVariableTypeText      '[ATS_CF_UO_SyAD_568]
    Variables.Add c_strClusterLevel2 & "MainUO.CarouselsConfiguration.ModeLabel", fvVariableTypeText                    '[ATS_CF_UO_SyAD_568]
    Variables.Add c_strClusterLevel2 & "MainUO.CarouselsConfiguration.Mode", fvVariableTypeText                         '[ATS_CF_UO_SyAD_576][ATS_CF_UO_SyAD_582][ATS_CF_UO_SyAD_1201]
    Variables.Add c_strClusterLevel2 & "IconisHMI.UO.RegulationStrategyList.Information.Value", fvVariableTypeText                  '[ATS_CF_UO_SyAD_678]
    Variables.Add c_strClusterLevel2 & "IconisHMI.UO.IsServiceOriented.Information.Value", fvVariableTypeRegister       '
    Variables.Add c_strClusterLevel2 & "MainKernelExtended.TPMModule.TPMTPC.TripTimes", fvVariableTypeText                 '[ATS_CF_UO_SyAD_1188]
    Variables.Add c_strClusterLevel2 & "MainKernelExtended.TTCModule.DBLoader.TimetableName", fvVariableTypeText        '[ATS_CF_UO_SyAD_567]
    Variables.Add c_strClusterLevel2 & "MainKernelExtended.ATRModule.ATRTPMA.AtrExtendedMode", fvVariableTypeText       '[ATS_CF_UO_SyAD_582][ATS_CF_UO_SyAD_583][ATS_CF_UO_SyAD_584]
    Variables.Add c_strClusterLevel2 & "MainKernelExtended.ATRModule.ATRTPMA.AtrExtendedStrategy", fvVariableTypeRegister
    Variables.Add c_strClusterLevel2 & "MainUO.TPMModule.TPBMgr.Configuration", fvVariableTypeText          '[ATS_CF_UO_SyAD_582][ATS_CF_UO_SyAD_1200][ATS_CF_UO_SyAD_1201]
    Variables.Add c_strClusterLevel2 & "CATS.ModeMgmt.Mode", fvVariableTypeText                             '[ATS_CF_UO_SyAD_582][ATS_CF_UO_SyAD_1200][ATS_CF_UO_SyAD_1201][ATS_CF_UO_SyAD_1250]
    Variables.Add c_strClusterLevel2 & "MainKernelExtended.ATRModule.ATRTPMA.AtrMode", fvVariableTypeRegister
    Variables.Add c_strClusterLevel2 & "MainUO.TPBModule.TPBMgr.Configuration", fvVariableTypeText
     Variables.Add c_strClusterLevel2 & "MainKernelExtended.TPMModule.TPMTPC.TripTimes", fvVariableTypeRegister                
    Variables.Add c_strClusterLevel2 & "CATS.ModeMgmt.Mode", fvVariableTypeText                             '[ATS_CF_UO_SyAD_582][ATS_CF_UO_SyAD_1200][ATS_CF_UO_SyAD_1201][ATS_CF_UO_SyAD_1250]
      Variables.Add c_strClusterLevel2 & "MainUO.HeadwaySettings.Value", fvVariableTypeText
    'Shuttle =========================================================================================================================
    Variables.Add c_strClusterLevel2 & "IconisHMI.UO.ShuttleOriginDestinationList.Information.Value", fvVariableTypeText    '[ATS_CF_UO_SyAD_2931]
    Variables.Add c_strClusterLevel1 & "CY_C01.HMI.Template.iCommand", fvVariableTypeRegister    '[ATS_CF_UO_SyAD_2931]
    Variables.Add c_strClusterLevel1 & "CY_C02.HMI.Template.iCommand", fvVariableTypeRegister    '[ATS_CF_UO_SyAD_2931]
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "mod_UO_General", "AddVariables", "EXCEPTION: " & Err.Description)
End Sub

'***********************************************************************************
' Name:         Init
' Input:        none
' Output:       non
' Description:  Initialize the project with the good mimic
'***********************************************************************************
Public Sub Init()
On Error GoTo ErrorHandler

    Mimics.Open "mmc_UOFunctions", c_strClusterLevel2 & "UOFunctions"
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "mod_UO_General", "Init", "EXCEPTION: " & Err.Description)
End Sub

'''******************************************************************************************
''' Name:         GetSymbolBranch
''' Input:        theSymbol [Symbol]
''' Output:       [String]   Branch
''' Description:  Compute the relative branch of a symbol
'''               even if it is nested within other symbols/groups/mimics
'''******************************************************************************************
''Public Function GetSymbolBranch(theSymbol As Symbol) As String
''On Error GoTo ErrorHandler
''    Call CBTrace(CBTRACE_VBA, "MOD_General", "GetSymbolBranch", "Begin Subroutine")
''
''    Dim MyParent As Object
''
''    GetSymbolBranch = theSymbol.LocalBranch
''
''    If InStr(1, theSymbol.LocalBranch, "@") > 0 Then Exit Function
''
''    Set MyParent = theSymbol.Parent
''
''    While ((TypeOf MyParent Is Symbol) Or (TypeOf MyParent Is Group))
''        If (TypeOf MyParent Is Symbol) Then
''            GetSymbolBranch = AppendBranches(MyParent.LocalBranch, GetSymbolBranch)
''        End If
''        Set MyParent = MyParent.Parent
''    Wend
''    GetSymbolBranch = AppendBranches(theSymbol.BranchContext, GetSymbolBranch)
''
''Exit Function
''ErrorHandler:
''    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetSymbolBranch", Err.Description)
''End Function

'**************************************************************************************
'* Name:         MOD_General::AppendBranches
'* Input:        strBranch1 [String] mother branch
'*               strBranch2 [String] child branch
'* Output:       [String]   Resulting branch
'* Description:  Combines two OPC branches to return a new branch
'**************************************************************************************
Private Function AppendBranches(strBranch1 As String, strBranch2 As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_General", "AppendBranches", "Begin Subroutine")

    If (strBranch1 = "*") Then
        AppendBranches = strBranch2
    Else
        If (strBranch2 = "*") Then
            AppendBranches = strBranch1
        Else
            Select Case Right(strBranch1, 1)
                Case "", ":", "."
                    AppendBranches = strBranch1 & strBranch2
                Case Else
                    Select Case Left(strBranch2, 1)
                        Case "", ":", "."
                            AppendBranches = strBranch1 & strBranch2
                        Case Else
                            AppendBranches = strBranch1 & "." & strBranch2
                    End Select
            End Select
        End If
    End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "mod_UO_General", "AppendBranches", "EXCEPTION: " & Err.Description)
End Function

'***********************************************************************************
' Name:         CreateNew_Iconis_CLS_List
' Input:        none
' Output:       [Iconis_CLS_List]       The new instance
' Description:  Create and return a new instance of an Iconis_CLS_List
'***********************************************************************************
Public Function CreateNew_Iconis_CLS_List() As Iconis_CLS_List
On Error GoTo ErrorHandler

    Set CreateNew_Iconis_CLS_List = New Iconis_CLS_List
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "mod_UO_General", "CreateNew_Iconis_CLS_List", "EXCEPTION: " & Err.Description)
End Function

'***********************************************************************************
' Name:         CreateNew_Iconis_CLS_OPCSet
' Input:        none
' Output:       [Iconis_CLS_OPCSet]   The new instance
' Description:  Create and return a new instance of an Iconis_CLS_OPCSet
'***********************************************************************************
Public Function CreateNew_Iconis_CLS_OPCSet() As Iconis_CLS_OPCSet
On Error GoTo ErrorHandler

    Set CreateNew_Iconis_CLS_OPCSet = New Iconis_CLS_OPCSet
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "mod_UO_General", "CreateNew_Iconis_CLS_OPCSet", "EXCEPTION: " & Err.Description)
End Function



'* *************************************************************************************
'*  Function: Remove_OPC_Variable
'*  Purpose : To Remove the OPC Variable.
'*  <parameter1 = Connected Variable to be Removed>
'*  This param is the current OPC Variable Which has to be removed
'*  This function does not return any value.
'* *************************************************************************************
Function RemoveOPCVariable(ByVal OPC_Symbol As Variable)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_General", "Remove_OPC_Variable", "Begin Subroutine")
    
    If Not OPC_Symbol Is Nothing Then
        'Variables.Remove (OPC_Symbol.Name)
        Set OPC_Symbol = Nothing
    End If
    
Exit Function
ErrorHandler:
Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "Remove_OPC_Variable", Err.Description)
End Function

Public Function Train_GetIDFromBerth(ByVal p_sBranch As String, ByVal iTrainID As Integer) As String
On Error GoTo ErrorHandler
Dim i                   As Integer 'index
Dim iTrainListID        As Integer
Dim strTrainListName    As String
Dim varTrainList
    
On Error GoTo ErrorHandler

    varTrainList = Split(Variables(c_strClusterLevel2 & "MainKernelBasic.TrainModule.HMITrainManager.bstrListHMITrain").Value, ";")
       
        If Variables(p_sBranch & ".TrainIndicator.TIBerth.iTrainID" & iTrainID).Value > 0 Then
        
            For I = 0 To UBound(varTrainList)
            
                iTrainListID = Split(varTrainList(I), ":")(0)
                strTrainListName = Split(varTrainList(I), ":")(1)
                
                If iTrainListID = Variables(p_sBranch & ".TrainIndicator.TIBerth.iTrainID" & iTrainID).Value Then
                    Train_GetIDFromBerth = strTrainListName
                    Exit Function
                    
                End If
                
            Next I
            
        End If
        
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "mod_UO_General", "Train_GetIDFromBerth", "EXCEPTION: " & Err.Description)
    
End Function
