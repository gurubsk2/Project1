Attribute VB_Name = "MOD_SP_General"
Option Explicit
Public xpos As Long ' FOr Displaying Mimic @ Center of Activ Mimic

Public bFormMsgQuestion As Boolean



Public Function UpdateSharedLibrary() As Boolean
    Dim PathUrbalis As String
    Dim File
    Dim bReturn As Boolean

    If Dir(PathUrbalis, vbDirectory) <> "" Then

'        Update traslated mimic files
        If Dir(ThisProject.Path & "\JAR Files\SharedLibraryTranslated\Mimic Files", vbDirectory) <> "" Then
            PathUrbalis = Replace(ThisLibrary.Path, "Script Files", "Mimic Files")
            bReturn = Shell("xcopy " _
                & Chr(34) & ThisProject.Path & "\JAR Files\SharedLibraryTranslated\Mimic Files\*.*" _
                & Chr(34) & " " _
                & Chr(34) & PathUrbalis _
                & Chr(34) & " /s /y")
        End If
        
'        Update traslated symbol files
        If Dir(ThisProject.Path & "\JAR Files\SharedLibraryTranslated\Symbol Files", vbDirectory) <> "" Then
            PathUrbalis = Replace(ThisLibrary.Path, "Script Files", "Symbol Files")
            bReturn = Shell("xcopy " _
                & Chr(34) & ThisProject.Path & "\JAR Files\SharedLibraryTranslated\Symbol Files\*.*" _
                & Chr(34) & " " _
                & Chr(34) & PathUrbalis _
                & Chr(34) & " /s /y")
        End If

'        Update traslated template files
        If Dir(ThisProject.Path & "\JAR Files\SharedLibraryTranslated\Template Files", vbDirectory) <> "" Then
            PathUrbalis = Replace(ThisLibrary.Path, "Script Files", "Template Files")
            bReturn = Shell("xcopy " _
                & Chr(34) & ThisProject.Path & "\JAR Files\SharedLibraryTranslated\Template Files\*.*" _
                & Chr(34) & " " _
                & Chr(34) & PathUrbalis _
                & Chr(34) & " /s /y")
        End If

        UpdateSharedLibrary = True
    Else
         MsgBox "The IconisATSUrbalis shared library is not installed!" & vbKeyReturn & _
            "Please, install the URBALIS product first.", vbCritical + vbOKOnly, "fvProject_StartupComplete"
    End If
End Function



Public Function OpenMenu(sMenuName As String, objSymbol As Symbol)
    Dim ActiveCoord As POINTAPI
    Dim iCount As Integer, iLeft As Integer, iTop As Integer, iMonitor As Integer
    Dim sBranch As String, sTrainOPCName As String
    
    On Error GoTo ErrorHandler

    'get the current cursor location
    Call GetCursorPos(ActiveCoord)

'    If LeftWorkspace > 0 Then iMonitor = 1
    iMonitor = Int(ActiveCoord.lXpos / System.HorizontalResolution) - iMonitor

    iLeft = objSymbol.Left + (iMonitor * System.HorizontalResolution) + (ActiveMimic.Windows(1).Left)
    If iLeft < (iMonitor * System.HorizontalResolution) Then iLeft = (iMonitor * System.HorizontalResolution) + 5
    iTop = objSymbol.Top + objSymbol.Height + ActiveMimic.Windows(1).Top

    'close all contextual menus
    For iCount = 1 To ThisProject.Mimics.Count
        If InStr(ThisProject.Mimics.Item(iCount).FileName, "Menu") > 0 Then
            ThisProject.Mimics.Item(iCount).Close fvDoNotSaveChanges
        End If
    Next iCount

    If sMenuName Like "Train_*" Then
        sBranch = objSymbol.Parent.Parent.Parent.LocalBranch
    ElseIf objSymbol.LocalBranch <> "" Then
        sBranch = objSymbol.LocalBranch
    ElseIf objSymbol.Parent.LocalBranch <> "" Then
        sBranch = objSymbol.Parent.LocalBranch
    ElseIf objSymbol.Parent.Parent.LocalBranch <> "" Then
        sBranch = objSymbol.Parent.Parent.LocalBranch
    End If
    
