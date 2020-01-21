Attribute VB_Name = "MOD_SP_Funcoes"
Option Explicit

Public xmlHeadway As IXMLDOMElement

Dim arrDestRoutes As Variant
Dim I As Integer
Dim sDestName As String, sRouteName As String
Dim strCommand As String

Private Declare Function GetTickCount Lib "kernel32" () As Long

Public Declare Function FindWindowA Lib "user32" (ByVal lpClassName As String, ByVal lpWindowName As String) As Long
Public Declare Function FindWindowEx Lib "user32" Alias "FindWindowsExA" (ByVal hWnd1 As Long, ByVal hWnd2 As Long, _
                                                ByVal hlpsz1 As String, ByVal hlpsz2 As String) As Long
Public Declare Function GetWindowLongA Lib "user32" (ByVal hWnd As Long, ByVal nIndex As Long) As Long
Public Declare Function SetWindowLongA Lib "user32" (ByVal hWnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long

Const PRINTER_ENUM_CONNECTIONS = &H4
Const PRINTER_ENUM_LOCAL = &H2

Private Declare Function EnumPrinters Lib "winspool.drv" Alias "EnumPrintersA" _
                                      (ByVal flags As Long, ByVal Name As String, ByVal Level As Long, _
                                       pPrinterEnum As Long, ByVal cdBuf As Long, pcbNeeded As Long, _
                                       pcReturned As Long) As Long

Private Declare Function PtrToStr Lib "kernel32" Alias "lstrcpyA" _
                                  (ByVal RetVal As String, ByVal Ptr As Long) As Long

Private Declare Function StrLen Lib "kernel32" Alias "lstrlenA" _
                                (ByVal Ptr As Long) As Long

Public arrList_CDVs() As Variant
Public arrList_Trains() As Variant

Public arrList_Stations() As String
Public arrList_Equipaments() As String

Public Enum eTypeCommand
    isNone = 0
    isNext = 1
    isPrevious = 2
End Enum

'Type used to keep the mouvement associated to the loop
Public Type Mvt
    InitialManeuverId       As String
    PatternId               As String
End Type

Public Type ServiceLoops
    Id                      As String
    Mvts                    As String
    MvtList()               As Mvt
End Type


' Constants used to manage Line Operating Mode
' ------------------------------------------------------
Public Const c_strMode As String = "NextMode"
Public Const c_strModeIndex As String = "Index"
Public Const c_strModeName As String = "Name"

'Operating Mode
Public Const c_strNextLineOperatingModesListTag    As String = ".ModeMgmt.NextOperatingModesList"
Public Const c_strCurrentOperatingModeTag          As String = ".ModeMgmt.ModeVal"
Public Const c_strCmdOperModeCarouselConfigMode    As String = "MainUO.CarouselsConfiguration.Mode"
Public Const c_strCarouselConfOperatingModeList    As String = "MainUO.CarouselsConfiguration.NextOperatingModesList"
Public Const c_strCmdOperModeTPBMgrConfig          As String = "MainUO.TPBModule.TPBMgr.Configuration"
Public Const c_strCmdOperModeMgmtMode              As String = ".ModeMgmt.Mode"
Public Const c_strCmdAutoWithTTRegulation          As String = "MainKernelExtended.ATRModule.ATRTPMA.AtrExtendedStrategy"
'TT
Public Const c_strChargedTTName                    As String = "MainKernelExtended.TTCModule.DBLoader.TimetableName"

Public m_OPC_CmdOperModeCarouselConfigMode  As Variable
Public m_OPC_CarouselConfOperatingModeList  As Variable
Public m_OPC_CmdOperModeTPBMgrConfig        As Variable
Public m_OPC_CmdOperModeMgmtMode            As Variable
Public m_OPC_CmdAutoWithTTRegulation        As Variable




Public Function ListPrinters() As Variant

    Dim bSuccess As Boolean
    Dim iBufferRequired As Long
    Dim iBufferSize As Long
    Dim iBuffer() As Long
    Dim iEntries As Long
    Dim iIndex As Long
    Dim strPrinterName As String
    Dim iDummy As Long
    Dim iDriverBuffer() As Long
    Dim StrPrinters() As String

    iBufferSize = 3072

    ReDim iBuffer((iBufferSize \ 4) - 1) As Long

    'A função EnumPrinters retornará falso casa a fila de impressão estiver muito cheia
    bSuccess = EnumPrinters(PRINTER_ENUM_CONNECTIONS Or _
                            PRINTER_ENUM_LOCAL, vbNullString, _
                            1, iBuffer(0), iBufferSize, iBufferRequired, iEntries)

    If Not bSuccess Then
        If iBufferRequired > iBufferSize Then
            iBufferSize = iBufferRequired
            Debug.Print "iBuffer too small. Trying again with "; _
                        iBufferSize & " bytes."
            ReDim iBuffer(iBufferSize \ 4) As Long
        End If

        'Tentar chamar a função novamente
        bSuccess = EnumPrinters(PRINTER_ENUM_CONNECTIONS Or _
                                PRINTER_ENUM_LOCAL, vbNullString, _
                                1, iBuffer(0), iBufferSize, iBufferRequired, iEntries)
    End If

    If Not bSuccess Then
        'Mostra mensagem em caso de erro na chamada da EnumPrinters
        MsgBox "Error enumerating printers."
        Exit Function
    Else
        'Caso EnumPrinters retorne True, preenche o array com as impressoras
        ReDim StrPrinters(iEntries - 1)
        For iIndex = 0 To iEntries - 1
            'Pega o nome da impressora
            strPrinterName = Space$(StrLen(iBuffer(iIndex * 4 + 2)))
            iDummy = PtrToStr(strPrinterName, iBuffer(iIndex * 4 + 2))
            StrPrinters(iIndex) = strPrinterName
        Next iIndex
    End If

    ListPrinters = StrPrinters

End Function

Public Function IsBounded(vArray As Variant) As Boolean
    'Se a variável passada é um array, retorna True, do contrário, False
    On Error Resume Next
    IsBounded = IsNumeric(UBound(vArray))
End Function

Public Function Read_List_CDVs()
    On Error Resume Next

    Dim I As Integer, InputData As String
    I = 0
    
    Open ThisProject.Path & "\Working Files\CDV_List.txt" For Input As #1    ' Open file for input.
    ReDim arrList_CDVs(0) As Variant
    Do While Not EOF(1)                 'Check for end of file.
        ReDim Preserve arrList_CDVs(I)
        Line Input #1, InputData        'Read line of data.
        If InputData <> "" Then arrList_CDVs(I) = InputData          'Print to the Immediate window.
        I = I + 1
    Loop
    Close #1    'Close file.
    
    'Adicionar variaveis para o VirtualTrain se já não estiverem adicionadas
    For I = 0 To UBound(arrList_CDVs)
        If Variables("OPCCluster:" & arrList_CDVs(I) & ".VirtualTrain.Value") Is Nothing Then _
            Variables.Add "OPCCluster:" & arrList_CDVs(I) & ".VirtualTrain.Value", fvVariableTypeText
        If Variables("OPCCluster:" & arrList_CDVs(I) & ".VirtualTrainStatus.Value") Is Nothing Then _
            Variables.Add "OPCCluster:" & arrList_CDVs(I) & ".VirtualTrainStatus.Value", fvVariableTypeRegister
        If Variables("OPCCluster:" & arrList_CDVs(I) & ".VirtualTrainComment.Value") Is Nothing Then _
            Variables.Add "OPCCluster:" & arrList_CDVs(I) & ".VirtualTrainComment.Value", fvVariableTypeText
    Next I
    
End Function

Public Function Read_List_Trains()
    On Error Resume Next

    Dim I As Integer, InputData As String
    I = 0
    
    Open ThisProject.Path & "\Working Files\Train_List.txt" For Input As #1    ' Open file for input.
    ReDim arrList_Trains(0) As Variant
    Do While Not EOF(1)                 'Check for end of file.
        ReDim Preserve arrList_Trains(I)
        Line Input #1, InputData        'Read line of data.
        If InputData <> "" Then arrList_Trains(I) = InputData          'Print to the Immediate window.
        I = I + 1
    Loop
    Close #1    'Close file.
    
    SortArray arrList_Trains
    
End Function


Public Function OpenMimicCommand(sMimicName As String, sBranch As String, iMimicWidht As Integer, iMimicHeight As Integer, Optional bCentralized As Boolean)
    Dim ActiveCoord As POINTAPI
    Dim iLeft As Integer, iTop As Integer, iMonitor As Integer
    
    On Error GoTo ErrorHandler
    
    If sMimicName = "" Then Exit Function
    
    'get the current cursor location
    GetCursorPos ActiveCoord
'    If LeftWorkspace > 0 Then iMonitor = 1
'    iMonitor = Int(ActiveCoord.lXpos / c_lScreenWidth) - iMonitor
    iMonitor = Int((ActiveCoord.lXpos - LeftWorkspace) / c_lScreenWidth)
    
    If bCentralized Then
        iLeft = c_lScreenWidth * iMonitor + (c_lScreenWidth / 2 - iMimicWidht / 2)
        iTop = c_lScreenHeight / 2 - iMimicHeight / 2
    Else
        iTop = ActiveCoord.lYpos + 7
        If iTop > (c_lScreenHeight - iMimicHeight) Then iTop = (c_lScreenHeight - iMimicHeight - 10)
        If ActiveCoord.lXpos > (iLeft + c_lScreenWidth - iMimicWidht) Then
            iLeft = (iLeft + c_lScreenWidth - iMimicWidht - 10)
        Else
            iLeft = ActiveCoord.lXpos
        End If
    End If
    
    Mimics.Open sMimicName, sBranch, , , , , , , iLeft, iTop, True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "OpenMimicCommand", Err.Description)

End Function

Public Function UpdateTrainList()
    Dim I As Integer
    
    On Error GoTo ErrorHandler

    If Not IsBounded(arrList_CDVs) Then Read_List_CDVs
    [sCDVUsedTrainIDList%] = ""
'    Variables("OPCCluster:IconisHMI.TrainsList.Value").Value = ""
    For I = 0 To UBound(arrList_CDVs)
        If Variables("OPCCluster:" & arrList_CDVs(I) & ".VirtualTrain.Value") <> "" And InStr(1, [sCDVUsedTrainIDList%], arrList_CDVs(I) & ";", vbTextCompare) = 0 Then _
            [sCDVUsedTrainIDList%] = [sCDVUsedTrainIDList%] & Variables("OPCCluster:" & arrList_CDVs(I) & ".VirtualTrain.Value").Value & "," & arrList_CDVs(I) & ";"
'        If (Variables("OPCCluster:" & arrList_CDVs(i) & ".VirtualTrain.Value").Value <> "") And (InStr(1, Variables("OPCCluster:IconisHMI.TrainsList.Value").Value, arrList_CDVs(i) & ",", vbTextCompare) = 0) Then
'            Variables("OPCCluster:IconisHMI.TrainsList.Value").Value = Variables("OPCCluster:IconisHMI.TrainsList.Value").Value & arrList_CDVs(i) & "," & Variables("OPCCluster:" & arrList_CDVs(i) & ".VirtualTrain.Value") & ";"
'        End If
    Next I
Debug.Print "UpdateTrainList - " & Now

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "UpdateTrainList", Err.Description)
    
End Function

Public Function SortArray(ByRef mArray As Variant)
    On Error GoTo ErrorHandler
    
    Dim Sorted As Boolean, iItem As Integer, Temp As Variant
    
    Sorted = False
    Do While Not Sorted
        Sorted = True
        For iItem = 0 To UBound(mArray) - 1
            If mArray(iItem) > mArray(iItem + 1) Then
                Temp = mArray(iItem + 1)
                mArray(iItem + 1) = mArray(iItem)
                mArray(iItem) = Temp
                Sorted = False
            End If
        Next iItem
    Loop
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "SortArray", Err.Description)

End Function


Public Function AddVarRouteCancelation(ByVal sCDV As String)
    Dim xmlDoc As DOMDocument
    Dim FirstNodeLevel As IXMLDOMNodeList
    Dim oElementClass As IXMLDOMElement
    Dim sQuery As String, sRouteName As String
    
    Dim sAux As String

    On Error GoTo ErrorHandler
    sCDV = Replace(sCDV, "@", "")
    If Variables(sCDV & ".Destinations.Value.bstrValue").Value = "" Then Exit Function

    sAux = Variables(sCDV & ".Destinations.Value.bstrValue").Value

'''    'Aguardar nova base
'''    sAux = "<RouteOrigin Name=""TC Name"" ID="""
'''    sAux = sAux & "" & Replace(sCDV, "OPCCluster:", "") & """>"
'''    sAux = sAux & Variables(sCDV & ".Destinations.Value.bstrValue").Value & "</RouteOrigin>"

    Set xmlDoc = New DOMDocument
    xmlDoc.loadXML sAux

    sCDV = Replace(sCDV, "opccluster:", "", , , vbTextCompare)
    sQuery = "//RouteOrigin[@ID=" & Chr(34) & sCDV & Chr(34) & "]/TrackSections/TrackSection"
    Set oElementClass = xmlDoc.selectSingleNode(sQuery)
    sRouteName = oElementClass.getAttribute("CancelRouteID")

    If Variables("OPCCluster:" & sRouteName & ".HMI.Template.iCommand") Is Nothing Then _
        Variables.Add "OPCCluster:" & sRouteName & ".HMI.Template.iCommand", fvVariableTypeRegister


    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "AddVarRouteCancelation", Err.Description)

End Function


Public Function GetRouteCancelation(ByVal sCDV As String) As String
    Dim xmlDoc As DOMDocument
    Dim FirstNodeLevel As IXMLDOMNodeList
    Dim oElementClass As IXMLDOMElement
    Dim sQuery As String, sRouteName As String, sAux As String
    
    On Error GoTo ErrorHandler
    
    sCDV = Replace(sCDV, "@", "")
    
    If Variables(sCDV & ".Destinations.Value.bstrValue").Value = "" Then Exit Function
    
    sAux = Variables(sCDV & ".Destinations.Value.bstrValue").Value

'''    'Aguardar nova base
'''    sAux = "<RouteOrigin Name=""TC Name"" ID="""
'''    sAux = sAux & "" & Replace(sCDV, "OPCCluster:", "") & """>"
'''    sAux = sAux & Variables(sCDV & ".Destinations.Value.bstrValue").Value & "</RouteOrigin>"

    Set xmlDoc = New DOMDocument
    xmlDoc.loadXML sAux
    
    sCDV = Replace(sCDV, "opccluster:", "", , , vbTextCompare)
    sQuery = "//RouteOrigin[@ID=" & Chr(34) & sCDV & Chr(34) & "]/TrackSections/TrackSection"
    Set oElementClass = xmlDoc.selectSingleNode(sQuery)
    GetRouteCancelation = oElementClass.getAttribute("CancelRouteID")
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "GetRouteCancelation", Err.Description)

