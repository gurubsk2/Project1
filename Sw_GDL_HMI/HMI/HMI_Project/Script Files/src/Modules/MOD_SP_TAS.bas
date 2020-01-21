Attribute VB_Name = "MOD_SP_TAS"
Option Explicit

'* Declarations
'* ******************************************************

'* Constants
'* ------------------------------------------------------

' Path to the OPC server variables
Public Const c_strTerritoryNameTag As String = ".TAS.Name"
Public Const c_strTakeTag As String = ".TAS.AssignToOperator"
Public Const c_strGrabTag As String = ".TAS.GiveToOperator"
Public Const c_strReleaseTag As String = ".TAS.DeAssignFromOperator"
Public Const c_strIsControlledTag As String = ".TAS.IsControlled"
Public Const c_strExcludeModeTag As String = ".TAS.ExcludeMode"

Public Const c_strLocalControlLocalTag As String = ".IsControlLocal.Value"
Public Const c_strIncomingTransferLocalTag As String = ".TAS.IncomingTransfer%"
Public Const c_strControlledByMeLocalTag As String = ".TAS.bControlledByMe%"

Public Const c_strAssignableToMeLocalTag As String = ".TAS.bAssignableToMe%"

'* OPC server's variables
'* ------------------------------------------------------
' Method plug to Take the territory
Private m_OPC_strTakeTerritory As Variable
' Method plug to Grab the territory
Private m_OPC_strGrabTerritory As Variable
' Method plug to Release the territory
Private m_OPC_strReleaseTerritory As Variable
' Territory controlled
Private m_OPC_bIsControlled As Variable
' Territory in exclude mode
Private m_OPC_bExcludeMode As Variable



Public Function UpdateRequestedPlugs(ByVal sRequestValue As String)
    Dim sTerritoryOPC As String, iTerritory As Integer
    Dim vStationList As Variant, i As Integer, sClusterName As String
    
    On Error GoTo ErrorHandler
    
    sClusterName = GetOPCCluster
    
    If InStr(sRequestValue, ";") = 0 Then
        'Clean request local variables
        For iTerritory = 1 To 6
            sTerritoryOPC = sClusterName & "Territory_" & iTerritory
        
            'Update Station local variables
            vStationList = Split(GetStationList(sTerritoryOPC), ";")
            For i = 0 To UBound(vStationList)
                Variables(sClusterName & "Station_" & vStationList(i) & ".TAS.bControllRequested%").Value = False
            Next i
        Next iTerritory
    Else
        'Update Station local variables
        sTerritoryOPC = Split(sRequestValue, ";")(0)
        vStationList = Split(GetStationList(sTerritoryOPC), ";")
        For i = 0 To UBound(vStationList)
            Variables(sClusterName & "Station_" & vStationList(i) & ".TAS.bControllRequested%").Value = True
        Next i
    
    End If
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_TAS", "IsControlledByMe", Err.Description)

End Function


Public Function IsControlledByMe(ByRef varTerritoryControlledBy As Variable)
    Dim sOPC_TagControlledByMe As String
    Dim vStationList As Variant, i As Integer, sClusterName As String
    
    On Error GoTo ErrorHandler
    
    sOPC_TagControlledByMe = Replace(varTerritoryControlledBy.Name, "ControlledBy", "bControlledByMe%")
    
    'Update Territory local variable
    Variables(sOPC_TagControlledByMe).Value = InStr(1, varTerritoryControlledBy, ThisProject.Security.UserName, vbTextCompare)
    
    'Update Station local variables
    vStationList = Split(GetStationList(varTerritoryControlledBy.Name), ";")
    sClusterName = GetOPCCluster
    For i = 0 To UBound(vStationList)
        Variables(sClusterName & "Station_" & vStationList(i) & c_strControlledByMeLocalTag).Value = Variables(sOPC_TagControlledByMe).Value
    Next i

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_TAS", "IsControlledByMe", Err.Description)

End Function