'''    If InStr(1, sBranch, "TCB_", vbTextCompare) > 0 And InStr(1, sBranch, "HMITrain1", vbTextCompare) = 0 Then sBranch = sBranch & ".HMITrain1"

'    'Se for o berth, abrir a tela com o tag do Trem
'    If InStr(1, sBranch, "TCB_", vbTextCompare) > 0 Then
'        sTrainOPCName = GetHMITrainOPCName(Variables(sBranch & ".HMITrain1.TDS.iTrainID").Value, Variables(sBranch & ".HMITrain1.TDS.bstrHMITrainID").Value)
'        If sTrainOPCName = "" Then Exit Function
'        sBranch = "OPCCluster:" & sTrainOPCName
'        AddTrainVariables sBranch
'    End If


'    Mimics.Open sMenuName, objSymbol.LocalBranch, , , , , , , ActiveCoord.lXpos, ActiveCoord.lYpos, True
    Mimics.Open sMenuName, sBranch, , , , , , , iLeft, iTop, True
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "OpenMenu", Err.Description)
    
  End Function

Public Function OpenForms(sFormName As String, Optional bNotCentralize As Boolean)
    Dim sCaption As String
    Dim ActiveCoord As POINTAPI
    Dim iLeft As Integer, iTop As Integer
    Dim iMonitor As Integer

    On Error GoTo ErrorHandler

    'get the current cursor location
    Call GetCursorPos(ActiveCoord)
    
    iMonitor = Int(ActiveCoord.lXpos / c_lScreenWidth)
    

      
    If bNotCentralize Then
        iTop = ActiveCoord.lYpos * 0.753
        iLeft = ActiveCoord.lXpos * 0.753
    Else
        iLeft = (c_lScreenWidth * iMonitor * 0.753) + (c_lScreenWidth * 0.753) / 2
        iTop = System.VerticalResolution / 2 * 0.753
    End If

    If InStr(sFormName, ":") > 0 Then
'        iFormMsgQuestion = Split(sFormName, ":")(1)
        sFormName = Split(sFormName, ":")(0)
    End If
    
    Select Case sFormName
        
        Case "frmMsgQuestion"
'            With frmMsgQuestion
''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''                .Top = Int(iTop * 0.753 - (.Height / 2))
'                .Top = Int(iTop - (.Height / 2))
'                .Left = Int(iLeft - (.Width / 2))
'                .Show
'            End With
'
'
'        Case "frmMsgExclamation"
'            With frmMsgExclamation
''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''                .Top = Int(iTop * 0.753 - (.Height / 2))
'                .Top = Int(iTop - (.Height / 2))
'                .Left = Int(iLeft - (.Width / 2))
'                .Show
'            End With
'
'        Case "frmLogin"
'            With frmLogin
''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''                .Top = Int(iTop * 0.753 - (.Height / 2))
'                .Top = Int(iTop - (.Height / 2))
'                .Left = Int(iLeft - (.Width / 2))
'                .Show
'            End With
'
''        Case "frmMenuHelp"
''            With frmMenuHelp
''            If iPopupPosition > 0 Then
''                .Left = 2375
''            Else
''                .Left = 1120
''            End If
''                .Top = 103
''                .Show
''            End With
'
'        Case "frmChangePassword"
'            With frmChangePassword
''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''                .Top = Int(iTop * 0.753 - (.Height / 2))
'                .Top = Int(iTop - (.Height / 2))
'                .Left = Int(iLeft - (.Width / 2))
'                .Show
'            End With
'
'
'        Case "frmCadUser"
'            With frmCadUser
''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''                .Top = Int(iTop * 0.753 - (.Height / 2))
'                .Top = Int(iTop - (.Height / 2))
'                .Left = Int(iLeft - (.Width / 2))
'                .Show
'            End With
'
'        Case "frm_Executelift"
'
'            With frm_Execute
'                frm_Execute.Caption = "Lift"
'                If iPopupPositionl > (iLeft + System.HorizontalResolution) * 0.753 - .Width Then iPopupPositionl = (iLeft + System.HorizontalResolution) * 0.753 - .Width
'                .Left = iPopupPositionl - 10
'                If iPopupPositiont > System.VerticalResolution * 0.753 - .Height Then iPopupPositiont = System.VerticalResolution * 0.753 - .Height
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'        Case "frm_Execute"
'
'            With frm_Execute
'                If iPopupPositionl > (iLeft + System.HorizontalResolution) * 0.753 - .Width Then iPopupPositionl = (iLeft + System.HorizontalResolution) * 0.753 - .Width
'                .Left = iPopupPositionl - 10
'                If iPopupPositiont > System.VerticalResolution * 0.753 - .Height Then iPopupPositiont = System.VerticalResolution * 0.753 - .Height
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'
'        Case "frm_cmd_ene_circuitbreaker"
'            With frm_cmd_ene_circuitbreaker
'                .Caption = "Circuit Breaker - " & powerCBname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'        Case "frm_cmd_esp_circuitbreaker"
'            With frm_cmd_esp_circuitbreaker
'                .Caption = "Circuit Breaker - " & powerCBname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'
'            End With
'
'         Case "frm_cmd_ene_disj"
'            With frm_cmd_ene_disj
'                .Caption = "DC Line Bypass - " & powerDJname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'
'         Case "frm_cmd_ene_line_feeder"
'            With frm_cmd_ene_line_feeder
'                .Caption = "DC Feeder - " & powerDCname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'
'         Case "frm_cmd_ene_esp_line_feeder"
'            With frm_cmd_ene_esp_line_feeder
'                .Caption = "DC Feeder - " & powerDCname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'
'         Case "frm_cmd_ene_reticf"
'            With frm_cmd_ene_reticf
'                .Caption = "Isolator - " & powerISname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'          Case "frm_cmd_fac_light"
'            With frm_cmd_fac_light
'
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'
'        Case "frm_cmdbc_ene_circuitbreaker"
'            With frm_cmdbc_ene_circuitbreaker
'                .Caption = "Circuit Breaker - " & powerCBname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'        Case "frm_cmdbc_esp_circuitbreaker"
'            With frm_cmdbc_esp_circuitbreaker
'                .Caption = "Circuit Breaker - " & powerCBname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'
'            End With
'
'         Case "frm_cmdbc_ene_disj"
'            With frm_cmdbc_ene_disj
'                .Caption = "DC Line Bypass - " & powerDJname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'
'         Case "frm_cmdbc_ene_line_feeder"
'            With frm_cmdbc_ene_line_feeder
'                .Caption = "DC Feeder - " & powerDCname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'
'         Case "frm_cmdbc_ene_esp_line_feeder"
'            With frm_cmdbc_ene_esp_line_feeder
'                .Caption = "DC Feeder - " & powerDCname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'
'         Case "frm_cmdbc_ene_reticf"
'            With frm_cmdbc_ene_reticf
'                .Caption = "Isolator - " & powerISname
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'          Case "frm_cmd_lift"
'            With frm_cmd_lift
'
'                .Left = iPopupPositionl - 10
'                .Top = iPopupPositiont - 10
'                .Show
'
'            End With
'
'
'        Case "frm_cmd_reset"
'
'
'            With frm_cmd_reset
'
'                .Left = iPopupPositionl - 10
'
'                    If iPopupPositiont < 680 Then
'
'                        .Top = iPopupPositiont - 10
'
'                    Else
'
'                        .Top = 680
'                    End If
'                .Show
'
'            End With
'
'
'        Case "frmMsgImediata"
''            With frmMsgImediata
''                .Left = Int(iLeft - (.Width / 2)) * 0.753
''                .Top = Int(iTop - (.Height / 2)) * 0.753
''                .Show
''            End With
'
'        Case "frmprinters"
'            With frmPrinters
''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''                .Top = Int(iTop * 0.753 - (.Height / 2))
'                .Top = Int(iTop - (.Height / 2))
'                .Left = Int(iLeft - (.Width / 2))
'                .Show
'            End With
'
'        Case "frmTAS"
'            'Para abrir próximo ao botão de comando
''            With frmTAS
''                If iLeft > (System.HorizontalResolution * iMonitor) * 0.753 - .Width Then iLeft = (System.HorizontalResolution * iMonitor) * 0.753 - .Width - 10
''                If iTop > System.VerticalResolution * 0.753 - .Height Then iTop = System.VerticalResolution * 0.753 - .Height - 10
''                .Left = iLeft
''                .Top = iTop
''                .Show
''            End With
'
'            'Para abrir centralizado na tela
'            With frmTAS
''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''                .Top = Int(iTop * 0.753 - (.Height / 2))
'                .Top = Int(iTop - (.Height / 2))
'                .Left = Int(iLeft - (.Width / 2))
'                .Show
'            End With
'
'        Case "frmInibeCMDs"
'            'Para abrir centralizado na tela
'            With frmInibeCMDs
''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''                .Top = Int(iTop * 0.753 - (.Height / 2))
'                .Top = Int(iTop - (.Height / 2))
'                .Left = Int(iLeft - (.Width / 2))
'                .Show
'            End With
'
'        Case "frmAPGeral"
'            'Para abrir centralizado na tela
'            With frmAPGeral
'                .Top = Int(iTop - (.Height / 2))
'                .Left = Int(iLeft - (.Width / 2))
'                .Show
'            End With

        Case "frmAbout"
            'Para abrir centralizado na tela
            With frmAbout
'                .Left = Int(iLeft * 0.753 - (.Width / 2))
'                .Top = Int(iTop * 0.753 - (.Height / 2))
                .Top = Int(iTop - (.Height / 2))
                .Left = Int(iLeft - (.Width / 2))
                .Show
            End With


    End Select
    

'    iPopupPosition = 0

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ModMain", "OpenForms", Err.Description)
    
  End Function


Public Function OpenInspPanel(Optional ByRef mmcMenu As Mimic, Optional ByRef sybSymbol As Symbol)
    Dim ActiveCoord As POINTAPI
    Dim iCount As Integer
    Dim sMimicInspPanel As String
    Dim sBranch As String, iLeft As Integer, iTop As Integer
    Dim iMonitor As Integer, sPML As String
    Dim sTrainOPCName As String

    On Error GoTo ErrorHandler

    If sMenuName Like "Train_*" Then
        sBranch = objSymbol.Parent.Parent.Parent.LocalBranch
    ElseIf sMenuName Like "Train_*" Then
        sBranch = objSymbol.Parent.Parent.Parent.LocalBranch
    ElseIf objSymbol.LocalBranch <> "" Then
        sBranch = objSymbol.LocalBranch
    ElseIf objSymbol.Parent.LocalBranch <> "" Then
        sBranch = objSymbol.Parent.LocalBranch
    ElseIf objSymbol.Parent.Parent.LocalBranch <> "" Then
        sBranch = objSymbol.Parent.Parent.LocalBranch
    End If

'    If InStr(sybSymbol.LocalBranch, "Train") > 0 Then
'        sMimicInspPanel = "TCB_InspectorPanel"
'    ElseIf InStr(sybSymbol.LocalBranch, "Stop_STA") > 0 Then
'        sMimicInspPanel = "PLAT_InspectorPanel"
'    ElseIf InStr(sybSymbol.LocalBranch, "DVO_") > 0 Then
'        sMimicInspPanel = "DV_InspectorPanel"
'    ElseIf InStr(sybSymbol.LocalBranch, "_SCT") > 0 Then
'        sMimicInspPanel = "SCT_InspectorPanel"
''            Rafaela 18-3-2016
'    ElseIf InStr(sybSymbol.LocalBranch, "SVO_") > 0 Then
'        sMimicInspPanel = "SV_InspectorPanel"
'    Else
'        sMimicInspPanel = Split(sybSymbol.LocalBranch, "_")(0) & "_InspectorPanel" & sPML
'    End If
'    sMimicInspPanel = Replace(sMimicInspPanel, "OPCCluster:", "", , , vbTextCompare)
'    sMimicInspPanel = Replace(sMimicInspPanel, "@", "")
'    sBranch = sybSymbol.LocalBranch
            
    'get the current cursor location
    Call GetCursorPos(ActiveCoord)
            
'        If LeftWorkspace > 0 Then iMonitor = 1
            
    iMonitor = Int(ActiveCoord.lXpos / System.HorizontalResolution) - iMonitor

'        iLeft = sybSymbol.Left + (iMonitor * System.HorizontalResolution) - (Abs(ActiveMimic.Windows(1).Left))
    iLeft = sybSymbol.Left + (iMonitor * System.HorizontalResolution) + (ActiveMimic.Windows(1).Left)
    If iLeft < (iMonitor * System.HorizontalResolution) Then iLeft = (iMonitor * System.HorizontalResolution) + 5
'       iLeft = ActiveCoord.lXpos
    iTop = sybSymbol.Top + sybSymbol.Height + ActiveMimic.Windows(1).Top
    
    If sMimicInspPanel = "" Then Exit Function

    'close all inspector panel of the same equipment type
    For iCount = 1 To ThisProject.Mimics.Count
        If (InStr(ThisProject.Mimics.Item(iCount).FileName, sMimicInspPanel) > 0 And ThisProject.Mimics.Item(iCount).FileName <> sBranch) _
          Or (InStr(ThisProject.Mimics.Item(iCount).FileName, "_ContextualMenu") > 0) Then
            ThisProject.Mimics.Item(iCount).Close fvDoNotSaveChanges
        End If
    Next iCount

'''    If InStr(1, sBranch, "TCB_", vbTextCompare) > 0 And InStr(1, sBranch, "HMITrain1", vbTextCompare) = 0 Then sBranch = sBranch & ".HMITrain1"
''    'Se for o berth, abrir a tela com o tag do Trem
''    If InStr(1, sBranch, "TCB_", vbTextCompare) > 0 Then
''        sTrainOPCName = GetHMITrainOPCName(Variables(sBranch & ".HMITrain1.TDS.iTrainID").Value, Variables(sBranch & ".HMITrain1.TDS.bstrHMITrainID").Value)
''        If sTrainOPCName = "" Then Exit Function
''        sBranch = "OPCCluster:" & sTrainOPCName
''    End If

    Mimics.Open sMimicInspPanel, sBranch, , , , , , , iLeft, iTop, True
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "OpenInspPanel", Err.Description)
    
  End Function


