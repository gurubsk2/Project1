Attribute VB_Name = "General"
'Public MyWinMP As New WindowsMediaPlayer
Public sLastImage As String
Public sLastImageFileName As String
Public sBranch As String
Public sTimeParoAlarma As String
Public bTipoSAF As Boolean
Public Type AppliedFilters_ALM
    sLabel As String
    sState As String
    sSeverity As String
    sTimeOfActivation As String
    sGroup As String
    sName As String
End Type
Public MyAppliedFilters_ALM As AppliedFilters_ALM
Public Type AppliedFiltersDisplay_ALM
    sLabel As String
    sState As String
    sSeverity As String
    sInitDate As String
    sEndDate As String
    sInitTime As String
    sEndTime As String
    sEquipment As String
    sStation As String
    sZone As String
    sName As String
End Type
Public MyAppliedFiltersDisplay_ALM As AppliedFiltersDisplay_ALM
Public Type AppliedFilters_EVT
    sLabel As String
    sSeverity As String
    sTimeOfActivation As String
    sGroup As String
End Type
Public MyAppliedFilters_EVT As AppliedFilters_EVT
Public Type AppliedFiltersDisplay_EVT
    sLabel As String
    sSeverity As String
    sInitDate As String
    sEndDate As String
    sInitTime As String
    sEndTime As String
    sEquipment As String
    sStation As String
    sZone As String
End Type
Public MyAppliedFiltersDisplay_EVT As AppliedFiltersDisplay_EVT
Public Type AppliedFilters_PTL
    sLabel As String
    sSeverity As String
    sTimeOfActivation As String
    sGroup As String
End Type
Public MyAppliedFilters_PTL As AppliedFilters_PTL
Public Type AppliedFiltersDisplay_PTL
    sLabel As String
    sSeverity As String
    sInitDate As String
    sEndDate As String
    sInitTime As String
    sEndTime As String
    sEquipment As String
    sStation As String
    sZone As String
End Type
Public MyAppliedFiltersDisplay_PTL As AppliedFiltersDisplay_PTL
Public Type AppliedFilters_OP
    sLabel As String
    sSeverity As String
    sTimeOfActivation As String
    sGroup As String
    sOperator As String
End Type
Public MyAppliedFilters_OP As AppliedFilters_OP
Public Type AppliedFiltersDisplay_OP
    sLabel As String
    sSeverity As String
    sInitDate As String
    sEndDate As String
    sInitTime As String
    sEndTime As String
    sEquipment As String
    sStation As String
    sOperator As String
    sZone As String
End Type
Public MyAppliedFiltersDisplay_OP As AppliedFiltersDisplay_OP
Public sAlarmEqpto As String



Public Const STR_TREND_XMLFILE = "\Working Files\DataSourceNames.xml"
Public Const INT_MAXPENS_MONO As Integer = 9 ' Including the X-axis
Public Const INT_MAXPENS_MULTI As Integer = 2 ' Including the X-axis

Public Const INT_IDXLISTBOX_IDXPENLIST_OFFSET = 1
Public Const STR_TREND_DELIM As String = "___"
Public Const STR_CLOSE_AFTER_ADD As String = "CloseAfterAdd"
Public Const STR_DONT_CLOSE_AFTER_ADD As String = "DontCloseAfterAdd"

Public Const STR_TRENDTXT_EQP_EXIST As String = "Equipo ya existente en la lista"
Public Const STR_TRENDTXT_EQP_ADDED_OK As String = "Equipo sido agregado con éxito"
Public Const STR_TRENDTXT_PENS_EXCEEDED As String = "No se añadió Equipo. Se alcanzó el número máximo de pluma"
Public Const STR_TRENDTXT_PLS_SELECT_EQP As String = "Por favor, seleccione el equipo para ver"
Public Const STR_TRENDTXT_EQP_ADDED_ERROR As String = "Error al añadir equipos a la tendencia"
Public Const STR_TRENDTXT_EQP_MAX_SELECTION_REACHED As String = "Ter escolhido o número máximo de equipamentos"

Public Const ATR_NAME As String = "NAME"
Public Const ATR_DISPLAYNAME As String = "DISPLAYNAME"
Public Const ATR_STATION As String = "STATION"
Public Const ATR_EQPFAMILY As String = "EQPFAMILY"
Public Const ATR_VARIABLETYPE As String = "VARIABLETYPE"
Public Const ATR_DESCRIPTION As String = "DESCRIPTION"
Public Const ATR_PLOTMIN As String = "PLOTMIN"
Public Const ATR_PLOTMAX As String = "PLOTMAX"


Public NameDes As Scripting.Dictionary
Public TrendXMLDoc As MSXML2.DOMDocument




Dim sProfile() As String
Public strMsgImediata1 As String
Public strMsgImediata2 As String
Public strMsgImediata3 As String
Public vbModalAnswer As VbMsgBoxResult
Public sMsgHIHI1_Atual As String
Public sListaClasesSinMode(30) As String

Public Function Navegation(sMimicOpened As String, sMimicClosed As String)
    'Funcao para abertura dos Mimics e dinamica dos botoes de navegacao
    'Abre o mimic solicitado e fecha o mimic ativo
    'Altera a cor e o modelo do botao de navegacao, isso serve para identificar qual tela esta ativa
    Dim iMimicPosition As Integer
    Dim aux_posic_origem As Text
    Dim aux_posic_destino As Text

'On Error Resume Next

    iMimicPosition = ThisProject.ActiveMimic.Windows(1).Left
'rparmeza
    'If iMimicPosition >= 1920 Then
        'iMimicPosition = 1921
        '[Monitor%] = "M2"
    'Else
        'iMimicPosition = 0
'        '[Monitor%] = "M1"
    'End If
    
    If TheseMimics.IsOpened(sMimicClosed) = False Then
        Mimics.Open sMimicClosed, , , , , , , , iMimicPosition, , True
        Mimics.Item(sMimicOpened).Close fvDoNotSaveChanges
        
    Else
       If ThisProject.Mimics.Item(sMimicClosed).Windows(1).Left <> iMimicPosition Then
        
           aux_posic_origem = TheseMimics.Item(sMimicOpened).Windows(1).Left
           aux_posic_destino = TheseMimics.Item(sMimicClosed).Windows(1).Left
           
           TheseMimics.Item(sMimicOpened).Windows(1).Left = aux_posic_destino
           
           TheseMimics.Item(sMimicClosed).Windows(1).Left = aux_posic_origem
       End If
    End If
    
    Call OnOff_Button(vbNullString)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::GetOPCCluster
' Input:        none
' Output:       [String]   The OPC Cluster
' Description:  Returns the OPC Cluster
'-------------------------------------------------------------------------------
'Public Function GetOPCCluster() As String
'    GetOPCCluster = m_strOPCClusterName
'End Function

Public Function OnOff_Button(sType As String)
'Ps:Obot¦o de TrendViewer n¦o depende do perfil do usuario logado e sim do subsistema selecionado
    On Error Resume Next
    sProfile = ThisProject.Security.users.GetProfiles(ThisProject.Security.UserName)
[txtUsuario%] = ThisProject.Security.UserName & "/" & sProfile(0)
Select Case sProfile(0)
  
    'Profile Administrator
    Case "Mainteneur-Administrateur"
        If sType = "Login" Then
'            Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = False
            Variables.Item("GTC_UpDown%").Value = False
            Variables.Item("GTE_UpDown%").Value = False
            Variables.Item("ATS_Control%").Value = False
            Variables.Item("GTC_Control%").Value = False
            Variables.Item("GTE_Control%").Value = False
            Variables.Item("Eclairage%").Value = False
            Variables.Item("Sound_Button%").Value = False
            Variables.Item("Alarms%").Value = False
            Variables.Item("AckSelection%").Value = False
            Variables.Item("Events%").Value = False
            Variables.Item("Export%").Value = False
            Variables.Item("ChangePassword%").Value = False
            Variables.Item("Users%").Value = False
            Variables.Item("ProjectHelp%").Value = False
            Variables.Item("TrendViewer%").Value = False
 '           Variables.Item("ProjectExit%").Value = True
            Variables.Item("System%").Value = False
'            Variables.Item("Printer%").Value = False
            Variables.Item("AProposDe%").Value = False
            
        Else