Public Function NegotiateTransfer(ByVal sBranch As String)
    Dim vStationList As Variant, i As Integer, sClusterName As String
    Dim sTerritoryName As String, sRequestedUserName As String
    
    On Error GoTo ErrorHandler
    
    '''sTerritoryName = GetTerritoryOPC(sBranch)
    sClusterName = GetOPCCluster
    
    If Variables(sBranch & c_strControlledByMeLocalTag).Value Then
        If ModalQuestion("¿Acepta el pedido de transferencia" & Chr(10) & _
            "del control de la estación?", "Control de estación") Then
            'Acept transfer
            If Variables(sClusterName & "AskTerritory.HMIRequest.Value.bstrValue").Value <> "" Then
                sTerritoryName = Split(Variables(sClusterName & "AskTerritory.HMIRequest.Value.bstrValue").Value, ";")(0)
                sRequestedUserName = Split(Variables(sClusterName & "AskTerritory.HMIRequest.Value.bstrValue").Value, ";")(1)
                
                Variables(sTerritoryName & ".TAS.GiveToOperator").Value = sRequestedUserName
            End If
        End If
            'Reset Ask variable
        Variables(sClusterName & "AskTerritory.HMIRequest.Value.bstrValue").Value = ""
    
    End If

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_TAS", "NegotiateTransfer", Err.Description)

End Function

Public Function RequestControl(ByVal sBranch As String)
    Dim vStationList As Variant, i As Integer, sClusterName As String
    Dim sTerritoryName As String
    
    On Error GoTo ErrorHandler
    
    sTerritoryName = GetTerritoryOPC(sBranch)
    sClusterName = GetOPCCluster
    
    If Not VerifyVariable(Variables(sTerritoryName & ".TAS.ControlledBy")) Then Exit Function
    
    If Variables(sTerritoryName & ".TAS.ControlledBy").Value <> "" Then
        'if it's under control, then resquest
        If Not VerifyVariable(Variables(sClusterName & "AskTerritory.HMIRequest.Value.bstrValue")) Then Exit Function
        Variables(sClusterName & "AskTerritory.HMIRequest.Value.bstrValue").Value = sTerritoryName & ";" & ThisProject.Security.UserName
        
    Else
        'if nobody is controlling, then take
        If VerifyVariable(Variables(sTerritoryName & ".TAS.AssignToOperator")) Then _
           Variables(sTerritoryName & ".TAS.AssignToOperator").Value = ThisProject.Security.UserName
    End If

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_TAS", "RequestControl", Err.Description)

End Function


'Return the territory name of the station
Public Function GetTerritoryOPC(ByVal sBranch As String) As String
    Dim sStationName As String, sClusterName As String, sTerritoryName As String
    
    On Error GoTo ErrorHandler
    
    If InStr(sBranch, ":") = 0 Or InStr(sBranch, "_") = 0 Then Exit Function
    
    sClusterName = GetOPCCluster
    sStationName = Split(sBranch, "_")(1)
    
    Select Case sStationName
        Case "TZA", "BEL", "MAR"
            sTerritoryName = "Territory_6"
    
        Case "BAS", "PAT", "CIR"
            sTerritoryName = "Territory_5"
    
        Case "FED", "NOR", "SAN"
            sTerritoryName = "Territory_4"
    
        Case "CTD", "IND", "BAN", "QCI"
            sTerritoryName = "Territory_3"
    
        Case "REV", "NIO", "TLQ"
            sTerritoryName = "Territory_2"
    
        Case "NOD", "TCC"
            sTerritoryName = "Territory_1"
    End Select
    
    GetTerritoryOPC = sClusterName & sTerritoryName
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_TAS", "ReturnTerritoryOPC", Err.Description)
    
End Function

'Return the territory name of the station
Public Function GetStationList(ByVal sBranch As String) As String
    Dim sTerritoryName As String, sStationName As String
    
    On Error GoTo ErrorHandler
    
    If InStr(sBranch, ":") = 0 Then Exit Function
    
    If InStr(sBranch, ".") > 0 Then
        sTerritoryName = Split(sBranch, ".")(0)
        sTerritoryName = Split(sTerritoryName, ":")(1)
    Else
        sTerritoryName = Split(sBranch, ":")(1)
    End If
    
    Select Case sTerritoryName
        Case "Territory_6"
            sStationName = "TZA;BEL;MAR"
    
        Case "Territory_5"
            sStationName = "BAS;PAT;CIR"
    
        Case "Territory_4"
            sStationName = "FED;NOR;SAN"
    
        Case "Territory_3"
            sStationName = "CTD;IND;BAN;QCI"
    
        Case "Territory_2"
            sStationName = "REV;NIO;TLQ"
    
        Case "Territory_1"
            sStationName = "NOD;TCC"
    End Select
    
    GetStationList = sStationName
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_TAS", "GetStationList", Err.Description)
    
End Function