Public Function ModalExclamation(strQuestion As String, strTitle As String)
    Dim ActiveCoord As POINTAPI
    Dim iLeft As Integer, iTop As Integer, iMonitor As Integer
       
    On Error GoTo ErrorHandler
       
    'get the current cursor location
    GetCursorPos ActiveCoord
    
    iMonitor = Int(ActiveCoord.lXpos / System.HorizontalResolution)
    
    With frmModalExclamation
        .Caption = strTitle
        .lblQuestion = strQuestion
        .Width = (.lblQuestion.Left * 2) + .lblQuestion.Width
        .cmdOk.Left = (.Width / 2) - (.cmdOk.Width / 2)
        .cmdOk.Top = .lblQuestion.Top + .lblQuestion.Height + 15
        .Height = .cmdOk.Top + 60
        .Left = ((System.HorizontalResolution * iMonitor * 0.753) + ((System.HorizontalResolution * 0.753) / 2 - .Width / 2))
        .Top = ((System.VerticalResolution) * 0.753 / 2 - .Height / 2)
        .Show
    End With
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ModMain", "ModalExclamation", Err.Description)
    
End Function


Public Function ModalQuestion(strQuestion As String, strTitle As String) As VbMsgBoxResult
    Dim ActiveCoord As POINTAPI
    Dim iLeft As Integer, iTop As Integer, iMonitor As Integer
       
    On Error GoTo ErrorHandler
       
    'get the current cursor location
    GetCursorPos ActiveCoord
 
    iMonitor = Int(ActiveCoord.lXpos / c_lScreenWidth)
    
    bFormMsgQuestion = False
    With frmModalQuestions
        .Caption = strTitle
        .lblQuestion = strQuestion
        .Width = (.lblQuestion.Left * 2) + .lblQuestion.Width
        .btOK.Left = (.Width / 2) - .btOK.Width - 20
        .btCancela.Left = (.Width / 2) + 20
        .btOK.Top = .lblQuestion.Top + .lblQuestion.Height + 15
        .btCancela.Top = .btOK.Top
        .Height = .btOK.Top + 60
        .Left = ((c_lScreenWidth * iMonitor * 0.753) + ((c_lScreenWidth * 0.753) / 2 - .Width / 2))
        .Top = ((System.VerticalResolution) * 0.753 / 2 - .Height / 2)
        .Show
    End With
    ModalQuestion = bFormMsgQuestion
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ModMain", "ModalQuestion", Err.Description)
End Function

