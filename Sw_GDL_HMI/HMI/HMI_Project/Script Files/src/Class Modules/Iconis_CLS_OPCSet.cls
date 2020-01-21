VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_OPCSet"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2009. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_OPCSet
'* *******************************************************************************************
'* Purpose:     Manage a connection to several OPC variables.
'*              Uses Iconis_CLS_OPCSet_Item.
'* *******************************************************************************************
'* Modification History:

'* Author:              Olivier TAYEG
'* Date:                November '09
'* Change:              All

'* Author:              Olivier TAYEG
'* Date:                June '10
'* Change:              Management of access modes and individual connection of the items

'* Author:              Nicole FLORIAN
'* Date:                August '10
'* Change:              CR 195069 : Fix the Status property

'* Author:              Olivier TAYEG
'* Date:                July '11
'* Change:              Adjust trace levels

'* Author:              Nicole FLORIAN
'* Date:                September '12
'* Change:              CRs ALPHA 286429 and 286430
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

'* Declarations
'* ------------------------------------------------------
Option Explicit


'* Constants
'* ------------------------------------------------------

' Enumeration of the available OPCSet types. Each type defines a behaviour for the notification events.
Public Enum enumOPCSetType
    ' Type "Connection": to use when a control has to be performed
    '   - Send OnConnection events only if all the variables are connected (with a good or a bad quality)
    '   - Send OnDisconnection event if a variable is disconnected
    '   - Send OnRefresh events when a variable is disconnected, or the value changes, or the quality changes
    c_OPCSetTypeConnection = 0

    ' Type "Read": to use when only values with good quality are accepted
    '   - Send OnConnection events only if all the variables are connected with a good quality
    '   - Send OnDisconnection event if a variable is disconnected or has a bad quality
    '   - Send OnRefresh events only if the variable is connected and the value changes with a good quality
    c_OPCSetTypeRead = 1
End Enum


Private Enum enumOPCSetState
    ' The OPCSet is not initialized.
    c_StatusInitial
    ' The variables are being connected.
    c_StatusFirstConnection
    ' All the variables are connected with a good state.
    c_StatusConnected
    ' Some variables are not connected with a good state.
    c_StatusDisconnected
End Enum


'* Class attributes
'* ------------------------------------------------------

' Type of the OPCSet
Private m_type As enumOPCSetType
' State of the OPCSet
Private m_state As enumOPCSetState
' Internal name used to designate the OPCSet in the traces
Private m_strName As String

' Collection of the variables in the OPCSet
' WARNING : Class_Terminate will never be called as long as the collection is not empty (see "Destroy" method)
Private m_coItems As Collection
' Number of variables that are still to connect
Private m_iVariablesToConnect As Integer


'================================================================
'           Events definitions for the user object
'================================================================

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::OnRefresh
' Input:        @param lIndex                              the zero-based index
'               @param Value [Variant]                     the new value
'               @param Status [fvVariableStatus]           the new status
' Output:       none
' Description:  Raised when one variable is updated
'-------------------------------------------------------------------------------
Public Event OnRefresh(lIndex As Long, Value As Variant, Status As fvVariableStatus)

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::OnConnection
' Input:        @param arrValue [Variant()]                the values of the OPC items
'               @param arrStatus [fvVariableStatus()]      the corresponding statuses
' Output:       none
' Description:  Raised when all the variables in the OPCSet are connected
'-------------------------------------------------------------------------------
Public Event OnConnection(arrValue() As Variant, arrStatus() As fvVariableStatus)

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::OnDisconnection
' Input:        none
' Output:       none
' Description:  Raised when there is a disconnection for at least one variable
'               A "OnConnection" event will be raised when all the variables
'               are connected again.
'-------------------------------------------------------------------------------
Public Event OnDisconnection()


