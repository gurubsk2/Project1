VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_Territory"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2008. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_Territory
'* *******************************************************************************************
'* Purpose:     Manage a Territory for the Territory Assignement (TAS)
'* *******************************************************************************************
'* Modification History:
'* Author:              Olivier TAYEG
'* Date:                October '09
'* Change:              All

'* Author:              Olivier TAYEG
'* Date:                Jan '10
'* Change:              CR ALPHA 172771
'*                      Manage the sectorization

'* Author:              Olivier TAYEG
'* Date:                Jan '10
'* Change:              CR ALPHA 170813
'*                      Compute the assignability based on the profile

'* Author:              Olivier TAYEG
'* Date:                Jan '10
'* Change:              CR ALPHA 168806

'* Author:              Olivier TAYEG
'* Date:                March '10
'* Change:              CR ALPHA 178237
'*                      Compute the assignability based on the user ID
'*
'* Author:              Olivier Tayeg
'* Date:                May '11
'* Change:              CR ALPHA 230623
'*                      Adapt to S2KGAL (change in the OPC path hierarchy). Improve the traces.
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

'* Constants
'* ------------------------------------------------------

Private Enum enumTerritoryStates
    c_stateInitial          ' At startup
    c_stateOwnedByMe        ' The control is local and territory is owned by the current operator
    c_stateNotOwned         ' The control is not local or the territory is not owned by the current operator
End Enum

' Path to the local variables
Private Const c_strControlledByCurrentOperatorLocalTag As String = ".TAS.bControlledByMe%"
Private Const c_strAssignableToCurrentOperatorLocalTag As String = ".TAS.bAssignableToMe%"
Private Const c_strTransferrableToTag As String = ".TAS.TransferrableTo%"
Private Const c_strIncomingTransferLocalTag As String = ".TAS.IncomingTransfer%"
Private Const c_strControlledLocalTag As String = ".TAS.bControlled%"
Private Const c_strTakeOverAcceptedByOperatorLocalTag As String = ".bTakeOverAcceptedByOperator%"
Private Const c_strOwnersLocalTag As String = ".strOwners%"

' Path to the OPC server variables
Private Const c_strNameTag As String = ".TAS.Name"
Private Const c_strLocalControlByTag As String = ".TAS.ControlledBy"
Private Const c_strRemoteControlByTag As String = ".DistantOperator.Value"
Private Const c_strAssignableUsersListTag As String = ".AssignableUsers.Value.bstrValue"
Private Const c_strAutomaticReleaseTag As String = ".Automatic_De_Assignment.Value"

Private Const c_strLocalControlTag As String = ".IsControlLocal.Value"
Private Const c_strATSSectorOutgoingRequestTag As String = ".ATSArea.WaitingConfirmation"
Private Const c_strATSSectorAckOutgoingRequestTag As String = ".ATSArea.Confirmation"

'* Class attributes
'* ------------------------------------------------------
' ID of the territory
Private m_strID As String
' Name of the territory
Private m_strName As String
' Status of the territory
Private m_state As enumTerritoryStates

' Path to the territory object
Private m_strPath As String

' List of the assignable users
Private m_collAssignableUsers As Collection

' Flag to indicate that we are managing a new user login
Dim m_bUserLoginInProgress As Boolean

'* Local OPC variables
'* ------------------------------------------------------
' Is the territory controlled by the current operator?
Private m_OPClocal_bControlledByCurrentOperator As Variable
' Is a transfer request coming?
Private m_OPClocal_bIncomingTransfer As Variable
' Is the territory assignable to the current operator?
Private m_OPClocal_bAssignableToCurrentOperator As Variable
' Name of the currently logged operator
Private WithEvents m_OPClocal_txtUserName As Variable
Attribute m_OPClocal_txtUserName.VB_VarHelpID = -1
' List of the owners of the territory
Private m_OPClocal_strOwners As Variable

' Is the control local?
Private m_OPC_bIsControlLocal As Variable
' Is the territory controlled somewhere?
Private m_OPClocal_bControlled As Variable
' Has the take over been accepted by the operator? If not, it means that the control was taken in emergency.
Private m_OPClocal_bTakeOverAcceptedByOperator As Variable