Public Function OpenMimicCommand(sMimicName As String, sBranch As String, iMimicWidht As Integer, iMimicHeight As Integer, Optional bCentralized As Boolean)
    Dim ActiveCoord As POINTAPI
    Dim iLeft As Integer, iTop As Integer, iMonitor As Integer
    Dim objMimic As Mimic
    
    On Error GoTo ErrorHandler
    
    If sMimicName = "" Then Exit Function
    
    'get the current cursor location
    GetCursorPos ActiveCoord
''    If LeftWorkspace > 0 Then iMonitor = 1
    iMonitor = Int(ActiveCoord.lXpos / System.HorizontalResolution) - iMonitor
    
    If bCentralized Then
        iLeft = System.HorizontalResolution * iMonitor + (System.HorizontalResolution / 2 - iMimicWidht / 2)
        iTop = System.VerticalResolution / 2 - iMimicHeight / 2
    Else
        iTop = ActiveCoord.lYpos + 7
        If iTop > (System.VerticalResolution - iMimicHeight) Then iTop = (System.VerticalResolution - iMimicHeight - 10)
        If ActiveCoord.lXpos > (iLeft + System.HorizontalResolution - iMimicWidht) Then
            iLeft = (iLeft + System.HorizontalResolution - iMimicWidht - 10)
        Else
            iLeft = ActiveCoord.lXpos
        End If
    End If
    
    'Close the other mimics with the same name
    For Each objMimic In Application.ActiveProject.Mimics
        If (objMimic.FileName = sMimicName) Then
            objMimic.Close
        End If
    Next
    
    Mimics.Open sMimicName, sBranch, , , , , , , iLeft, iTop, True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "OpenMimicCommand", Err.Description)

