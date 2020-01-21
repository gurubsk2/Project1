Attribute VB_Name = "Mod_General"
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Project: Taichung Green Line
'* *******************************************************************************************
'* Purpose: Module: MOD_General
'* *******************************************************************************************
'* Modification History:
'* Author:              Geeta Tegginamani
'* Description:         To manage the general functions invloved in the project
'* Date:                June 2014

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION()
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION
'* *******************************************************************************************

Option Explicit

'* Public variables
Dim ShortName() As String
Public strMimicName As String ' For Storing Active mimic name for Train Compact

'* Public Constants
Public Const c_lScreenWidth As Integer = 1920
Public Const c_lScreenHeight As Integer = 1200
Public Const c_strClusterLevel2 As String = "OPCClusterATSLV2:"
Public Const c_strClusterLevel1 As String = "OPCCluster:"
Private Const c_sServerSeparator As String = ":"

Public xpos As Long ' FOr Displaying Mimic @ Center of Activ Mimic

Declare Function GetCursorPos Lib "user32" (lbPoint As POINTAPI) As Long
Public Type POINTAPI
    lXpos As Long
    lYpos As Long
End Type

Public Type STATIONEQP
    StationName As String
    EqpFlavour As String
    EqpType As String
    EqpID As String
    EqpCommand1 As String
    EqpCommandVal As Integer
    Delay As String
End Type

Public m_layervalue As Long
Public SDetails As STATIONEQP
Private Const c_lBannerHeight As Integer = 258
Public TrainstrBranch As String
'* ******************************************************************************************
'*  SubRoutine: GetMonitors
'*    Get the number of monitors used
'* ******************************************************************************************
Public Sub GetMonitors()
On Error GoTo ErrorHandler
Dim I As Integer
    I = ThisSystem.HorizontalResolution
    If (I > (c_lScreenWidth * 3)) Then
        ThisProject.Monitors = 4
        Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetMonitors", "HMI runs with 4 Monitor")
    ElseIf ((I > (c_lScreenWidth * 2))) Then
        ThisProject.Monitors = 3
        Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetMonitors", "HMI runs with 3 Monitors")
    ElseIf ((I > (c_lScreenWidth * 1))) Then
        ThisProject.Monitors = 2
        Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetMonitors", "HMI runs with 2 Monitors")
    Else
        ThisProject.Monitors = 1
        Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetMonitors", "HMI runs with 1 Monitors")
    End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetMonitors", Err.Description)
End Sub

'* ******************************************************************************************
'*  SubRoutine: OpenDefaultMimics
'*    Open default mimics on the monitors
'* ******************************************************************************************


 Public Sub OpenDefaultMimics()

On Error GoTo ErrorHandler

    '* Open the Mimics according to the Monitors connected to the syste
    If (((ThisSystem.ComputerName) Like "TLLIHMTTR1")) Then
    ' If (((ThisSystem.ComputerName) Like "Simu_DEPOT")) Then
   Variables.Item("@Loading_Progress%").Value = 20
    TheseMimics.Open "GDL_Depot_Welcome_View", , , , , , , , 0, 0, True
    'TheseMimics.Open "GDL_DepotDetailed_view", , , , , , , , 0, 200, True
    TheseMimics.Open "GDL_DepotDetailed_view", , , , "GDL_Depot_Welcome_View", , , , 0, 200, True
    Variables.Item("@Loading_Progress%").Value = 75
    Else
'        If Not (Mimics.IsOpened("GDL_Operational_View")) Then
            ' Open initialization layout
                        TheseMimics.Open "GDL_Initial_View", "M3", , , , , , , 3840, 0, True
                        Variables.Item("@Loading_Progress%").Value = 20
            TheseMimics.Open "GDL_Initial_View", "M2", , , , , , , 1920, 0, True
                        Variables.Item("@Loading_Progress%").Value = 50
            TheseMimics.Open "GDL_Initial_View", "M1", , , , , , , 0, 0, True
            Variables.Item("@Loading_Progress%").Value = 75
                
        
        ''            ' Open operational layout, and hide it
''            TheseMimics.Open "GUA_Geral", , , , , , , , 0, 242, True
            
   End If
    
    
    'To Do, if needed preload of every view
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "OpenDefaultMimics", Err.Description)
End Sub
   '* ******************************************************************************************