'================================================================
'               Public functions declarations
'================================================================


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::AddItem
' Input:        @param strPath [String]                     Path to the OPC item to connect
'               @param VarType [FrontVue.fvVariableType]    Type
'               @param AccessMode [enumOPCAccessMode]       Access mode
' Output:       @return [Iconis_CLS_OPCSet_Item]            OPC item object created
' Description:  Add a new item to the OPCSet
'-------------------------------------------------------------------------------
Public Function AddItem(strPath As String, VarType As fvVariableType, AccessMode As enumOPCAccessMode) As Iconis_CLS_OPCSet_Item
On Error GoTo ErrorHandler

    ' Create the Iconis_CLS_OPCSet_Item object
    Set AddItem = New Iconis_CLS_OPCSet_Item
    AddItem.Init strPath, VarType, AccessMode, Me, m_coItems.Count
    ' Add the Iconis_CLS_OPCSet_Item object in the collection
    m_coItems.Add AddItem
    
    ' If the OPCSet is already connected, initiate the connection to this new item
    If m_state <> c_StatusInitial And m_state <> c_StatusFirstConnection Then
        OPCSetTrace CBTRACE_VBA, "AddItem", "The OPCSet now holds " & m_coItems.Count & " variable(s)"
        AddItem.DoConnect
    End If

    Exit Function
    
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "AddItem", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::DoConnect
' Input:        @param arrStrPath [String()]                Variables to connect
'               @param arTypes [FrontVue.fvVariableType()]  Types for each variable
' Output:       @return success (True) or failure (False)
' Description:  Perform the connection to the variables
'-------------------------------------------------------------------------------
Public Function DoConnect(strOPCSetName As String)
On Error GoTo ErrorHandler

    Dim Item As Iconis_CLS_OPCSet_Item
    Dim I As Integer

    If m_state = c_StatusInitial Then
        ' We want to connect the items
        m_state = c_StatusFirstConnection
        
        ' Store the name
        m_strName = strOPCSetName
        
        m_iVariablesToConnect = m_coItems.Count
        OPCSetTrace CBTRACE_VBA, "DoConnect", "Initiating connection to " & m_iVariablesToConnect & " variable(s)"
         
        For Each Item In m_coItems
            Item.DoConnect
        Next Item
    Else
        Call OPCSetTrace(CBTRACEF_ALWAYS, "DoConnect", "Error (Not implemented): The OPCSet is already connected, call Destroy first")
    End If
    
    Exit Function
    
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "DoConnect", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::Connect
' Input:        @param arrStrPath [String()]                 Variables to connect
'               @param VarType [FrontVue.fvVariableType]   Type of all variables
' Output:       @return success (True) or failure (False)
' Description:  Connect the variables using the same type.
'               After Connect, the user object must call Destroy.
'-------------------------------------------------------------------------------
Public Function Connect(arrStrPath() As String, VarType As fvVariableType, OPCSetType As enumOPCSetType, Optional OPCSetName As String) As Boolean
On Error GoTo ErrorHandler

    Dim iFirstIndex As Integer
    Dim iLastIndex As Integer
    Dim arTypes() As fvVariableType
    Dim I As Integer

    Connect = False
    
    ' Retrieve number of elements and the first element index in the array
    m_iVariablesToConnect = CheckArray(arrStrPath, iFirstIndex)
    iLastIndex = iFirstIndex + m_iVariablesToConnect - 1
    ' Error : Empty array
    If Not m_iVariablesToConnect > 0 Then
        Connect = False
        Exit Function
    End If
    
    ReDim arTypes(iFirstIndex To iLastIndex)
    
    For I = iFirstIndex To iLastIndex
        arTypes(I) = VarType
    Next I
    
    Connect = ConnectWithTypes(arrStrPath, arTypes, OPCSetType, OPCSetName)
    