End Function


''Public Function WaitSecconds(ByVal iSecc As Integer)
  ''  Dim sEndDate As String

    ''sEndDate = DateAdd("s", iSecc, Now)

    ''While Now < sEndDate
      ''  DoEvents
    ''Wend

''End Function


Public Function SetSinoticoLayers()
    Dim iCount As Integer
    Dim iLayerValue As Long
    
    On Error GoTo ErrorHandler
    
    iLayerValue = 65535
    
    iLayerValue = iLayerValue Xor (Not [@HideCDV.Sinotico%] And 4096) 'Layer 12
    iLayerValue = iLayerValue Xor (Not [@HideAMV.Sinotico%] And 2048) 'Layer 11
    iLayerValue = iLayerValue Xor (Not [@HideSinal.Sinotico%] And 1024) 'Layer 10
    
    For iCount = 1 To ThisProject.Mimics.Count
        If InStr(ThisProject.Mimics.Item(iCount).FileName, "GUA_TRAF_") > 0 Then
            ThisProject.Mimics.Item(iCount).Windows(1).Layers = iLayerValue
        End If
    Next iCount
       
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "SetSinoticoLayers", Err.Description)

End Function



'=======================================================================================
'=======================================================================================
'Procedure  : FillPlatformsGeografic
'Type       : Sub
'Objective  : Take all platforms in the current line and to insert these platforms in the combobox
'Parameters : sBranch (Branch), Combobox(Combobox where the platforms will be inserted), _
                bDefaultEmpty (if this parameter is TRUE a empty value will be inserted)
