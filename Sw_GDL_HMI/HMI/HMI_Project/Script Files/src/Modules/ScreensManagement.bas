Attribute VB_Name = "ScreensManagement"

'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Project: SCMA-Amsterdam
'* *******************************************************************************************
'* Purpose: Module: ScreeenManagement
'* *******************************************************************************************
'* Modification History:
'* Author:              Bhavik Gandhi
'* Description:         To Manage Scroll Position Center Dynamically
'* Date:                Apr 2016
'* CR:                  CR#705633
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION()
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (IRS_ATS_Human_interface_SCMA_2_2_D_0396_B)
'* *******************************************************************************************
Option Explicit ' Constants
' =========

Public Const SC1 = 1920
Public Const SC2 = 3840
'Public Const SC3 = 5760

Public Const VIEW_MainLine_GeneralView = 1
Public Const VIEW_Depot_GeneralView = 2
Public Const VIEW_Alarms = 3
Public Const VIEW_Events = 4
Public Const VIEW_RollingStock = 5
Public Const VIEW_LineOverview = 6
Public Const VIEW_MainLineDetailedTrafficView = 7
Public Const VIEW_TimeTable = 8
Public Const VIEW_Global = 9
Public Const VIEW_DepotDetailedTrafficView_3 = 10
Public Const VIEW_MainLineDetailedTrafficView_2 = 11
Public Const VIEW_MainLineDetailedTrafficView_3 = 12

Public Const NOVIEW As Integer = 0
Public Const NBVIEWS As Integer = 20

Public Hold As POINTAPI

Public TabOpenViews(1 To 2, 1 To NBVIEWS) As Boolean
Public Station_To_Center_On As String

' Public functions and procedures
' ===============================

Public Sub InitAllWindowStates()

    InitAllWindowStatesOnScreen (1)
    InitAllWindowStatesOnScreen (2)
    'InitAllWindowStatesOnScreen (3)

    Station_To_Center_On = ""
End Sub

Public Sub InitAllWindowStatesOnScreen(Screen As Integer)
    
    TabOpenViews(Screen, VIEW_MainLineDetailedTrafficView) = False
    
End Sub

Public Function IsOpenedView(View As Integer) As Integer

    IsOpenedView = 0
    If (IsOpenedViewOnScreen(1, View)) Then
        IsOpenedView = 1
    ElseIf (IsOpenedViewOnScreen(2, View)) Then
        IsOpenedView = 2
    ElseIf (IsOpenedViewOnScreen(3, View)) Then
        IsOpenedView = 3
    ElseIf (IsOpenedViewOnScreen(4, View)) Then
        IsOpenedView = 4
    End If

End Function

Public Function WhatIsOpenedOnScreen(Screen As Integer) As Integer

    Dim iview As Integer
    WhatIsOpenedOnScreen = NOVIEW
    For iview = 1 To NBVIEWS
        If (IsOpenedViewOnScreen(Screen, iview)) Then
            WhatIsOpenedOnScreen = iview
            Exit For
        End If
    Next iview
Exit Function
End Function

'* ******************************************************************************************
'*  SubRoutine: OpenMimicOnScreen
'*    Open the mimic based on the screen number and mimic number
'* ******************************************************************************************
Public Sub OpenMimicOnScreen(Screen As Integer, ByVal View As Integer, Optional ByVal StrBranch As String)
On Error GoTo ErrorHandler
Dim iLeftPos As Long

If (Screen = 3) Then
    iLeftPos = SC2
ElseIf (Screen = 2) Then
    iLeftPos = SC1
Else
    iLeftPos = 0