Exit Function
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "Connect", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::ConnectWithTypes
' Input:        @param arrStrPath [String()]                Variables to connect
'               @param arTypes [FrontVue.fvVariableType()]  Types for each variable
' Output:       @return success (True) or failure (False)
' Description:  Connect the variables
'               After Connect, the user object must call Destroy.
'-------------------------------------------------------------------------------
Public Function ConnectWithTypes(arrStrPath() As String, arTypes() As fvVariableType, OPCSetType As enumOPCSetType, Optional OPCSetName As String) As Boolean
On Error GoTo ErrorHandler

    Dim iFirstIndex As Integer
    Dim iLastIndex As Integer
    Dim Item As Iconis_CLS_OPCSet_Item
    Dim I As Integer
    Dim AccessMode As enumOPCAccessMode
     
    ConnectWithTypes = False
    
    ' Convert the OPCSet type into an access mode for the underlying OPC items
    m_type = OPCSetType
    Select Case OPCSetType
        Case c_OPCSetTypeConnection
            AccessMode = c_OPCReadWriteQuality
        Case c_OPCSetTypeRead
            AccessMode = c_OPCReadWrite
    End Select
    
    ' Retrieve number of elements and the first element index in the array
    m_iVariablesToConnect = CheckArray(arrStrPath, iFirstIndex)
    iLastIndex = iFirstIndex + m_iVariablesToConnect - 1
    
    ' Error : Empty array
    If m_iVariablesToConnect <= 0 Then
        ConnectWithTypes = False
        Exit Function
    End If
    
    ' Store the name
    If OPCSetName <> "" Then
        m_strName = OPCSetName
    Else
        m_strName = arrStrPath(0)
    End If

    OPCSetTrace CBTRACE_VBA, "ConnectWithTypes", "Initiating connection to " & m_iVariablesToConnect & " variable(s)"

    ' We want to connect the items
    m_state = c_StatusFirstConnection

    ' Iterate each variables name in the array,
    ' create a Iconis_CLS_OPCSet_Item object for each one and connect the associated variable
    For I = iFirstIndex To iLastIndex
        ' Create the Iconis_CLS_OPCSet_Item object
        Set Item = New Iconis_CLS_OPCSet_Item
        ' Add the Iconis_CLS_OPCSet_Item object in the collection
        m_coItems.Add Item
        ' Call the Iconis_CLS_OPCSet_Item object function "Connect" with the variable name and the OPCSet object (keyword "Me") as parameters
        ' The item object will callback the caller ("Me") when the variable is refreshed
        Item.Connect arrStrPath(I), arTypes(I), AccessMode, Me, CLng(I)
    Next I
    
    ' Everything worked correctly, return "True" to the caller
    ConnectWithTypes = True

    Exit Function
    
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "ConnectWithTypes", Err.Description)
End Function


'---------------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::Destroy
' Input:        none
' Output:       none
' Description:  Reset the OPCSet object.
'               This method MUST be called by the client object to free the memory.
'---------------------------------------------------------------------------------------
Public Function Destroy()
On Error GoTo ErrorHandler

    Dim I As Long

    OPCSetTrace CBTRACE_VBA, "Destroy", "Disconnecting from the " & m_coItems.Count & " variable(s)"
    If m_iVariablesToConnect > 0 Then
        OPCSetTrace CBTRACEF_ALWAYS, "Destroy", "Warning: The OPCSet was still waiting for the connection of  " & m_iVariablesToConnect & " variable(s)"
    End If
    
    ' Iterate each object in the collection, delete it and remove it from the collection
    For I = 1 To m_coItems.Count
        ' Since collections are reindexed automatically, delete and remove the first member on each iteration
        m_coItems.Remove 1
    Next I

    ' Reset the variable members
    m_iVariablesToConnect = 0
    m_state = c_StatusInitial
    
Exit Function
ErrorHandler:
        Call OPCSetTrace(CBTRACEF_ALWAYS, "Destroy", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::WriteValues
' Input:        @param arrValue [Variant()]         values to write
' Output:       @return 0   if success
'                       else the number of variables that could not be written
' Description:  Write the given values to all the variables in the OPCSet
'-------------------------------------------------------------------------------
Public Function WriteValues(arrValue() As Variant) As Long
On Error GoTo ErrorHandler
   
    Dim I As Long
    Dim Status As fvVariableStatus
    
    WriteValues = UBound(arrValue) + 1
    
    If WriteValues <> m_coItems.Count Then
        OPCSetTrace CBTRACEF_ALWAYS, "WriteValues", "Error: The number of values do not match the items count in the OPCSet"
    End If
    
    ' Reject if the status is not yet ready
    If m_state <> c_StatusConnected Then
        OPCSetTrace CBTRACEF_ALWAYS, "WriteValues", "Error: Impossible to send data, the OPCSet is not connected"
        Exit Function
    End If
    
    For I = 1 To m_coItems.Count
        Status = m_coItems.Item(I).Status
        If m_coItems.Item(I).bIsWritable Then
            m_coItems.Item(I).Value = arrValue(I - 1)
            WriteValues = WriteValues - 1
        End If
    Next I

Exit Function
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "WriteValues", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::get_Item
' Input:        @param index [Long]                    index to the variable (as used in Connect)
' Output:       @return [OPC_OPCSet_Item]     the variable
' Description:  Obtain a variable present in the OPCSet
'-------------------------------------------------------------------------------
Public Property Get Item(index As Long) As Iconis_CLS_OPCSet_Item
On Error GoTo ErrorHandler

    Set Item = m_coItems(index + 1)

Exit Property
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "Property Get Item", Err.Description)
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::get_IsAllConnected
' Input:        none
' Output:       @return [Boolean]     whether all variables are connected
' Description:  Get the connected status of the OPCSet
'-------------------------------------------------------------------------------
Public Property Get IsAllConnected() As Boolean
On Error GoTo ErrorHandler

    IsAllConnected = (m_state = c_StatusConnected)
    