'            Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = True
            Variables.Item("GTC_UpDown%").Value = True
            Variables.Item("GTE_UpDown%").Value = True
            Variables.Item("ATS_Control%").Value = True
            Variables.Item("GTC_Control%").Value = True
            Variables.Item("GTE_Control%").Value = True
            Variables.Item("Eclairage%").Value = True
            Variables.Item("Sound_Button%").Value = True
            Variables.Item("Alarms%").Value = True
            Variables.Item("AckSelection%").Value = True
            Variables.Item("Events%").Value = True
            Variables.Item("Export%").Value = True
            Variables.Item("ChangePassword%").Value = True
            Variables.Item("Users%").Value = True
            Variables.Item("ProjectHelp%").Value = True
            Variables.Item("TrendViewer%").Value = True
'            Variables.Item("ProjectExit%").Value = True
            Variables.Item("System%").Value = True
'            Variables.Item("Printer%").Value = True
            Variables.Item("AProposDe%").Value = True

        End If
        
        'Profile Operator
    Case "Opérateur"
        If sType = "Login" Then
'           Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = False
            Variables.Item("GTC_UpDown%").Value = False
            Variables.Item("GTE_UpDown%").Value = False
            Variables.Item("ATS_Control%").Value = False
            Variables.Item("GTC_Control%").Value = False
            Variables.Item("GTE_Control%").Value = False
            Variables.Item("Eclairage%").Value = False
            Variables.Item("Sound_Button%").Value = False
            Variables.Item("Alarms%").Value = False
            Variables.Item("AckSelection%").Value = False
            Variables.Item("Events%").Value = False
            Variables.Item("Export%").Value = False
            Variables.Item("ChangePassword%").Value = False
            Variables.Item("Users%").Value = False
            Variables.Item("ProjectHelp%").Value = False
            Variables.Item("TrendViewer%").Value = False
'            Variables.Item("ProjectExit%").Value = False
            Variables.Item("System%").Value = False
'            Variables.Item("Printer%").Value = False
            Variables.Item("AProposDe%").Value = False
        Else
'            Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = True
            Variables.Item("GTC_UpDown%").Value = True
            Variables.Item("GTE_UpDown%").Value = True
            Variables.Item("ATS_Control%").Value = True
            Variables.Item("GTC_Control%").Value = True
            Variables.Item("GTE_Control%").Value = True
            Variables.Item("Eclairage%").Value = True
            Variables.Item("Sound_Button%").Value = True
            Variables.Item("Alarms%").Value = True
            Variables.Item("AckSelection%").Value = True
            Variables.Item("Events%").Value = True
            Variables.Item("ChangePassword%").Value = True
            Variables.Item("ProjectHelp%").Value = True
            Variables.Item("AProposDe%").Value = True
            Variables.Item("Export%").Value = False
            Variables.Item("Users%").Value = False
            Variables.Item("TrendViewer%").Value = False
'            Variables.Item("ProjectExit%").Value = False
            Variables.Item("System%").Value = False
'            Variables.Item("Printer%").Value = True

        End If
    
    'Profile Guest
    Case "Invité"
        If sType = "Login" Then
'            Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = False
            Variables.Item("GTC_UpDown%").Value = False
            Variables.Item("GTE_UpDown%").Value = False
            Variables.Item("ATS_Control%").Value = False
            Variables.Item("GTC_Control%").Value = False
            Variables.Item("GTE_Control%").Value = False
            Variables.Item("Eclairage%").Value = False
            Variables.Item("Sound_Button%").Value = False
            Variables.Item("Alarms%").Value = False
            Variables.Item("AckSelection%").Value = False
            Variables.Item("Events%").Value = False
            Variables.Item("Export%").Value = False
            Variables.Item("ChangePassword%").Value = False
            Variables.Item("Users%").Value = False
            Variables.Item("ProjectHelp%").Value = False
            Variables.Item("TrendViewer%").Value = False
 '           Variables.Item("ProjectExit%").Value = False
            Variables.Item("System%").Value = False
 '           Variables.Item("Printer%").Value = False
            Variables.Item("AProposDe%").Value = False
        Else
'            Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = True
            Variables.Item("GTC_UpDown%").Value = True
            Variables.Item("GTE_UpDown%").Value = True
            Variables.Item("ATS_Control%").Value = False
            Variables.Item("GTC_Control%").Value = False
            Variables.Item("GTE_Control%").Value = False
            Variables.Item("Eclairage%").Value = False
            Variables.Item("Sound_Button%").Value = True
            Variables.Item("Alarms%").Value = True
            Variables.Item("AckSelection%").Value = False
            Variables.Item("Events%").Value = True
            Variables.Item("ChangePassword%").Value = True
            Variables.Item("ProjectHelp%").Value = True
            Variables.Item("AProposDe%").Value = True
            Variables.Item("Export%").Value = False
            Variables.Item("Users%").Value = False
            Variables.Item("TrendViewer%").Value = True
'            Variables.Item("ProjectExit%").Value = False
            Variables.Item("System%").Value = False
'            Variables.Item("Printer%").Value = False
            
        End If
        
     'Profile Formateur
    Case "Formateur"
        If sType = "Login" Then
'            Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = False
            Variables.Item("GTC_UpDown%").Value = False
            Variables.Item("GTE_UpDown%").Value = False
            Variables.Item("ATS_Control%").Value = False
            Variables.Item("GTC_Control%").Value = False
            Variables.Item("GTE_Control%").Value = False
            Variables.Item("Eclairage%").Value = False
            Variables.Item("Sound_Button%").Value = False
            Variables.Item("Alarms%").Value = False
            Variables.Item("AckSelection%").Value = False
            Variables.Item("Events%").Value = False
            Variables.Item("ChangePassword%").Value = False
            Variables.Item("ProjectHelp%").Value = False
            Variables.Item("AProposDe%").Value = False
            Variables.Item("Export%").Value = False
            Variables.Item("Users%").Value = False
            Variables.Item("TrendViewer%").Value = False
'            Variables.Item("ProjectExit%").Value = False
            Variables.Item("System%").Value = False
'            Variables.Item("Printer%").Value = False
            Variables.Item("Rejeu%").Value = False
        Else
'            Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = True
            Variables.Item("GTC_UpDown%").Value = True
            Variables.Item("GTE_UpDown%").Value = True
            Variables.Item("ATS_Control%").Value = False
            Variables.Item("GTC_Control%").Value = False
            Variables.Item("GTE_Control%").Value = False
            Variables.Item("Eclairage%").Value = False
            Variables.Item("Sound_Button%").Value = False
            Variables.Item("Alarms%").Value = True
            Variables.Item("AckSelection%").Value = False
            Variables.Item("Events%").Value = False
            Variables.Item("ChangePassword%").Value = True
            Variables.Item("ProjectHelp%").Value = True
            Variables.Item("AProposDe%").Value = True
            Variables.Item("Export%").Value = False
            Variables.Item("Users%").Value = True
            Variables.Item("TrendViewer%").Value = False
'            Variables.Item("ProjectExit%").Value = False
            Variables.Item("System%").Value = False
'            Variables.Item("Printer%").Value = True
            Variables.Item("Rejeu%").Value = True
            
        End If
    
    'Profile Consultation
    Case "Consultation"
        If sType = "Login" Then
 '           Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = False
            Variables.Item("GTC_UpDown%").Value = False
            Variables.Item("GTE_UpDown%").Value = False
            Variables.Item("ATS_Control%").Value = False
            Variables.Item("GTC_Control%").Value = False
            Variables.Item("GTE_Control%").Value = False
            Variables.Item("Eclairage%").Value = False
            Variables.Item("Sound_Button%").Value = False
            Variables.Item("Alarms%").Value = False
            Variables.Item("AckSelection%").Value = False
            Variables.Item("Events%").Value = False
            Variables.Item("ChangePassword%").Value = False
            Variables.Item("ProjectHelp%").Value = False
            Variables.Item("AProposDe%").Value = False
            Variables.Item("Export%").Value = False
            Variables.Item("Users%").Value = False
            Variables.Item("TrendViewer%").Value = False
'            Variables.Item("ProjectExit%").Value = False
            Variables.Item("System%").Value = False
'            Variables.Item("Printer%").Value = False
            Variables.Item("Rejeu%").Value = False
        Else