'* OPC server's variables
'* ------------------------------------------------------
' Name of the territory
Private WithEvents m_OPC_txtName As Variable
Attribute m_OPC_txtName.VB_VarHelpID = -1
' List of the local operators controlling this territory
Private WithEvents m_OPC_txtLocalControlOperatorsList As Variable
Attribute m_OPC_txtLocalControlOperatorsList.VB_VarHelpID = -1
' List of the remote operators controlling this territory
Private WithEvents m_OPC_txtRemoteControlOperatorsList As Variable
Attribute m_OPC_txtRemoteControlOperatorsList.VB_VarHelpID = -1
' List of the operators allowed to control this territory
Private WithEvents m_OPC_txtAssignableUsersList As Variable
Attribute m_OPC_txtAssignableUsersList.VB_VarHelpID = -1
' Indicate if the user may logoff without deassignation
Private m_OPC_iAutomaticRelease As Variable

' Outgoing request from another sector
Private WithEvents m_OPC_bATSSectorOutgoingRequest As Variable
Attribute m_OPC_bATSSectorOutgoingRequest.VB_VarHelpID = -1
' Acknowledge an outgoing request
Private m_OPC_bATSSectorAckOutgoingRequest As Variable


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::init
' Input:        strTerritoryPath [String]    Path to the territory
' Output:       none
' Description:  Initialize the territory by connecting to the OPC variables.
'-------------------------------------------------------------------------------
Public Sub Init(strTerritoryPath As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "init", "Begin Subroutine")

    m_strPath = strTerritoryPath
    
    ' Store the ID of the territory
    Dim pos As Long
    pos = InStr(1, strTerritoryPath, ":")
    If pos > 0 Then
        m_strID = Mid(strTerritoryPath, pos + 1)
    Else
        m_strID = strTerritoryPath
    End If
    
    ' The default value for the name is the ID
    m_strName = m_strID
    
    ' Add the local variables to the collection of subscribed variables
    Set m_OPClocal_bControlledByCurrentOperator = Variables.Add(m_strPath & c_strControlledByCurrentOperatorLocalTag, fvVariableTypeBit)
    Set m_OPClocal_bAssignableToCurrentOperator = Variables.Add(m_strPath & c_strAssignableToCurrentOperatorLocalTag, fvVariableTypeBit)

    Set m_OPClocal_bIncomingTransfer = Variables.Add(m_strPath & c_strIncomingTransferLocalTag, fvVariableTypeBit)
    Set m_OPClocal_bControlled = Variables.Add(m_strPath & c_strControlledLocalTag, fvVariableTypeBit)
    Set m_OPClocal_bTakeOverAcceptedByOperator = Variables.Add(m_strPath & c_strTakeOverAcceptedByOperatorLocalTag, fvVariableTypeBit)
    Set m_OPClocal_strOwners = Variables.Add(m_strPath & c_strOwnersLocalTag, fvVariableTypeText)
    
    Set m_OPClocal_txtUserName = Variables.Add(Iconis_MOD_General.c_strUserNameLocalTag, fvVariableTypeText)
    
    ' Add the server variables to the collection of subscribed variables
    Set m_OPC_txtName = Variables.Add(m_strPath & c_strNameTag, fvVariableTypeText)
    
    Set m_OPC_bIsControlLocal = Variables.Add(m_strPath & c_strLocalControlTag, fvVariableTypeBit)
    Set m_OPC_txtLocalControlOperatorsList = Variables.Add(m_strPath & c_strLocalControlByTag, fvVariableTypeText)
    Set m_OPC_txtRemoteControlOperatorsList = Variables.Add(m_strPath & c_strRemoteControlByTag, fvVariableTypeText)
    Set m_OPC_txtAssignableUsersList = Variables.Add(m_strPath & c_strAssignableUsersListTag, fvVariableTypeText)
    Set m_OPC_iAutomaticRelease = Variables.Add(m_strPath & c_strAutomaticReleaseTag, fvVariableTypeRegister)
    
    Set m_OPC_bATSSectorOutgoingRequest = Variables.Add(m_strPath & c_strATSSectorOutgoingRequestTag, fvVariableTypeBit)
    Set m_OPC_bATSSectorAckOutgoingRequest = Variables.Add(m_strPath & c_strATSSectorAckOutgoingRequestTag, fvVariableTypeBit)

    ' Set the initial default values for the local variables
    m_OPClocal_bControlledByCurrentOperator.Value = False
    m_OPClocal_bAssignableToCurrentOperator.Value = False
    m_OPClocal_bIncomingTransfer.Value = False
    m_OPClocal_bControlled.Value = False
    m_OPClocal_bTakeOverAcceptedByOperator.Value = False

    ' Enable the notifications
    If m_OPClocal_txtUserName.EnableEvents Then
        m_OPClocal_txtUserName_ValueChange
    Else
        m_OPClocal_txtUserName.EnableEvents = True
    End If
    
    If m_OPC_txtName.EnableEvents Then
        m_OPC_txtName_ValueChange
    Else
        m_OPC_txtName.EnableEvents = True
    End If
    
    If m_OPC_txtLocalControlOperatorsList.EnableEvents Then
        m_OPC_txtLocalControlOperatorsList_ValueChange
    Else
        m_OPC_txtLocalControlOperatorsList.EnableEvents = True
    End If
    If m_OPC_txtRemoteControlOperatorsList.EnableEvents Then
        m_OPC_txtRemoteControlOperatorsList_ValueChange
    Else
        m_OPC_txtRemoteControlOperatorsList.EnableEvents = True
    End If
    
    If m_OPC_txtAssignableUsersList.EnableEvents Then
        m_OPC_txtAssignableUsersList_ValueChange
    Else
        m_OPC_txtAssignableUsersList.EnableEvents = True
    End If
    
    If m_OPC_bATSSectorOutgoingRequest.EnableEvents Then
        m_OPC_bATSSectorOutgoingRequest_ValueChange
    Else
        m_OPC_bATSSectorOutgoingRequest.EnableEvents = True
    End If

    If m_OPC_bIsControlLocal.EnableEvents Then
        m_OPC_bIsControlLocal_ValueChange
    Else
        m_OPC_bIsControlLocal.EnableEvents = True
    End If
    m_state = c_stateInitial

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "init", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Get Iconis_CLS_Territory::strID
' Input:        none
' Output:       [String]        name of the territory
' Description:  Return the name of the territory
'-------------------------------------------------------------------------------
Public Property Get strID() As String
    strID = m_strID