Exit Property
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "get_IsAllConnected", Err.Description)
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::get_IsAllGood
' Input:        none
' Output:       @return [Boolean]     whether all variables are good
' Description:  Get the good status of the OPCSet
'-------------------------------------------------------------------------------
Public Property Get IsAllGood() As Boolean
On Error GoTo ErrorHandler

    IsAllGood = (m_state = c_StatusConnected)
    
Exit Property
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "get_IsAllGood", Err.Description)
End Property


'==================================================================================
'           Callback functions (declared as Public, should not be used by users)
'==================================================================================



'---------------------------------------------------------------------------------------
' Name:         ItemConnected
' Input:        lIndex  [Long]                  Index in the OPCSet of the item
'               newstatus [fvVariableStatus]    New status of the item
'                                               (ConfigError Or NotConnected Or Waiting) = disconnected
'                                               (Bad) = bad quality
'                                               (Good) = good quality
' Output:       none
' Description:  Method ("callback") called from the Iconis_CLS_OPCSet_Item objects
'               to notify that one OPC item was connected
'               This happens on the first connection after the initialization
'               or a disconnection event
'---------------------------------------------------------------------------------------
Public Sub ItemConnected(index As Long)
On Error GoTo ErrorHandler

    If m_state > c_StatusInitial Then
        ' A new variable has been connected
        m_iVariablesToConnect = m_iVariablesToConnect - 1
        
        ' Are every items connected?
        If m_iVariablesToConnect <= 0 Then
            If m_state = c_StatusDisconnected Then
                ' Everything connected, after a disconnection event
                OPCSetTrace CBTRACE_VAR, "ItemConnected", "OPCSet reconnected."
            Else
                ' Initial connection
                OPCSetTrace CBTRACE_VAR, "ItemConnected", "All the variables are connected."
            End If
            m_state = c_StatusConnected

            ' Now prepare to fire the "OnConnection" event
            Dim arStrVarValues() As Variant
            Dim arVarStatus() As fvVariableStatus
            Dim Item As Iconis_CLS_OPCSet_Item
            Dim I As Integer
            
            ReDim arStrVarValues(0 To m_coItems.Count - 1)
            ReDim arVarStatus(0 To m_coItems.Count - 1)
            I = 0
            
            For Each Item In m_coItems
                ' For each variable retrieve the value and status
                If Item.bIsReadable Then
                    arStrVarValues(I) = Item.Value
                End If
                arVarStatus(I) = Item.Status
                I = I + 1
            Next
    
            ' Fire the "OnConnection" event
            RaiseEvent OnConnection(arStrVarValues, arVarStatus)
            
            ' Now prepare to fire "OnRefresh" events for all the items
            For Each Item In m_coItems
                Item.ForceRefresh
            Next Item
        End If
    End If

Exit Sub
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "ItemConnected", Err.Description)
End Sub


