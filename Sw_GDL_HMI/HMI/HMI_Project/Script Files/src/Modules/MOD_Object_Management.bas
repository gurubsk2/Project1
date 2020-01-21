Attribute VB_Name = "MOD_Object_Management"
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Project: Kochi
'* *******************************************************************************************
'* Purpose: Object Management : used to manage the background, and the availability
'*          Used for combobox animation
'* *******************************************************************************************
'* Modification History:
'* Author:
'* Description:
'* Date:                november 2013
'* Change:              All
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION()
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (2S&TDM-ATS-0007 - vA)
'* *******************************************************************************************

Public Const c_StrOPCClusterSeparator = ":"

'* ***************************************************************************************
'*  Function: Update_Background
'* ***************************************************************************************
'*  Parameters :
'*      pObject [Object]: instance of the object to control
'* ***************************************************************************************
'* the subroutine updates the background according the enabled status
'* ***************************************************************************************
Public Sub Update_Background(pObject As Object)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Object_Management", "Update_Background", "Begin Subroutine")
    
    If Not (pObject Is Nothing) Then
    
        If pObject.Enabled Then
            '* background color as white
            pObject.BackColor = RGB(255, 255, 255)
        Else
            '* background color as light grey
            pObject.BackColor = RGB(215, 215, 215)
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "Update_Background", "Object Passed in Parameters is invalid")
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "Update_Background", Err.Description)
End Sub

'* ***************************************************************************************
'*  Function: setObjectAbility
'* ***************************************************************************************
'*  Parameters :
'*      pObject [Object]: instance of the object to control
'*      bAbility [Boolean]: Ability status requested
'* ***************************************************************************************
'* the subroutine enabled the object passed in parameters and updates its background
'* according the ability status
'* ***************************************************************************************
Public Sub setObjectAbility(pObject As Object, bAbility As Boolean)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Object_Management", "setObjectAbility", "Begin Subroutine")
     
    If Not (pObject Is Nothing) Then
        If bAbility Then
            '* background color as white
            pObject.Enabled = True
            pObject.BackColor = RGB(255, 255, 255)
        Else
            '* background color as light grey
            pObject.Enabled = False
            pObject.BackColor = RGB(215, 215, 215)
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "setObjectAbility", "Object Passed in Parameters is invalid")
    End If
   
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "setObjectAbility", Err.Description)

End Sub


'* ***************************************************************************************
'*  Function: GetOPCClusterFromBranch
'* ***************************************************************************************
'*  Parameters :
'*      strBranch [String]: Branch to read and parse
'* ***************************************************************************************
'* the function parses the branch to extract the OPC Cluster name used
'* ***************************************************************************************
Public Function GetOPCClusterFromBranch(StrBranch As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Object_Management", "GetOPCClusterFromBranch", "Begin Function")
     
        Dim arrBranchInfo() As String
        
        ' Extract the cluster name from the branch of the mimic
        arrBranchInfo = Split(StrBranch, c_StrOPCClusterSeparator)
        If (UBound(arrBranchInfo) <> -1) Then
            GetOPCClusterFromBranch = arrBranchInfo(0) & c_StrOPCClusterSeparator
        Else
            GetOPCClusterFromBranch = ""
        End If
   
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "GetOPCClusterFromBranch", Err.Description)

End Function



'* ***************************************************************************************
'*  Function: GetOPCPathFrom
'* ***************************************************************************************
'*  Parameters :
'*      strBranch [String]: Branch to read and parse
'* ***************************************************************************************
'* the function parses the branch to extract the path, without cluster
'* ***************************************************************************************
Public Function GetOPCPathFrom(StrBranch As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Object_Management", "GetOPCPathFrom", "Begin Function")
     
        Dim arrBranchInfo() As String
        
        ' Extract the cluster name from the branch of the mimic
        arrBranchInfo = Split(StrBranch, c_StrOPCClusterSeparator)
        If (UBound(arrBranchInfo) <> -1) Then
            GetOPCPath = Replace(StrBranch, arrBranchInfo(0) & c_StrOPCClusterSeparator, "")
        Else
            GetOPCPath = StrBranch
        End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "GetOPCPathFrom", Err.Description)

End Function