End Function

Public Function RouteSetting(ByVal sCDV As String)
    Dim xmlDoc As DOMDocument
    Dim FirstNodeLevel As IXMLDOMNodeList
    Dim oElementClass As IXMLDOMElement
    Dim sQuery As String, sRouteName As String
    
    On Error GoTo ErrorHandler
    
    If [RotaEmAndamento%] = "" Then Exit Function
    
    Set xmlDoc = New DOMDocument
    xmlDoc.loadXML [RotaEmAndamento%]
    sCDV = Replace(sCDV, "@", "")
    sCDV = Replace(sCDV, "opccluster:", "", , , vbTextCompare)
    sQuery = "//RouteOrigin/TrackSections/TrackSection[@ID=" & Chr(34) & sCDV & Chr(34) & "]"
    Set oElementClass = xmlDoc.selectSingleNode(sQuery)
    sRouteName = oElementClass.getAttribute("RouteID")
    
    Variables("OPCCluster:" & sRouteName & ".Detection.Template.iCommand").Value = 1
    
    RouteCleanDestinations
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "RouteSetting", Err.Description)
    
End Function

Public Function RouteCleanDestinations()
    Dim xmlDoc              As DOMDocument
    Dim FirstNodeLevel      As IXMLDOMNodeList
    Dim oElementClass       As IXMLDOMElement
    Dim sOrigem As String, sDestName As String, sCancelRouteID As String
    
    On Error GoTo ErrorHandler
        
    If [RotaEmAndamento%] = "" Then Exit Function
    
    ThisProject.TIMER_RouteReset.Enabled = False
    
    Set xmlDoc = New DOMDocument
    xmlDoc.loadXML [RotaEmAndamento%]
    sOrigem = xmlDoc.firstChild.Attributes(1).Text
    
    Set FirstNodeLevel = xmlDoc.documentElement.getElementsByTagName("TrackSection")
    
    'Set destinations
    For Each oElementClass In FirstNodeLevel
        sDestName = oElementClass.getAttribute("ID")
''        sCancelRouteID = oElementClass.getAttribute("CancelRouteID")
        'Limpa sinal de destino
        Variables("OPCCluster:" & sDestName & ".Destino%").Value = False
        
        'Remove variavel de rota se já está adicionada
        If Not Variables("OPCCluster:" & sRouteName & ".Detection.Template.iCommand") Is Nothing Then _
            Variables.Remove "OPCCluster:" & sRouteName & ".Detection.Template.iCommand"
        If Not Variables("OPCCluster:" & sRouteName & ".Detection.Template.iEqpState") Is Nothing Then _
            Variables.Remove "OPCCluster:" & sRouteName & ".Detection.Template.iEqpState"
''        If Not Variables("OPCCluster:" & sCancelRouteID & ".HMI.Template.iCommand") Is Nothing Then _
''            Variables.Remove "OPCCluster:" & sCancelRouteID & ".HMI.Template.iCommand"
    
    Next oElementClass
       
    Variables(sOrigem & ".ButtonActivated%").Value = False

    [RotaEmAndamento%] = ""


    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "RouteCleanDestinations", Err.Description)

End Function

Public Function RoutePreparation(ByVal sOrigem As String)
    Dim xmlDoc              As DOMDocument
    Dim FirstNodeLevel      As IXMLDOMNodeList
    Dim oElementClass       As IXMLDOMElement
    Dim sRouteName As String, sDestName As String, sCancelRouteID As String
    Dim bDisableRoute As Boolean
    
    'On Error GoTo ErrorHandler
    
    On Error Resume Next
    
    If Not (Variables(sOrigem & ".Detection.Template.Security").Value < 63 And [@UserAccessCommand%]) Then Exit Function
    If Variables(sOrigem & ".Destinations.Value.bstrValue").Value = "" Then Exit Function
    
    'Verifica se CDV está em Zona Escura > "bit mask (0x0200: Dark zone = 512)"
    If (Variables.Item(sOrigem & ".Detection.TCTracker.iState").Value And 512) Then Exit Function
    
    If [RotaEmAndamento%] <> "" Then RouteCleanDestinations
    [RotaEmAndamento%] = Variables(sOrigem & ".Destinations.Value.bstrValue").Value
    
'''    'Aguardar nova base
'''    [RotaEmAndamento%] = "<RouteOrigin Name=""TC Name"" ID="""
'''    [RotaEmAndamento%] = [RotaEmAndamento%] & "" & Replace(sOrigem, "OPCCluster:", "") & """>"
'''    [RotaEmAndamento%] = [RotaEmAndamento%] & Variables(sOrigem & ".Destinations.Value.bstrValue").Value & "</RouteOrigin>"

    Set xmlDoc = New DOMDocument
    xmlDoc.loadXML [RotaEmAndamento%]

    Set FirstNodeLevel = xmlDoc.documentElement.getElementsByTagName("TrackSection")

    'Set destinations
    For Each oElementClass In FirstNodeLevel
        sDestName = oElementClass.getAttribute("ID")
        sRouteName = oElementClass.getAttribute("RouteID")
''        sCancelRouteID = oElementClass.getAttribute("CancelRouteID")
        
        'Desabilitar rota se sianal BS estiver diferente de reconhecido
        'BS 14: 14->45 (BA_PMO_14.POS.Template.iEqpState <> 2)
        'BS ZA: ZA->48 (BA_CNV_ZA)
        'BS ZB: ZB->45 e ZB->58 (BA_PMO_ZB1)
        
        If InStr(sOrigem, "CDV_CNV_14_CNV") > 0 And InStr(sDestName, "CDV_PMO_45_PMO") > 0 Then
            If TestVariable(Variables("OPCCluster:BA_PMO_14.POS.Template.iEqpState")) Then
                bDisableRoute = Variables("OPCCluster:BA_PMO_14.POS.Template.iEqpState").Value <> 2
                Exit Function
            End If
        ElseIf InStr(sOrigem, "CDV_CNV_Z_CNV") > 0 And InStr(sDestName, "CDV_PMO_48_PMO") > 0 Then
            If TestVariable(Variables("OPCCluster:BA_CNV_ZA.POS.Template.iEqpState")) Then _
                bDisableRoute = Variables("OPCCluster:BA_CNV_ZA.POS.Template.iEqpState").Value <> 2
        ElseIf InStr(sOrigem, "CDV_CNV_Z_CNV") > 0 And (InStr(sDestName, "CDV_PMO_45_PMO") > 0 Or InStr(sDestName, "CDV_PMO_58_PMO") > 0) Then
            If TestVariable(Variables("OPCCluster:BA_PMO_ZB1.POS.Template.iEqpState")) Then _
                bDisableRoute = Variables("OPCCluster:BA_PMO_ZB1.POS.Template.iEqpState").Value <> 2
        End If
        
        If Not bDisableRoute Then
            'Pisca sinal de destino
            Variables("OPCCluster:" & sDestName & ".Destino%").Value = True
            
            'Adiciona variavle de rota se já não estã adicionada
            If Variables("OPCCluster:" & sRouteName & ".Detection.Template.iCommand") Is Nothing Then _
                Variables.Add "OPCCluster:" & sRouteName & ".Detection.Template.iCommand", fvVariableTypeRegister
            If Variables("OPCCluster:" & sRouteName & ".Detection.Template.iEqpState") Is Nothing Then _
                Variables.Add "OPCCluster:" & sRouteName & ".Detection.Template.iEqpState", fvVariableTypeRegister
    ''        If Variables("OPCCluster:" & sCancelRouteID & ".HMI.Template.iEqpState") Is Nothing Then _
    ''            Variables.Add "OPCCluster:" & sCancelRouteID & ".HMI.Template.iEqpState", fvVariableTypeRegister
        End If
    Next oElementClass
    
    Variables(sOrigem & ".ButtonActivated%").Value = True

    ThisProject.TIMER_RouteReset.Enabled = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "RoutePreparation", Err.Description)

End Function

Public Function RouteCancelation(ByVal sCDV As String, ByVal iValue As Integer)
    Dim xmlDoc As DOMDocument
    Dim FirstNodeLevel As IXMLDOMNodeList
    Dim oElementClass As IXMLDOMElement
    Dim sQuery As String, sRouteName As String
    
    On Error GoTo ErrorHandler
    
    sCDV = Replace(sCDV, "@", "")

    If Variables(sCDV & ".Destinations.Value.bstrValue").Value = "" Then Exit Function
    
    [RotaEmAndamento%] = Variables(sCDV & ".Destinations.Value.bstrValue").Value

'''    'Aguardar nova base
'''    [RotaEmAndamento%] = "<RouteOrigin Name=""TC Name"" ID="""
'''    [RotaEmAndamento%] = [RotaEmAndamento%] & "" & Replace(sCDV, "OPCCluster:", "") & """>"
'''    [RotaEmAndamento%] = [RotaEmAndamento%] & Variables(sCDV & ".Destinations.Value.bstrValue").Value & "</RouteOrigin>"
        
    Set xmlDoc = New DOMDocument
    xmlDoc.loadXML [RotaEmAndamento%]
    
    sCDV = Replace(sCDV, "opccluster:", "", , , vbTextCompare)
    sQuery = "//RouteOrigin[@ID=" & Chr(34) & sCDV & Chr(34) & "]/TrackSections/TrackSection"
    Set oElementClass = xmlDoc.selectSingleNode(sQuery)
    sRouteName = oElementClass.getAttribute("CancelRouteID")
    
    Variables("OPCCluster:" & sRouteName & ".HMI.Template.iCommand").Value = iValue

    RouteCleanDestinations

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "RouteCancelation", Err.Description)

End Function


'*  Function: CloseAllMimics
'* Closes all the currently opened mimics
'* ***************************************************************************************
Public Function CloseAllMimics()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "ModMain", "CloseAllMimics", "Begin Function")
    
    Dim objMimic As Mimic
    For Each objMimic In Application.ActiveProject.Mimics
        If InStr(objMimic.FileName, "_INICIAL") = 0 Then objMimic.Close fvDoNotSaveChanges
    Next
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "CloseAllMimics", Err.Description)
End Function



Public Function ActivateInspectorPanel(ByRef mmcActive As Mimic)
    Dim sParentMimic As String
    
    sParentMimic = Replace(mmcActive.FileName, "_Control", "")
    Mimics(sParentMimic, mmcActive.Branch).Activate

End Function


Public Function OpenMenu(sMenuName As String, objSymbol As Symbol)
    Dim ActiveCoord As POINTAPI
    Dim iCount As Integer, iLeft As Integer, iTop As Integer, iMonitor As Integer
    Dim sBranch As String, sTrainOPCName As String
    
    On Error GoTo ErrorHandler

    If ActiveMimic.FileName Like "TrainIndicator_List" Then
        iLeft = objSymbol.Left + ActiveMimic.Windows(1).Left
    Else
    
        'get the current cursor location
        Call GetCursorPos(ActiveCoord)
    
'        If LeftWorkspace > 0 Then iMonitor = 1
        iMonitor = Int(ActiveCoord.lXpos / c_lScreenWidth) - iMonitor
'        iMonitor = Int((ActiveCoord.lXpos - LeftWorkspace) / c_lScreenWidth)
    
        iLeft = objSymbol.Left + (iMonitor * c_lScreenWidth) + (ActiveMimic.Windows(1).Left)
        If iLeft < (iMonitor * c_lScreenWidth) Then iLeft = (iMonitor * c_lScreenWidth) + 5
    End If
    
    iTop = objSymbol.Top + objSymbol.Height + ActiveMimic.Windows(1).Top
    
    'close all contextual menus
    For iCount = 1 To ThisProject.Mimics.Count
        If InStr(ThisProject.Mimics.Item(iCount).FileName, "_ContextualMenu") > 0 Then
            ThisProject.Mimics.Item(iCount).Close fvDoNotSaveChanges
        End If
    Next iCount

    sBranch = objSymbol.LocalBranch