End Property


'-------------------------------------------------------------------------------
' Name:         Get Iconis_CLS_Territory::strName
' Input:        none
' Output:       [String]        name of the territory
' Description:  Return the name of the territory
'-------------------------------------------------------------------------------
Public Property Get strName() As String
    strName = m_strName
End Property

'-------------------------------------------------------------------------------
' Name:         Get Iconis_CLS_Territory::strPath
' Input:        none
' Output:       [String]        name of the territory
' Description:  Return the path to the territory
'-------------------------------------------------------------------------------
Public Property Get strPath() As String
    strPath = m_strPath
End Property


'-------------------------------------------------------------------------------
' Name:         Get Iconis_CLS_Territory::collAssignableUsers
' Input:        none
' Output:       [Collection]  list of String (user login)
' Description:  Return the users who can assign the territory
'-------------------------------------------------------------------------------
Public Property Get collAssignableUsers() As Collection
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "IsAssignableTo", "Begin Subroutine")

    Set collAssignableUsers = m_collAssignableUsers

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "collAssignableUsers", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Get Iconis_CLS_Territory::bIsControlledByCurrentOperator
' Input:        none
' Output:       [Boolean]  True if the territory is controlled by the current user
'                          False otherwise
' Description:  Indicate whether the territory is controlled by the current user
'-------------------------------------------------------------------------------
Public Property Get bIsControlledByCurrentOperator() As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "IsAssignableTo", "Begin Subroutine")

    bIsControlledByCurrentOperator = m_OPClocal_bControlledByCurrentOperator.Value

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "bIsControlledByCurrentOperator", Err.Description)
End Property


'-------------------------------------------------------------------------------
' Name:         Get Iconis_CLS_Territory::IsAssignableTo
' Input:        strOperator [String]    Login of the operator
' Output:       [Boolean]  True if the territory can be controlled by the user
'                          False otherwise
' Description:  Indicate whether the territory is controlled by the user
'-------------------------------------------------------------------------------
Public Property Get IsAssignableTo(strOperator As String) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "IsAssignableTo", "Begin Subroutine")

    Dim I As Long
    IsAssignableTo = False
    For I = 1 To m_collAssignableUsers.Count
        If m_collAssignableUsers.Item(I) = strOperator Then
            IsAssignableTo = True
            Exit For
        End If
    Next I

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "IsAssignableTo", Err.Description)
End Property