'            Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = True
            Variables.Item("GTC_UpDown%").Value = True
            Variables.Item("GTE_UpDown%").Value = True
            Variables.Item("ATS_Control%").Value = False
            Variables.Item("GTC_Control%").Value = False
            Variables.Item("GTE_Control%").Value = False
            Variables.Item("Eclairage%").Value = False
            Variables.Item("Sound_Button%").Value = True
            Variables.Item("Alarms%").Value = True
            Variables.Item("AckSelection%").Value = False
            Variables.Item("Events%").Value = True
            Variables.Item("ChangePassword%").Value = True
            Variables.Item("ProjectHelp%").Value = True
            Variables.Item("AProposDe%").Value = True
            Variables.Item("Export%").Value = False
            Variables.Item("Users%").Value = False
            Variables.Item("TrendViewer%").Value = True
'            Variables.Item("ProjectExit%").Value = False
            Variables.Item("System%").Value = False
'            Variables.Item("Printer%").Value = False
            Variables.Item("Rejeu%").Value = False
            
        End If
    
    
    'Profile Default
    Case "DefaultProfile"
'        Variables.Item("Login_Logout%").Value = True
            Variables.Item("ATS_UpDown%").Value = False
            Variables.Item("GTC_UpDown%").Value = False
            Variables.Item("GTE_UpDown%").Value = False
            Variables.Item("ATS_Control%").Value = False
            Variables.Item("GTC_Control%").Value = False
            Variables.Item("GTE_Control%").Value = False
            Variables.Item("Eclairage%").Value = False
            Variables.Item("Sound_Button%").Value = False
            Variables.Item("Alarms%").Value = False
            Variables.Item("AckSelection%").Value = False
            Variables.Item("Events%").Value = False
            Variables.Item("ChangePassword%").Value = False
            Variables.Item("ProjectHelp%").Value = False
            Variables.Item("AProposDe%").Value = False
            Variables.Item("Export%").Value = False
            Variables.Item("Users%").Value = False
            Variables.Item("TrendViewer%").Value = False
'            Variables.Item("ProjectExit%").Value = False
            Variables.Item("System%").Value = False
'            Variables.Item("Printer%").Value = False
            Variables.Item("Rejeu%").Value = False
    Case Else
'        Variables.Item("Login_Logout%").Value = False
            Variables.Item("ATS_UpDown%").Value = True
            Variables.Item("GTC_UpDown%").Value = True
            Variables.Item("GTE_UpDown%").Value = True
            Variables.Item("ATS_Control%").Value = True
            Variables.Item("GTC_Control%").Value = True
            Variables.Item("GTE_Control%").Value = True
            Variables.Item("Eclairage%").Value = True
            Variables.Item("Sound_Button%").Value = True
            Variables.Item("Alarms%").Value = True
            Variables.Item("AckSelection%").Value = True
            Variables.Item("Events%").Value = True
            Variables.Item("ChangePassword%").Value = True
            Variables.Item("ProjectHelp%").Value = True
            Variables.Item("AProposDe%").Value = True
            Variables.Item("Export%").Value = True
            Variables.Item("Users%").Value = True
            Variables.Item("TrendViewer%").Value = True
 '           Variables.Item("ProjectExit%").Value = True
            Variables.Item("System%").Value = True
'            Variables.Item("Printer%").Value = True
            Variables.Item("Rejeu%").Value = True
  End Select
    
End Function

'###########################################################################
'Comandos de Login, Logout e Exit
'###########################################################################
Public Function LogOnF2()
Dim strFiltro_top As String
    On Error Resume Next

Dim strUser As String
strUser = CreateObject("WScript.Network").UserName

'Mimics.Open "GUA_welcome2", , , 2
ThisProject.LogonUser False, strUser, ""
'[txtUsuario%] = ThisProject.Security.UserName & "/" & sProfile(0)
'rparmeza
'    Mimics.Open "GUA_Welcome", "M1", , , , , , , , , True
    
'    If ((LCase(ThisSystem.ComputerName) Like "*tcc*")) Or ((LCase(ThisSystem.ComputerName) Like "*tccsrvten1*")) Or ((LCase(ThisSystem.ComputerName) Like "*tccsrvten2*")) Or ((LCase(ThisSystem.ComputerName) Like "*tccihmten1*")) Or ((LCase(ThisSystem.ComputerName) Like "*tzasrvten1*")) Or ((LCase(ThisSystem.ComputerName) Like "*tzasrvten2*")) Or ((LCase(ThisSystem.ComputerName) Like "*tzaihmten1*")) Then
    If ((LCase(ThisSystem.ComputerName) Like "*tccsrvten1*")) Or ((LCase(ThisSystem.ComputerName) Like "*tccsrvten2*")) Or ((LCase(ThisSystem.ComputerName) Like "*tccihmten1*")) Or ((LCase(ThisSystem.ComputerName) Like "*tzasrvten1*")) Or ((LCase(ThisSystem.ComputerName) Like "*tzasrvten2*")) Or ((LCase(ThisSystem.ComputerName) Like "*tzaihmten1*")) Then
'        Mimics.Open "GUA_TELA_ENE_GERAL", "M1", , , , , , , , , True
'        Mimics.Open "GUA_TELA_ENE_GERAL2", "M2", , , , , , , , , True
        TheseMimics.Open "GUA_TELA_ENE_GERAL", "M2", , , , , , , 1921, 0, True
        TheseMimics.Open "GUA_TELA_ENE_GERAL", "M1", , , , , , , 0, 0, True
        
    Else
    Mimics.Open "GUA_Welcome", "M1", , , , , , , , , True


    End If
    
    Erase sProfile
    Call OnOff_Button(vbNullString)
    
    If Variables.Item("Login_Logout%").Value = False Then Exit Function
    
    iPopupPosition = ThisProject.ActiveMimic.Windows(1).Left

    If iPopupPosition = 0 Then
        iPopupPosition = 0
    Else
        iPopupPosition = 1681
    End If
    
    ThisProject.LogonUser False, strUser, ""

    'Call OpenForms("frmLogin")
    
    sProfile = ThisProject.Security.users.GetProfiles(ThisProject.Security.UserName)
    
    If sProfile(0) <> "DefaultProfile" Then
'        Variables.Item("Login_Logout%").Value = False
        [txtUsuario%] = ThisProject.Security.UserName & "/" & sProfile(0)
    End If
    Call OnOff_Button(vbNullString)
End Function

Public Function LogOffF3()


OpenForms ("Log_off")
    On Error Resume Next
    Dim iCount As Integer

    If Variables.Item("Login_Logout%").Value = False Then Exit Function

    iPopupPosition = ThisProject.ActiveMimic.Windows(1).Left
    If iPopupPosition = 0 Then
        iPopupPosition = 0
    Else
        iPopupPosition = 1681
    End If

    OpenForms ("frmMsgQuestion:2")

    If blogoff = True Then

        For iCount = 1 To ThisProject.Mimics.Count
            ThisProject.Mimics.Item(iCount).Close fvDoNotSaveChanges
        Next iCount

        Mimics.Open "All_Timer", , , , , , , , 0, 0, True
        Mimics.Open "GUA_Welcome", , , , , , , , 1921, 0, True
'        Mimics.Open "GUA_TELA_ENE_GERAL", , , , , , , , 1921, 0, True
        Mimics.Open "GUA_welcome2", , , , , , , , 0, 0, True
'        Mimics.Open "GUA_TELA_ENE_GERAL", , , , , , , , 0, 0, True
        
'        Mimics.Open "All_Timer", , , , , , , , 0, 0, True
'        Mimics.Open "GUA_TELA_ENE_GERAL", , , , , , , , 1921, 0, True
'        Mimics.Open "GUA_TELA_ENE_GERAL2", , , , , , , , 0, 0, True

        [txtUsuario%] = vbNullString

        ThisProject.Security.LogoffUser (False)

        Call OnOff_Button(vbNullString)
        blogoff = False
    End If
End Function

Public Function ExitProjectAltF4()
    On Error Resume Next

    If Variables.Item("ProjectExit%").Value = False Then Exit Function
    OpenForms ("frmMsgQuestion:1")
End Function

Public Function COMMAND_S2K_COMMON_NO_CONS(ByVal ValueCommand As String, ByVal Complement As String)
    On Error Resume Next
    aux_cmd = StrObjectName & Complement
    TheseVariables.Item(aux_cmd).Value = ValueCommand
End Function

###########################################################################
Funç¦o para abertura dos forms
###########################################################################