'''    [sBerthTag%] = sBranch
''''''    If InStr(1, sBranch, "TCB_", vbTextCompare) > 0 And InStr(1, sBranch, "HMITrain1", vbTextCompare) = 0 Then sBranch = sBranch & ".HMITrain1"
'''
'''    'Se for o berth, abrir a tela com o tag do Trem
'''    If InStr(1, sBranch, "TCB_", vbTextCompare) > 0 Then
'''        sTrainOPCName = GetHMITrainOPCName(Variables(sBranch & ".HMITrain1.TDS.iTrainID").Value, Variables(sBranch & ".HMITrain1.TDS.bstrHMITrainID").Value)
'''        If sTrainOPCName = "" Then Exit Function
'''        sBranch = "OPCCluster:@" & sTrainOPCName
'''        AddTrainVariables sBranch
'''    End If

'    Mimics.Open sMenuName, objSymbol.LocalBranch, , , , , , , ActiveCoord.lXpos, ActiveCoord.lYpos, True
    Mimics.Open sMenuName, sBranch, , , , , , , iLeft, iTop, True
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "OpenMenu", Err.Description)
    
  End Function

'''Public Function OpenForms(sFormName As String, Optional bNotCentralize As Boolean)
'''    Dim sCaption As String
'''    Dim ActiveCoord As POINTAPI
'''    Dim iLeft As Integer, iTop As Integer
'''    Dim iMonitor As Integer
'''
'''    On Error GoTo ErrorHandler
'''
'''    'get the current cursor location
'''    Call GetCursorPos(ActiveCoord)
'''
''''    iMonitor = Int(ActiveCoord.lXpos / c_lScreenWidth)
'''    iMonitor = Int((ActiveCoord.lXpos - LeftWorkspace) / c_lScreenWidth)
'''
'''    If bNotCentralize Then
'''        iTop = ActiveCoord.lYpos * 0.753
'''        iLeft = (ActiveCoord.lXpos - LeftWorkspace) * 0.753
'''    Else
'''        iLeft = ((c_lScreenWidth * iMonitor + LeftWorkspace) * 0.753) + (c_lScreenWidth * 0.753) / 2
'''        iTop = c_lScreenHeight / 2 * 0.753
'''    End If
'''
'''    If InStr(sFormName, ":") > 0 Then
'''        iFormMsgQuestion = Split(sFormName, ":")(1)
'''        sFormName = Split(sFormName, ":")(0)
'''    End If
'''
'''    Select Case sFormName
'''
'''        Case "frmMsgQuestion"
'''            With frmMsgQuestion
''''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''''                .Top = Int(iTop * 0.753 - (.Height / 2))
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
'''
'''        Case "frmMsgExclamation"
'''            With frmMsgExclamation
''''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''''                .Top = Int(iTop * 0.753 - (.Height / 2))
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
'''        Case "frmLogin"
'''            With frmLogin
''''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''''                .Top = Int(iTop * 0.753 - (.Height / 2))
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
''''        Case "frmMenuHelp"
''''            With frmMenuHelp
''''            If iPopupPosition > 0 Then
''''                .Left = 2375
''''            Else
''''                .Left = 1120
''''            End If
''''                .Top = 103
''''                .Show
''''            End With
'''
'''        Case "frmChangePassword"
'''            With frmChangePassword
''''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''''                .Top = Int(iTop * 0.753 - (.Height / 2))
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
'''
'''        Case "frmCadUser"
'''            With frmCadUser
''''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''''                .Top = Int(iTop * 0.753 - (.Height / 2))
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
'''        Case "frm_Executelift"
'''
'''            With frm_Execute
'''                frm_Execute.Caption = "Lift"
'''                If iPopupPositionl > (iLeft + c_lScreenWidth) * 0.753 - .Width Then iPopupPositionl = (iLeft + c_lScreenWidth) * 0.753 - .Width
'''                .Left = iPopupPositionl - 10
'''                If iPopupPositiont > c_lScreenHeight * 0.753 - .Height Then iPopupPositiont = c_lScreenHeight * 0.753 - .Height
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''        Case "frm_Execute"
'''
'''            With frm_Execute
'''                If iPopupPositionl > (iLeft + c_lScreenWidth) * 0.753 - .Width Then iPopupPositionl = (iLeft + c_lScreenWidth) * 0.753 - .Width
'''                .Left = iPopupPositionl - 10
'''                If iPopupPositiont > c_lScreenHeight * 0.753 - .Height Then iPopupPositiont = c_lScreenHeight * 0.753 - .Height
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''
'''        Case "frm_cmd_ene_circuitbreaker"
'''            With frm_cmd_ene_circuitbreaker
'''                .Caption = "Circuit Breaker - " & powerCBname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''        Case "frm_cmd_esp_circuitbreaker"
'''            With frm_cmd_esp_circuitbreaker
'''                .Caption = "Circuit Breaker - " & powerCBname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''
'''            End With
'''
'''         Case "frm_cmd_ene_disj"
'''            With frm_cmd_ene_disj
'''                .Caption = "DC Line Bypass - " & powerDJname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''
'''         Case "frm_cmd_ene_line_feeder"
'''            With frm_cmd_ene_line_feeder
'''                .Caption = "DC Feeder - " & powerDCname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''
'''         Case "frm_cmd_ene_esp_line_feeder"
'''            With frm_cmd_ene_esp_line_feeder
'''                .Caption = "DC Feeder - " & powerDCname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''
'''         Case "frm_cmd_ene_reticf"
'''            With frm_cmd_ene_reticf
'''                .Caption = "Isolator - " & powerISname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''          Case "frm_cmd_fac_light"
'''            With frm_cmd_fac_light
'''
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''
'''        Case "frm_cmdbc_ene_circuitbreaker"
'''            With frm_cmdbc_ene_circuitbreaker
'''                .Caption = "Circuit Breaker - " & powerCBname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''        Case "frm_cmdbc_esp_circuitbreaker"
'''            With frm_cmdbc_esp_circuitbreaker
'''                .Caption = "Circuit Breaker - " & powerCBname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''
'''            End With
'''
'''         Case "frm_cmdbc_ene_disj"
'''            With frm_cmdbc_ene_disj
'''                .Caption = "DC Line Bypass - " & powerDJname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''
'''         Case "frm_cmdbc_ene_line_feeder"
'''            With frm_cmdbc_ene_line_feeder
'''                .Caption = "DC Feeder - " & powerDCname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''
'''         Case "frm_cmdbc_ene_esp_line_feeder"
'''            With frm_cmdbc_ene_esp_line_feeder
'''                .Caption = "DC Feeder - " & powerDCname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''
'''         Case "frm_cmdbc_ene_reticf"
'''            With frm_cmdbc_ene_reticf
'''                .Caption = "Isolator - " & powerISname
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''          Case "frm_cmd_lift"
'''            With frm_cmd_lift
'''
'''                .Left = iPopupPositionl - 10
'''                .Top = iPopupPositiont - 10
'''                .Show
'''
'''            End With
'''
'''
'''        Case "frm_cmd_reset"
'''
'''
'''            With frm_cmd_reset
'''
'''                .Left = iPopupPositionl - 10
'''
'''                    If iPopupPositiont < 680 Then
'''
'''                        .Top = iPopupPositiont - 10
'''
'''                    Else
'''
'''                        .Top = 680
'''                    End If
'''                .Show
'''
'''            End With
'''
'''
'''        Case "frmMsgImediata"
''''            With frmMsgImediata
''''                .Left = Int(iLeft - (.Width / 2)) * 0.753
''''                .Top = Int(iTop - (.Height / 2)) * 0.753
''''                .Show
''''            End With
'''
'''        Case "frmprinters"
'''            With frmPrinters
''''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''''                .Top = Int(iTop * 0.753 - (.Height / 2))
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
'''        Case "frmTAS"
'''            'Para abrir próximo ao botão de comando
''''            With frmTAS
''''                If iLeft > (c_lScreenWidth * iMonitor) * 0.753 - .Width Then iLeft = (c_lScreenWidth * iMonitor) * 0.753 - .Width - 10
''''                If iTop > c_lScreenHeight * 0.753 - .Height Then iTop = c_lScreenHeight * 0.753 - .Height - 10
''''                .Left = iLeft
''''                .Top = iTop
''''                .Show
''''            End With
'''
'''            'Para abrir centralizado na tela
'''            With frmTAS
''''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''''                .Top = Int(iTop * 0.753 - (.Height / 2))
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
'''        Case "frmInibeCMDs"
'''            'Para abrir centralizado na tela
'''            With frmInibeCMDs
''''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''''                .Top = Int(iTop * 0.753 - (.Height / 2))
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
'''        Case "frmAPGeral"
'''            'Para abrir centralizado na tela
'''            With frmAPGeral
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
'''        Case "frmPO"
'''            'Para abrir centralizado na tela
'''            With frmPO
''''                .Left = Int(iLeft * 0.753 - (.Width / 2))
''''                .Top = Int(iTop * 0.753 - (.Height / 2))
'''                .Top = Int(iTop - (.Height / 2))
'''                .Left = Int(iLeft - (.Width / 2))
'''                .Show
'''            End With
'''
'''
'''    End Select
'''
'''
'''    iPopupPosition = 0
'''
'''    Exit Function
'''ErrorHandler:
'''    Call CBTrace(CBTRACEF_ALWAYS, "ModMain", "OpenForms", Err.Description)
'''
'''  End Function


Public Function OpenInspPanel(Optional ByRef mmcMenu As Mimic, Optional ByRef sybSymbol As Symbol)
    Dim ActiveCoord As POINTAPI
    Dim iCount As Integer
    Dim sMimicInspPanel As String
    Dim sBranch As String, iLeft As Integer, iTop As Integer
    Dim iMonitor As Integer, sPML As String
    Dim sTrainOPCName As String

    On Error GoTo ErrorHandler

    If InStr(ThisProject.ProjectName, "_PML") > 0 Then sPML = "_PML"
    If Not mmcMenu Is Nothing Then
        sMimicInspPanel = Split(mmcMenu.FileName, "_")(0) & "_InspectorPanel" & sPML
        sBranch = mmcMenu.Branch
        iLeft = mmcMenu.Windows(1).Left
        iTop = mmcMenu.Windows(1).Top
    ElseIf sybSymbol Is Nothing Or sybSymbol.LocalBranch = "" Then
        Exit Function
    Else
        If TestVariable(Variables.Item(sybSymbol.LocalBranch & ".POS.Template.Security")) Then _
            If Variables.Item(sybSymbol.LocalBranch & ".POS.Template.Security").Value = 63 Then Exit Function
        
        If InStr(sybSymbol.LocalBranch, "Train") > 0 Then
            sMimicInspPanel = "TCB_InspectorPanel"
        ElseIf InStr(sybSymbol.LocalBranch, "Stop_STA") > 0 Then
            sMimicInspPanel = "PLAT_InspectorPanel"
        ElseIf InStr(sybSymbol.LocalBranch, "DVO_") > 0 Then
            sMimicInspPanel = "DV_InspectorPanel"
        ElseIf InStr(sybSymbol.LocalBranch, "_SCT") > 0 Then
            sMimicInspPanel = "SCT_InspectorPanel"
'            Rafaela 18-3-2016
        ElseIf InStr(sybSymbol.LocalBranch, "SVO_") > 0 Then
            sMimicInspPanel = "SV_InspectorPanel"
        Else
            sMimicInspPanel = Split(sybSymbol.LocalBranch, "_")(0) & "_InspectorPanel" & sPML
        End If
        sMimicInspPanel = Replace(sMimicInspPanel, "OPCCluster:", "", , , vbTextCompare)
        sMimicInspPanel = Replace(sMimicInspPanel, "@", "")
        sBranch = sybSymbol.LocalBranch
                
        If ActiveMimic.FileName Like "TrainIndicator_List" Then
            iLeft = sybSymbol.Left + ActiveMimic.Windows(1).Left
        Else
                
            'get the current cursor location
            Call GetCursorPos(ActiveCoord)
                    
'            If LeftWorkspace > 0 Then iMonitor = 1
'
'            iMonitor = Int(ActiveCoord.lXpos / c_lScreenWidth) - iMonitor
            iMonitor = Int((ActiveCoord.lXpos - LeftWorkspace) / c_lScreenWidth)
    
    '        iLeft = sybSymbol.Left + (iMonitor * c_lScreenWidth) - (Abs(ActiveMimic.Windows(1).Left))
            iLeft = sybSymbol.Left + (iMonitor * c_lScreenWidth) + (ActiveMimic.Windows(1).Left)
            If iLeft < (iMonitor * c_lScreenWidth) Then iLeft = (iMonitor * c_lScreenWidth) + 5
     '       iLeft = ActiveCoord.lXpos
        End If
        iTop = sybSymbol.Top + sybSymbol.Height + ActiveMimic.Windows(1).Top
    End If
    
    If sMimicInspPanel = "" Then Exit Function

    'close all inspector panel of the same equipment type
    For iCount = 1 To ThisProject.Mimics.Count
        If (InStr(ThisProject.Mimics.Item(iCount).FileName, sMimicInspPanel) > 0 And ThisProject.Mimics.Item(iCount).FileName <> sBranch) _
          Or (InStr(ThisProject.Mimics.Item(iCount).FileName, "_ContextualMenu") > 0) Then
            ThisProject.Mimics.Item(iCount).Close fvDoNotSaveChanges
        End If
    Next iCount

'    If InStr(1, sBranch, "TCB_", vbTextCompare) > 0 And InStr(1, sBranch, "HMITrain1", vbTextCompare) = 0 Then sBranch = sBranch & ".HMITrain1"
    'Se for o berth, abrir a tela com o tag do Trem
    If InStr(1, sBranch, "TCB_", vbTextCompare) > 0 Then
        [sBerthTag%] = sBranch
        sTrainOPCName = GetHMITrainOPCName(Variables(sBranch & ".HMITrain1.TDS.iTrainID").Value, Variables(sBranch & ".HMITrain1.TDS.bstrHMITrainID").Value)
        If sTrainOPCName = "" Then Exit Function
        sBranch = "OPCCluster:" & sTrainOPCName
        AddTrainVariables sBranch
    End If

    If InStr(sBranch, "NRE_") > 0 And InStr(sBranch, ".POS") = 0 Then sBranch = sBranch & ".POS"

    Mimics.Open sMimicInspPanel, sBranch, , , , , , , iLeft, iTop, True
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "OpenInspPanel", Err.Description)
    
  End Function


Public Function LogonExecute(ByVal sUser As String, sPass As String)
    Dim sPMLOper As String
    Dim I As Integer
    Dim sLine As String

    If ThisProject.LogonUser(False, sUser, sPass) Then
    
        'Force to change passaword in the first access
        While ThisProject.Security.users.GetChangePassword(ThisProject.Security.UserName) = 1
            ModMain.Alterasenha
        Wend
   