End If

    If (View > 0 And View <= NBVIEWS) Then

        If (View = VIEW_MainLineDetailedTrafficView) Then
            'Open the general view above the stations banner
            TheseMimics.Open "GDL_Detailed_View", , , , "GDL_Operational_View", , , , 0, 246, True
            'Mimics.Open GetViewName(View), StrBranch, , , "GDL_Operational_View", , , , 0, 246, True
       ElseIf (View = VIEW_MainLineDetailedTrafficView_2) Then
            'Open the general view above the stations banner
            Mimics.Open GetViewName(View), StrBranch, , , "GDL_Operational_View", , , , 1920, 246, True
            'Mimics.Open "GDL_Detailed_View", , , , "GDL_Operational_View", , , 0, 0, True
      ElseIf (View = VIEW_MainLineDetailedTrafficView_3) Then
            'Open the general view above the stations banner
            Mimics.Open GetViewName(View), StrBranch, , , "GDL_Operational_View", , , , 3840, 246, True
            'Mimics.Open "GDL_Detailed_View", , , , "GDL_Operational_View", , , 0, 0, True
        

       
    End If

        InitAllWindowStatesOnScreen Screen
        SetIsOpenedViewOnScreen Screen, View, True
        SetIsOpenedViewOnScreen IIf(Screen = 1, 2, 1), View, False
        Manage_ScrollBar_Position View
     
     End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ScreensManagement", "OpenMimicOnScreen", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         ScreensManagement::ViewOperationalLayout
' Input:        none
' Output:       @returns [string] Name of the WZ view
' Description:  Returns the Level2 cluster according to the current deployment
'-------------------------------------------------------------------------------
 Public Function ViewOperationalLayout() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "ScreensManagement", "ViewOperationalLayout", "Begin Function")

        If MOD_Deployment.CurrentDeployment = deploymentNZL Then
                ViewOperationalLayout = "GDL_Operational_View"
        Else
                ViewOperationalLayout = "AMSTERDAM_WELCOME_OPERATIONAL"
        End If
        
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ScreensManagement", "ViewOperationalLayout", Err.Description)
End Function
'* ******************************************************************************************
'*  SubRoutine: Manage_ScrollBar_Position
'*    Set the current scroll bar position
'*    NOTE: Implement a fuzzy logic (!) to manage station pattern matching
'* ******************************************************************************************
Public Sub Manage_ScrollBar_Position(View As Integer, Optional sMimicName As String)
On Error GoTo ErrorHandler

    Dim ObjWindow As Object
    Dim myitem As Object
    Dim iItemIndex As Long
    
    Dim iObjectSize As Integer

    If sMimicName = "" Then
        Set ObjWindow = Application.ActiveProject.Mimics(GetViewName(View))
    Else
        Set ObjWindow = Mimics(sMimicName)
    End If

    Dim l_ScrollValue As Integer
    Dim l_Do_Scroll As Boolean
    l_Do_Scroll = False

    '-----------FILTER on DETAILED VIEW---------------
   If (View = VIEW_MainLineDetailedTrafficView) Or (View = VIEW_MainLineDetailedTrafficView_2) Or (View = VIEW_MainLineDetailedTrafficView_3) Then
    
       ' Look for Terminuses and Navigation arrows
        For iItemIndex = 1 To ObjWindow.Graphics.Count Step 1

            Set myitem = ObjWindow.Graphics.Item(iItemIndex)
            
            If TypeOf myitem Is Symbol Then

                If (myitem.FileName <> "") Then
   
                    ' Station
                    If (myitem.FileName = "Station_MDV_Display") _
                    And ("Station_" & Station_To_Center_On = myitem.Name) Then
                        l_ScrollValue = myitem.Left + myitem.Width / 2
                        l_Do_Scroll = True
                        Exit For
                    End If
                    
                End If
            
            End If
    
        Next iItemIndex
    
    Else
        l_Do_Scroll = False
    End If

    If Not (l_Do_Scroll) Then
    
        ' A Second loop to detect properly NDP (not to be mismatched with ND)
        For iItemIndex = 1 To ObjWindow.Graphics.Count Step 1

            Set myitem = ObjWindow.Graphics.Item(iItemIndex)
            ' myitem might be Nothing is its type is not known by Client Builder (e.g. an ActiveX)
            If Not myitem Is Nothing Then
                If TypeOf myitem Is Symbol Then
                    If (myitem.FileName <> "") Then
    
                        ' Station
                        If (myitem.FileName = "General_Station_Display") _
                        And (InStr(("Station_" & Station_To_Center_On), myitem.Name)) And Not (l_Do_Scroll) Then
    
                            l_ScrollValue = myitem.Left + myitem.Width / 2
                            l_Do_Scroll = True
                            Exit For
                        Else
                            'nothing to do
                        End If
                    End If
                End If
            End If
        Next iItemIndex
    End If
    
    If l_Do_Scroll Then
        ObjWindow.Windows.Item(1).Zoom 100
        ObjWindow.ScrollTo l_ScrollValue, 0, 1
        Station_To_Center_On = ""
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ScreensManagement", "Manage_ScrollBar_Position", Err.Description)
End Sub