'-------------------------------------------------------------------------------
' Name:         Get Iconis_CLS_Territory::bIsAssignableToCurrentOperator
' Input:        none
' Output:       [Boolean]  True if the territory can be controlled by the current operator
'                          False otherwise
' Description:  Indicate whether the territory is controlled by the current operator
'-------------------------------------------------------------------------------
Public Property Get bIsAssignableToCurrentOperator() As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "bIsAssignableToCurrentOperator", "Begin Subroutine")

    Dim I As Long
    bIsAssignableToCurrentOperator = False
    For I = 1 To m_collAssignableUsers.Count
        If m_collAssignableUsers.Item(I) = ThisLibrary.Security.UserName Then
            bIsAssignableToCurrentOperator = True
            Exit For
        End If
    Next I

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "bIsAssignableToCurrentOperator", Err.Description)
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::bIncomingTransfer [Property Let]
' Input:        bValue [Boolean]    Value to write
' Output:       none
' Description:  Set the value of the "incoming transfer" status
'-------------------------------------------------------------------------------
Public Property Let bIncomingTransfer(bValue As Boolean)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "bIncomingTransfer", "Begin Subroutine")

    m_OPClocal_bIncomingTransfer.Value = bValue

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "bIncomingTransfer", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Get Iconis_CLS_Territory::bAutomaticRelease
' Input:        none
' Output:       [Boolean]   False if the automatic release is not allowed
'                           True if the automatic release is allowed
'                                or the server is not present
' Description:  Return whether the territory is released automatically at logoff
'-------------------------------------------------------------------------------
Public Property Get bAutomaticRelease() As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "bAutomaticRelease", "Begin Subroutine")

    If m_OPC_iAutomaticRelease.Quality <> 192 Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_txtAssignableUsersList_ValueChange", "The Quality of " & m_OPC_txtAssignableUsersList.Name & " is not good")
        bAutomaticRelease = True
    Else '* Status and quality of the variable are good
        bAutomaticRelease = m_OPC_iAutomaticRelease.Value
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "bAutomaticRelease", Err.Description)
End Property



'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::txtAssignableUsersList [Property Let]
' Input:        strXmlAssignableUsersList [String]    Value to write
' Output:       none
' Description:  Send a new value for the "Assignable Users" list
'-------------------------------------------------------------------------------
Public Property Let strAssignableUsersList(strXmlAssignableUsersList As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "set_txtAssignableUsersList", "Begin Subroutine")

    ' Check the status and the quality of the OPC variable related to the command
    If (m_OPC_txtAssignableUsersList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "set_txtAssignableUsersList", "The status of " & m_OPC_txtAssignableUsersList.Name & " is Waiting")
    ElseIf (m_OPC_txtAssignableUsersList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "set_txtAssignableUsersList", "The status of " & m_OPC_txtAssignableUsersList.Name & " is Config Error")
    ElseIf (m_OPC_txtAssignableUsersList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TAS", "set_txtAssignableUsersList", "The status of " & m_OPC_txtAssignableUsersList.Name & " is Not Connected")
    Else
        m_OPC_txtAssignableUsersList.Value = strXmlAssignableUsersList
        m_OPC_txtAssignableUsersList_ValueChange
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "set_txtAssignableUsersList", Err.Description)
End Property