'''        Variables("opccluster:TERRITORIO_SCO_L4.TAS.AssignToOperator").Value = ThisProject.UserName
        
        If InStr(ThisProject.ProjectName, "FEP") > 0 Then
            'Iniciar SSCT de acordo com a Linha
            sLine = Right(ThisProject.ProjectName, 1)
            If sLine = 4 Then sLine = sLine & "P"
            
            I = 4
            While I > 0
                Mimics.Open "MBL4_SSCTT_OPER_L" & sLine, "M" & I, , , , , , , c_lScreenWidth * (I - 1), 0, True
                I = I - 1
            Wend
            
            For I = 1 To 4
                Mimics.Item("MBL4_SSCTT_INICIAL", I).Close
            Next I
        
        ElseIf InStr(ThisProject.ProjectName, "SSCTT") > 0 Then
            'Iniciar SSCT de acordo com a Linha
            If InStr([Machine_Name%], "PCTL4") > 0 Then
                sLine = "4P"
            ElseIf InStr([Machine_Name%], "PCTL2") > 0 Then
                sLine = "2"
            Else
                sLine = "1"
            End If
            
            I = 4
            While I > 0
                Mimics.Open "MBL4_SSCTT_OPER_L" & sLine, "M" & I, , , , , , , c_lScreenWidth * (I - 1), 0, True
                I = I - 1
            Wend
            
            For I = 1 To 4
                Mimics.Item("MBL4_SSCTT_INICIAL", I).Close
            Next I
            
            
        ElseIf InStr(ThisProject.ProjectName, "PML_") > 0 Then
            'Iniciar PMLs
            If InStr(ThisProject.ProjectName, "PML_BDC") > 0 Then
                sPMLOper = "MBL4_PML_OPER_GOS2"
            Else
                sPMLOper = "MBL4_PML_OPER_" & Split(ThisProject.ProjectName, "_")(3)
            End If
            Mimics.Open sPMLOper, , , , , , , , 0, 0, True
            Mimics("MBL4_PML_INICIAL").Close fvDoNotSaveChanges
        End If
        Variables.Item("Login_Logout%").Value = False
    End If

End Function

Public Function TestVariable(ByRef varOPC As Variable) As Boolean
On Error GoTo ErrorHandler

    '* Check the status and the quality of the variable
    If (varOPC.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Audibility", "TestVariable", "The status of " & varOPC.Name & " is Waiting")
    ElseIf (varOPC.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Audibility", "TestVariable", "The status of " & varOPC.Name & " is Config Error")
    ElseIf (varOPC.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Audibility", "TestVariable", "The status of " & varOPC.Name & " is Not Connected")
    ElseIf (varOPC.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Audibility", "TestVariable", "The Quality of " & varOPC.Name & " is not good")
    Else
        '* Status and quality of the variable are good
        TestVariable = True
    End If
    
    Exit Function
ErrorHandler:
        Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "TestVariable", Err.Description)
End Function


Public Function SetTAS_PML()
    Dim sTASName As String
    
    On Error GoTo ErrorHandler
    
    If ThisProject.UserName = "MyUser" Then Exit Function
    If InStr(ThisProject.ProjectName, "PML_GOS") > 0 Then
        sTASName = "TERRITORIO_GOS2_L4"
    ElseIf InStr(ThisProject.ProjectName, "PML_AQT") > 0 Then
        sTASName = "TERRITORIO_AQT_L4"
    ElseIf InStr(ThisProject.ProjectName, "PML_JOC") > 0 Then
        sTASName = "TERRITORIO_JOC_L4"
    ElseIf InStr(ThisProject.ProjectName, "PML_SCO") > 0 Then
        sTASName = "TERRITORIO_SCO_L4"
    Else
        'Backup da Central
        sTASName = "TERRITORIO_L4"
    End If
    
    If InStr(Variables("OPCCluster:" & sTASName & ".TAS.ControlledBy").Value, ThisProject.UserName) = 0 Then Variables("OPCCluster:" & sTASName & ".TAS.AssignToOperator").Value = ThisProject.UserName
    
    Exit Function
ErrorHandler:
        Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "SetTAS_PML", Err.Description)

End Function

Public Function SetTAS_FEP()
    Dim sTASName As String, iLine As Integer
    
    On Error GoTo ErrorHandler
    
    If ThisProject.UserName = "MyUser" Then Exit Function
    
    iLine = Right(ThisProject.ProjectName, 1)
    sTASName = "DOM_LINHA" & iLine
 
    If InStr(Variables("OPCCluster:" & sTASName & ".TAS.ControlledBy").Value, ThisProject.UserName) = 0 Then _
       Variables("OPCCluster:" & sTASName & ".TAS.AssignToOperator").Value = ThisProject.UserName
    
    Exit Function
ErrorHandler:
        Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "SetTAS_PML", Err.Description)

End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_General::CreateNew_Iconis_CLS_OPCSet
' Input:        none
' Output:       [Iconis_CLS_OPCSet]   The new instance
' Description:  Create and return a new instance of an Iconis_CLS_OPCSet
'-------------------------------------------------------------------------------
Public Function CreateNew_Iconis_CLS_OPCSet() As Iconis_CLS_OPCSet
    Set CreateNew_Iconis_CLS_OPCSet = New Iconis_CLS_OPCSet
End Function



'Terminais, conforme OCD:
' L1: URI, GLR, BTF E GOS1
' L2: PVN E ESA2
' L4: GOS2, JOC E GVA
Public Function IsTerminal(ByVal sBranch As String) As Boolean
    IsTerminal = (InStr(1, sBranch, "URI", vbTextCompare) > 0) Or (InStr(1, sBranch, "GLR", vbTextCompare) > 0) Or _
                 (InStr(1, sBranch, "BTF", vbTextCompare) > 0) Or (InStr(1, sBranch, "GOS", vbTextCompare) > 0) Or _
                 (InStr(1, sBranch, "PVN", vbTextCompare) > 0) Or (InStr(1, sBranch, "ESA2", vbTextCompare) > 0) Or _
                 (InStr(1, sBranch, "JOC", vbTextCompare) > 0) Or (InStr(1, sBranch, "GVA", vbTextCompare) > 0) Or _
                 (InStr(1, sBranch, "SPN", vbTextCompare) > 0)
                 
End Function


'Verifica se o equipamento está sob controle local
Public Function IsLocalMode(ByVal sDOM As String) As Boolean
    Dim varTCR As Variable
    
    On Error GoTo ErrorHandler
    
    Select Case sDOM
        'PMLs da Linha 1
        Case "BTF1"
            Set varTCR = Variables("OPCCluster:TCR_BTF1_M_L1.HMIMODE.Template.iEqpState")
        Case "CRC"
            Set varTCR = Variables("OPCCluster:TCR_CRC_M_L1.HMIMODE.Template.iEqpState")
        Case "CTG"
            Set varTCR = Variables("OPCCluster:TCR_CTG_M_L1.HMIMODE.Template.iEqpState")
        Case "CTR"
            Set varTCR = Variables("OPCCluster:TCR_CTR_M_L1.HMIMODE.Template.iEqpState")
        Case "ESA1"
            Set varTCR = Variables("OPCCluster:TCR_ESA1_M_L1.HMIMODE.Template.iEqpState")
        Case "GLR"
            Set varTCR = Variables("OPCCluster:TCR_GLR_M_L1.HMIMODE.Template.iEqpState")
        Case "GOS1"
            Set varTCR = Variables("OPCCluster:TCR_GOS1_M_L1.HMIMODE.Template.iEqpState")
        Case "SCP"
            Set varTCR = Variables("OPCCluster:TCR_SCP2_M_L1.HMIMODE.Template.iEqpState")
        Case "SPN", "URI"
            Set varTCR = Variables("OPCCluster:TCR_SPN_M_L1.HMIMODE.Template.iEqpState")
    
    
        'PMLs da Linha 2
        Case "ESA2"
            Set varTCR = Variables("OPCCluster:TCR_ESA_M_L2.HMIMODE.Template.iEqpState")
        Case "MGR"
            Set varTCR = Variables("OPCCluster:TCR_MGR_M_L2.HMIMODE.Template.iEqpState")
        Case "MRC"
            Set varTCR = Variables("OPCCluster:TCR_MRC_M_L2.HMIMODE.Template.iEqpState")
'''        Case "PMO"
'''            Set varTCR = Variables("OPCCluster:TCR_PMO_M_L2.HMIMODE.Template.iEqpState")
        Case "SCR"
            Set varTCR = Variables("OPCCluster:TCR_SCR_M_L2.HMIMODE.Template.iEqpState")
    
        'PMLs da Linha 4
        Case "AQT"
            Set varTCR = Variables("OPCCluster:TCR_AQT_M_L4.HMIMODE.Template.iEqpState")
        Case "GOS2"
            Set varTCR = Variables("OPCCluster:TCR_GOS2_M_L4.HMIMODE.Template.iEqpState")
        Case "JOC"
            Set varTCR = Variables("OPCCluster:TCR_JOC_M_L4.HMIMODE.Template.iEqpState")
        Case "SCO"
            Set varTCR = Variables("OPCCluster:TCR_SCO_M_L4.HMIMODE.Template.iEqpState")
    
    End Select
    
    IsLocalMode = (varTCR = 1)
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "IsLocalMode", Err.Description)

End Function


Public Function GetHMITrainOPCName(ByVal sOPCTrainID As String, ByVal sHMITrainID As String) As String
    Dim I As Integer, iTrain As Integer
    
    On Error GoTo ErrorHandler
    
    Dim xmlDoc As DOMDocument
    Dim pNode As IXMLDOMNode
    Dim sQuery As String
    Dim pElement        As IXMLDOMElement

    Set xmlDoc = New DOMDocument
'    xmlDoc.loadXML Variables("OPCCluster:IconisMain.HMITrainModule.HMITrainManager.xmlListHMITrain").Value
    xmlDoc.loadXML Variables("OPCCluster:MainKernelBasic.TrainModule.HMITrainManager.xmlListHMITrain").Value
    
    sQuery = "//Train[@UniqueID=" & Chr(34) & sOPCTrainID & Chr(34) & "][@HMITrainID=" & Chr(34) & sHMITrainID & Chr(34) & "]"
    Set pNode = xmlDoc.selectSingleNode(sQuery)
    
    GetHMITrainOPCName = pNode.Attributes(1).nodeValue
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "GetHMITrainOPCName", Err.Description)

End Function



Public Function GetNbTrain(ByVal sHeadLocation As String) As String
    Dim I As Integer, iTrain As Integer
    
    On Error GoTo ErrorHandler
    
    Dim xmlDoc As DOMDocument
    Dim pNodeList As IXMLDOMNodeList
    Dim sQuery As String
    Dim pElement        As IXMLDOMElement

    Set xmlDoc = New DOMDocument
'    xmlDoc.loadXML Variables("OPCCluster:IconisMain.HMITrainModule.HMITrainManager.xmlListHMITrain").Value
    xmlDoc.loadXML Variables("OPCCluster:IconisMain.HMITrainModule.HMITrainManager.xmlListHMITrain").Value
    
    sQuery = "//Train[@HeadLocation=" & Chr(34) & sHeadLocation & Chr(34) & "]"
    Set pNodeList = xmlDoc.selectNodes(sQuery)
    
    GetNbTrain = pNodeList.length
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "GetNbTrain", Err.Description)

End Function



'>>>>>>>
'>>>>>>> COMANDOS SOBRE CDV
'>>>>>>>
'Conforme o TDS, os estados do CDV são:
'
' 1: FREE
' 2: OCCUPIED
' 3: FALSEOCCUPANCY
' 4: DESAPPEAREADTRAIN
' 7: OVERRIDESHUNTTC
' 8: INDERTEMINATIONSTATE

' BIT MASKS:
' 0x0040: Start             = 64
' 0x0080: Unknown           = 128
' 0x0100: Out-of-service    = 256
' 0x0200: Dark zone         = 512
' 0x0400: OCCUPIEDDZ        = 1024
' 0x0800: DZWITHTRAIN       = 2048 (Contém pelo menos 1 trem)

'>>>>>>> CDV - Promove Falsa Ocupação (FO)
Public Function CdvPromoveFO(ByRef mimicCommand As Mimic) As Boolean
    Dim sCDVName As String
    
    On Error GoTo ErrorHandler

    '=(@Plug% == 0) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Detection.Template.Security")) Or _
       Not TestVariable(Variables.Item(mimicCommand.Branch & ".Detection.TCTracker.iState")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Detection.Template.Security").Value = 63 Or Not [@UserAccessCommand%] _
        Or Variables.Item(mimicCommand.Branch & ".Detection.TCTracker.iState") <> 3 _
        Or Variables.Item(mimicCommand.Branch & ".DarkZone%") _
        Or Variables(mimicCommand.Branch & ".LocalMode%").Value _
        Or Variables("bIMH_FEP%").Value Then Exit Function
    
    sCDVName = Replace(mimicCommand.Branch, "opccluster:@", "", 1, , vbTextCompare)
    strCommand = sCDVName & "|Train"
    Variables("OPCCluster:IconisMain.TrainIDModule.TrainID.bstrInterposeTC").Value = strCommand
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    CdvPromoveFO = True
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "CdvPromoveFO", Err.Description)

End Function

'>>>>>>> CDV - Desativar/Reativar
Public Function CdvDesativaReativa(ByRef mimicCommand As Mimic) As Boolean
    Dim sCDVName As String
    Dim vBitMask
    
    On Error GoTo ErrorHandler

    '=(@Plug% == 0) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Detection.Template.Security")) Then Exit Function
'    If Variables.Item(mimicCommand.Branch & ".Detection.Template.Security").Value = 63 Or Not [@UserAccessCommand%] _
'       Or Variables.Item(mimicCommand.Branch & ".DarkZone%") Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Detection.Template.Security").Value = 63 Or Not [@UserAccessCommand%] _
       Or Variables(mimicCommand.Branch & ".LocalMode%").Value _
       Or Variables("bIMH_FEP%").Value Then Exit Function

    sCDVName = Replace(mimicCommand.Branch, "opccluster:@", "", 1, , vbTextCompare)

    'Confere "bit mask (0x0100: Out-of-service = 256)"
    vBitMask = Variables.Item(mimicCommand.Branch & ".Detection.TCTracker.iState").Value And 256

    If vBitMask = 0 Then
        If ModalQuestion("Confirma a desativação do CDV " & sCDVName & "?", "CDV - Desativar") Then
            strCommand = sCDVName & "|OutOfService"
        End If
    Else
        strCommand = sCDVName & "|InService"
    End If

      ''  strCommand = sCDVName & "|RemoveFromDZ"

    If strCommand <> "" Then
        Variables("OPCCluster:IconisMain.TrainIDModule.TrainID.bstrInterposeTC").Value = strCommand
        CdvDesativaReativa = True
    End If
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "CdvPromoveFO", Err.Description)

End Function


'>>>>>>> CDV - CE Rota
Public Function CdvRotaCE(ByRef mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

    '=(@Plug% == 0) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Detection.Template.Security")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Detection.Template.Security").Value = 63 Or Not [@UserAccessCommand%] _
       Or Variables.Item(mimicCommand.Branch & ".DarkZone%").Value _
       Or Variables(mimicCommand.Branch & ".LocalMode%").Value Then Exit Function
    
    RouteCancelation mimicCommand.Branch, 1

    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    CdvRotaCE = True
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "CdvRotaCE", Err.Description)

End Function


'>>>>>>> CDV - CI Rota
Public Function CdvRotaCI(ByRef mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

    '=(@Plug% == 0) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Detection.Template.Security")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Detection.Template.Security").Value = 63 Or Not [@UserAccessCommand%] _
       Or Variables.Item(mimicCommand.Branch & ".DarkZone%").Value _
       Or Variables(mimicCommand.Branch & ".LocalMode%").Value Then Exit Function
    
    RouteCancelation mimicCommand.Branch, 0

    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    CdvRotaCI = True
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "CdvRotaCI", Err.Description)

End Function

'>>>>>>> CDV - Bandeira de Restrição
Public Function CdvBandRestr(ByRef mimicCommand As Mimic) As Boolean
    Dim sCMD As String
    On Error GoTo ErrorHandler

    Variables.Item(mimicCommand.Branch & ".RestrictionFlag.Value").Value = Not Variables.Item(mimicCommand.Branch & ".RestrictionFlag.Value").Value
    'GERAÇÃO DE EVENTO
    If Variables.Item(mimicCommand.Branch & ".RestrictionFlag.Value").Value Then
        sCMD = "Remove"
    Else
        sCMD = "Insere"
    End If
    Variables.Item("OPCCluster:HMIEvent.S2KString_2.Value") = "CMD: " & sCMD & " Bandeira de Restrição executado com sucesso no CDV " & Variables.Item(mimicCommand.Branch & ".Detection.Template.Name").Value
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    CdvBandRestr = True
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "CdvBandRestr", Err.Description)

End Function

'>>>>>>> CDV - Trens na Zona Escura
Public Function CdvDarkZone(ByRef mimicCommand As Mimic) As Boolean
    Dim sCDVName As String
    
    On Error GoTo ErrorHandler

    If Not Variables(mimicCommand.Branch & ".TrainInDarkZone%").Value _
       Or Variables("bIMH_FEP%").Value Then Exit Function

    'Abrir janela de comando no centro do monitor
    OpenMimicCommand "CDV_cmd_darkzone", mimicCommand.Branch, 320, 200, True
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    CdvDarkZone = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "CdvDarkZone", Err.Description)

End Function



'>>>>>>>
'>>>>>>> COMANDOS SOBRE PLATAFORMA
'>>>>>>>

'>>>>>>> PLATAFORMA - Autoriza AP (AP) - Mudou para Retém por solicitação do Bertolino
Public Function PlatAutorizaAP(ByVal mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

    '=(!@InibeCMD_AP%) and (Point.Security < 63) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Point.Security")) Or _
       Not TestVariable(Variables.Item(mimicCommand.Branch & ".RegPoint.iHoldType")) Or _
       Not TestVariable(Variables.Item(mimicCommand.Branch & ".RegPoint.HoldPlatform")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Point.Security").Value = 63 Or Not [@UserAccessCommand%] _
       Or [@InibeCMD_AP%] Or Variables(mimicCommand.Branch & ".LocalMode%").Value _
       Or Variables("bIMH_FEP%").Value Then Exit Function

    If Not Variables.Item(mimicCommand.Branch & ".RegPoint.HoldPlatform").Value Then Variables.Item(mimicCommand.Branch & ".DOO.Detection.Template.iCommand").Value = 1
    Variables.Item(mimicCommand.Branch & ".RegPoint.HoldPlatform").Value = Not Variables.Item(mimicCommand.Branch & ".RegPoint.HoldPlatform").Value
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    PlatAutorizaAP = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "PlatAutorizaAP", Err.Description)

End Function

'>>>>>>> PLATAFORMA - Horário de Partida (HMA)
Public Function PlatHMA(ByVal mimicCommand As Mimic) As Boolean
    
Exit Function 'Implementar para FASE 2
    
    On Error GoTo ErrorHandler

    '=(Point.Security < 63) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Point.Security")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Point.Security").Value = 63 Or Not [@UserAccessCommand%] _
       Or Variables(mimicCommand.Branch & ".LocalMode%").Value _
       Or Variables("bIMH_FEP%").Value Then Exit Function
    
    'Abrir janela de comando no centro do monitor
    OpenMimicCommand "PLAT_cmd_HrPartida", mimicCommand.Branch, 220, 165, True
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    PlatHMA = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "PlatHMA", Err.Description)

End Function

'>>>>>>> PLATAFORMA - Tempo de Parada
Public Function PlatTP(ByVal mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

    '=(!@InibeCMD_PlataformaTP%) and (Point.Security < 63) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Point.Security")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Point.Security").Value = 63 Or Not [@UserAccessCommand%] _
       Or [@InibeCMD_PlataformaTP%] Or Variables(mimicCommand.Branch & ".LocalMode%").Value _
       Or Variables("bIMH_FEP%").Value Then Exit Function
    
    'Abrir janela de comando no centro do monitor
    OpenMimicCommand "PLAT_cmd_TP", mimicCommand.Branch, 220, 165, True
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    PlatTP = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "PlatTP", Err.Description)

End Function

'>>>>>>> PLATAFORMA - Próxima Partida (Motivo)
Public Function PlatMotivo(ByVal mimicCommand As Mimic) As Boolean
    Dim sPlataforma As String
    Dim iValue As Integer
    
    On Error GoTo ErrorHandler

    '=(Point.Security < 63) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Point.Security")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Point.Security").Value = 63 Or Not [@UserAccessCommand%] _
      Or Variables(mimicCommand.Branch & ".LocalMode%").Value _
      Or Variables("bIMH_FEP%").Value Then Exit Function
      
    sPlataforma = Replace(mimicCommand.Branch, "Stop_STA_PF_", "MOT_")
    
    If Variables.Item(sPlataforma & ".POS.Template.iEqpState").Value = 1 Then iValue = 1
    
    Variables.Item(sPlataforma & ".POS.Template.iCommand").Value = iValue
    ''''Gerar evento de comando
    '''Variables.Item("OPCCluster:HMIEvent.S2KString_2.Value") = "CMD: Próxima Partida (Motivo) executado com sucesso, valor do comando:" & iValue
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    PlatMotivo = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "PlatMotivo", Err.Description)

End Function

'>>>>>>> PLATAFORMA - Avisa partida iminente (sin.son)
Public Function PlatSinSon(ByVal mimicCommand As Mimic) As Boolean
    Dim sStationName As String
    
    On Error GoTo ErrorHandler

    '=(Point.Security < 63) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Point.Security")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Point.Security").Value = 63 Or Not [@UserAccessCommand%] _
       Or Variables(mimicCommand.Branch & ".LocalMode%").Value _
       Or Variables("bIMH_FEP%").Value Then Exit Function
    
    If InStr(mimicCommand.Branch, "URI") > 0 Then
        sStationName = "LP_ST_URI"
    ElseIf InStr(mimicCommand.Branch, "SPN") > 0 Then
        sStationName = "LP_ST_SPN"
    Else
        Exit Function
    End If
    
    Variables("OPCCluster:" & sStationName & ".Bell.Detection.Template.iCommand").Value = 1
    'GERAÇÃO DE EVENTO
    Variables.Item("OPCCluster:HMIEvent.S2KString_2.Value") = "CMD: Sin. Son. executado com sucesso na plataforma " & Variables.Item(mimicCommand.Branch & ".Point.Name").Value & ", valor comandado 1."
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    PlatSinSon = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "PlatSinSon", Err.Description)

End Function

'>>>>>>> PLATAFORMA - NRE
Public Function PlatNRE(ByVal mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

    '=(Point.Security < 63) and (@UserAccessCommand%)
    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Point.Security")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Point.Security").Value = 63 Or Not [@UserAccessCommand%] _
       Or Variables(mimicCommand.Branch & ".LocalMode%").Value Then Exit Function

    'Abrir janela de comando no centro do monitor
    OpenMimicCommand "PLAT_cmd_NRE", mimicCommand.Branch, 220, 120, True
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    PlatNRE = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "PlatNRE", Err.Description)

End Function

'>>>>>>> PLATAFORMA - TCA
Public Function PlatTCA(ByRef mimicCommand As Mimic) As Boolean
    Dim sCMD As String
    
    On Error GoTo ErrorHandler

    If Not TestVariable(Variables.Item(mimicCommand.Branch & ".Point.Security")) Then Exit Function
    If Variables.Item(mimicCommand.Branch & ".Point.Security").Value = 63 Or Not [@UserAccessCommand%] _
       Or Variables(mimicCommand.Branch & ".LocalMode%").Value Then Exit Function
    
    Variables.Item(mimicCommand.Branch & ".TCAFlag.Value").Value = Not Variables.Item(mimicCommand.Branch & ".TCAFlag.Value").Value
    'GERAÇÃO DE EVENTO
    If Variables.Item(mimicCommand.Branch & ".TCAFlag.Value").Value Then
        sCMD = "Remove"
    Else
        sCMD = "Insere"
    End If
    Variables.Item("OPCCluster:HMIEvent.S2KString_2.Value") = "CMD: " & sCMD & " TCA executado com sucesso na plataforma " & Variables.Item(mimicCommand.Branch & ".Point.Name").Value
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then mimicCommand.Close fvDoNotSaveChanges
    PlatTCA = True
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "PlatTCA", Err.Description)

End Function



'>>>>>>>
'>>>>>>> COMANDOS SOBRE TREM
'>>>>>>>

'>>>>>>> TREM - Identifica (D+NT)
'>>>>>>> Comando: "%UniqueID%|n|Identification|XXXX"
Public Function TremID(ByVal mimicCommand As Mimic) As Boolean
    Dim sBranch As String
    
    On Error GoTo ErrorHandler

    '=(@UserAccessCommand%)
    If Not [@UserAccessCommand%] Or [@InibeCMD_TremID%] Then Exit Function

    If InStr(mimicCommand.Branch, "TCB_") > 0 And InStr(mimicCommand.Branch, "HMITrainID1") = 0 Then
        sBranch = mimicCommand.Branch & ".HMITrain1"
    Else
        sBranch = mimicCommand.Branch
    End If

    'Abrir janela de comando no centro do monitor
    OpenMimicCommand "TCB_cmd_identifica", sBranch, 220, 165, True
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        mimicCommand.Close fvDoNotSaveChanges
        If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    End If
    
    TremID = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "PlatNRE", Err.Description)

End Function

'>>>>>>> TREM - Troca identificação com...
'>>>>>>> Comando: "%UniqueID%|n|DarkZone|m" n=ID do trem do sistema, m=ID do trem na Zona Escura>>> para trem em Zona Escura
'>>>>>>> Comando: "%UniqueID%|n|????|m" n=ID do trem do atual, m=ID do trem para trocar>>> para trem no Rastramento
Public Function TremTrocaID(ByVal mimicCommand As Mimic) As Boolean
    
Exit Function 'Implementar para FASE 2
    
    On Error GoTo ErrorHandler

    '=(@UserAccessCommand%)
    If Not [@UserAccessCommand%] Or [InibeCMD_TremID%] Then Exit Function

    If InStr(mimicCommand.Branch, "TCB_") > 0 And InStr(mimicCommand.Branch, "HMITrainID1") = 0 Then
        sBranch = mimicCommand.Branch & ".HMITrain1"
    Else
        sBranch = mimicCommand.Branch
    End If
    
    'Abrir janela de comando no centro do monitor
'''    OpenMimicCommand "TCB_cmd_identifica", mimicCommand.Branch, 220, 165, True
    MsgBox "Comando Troca identificação com...  - Aguardando plug..."
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        mimicCommand.Close fvDoNotSaveChanges
        If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    End If
    
    TremTrocaID = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "TremTrocaID", Err.Description)