'Return     : Byref Combobox
'=======================================================================================
' Rev       Date        Modified by       Description
'---------------------------------------------------------------------------------------
'  1     2011/12/22     Wagner Queiroz    Creation
'=======================================================================================
Public Sub FillPlatformsGeografic(ByRef m_CollPlat As Object, ByVal sBranch As String)
    Dim xmlOrderedPlatformList              As DOMDocument
    Dim FirstNodeLevel      As IXMLDOMNodeList
    Dim oElementClass       As IXMLDOMElement
    Dim sQuery              As String
    Dim sSentido            As String
    Dim iCount              As Integer
    Dim bInvert             As Boolean
    Dim CollAux             As Variant
    Dim vPlatId             As Variant
    Dim vPlatName           As Variant
    
On Error GoTo ErrorHandler

    Set m_CollPlat = CreateObject("Scripting.Dictionary")

    Set CollAux = Nothing
    Set CollAux = CreateObject("Scripting.Dictionary")
    
    Set xmlOrderedPlatformList = New DOMDocument
    
    If VerifyVariable(Variables("OPCCluster:SpecificModuleObject.OTTModule.OTTMgr.OrderedPlatformList")) Then
        
        xmlOrderedPlatformList.loadXML Variables("OPCCluster:SpecificModuleObject.OTTModule.OTTMgr.OrderedPlatformList").Value
    
    Else
        
        xmlOrderedPlatformList.Load ThisProject.Path & "\JAR Files\Specific\OrderedPlatformList.xml"
    
    End If
   
    If [LibraryPath%] Like "*L1*" Then
        
        sSentido = "LEFT"
    
    ElseIf [LibraryPath%] Like "*L2*" Then
        
        If InStr(1, sBranch, "_ER_") > 0 Or InStr(1, sBranch, "_EL_") > 0 Then
            
            sSentido = "RIGHT"
            bInvert = True
            
        Else
        
            sSentido = "LEFT"
            
        
        End If
        
    ElseIf [LibraryPath%] Like "*L3*" Then
        
        sSentido = "LEFT"
    
    End If
     
    sQuery = "//OrderedPlatformList/Path[@direction=" & Chr(34) & sSentido & Chr(34) & "]/Platform"
    
    Set FirstNodeLevel = xmlOrderedPlatformList.selectNodes(sQuery)
    
    If bInvert = True Then
        
        For Each oElementClass In FirstNodeLevel
                
            CollAux.Add oElementClass.getAttribute("id"), oElementClass.getAttribute("name")
            
        Next oElementClass
        
        vPlatId = CollAux.Keys
        vPlatName = CollAux.Items
        
        For iCount = CollAux.Count - 1 To 0 Step -1
                
            m_CollPlat.Add vPlatId(iCount), vPlatName(iCount)
            
        Next iCount
        
    Else
        
        For Each oElementClass In FirstNodeLevel
                
            m_CollPlat.Add oElementClass.getAttribute("id"), oElementClass.getAttribute("name")
            
        Next oElementClass
    
    End If
    Exit Sub