'*  SubRoutine: Mimic_ShortName
'*    Get the shortname of the equipment
'* ******************************************************************************************
Public Function Mimic_ShortName(MimicView As Mimic)
    On Error GoTo ErrorHandler
    
        Dim myitem As Graphic
        Dim MySubItem As Graphic
        Dim MyLabel As Graphic
        Dim TheLabel As String
        Dim ArrayName() As String
        Dim iCount As Long
        Dim jCount As Long
        Dim SymbolBranch As String
                
        'Short Names for Signals, Points, Stations, SDD and GAMA Zones
          
        For iCount = 1 To MimicView.Graphics.Count Step 1
              
            Set myitem = MimicView.Graphics.Item(iCount)
             
                If TypeOf myitem Is Symbol Then
               
                    If (myitem.FileName <> " ") Then
                    
                'For Signals
                      If (myitem.FileName Like "S_*") Then
                      SymbolBranch = myitem.LocalBranch
                      Mod_General.SetSignalShortName (SymbolBranch)
                        'MyItem.FileName Like "Signal_Up_Right_Status_Small_Ident" Or _

                               
                    


                'For Buffer Signals
                    ElseIf (myitem.FileName Like "SI_*") Then
                      SymbolBranch = myitem.LocalBranch
                      Mod_General.SetBufferSignalShortName (SymbolBranch)
                        
                'For Points
                    ElseIf (myitem.FileName Like "Point_*") Then
                           SymbolBranch = myitem.LocalBranch
                        Mod_General.SetPointShortName (SymbolBranch)
                        
                  'For Derail Points
                    ElseIf (myitem.FileName Like "Derail_*") Then
                           SymbolBranch = myitem.LocalBranch
                        Mod_General.SetPointShortName (SymbolBranch)
                        
                'For Stations
                    ElseIf (myitem.FileName Like "Station_MGV_Display") Or (myitem.FileName Like "Station_MDV_Display") Then
                    
                        SymbolBranch = myitem.LocalBranch
                        Mod_General.SetStationShortName (SymbolBranch)

                'For SDD's
                    ElseIf (myitem.FileName Like "SDD_Status") Then
                        SymbolBranch = myitem.LocalBranch
                        Mod_General.SetSDDShortName (SymbolBranch)
     
     
                    ElseIf (myitem.FileName Like "SDD_Status_Depot") Then
                        SymbolBranch = myitem.LocalBranch
                        Mod_General.SetSDDShortNameDepot (SymbolBranch)
    
                'For GAMA Zones
                    ElseIf (myitem.FileName Like "GAMAZone*") Then
                        SymbolBranch = myitem.LocalBranch
                        Mod_General.SetGAMAZoneShortName (SymbolBranch)
                        
                'For Cycles
                    ElseIf (myitem.FileName Like "CY_*") Then
                      SymbolBranch = myitem.LocalBranch
                      Mod_General.SetCycleShortName (SymbolBranch)
                      
                'For Kochi_Station_Button_Banner
                
                    ElseIf (myitem.FileName Like "GDL_Station_Button*") Then
                      SymbolBranch = myitem.LocalBranch
                      Mod_General.SetStationBannerShortName (SymbolBranch)
                      
                'For Block Id
                    ElseIf (myitem.FileName Like "B_*") Or (myitem.FileName Like "Block_*") Then
                      SymbolBranch = myitem.LocalBranch
                      Mod_General.SetBlockIdentifierShortName (SymbolBranch)
                      
                'For Platform Id
                    ElseIf (myitem.FileName Like "PF_*") Then
                      SymbolBranch = myitem.LocalBranch
                      Mod_General.SetPlatFormShortName (SymbolBranch)
    
                    End If
                   End If
                End If
        Next
        Exit Function
ErrorHandler:

        Call CBTrace(CBTRACEF_ALWAYS, "TGL_MainLine_Detailed_View", "Mimic_ShortName", Err.Description)
    End Function