End Function

'>>>>>>> TREM - Renumera trens do laço...
'>>>>>>> Comando: ?????
Public Function TremRenum(ByVal mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

Exit Function 'Implementar para FASE 2

    '=(@UserAccessCommand%)
    If Not [@UserAccessCommand%] Or [InibeCMD_TremID%] Then Exit Function

    If InStr(mimicCommand.Branch, "TCB_") > 0 And InStr(mimicCommand.Branch, "HMITrainID1") = 0 Then
        sBranch = mimicCommand.Branch & ".HMITrain1"
    Else
        sBranch = mimicCommand.Branch
    End If
    
    'Abrir janela de comando no centro do monitor
'''    OpenMimicCommand "TCB_cmd_identifica", mimicCommand.Branch, 220, 165, True
    MsgBox "Comando Renumera trens do laço...  - Sistema Completo:Aguardando plug..."
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        mimicCommand.Close fvDoNotSaveChanges
        If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    End If
    
    TremRenum = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "TremRenum", Err.Description)

End Function

'>>>>>>> TREM - Atribui NMT...
'>>>>>>> Comando: "%UniqueID%|n|%RollingStockID%|XXXX"
Public Function TremNMT(ByVal mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

    '=(@UserAccessCommand%)
    If Not [@UserAccessCommand%] Or [InibeCMD_TremNMT%] Then Exit Function
    If InStr(mimicCommand.Branch, "TCB_") > 0 And InStr(mimicCommand.Branch, "HMITrainID1") = 0 Then
        sBranch = mimicCommand.Branch & ".HMITrain1"
    Else
        sBranch = mimicCommand.Branch
    End If
    
    'Abrir janela de comando no centro do monitor
    OpenMimicCommand "TCB_cmd_NMT", sBranch, 220, 165, True
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        mimicCommand.Close fvDoNotSaveChanges
        If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    End If
    
    TremNMT = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "TremNMT", Err.Description)

End Function

'>>>>>>> TREM - Rebaixa à Falsa Ocupação (FO)
'>>>>>>> Comando: "%UniqueID%|n|FalseOccupancy"
Public Function TremRebaixaFO(ByVal mimicCommand As Mimic) As Boolean
    Dim sTrainName As String
    
    On Error GoTo ErrorHandler

    If Not [@UserAccessCommand%] Or [InibeCMD_TremFO%] Then Exit Function
    
    If InStr(mimicCommand.Branch, "TCB_") > 0 And InStr(mimicCommand.Branch, "HMITrainID1") = 0 Then
        sBranch = mimicCommand.Branch & ".HMITrain1"
    Else
        sBranch = mimicCommand.Branch
    End If
    
    If Variables(sBranch & ".TDS.iNbOccupiedTrack").Value <> 1 Then Exit Function
    
    sTrainName = Variables(sBranch & ".TDS.bstrHMITrainID").Value
    strCommand = "%UniqueID%|" & Format(Variables(sBranch & ".TDS.iTrainID").Value)
    strCommand = strCommand & "|FalseOccupancy"
    
    If ModalQuestion("Confirma o rebaixamento da composição " & sTrainName & " à Falsa Ocupação (FO)?", "Trem - Confirma FO") Then
        Variables("OPCCluster:IconisMain.TrainIDModule.TrainID.bstrInterposeBerth").Value = strCommand
        TremRebaixaFO = True
    End If
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        mimicCommand.Close fvDoNotSaveChanges
        If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    End If
        
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "CdvPromoveFO", Err.Description)

End Function

'>>>>>>> TREM - Tempo de parada...
'>>>>>>> Comando: "%UniqueID%|n|%ImposedDwellTime%|XXXX" - XXXX é o valor do tempo, e "-1" para retirar imposição
Public Function TremTP(ByVal mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

    '=(@UserAccessCommand%)
    If Not [@UserAccessCommand%] Or [InibeCMD_TremTP%] Then Exit Function

    If InStr(mimicCommand.Branch, "TCB_") > 0 And InStr(mimicCommand.Branch, "HMITrainID1") = 0 Then
        sBranch = mimicCommand.Branch & ".HMITrain1"
    Else
        sBranch = mimicCommand.Branch
    End If
    
    'Abrir janela de comando no centro do monitor
    OpenMimicCommand "TCB_cmd_TP", sBranch, 220, 165, True
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        mimicCommand.Close fvDoNotSaveChanges
        If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    End If
    
    TremTP = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "TremTP", Err.Description)

End Function

'>>>>>>> TREM - Nível de desempenho (ND)...
'>>>>>>> Comando: "%UniqueID%|n|%PerformanceLevel%|X" - X= indice do ND, 0 para retirar
Public Function TremND(ByVal mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

    Exit Function 'Implementar para FASE 2

    '=(@UserAccessCommand%)
    If Not [@UserAccessCommand%] Or [InibeCMD_TremND%] Then Exit Function
    If InStr(mimicCommand.Branch, "TCB_") > 0 And InStr(mimicCommand.Branch, "HMITrainID1") = 0 Then
        sBranch = mimicCommand.Branch & ".HMITrain1"
    Else
        sBranch = mimicCommand.Branch
    End If
    
    'Abrir janela de comando no centro do monitor
    OpenMimicCommand "TCB_cmd_ND", mimicCommand.Branch, 220, 165, True
'''    MsgBox "Comando Nível de desempenho (ND)...  - Sistema Completo:Aguardando plug..."
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        mimicCommand.Close fvDoNotSaveChanges
        If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    End If
    TremND = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "TremND", Err.Description)

End Function

