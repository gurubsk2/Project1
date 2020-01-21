Attribute VB_Name = "MOD_Train"
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Project: SCMA-Amsterdam
'* *******************************************************************************************
'* Purpose: General functions for Trains
'* *******************************************************************************************
'* Modification History:
'* Author:              Olivier Tayeg
'* Description:         Use TrainManager service to find TrainID from UniqueID
'* Date:                July 2015


'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION()
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION
'* *******************************************************************************************

Option Explicit


'* Function: ReturnTrainIDfromUniqueID
'* Return TrainId from Unique ID
'* ************************************************************************************************
Public Function ReturnTrainIDfromUniqueID(sListIDs As String, iUniqueID As String) As String
On Error GoTo ErrorHandler

    Dim iList() As String
    Dim i As Integer
    Dim m_sListIDsSplitted_1() As String
    
    ReturnTrainIDfromUniqueID = ""
    
    If (sListIDs <> "" And iUniqueID <> "") Then
        m_sListIDsSplitted_1 = Split(sListIDs, ";")
    
       For i = 0 To UBound(m_sListIDsSplitted_1)
            iList = Split(m_sListIDsSplitted_1(i), ":")
            If (iUniqueID = iList(0)) Then
                ReturnTrainIDfromUniqueID = iList(1)
               Exit For
            End If
        Next
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "MOD_Train", "ReturnTrainIDfromUniqueID", "WARNING:m_sListIDs or m_sUniqueID is empty")
    End If
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Train", "ReturnTrainIDfromUniqueID", "EXCEPTION:" & Err.Description)
End Function