ErrorHandler:
    
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "FillPlatformsGeografic", Err.Description)

End Sub

Public Sub FillPlatformsGeograficToTrain(ByRef m_CollPlat As Object, ByVal sBranch As String)
    Dim xmlOrderedPlatformList              As DOMDocument
    Dim FirstNodeLevel      As IXMLDOMNodeList
    Dim oElementClass       As IXMLDOMElement
    Dim sQuery              As String
    Dim sSentido            As String
    Dim iCount              As Integer
    Dim bInvert             As Boolean
    Dim CollAux             As Variant
    Dim vPlatId             As Variant
    Dim vPlatName           As Variant
    
On Error GoTo ErrorHandler

    Set m_CollPlat = CreateObject("Scripting.Dictionary")

    Set CollAux = Nothing
    Set CollAux = CreateObject("Scripting.Dictionary")
    
    Set xmlOrderedPlatformList = New DOMDocument
    
    If VerifyVariable(Variables("OPCCluster:SpecificModuleObject.OTTModule.OTTMgr.OrderedPlatformList")) Then
        
        xmlOrderedPlatformList.loadXML Variables("OPCCluster:SpecificModuleObject.OTTModule.OTTMgr.OrderedPlatformList").Value
    
    Else
        
        xmlOrderedPlatformList.Load ThisProject.Path & "\JAR Files\Specific\OrderedPlatformList.xml"
    
    End If
   
    If [LibraryPath%] Like "*L1*" Then
        
        sSentido = "LEFT"
    
    ElseIf [LibraryPath%] Like "*L2*" Then
        
        If InStr(1, sBranch, "_ER_") > 0 Or InStr(1, sBranch, "_EL_") > 0 Then
            
            sSentido = "RIGHT"
            bInvert = True
            
        Else
        
            sSentido = "LEFT"
            
        
        End If
        
    ElseIf [LibraryPath%] Like "*L3*" Then
        
        sSentido = "LEFT"
    
    End If
     
    sQuery = "//OrderedPlatformList/Path[@direction=" & Chr(34) & sSentido & Chr(34) & "]/Platform"
    
    Set FirstNodeLevel = xmlOrderedPlatformList.selectNodes(sQuery)
    
    If bInvert = True Then
        
        For Each oElementClass In FirstNodeLevel
                
            CollAux.Add oElementClass.getAttribute("id"), oElementClass.getAttribute("name")
            
        Next oElementClass
        
        vPlatId = CollAux.Keys
        vPlatName = CollAux.Items
        
        For iCount = 0 To CollAux.Count
                
            m_CollPlat.Add vPlatId(iCount), vPlatName(iCount)
            
        Next iCount
        
    Else
        
        For Each oElementClass In FirstNodeLevel
                
            m_CollPlat.Add oElementClass.getAttribute("id"), oElementClass.getAttribute("name")
            
        Next oElementClass
    
    End If
    Exit Sub