'>>>>>>> TREM - Distribui atraso (Ajuste)...
'>>>>>>> Comando Solicitar: "IconisMain.ATRModule.DelayDistribution.Request"
'>>>>>>> Comando Formatar: "IconisMain.ATRModule.DelayDistribution.Trains"
'>>>>>>> Comando Aplicar: "IconisMain.ATRModule.DelayDistribution.Trains"
'>>>>>>> Comando Remover: "<Train>.ATR.AcknowledgeDelay"
Public Function TremAjuste(ByVal mimicCommand As Mimic) As Boolean
    
    
    On Error GoTo ErrorHandler

Exit Function 'Implementar para FASE 2

    '=(@UserAccessCommand%)
    If Not [@UserAccessCommand%] Then Exit Function
    If InStr(mimicCommand.Branch, "TCB_") > 0 And InStr(mimicCommand.Branch, "HMITrainID1") = 0 Then
        sBranch = mimicCommand.Branch & ".HMITrain1"
    Else
        sBranch = mimicCommand.Branch
    End If
    
    'Abrir janela de comando no centro do monitor
'''    OpenMimicCommand "TCB_cmd_identifica", mimicCommand.Branch, 220, 165, True
    MsgBox "Comando Distribui atraso (Ajuste)...  - Sistema Completo:Aguardando plug..."
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        mimicCommand.Close fvDoNotSaveChanges
        If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    End If
    TremAjuste = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "TremAjuste", Err.Description)

End Function

'>>>>>>> TREM - Anotação...
Public Function TremNota(ByVal mimicCommand As Mimic) As Boolean
    
    On Error GoTo ErrorHandler

    '=(@UserAccessCommand%)
    If Not [@UserAccessCommand%] Then Exit Function
    If InStr(mimicCommand.Branch, "TCB_") > 0 And InStr(mimicCommand.Branch, "HMITrainID1") = 0 Then
        sBranch = mimicCommand.Branch & ".HMITrain1"
    Else
        sBranch = mimicCommand.Branch
    End If
    
    'Abrir janela de comando no centro do monitor
    OpenMimicCommand "Train_Note", mimicCommand.Branch, 220, 165, True
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        mimicCommand.Close fvDoNotSaveChanges
        If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    End If
    
    TremNota = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "TremNota", Err.Description)

End Function


'>>>>>>> TREM - Composições no CDV...
Public Function TremCompCDV(ByVal mimicCommand As Mimic) As Boolean
    Dim sBranch As String
    
    On Error GoTo ErrorHandler

    sBranch = Replace(mimicCommand.Branch, ".HMITrain1", "")
    '=(Berth.iCount > 1) and (@UserAccessCommand%)
    If Variables.Item(sBranch & ".CDViCount%").Value < 2 Or Not [@UserAccessCommand%] Then Exit Function
    
    If InStr(mimicCommand.FileName, "ContextualMenu") > 0 Then
        Mimics.Open "TrainIndicator_List", [sBerthTag%], , , , , , , mimicCommand.Windows(1).Left, mimicCommand.Windows(1).Top, True
        mimicCommand.Close fvDoNotSaveChanges
    Else
        'Abrir lista de trens em baixo do símbolo
        OpenMimicCommand "TrainIndicator_List", [sBerthTag%], 189, 84, True
    End If
    If Mimics.IsOpened("GeneralTrainList_ContextualMenu") Then Mimics("GeneralTrainList_ContextualMenu").Close fvDoNotSaveChanges
    
    TremCompCDV = True

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "TremCompCDV", Err.Description)

End Function






Public Function SetSinoticoLayers()
    Dim iCount As Integer
    Dim iLayerValue As Long
    
    On Error GoTo ErrorHandler
    
    iLayerValue = 65535
    
    iLayerValue = iLayerValue Xor (Not [@HideCDV.Sinotico%] And 4096)
    iLayerValue = iLayerValue Xor (Not [@HideAMV.Sinotico%] And 2048)
    iLayerValue = iLayerValue Xor (Not [@HideSinal.Sinotico%] And 1024)
    iLayerValue = iLayerValue Xor (Not [@HideTrem.Sinotico%] And 512)
    
    For iCount = 1 To ThisProject.Mimics.Count
        If InStr(ThisProject.Mimics.Item(iCount).FileName, "RIO_SINOPTICO_") > 0 Then
            ThisProject.Mimics.Item(iCount).Windows(1).Layers = iLayerValue
        End If
    Next iCount
       
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "SetSinoticoLayers", Err.Description)

End Function


Public Function LeftWorkspace() As Integer
    Dim sConfigFiles As String
    Dim sInputData As String
    
    On Error GoTo ErrorHandler
    
'    sConfigFiles = Replace(ThisProject.ProjectName, "HMI_MBL4_", "\Config Files ")
    sConfigFiles = "\Config Files"
    
    Open ThisProject.Path & sConfigFiles & "\paramws.dat" For Input As #1    ' Open file for input.
    Line Input #1, sInputData        'Read line of data.
    Close #1    'Close file.
    
    LeftWorkspace = Split(sInputData, ",")(2)
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "bLeftWorkspace", Err.Description)

End Function



Public Function VerifyMimicPosition(ByRef mmcCommand As Mimic)
    Dim iMonitor As Integer

    On Error GoTo ErrorHandler

    iMonitor = Abs(Int((mmcCommand.Windows(1).Left / c_lScreenWidth) * -1))
    If mmcCommand.Windows(1).Top > c_lScreenHeight - mmcCommand.Windows(1).Height - 10 Then mmcCommand.Windows(1).Top = c_lScreenHeight - mmcCommand.Windows(1).Height - 10
    If mmcCommand.Windows(1).Left > (c_lScreenWidth * iMonitor) - mmcCommand.Windows(1).Width - 10 Then mmcCommand.Windows(1).Left = (c_lScreenWidth * iMonitor) - mmcCommand.Windows(1).Width - 10

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "modFuncoes", "VerifyMimicPosition", Err.Description)

End Function



Public Function aux_navegacao(tela_Origem As String, ByVal Posicao As Integer, tela_Destino As String)
'    On Error GoTo Trap
    Dim sNomeTelaTracao As String


    If TheseMimics.IsOpened(tela_Destino) = True Then
        If TheseMimics.Item(tela_Destino).Windows(1).Left <> Posicao Then

            aux_posic_origem = TheseMimics.Item(tela_Origem).Windows(1).Left
            aux_posic_destino = TheseMimics.Item(tela_Destino).Windows(1).Left

            With TheseMimics.Item(tela_Origem)
                .Windows(1).Left = aux_posic_destino
            End With

            With TheseMimics.Item(tela_Destino)
                 .Windows(1).Left = aux_posic_origem
            End With
        End If
    Else
        'TheseMimics.Open (tela_Destino), , , , , , , , Posicao, 0, True
        TheseMimics.Open (tela_Destino), , , , , , , , 0, 0, True
        ThisProject.Mimics(tela_Destino).Windows(1).Layers = ThisProject.Mimics(tela_Origem).Windows(1).Layers

        TheseMimics.Item(tela_Origem).Close (fvDoNotSaveChanges)
    End If

End Function

 Public Function Navegation(sMimicOpened As String, sMimicClosed As String, Optional sTag As String)
    'Funcao para abertura dos Mimics e dinamica dos botoes de navegacao
    'Abre o mimic solicitado e fecha o mimic ativo
    'Altera a variável do botao de navegacao, isso serve para identificar qual tela esta ativa
    Dim iMimicLeft As Integer, iMimicTop As Integer
    Dim iCount As Integer, sButton As String
    Dim mmcActive As Mimic
    Dim sMonitor As String
    
    On Error GoTo ErrorHandler
    
    Set mmcActive = ActiveMimic
'    sMonitor = "M" & (ActiveMimic.Windows(1).Left / c_lScreenWidth) + 1
    iMimicLeft = mmcActive.Windows(1).Left
    
    'close all inspector panel of the same equipment type in the current monitor
    For iCount = 1 To ThisProject.Mimics.Count
        If (InStr(ThisProject.Mimics.Item(iCount).FileName, "_InspectorPanel") > 0) Or (InStr(ThisProject.Mimics.Item(iCount).FileName, "_ContextualMenu") > 0) Then
            If Int(ThisProject.Mimics.Item(iCount).Windows(1).Left / c_lScreenWidth) = Int(mmcActive.Windows(1).Left / c_lScreenWidth) Then ThisProject.Mimics.Item(iCount).Close fvDoNotSaveChanges
        End If
    Next iCount

    If TheseMimics.IsOpened(sMimicClosed) = True Then
        If TheseMimics.Item(sMimicClosed).Windows(1).Left <> iMimicLeft Then
            mmcActive.Windows(1).Left = TheseMimics.Item(sMimicClosed).Windows(1).Left
            TheseMimics.Item(sMimicClosed).Windows(1).Left = iMimicLeft
'        ElseIf sMimicClosed = sMimicOpened Then
'            TheseMimics.Item(sMimicOpened).Close (fvDoNotSaveChanges)
        End If
    Else
        TheseMimics.Open sMimicClosed, , , , , , , , iMimicLeft, iMimicTop, True
        mmcActive.Close (fvDoNotSaveChanges)
    End If
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ModMain", "Navegation", Err.Description)
 
End Function



Public Function FillComboBox(ByRef objCombo As ComboBox, ByVal sTipo As String, ByVal sSub As Variant, Optional ByRef objComboEst As ComboBox)
    Dim I As Integer, sList As String, arrList As Variant
    Dim arrSub As Variant
    Dim sArea As String, sName As String
    
    On Error GoTo ErrorHandler
    
    If InStr(sSub, ";") = 0 Then Exit Function
    arrSub = Split(sSub, ";")
    objCombo.Clear
    objCombo.AddItem "Todos"
    objCombo = "Todos"
    
    If Not IsBounded(arrList_Stations) Then Read_List_Stations
    If Not IsBounded(arrList_Equipaments) Then Read_List_Equipaments
    
    For Each sSub In arrSub
        If sSub <> "" Then
            Select Case sTipo
                Case "Local"
'                    For i = 0 To UBound(arrList_Stations)
'                        If Left(arrList_Stations(i), Len(sSub)) = sSub Then
'                            sList = sList & Split(arrList_Stations(i), ";")(1) & ";"
'                        End If
'                    Next i
                                    
                    For I = 0 To UBound(arrList_Stations)
                        If Left(arrList_Stations(I), Len(sSub)) = sSub Then
                           
                            sArea = Split(arrList_Stations(I), ";")(1)
                            
                            If InStr(sArea, "/") > 0 Then
                                sName = Split(sArea, "/")(1) & ";"
                            Else
                                sName = sArea & ";"
                            End If
                            
                            If InStr(sList, sName) = 0 Then
                                sList = sList & sName
                            End If
                        End If
                    Next I
                                    
                
                Case "Tipo"
'                    For i = 0 To UBound(arrList_Equipaments)
'                        If Left(arrList_Equipaments(i), Len(sSub)) = sSub Then
'                            sList = sList & Split(arrList_Equipaments(i), ";")(1) & ";"
'                        End If
'                    Next i
                    For I = 0 To UBound(arrList_Equipaments)
                        If Left(arrList_Equipaments(I), Len(sSub)) = sSub Then
                           
                            sArea = Split(arrList_Equipaments(I), ";")(1)
                            
                            If InStr(sArea, "SIG/") > 0 Then
                                sName = Split(sArea, "/")(1) & ";"
                            ElseIf InStr(sArea, "ENE/") > 0 Or InStr(sArea, "AUX/") > 0 Then
                                If objComboEst Is Nothing Then
                                    sName = Split(sArea, "/")(2) & ";"
                                Else
                                    If (objComboEst.Text = "Todos") Or (objComboEst.Text <> "Todos" And InStr(sArea, objComboEst.Text) > 0) Then
                                        sName = Split(sArea, "/")(2) & ";"
'                                    Else
'                                        sName = Split(sArea, "/")(2) & ";"
                                    End If
                                End If
                            Else
                                sName = sArea & ";"
                            End If
                            
                            If InStr(sList, sName) = 0 Then
                                sList = sList & sName
                            End If
                        End If
                    Next I
                        
            End Select
        End If
    Next
    
    If sList <> "" Then
        arrList = Split(sList, ";")
        SortArray arrList
        For I = 1 To UBound(arrList)
            objCombo.AddItem arrList(I)
        Next I
    End If

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "FillComboBox", Err.Description)

End Function

Public Function Read_List_Equipaments()
On Error Resume Next

    Dim I As Integer, InputData As String
    I = 0
    
    Open ThisProject.Path & "\JAR Files\FilterConfigFunction.txt" For Input As #1    ' Open file for input.

    Do While Not EOF(1)                    'Check for end of file.
        Line Input #1, InputData           'Read line of data.
        ReDim Preserve arrList_Equipaments(I)
        arrList_Equipaments(I) = InputData   'Print to the Immediate window.
        I = I + 1
    Loop
    Close #1    'Close file.

End Function

Public Function Read_List_Stations()
On Error Resume Next

    Dim I As Integer, InputData As String
    I = 0
    
    Open ThisProject.Path & "\JAR Files\FilterConfigArea.txt" For Input As #1    ' Open file for input.

    Do While Not EOF(1)                 'Check for end of file.
        Line Input #1, InputData        'Read line of data.
        ReDim Preserve arrList_Stations(I)
        arrList_Stations(I) = InputData   'Print to the Immediate window.
        I = I + 1
    Loop
    Close #1    'Close file.

End Function

Public Function FindArea(ByRef objComboEst As ComboBox, ByRef objComboEqp As ComboBox, ByVal sSub As Variant) As String
    Dim I As Integer, sList As String, arrList As Variant
    Dim arrSub As Variant, arrArea As Variant
    Dim sAreaFunc As String
    
    If InStr(sSub, ";") = 0 Then Exit Function
    arrSub = Split(sSub, ";")
    
    If Not IsBounded(arrList_Stations) Then Read_List_Stations
    If Not IsBounded(arrList_Equipaments) Then Read_List_Equipaments
    
    For Each sSub In arrSub
        If sSub <> "" Then
            
            'Preencher o Area
            If sSub = "System" Then
                sAreaFunc = "Area/" & sSub
            Else
                For I = 0 To UBound(arrList_Stations)
                    'Localiza Subsystem
                    If (objComboEst.Text = "Todos" And InStr(arrList_Stations(I), sSub) > 0) Then
                        sAreaFunc = "Area"  '& Split(arrList_Stations(I), ";")(0)
                        Exit For
                    'Localiza Estação
                    ElseIf (InStr(arrList_Stations(I), sSub & ";" & objComboEst.Text) > 0) Then
                        sAreaFunc = "Area/" & Split(arrList_Stations(I), ";")(2)
                        Exit For
                    End If
                Next I
            End If
            
            If InStr(sList, sAreaFunc) = 0 Then
                If sList <> "" Then sList = sList & ";"
                sList = sList & sAreaFunc
            End If
            
            'Preencher Function
            For I = 0 To UBound(arrList_Equipaments)
                
                'Localiza Subsystem
                If (objComboEqp.Text = "Todos" And objComboEst.Text = "Todos" And InStr(arrList_Equipaments(I), sSub & ";") > 0) Then
                    sAreaFunc = "Function" ' & Split(arrList_Equipaments(I), ";")(0)
                
                'Localiza SIG
                ElseIf (InStr(arrList_Equipaments(I), sSub & ";" & objComboEqp.Text) > 0) Then
                    sAreaFunc = "Function/" & Split(arrList_Equipaments(I), ";")(2)
                
                'Localiza ENE de uma Estação
                ElseIf (objComboEqp.Text = "Todos" And InStr(arrList_Equipaments(I), "/" & objComboEst.Text & "/") > 0) Then
                    arrArea = Split(Split(arrList_Equipaments(I), ";")(2), "/")
                    sAreaFunc = "Function/" & arrArea(0) & "/" & arrArea(1)
                    
                'Localiza ENE de todas as Estações
                ElseIf (objComboEst.Text = "Todos" And InStr(arrList_Equipaments(I), "/" & objComboEqp.Text & "/") > 0) Or _
                  (InStr(arrList_Equipaments(I), sSub & "/" & objComboEst.Text & "/" & objComboEqp.Text) > 0) Then
                    arrArea = Split(Split(arrList_Equipaments(I), ";")(2), "/")
                    sAreaFunc = "Function/" & arrArea(0) & "/" & arrArea(1) & "/" & arrArea(2)
                    'Exit For
                
                End If
                
                If InStr(sList, sAreaFunc) = 0 Then
                    If sList <> "" Then sList = sList & ";"
                    sList = sList & sAreaFunc
                End If
            Next I
        End If
    Next
    
    If sList <> "" Then FindArea = sList

End Function


Public Function AddGeneralVariables()
    Dim sOPCCluster As String
    
    On Error GoTo ErrorHandler
    
    sOPCCluster = GetOPCCluster

    'used to manage trains
    Variables.Add sOPCCluster & "MainKernelBasic.TrainModule.HMITrainManager.xmlListHMITrain", fvVariableTypeText
    Variables.Add sOPCCluster & "MainKernelBasic.TrainModule.BasicCmd.bstrInterposeBerth", fvVariableTypeText
    Variables.Add sOPCCluster & ".ATR.RegPoint.InitialMaxDwellTimeImposed", fvVariableTypeRegister
    Variables.Add sOPCCluster & ".ATR.RegPoint.InitialMinDwellTimeImposed", fvVariableTypeRegister
    Variables.Add sOPCCluster & ".Detection.Template.Security", fvVariableTypeRegister
    'used for Profiles
    Variables.Add "bAdmin%", fvVariableTypeBit
    Variables.Add "bSupervisor%", fvVariableTypeBit
    Variables.Add "bRegulator%", fvVariableTypeBit
    Variables.Add "bMaintenance%", fvVariableTypeBit
    Variables.Add "bDepotRegulator%", fvVariableTypeBit

    Variables.Add sOPCCluster & "CBIS_15361.Monitor.Template.iEqpState", fvVariableTypeRegister
    Variables.Add sOPCCluster & "CBIS_15361.Monitor.Template.iCommand", fvVariableTypeRegister
    Variables.Add c_strClusterLevel2 & "CATS.ModeMgmt.ModeVal", fvVariableTypeRegister

    'Variables for Playback
    Variables.Add sOPCCluster & "S2KPlayback.Monitor.ReplayMode", fvVariableTypeBit
    Variables.Add sOPCCluster & "S2KPlayback.Monitor.ReplaySpeed", fvVariableTypeRegister
    Variables.Add sOPCCluster & "S2KPlayback.Monitor.DBreakPointDate", fvVariableTypeText
    Variables.Add c_strClusterLevel2 & "S2KPlayback.Monitor.ReplayMode", fvVariableTypeBit
    Variables.Add c_strClusterLevel2 & "S2KPlayback.Monitor.ReplaySpeed", fvVariableTypeRegister
    Variables.Add c_strClusterLevel2 & "S2KPlayback.Monitor.DBreakPointDate", fvVariableTypeText
    
    'Line control
    Variables.Add sOPCCluster & "CATS.KB.ModeMgmt.Mode", fvVariableTypeRegister
    Variables.Add sOPCCluster & "LATS.KB.ModeMgmt.Mode", fvVariableTypeRegister

    Exit Function
    
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "AddGeneralVariables", Err.Description)
    

End Function

Public Function GetHMITrainOPCNameFromBerth(ByVal sOPCBerth As String) As String
    Dim xmlDoc As DOMDocument
    Dim pNode As IXMLDOMNode
    Dim sQuery As String
    Dim pElement        As IXMLDOMElement
    Dim I As Integer, iTrain As Integer
    Dim sOPCCluster As String
    
    On Error GoTo ErrorHandler
    
    sOPCCluster = GetOPCCluster
    sOPCBerth = Replace(sOPCBerth, sOPCCluster, "")

    Set xmlDoc = New DOMDocument
'    xmlDoc.loadXML Variables("OPCCluster:IconisMain.HMITrainModule.HMITrainManager.xmlListHMITrain").Value
    xmlDoc.loadXML Variables("OPCCluster:MainKernelBasic.TrainModule.HMITrainManager.xmlListHMITrain").Value
    
    sQuery = "//Train[@HeadLocation=" & Chr(34) & sOPCBerth & ".TrackPortion" & Chr(34) & "]"
    Set pNode = xmlDoc.selectSingleNode(sQuery)
    
    GetHMITrainOPCNameFromBerth = pNode.Attributes.getNamedItem("HMITrainOPCName").nodeValue
    If GetHMITrainOPCNameFromBerth <> "" Then GetHMITrainOPCNameFromBerth = sOPCCluster & GetHMITrainOPCNameFromBerth
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "GetHMITrainOPCName", Err.Description)

End Function

Public Function GetHMITrainID(ByVal sHMITrainOPCName As String) As String
    Dim xmlDoc As DOMDocument
    Dim pNode As IXMLDOMNode
    Dim sQuery As String
    Dim pElement        As IXMLDOMElement
    Dim I As Integer, iTrain As Integer
    Dim sOPCCluster As String
    
    On Error GoTo ErrorHandler

    sOPCCluster = GetOPCCluster
    sHMITrainOPCName = Replace(sHMITrainOPCName, sOPCCluster, "")

    Set xmlDoc = New DOMDocument
'    xmlDoc.loadXML Variables("OPCCluster:IconisMain.HMITrainModule.HMITrainManager.xmlListHMITrain").Value
    xmlDoc.loadXML Variables("OPCCluster:MainKernelBasic.TrainModule.HMITrainManager.xmlListHMITrain").Value
    
    sQuery = "//Train[@HMITrainOPCName=" & Chr(34) & sHMITrainOPCName & Chr(34) & "]"
    Set pNode = xmlDoc.selectSingleNode(sQuery)
    
    GetHMITrainID = pNode.Attributes(2).nodeValue
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "GetHMITrainID", Err.Description)

End Function


Public Function GetTrainUniqueID(ByVal sOPCHMITrainID As String) As Integer
    Dim xmlDoc As DOMDocument
    Dim pNode As IXMLDOMNode
    Dim sQuery As String
    Dim pElement        As IXMLDOMElement
    Dim I As Integer, iTrain As Integer
    Dim sOPCCluster As String
    
    On Error GoTo ErrorHandler
    
    sOPCCluster = GetOPCCluster
    sOPCHMITrainID = Replace(sOPCHMITrainID, sOPCCluster, "")

    Set xmlDoc = New DOMDocument
'    xmlDoc.loadXML Variables("OPCCluster:IconisMain.HMITrainModule.HMITrainManager.xmlListHMITrain").Value
    xmlDoc.loadXML Variables("OPCCluster:MainKernelBasic.TrainModule.HMITrainManager.xmlListHMITrain").Value
    
    sQuery = "//Train[@HMITrainOPCName=" & Chr(34) & sOPCHMITrainID & Chr(34) & "]"
    Set pNode = xmlDoc.selectSingleNode(sQuery)
    
    GetTrainUniqueID = CInt(pNode.Attributes.getNamedItem("UniqueID").nodeValue)
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "GetHMITrainOPCName", Err.Description)

End Function

Public Function AddTrainVariables(ByVal sTrainOPCTag As String)
'    If Variables(sTrainOPCTag & ".CDViCount%") Is Nothing Then Variables.Add sTrainOPCTag & ".CDViCount%", fvVariableTypeRegister
'    If Variables(sTrainOPCTag & ".TDS.iTrainID") Is Nothing Then Variables.Add sTrainOPCTag & ".TDS.iTrainID", fvVariableTypeRegister
'    If Variables(sTrainOPCTag & ".TDS.bstrHMITrainID") Is Nothing Then Variables.Add sTrainOPCTag & ".TDS.bstrHMITrainID", fvVariableTypeText
'    If Variables(sTrainOPCTag & ".TDS.bstrHeadTC") Is Nothing Then Variables.Add sTrainOPCTag & ".TDS.bstrHeadTC", fvVariableTypeText
'    If Variables(sTrainOPCTag & ".TDS.bstrRollingStockId") Is Nothing Then Variables.Add sTrainOPCTag & ".TDS.bstrRollingStockId", fvVariableTypeText
'    If Variables(sTrainOPCTag & ".HMICOLTrain.bGetTrainInfo") Is Nothing Then Variables.Add sTrainOPCTag & ".HMICOLTrain.bGetTrainInfo", fvVariableTypeRegister
'    If Variables(sTrainOPCTag & ".HMICOLTrain.bstrTrainInfo") Is Nothing Then Variables.Add sTrainOPCTag & ".HMICOLTrain.bGetTrainInfo", fvVariableTypeRegister
    
    If Variables(sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_1") Is Nothing Then Variables.Add sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_1", fvVariableTypeText
    If Variables(sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_5") Is Nothing Then Variables.Add sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_5", fvVariableTypeText
    If Variables(sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_6") Is Nothing Then Variables.Add sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_6", fvVariableTypeText
    If Variables(sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_5") Is Nothing Then Variables.Add sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_5", fvVariableTypeText
    If Variables(sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_6") Is Nothing Then Variables.Add sTrainOPCTag & ".Attributes.HMITETrain.bstrPlug_6", fvVariableTypeText

    If Variables(sTrainOPCTag & ".Attributes.HMITETrain.ustrPlug_2") Is Nothing Then Variables.Add sTrainOPCTag & ".Attributes.HMITETrain.ustrPlug_2", fvVariableTypeText

    If Variables(sTrainOPCTag & ".Attributes.HMITETrain.boolPlug_1") Is Nothing Then Variables.Add sTrainOPCTag & ".Attributes.HMITETrain.boolPlug_1", fvVariableTypeRegister
'    If Variables(sTrainOPCTag & ".PropertyBag_EvacuationStatus.LongValue") Is Nothing Then Variables.Add sTrainOPCTag & ".PropertyBag_EvacuationStatus.LongValue", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".EvacuationStatus.HMIPropertyBag.LongValue") Is Nothing Then Variables.Add sTrainOPCTag & ".EvacuationStatus.HMIPropertyBag.LongValue", fvVariableTypeRegister
    
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.doublePlug_1") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.doublePlug_1", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.boolPlug_1") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.boolPlug_1", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.boolPlug_2") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.boolPlug_2", fvVariableTypeRegister
    
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_1") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_1", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_2") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_2", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_3") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_3", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_4") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_4", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_5") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_5", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_6") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_6", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_7") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_7", fvVariableTypeRegister
    If Variables(sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_8") Is Nothing Then Variables.Add sTrainOPCTag & ".GDLL3Attributes.HMITETrain.longPlug_8", fvVariableTypeRegister
    
End Function


Public Function SendTrainInterposeCmd(ByVal sCommand As String) As Boolean
    Dim sOPCCluster As String
    
    On Error GoTo ErrorHandler
    
    If sCommand = "" Then Exit Function
    sOPCCluster = GetOPCCluster
    
    If VerifyVariable(Variables(sOPCCluster & "MainKernelBasic.TrainModule.BasicCmd.bstrInterposeBerth")) Then
        Variables(sOPCCluster & "MainKernelBasic.TrainModule.BasicCmd.bstrInterposeBerth").Value = sCommand
        SendTrainInterposeCmd = True
    End If

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "GetHMITrainID", Err.Description)

End Function

Public Function Read_UserNote()
On Error Resume Next

    Dim InputData As String
    
    If [UserNoteMsg%] Is Nothing Then Variables.Add "UserNoteMsg%", fvVariableTypeText
    If [bUserNote%] Is Nothing Then Variables.Add "bUserNote%", fvVariableTypeText
        
    Open ThisProject.Path & "\JAR Files\UserNote.txt" For Input As #1    ' Open file for input.

    [UserNoteMsg%] = ""
    Do While Not EOF(1)                 'Check for end of file.
        Line Input #1, InputData        'Read line of data.
        [UserNoteMsg%] = [UserNoteMsg%] & InputData & Chr(10)         'Print to the local variable.
    Loop
    Close #1    'Close file.

    [bUserNote%] = Len([UserNoteMsg%]) > 1

End Function

'Variables used to set the equipment in maintenance
Public Function AddPointVariables(ByVal sOPCTag As String)
    On Error GoTo ErrorHandler
    
    If Variables(sOPCTag & ".INHIBIT.Status.Value") Is Nothing Then Variables.Add sOPCTag & ".INHIBIT.Status.Value", fvVariableTypeRegister
    If Variables(sOPCTag & ".Detection.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".Detection.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMI.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMI.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMIBlocking.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMIBlocking.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMIControl.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMIControl.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMILocal.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMILocal.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMILocked.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMILocked.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMINormal.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMINormal.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMIReverse.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMIReverse.Template.bIsOn", fvVariableTypeRegister
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "AddPointVariables", Err.Description)
End Function


'Variables used to set the equipment in maintenance
Public Function AddSignalVariables(ByVal sOPCTag As String)
    On Error GoTo ErrorHandler
    
    If Variables(sOPCTag & ".INHIBIT.Status.Value") Is Nothing Then Variables.Add sOPCTag & ".INHIBIT.Status.Value", fvVariableTypeRegister
    If Variables(sOPCTag & ".Detection.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".Detection.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMIApproachLocking.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMIApproachLocking.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMIBlocking.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMIBlocking.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMIFilament.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMIFilament.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMILampCommand.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMILampCommand.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMILampCommandPermissive.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMILampCommandPermissive.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMILampCommandRestrictive.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMILampCommandRestrictive.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMILampProvedPermissive.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMILampProvedPermissive.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMILampProvedRestrictive.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMILampProvedRestrictive.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMINormalRoute.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMINormalRoute.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMIPermanentRoute.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMIPermanentRoute.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMIRouteRelease.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMIRouteRelease.Template.bIsOn", fvVariableTypeRegister
    If Variables(sOPCTag & ".HMIRouteSignal.Template.bIsOn") Is Nothing Then Variables.Add sOPCTag & ".HMIRouteSignal.Template.bIsOn", fvVariableTypeRegister
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "AddSignalVariables", Err.Description)
End Function








'* Subroutine: ReadServiceLoop
'*  Take the Loop associated to the selected service
'*  Params: p_ServiceSelected (Service Selected) - byval
'*          p_ServiceLoops (List of loops associated to the service) - byref
'* ********************************************************************************
Private Function ReadServiceLoop(ByVal p_ServiceSelected As Integer, ByRef p_ServiceLoop() As ServiceLoops)
On Error GoTo ErrorHandler
Dim intCountLoop    As Integer
Dim intCountMvt     As Integer
Dim arrLoops()      As String
Dim arrMvt()        As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_SP_Funcoes", "ReadServiceLoop", "Begin Subroutine")
    
    Dim oDoc As DOMDocument

    Set oDoc = New DOMDocument
    '* Load the XML string
    If (oDoc.loadXML(m_OPC_CarouselConfOperatingModeList.Value) = True) Then
        Dim FirstNodeLevel As IXMLDOMNodeList
        
        '* Get all <NextMode ...> nodes
        Set FirstNodeLevel = oDoc.documentElement.getElementsByTagName("NextMode")
        If (FirstNodeLevel.length > 0) Then
            Dim oNextModeNodeClass As IXMLDOMElement
            
            For Each oNextModeNodeClass In FirstNodeLevel
                Dim strName As String
                Dim strIndex As String
                Dim strType As String
                Dim strLoopList As String
                Dim strMvtList  As String
                '* Get attributes (Index, LoopList and Mvt)of the service
                strIndex = Format(oNextModeNodeClass.getAttribute("Index"))
                strLoopList = Format(oNextModeNodeClass.getAttribute("Loops"))
                strMvtList = Format(oNextModeNodeClass.getAttribute("Movements"))
                
                
                If ((strLoopList <> "") And (strMvtList <> "") And (strIndex = CStr(p_ServiceSelected))) Then
                    '* Note : if attribute type has not been configurated, the type of service by default is "Nominal"
                    arrLoops = Split(strLoopList, "|")
                    ReDim p_ServiceLoop(UBound(arrLoops))
                    For intCountLoop = LBound(arrLoops) To UBound(arrLoops)
                        
                        'Get Loop Information
                        p_ServiceLoop(intCountLoop).Id = arrLoops(intCountLoop)
                        p_ServiceLoop(intCountLoop).Mvts = Split(strMvtList, "|")(intCountLoop)
                        arrMvt = Split(p_ServiceLoop(intCountLoop).Mvts, ";")
                        
                        'Resize Loop array with the mvts
                        ReDim Preserve p_ServiceLoop(intCountLoop).MvtList(UBound(arrMvt))
                        
                        'Take the information about the mouvement associated to the loop
                        For intCountMvt = LBound(arrMvt) To UBound(arrMvt)
                            p_ServiceLoop(intCountLoop).MvtList(intCountMvt).InitialManeuverId = Split(arrMvt(intCountMvt), ",")(0)
                            p_ServiceLoop(intCountLoop).MvtList(intCountMvt).PatternId = Split(arrMvt(intCountMvt), ",")(1)
                        Next intCountMvt
                        
                    Next intCountLoop
                    
                End If
            Next
        End If
        Set FirstNodeLevel = Nothing
    End If
    Set oDoc = Nothing
        
    Call CBTrace(CBTRACE_VBA, "MOD_SP_Funcoes", "ReadServiceLoop", "End Subroutine")
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "ReadServiceLoop", "EXCEPTION: " & Err.Description)
End Function

'* Subroutine: CreateXMLTPMConfiguration
'*  Create the xml with the parameters to change the TPBMgr
'* ********************************************************************************
Private Function CreateXMLTPMConfiguration(Optional ByVal iServiceID As Integer, Optional ByVal sParamRegulation As String) As String
On Error GoTo ErrorHandler
Dim ServiceLoop()       As ServiceLoops
Dim intCountLoops       As Integer
Dim intCountMvts        As Integer
Dim oDoc                As DOMDocument
Dim oParameters         As IXMLDOMElement
Dim oPath               As IXMLDOMElement
Dim oAttribute          As IXMLDOMAttribute
    'Call Mimic_Open
    'Call ReadServiceLoop(m_Local_AutoWithoutTTParamService.Value, ServiceLoop)
    Call ReadServiceLoop(iServiceID, ServiceLoop)
    
    Set oDoc = New DOMDocument
    Set oParameters = oDoc.createElement("Parameters")
    Set oPath = oDoc.createElement("Path")
    oParameters.appendChild oPath
    
    'With one <Path Mode="Mode"> element per pattern involved in the selected service
    oPath.setAttribute "Mode", 0

    For intCountLoops = LBound(ServiceLoop) To UBound(ServiceLoop)
        
        For intCountMvts = LBound(ServiceLoop(intCountLoops).MvtList) To UBound(ServiceLoop(intCountLoops).MvtList)
            Set oPath = oDoc.createElement("Path")
                
                '- Mode = 2 if the pattern is part of a loop configured in constant headway regulation, 3 for dwell time
'                oPath.setAttribute "Mode", GetModeType(m_Local_AutoWithoutTTParamRegulation.Value)
                oPath.setAttribute "Mode", GetModeType(sParamRegulation)
                
                '- PatternID = Identifier of the pattern from the loop
                oPath.setAttribute "TPBPatternID", ServiceLoop(intCountLoops).MvtList(intCountMvts).PatternId
                
                '- InitialID = Identifier of the initial maneuver related to the pattern, attribute not generated if initial maneuver is 0
                If CStr(ServiceLoop(intCountLoops).MvtList(intCountMvts).InitialManeuverId) <> "0" Then
                    
                    oPath.setAttribute "InitialMvtID", CStr(ServiceLoop(intCountLoops).MvtList(intCountMvts).InitialManeuverId)
                    
                End If
                
                oPath.setAttribute "InstanciationMode", "4"
                
                'if mode is DWELLTIME DO NOT add attribute
'                If GetModeType(m_Local_AutoWithoutTTParamRegulation.Value) <> 3 Then
                If GetModeType(sParamRegulation) <> 3 Then
                    
                    oPath.setAttribute "SpacingValue", "DeducedFromSelectedHeadways"
                    
                End If
                
                oParameters.appendChild oPath
                
        Next intCountMvts
        
    Next intCountLoops
    oDoc.appendChild oParameters
    
    CreateXMLTPMConfiguration = oDoc.xml
    
    Set oDoc = Nothing

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "CreateXMLTPMConfiguration", "EXCEPTION: " & Err.Description)
End Function

'* Subroutine: SendCommand
'*  Contains the commands that will be send to the server
'* ********************************************************************************
Public Function SendCommand(ByVal intCmd As Integer, Optional ByVal iServiceID As Integer, Optional ByVal iStrategyID As Integer, _
                            Optional ByVal sParamRegulation As String)
    Dim sCATSorLATS As String
    Dim HDWCommand As New HDW.IHeadwayConfigurationCtrl

    On Error GoTo ErrorHandler
    
    Call CBTrace(CBTRACE_VBA, "MOD_SP_Funcoes", "SendCommand", "Begin Subroutine")
    
    
    sCATSorLATS = "CATS"
    
    Select Case intCmd
        Case 1 'Manual
        
            Variables.Item(c_strClusterLevel2 & c_strCarouselConfOperatingModeList).Value = 0
            Variables.Item(c_strClusterLevel2 & c_strCmdOperModeTPBMgrConfig).Value = "<Parameters><Path Mode=" & Chr(34) & "0" & Chr(34) & "/></Parameters>"
            Variables.Item(c_strClusterLevel2 & sCATSorLATS & c_strCmdOperModeMgmtMode).Value = 0
            
'''            m_OPC_CmdOperModeCarouselConfigMode.Value = 0
'''            m_OPC_CmdOperModeTPBMgrConfig.Value = "<Parameters><Path Mode=" & Chr(34) & "0" & Chr(34) & "/></Parameters>"
'''            m_OPC_CmdOperModeMgmtMode.Value = 0
            '[ATS_CF_UO_SyAD_581]
            '    On MainUO.CarouselsConfiguration.Mode the value 0
            '    On MainUO.TPBModule.TPBMgr.Configuration plug <Parameters><Path Mode="0"/></Parameters>
            '    On CATS.ModeMgmt.Mode plug the value 0

        Case 2 'Automatic With TT
            
            Variables.Item(c_strClusterLevel2 & c_strCarouselConfOperatingModeList).Value = 0
            Variables.Item(c_strClusterLevel2 & c_strCmdOperModeTPBMgrConfig).Value = "<Parameters><Path Mode=" & Chr(34) & "0" & Chr(34) & "/><Path Mode=" & Chr(34) & "1" & Chr(34) & " TPBPatternID=" & Chr(34) & "DeducedFromTimetable" & Chr(34) & "/></Parameters>"
            Variables.Item(c_strClusterLevel2 & sCATSorLATS & c_strCmdOperModeMgmtMode).Value = 2
            Variables.Item(c_strClusterLevel2 & c_strCmdAutoWithTTRegulation).Value = 0 'm_Local_AutoWithTTParam.Value
            
