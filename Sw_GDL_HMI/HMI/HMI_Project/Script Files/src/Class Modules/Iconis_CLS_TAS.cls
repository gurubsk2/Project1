VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_TAS"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2008. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_TAS
'* *******************************************************************************************
'* Purpose:     Manage the Territory Assignement (TAS)
'* *******************************************************************************************
'* Modification History:
'* Author:              Olivier TAYEG
'* Date:                October '09
'* Change:              All

'* Author:              Olivier TAYEG
'* Date:                March '10
'* Change:              CR ALPHA 178237
'*                      Compute the assignability based on the user ID

'* Author:              Nicole FLORIAN
'* Date:                October '10
'* Change:              CR ALPHA 200872
'*                      - Remove the constant c_strClusterName and replace it by the
'*                        call to the Iconis_MOD_General.GetOPCCluster() function in the
'*                        Class_Initialize() subroutine
'*                      - Remove the character ":" in the following constants :
'*                        c_strIncomingTransferListTag, c_strIncomingTransferStatusTag,
'*                        and c_strAcceptTransferTag
'*
'* Author:              Olivier Tayeg
'* Date:                May '11
'* Change:              CR ALPHA 230623
'*                      Adapt to S2KGAL (change in the OPC path hierarchy)

'* Author:              Olivier Tayeg
'* Date:                May '11
'* Change:              CR ALPHA 230623
'*                      Adapt to S2KGAL (change in the OPC path hierarchy)

'* Author:              Olivier TAYEG
'* Date:                May '11
'* Change:              CR ALPHA 218695
'*                      Multiscreen management
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

'* Constants
'* ------------------------------------------------------
' Path to the OPC server variables
Private Const c_strIncomingTransferListTag As String = "IconisS2K.Core.TerritoryManagement.Core.Monitor.Core.OpIncomingTransferList"
Private Const c_strIncomingTransferStatusTag As String = "IconisS2K.Core.TerritoryManagement.Core.Monitor.Core.OpIncomingTrStatusCode"
Private Const c_strAcceptTransferTag As String = "IconisS2K.Core.TerritoryManagement.Core.Monitor.Core.AcceptTransfer"

'* Class attributes
'* ------------------------------------------------------
' List of the territories
Private m_Territories As Collection

'* Local OPC variables
'* ------------------------------------------------------