Public Sub DisplayCurrentViews(Message As String)

    V1 = WhatIsOpenedOnScreen(1)

End Sub


' Private functions and procedures
' ================================

Private Function IsOpenedViewOnScreen(Screen As Integer, ByVal View As Integer) As Boolean

    IsOpenedViewOnScreen = TabOpenViews(Screen, View)

End Function

Private Sub SetIsOpenedViewOnScreen(Screen As Integer, View As Integer, State As Boolean)

    TabOpenViews(Screen, View) = State

End Sub

'* *************************************************************
'*  Function: GetActiveMimic
'*  Get the active mimic name of the selected monitor.
'* *************************************************************
Public Function GetBackgroundView_OnScreen(ByVal pos As Integer) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "ScreensManagement", "GetBackgroundView_OnScreen", "Begin Function")
        
    If pos < SC2 Then
        GetBackgroundView_OnScreen = GetViewName(Variables.Item("displayedViewOnScreen1%").Value)
    Else
        GetBackgroundView_OnScreen = GetViewName(Variables.Item("displayedViewOnScreen2%").Value)
    End If

ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ScreensManagement", "GetBackgroundView_OnScreen", Err.Description)
End Function

Public Function GetViewName(ByVal View As Integer) As String

    GetViewName = ""
    If (View = VIEW_MainLine_GeneralView) Then
        GetViewName = "View_General"
    ElseIf (View = VIEW_Alarms) Then
        GetViewName = "GUA_Alarms_DepotView"
    ElseIf (View = VIEW_Events) Then
        GetViewName = "GUA_Event_DepotView"
    ElseIf (View = VIEW_Global) Then
        GetViewName = "TGL_GLOBAL_OVERVIEW_POLY"
    ElseIf (View = VIEW_RollingStock) Then
        GetViewName = "RollingStock_Management_View"
    ElseIf (View = VIEW_MainLine_GeneralView) Then
        GetViewName = "View_General"
    ElseIf (View = VIEW_Depot_GeneralView) Then
        GetViewName = "View_Depot"
    ElseIf (View = VIEW_MainLineDetailedTrafficView) Then
        GetViewName = "GDL_Detailed_View"
    ElseIf (View = VIEW_MainLineDetailedTrafficView_2) Then
        GetViewName = "GDL_Detailed_View_2"
    ElseIf (View = VIEW_MainLineDetailedTrafficView_3) Then
        GetViewName = "GDL_Detailed_View_3"
        


    End If
    
End Function
'* ******************************************************************************************
'*  SubRoutine: OpenViewOnSameScreen
'*    To open the view on the same screen
'* ******************************************************************************************
Public Sub OpenViewOnSameScreen(ByVal View As Integer, Optional ByVal Click_Pos As Integer)
On Error GoTo ErrorHandler

    Dim Screen As Integer
    
    'Check on which screen the station as been selected, so where detailed view is to display
    If (ThisProject.Application.ActiveWindow.Left + Click_Pos) < SC2 Then
        Screen = 1
    Else
        Screen = 2
    End If
    
    OpenViewOnScreen Screen, View
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ScreensManagement", "OpenViewOnSameScreen", Err.Description)
End Sub
Public Sub OpenViewOnScreen(Screen As Integer, ByVal View As Integer, Optional ByVal StrBranch As String)
On Error GoTo ErrorHandler
    Dim sViewOnScrn1, sViewOnScrn2, sViewOnScrn3
    
    sViewOnScrn1 = WhatIsOpenedOnScreen(1)
    sViewOnScrn2 = WhatIsOpenedOnScreen(2)
    'sViewOnScrn3 = WhatIsOpenedOnScreen(3)
  OpenMimicOnScreen Screen, View, StrBranch

    If (Screen = 1) Then
        If (sViewOnScrn2 = View) Then
            OpenMimicOnScreen 2, sViewOnScrn1
        End If
    ElseIf (Screen = 2) Then
        If (sViewOnScrn1 = View) Then
            OpenMimicOnScreen 1, sViewOnScrn2
        End If
   End If

