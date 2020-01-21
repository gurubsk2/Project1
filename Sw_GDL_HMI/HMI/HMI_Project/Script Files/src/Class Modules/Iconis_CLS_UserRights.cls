VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_UserRights"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* Copyright, ALSTOM Transport Information Solutions, 2010. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* MODULE:      Iconis_CLS_UserRights
'* *******************************************************************************************
'* Purpose:     Manage the user rights
'* *******************************************************************************************
'* Modification History:
'* Author:              Olivier Tayeg
'* Date:                July '10
'* Change:              CR ALPHA 199652
'*                      All

'* Author:              Eric Foissey
'* Date:                September '12
'* Change:              CR ALPHA 312312
'*                      Add the read of Profile Type

'* Author:              Omar Hafadi
'* Date:                November '28
'* Change:              CR ALPHA 312312
'*                      Add the read of Profile Type

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

'* Types
'* ------------------------------------------------------
Private Type typeCategory
    strID As String
    iNbLevels As Integer
End Type

'* Constants
'* ------------------------------------------------------

Private Const c_strIconisUserRightsFile As String = "\ATSUserRights.sec"
Private Const c_strSecurityFile As String = "\Security.dat"

Private Const c_strProfileOffline As String = "@HMI.ProfileOffline%"
Private Const c_strProfileOnline As String = "@HMI.ProfileOnline%"
Private Const c_strProfileTypeKey As String = "ProfileType"
'* Class attributes
'* ------------------------------------------------------
Dim m_arrCategories() As typeCategory
Dim m_lCategoriesCount As Long
Dim m_ProfileType As Integer

' User change event
Dim WithEvents m_OPClocal_txtUserName  As Variable
Attribute m_OPClocal_txtUserName.VB_VarHelpID = -1


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_UserRights::Class_Initialize
' Input:        none
' Output:       none
' Description:  Initialization of the UserRights module:
'                   - subscription to the user change events
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()

    m_ProfileType = 1
    'initialise the profile type
    If Variables.Item(c_strProfileOffline) Is Nothing Then
        Variables.Add c_strProfileOffline, fvVariableTypeBit
        Variables.Item(c_strProfileOffline).Value = 0
    End If
    
    If Variables.Item(c_strProfileOnline) Is Nothing Then
        Variables.Add c_strProfileOnline, fvVariableTypeBit
        Variables.Item(c_strProfileOnline).Value = 1
    End If
    ' Create the available user rights, according to the configuration
    ReadConfiguration
    
    ' Subscribe for user change events
    Set m_OPClocal_txtUserName = Variables.Add(Iconis_MOD_General.c_strUserNameLocalTag, fvVariableTypeText)
    If m_OPClocal_txtUserName.EnableEvents Then
        m_OPClocal_txtUserName_ValueChange
    Else
        m_OPClocal_txtUserName.EnableEvents = True
    End If