Public Function OpenForms(sFormName As String, Optional ByVal sBranchForm As String)
    On Error GoTo ErrorHandler

    If InStr(sFormName, ":") > 0 Then
        iFormMsgQuestion = Split(sFormName, ":")(1)
        sFormName = Split(sFormName, ":")(0)
    End If

    Select Case sFormName
        
        Case "frm_gua_cmd_Teleindicadores"
            With frm_gua_cmd_Teleindicadores
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
         Case "Log_off"
            With Log_off
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_disyuntor_dv"
            With frm_gua_cmd_disyuntor_dv
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frmswitch"
            With frmswitch
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_Rectificador"
            With frm_gua_cmd_Rectificador
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_Tablero"
            With frm_gua_cmd_Tablero
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
            
        Case "frm_gua_cmd_batteries_charger"
            With frm_gua_cmd_batteries_charger
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With

            
        Case "frm_gua_reconfigurador_cmd"
            With frm_gua_reconfigurador_cmd
            If iPopupPosition > 1920 Then
                .Left = 1820
            Else
                .Left = 380
            End If
                .Top = 100
                .Show
            End With
            
        Case "frm_gua_cmd_Transformador"
            With frm_gua_cmd_Transformador
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_Ondulador"
            With frm_gua_cmd_Ondulador
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
            Case "frm_gua_cmd_DTRS"
            With frm_gua_cmd_DTRS
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_PML"
            With frm_gua_cmd_PML
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_TCM"
            With frm_gua_cmd_TCM
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_TCM_A"
            With frm_gua_cmd_TCM_A
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_TCMLLEGADA"
            With frm_gua_cmd_TCMLlegada
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_interruptor"
            With frm_gua_cmd_interruptor
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_interruptor_A"
            With frm_gua_cmd_interruptor_A
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_interruptor_B"
            With frm_gua_cmd_interruptor_B
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_seccionador"
            With frm_gua_cmd_seccionador
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_Transformador_230"
            With frm_gua_cmd_Transformador_230
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_DisconnectSwitchSIB"
            With frm_gua_cmd_DisconnectSwitchSIB
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_disyuntor"
            With frm_gua_cmd_disyuntor
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_disyuntor_A"
            With frm_gua_cmd_disyuntor_A
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_disyuntor_B"
            With frm_gua_cmd_disyuntor_B
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_disyuntor_C"
            With frm_gua_cmd_disyuntor_C
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_vigilancia"
            With frm_gua_cmd_vigilancia
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_sonorizacion"
            With frm_gua_cmd_sonorizacion
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
         Case "frm_gua_cmd_SAI"
            With frm_gua_cmd_SAI
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_SAA"
            With frm_gua_cmd_SAA
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_DV"
            With frm_gua_cmd_DV
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_ST"
            With frm_gua_cmd_ST
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_SV"
            With frm_gua_cmd_SV
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_IT"
            With frm_gua_cmd_IT
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
                        
        Case "frm_gua_cmd_DTRS"
            With frm_gua_cmd_DTRS
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_clima"
            With frm_gua_cmd_clima
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
        Case "frm_gua_cmd_elevador"
            With frm_gua_cmd_elevador
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With

        Case "frm_gua_cmd_escalera"
            With frm_gua_cmd_escalera
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
    
        Case "frm_gua_cmd_incendio"
            With frm_gua_cmd_incendio
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With
            
            
        Case "frm_gua_cmd_ventilacao_estacion"
            With frm_gua_cmd_ventilacao_estacion
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With

        Case "frm_gua_cmd_DSTRA"
        'open form only with communication
        With frm_gua_cmd_DSTRA
        If iPopupPositionl > 1100 Then iPopupPositionl = (iPopupPositionl - 30)

            .Left = iPopupPositionl - 10
            .Top = iPopupPositiont - 10
         .Show
        End With

        Case "frm_gua_cmd_drenage"
        'open form only with communication
        With frm_gua_cmd_drenage
        If iPopupPositionl > 1100 Then iPopupPositionl = (iPopupPositionl - 30)

            .Left = iPopupPositionl - 10
            .Top = iPopupPositiont - 10
         .Show
        End With
        

        Case "frmMsgQuestion"
            With frmMsgQuestion
            If iPopupPosition > 1920 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With



        Case "frmMsgExclamation"
           With frmMsgExclamation

            If iPopupPosition > 1920 Then
                .Left = 1980
            Else
                .Left = 500
            End If
                .Top = 400
                 .Show
            Exit Function
            End With

        Case "frmLogin"
            With frmLogin
            If iPopupPosition > 0 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With

        Case "frmMenuHelp"
            With frmMenuHelp
            If iPopupPosition > 0 Then
                .Left = 2375
            Else
                .Left = 1120
            End If
                .Top = 103
                .Show
            End With

        Case "frmChangePassword"
            With frmChangePassword
            If iPopupPosition > 0 Then
                .Left = 2165
            Else
                .Left = 910
            End If
                .Top = 103
                .Show
            End With


        Case "frmCadUser"
            With frmCadUser
            If iPopupPosition > 0 Then
                .Left = 2065
            Else
                .Left = 810
            End If
                .Top = 103
                .Show
            End With

        Case "frmAbout"
            With frmAbout
            If iPopupPosition > 0 Then
                .Left = 1680
            Else
                .Left = 450
            End If
                .Top = 400
                .Show
            End With



        Case "frm_Executelift"
'        If bCanCMD = True Then
            With frm_Execute
                     frm_Execute.Caption = "Lift"
                     .Left = iPopupPositionl - 10
                     .Top = iPopupPositiont - 10
                     .Show
                 End With

        Case "frm_Execute"

            With frm_Execute
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10

'                    If iPopupPositionl > 1000 Then
'                        iPopupPositionl = iPopupPosition - 100
'                    End If
                .Show

            End With

        Case "frm_cmd_ene_circuitbreaker"
        'open form only with communication
        With frm_cmd_ene_circuitbreaker
    '       .Caption = "Circuit Breaker - " & powerCBname
            .Caption = "   " & powerCBname
            .Left = iPopupPositionl - 10
            .Top = iPopupPositiont - 10
         .Show
        End With

        Case "frm_cmd_circuitbreaker_comment"
        'open form only with communication
        With frm_cmd_circuitbreaker_comment
        If iPopupPositionl > 1100 Then iPopupPositionl = (iPopupPositionl - 30)
          .Caption = "   " & powerCBname
            .Left = iPopupPositionl - 10
            .Top = iPopupPositiont - 10
         .Show
        End With




         Case "frm_cmdbc_esp_circuitb_comm"
            With frm_cmdbc_esp_circuitb_comm
    '                .Caption = "Circuit Breaker - " & powerCBname
                .Caption = "   " & powerCBname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

         Case "frm_cmd_esp_circuitbreaker"
            With frm_cmd_esp_circuitbreaker
    '                .Caption = "Circuit Breaker - " & powerCBname
                .Caption = "   " & powerCBname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

         Case "frm_cmd_ene_disj"
           With frm_cmd_ene_disj
'                .Caption = "DC Line Bypass - " & powerDJname
                .Caption = "  " & powerDJname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

         Case "frm_cmd_ene_disj_con_desc"
           With frm_cmd_ene_disj_con_desc
'                .Caption = "DC Line Bypass - " & powerDJname
                .Caption = "  " & powerDJname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With



         Case "frm_cmd_ene_line_feeder"
            With frm_cmd_ene_line_feeder
'                .Caption = "DC Feeder - " & powerDCname
                .Caption = "   " & powerDCname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

            Case "frm_cmd_ene_line_feeder_comm"
            With frm_cmd_ene_line_feeder_comm
'                .Caption = "DC Feeder - " & powerDCname
                .Caption = "   " & powerDCname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With



         Case "frm_cmd_ene_esp_line_feeder"
            With frm_cmd_ene_esp_line_feeder
'                .Caption = "DC Feeder - " & powerDCname
                .Caption = "   " & powerDCname
               .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

         Case "frm_cmd_ene_reticf"
            With frm_cmd_ene_reticf
'                .Caption = "Isolator - " & powerISname
                .Caption = "   " & powerISname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

        Case "frm_cmd_disj_earth"
            With frm_cmdbc_ene_disj_earth
'                .Caption = "Isolator - " & powerISname
                .Caption = "   " & powerISname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

        Case "frm_cmd_fac_light"
         With frm_cmd_fac_light
              .Left = iPopupPositionl - 10
              .Top = iPopupPositiont - 10
              .Show
         End With

        Case "frm_cmdbc_ene_circuitbreaker"
            With frm_cmdbc_ene_circuitbreaker