'* ******************************************************************************************
'*  SubRoutine: GetWorkStationName
'*    Get the name of the workstation
'* ******************************************************************************************
Public Sub GetWorkStationName()
On Error GoTo ErrorHandler

    Dim WorkStationName As String
    Dim StationCode As String
    Dim ArrayMachineName() As String
    
    WorkStationName = ThisSystem.ComputerName
    
    ArrayMachineName = Split(WorkStationName)
    StationCode = ArrayMachineName(0)
    ThisProject.WKSName = StationCode

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetWorkStationName", Err.Description)
End Sub
'* ******************************************************************************************
'*  SubRoutine: GeneralViewPlatformName
'*    Get the short name of the Platform
'* ******************************************************************************************
Public Sub SetPlatFormShortName(ByVal SymbolName As String)
On Error GoTo ErrorHandler

    ShortName = Split(SymbolName, ":")
    
       If ShortName(0) <> "" And ShortName(1) <> "" Then
        Call Variables.Add(SymbolName & ".Shortname%", fvVariableTypeText)
        Variables.Item(SymbolName & ".Shortname%").Value = ShortName(1)
     End If
    

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetPlatFormShortName", Err.Description)
End Sub
'* ******************************************************************************************
'*  SubRoutine: GetApplicationName
'*    Get the name of the application
'* ******************************************************************************************
Public Sub GetApplicationName()

    On Error GoTo ErrorHandler
    Dim OPCVar As Variable
    
    Dim ApplicationName As String
    Set OPCVar = Variables.Add(Iconis_MOD_General.GetOPCCluster & "IconisS2K.Core.ServerState.Core.ServerState.Core.ApplicationName", fvVariableTypeText)
    ApplicationName = Variables.Add(Iconis_MOD_General.GetOPCCluster & "IconisS2K.Core.ServerState.Core.ServerState.Core.ApplicationName").Value
    ThisProject.APPName = ApplicationName
   
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "GetApplicationName", Err.Description)
End Sub


'* ******************************************************************************************
'*  SubRoutine: SetSignalShortName
'*    Get the name of the signal
'* ******************************************************************************************

Public Sub SetSignalShortName(SymbolBranch As String)
On Error GoTo ErrorHandler
    
    ShortName = Split(SymbolBranch, "_")
    Variables.Item(SymbolBranch + ".shortname%").Value = ShortName(1)
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetSignalShortName", Err.Description)
End Sub

'* ******************************************************************************************
'*  SubRoutine: SetCycleShortName
'*    Get the name of the signal
'* ******************************************************************************************

Public Sub SetCycleShortName(SymbolBranch As String)
On Error GoTo ErrorHandler
    
    ShortName = Split(SymbolBranch, "_")
    Variables.Item(SymbolBranch + ".shortname%").Value = "CY" & "-" + ShortName(1) & "-" + ShortName(2)
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetSignalShortName", Err.Description)
End Sub
'* ******************************************************************************************
'*  SubRoutine: SetBufferSignalShortName
'*    Get the name of the signal
'* ******************************************************************************************
'* ******************************************************************************************
'*  SubRoutine:  Block Identifier
'*    Get the name of the Block Identifier
'* ******************************************************************************************
Public Sub SetBlockIdentifierShortName(SymbolBranch As String)
On Error GoTo ErrorHandler

    ShortName = Split(SymbolBranch, "_")
    Variables.Item(SymbolBranch + ".shortname%").Value = ShortName(1)
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetBlockIdentifierShortName", Err.Description)
End Sub
Public Sub SetBufferSignalShortName(SymbolBranch As String)
On Error GoTo ErrorHandler
    
    ShortName = Split(SymbolBranch, "_")
    Variables.Item(SymbolBranch + ".shortname%").Value = ShortName(1)
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetBufferSignalShortName", Err.Description)
End Sub
'* ******************************************************************************************
'*  SubRoutine: SetPointShortName
'*    Get the name of the POint
'* ******************************************************************************************
Public Sub SetPointShortName(SymbolBranch As String)
On Error GoTo ErrorHandler
Dim strPointName As String

    ShortName = Split(SymbolBranch, "_")
       If ShortName(1) <> "" Then
            If ShortName(1) = "DH" And ShortName(2) = "03" Then
            strPointName = "D3"
            Variables.Item(SymbolBranch + ".shortname%").Value = strPointName
            Exit Sub
            ElseIf ShortName(1) = "DH" And ShortName(2) = "01" Then
            strPointName = "D1"
             Variables.Item(SymbolBranch + ".shortname%").Value = strPointName
            Exit Sub
            End If
        strPointName = ShortName(1)
       End If
        Variables.Item(SymbolBranch + ".shortname%").Value = strPointName
    
   
   
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetPointShortName", Err.Description)
End Sub
Public Function Get_OPCClusterName(sLocalBranch As String) As String
On Error GoTo ErrorHandler
Dim sTemp() As String
    If InStr(1, sLocalBranch, c_sServerSeparator) Then
        sTemp() = Split(sLocalBranch, c_sServerSeparator)
        Get_OPCClusterName = sTemp(0)
    Else
        Get_OPCClusterName = ""
    End If
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Get_OPCClusterName", "CloseMimic", Err.Description)
End Function