'* OPC server's variables
'* ------------------------------------------------------
' Incoming transfer for the operator
Private WithEvents m_OPC_iIncomingTransferStatus As Variable
Attribute m_OPC_iIncomingTransferStatus.VB_VarHelpID = -1
' List of the territories in the transfer
Private WithEvents m_OPC_strIncomingTransferList As Variable
Attribute m_OPC_strIncomingTransferList.VB_VarHelpID = -1
' Enables to clear a transfer
Private m_OPC_bAcceptTransfer As Variable

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::AddTerritory
' Input:        strPath [String]     Path to the territory
' Output:       none
' Description:  Notify the module to manage another territory
'-------------------------------------------------------------------------------
Public Function AddTerritory(strPath As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "AddTerritory", "Begin Subroutine")
    
    Dim Territory As Iconis_CLS_Territory
    
    Set Territory = New Iconis_CLS_Territory
    Territory.Init strPath
    m_Territories.Add Territory

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "AddTerritory", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Get Iconis_CLS_TAS::lTerritoriesCount
' Input:        none
' Output:       [Long]        name of the territory
' Description:  Return the name of the territory
'-------------------------------------------------------------------------------
Public Property Get lTerritoriesCount() As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "lTerritoriesCount", "Begin Subroutine")
        
    If Not m_Territories Is Nothing Then
        lTerritoriesCount = m_Territories.Count
    Else
        lTerritoriesCount = 0
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "lTerritoriesCount", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::get_Item
' Input:        lIndex [Long]               Index of territory
' Output:       [Iconis_CLS_Territory]      The territory
' Description:  Return the territory
'-------------------------------------------------------------------------------
Public Property Get Item(lIndex As Long) As Iconis_CLS_Territory
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "Item", "Begin Subroutine")
        
    If Not m_Territories Is Nothing Then
        If lIndex >= 0 And lIndex < m_Territories.Count Then
            Set Item = m_Territories.Item(lIndex + 1)
        Else
            Set Item = Nothing
        End If
    Else
        Set Item = Nothing
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "Item", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::IsUserAssignableForTerritory
' Input:        strUser [String]     Name of the user
'               strTerritory [String]     Name of the territory
' Output:       [Boolean]               True if the user can be assigned
' Description:  Returns True if the user can be assigned to the territory
'-------------------------------------------------------------------------------
Public Function IsUserAssignableForTerritory(strUser As String, strTerritory As String) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "ListAssignableUsersForTerritory", "Begin Subroutine")
    
    Dim collAssignableUsers As Collection
    Dim strAssignableUser As Variant
    
    Set collAssignableUsers = ListAssignableUsersForTerritory(strTerritory)
    For Each strAssignableUser In collAssignableUsers
        If strAssignableUser = strUser Then
            IsUserAssignableForTerritory = True
            Exit For
        End If
    Next strAssignableUser

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "IsUserAssignableForTerritory", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::IsUserAssignableForAllTerritories
' Input:        strUser [String]     Name of the user
' Output:       [Boolean]            True if the user can be assigned
' Description:  Returns True if the user is allowed to receive all the territories from the current operator
'-------------------------------------------------------------------------------
Public Function IsUserAssignableForAllTerritories(strUser As String) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "IsUserAssignableForAllTerritories", "Begin Subroutine")
    
    Dim collAssignableUsers As Collection
    Dim strAssignableUser As Variant
    
    Set collAssignableUsers = ListAssignableUsersForAllTerritories
    If Not collAssignableUsers Is Nothing Then
        For Each strAssignableUser In collAssignableUsers
            If strAssignableUser = strUser Then
                IsUserAssignableForAllTerritories = True
                Exit For
            End If
        Next strAssignableUser
    End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "IsUserAssignableForAllTerritories", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::ListTerritoriesToReleaseBeforeLogoff
' Input:        none
' Output:       [Collection]    List of territories names (string)
' Description:  List the territories which must be released before a logoff
'-------------------------------------------------------------------------------
Public Function ListTerritoriesToReleaseBeforeLogoff() As Collection
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "ListTerritoriesToReleaseBeforeLogoff", "Begin Subroutine")

    Dim Territory As Iconis_CLS_Territory

    Set ListTerritoriesToReleaseBeforeLogoff = New Collection
    
    For Each Territory In m_Territories
        If Territory.bIsControlledByCurrentOperator And Not Territory.bAutomaticRelease Then
            ListTerritoriesToReleaseBeforeLogoff.Add Territory.strName
        End If
    Next Territory

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "ListTerritoriesToReleaseBeforeLogoff", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::XmlTerritoriesAssignation
' Input:        none
' Output:       [String]        Assignation list
'                               <Territories>
'                                   <Territory ID="xx" Name="xx">
'                                       <User Login="xx"/>
'                                       <User ... />
'                                   </Territory>
'                                   <Territory ... />
'                               </Territories>
' Description:  Compute a list which gives for each territory the list of users
'               who are allowed to take control for all territories
'-------------------------------------------------------------------------------
Public Property Get XmlTerritoriesAssignation() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "get_XmlTerritoriesAssignation", "Begin Subroutine")

    Dim oDoc As DOMDocument
    Dim oNodeRoot As IXMLDOMNode
    Dim oNodeTerritory As IXMLDOMElement
    Dim oNodeUser As IXMLDOMElement
    Dim Territory As Iconis_CLS_Territory
    Dim strUserID As Variant
    
    Set oDoc = New DOMDocument
    Set oNodeRoot = oDoc.createElement("Territories")
    oDoc.appendChild oNodeRoot
    
    For Each Territory In m_Territories
        Set oNodeTerritory = oDoc.createElement("Territory")
        oNodeTerritory.setAttribute "ID", Territory.strID
        oNodeTerritory.setAttribute "Name", Territory.strName
        For Each strUserID In Territory.collAssignableUsers
            Set oNodeUser = oDoc.createElement("User")
            oNodeUser.setAttribute "Login", strUserID
            oNodeTerritory.appendChild oNodeUser
            Set oNodeUser = Nothing
        Next strUserID
        oNodeRoot.appendChild oNodeTerritory
        Set oNodeTerritory = Nothing
    Next Territory
    
    XmlTerritoriesAssignation = oDoc.xml
    
    Set oDoc = Nothing

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "get_XmlTerritoriesAssignation", Err.Description)