'''            m_OPC_CmdOperModeCarouselConfigMode.Value = 0
'''            m_OPC_CmdOperModeTPBMgrConfig.Value = "<Parameters><Path Mode=" & Chr(34) & "0" & Chr(34) & "/><Path Mode=" & Chr(34) & "1" & Chr(34) & " TPBPatternID=" & Chr(34) & "DeducedFromTimetable" & Chr(34) & "/></Parameters>"
'''            m_OPC_CmdOperModeMgmtMode.Value = 2
'''            m_OPC_CmdAutoWithTTRegulation.Value = m_Local_AutoWithTTParam.Value
            '[ATS_CF_UO_SyAD_581]
            'Before changing the line operating mode to Automatic with Timetable mode, HMI shall first ensure that a timetable is loaded by checking either that a timetable was loaded previously and or that the timetable loading was succesful (see F1).
            '[ATS_CF_UO_SyAD_582]
            'If a timetable is loaded, to switch to Automatic with Timetable mode, HMI shall write:
            '    On MainUO.CarouselsConfiguration.Mode the value 0
            '    On MainUO.TPBModule.TPBMgr.Configuration plug <Parameters><Path Mode="0"/><Path Mode="1" TPBPatternID="DeducedFromTimetable"/></Parameters>
            '    On CATS.ModeMgmt.Mode plug the value 2
            '    On MainKernelExtended.ATRModule.ATRTPMA.AtrExtendedMode the value 0 for ScheduleRegulation, the value 1 for Schedule and Headway regulation.

        Case 3 'Automatic Without TT
            'MsgBox "COMMAND - Automatic Without TT"
            'MsgBox "m_Local_AutoWithoutTTParamRegulation.Value:" & m_Local_AutoWithoutTTParamRegulation.Value
            
            '[ATS_CF_UO_SyAD_1200]
            '    Select the set of carousels (see F2.1)
            Variables.Item(c_strClusterLevel2 & "MainUO.CarouselsConfiguration.Mode").Value = iServiceID 'the identifier of the service (Index from NextOperatingModesList).
            
            '    Select the regulation strategy (see F2.2)
            Variables.Item(c_strClusterLevel2 & "MainKernelExtended.TPMModule.TPMTPC.TripTimes").Value = iStrategyID 'Id of regulation strategy
            
            '    Select the headway (see F2.3)
            HDWCommand.SetHeadways iStrategyID, sParamRegulation 'CStr(m_Local_AutoWithoutTTParamRegulation.Value) 'Example: "3;0"
            
            '    Write on MainUO.TPBModule.TPBMgr.Configuration plug:
            Variables.Item(c_strClusterLevel2 & "MainUO.TPBModule.TPBMgr.Configuration").Value = CreateXMLTPMConfiguration(iServiceID, sParamRegulation) 'Id of regulation strategy
            
            '    Write on CATS.ModeMgmt.Mode plug the value 1.
            m_OPC_CmdOperModeMgmtMode.Value = 1
            
            '
            'The loops, patterns and initial/final maneuvers are found in MainUO.CarouselsConfiguration.NextOperatingModesList (see F2.1).
        Case Else
        
    End Select
    
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "SendCommand", "End Subroutine")

    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "SendCommand", "EXCEPTION: " & Err.Description)