'* ******************************************************************************************
'*  SubRoutine: SetGAMAZoneShortName
'*    Get the name of the GAMA zone
'* ******************************************************************************************
Public Sub SetGAMAZoneShortName(SymbolBranch As String)
On Error GoTo ErrorHandler
    
    ShortName = Split(SymbolBranch, "_")
    If UBound(ShortName) > 2 Then
        Variables.Item(SymbolBranch + ".shortname%").Value = ShortName(1) & "-" + ShortName(2) & "-" + ShortName(3)
    Else
        Variables.Item(SymbolBranch + ".shortname%").Value = ShortName(1)
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetGAMAZoneShortName", Err.Description)
End Sub

'* ******************************************************************************************
'*  SubRoutine: SetGAMAZoneShortName
'*    Get the name of the GAMA zone
'* ******************************************************************************************
Public Sub SetGAMAZoneShortName_1(SymbolBranch As String)
On Error GoTo ErrorHandler
    
    ShortName = Split(SymbolBranch, "_")
    If UBound(ShortName) > 1 Then
        Variables.Item(SymbolBranch + ".shortname%").Value = ShortName(1) & "-" + ShortName(2)
    Else
        Variables.Item(SymbolBranch + ".shortname%").Value = ShortName(1)

    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetGAMAZoneShortName", Err.Description)
End Sub

'* ******************************************************************************************
'*  SubRoutine: SetTCShortName
'*    Get the short name of the Track Circuit
'* ******************************************************************************************
Public Sub SetTCShortName(ByVal SymbolName As String, ByVal SymbolBranch As String)
On Error GoTo ErrorHandler

    ShortName = Split(SymbolName, "_")
    If UBound(ShortName) > 1 Then
        Variables.Item(SymbolName + ".shortname%").Value = ShortName(2)
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetTCShortName", Err.Description)
End Sub


'* ******************************************************************************************
'*  SubRoutine: Set StationName
'*    Get the short name of the Stations
'* ******************************************************************************************
Public Sub SetStationShortName(ByVal SymbolName As String)
On Error GoTo ErrorHandler

    ShortName = Split(SymbolName, "_")
    
        Variables.Item(SymbolName + ".shortname%").Value = ShortName(1)
    

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetStationShortName", Err.Description)
End Sub

'* ******************************************************************************************
'*  SubRoutine: SetSDDName
'*    Get the short name of the SDD's for MainLine
'* ******************************************************************************************
Public Sub SetSDDShortName(ByVal SymbolName As String)
On Error GoTo ErrorHandler

    ShortName = Split(SymbolName, "_")
     If ShortName(1) <> "" Then
        Variables.Item(SymbolName + ".shortname%").Value = ShortName(1)
     End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetSDDShortName", Err.Description)
End Sub
'* ******************************************************************************************
'*  SubRoutine:  StationBanner
'*    Get the name of the signal
'* ******************************************************************************************
Public Sub SetStationBannerShortName(SymbolBranch As String)
On Error GoTo ErrorHandler
   
    ShortName = Split(SymbolBranch, "_")
    Variables.Item(SymbolBranch + ".shortname%").Value = ShortName(1)
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetStationBannerShortName", Err.Description)
End Sub
'* ******************************************************************************************
'*  SubRoutine: SetSDDName
'*    Get the short name of the SDD's for Depot
'* ******************************************************************************************

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
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "CreateNew_Iconis_CLS_OPCSet", Err.Description)
End Function

'* ********
Public Sub SetSDDShortNameDepot(ByVal SymbolName As String)
On Error GoTo ErrorHandler

    ShortName = Split(SymbolName, "_")
     If ShortName(1) <> "" Then
        Variables.Item(SymbolName + ".shortname%").Value = ShortName(1) & "-" + ShortName(2)
     End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "SetSDDShortName", Err.Description)
End Sub

Public Function CloseMimic(sMimicName As String)
On Error GoTo ErrorHandler
Dim oMimic As Mimic
For Each oMimic In Mimics
    If StrComp(oMimic.FileName, sMimicName, vbTextCompare) = 0 Then
        oMimic.Close fvDoNotSaveChanges
    End If