'---------------------------------------------------------------------------------------
' Name:         ListBoxEnabled
' Input:        @param listbox
' Output:       none
' Description:  Visual appearance of a List Box
'---------------------------------------------------------------------------------------
Public Sub ListBoxEnabled(lb As ListBox, bEnabled As Boolean, Optional lSelectIndex As Long = -1)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Object_Management", "ListBoxEnabled", "Begin Subroutine")
    
    If bEnabled Then
        lb.ForeColor = &H0
        lb.BackColor = &HFFFFFF
        
        ' To ensure the refresh, send a "no selection" first then the selection
        lb.ListIndex = -1
        If lSelectIndex < lb.ListCount Then
            lb.ListIndex = lSelectIndex
        Else
            Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "ListBoxEnabled", _
                        "The selected index (" & lSelectIndex & ") is out of the bounds in the listbox.")
        End If
    Else
        lb.BackColor = &HF0F0F0
        lb.ForeColor = &HC0C0C0
        
        lb.ListIndex = -1
    End If
    lb.Enabled = bEnabled

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "ListBoxEnabled", Err.Description)
End Sub

'---------------------------------------------------------------------------------------
' Name:         SetCheckBoxesAbility
' Input:        Screen Number (integer), Enabled/Disabled (boolean)
' Output:       none
' Description:  Visual appearance/selection of check boxes on Operational view
'---------------------------------------------------------------------------------------
Public Sub SetCheckBoxesAbility(iScreen As Integer, bEnabled As Boolean)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Object_Management", "SetCheckBoxesAbility", "Begin Subroutine")
    Dim item_CheckBox As checkbox
    Dim i As Integer
    Dim obj_object As Object
    Dim objMimic As Mimic

For Each objMimic In ThisProject.Mimics

    If objMimic.FileName Like "KOCHI_WELCOME_OPERATIONAL*" Then
    
        For i = 1 To objMimic.Graphics.Count
            If TypeOf objMimic.Graphics.Item(i) Is checkbox Then
                Set item_CheckBox = objMimic.Graphics.Item(i)
                
                    If iScreen = 1 Then
                        If item_CheckBox.Left < 1921 Then
                            If bEnabled Then
                                item_CheckBox.Enabled = True
                            Else
                                item_CheckBox.Enabled = False
                            End If
                        End If
                    ElseIf iScreen = 2 Then
                        If item_CheckBox.Left > 1919 Then
                            If bEnabled Then
                                item_CheckBox.Enabled = True
                            Else
                                item_CheckBox.Enabled = False
                            End If
                        End If
                    End If
            End If
        Next i
    
    End If

Next


Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "SetCheckBoxesAbility", Err.Description)
End Sub

'---------------------------------------------------------------------------------------
' Name:         SetIndividualCheckBoxesAbility
' Input:        Screen Number (integer), Enabled/Disabled (boolean)
' Output:       none
' Description:  Visual appearance/selection of check boxes on Operational view
'---------------------------------------------------------------------------------------
Public Sub SetIndividualCheckBoxesAbility(strName As String, iScreen As Integer, bEnabled As Boolean)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "MOD_Object_Management", "SetIndividualCheckBoxesAbility", "Begin Subroutine")
    Dim item_CheckBox As checkbox
    Dim i As Integer
    Dim obj_object As Object
    Dim objMimic As Mimic

For Each objMimic In ThisProject.Mimics

    If objMimic.FileName Like "KOCHI_WELCOME_OPERATIONAL*" Then
    
        For i = 1 To objMimic.Graphics.Count
            If TypeOf objMimic.Graphics.Item(i) Is checkbox Then
                Set item_CheckBox = objMimic.Graphics.Item(i)
                    If item_CheckBox.Name = strName Then
                        If iScreen = 1 Then
                            If item_CheckBox.Left < 1921 Then
                                If bEnabled Then
                                    item_CheckBox.Enabled = True
                                Else
                                    item_CheckBox.Enabled = False
                                End If
                            End If
                        ElseIf iScreen = 2 Then
                            If item_CheckBox.Left > 1919 Then
                                If bEnabled Then
                                    item_CheckBox.Enabled = True
                                Else
                                    item_CheckBox.Enabled = False
                                End If
                            End If
                        End If
                    End If
            End If
        Next i
    
    End If

Next


Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "MOD_Object_Management", "SetIndividualCheckBoxesAbility", Err.Description)
End Sub

'---------------------------------------------------------------------------------------
' Name:         RemoveItem
' Input:        ComboBox , item
' Output:       none
' Description:  Remove item into ComboBox
'---------------------------------------------------------------------------------------
Public Sub RemoveItem(oComboBox As Object, sItem As String)

    Dim lIndex As Variant

    For lIndex = 0 To (oComboBox.ListCount - 1)
        'If no selection, choose last list item.
        If oComboBox.List(lIndex) = sItem Then
            oComboBox.RemoveItem (oComboBox.List(lIndex))
            Exit For
        End If
        
    Next

End Sub