End Function

'* Function: GetServiceID
'* Purpose: Retrieve the ID of the selected service in the combo box (nominal or provisional)
'* ******************************************************************************************
Private Function GetServiceID() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, ThisMimic.Name, "GetServiceID", "Begin Function")
    
    Dim IDsArray
    Dim NamesArray
    Dim I As Integer
    Dim strServiceID As String
        
    
        '* Get the array containing IDs of nominal services
        IDsArray = m_collStrategy.Keys
        '* Get the array containing Names of nominal services
        NamesArray = m_collStrategy.Items
        For I = 0 To m_collStrategy.Count - 1
            If (StrComp(NamesArray(I), cbDwellTimesRunningTimes.Value, vbTextCompare) = 0) Then
                strServiceID = IDsArray(I)
                Exit For
            End If
        Next I
        
    GetServiceID = strServiceID
        
    Call CBTrace(CBTRACE_VBA, ThisMimic.Name, "GetServiceID", "End Function")
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "GetServiceID", "EXCEPTION: " & Err.Description)
End Function

Private Function GetModeType(ByVal p_strParamRegulation As String) As Integer
On Error GoTo ErrorHandler
Dim arrLoops()          As String
Dim arrLoopHeadway()    As String
Dim intLoops            As Integer
Dim intLoopsHeadway     As Integer

    arrLoopHeadway = Split(p_strParamRegulation, "|")
    
    For intLoops = LBound(arrLoopHeadway) To UBound(arrLoopHeadway)
            
        intLoopsHeadway = Split(arrLoopHeadway(intLoops), ";")(1)
        
        If intLoopsHeadway <> 0 Then
            '2 for headway
            GetModeType = 2
            Exit Function
            
        Else
            '3 for dwell time
            GetModeType = 3
            
        End If
                
    
    Next intLoops
    
    
    Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_SP_Funcoes", "GetModeType", "EXCEPTION: " & Err.Description)
End Function


'-----------------------------------------------------------------------------
' <summary>
'     Sub to Wait Process in one determines time
' </summary>
' <param name=MSeconds As Integer>
'     MiliSeconds to Wait
' </param>
' <remarks></remarks>
'-----------------------------------------------------------------------------
Public Sub WaitSeconds(MSeconds As Integer)
    On Error GoTo ErrorHandler
    Dim Start As Long, Temp As Integer
    
    Start = GetTickCount()
    While GetTickCount() < Start + MSeconds + 1
        Temp = DoEvents()
    Wend
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_GlobalUnblockHILCCtrl", "WaitSeconds", Err.Description)
End Sub