End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::XmlTerritoriesAssignation
' Input:        strXml [String]     Assignation list
'                                   <Territories>
'                                       <Territory ID="xx" Name="xx">
'                                           <User Login="xx"/>
'                                           <User ... />
'                                       </Territory>
'                                       <Territory ... />
'                                   </Territories>
' Output:       none
' Description:  Set the assignation user lists for the territories
'-------------------------------------------------------------------------------
Public Property Let strXmlTerritoriesAssignation(strXml As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "set_XmlTerritoriesAssignation", "Begin Subroutine")

    Dim oDoc As DOMDocument
    Dim oNodeTerritory As IXMLDOMNode
    Dim oNodeListTerritory As IXMLDOMNodeList
    Dim oAttr As IXMLDOMAttribute
    Dim Territory As Iconis_CLS_Territory
    
    
    Set oDoc = New DOMDocument
    
    If oDoc.loadXML(strXml) Then
        Set oNodeListTerritory = oDoc.getElementsByTagName("Territory")
        For Each oNodeTerritory In oNodeListTerritory
            For Each oAttr In oNodeTerritory.Attributes
                Select Case oAttr.nodeName
                    Case "ID"
                        For Each Territory In m_Territories
                            If Territory.strID = oAttr.Value Then
                                ' Transform the Territory node into a Users node
                                Dim oNodeUsers As IXMLDOMElement
                                Dim oNodeUser As IXMLDOMNode
                                Set oNodeUsers = oDoc.createElement("Users")
                                For Each oNodeUser In oNodeTerritory.childNodes
                                    oNodeUsers.appendChild oNodeUser
                                Next oNodeUser

                                ' Send the new list for this territory
                                Territory.strAssignableUsersList = oNodeUsers.xml
                                Set oNodeUsers = Nothing
                                Exit For
                            End If
                        Next Territory
                End Select
            Next oAttr
        Next oNodeTerritory
        Set Territory = Nothing
        Set oNodeListTerritory = Nothing
        Set oDoc = Nothing
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "set_XmlTerritoriesAssignation", Err.Description)
End Property

'================================================================
'                        Internal functions
'================================================================

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::Class_Initialize
' Input:        none
' Output:       none
' Description:  Object constructor.
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "Class_Initialize", "Begin Subroutine")
    
    ' Create the collection
    Set m_Territories = New Collection
    
    '* Adding the server variables to the collection of subscribed variables
    Set m_OPC_iIncomingTransferStatus = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strIncomingTransferStatusTag, fvVariableTypeRegister)
    Set m_OPC_strIncomingTransferList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strIncomingTransferListTag, fvVariableTypeText)
    
    '* OPC variable to connect the method plugs
    Set m_OPC_bAcceptTransfer = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strAcceptTransferTag, fvVariableTypeBit)

    ' Enable the refreshments
    If (m_OPC_iIncomingTransferStatus.EnableEvents = True) Then
        m_OPC_iIncomingTransferStatus_ValueChange
    Else
        m_OPC_iIncomingTransferStatus.EnableEvents = True
    End If

    If (m_OPC_strIncomingTransferList.EnableEvents = True) Then
        m_OPC_strIncomingTransferList_ValueChange
    Else
        m_OPC_strIncomingTransferList.EnableEvents = True
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "Class_Initialize", Err.Description)