ErrorHandler:
    
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "FillPlatformsGeografic", Err.Description)

End Sub

'=======================================================================================
'=======================================================================================
'Procedure  : FillStationsGeografic
'Type       : Sub
'Objective  : Take all stations in the current line and to insert these Stations in the combobox
'Parameters : sBranch (Branch), Combobox(Combobox where the Stations will be inserted),
                'bDefaultEmpty (if this parameter is TRUE a empty value will be inserted)
'Return     : Byref Combobox
'=======================================================================================
' Rev       Date        Modified by       Description
'---------------------------------------------------------------------------------------
'  1     2011/12/22     Wagner Queiroz    Creation
'=======================================================================================
Public Sub FillStationsGeografic(ByRef m_CollStat As Object, ByVal sBranch As String)
    Dim xmlOrderedStationList              As DOMDocument
    Dim FirstNodeLevel      As IXMLDOMNodeList
    Dim oElementClass       As IXMLDOMElement
    Dim sQuery              As String
    Dim sSentido            As String
    Dim iCount              As Integer
    Dim bInvert             As Boolean
    Dim CollAux             As Variant
    Dim vStatId             As Variant
    Dim vStatName           As Variant
    
On Error GoTo ErrorHandler

    Set m_CollStat = CreateObject("Scripting.Dictionary")
    
    Set CollAux = Nothing
    Set CollAux = CreateObject("Scripting.Dictionary")
    
    Set xmlOrderedStationList = New DOMDocument
    
    If VerifyVariable(Variables("OPCCluster:SpecificModuleObject.OTTModule.OTTMgr.OrderedStationList")) Then
        
        xmlOrderedStationList.loadXML Variables("OPCCluster:SpecificModuleObject.OTTModule.OTTMgr.OrderedStationList").Value
    
    Else
        
        xmlOrderedStationList.Load ThisProject.Path & "\JAR Files\Specific\OrderedStationList.xml"
    
    End If
   
    If [LibraryPath%] Like "*L1*" Then
        
        sSentido = "LEFT"
    
    ElseIf [LibraryPath%] Like "*L2*" Then
    
        
        sSentido = "LEFT"

        
    ElseIf [LibraryPath%] Like "*L3*" Then
        
        sSentido = "LEFT"
    
    End If
     
    sQuery = "//OrderedStationList/Path[@direction=" & Chr(34) & sSentido & Chr(34) & "]/Station"
    
    Set FirstNodeLevel = xmlOrderedStationList.selectNodes(sQuery)
    
        
    For Each oElementClass In FirstNodeLevel
                
        m_CollStat.Add oElementClass.getAttribute("id"), oElementClass.getAttribute("name")
            
    Next oElementClass
    
    Exit Sub

ErrorHandler:
    
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "FillStationsGeografic", Err.Description)

End Sub


'*  Function: VerifyVariable
'*            Check the status and the quality of the variable
'*  It receives an variable to test, return true or false
'* ***************************************************************************************
Public Function VerifyVariable(ByRef varTestVariable As Variable) As Boolean
    On Error GoTo ErrorHandler
    
    If (varTestVariable.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACEF_ALWAYS, "ERROR - MOD_General", "VerifyVariable", "The Status is WAITING - " & varTestVariable.Name)
    ElseIf (varTestVariable.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "ERROR - MOD_General", "VerifyVariable", "The Status is CONFIG ERROR - " & varTestVariable.Name)
    ElseIf (varTestVariable.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACEF_ALWAYS, "ERROR - MOD_General", "VerifyVariable", "The Status is NOT CONNECTED - " & varTestVariable.Name)
    ElseIf (varTestVariable.Status = fvVariableStatusBad) Then
        Call CBTrace(CBTRACEF_ALWAYS, "ERROR - MOD_General", "VerifyVariable", "The Status is BAD - " & varTestVariable.Name)
    ElseIf (varTestVariable.Quality <> 192) Then '* The quality of the variable is not good
        Call CBTrace(CBTRACEF_ALWAYS, "ERROR - MOD_General", "VerifyVariable", "The Quality is not Good - " & varTestVariable.Name)
    Else
        VerifyVariable = True
    End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "VerifyVariable", Err.Description)
'    Debug.Print Err.Description
End Function