'                .Caption = "Circuit Breaker - " & powerCBname
                .Caption = "   " & powerCBname
                If iPopupPositionl > 1100 Then iPopupPositionl = (iPopupPositionl - 30)
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

        Case "frm_cmdbc_esp_circuitbreaker"
            With frm_cmdbc_esp_circuitbreaker

'                .Caption = "Circuit Breaker - " & powerCBname
                .Caption = "   " & powerCBname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

        Case "frm_cmdbc_ene_disj"
           With frm_cmdbc_ene_disj
'                .Caption = "DC Line Bypass - " & powerDJname
            .Caption = "   " & powerDJname
            .Left = iPopupPositionl - 10
            .Top = iPopupPositiont - 10
            .Show
            End With

        Case "frm_cmdbc_ene_disj_con_disc"
           With frm_cmdbc_ene_disj_con_disc
'                .Caption = "DC Line Bypass - " & powerDJname
            .Caption = "   " & powerDJname
            .Left = iPopupPositionl - 10
            .Top = iPopupPositiont - 10
            .Show
            End With

        Case "frm_cmdbc_ene_line_feeder"
            With frm_cmdbc_ene_line_feeder
'                .Caption = "DC Feeder - " & powerDCname
                .Caption = "   " & powerDCname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With
         Case "frm_cmdbc_ene_esp_line_feeder"
            With frm_cmdbc_ene_esp_line_feeder
'                .Caption = "DC Feeder - " & powerDCname
                .Caption = "   " & powerDCname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

        Case "frm_cmdbc_ene_reticf"
            With frm_cmdbc_ene_reticf
'           .Caption = "Isolator - " & powerISname
            .Caption = "   " & powerISname
            If iPopupPositionl > 1100 Then iPopupPositionl = (iPopupPositionl - 30)
            .Left = iPopupPositionl - 10
            .Top = iPopupPositiont - 10
            .Show
            End With
        Case "frm_Section_Isolator"
            With frm_Section_Isolator
'                .Caption = "Section Isolator - " & powerSIname
                .Caption = "   " & powerSIname
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With

        Case "frm_cmd_lift"
            With frm_cmd_lift
                .Left = iPopupPositionl - 10
                .Top = iPopupPositiont - 10
                .Show
            End With


        Case "frmMsgImediata"
            With frmMsgImediata
            If iPopupPosition > 0 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With

        Case "frmprinters"
            With frmPrinters
            If iPopupPosition > 0 Then
                .Left = 1780
            Else
                .Left = 500
            End If
                .Top = 400
                .Show
            End With

        Case "frm_gua_cmd_escalera"
         With frm_gua_cmd_escalera
                .Left = 500
                .Top = 400
                .Show
            End With

    End Select


    iPopupPosition = 0

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "mmodMain", "OpenForms", Err.Description)

End Function

Public Function CloseForms()
'FAO Mayo 2016: Comentamos esta parte, pues no tiene ningún sentido hacer un Unload de un formulario que no usamos
'    On Error Resume Next
'
'    Unload frmCMD
End Function

Public Function change_layer_7_GTE()
    On Error Resume Next
    
    MimicName = ActiveMimic.FileName
    ThisProject.Mimics.Item(MimicName).Windows(1).Layers = ThisProject.Mimics.Item(MimicName).Windows(1).Layers Xor 128
End Function

Public Function change_layer_11()
    On Error Resume Next
    
    MimicName = ActiveMimic.FileName
    ThisProject.Mimics.Item(MimicName).Windows(1).Layers = ThisProject.Mimics.Item(MimicName).Windows(1).Layers Xor 2048
End Function

Public Function MsgImediata(strMsg1 As String, strMsg2 As String, strMsg3 As String) As VbMsgBoxResult
    strMsgImediata1 = strMsg1
    strMsgImediata2 = strMsg2
    strMsgImediata3 = strMsg3
    sMsgHIHI1_Atual = strMsg1
    iPopupPosition = ThisProject.ActiveMimic.Windows(1).Left
        
    If frmMsgImediata.Visible = True Then
        Exit Function
    Else
        With frmMsgImediata
        If iPopupPosition > 0 Then
            .Left = 1920
        Else
            .Left = 335
        End If
            .Top = 400
            .Show
        End With
    
        MsgImediata = vbModalAnswer
    End If
End Function

Public Function GetCurrentHMI() As String
    On Error Resume Next
    Dim TextLine As String
    Open ThisProject.Path & "\install.log" For Input As #1   ' Open file.
    Do While Not EOF(1)    ' Loop until end of file.
        Line Input #1, TextLine    ' Read line into variable.
        If TextLine Like "*HMI_Oran_PBK*" Then
            GetCurrentHMI = "Playback"
        Else
            GetCurrentHMI = "HMI"
        End If
    Loop
    Close #1    ' Close file.
End Function

'v2.2 FAO Marzo 2016    'Funcion que recibe un nombre de fichero y una ruta: devuelve True si el fichero existe en esa ruta; False en caso contrario

Public Function FileExists(sFPathFile As String) As Boolean
    
    If Len(Dir(sFPathFile)) <> 0 Then   'Si "Dir" no devuelve cadena vacía (longitud 0), es que existe dicho fichero
        FileExists = True
    Else                            'En caso contrario, el fichero no existe en el directorio
        FileExists = False
    End If
    
End Function

'v2.2 FAO Marzo 2016    'Funcion que lee un fichero de texto plano, que contiene en cada línea el nombre de cada clase que no tiene flavor MODE, y que debemos de tratar de
'forma diferente para saber si hemos de desplegar menú de mando o no

Public Function getClasesSinMode() As String
    On Error Resume Next
    Dim TextLine As String
    Dim I As Integer    'Indice del array
    If FileExists(ThisProject.Path & "\Config Files" & "\ListaClasesSinMode.txt") Then             'Si existe el fichero que ha de leerse...
        Open ThisProject.Path & "\Config Files" & "\ListaClasesSinMode.txt" For Input As #1      'Abre el fichero con la lista de clases que no tienen flavor mode
        I = 0
        Do While Not EOF(1)    ' Continuar hastafin de fichero
            Line Input #1, sListaClasesSinMode(I)    'Leemos el contenido de la línea y lo almacenamos en Array publico para acceder desde el resto del proyecto
            I = I + 1           'Incrementamos el indice del array
        Loop
        Close #1    ' Close file.
    Else
        MsgBox "No existe el fichero de Lista de Clases sin Mode", vbOKOnly
        
        'Mostramos mensaje de error
    End If
    
End Function

'v2.2 FAO Marzo 2016    'Funcion que recibe como parámetros el nombre de una clase y el array donde almacenamos las clases que no tienen flavor MODE, y nos devuelve True
'si dicha clase no tiene ese flavor

Public Function NoTieneMode(NombreClase As String, sListaClasesSinMode() As String) As Boolean
    Dim I As Integer
    
    NoTieneMode = False                                             'Inicializamos función a False
    I = 0
    Do While I < UBound(sListaClasesSinMode)                        'Vamos a recorrer el array
        If UCase(NombreClase) = UCase(sListaClasesSinMode(I)) Then  'Si encontramos la clase del objeto en la lista, es que no tiene mode
            NoTieneMode = True                                      'Asignamos valor a la funcion
            Exit Do                                                 'Salimosdel bucle
        End If
        I = I + 1                                                   'Sino, incrementamos índice y seguimos buscando
    Loop
    
End Function
'v2.3 FAO Marzo 2016: Al abrir un mimic de GTE o tercer nivel de GTC,creamos los tags necesarios para lanzar los mandos sobre los elementos
Public Sub CreaTagsMandos(sNombreMimic As String, sNombreSimboloMando As String)
On Error Resume Next
Dim I As Integer
Dim iPosArrayMimics As Integer
Dim sNombreFicheroObjeto As String

For I = 1 To ThisProject.Mimics.Count                                   'Buscamos el mimic actual en el array de mimics del proyecto
    If UCase(ThisProject.Mimics(I).Name) = UCase(sNombreMimic) Then
        iPosArrayMimics = I
    End If
Next