Next

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "CloseMimic", Err.Description)
End Function
'* *************************************************************************************
'*  Author: Vinay CR
'*  Function: To Open Contextual Menu Based on the Click position.
'* <parameter1 = Symbol opening the Contextual Menu >
'* <parameter2 = Name Of the Contextual Menu to be opened>
'* <parameter3 = Branch for Contextual Menu>
'* <parameter4 = Name of the parent on which Contextual Menu to be opened >
'* <parameter5&6 = Mouse pointer coordinates
'* <parameter5&6 = Symbol coordinates
'* <parameter7&8= Width & Hight of the Contextual Menu to be opened
'   oMimic.tag will have the name of the parent mimic
'* This Function Doesnot Returns Any value.
'**************************************************************************************
'
'
'* Open the Contextual Menu mimic
'*********************************************************************************

'* Check_Variable :Check for Proper Quality of opc variable
'**********************************************************
Public Function Check_Variable(OPCVariable_name As Variable, Optional ByVal strObjName As String = " ") As Boolean
On Error GoTo ErrorHandler
    'Dim bResult As Boolean
    Dim strtemp As String
    
    If (strObjName <> "") Then
        strtemp = "Check_Variable->" & strObjName
     Else
        strtemp = "Check_Variable"
     End If
    Check_Variable = False
    
    If (OPCVariable_name.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "MOD_General", "Check_Variable", "Check fail on variable : " & OPCVariable_name.Name & ". Status Variable is Waiting.")
    ElseIf (OPCVariable_name.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "Check_Variable", "Check fail on variable : " & OPCVariable_name.Name & ". Status Variable is Config Error.")
    ElseIf (OPCVariable_name.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VBA, "MOD_General", "Check_Variable", "Check fail on variable : " & OPCVariable_name.Name & ". Status Variable is Not connected.")
    ElseIf (OPCVariable_name.Quality <> 192) Then
        Call CBTrace(CBTRACE_VBA, "MOD_General", "Check_Variable", "Check fail on variable : " & OPCVariable_name.Name & ". Variable Quality is Bad.")
    Else
        Check_Variable = True
    End If
    
    'Check_Variable = bResult
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "Check_Variable", Err.Description)
End Function

Public Function SetOPCSymbolBranch(MimicView As Mimic)
On Error GoTo ErrorHandler
    
    Dim iCounter, Symbol_Count As Integer, File_Name As String
    Dim STArray() As String
    Dim IsGraphic, myitem As Graphic
    
    Symbol_Count = MimicView.Graphics.Count
    
    iCounter = 1
    For iCounter = 1 To Symbol_Count
    
    Set myitem = MimicView.Graphics.Item(iCounter)
        If TypeOf myitem Is Symbol Then
        
        File_Name = MimicView.Graphics.Item(iCounter).FileName
                    
            If File_Name Like "B_MDV_Down_*" Or File_Name Like "B_MDV_Top_*" Or File_Name Like "Block_*" Or File_Name Like "B_WZViewMainline_*" Then
           
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & Left(MimicView.Graphics(iCounter).Name, 5)
            ElseIf File_Name Like "B_MDV_BufferDirection_Up*" Or File_Name Like "B_MDV_BufferUpDirection" Or File_Name Like "B_MDV__BufferUpDirection_*" Or File_Name Like "B_MDV_BufferDirectionUp_2" Then

            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & Replace(MimicView.Graphics(iCounter).Name, "BFU", "B")

            ElseIf File_Name Like "B_MDV_BufferDirection_Down*" Or File_Name Like "B_MDV_BufferDownDirection" Or File_Name Like "B_MDV__BufferDownDirection_*" Or File_Name Like "B_MDV_BufferDirectionDown_2" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & Replace(MimicView.Graphics(iCounter).Name, "BFD", "B")
            
             ElseIf File_Name Like "*SubRoute*" Then
             MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name



            ElseIf File_Name Like "B_DDV_*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & Left(MimicView.Graphics(iCounter).Name, 5)
            
            ElseIf File_Name Like "B_GV_*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:@" & Left(MimicView.Graphics(iCounter).Name, 5)

            ElseIf File_Name Like "*Station_WZV_Display" Or File_Name Like "Station_MDV_Display" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "Station_MGV_Display" Then

            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:@" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "Point_*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "GV_*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:@" & MimicView.Graphics(iCounter).Name
            'ElseIf File_Name Like "PT_Point_Status_Top_Left_With_Identification_RN*" Then
            'MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "S_*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name
            
            ElseIf File_Name Like "SI_*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "RN_*" Or File_Name Like "RP_*" Or File_Name Like "RR_*" Or File_Name Like "FR_*" Or File_Name Like "RouteForbidden_*" Or File_Name Like "ARS*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & Right(MimicView.Graphics(iCounter).Name, 9)

            'ElseIf File_Name Like "Signal_Up_Right_Status_Small_*" Then
            'MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            'ElseIf File_Name Like "SI_Buffer_*" Then
            'MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name


            ElseIf File_Name Like "T_*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name
            
            ElseIf File_Name Like "SDD_*" Then

            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name
                
            ElseIf File_Name Like "Route_NormalSet" Or _
                   File_Name Like ("Route_NormalSet_left") Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name
            MimicView.Graphics.Item(iCounter).LocalBranch = Replace(MimicView.Graphics.Item(iCounter).LocalBranch, "RN_SI", "SI")

            ElseIf File_Name Like "EmergencyRouteRelease" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name
            MimicView.Graphics.Item(iCounter).LocalBranch = Replace(MimicView.Graphics.Item(iCounter).LocalBranch, "ERR_SI", "SI")

            ElseIf File_Name Like ("Route_PermanentSetRight") Or _
                   File_Name Like ("Route_PermanentSetLeft") Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name
            MimicView.Graphics.Item(iCounter).LocalBranch = Replace(MimicView.Graphics.Item(iCounter).LocalBranch, "RP_SI", "SI")
            ElseIf File_Name Like "SDD_Status" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & Left(MimicView.Graphics(iCounter).Name, 12)
            MimicView.Graphics.Item(iCounter).LocalBranch = Replace(MimicView.Graphics.Item(iCounter).LocalBranch, "SDD", "SD")

            'ElseIf File_Name Like "*SubRoute*" Or File_Name Like "B_MDV_SubRoute_Top_Right" Or File_Name Like "B_MDV_SubRoute_Top_Left" Or File_Name Like "B_MDV_SubRoute_Bottom_Left" Or File_Name Like "B_MDV_SubRoute_Bottom_Right" Or File_Name Like "B_DDV_SubRouteAngled_Bottom_Right" Or File_Name Like "B_DDV_SubRouteAngled_Top_Left" Or File_Name Like "B_DDV_SubRouteAngled_Bottom_Left" Or File_Name Like "B_DDV_SubRouteAngled_Top_Right" Then