'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::Class_Initialize
' Input:        none
' Output:       none
' Description:  Object constructor.
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "Class_Initialize", "Begin Subroutine")

    Set m_collAssignableUsers = New Collection

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "Class_Initialize", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor.
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "Class_Terminate", "Begin Subroutine")
      
    '* Unsubscribe all the variables previously subscribed
    If Not (m_OPClocal_bControlledByCurrentOperator Is Nothing) Then
        Variables.Remove (m_OPClocal_bControlledByCurrentOperator.Name)
        Set m_OPClocal_bControlledByCurrentOperator = Nothing
    End If
    If Not (m_OPClocal_bAssignableToCurrentOperator Is Nothing) Then
        Variables.Remove (m_OPClocal_bAssignableToCurrentOperator.Name)
        Set m_OPClocal_bAssignableToCurrentOperator = Nothing
    End If
    If Not (m_OPClocal_bIncomingTransfer Is Nothing) Then
        Variables.Remove (m_OPClocal_bIncomingTransfer.Name)
        Set m_OPClocal_bIncomingTransfer = Nothing
    End If
    
    If Not (m_OPC_txtLocalControlOperatorsList Is Nothing) Then
        Variables.Remove (m_OPC_txtLocalControlOperatorsList.Name)
        Set m_OPC_txtLocalControlOperatorsList = Nothing
    End If
    If Not (m_OPC_txtAssignableUsersList Is Nothing) Then
        Variables.Remove (m_OPC_txtAssignableUsersList.Name)
        Set m_OPC_txtAssignableUsersList = Nothing
    End If
    
    If Not (m_OPClocal_txtUserName Is Nothing) Then
        Variables.Remove (m_OPClocal_txtUserName.Name)
        Set m_OPClocal_txtUserName = Nothing
    End If
    

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "Class_Terminate", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::m_OPClocal_txtUserName_ValueChange
' Input:        none
' Output:       none
' Description:  Manage a new logon.
'-------------------------------------------------------------------------------
Private Sub m_OPClocal_txtUserName_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPClocal_txtUserName_ValueChange", "Begin Subroutine")

    If Not m_OPC_txtLocalControlOperatorsList Is Nothing And Not m_OPC_txtAssignableUsersList Is Nothing Then
        ' Raise flag to indicate the user is changing (in this case, less traces to output)
        m_bUserLoginInProgress = True
        ' Compute the 'controlled by me' status
        ComputeIsControlledByCurrentOperator
        ' Compute the 'assignable by me' status
        ComputeIsAssignableByCurrentOperator
        
        m_bUserLoginInProgress = False
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPClocal_txtUserName_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::m_OPC_txtName_ValueChange
' Input:        none
' Output:       none
' Description:  Store the name of the territory
'-------------------------------------------------------------------------------
Private Sub m_OPC_txtName_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_txtName_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_txtName.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_txtName_ValueChange", "The status of " & m_OPC_txtName.Name & " is Waiting")
    ElseIf (m_OPC_txtName.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_txtName_ValueChange", "The status of " & m_OPC_txtName.Name & " is Config Error")
    ElseIf (m_OPC_txtName.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_txtName_ValueChange", "The status of " & m_OPC_txtName.Name & " is Not Connected")
    ElseIf (m_OPC_txtName.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_txtName_ValueChange", "The Quality of " & m_OPC_txtName.Name & " is not good")
    Else '* Status and quality of the variable are good
        m_strName = m_OPC_txtName.Value
    End If
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_txtName_ValueChange", Err.Description)
End Sub



'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::m_OPC_txtLocalControlOperatorsList_ValueChange
' Input:        none
' Output:       none
' Description:  When the list of local operators controlling the territory is updated,
'               - compute whether the territory is controlled
'               - look if the territory is owned by the current operator
'-------------------------------------------------------------------------------
Private Sub m_OPC_txtLocalControlOperatorsList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_txtLocalControlOperatorsList_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_txtLocalControlOperatorsList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_txtLocalControlOperatorsList_ValueChange", "The status of " & m_OPC_txtLocalControlOperatorsList.Name & " is Waiting")
    ElseIf (m_OPC_txtLocalControlOperatorsList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_txtLocalControlOperatorsList_ValueChange", "The status of " & m_OPC_txtLocalControlOperatorsList.Name & " is Config Error")
    Else
        ' NB: Status of the variable may be Bad or Disconnected
        
        ' Compute the owners list and the controlled status
        ComputeOwners

        ' Compute whether the territory is controlled by the current operator
        ComputeIsControlledByCurrentOperator

    End If
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_txtLocalControlOperatorsList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::m_OPC_txtRemoteControlOperatorsList_ValueChange
' Input:        none
' Output:       none
' Description:  When the list of remote operators controlling the territory is updated,
'               compute whether the territory is controlled
'-------------------------------------------------------------------------------
Private Sub m_OPC_txtRemoteControlOperatorsList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_txtRemoteControlOperatorsList_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_txtRemoteControlOperatorsList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_txtRemoteControlOperatorsList_ValueChange", "The status of " & m_OPC_txtRemoteControlOperatorsList.Name & " is Waiting")
    ElseIf (m_OPC_txtRemoteControlOperatorsList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_txtRemoteControlOperatorsList_ValueChange", "The status of " & m_OPC_txtRemoteControlOperatorsList.Name & " is Config Error")
    Else
        ' NB: Status of the variable may be Bad or Disconnected

        ' Compute the owners list and the controlled status
        ComputeOwners
    End If
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_txtRemoteControlOperatorsList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::m_OPC_txtAssignableUsersList_ValueChange
' Input:        none
' Output:       none
' Description:  When the list of operators controlling the territory is updated,
'               extract the list of assignable users and check if the territory
'               is assignable by the current operator
'-------------------------------------------------------------------------------
Private Sub m_OPC_txtAssignableUsersList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_txtAssignableUsersList_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_txtAssignableUsersList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_txtAssignableUsersList_ValueChange", "The status of " & m_OPC_txtAssignableUsersList.Name & " is Waiting")
    ElseIf (m_OPC_txtAssignableUsersList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_txtAssignableUsersList_ValueChange", "The status of " & m_OPC_txtAssignableUsersList.Name & " is Config Error")
    ElseIf (m_OPC_txtAssignableUsersList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_txtAssignableUsersList_ValueChange", "The status of " & m_OPC_txtAssignableUsersList.Name & " is Not Connected")
    ElseIf (m_OPC_txtAssignableUsersList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_txtAssignableUsersList_ValueChange", "The Quality of " & m_OPC_txtAssignableUsersList.Name & " is not good")
    Else '* Status and quality of the variable are good
        ' Extract the list of Users
        ReadXmlAssignableUsersList (m_OPC_txtAssignableUsersList.Value)
        ' Compute the assignability again
        ComputeIsAssignableByCurrentOperator
    End If
    
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_txtAssignableUsersList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::m_OPC_bATSSectorOutgoingRequest_ValueChange
' Input:        none
' Output:       none
' Description:  Open a popup on a request for a territory
'-------------------------------------------------------------------------------
Private Sub m_OPC_bATSSectorOutgoingRequest_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_bATSSectorOutgoingRequest_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_bATSSectorOutgoingRequest.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_bATSSectorOutgoingRequest_ValueChange", "The status of " & m_OPC_bATSSectorOutgoingRequest.Name & " is Waiting")
    ElseIf (m_OPC_bATSSectorOutgoingRequest.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_bATSSectorOutgoingRequest_ValueChange", "The status of " & m_OPC_bATSSectorOutgoingRequest.Name & " is Config Error")
    ElseIf (m_OPC_bATSSectorOutgoingRequest.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_bATSSectorOutgoingRequest_ValueChange", "The status of " & m_OPC_bATSSectorOutgoingRequest.Name & " is Not Connected")
    ElseIf (m_OPC_bATSSectorOutgoingRequest.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_bATSSectorOutgoingRequest_ValueChange", "The Quality of " & m_OPC_bATSSectorOutgoingRequest.Name & " is not good")
    Else '* Status and quality of the variable are good
        ' Check whether there is a request for a territory
        If m_OPC_bATSSectorOutgoingRequest.Value = True Then
            ' Does the territory belong to anybody?
            If m_OPClocal_bControlled.Value Then
                ' Does it belong to me (the current operator)?
                If m_OPClocal_bControlledByCurrentOperator.Value = True Then
                    ' The confirmation dialog is displayed to the user, as territory owner
                    Iconis_MOD_Navigation.OpenPopup "/iconisatsurbalis/Territory_ManualControls_HandoverRequest", m_strPath
                End If
            Else
                ' Nobody owns the territory: Accept the transfer
                If (m_OPC_bATSSectorAckOutgoingRequest.Status = fvVariableStatusWaiting) Then
                    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_bATSSectorOutgoingRequest_ValueChange", "The status of " & m_OPC_bATSSectorAckOutgoingRequest.Name & " is Waiting")
                ElseIf (m_OPC_bATSSectorAckOutgoingRequest.Status = fvVariableStatusConfigError) Then
                    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_bATSSectorOutgoingRequest_ValueChange", "The status of " & m_OPC_bATSSectorAckOutgoingRequest.Name & " is Config Error")
                ElseIf (m_OPC_bATSSectorAckOutgoingRequest.Status = fvVariableStatusNotConnected) Then
                    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_bATSSectorOutgoingRequest_ValueChange", "The status of " & m_OPC_bATSSectorAckOutgoingRequest.Name & " is Not Connected")
                Else
                    m_OPC_bATSSectorAckOutgoingRequest.Value = True
                End If
            End If
        End If
    End If

    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_bATSSectorOutgoingRequest_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::m_OPC_bIsControlLocal_ValueChange
' Input:        none
' Output:       none
' Description:  Open a popup on a request for a territory
'-------------------------------------------------------------------------------
Private Sub m_OPC_bIsControlLocal_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_bIsControlLocal_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_bIsControlLocal.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "m_OPC_bIsControlLocal_ValueChange", "The status of " & m_OPC_bIsControlLocal.Name & " is Waiting")
    ElseIf (m_OPC_bIsControlLocal.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_bIsControlLocal_ValueChange", "The status of " & m_OPC_bIsControlLocal.Name & " is Config Error")
    ElseIf (m_OPC_bIsControlLocal.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_bIsControlLocal_ValueChange", "The status of " & m_OPC_bIsControlLocal.Name & " is Not Connected")
    ElseIf (m_OPC_bIsControlLocal.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "m_OPC_bIsControlLocal_ValueChange", "The Quality of " & m_OPC_bIsControlLocal.Name & " is not good")
    Else '* Status and quality of the variable are good
        ManageMode
    End If

    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "m_OPC_bIsControlLocal_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::ComputeOwners
' Input:        none
' Output:       none
' Description:  Compute the local variables "bControlled" and "txtOwners"
'-------------------------------------------------------------------------------
Private Function ComputeOwners()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "strOwners", "Begin Subroutine")
    
    Dim strOwners As String

    ' Compute the 'Controlled' attribute of the Territory
    m_OPClocal_bControlled.Value = (m_OPC_txtLocalControlOperatorsList.Status = fvVariableStatusGood _
                                    And m_OPC_txtLocalControlOperatorsList.Value <> "") _
                                Or (m_OPC_txtRemoteControlOperatorsList.Status = fvVariableStatusGood _
                                     And m_OPC_txtRemoteControlOperatorsList.Value <> "")

    ' Initially the list is empty
    strOwners = ""
    
    ' Append the local operators list
    If m_OPC_txtLocalControlOperatorsList.Quality <> 192 Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Territory", "strOwners", "The Quality of " & m_OPC_txtLocalControlOperatorsList.Name & " is not good")
    Else
        strOwners = m_OPC_txtLocalControlOperatorsList.Value
    End If
    ' Append the remote operators list
    If m_OPC_txtRemoteControlOperatorsList.Quality = 192 Then
        '* Status and quality of the variable are good
        strOwners = strOwners & m_OPC_txtRemoteControlOperatorsList.Value
    End If
    
    ' Format the list by replacing \n by commas
    strOwners = Replace(strOwners, Chr(10) & "", ", ")
    ' If a comma ends the list, remove it
    If Right(strOwners, 2) = ", " Then
        strOwners = Mid(strOwners, 1, Len(strOwners) - 2)
    End If
    ' Refresh the list
    m_OPClocal_strOwners.Value = strOwners

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "OperatorsListChanged", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::ComputeIsControlledByCurrentOperator
' Input:        none
' Output:       none
' Description:  Find out if the current operator can control the territory
'-------------------------------------------------------------------------------
Private Sub ComputeIsControlledByCurrentOperator()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "ComputeIsControlledByCurrentOperator", "Begin Subroutine")
    
    Dim arrOperators() As String
    Dim I As Long
    
    m_OPClocal_bControlledByCurrentOperator.Value = False
    ' Parse the string. The user names are separated by LF. They may be quoted (with double-quotes).
    arrOperators = Split(m_OPC_txtLocalControlOperatorsList.Value, Chr(10))
    For I = 0 To UBound(arrOperators)
        If arrOperators(I) = ThisLibrary.Security.UserName _
            Or arrOperators(I) = """" & ThisLibrary.Security.UserName & """" Then
            m_OPClocal_bControlledByCurrentOperator.Value = True
            Exit For
        End If
    Next I
    
    ' Manage the mode
    ManageMode

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "ComputeIsControlledByCurrentOperator", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::ComputeIsAssignableByCurrentOperator
' Input:        none
' Output:       none
' Description:  Find out if the current operator can assign the list
'-------------------------------------------------------------------------------
Private Sub ComputeIsAssignableByCurrentOperator()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "ComputeIsAssignableByCurrentOperator", "Begin Subroutine")
    
    Dim I As Long

    If Not m_collAssignableUsers Is Nothing Then
        m_OPClocal_bAssignableToCurrentOperator.Value = False
        I = 1
        While I <= m_collAssignableUsers.Count And m_OPClocal_bAssignableToCurrentOperator.Value = False
            If m_collAssignableUsers.Item(I) = ThisLibrary.Security.UserName Then
                m_OPClocal_bAssignableToCurrentOperator.Value = True
            End If
            I = I + 1
        Wend
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "ComputeIsAssignableByCurrentOperator", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Territory::ManageMode
' Input:        none
' Output:       none
' Description:  Manage the mode. Open a popup when the territory is lost
'-------------------------------------------------------------------------------
Private Sub ManageMode()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "ManageMode", "Begin Subroutine")

    '* Check the status and the quality of the variables
    If m_OPC_bIsControlLocal.Status = fvVariableStatusGood Then
    
        ' Detect a loss of territory (take in emergency)
        If m_state = c_stateOwnedByMe And m_OPC_bIsControlLocal.Value = False Then
            ' If this take over has not been acknowledged by the operator
            ' and the control has changed, display the Loss Notification dialog
            If m_OPClocal_bTakeOverAcceptedByOperator.Value = False Then
                Iconis_MOD_Navigation.OpenPopup "/iconisatsurbalis/Territory_ManualControls_HandoverNotification", m_strPath
            Else
                ' Reset the acknowledgement
                m_OPClocal_bTakeOverAcceptedByOperator.Value = False
            End If
        End If
        
        ' Compute the new state of the territory
        If m_OPC_bIsControlLocal.Value And m_OPClocal_bControlledByCurrentOperator.Value Then
            ' Log a trace only if the state has changed
            If m_state <> c_stateOwnedByMe Then
                CBTrace CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "ManageMode", "Operator " & ThisLibrary.Security.UserName & " has taken the territory " & m_strName
            End If
            m_state = c_stateOwnedByMe
        Else
            ' Log a trace only if the state has changed and it is not a user login
            If m_state <> c_stateNotOwned And Not m_bUserLoginInProgress Then
                CBTrace CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "ManageMode", "Operator " & ThisLibrary.Security.UserName & " has lost control on the territory " & m_strName
            End If
            m_state = c_stateNotOwned
        End If
        
    End If

    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "ManageMode", Err.Description)
End Sub



'-------------------------------------------------------------------------------
' Name:         ReadXmlAssignableUsersList
' Input:        @param strXml string to parse
' Output:       none
' Description:  Parse the XML string containing the description of each user
'               who can assign a territory.
'-------------------------------------------------------------------------------
Private Function ReadXmlAssignableUsersList(ByRef strXml As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Territory", "ReadXmlAssignableUsersList", "Begin Function")

    Dim I As Long
    Dim oDoc As DOMDocument
    Dim oNodeListUser As IXMLDOMNodeList
    Dim oNodeClass As IXMLDOMNode

    Set oDoc = New DOMDocument
    
    For I = 0 To m_collAssignableUsers.Count - 1
        m_collAssignableUsers.Remove 1
    Next I

    '* Load the XML format string
    If oDoc.loadXML(strXml) Then
        Set oNodeListUser = oDoc.documentElement.getElementsByTagName("User")
        If (oNodeListUser.length <> 0) Then
            For Each oNodeClass In oNodeListUser
                Dim strID As String
                Dim oAttrDest As IXMLDOMAttribute

                strID = ""
                For Each oAttrDest In oNodeClass.Attributes
                    If (oAttrDest.nodeName = "Login") Then
                        '* User login
                        strID = oAttrDest.nodeValue
                    End If
                Next
                If (strID <> "") Then
                    '* Memorizes couple of data
                    m_collAssignableUsers.Add strID
                End If
            Next
        End If
        Set oNodeListUser = Nothing
    End If
    Set oDoc = Nothing

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Territory", "ReadXmlAssignableUsersList", Err.Description)
End Function