'---------------------------------------------------------------------------------------
' Name:         ItemDisconnected
' Input:        lIndex  [Long]                  Index in the OPCSet of the item
'               newstatus [fvVariableStatus]    New status of the item
'                                               (ConfigError Or NotConnected Or Waiting) = disconnected
'                                               (Bad) = bad quality
'                                               (Good) = good quality
' Output:       none
' Description:  Method ("callback") called from the Iconis_CLS_OPCSet_Item objects
'               to notify that an OPC item was disconnected
'---------------------------------------------------------------------------------------
Public Sub ItemDisconnected(index As Long)
On Error GoTo ErrorHandler

    If m_state > c_StatusInitial Then
        ' A variable has been disconnected
        m_iVariablesToConnect = m_iVariablesToConnect + 1
        
        If m_state = c_StatusConnected Then
            OPCSetTrace CBTRACE_VAR, "ItemDisconnected", "OPCSet disconnected."
            m_state = c_StatusDisconnected

            ' Fire the "OnDisconnection" event
            RaiseEvent OnDisconnection
        End If
    End If

Exit Sub
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "ItemDisconnected", Err.Description)
End Sub


'---------------------------------------------------------------------------------------
' Name:         ItemRefreshed
' Input:        lIndex  [Long]                  Index in the OPCSet of the item
' Output:       none
' Description:  Method ("callback") called from the Iconis_CLS_OPCSet_Item objects
'               to notify that the value of one OPC item changed.
'---------------------------------------------------------------------------------------
Public Sub ItemRefreshed(index As Long)
On Error GoTo ErrorHandler

    If m_state = c_StatusConnected Then
        RaiseEvent OnRefresh(index, m_coItems(index + 1).Value, m_coItems(index + 1).Status)
        m_coItems(index + 1).ForceRefresh
    End If

Exit Sub
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "ItemRefreshed", Err.Description)
End Sub


'================================================================
'                        Internal functions
'================================================================

'---------------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::Class_Initialize
' Input:        none
' Output:       none
' Description:  Constructor
'---------------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler

    Set m_coItems = New Collection
    m_state = c_StatusInitial
    m_iVariablesToConnect = 0

    Exit Sub
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "Class_Initialize", Err.Description)
End Sub


'---------------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::Class_Terminate
' Input:        none
' Output:       none
' Description:  Destructor
'---------------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler

    OPCSetTrace CBTRACE_VBA, "Terminate", "Terminating the instance"
    
    ' Delete the collection object
    Set m_coItems = Nothing
    
    On Error GoTo 0
    Exit Sub
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "Class_Terminate", Err.Description)
End Sub



'---------------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::OPCSetTrace
' Input:        lLevel [Long]           Level of trace (see CB documentation)
'               strFunction [String]    Name of the function
'               strDescription [String] Trace text
' Output:       none
' Description:  Specific trace function for the class
'---------------------------------------------------------------------------------------
Private Sub OPCSetTrace(lLevel As Long, strFunction As String, strDescription As String)
    Dim strTrace As String
    strTrace = "OPCSet [" & m_strName
    Select Case m_type
        Case c_OPCSetTypeConnection
            strTrace = strTrace & ", type Connection] - "
        Case c_OPCSetTypeRead
            strTrace = strTrace & ", type Read] - "
    End Select
    strTrace = strTrace & strDescription
    CBTrace lLevel, "Iconis_CLS_OPCSet", strFunction, strTrace
End Sub


'---------------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet::CheckArray
' Input:        @param  arVar       [Array]     Data to check
' Output:       @param  iFirstIndex [Integer]   Index of the first element
'               @return             [Integer]   Number of elements in the array
' Description:  Check that a data is an array, retrieve the number of elements
'               and compute the first index in the array
'---------------------------------------------------------------------------------------
Private Function CheckArray(ByVal arVar As Variant, ByRef iFirstIndex As Integer) As Integer
On Error GoTo ErrorHandler

    Dim iUBound As Integer

    ' Initialize the number of elements to 0
    CheckArray = 0
    ' Check that the data is an array
    If VarType(arVar) & vbArray Then
        ' Retrieve the first and last indexes
        iFirstIndex = LBound(arVar)
        iUBound = UBound(arVar)
        ' Calculate the number of elements
        CheckArray = iUBound - iFirstIndex + 1
    End If

Exit Function
ErrorHandler:
    Call OPCSetTrace(CBTRACEF_ALWAYS, "CheckArray", Err.Description)
End Function