End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor.
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "Class_Terminate", "Begin Subroutine")
    
    ' Unsubscribe all the variables previously subscribed
    If Not (m_OPC_iIncomingTransferStatus Is Nothing) Then
        Variables.Remove (m_OPC_iIncomingTransferStatus.Name)
        Set m_OPC_iIncomingTransferStatus = Nothing
    End If
    If Not (m_OPC_strIncomingTransferList Is Nothing) Then
        Variables.Remove (m_OPC_strIncomingTransferList.Name)
        Set m_OPC_strIncomingTransferList = Nothing
    End If
    If Not (m_OPC_bAcceptTransfer Is Nothing) Then
        Variables.Remove (m_OPC_bAcceptTransfer.Name)
        Set m_OPC_bAcceptTransfer = Nothing
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "Class_Terminate", Err.Description)

End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::ListAssignableUsersForTerritory
' Input:        strName [String]     Name of the territory
' Output:       [Collection]         List of users
' Description:  List the users who are allowed to assign the territory
'-------------------------------------------------------------------------------
Private Function ListAssignableUsersForTerritory(strName As String) As Collection
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "ListAssignableUsersForTerritory", "Begin Subroutine")
    
    Dim Territory As Iconis_CLS_Territory
    
    Set ListAssignableUsersForTerritory = Nothing
    For Each Territory In m_Territories
        If Territory.strName = strName Then
            Set ListAssignableUsersForTerritory = Territory.collAssignableUsers
            Exit For
        End If
    Next Territory

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "ListAssignableUsersForTerritory", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::ListAssignableUsersForAllTerritories
' Input:        none
' Output:       [Collection]         List of users
' Description:  List the users who are allowed to assign all the territories
'-------------------------------------------------------------------------------
Private Function ListAssignableUsersForAllTerritories() As Collection
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "ListAssignableUsersForAllTerritories", "Begin Subroutine")

    Dim Territory As Iconis_CLS_Territory
    Dim strLogin As String

    Set ListAssignableUsersForAllTerritories = Nothing
    
    ' There is also a plug OperatorTerritories to get the list of all territories
    For Each Territory In m_Territories
        If Territory.bIsControlledByCurrentOperator Then
            If ListAssignableUsersForAllTerritories Is Nothing Then
                ' For the first territory, initialize the collection
                Set ListAssignableUsersForAllTerritories = Territory.collAssignableUsers
            Else
                ' Get the list of assignable users for this territory
                Dim collListUsers As Collection
                Dim I As Long
                Set collListUsers = Territory.collAssignableUsers
                
                I = 1
                ' For each user in the current collection of assignable users, see if it is in the assignable
                ' users for this territory also
                Do While I <= ListAssignableUsersForAllTerritories.Count
                    If Territory.IsAssignableTo(ListAssignableUsersForAllTerritories.Item(I)) = False Then
                        ' Not assignable for this territory: Remove the user
                        ListAssignableUsersForAllTerritories.Remove I
                    Else
                        ' This user is OK, go on
                        I = I + 1
                    End If
                Loop
            End If
        End If
    Next Territory

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "ListAssignableUsersForAllTerritories", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::m_OPC_iIncomingTransferStatus_ValueChange
' Input:        none
' Output:       none
' Description:  Auto-clear the transfer when an incoming transfer is aborted (by the sender)
'-------------------------------------------------------------------------------
Private Sub m_OPC_iIncomingTransferStatus_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "m_OPC_iIncomingTransferStatus_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_iIncomingTransferStatus.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "m_OPC_iIncomingTransferStatus_ValueChange", "The status of " & m_OPC_iIncomingTransferStatus.Name & " is Waiting")
    ElseIf (m_OPC_iIncomingTransferStatus.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "m_OPC_iIncomingTransferStatus_ValueChange", "The status of " & m_OPC_iIncomingTransferStatus.Name & " is Config Error")
    ElseIf (m_OPC_iIncomingTransferStatus.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TAS", "m_OPC_iIncomingTransferStatus_ValueChange", "The status of " & m_OPC_iIncomingTransferStatus.Name & " is Not Connected")
    ElseIf (m_OPC_iIncomingTransferStatus.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TAS", "m_OPC_iIncomingTransferStatus_ValueChange", "The Quality of " & m_OPC_iIncomingTransferStatus.Name & " is not good")
    Else '* Status and quality of the variable are good
        Select Case m_OPC_iIncomingTransferStatus.Value
            Case 5  ' Transfer aborted by the other party (sender): let's clear it
                ' Check the status and the quality of the OPC variable related to the command
                If (m_OPC_bAcceptTransfer.Status = fvVariableStatusWaiting) Then
                    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "btnOK_Click", "The status of " & m_OPC_bAcceptTransfer.Name & " is Waiting")
                ElseIf (m_OPC_bAcceptTransfer.Status = fvVariableStatusConfigError) Then
                    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "btnOK_Click", "The status of " & m_OPC_bAcceptTransfer.Name & " is Config Error")
                ElseIf (m_OPC_bAcceptTransfer.Status = fvVariableStatusNotConnected) Then
                    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TAS", "btnOK_Click", "The status of " & m_OPC_bAcceptTransfer.Name & " is Not Connected")
                Else
                    ' Clear the transfer by controlling the plug (any value)
                    m_OPC_bAcceptTransfer.Value = True
                End If
        End Select

    End If

    Exit Sub