''            ElseIf File_Name Like "B_DDV_SubRouteAngled_Top_Left" Then
''
''            'MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name
''            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name


            'ElseIf File_Name Like "SubRouteDown*" Then
            'MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name
            'MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name


            ElseIf File_Name Like "GAMAZone*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "CY_*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "Kochi_Station_Button_*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "TSR_Speed*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & Replace(MimicView.Graphics(iCounter).Name, "TSR_B", "B")


            ElseIf File_Name Like "UPS1_St*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "Route_Indicator_St*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & "GATSM_GAIO_ATSI_" & Right(MimicView.Graphics(iCounter).Name, 6)

            ElseIf File_Name Like "ESP_MDV*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

            ElseIf File_Name Like "Point_Key*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & Left(MimicView.Graphics(iCounter).Name, 8)

            ElseIf File_Name Like "PF_WZV*" Or File_Name Like "WZB_WZV*" Then
            MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name

           End If

        ElseIf TypeOf myitem Is Group Then
        File_Name = MimicView.Graphics.Item(iCounter).Name Like "Group*"

            If (MimicView.Graphics.Item(iCounter).Name) = "Group*" Then

              If MimicView.Graphics.Item(iCounter).Graphics.Item(iCounter) Like "SubRoute*" Then
                MimicView.Graphics.Item(iCounter).LocalBranch = "OPCCluster:" & MimicView.Graphics(iCounter).Name
                End If
              End If
       End If
    Next
    Exit Function
ErrorHandler:
        Call CBTrace(CBTRACEF_ALWAYS, "TGL_MainLine_Detailed_View", "Mimic_ShortName", Err.Description)
End Function

Public Function DiffStartDateTimeEndDateTime(Date1 As String, Date2 As String) As Boolean
On Error GoTo ErrorHandler
Dim result As Variant
result = DateDiff("n", Date1, Date2)

Select Case result
    Case Is = 0
            DiffStartDateTimeEndDateTime = True
            Exit Function
        Case Is > 0
            DiffStartDateTimeEndDateTime = True
            Exit Function
        Case Is < 0
            DiffStartDateTimeEndDateTime = False
            Exit Function
End Select
DiffStartDateTimeEndDateTime = False
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "DiffStartDateTimeEndDateTime", Err.Description)
End Function