'Texto de pruebas para controlar que las variables se añaden
Debug.Print ("Numero de variables antes de crear las nuevas: " & Variables.Count)
With ThisProject.Mimics(iPosArrayMimics)                                'Recorremos en el mimic el array de objetos, buscando los que sean de mandos sobre elementos GTE
    For I = 1 To .Graphics.Count
        
        sNombreFicheroObjeto = UCase(.Graphics(I).FileName)             'Controlamos el error si el objetono admite esta propiedad, para que no se detenga el código
        If Err.Number > 2 Then                                          'Si se produce un error
            Err.Clear                                                   'Lo borramos
            GoTo continuar                                              'Pasamos a la siguiente iteración (objeto)
        Else
            'PARA MANDOS DE GTE
            If UCase(sNombreFicheroObjeto) = "SYB_CMD_GTE" Then                'Cuando encontramos un objeto de mando de GTE...
                sBranch = .Graphics(I).LocalBranch                          'Leeemos su branch
                'Añadimos variables a la colección
                Variables.Add sBranch & ".Template.iCommand", fvVariableTypeRegister                'Sólo es necesario crear los tags para iCommand, Name y AreaName
                Variables.Add sBranch & ".Template.Name", fvVariableTypeText
                Variables.Add sBranch & ".StateAlarmEventFilter.AlarmEventFilter.AreaName", fvVariableTypeText
            Else
                'PARA MANDOS DE INHIBICION DE GTC
                If UCase(sNombreFicheroObjeto) = "SYB_CMD_GTC_3NIVEAU" Then     'Cuando encontramos un símbolo de tercer nivel de GTC...
                    sBranch = .Graphics(I).LocalBranch                          'Leeemos su branch
                    Variables.Add sBranch & ".Inhibited", fvVariableTypeText    'Añadimos variables a la colección. Sólo es necesario crear el tags para Inhibited (inhibición de alarmas)
                    Variables.Add sBranch & ".Inhibited.AreaName", fvVariableTypeText   'Añadimos esta variable para mostrar, en el caption del formulario, el área y no el objeto (más "amigable" para el operador)
                End If
            End If
        End If
continuar:
    Next

End With

'Texto de pruebas para controlar que las variables se añaden
Debug.Print ("Numero de variables después de crear las nuevas: " & Variables.Count)

'For i = 1 To Variables.Count
'Debug.Print i; ": "; Variables.Item(i).Name; ""
'Next i

End Sub
'v2.3 FAO Marzo 2016:Al cerrar un mimic de GTE,borramos los tags necesarios para lanzar los mandos sobre los elementos que se han creado al abrirlo
Public Sub BorrarTagsMandos(sNombreMimic As String, sNombreSimboloMando As String)
On Error Resume Next
Dim I As Integer
Dim NumVariables As Integer
Dim iPosArrayMimics As Integer
Dim sNombreFicheroObjeto As String


'Texto de pruebas para controlar que las variables se añaden
Debug.Print ("Numero de variables antes de borrar las creadas anteriormente: " & Variables.Count)

For I = 1 To ThisProject.Mimics.Count                                   'Buscamos el mimic actual en el array de mimics del proyecto
    If UCase(ThisProject.Mimics(I).Name) = UCase(sNombreMimic) Then
        iPosArrayMimics = I
    End If
Next


With ThisProject.Mimics(iPosArrayMimics)                                'Recorremos en el mimic el array de objetos, buscando los que sean de mandos sobre elementos GTE
    For I = 1 To .Graphics.Count
        
        sNombreFicheroObjeto = UCase(.Graphics(I).FileName)             'Controlamos el error si el objetono admite esta propiedad, para que no se detenga el código
        If Err.Number > 2 Then                                          'Si se produce un error
            Err.Clear                                                   'Lo borramos
            GoTo continuar                                              'Pasamos a la siguiente iteración (objeto)
        Else
            If UCase(sNombreFicheroObjeto) = "SYB_CMD_GTE" Then         'Cuando encontramos un objeto de mando GTE...
                sBranch = .Graphics(I).LocalBranch                          'Leeemos su branch
                Variables.Remove (sBranch & ".Template.iCommand")           'Sólo borramos los dos tags que hemos creado de forma manual
                Variables.Remove (sBranch & ".Template.Name")
                Variables.Remove (sBranch & ".StateAlarmEventFilter.AlarmEventFilter.AreaName")
            Else
                If UCase(sNombreFicheroObjeto) = "SYB_CMD_GTC_3NIVEAU" Then  'Cuando encontramos un objeto de mando GTC tercer nivel
                    sBranch = .Graphics(I).LocalBranch                          'Leeemos su branch
                    Variables.Remove (sBranch & ".Inhibited")                   'Borramos los tags que hemos creado de forma manual
                    Variables.Remove (sBranch & ".Inhibited.AreaName")
                End If
            End If
        End If
continuar:
    Next
End With

'Texto de pruebas para controlar que las variables se añaden
Debug.Print ("Numero de variables después de borrar las creadas anteriormente: " & Variables.Count)


'For i = 1 To Variables.Count
'Debug.Print i; ": "; Variables.Item(i).Name; ""
'Next i

End Sub


Public Function Printer_Button(sType As String)

    On Error Resume Next
'    sProfile = ThisProject.Security.Users.GetProfiles(ThisProject.Security.UserName)
'    [txtUsuario%] = ThisProject.Security.UserName & "/" & sProfile(0)
    If ((sType = "PwrMainEng/Supervisor") Or sType = ("iconis/MaintenanceEngineer") Or (sType = "Usuario1/Supervisor")) Or (sType = "iconis/Administrator") Then
    Variables.Item("@Printer%").Value = True
    Else
    Variables.Item("@Printer%").Value = False
    End If
    
End Function


' Returns the next cyclic PEN colors from the given list of colors
Public Function GetPenColor(I As Integer) As Long

    Dim OLEColors(0 To 6) As Long
    OLEColors(0) = vbWhite
    OLEColors(1) = vbGreen
    OLEColors(2) = vbRed
    OLEColors(3) = vbBlue
    OLEColors(4) = vbYellow
    OLEColors(5) = vbMagenta
    OLEColors(6) = vbCyan

    Dim r As Integer: r = I Mod UBound(OLEColors)
    GetPenColor = OLEColors(r)

End Function

'* Return true if the trend contains the maximum number of pens allowed
 Public Function HasReachedMaximumPens(theTrend As TREND, mp As Integer) As Boolean
    HasReachedMaximumPens = (theTrend.PenSet.Count >= mp)
End Function


'* Return true if at least 1 item in the listbox is selected
Public Function IsListBoxSelected(theListBox As ListBox) As Boolean
    Dim b As Boolean: b = False
    Dim I As Integer
    For I = 0 To theListBox.ListCount - 1
        b = b Or theListBox.Selected(I)
    Next
    IsListBoxSelected = b
End Function



Public Sub DisplayEquipmentDescription(theListBox As ListBox, theTextBox As TextBox)
    If (theListBox.ListCount > 0) Then
        theListBox.Selected(theListBox.ListCount - 1) = True
        theTextBox.Text = General.GetEquipmentDescription(theListBox.List(theListBox.ListCount - 1))
    Else
        theTextBox.Text = ""
    End If
End Sub


'Load the given listbox with the pen names in the given Trend
Public Sub LoadPenNamesToListBox(theTrend As TREND, theListBox As ListBox)
On Error GoTo Error
Call CBTrace(CBTRACE_VBA, "MOD_General", "LoadPenNamesToListBox", "Begin Sub")

    Dim I As Integer
    Do While theListBox.ListCount > 0
        theListBox.RemoveItem (theListBox.ListCount - 1)
    Loop
    
    For I = INT_IDXLISTBOX_IDXPENLIST_OFFSET To theTrend.PenSet.Count
        theListBox.AddItem theTrend.PenSet.Item(I).Name
    Next
    
    If (theListBox.ListCount > 0) Then
        theListBox.Selected(0) = True
    Else
    End If
    
    Exit Sub
Error:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "LoadPenNamesToListBox", Err.Description)
End Sub


