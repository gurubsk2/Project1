Attribute VB_Name = "MOD_Deployment"
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Project: SCMA-Amsterdam
'* *******************************************************************************************
'* Purpose: Module: MOD_General
'* *******************************************************************************************
'* Modification History:
'* Author:              Olivier Tayeg
'* Date:                February 2015

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION A
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION
'* *******************************************************************************************

Option Explicit

Public Enum enumAvailableDeployments
        deploymentPL
        deploymentNZL
        deploymentOverview  ' Deployment on wide screens (BARCO display)
End Enum

'-------------------------------------------------------------------------------
' Name:         MOD_Deployment::CurrentDeployment
' Input:        none
' Output:       @returns [enumAvailableDeployments] Deployment currently running
' Description:  Returns which deployment is running on the workstation
'-------------------------------------------------------------------------------
Public Function CurrentDeployment() As enumAvailableDeployments
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Deployment", "CurrentDeployment", "Begin Function")

    Select Case ThisProject.ProjectName
        Case "SCMA_HMI_Overview"
            CurrentDeployment = deploymentOverview
        Case "SCMA_HMI_NZL"
            CurrentDeployment = deploymentNZL
        Case Else
            ' By default, the deployment is PL
            CurrentDeployment = deploymentPL
    End Select

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Deployment", "CurrentDeployment", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         MOD_Deployment::CBTCLevel1Cluster
' Input:        none
' Output:       @returns [string] Cluster for the CBTC zone server
' Description:  Returns the CBTC cluster according to the current deployment
'-------------------------------------------------------------------------------
Public Function CBTCLevel1Cluster() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Deployment", "CBTCLevel1Cluster", "Begin Function")

    If ThisProject.ProjectName = "Guadalajara*" Then
        CBTCLevel1Cluster = "OPCCluster:"
    Else
        CBTCLevel1Cluster = "OPCCluster:"
    End If
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Deployment", "CBTCLevel1Cluster", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         MOD_Deployment::Level2Cluster
' Input:        none
' Output:       @returns [string] Cluster for the Level2 server
' Description:  Returns the Level2 cluster according to the current deployment
'-------------------------------------------------------------------------------
Public Function Level2Cluster() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Deployment", "Level2Cluster", "Begin Function")

    Level2Cluster = "OPCCluster:"
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Deployment", "Level2Cluster", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         MOD_Deployment::ConfigPath
' Input:        none
' Output:       @returns [string] Cluster for the Level2 server
' Description:  Returns the Level2 cluster according to the current deployment
'-------------------------------------------------------------------------------
Public Function ConfigPath() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Deployment", "ConfigPath", "Begin Function")

    If CurrentDeployment = deploymentNZL Then
        ConfigPath = ThisProject.Path & "\Config Files NZL"
    Else
        ConfigPath = ThisProject.Path & "\Config Files PL"
    End If
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Deployment", "ConfigPath", Err.Description)
End Function




'-------------------------------------------------------------------------------
' Name:         MOD_Deployment::GetLineControllerOPCPath
' Input:        none
' Output:       @returns [string] Path to the server's Line Controller object
' Description:  Gives a path to the server's Line Controller object
'-------------------------------------------------------------------------------
Public Function GetLineControllerOPCPath() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Deployment", "GetLineControllerOPCPath", "Begin Function")

        If CurrentDeployment = deploymentNZL Then
                GetLineControllerOPCPath = "OPCCluster_NZL:LCS_10242"
        Else
                GetLineControllerOPCPath = "OPCCluster_CBTC:LCS_10241"
        End If
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Deployment", "GetLineControllerOPCPath", Err.Description)
End Function