End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_UserRights::ReadConfiguration
' Input:        strFilename [String]        Name of the mimic
'               strBranch [String]          Branch to the mimic
'               iRegion [Integer]           Region where the mimic shall be open
'               bClosedByOperator [Boolean] Indicates if the mimic shall be
'                                           automatically closed when another
'                                           is open.
' Output:       none
' Description:  Read the Iconis User Rights file configuration
'-------------------------------------------------------------------------------
Public Sub ReadConfiguration()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_UserRights", "ReadConfiguration", "Begin Function")
    
    Dim arrStrCategories() As String
    Dim arrStrGeneral() As String
    Dim I As Long
    Dim pos As Long
    Dim strCategory As String
    Dim strAttr As String
    

    ' Read all the Categories
    arrStrCategories = Split(Ini_ReadSection(MOD_Deployment.ConfigPath & c_strIconisUserRightsFile, "Categories"), Chr(0))
    m_lCategoriesCount = UBound(arrStrCategories)
    If m_lCategoriesCount > 0 Then
        ReDim m_arrCategories(0 To m_lCategoriesCount - 1)
        
        For I = 0 To m_lCategoriesCount - 1
            pos = InStr(1, arrStrCategories(I), "=")
            strCategory = Left(arrStrCategories(I), pos - 1)
            m_arrCategories(I).strID = strCategory
            m_arrCategories(I).iNbLevels = Val(Mid(arrStrCategories(I), pos + 1))
            If Variables.Item(strCategory & "%") Is Nothing Then
                Variables.Add strCategory & "%", fvVariableTypeRegister
            End If
        Next I
    End If
    
    Variables.Add "HMI.UserRights.CB_Exit%", fvVariableTypeRegister
    
    ' Read the profile type
    arrStrGeneral = Split(Ini_ReadSection(MOD_Deployment.ConfigPath & c_strSecurityFile, "General"), Chr(0))
    If UBound(arrStrGeneral) > 0 Then
        
        For I = 0 To UBound(arrStrGeneral)
            pos = InStr(1, arrStrGeneral(I), "=")
            strAttr = Left(arrStrGeneral(I), pos - 1)
            If (strAttr = c_strProfileTypeKey) Then
                m_ProfileType = Val(Mid(arrStrGeneral(I), pos + 1))
                If Variables.Item(c_strProfileOffline) Is Nothing Then
                    Variables.Add c_strProfileOffline, fvVariableTypeBit
                End If
                
                If Variables.Item(c_strProfileOnline) Is Nothing Then
                    Variables.Add c_strProfileOnline, fvVariableTypeBit

                End If
                
                If (m_ProfileType <> 1) Then
                    Variables.Item(c_strProfileOffline).Value = 1
                Else
                    Variables.Item(c_strProfileOffline).Value = 0
                End If
                    
                If (m_ProfileType > 0) Then
                    Variables.Item(c_strProfileOnline).Value = 1
                Else
                    Variables.Item(c_strProfileOnline).Value = 0
                End If
                    
            End If
        Next I
    End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_UserRights", "ReadConfiguration", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_UserRights::m_OPClocal_txtUserName_ValueChange
' Input:        none
' Output:       none
' Description:  Adapt the rights according to the user login
'-------------------------------------------------------------------------------
Private Sub m_OPClocal_txtUserName_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_UserRights", "m_OPClocal_txtUserName_ValueChange", "Begin Subroutine")
    
    Dim I As Long

    ' Variables for the ICONIS user rights
    For I = 0 To m_lCategoriesCount - 1
        If Variables.Item(m_arrCategories(I).strID & "%") Is Nothing Then
                Variables.Add m_arrCategories(I).strID & "%", fvVariableTypeText
        End If
        Variables.Item(m_arrCategories(I).strID & "%").Value = ThisProject.Security.IsAccessAllowedForCurrentUser(m_arrCategories(I).strID, 0)
    Next I
    
    ' Additional variables for the built-in user rights
    Variables.Item("HMI.UserRights.CB_Exit%") = ThisProject.Security.IsAccessAllowedForCurrentUser("07", 0)

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_UserRights", "m_OPClocal_txtUserName_ValueChange", Err.Description)
End Sub



'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_UserRights::IsAccessAllowedForUser
' Input:        none
' Output:       none
' Description:  Adapt the rights according to the user login
'-------------------------------------------------------------------------------
Public Function IsAccessAllowedForUser(strLogin As String, strCategoryID As String, iLevel As Integer) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_UserRights", "IsAccessAllowedForUser", "Begin Subroutine")
    
    Dim strProfile As Variant
    
    IsAccessAllowedForUser = False
    For Each strProfile In ThisProject.Security.users.GetProfiles(strLogin)
        If ThisProject.Security.Profiles.GetCategoryAccessRight(strProfile, strCategoryID, iLevel) Then
            IsAccessAllowedForUser = True
            Exit For
        End If
    Next strProfile

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_UserRights", "IsAccessAllowedForUser", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_UserRights::GetProfileType
' Input:        none
' Output:       none
' Description:  return the value of user profile
'-------------------------------------------------------------------------------
Public Function GetProfileType() As Integer
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_UserRights", "GetProfileType", "Begin Function")
    
    GetProfileType = m_ProfileType
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_UserRights", "GetProfileType", Err.Description)
End Function