'* Add the selected Pen to the given trend and update the listbox content
'* Returns an empty string if good, else return a string that describes an error
Public Function Add_DataSource_Pen(theEQP As Scripting.Dictionary, theTrend As TREND, theListBox As ListBox, maxPens As Integer) As String
On Error GoTo Error

    Call CBTrace(CBTRACE_VBA, "MOD_General", "Add_DataSource_Pen", "Begin function")
    
    Dim strMsg As String: strMsg = ""
    
    ' The selected equipment
    Dim strName As String: strName = theEQP.Item(ATR_NAME)
    Dim lgnPlotMin As Long: lgnPlotMin = CLng(theEQP.Item(ATR_PLOTMIN))
    Dim lgnPlotMax As Long: lgnPlotMax = CLng(theEQP.Item(ATR_PLOTMAX))
    Dim strDisplayName As String: strDisplayName = theEQP.Item(ATR_DISPLAYNAME)
    Dim strDescription As String: strDescription = theEQP.Item(ATR_DESCRIPTION)
    
    ' Check if the number of pens has reached the limit
    Dim numberOfPens As Integer: numberOfPens = theTrend.PenSet.Count
    
    If (HasReachedMaximumPens(theTrend, maxPens)) Then
        strMsg = STR_TRENDTXT_PENS_EXCEEDED
    Else
        ' Check if the variable is already in the pen list
        Dim alreadyInTrend As Boolean: alreadyInTrend = False
        Dim I As Integer
        For I = 1 To numberOfPens
            If (theTrend.PenSet.Item(I).Name = strDisplayName) Then
                alreadyInTrend = True
            End If
        Next
        If (alreadyInTrend) Then
            strMsg = STR_TRENDTXT_EQP_EXIST
        Else
            '' Good now, start to add the new pen to the trend viewer
            Dim pcl As Long: pcl = GetPenColor(theTrend.PenSet.Count)
            theTrend.PenSet.Add strDisplayName, pcl
            
            theTrend.PenSet(theTrend.PenSet.Count).YAxis.LineColor = pcl
            theTrend.PenSet(theTrend.PenSet.Count).ShowXAxis = False
            theTrend.PenSet(theTrend.PenSet.Count).AutoYScale = False
            theTrend.PenSet(theTrend.PenSet.Count).PlotMax = lgnPlotMax
            theTrend.PenSet(theTrend.PenSet.Count).PlotMin = lgnPlotMin
            theTrend.PenSet(theTrend.PenSet.Count).AutoYScale = False
            
            theTrend.PenSet(theTrend.PenSet.Count).DeltaTLen = 0
            theTrend.PenSet(theTrend.PenSet.Count).NoCalcBrushStyle = 5
            theTrend.PenSet(theTrend.PenSet.Count).NoCalcLineColor = pcl
            theTrend.PenSet(theTrend.PenSet.Count).NoCalcLineStyle = 1
            theTrend.PenSet(theTrend.PenSet.Count).PointColor = pcl
            theTrend.PenSet(theTrend.PenSet.Count).RealTime = True
            theTrend.PenSet(theTrend.PenSet.Count).RTKeepAllPoints = True
            
            Dim strdatasourceName As String
            strdatasourceName = GetDataSourceSuffix
            strdatasourceName = strdatasourceName & strName
            strdatasourceName = strdatasourceName & "(Value)"
            theTrend.PenSet(theTrend.PenSet.Count).DataSourceName = strdatasourceName
            theTrend.PenSet(theTrend.PenSet.Count).AttachToDataSource
                        
            strMsg = STR_TRENDTXT_EQP_ADDED_OK
            theTrend.Refresh
            theTrend.TurnOnRealtime
            
            ''theListBox.ListIndex = -1
            LoadPenNamesToListBox theTrend, theListBox

            
        End If
    End If
    
    Add_DataSource_Pen = strMsg
    Exit Function
    
Error:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "Add_DataSource_Pen", Err.Description)
    strMsg = STR_TRENDTXT_EQP_ADDED_ERROR
    Add_DataSource_Pen = strMsg
    Exit Function
    
End Function


'* Remove the selected Pen
Public Function Remove_DataSource_Pen(theTrend As TREND, theListBox As ListBox) As String
On Error GoTo Error
    Call CBTrace(CBTRACE_VBA, "MOD_General", "Remove_DataSource_Pen", "Begin function")
    
    Dim I As Integer
    Dim p As Integer
    
    I = theListBox.ListCount - 1
    Dim strName As String
    Do While (I > -1)
        If (theListBox.Selected(I)) Then 'Remove the selected pens
            '* Pen index is listbox index + Offset because we don't show the X-Axis pen
            p = I + INT_IDXLISTBOX_IDXPENLIST_OFFSET
            strName = theTrend.PenSet(p).Name
            theTrend.PenSet.Remove theTrend.PenSet(p).Name
            
            '* Removing the description
            If (NameDes Is Nothing) Then
                Set NameDes = New Scripting.Dictionary
            End If
            If (NameDes.Exists(strName)) Then
                NameDes.Remove strName
            End If
            
        End If
        I = I - 1
    Loop
    
    theTrend.Refresh
    
    LoadPenNamesToListBox theTrend, theListBox
    
    Exit Function
    
Error:
Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "Remove_DataSource_Pen", Err.Description)
    Exit Function
    
End Function


'* Return a user-friendly description of the given equipment variable
Public Function GetEquipmentDescription(strEqpName As String) As String
On Error GoTo Error
    Call CBTrace(CBTRACE_VBA, "MOD_General", "GetEquipmentDescription", "Begin function")
    
    Dim strResult As String: strResult = ""
    
    '* Load the XML document object if it has not been loaded
    If (General.TrendXMLDoc Is Nothing) Then
        Set TrendXMLDoc = New MSXML2.DOMDocument
        TrendXMLDoc.Load (ThisProject.Path & STR_TREND_XMLFILE)
    End If
    
    Dim node As IXMLDOMNode
    Dim StrQuery As String: StrQuery = "//Equipment[@DISPLAYNAME = '" & strEqpName & "']"
    Set node = TrendXMLDoc.selectSingleNode(StrQuery)
    If (Not node Is Nothing) Then
        strResult = node.Attributes.getNamedItem(ATR_DESCRIPTION).Text
    End If

    GetEquipmentDescription = strResult
    Exit Function
    
Error:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetEquipmentDescription", Err.Description)
    GetEquipmentDescription = ""
    
End Function