Exit Sub

End Sub

Public Function OpenMimicInCenter(ByVal sMimicName As String, ByVal sMimicBranch As String, Optional iScreenToOpen As Integer) As Boolean
On Error GoTo ErrorHandler

Const c_TopCorrection As Long = 2
Const c_LeftCorrection As Long = 1

Dim oMimic As Mimic
Dim lTop As Long
Dim lLeft As Long

If iScreenToOpen > 1 Then
    iScreenToOpen = iScreenToOpen - 1
Else
    iScreenToOpen = 0
End If

Set oMimic = Mimics.Open(sMimicName, sMimicBranch, , , , , , , 5759, 1199, True)

lLeft = (c_lScreenWidth * iScreenToOpen) + (c_lScreenWidth / 2) - (oMimic.Windows(1).Width / 2) - c_LeftCorrection
lTop = (c_lScreenHeight / 2) - (oMimic.Windows(1).Height / 2) - c_TopCorrection

oMimic.Windows(1).Top = lTop
oMimic.Windows(1).Left = lLeft

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ScreensManagement", "OpenMimicInCenter", Err.Description)
End Function

Function GetmousepointerPossition() As Integer
On Error GoTo ErrorHandler
GetCursorPos Hold

If Hold.lXpos < c_lScreenWidth Then
    GetmousepointerPossition = 1
ElseIf Hold.lXpos > c_lScreenWidth And Hold.lXpos < (2 * c_lScreenWidth) Then
    GetmousepointerPossition = 2
ElseIf Hold.lXpos > (2 * c_lScreenWidth) Then
    GetmousepointerPossition = 3
Else
    GetmousepointerPossition = 1
End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "ScreensManagement", "OpenMimicInCenter", Err.Description)
End Function
'* *************************************************************************************
'*  Author: Vinay CR
'*  Function: To Open Contextual Menu Based on the Click position.
'* <parameter2 = Name Of the Contextual Menu to be opened>
'* <parameter3 = Branch for Contextual Menu>
'* <parameter4 = Name of the parent on which Contextual Menu to be opened >
'* <parameter5&6 = Screen Width & Hight
'* This Function Doesnot Returns Any value.
'**************************************************************************************
'* Open the Contextual Menu mimic
'**************************************************************************************
Public Sub OpenContextualMenu(ByVal sContxtMenuName As String, ByVal sBranch As String _
                               , Optional ScreenWidth As Long = c_lScreenWidth, Optional ScreenHight As Long = c_lScreenHeight)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_ScreensManagement", "OpenContextualMenu", "Begin subroutine")
    Dim oMimic As Mimic
    Dim lLeft As Long
    Dim lTop As Long

    GetCursorPos Hold
    ' Same contextual already open? Close it.
  
    ScreenWidth = GetmousepointerPossition * c_lScreenWidth
    CloseMimic (sContxtMenuName)
    Set oMimic = Mimics.Open(sContxtMenuName, sBranch, , , "", "", , , 5000, 5000, True)
    If (Hold.lXpos > (ScreenWidth - oMimic.Windows(1).Width)) Or (Hold.lXpos > (2 * ScreenWidth) - oMimic.Windows(1).Width) Then
        lLeft = Hold.lXpos - oMimic.Windows(1).Width
    Else
        lLeft = Hold.lXpos
    End If

    If ((c_lScreenHeight) < (Hold.lYpos + oMimic.Windows(1).Height)) Then
        lTop = Hold.lYpos - oMimic.Windows(1).Height
    Else
       lTop = Hold.lYpos
    End If
   ' * Open the Contextual Menu mimic
    oMimic.Windows(1).Top = lTop
    oMimic.Windows(1).Left = lLeft
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_General", "OpenContextualMenu", Err.Description)
End Sub