ErrorHandler:
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "m_OPC_iIncomingTransferStatus_ValueChange", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_TAS::m_OPC_strIncomingTransferList_ValueChange
' Input:        none
' Output:       none
' Description:  Extract the territories in the transfer
'-------------------------------------------------------------------------------
Private Sub m_OPC_strIncomingTransferList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "m_OPC_strIncomingTransferList_ValueChange", "Begin Subroutine")

    '* Check the status and the quality of the variable
    If (m_OPC_strIncomingTransferList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_TAS", "m_OPC_strIncomingTransferList_ValueChange", "The status of " & m_OPC_strIncomingTransferList.Name & " is Waiting")
    ElseIf (m_OPC_strIncomingTransferList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "m_OPC_strIncomingTransferList_ValueChange", "The status of " & m_OPC_strIncomingTransferList.Name & " is Config Error")
    ElseIf (m_OPC_strIncomingTransferList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TAS", "m_OPC_strIncomingTransferList_ValueChange", "The status of " & m_OPC_strIncomingTransferList.Name & " is Not Connected")
    ElseIf (m_OPC_strIncomingTransferList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_TAS", "m_OPC_strIncomingTransferList_ValueChange", "The Quality of " & m_OPC_strIncomingTransferList.Name & " is not good")
    Else '* Status and quality of the variable are good
        Dim arrStrTerritories() As String
        Dim bFound As Boolean
        Dim I As Long
        Dim lTerritoryIndex As Long

            arrStrTerritories = Split(m_OPC_strIncomingTransferList.Value, Chr(10))
            
            For lTerritoryIndex = 1 To m_Territories.Count
                ' Try to find the territory in the array
                bFound = False
                For I = 0 To UBound(arrStrTerritories) - 1
                    If arrStrTerritories(I) = m_Territories.Item(lTerritoryIndex).strName Then
                       bFound = True
                       Exit For
                    End If
                Next I
                ' This territory is part of the Transfer
                m_Territories.Item(lTerritoryIndex).bIncomingTransfer = bFound
            Next lTerritoryIndex
                
    End If

    Exit Sub
ErrorHandler:
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_TAS", "m_OPC_strIncomingTransferList_ValueChange", Err.Description)
End Sub