Public Sub InitFilterVariables(ByVal sType As String)
    
    Select Case sType
    
    Case "ALM"
    
        MyAppliedFilters_ALM.sLabel = ""
        MyAppliedFilters_ALM.sState = ""
        MyAppliedFilters_ALM.sSeverity = ""
        MyAppliedFilters_ALM.sTimeOfActivation = ""
        MyAppliedFilters_ALM.sGroup = ""
        MyAppliedFilters_ALM.sName = ""
        
        MyAppliedFiltersDisplay_ALM.sLabel = ""
        MyAppliedFiltersDisplay_ALM.sState = ""
        MyAppliedFiltersDisplay_ALM.sSeverity = ""
        MyAppliedFiltersDisplay_ALM.sInitDate = "__/__/__"
        MyAppliedFiltersDisplay_ALM.sEndDate = "__/__/__"
        MyAppliedFiltersDisplay_ALM.sInitTime = "__:__:__"
        MyAppliedFiltersDisplay_ALM.sEndTime = "__:__:__"
        MyAppliedFiltersDisplay_ALM.sEquipment = ""
        MyAppliedFiltersDisplay_ALM.sStation = ""
        MyAppliedFiltersDisplay_ALM.sZone = ""
        MyAppliedFiltersDisplay_ALM.sName = ""
    
    Case "EVT"
            
        MyAppliedFilters_EVT.sLabel = ""
        MyAppliedFilters_EVT.sSeverity = ">= 100"
        MyAppliedFilters_EVT.sTimeOfActivation = ""
        MyAppliedFilters_EVT.sGroup = ""
        
        MyAppliedFiltersDisplay_EVT.sLabel = ""
        MyAppliedFiltersDisplay_EVT.sSeverity = ""
        MyAppliedFiltersDisplay_EVT.sInitDate = "__/__/__"
        MyAppliedFiltersDisplay_EVT.sEndDate = "__/__/__"
        MyAppliedFiltersDisplay_EVT.sInitTime = "__:__:__"
        MyAppliedFiltersDisplay_EVT.sEndTime = "__:__:__"
        MyAppliedFiltersDisplay_EVT.sEquipment = ""
        MyAppliedFiltersDisplay_EVT.sStation = ""
        MyAppliedFiltersDisplay_EVT.sZone = ""
    
    Case "PTL"
        MyAppliedFilters_PTL.sLabel = ""
        MyAppliedFilters_PTL.sSeverity = ">= 100"
        MyAppliedFilters_PTL.sTimeOfActivation = ""
        MyAppliedFilters_PTL.sGroup = ""
        
        MyAppliedFiltersDisplay_PTL.sLabel = ""
        MyAppliedFiltersDisplay_PTL.sSeverity = ""
        MyAppliedFiltersDisplay_PTL.sInitDate = "__/__/__"
        MyAppliedFiltersDisplay_PTL.sEndDate = "__/__/__"
        MyAppliedFiltersDisplay_PTL.sInitTime = "__:__:__"
        MyAppliedFiltersDisplay_PTL.sEndTime = "__:__:__"
        MyAppliedFiltersDisplay_PTL.sEquipment = ""
        MyAppliedFiltersDisplay_PTL.sStation = ""
        MyAppliedFiltersDisplay_PTL.sZone = ""

    Case "OP"
        MyAppliedFilters_OP.sLabel = ""
        MyAppliedFilters_OP.sSeverity = ">= 100"
        MyAppliedFilters_OP.sTimeOfActivation = ""
        MyAppliedFilters_OP.sGroup = ""
        MyAppliedFilters_OP.sOperator = ""
        
        MyAppliedFiltersDisplay_OP.sLabel = ""
        MyAppliedFiltersDisplay_OP.sSeverity = ""
        MyAppliedFiltersDisplay_OP.sInitDate = "__/__/__"
        MyAppliedFiltersDisplay_OP.sEndDate = "__/__/__"
        MyAppliedFiltersDisplay_OP.sInitTime = "__:__:__"
        MyAppliedFiltersDisplay_OP.sEndTime = "__:__:__"
        MyAppliedFiltersDisplay_OP.sEquipment = ""
        MyAppliedFiltersDisplay_OP.sStation = ""
        MyAppliedFiltersDisplay_OP.sOperator = ""
        MyAppliedFiltersDisplay_OP.sZone = ""
    Case Else
    
        MyAppliedFilters_ALM.sLabel = ""
        MyAppliedFilters_ALM.sState = ""
        MyAppliedFilters_ALM.sSeverity = ""
        MyAppliedFilters_ALM.sTimeOfActivation = ""
        MyAppliedFilters_ALM.sGroup = ""
        MyAppliedFilters_ALM.sName = ""
        
        MyAppliedFiltersDisplay_ALM.sLabel = ""
        MyAppliedFiltersDisplay_ALM.sState = ""
        MyAppliedFiltersDisplay_ALM.sSeverity = ""
        MyAppliedFiltersDisplay_ALM.sInitDate = "__/__/__"
        MyAppliedFiltersDisplay_ALM.sEndDate = "__/__/__"
        MyAppliedFiltersDisplay_ALM.sInitTime = "__:__:__"
        MyAppliedFiltersDisplay_ALM.sEndTime = "__:__:__"
        MyAppliedFiltersDisplay_ALM.sEquipment = ""
        MyAppliedFiltersDisplay_ALM.sStation = ""
        MyAppliedFiltersDisplay_ALM.sZone = ""
        MyAppliedFiltersDisplay_ALM.sName = ""
        
        MyAppliedFilters_EVT.sLabel = ""
        MyAppliedFilters_EVT.sSeverity = ">= 100"
        MyAppliedFilters_EVT.sTimeOfActivation = ""
        MyAppliedFilters_EVT.sGroup = ""
        
        MyAppliedFiltersDisplay_EVT.sLabel = ""
        MyAppliedFiltersDisplay_EVT.sSeverity = ""
        MyAppliedFiltersDisplay_EVT.sInitDate = "__/__/__"
        MyAppliedFiltersDisplay_EVT.sEndDate = "__/__/__"
        MyAppliedFiltersDisplay_EVT.sInitTime = "__:__:__"
        MyAppliedFiltersDisplay_EVT.sEndTime = "__:__:__"
        MyAppliedFiltersDisplay_EVT.sEquipment = ""
        MyAppliedFiltersDisplay_EVT.sStation = ""
        MyAppliedFiltersDisplay_EVT.sZone = ""
        
        MyAppliedFilters_PTL.sLabel = ""
        MyAppliedFilters_PTL.sSeverity = ">= 100"
        MyAppliedFilters_PTL.sTimeOfActivation = ""
        MyAppliedFilters_PTL.sGroup = ""
        
        MyAppliedFiltersDisplay_PTL.sLabel = ""
        MyAppliedFiltersDisplay_PTL.sSeverity = ""
        MyAppliedFiltersDisplay_PTL.sInitDate = "__/__/__"
        MyAppliedFiltersDisplay_PTL.sEndDate = "__/__/__"
        MyAppliedFiltersDisplay_PTL.sInitTime = "__:__:__"
        MyAppliedFiltersDisplay_PTL.sEndTime = "__:__:__"
        MyAppliedFiltersDisplay_PTL.sEquipment = ""
        MyAppliedFiltersDisplay_PTL.sStation = ""
        MyAppliedFiltersDisplay_PTL.sZone = ""

        MyAppliedFilters_OP.sLabel = ""
        MyAppliedFilters_OP.sSeverity = ">= 100"
        MyAppliedFilters_OP.sTimeOfActivation = ""
        MyAppliedFilters_OP.sGroup = ""
        MyAppliedFilters_OP.sOperator = ""
        
        MyAppliedFiltersDisplay_OP.sLabel = ""
        MyAppliedFiltersDisplay_OP.sSeverity = ""
        MyAppliedFiltersDisplay_OP.sInitDate = "__/__/__"
        MyAppliedFiltersDisplay_OP.sEndDate = "__/__/__"
        MyAppliedFiltersDisplay_OP.sInitTime = "__:__:__"
        MyAppliedFiltersDisplay_OP.sEndTime = "__:__:__"
        MyAppliedFiltersDisplay_OP.sEquipment = ""
        MyAppliedFiltersDisplay_OP.sStation = ""
        MyAppliedFiltersDisplay_OP.sOperator = ""
        MyAppliedFiltersDisplay_OP.sZone = ""

    End Select

End Sub

Public Function GetTrendSuffix() As String
    ''Trend screens
    Select Case Variables.Item("opccluster:IconisS2K.Core.ServerState.Core.ServerState.Core.ServerID").Value
    'Case "TCC_SRV_TEN_1"
    Case "CTRSRVSCD1"
        GetTrendSuffix = "SRV_1"
    ''Case "TCC_SRV_TEN_2"
    Case "CTRSRVSCD2"
        GetTrendSuffix = "SRV_2"
    End Select
End Function

Public Function GetDataSourceSuffix() As String
''S2KTrend_SRV2\S2KVTQ_VTQTimeView\MEXICO_L12.SCADA.
    Select Case Variables.Item("opccluster:IconisS2K.Core.ServerState.Core.ServerState.Core.ServerID").Value
    'Case "TCC_SRV_TEN_1"
    Case "CTRSRVSCD1"
        'GetDataSourceSuffix = "S2KTrend_SRV1\S2KVTQ_VTQTimeView\SCADA_L3.SCADA_1."
        GetDataSourceSuffix = "S2KTrend_SRV1\S2KVTQ_VTQTimeView\GDL3.SCADA_1."
    'Case "TCC_SRV_TEN_2"
    Case "CTRSRVSCD2"
        'GetDataSourceSuffix = "S2KTrend_SRV2\S2KVTQ_VTQTimeView\SCADA_L3.SCADA_1."
        GetDataSourceSuffix = "S2KTrend_SRV2\S2KVTQ_VTQTimeView\GDL3.SCADA_1."
    End Select
End Function

Public Sub OpenCloseTrendMimics(ByVal sServerOff As String, sServerOn As String)
On Error GoTo Error:

    Dim objMimic As Mimic
    For Each objMimic In Application.ActiveProject.Mimics
        If (objMimic.FileName Like "GDL_Historico_*_" & sServerOff) Then
            Mimics.Item(objMimic.index).Close fvDoNotSaveChanges
            Mimics.Open Replace(objMimic.FileName, sServerOff, sServerOn)
            Exit For
        End If
    Next
    
    Exit Sub
Error:
Call CBTrace(CBTRACEF_ALWAYS, "General", "CloseAllMyMimics", Err.Description)
        
End Sub


Public Sub Language()
 If ThisProject.ProjectLanguage = "ENU" Then
        ThisProject.SetProjectLanguage ("ESM")
    End If
End Sub

