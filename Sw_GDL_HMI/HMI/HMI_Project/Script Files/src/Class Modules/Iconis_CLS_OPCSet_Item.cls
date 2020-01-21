VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_OPCSet_Item"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2009. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_OPCSet_Item
'* *******************************************************************************************
'* Purpose:     Manage one variable that belongs to an Iconis_CLS_OPCSet
'* *******************************************************************************************
'* Modification History:

'* Author:              Olivier TAYEG
'* Date:                November '09
'* Change:              All

'* Author:              Olivier TAYEG
'* Date:                June '10
'* Change:              Management of the access modes

'* Author:              Olivier TAYEG
'* Date:                September '10
'* Change:              No refresh notification when the access mode is WO

'* Author:              Olivier TAYEG
'* Date:                July '11
'* Change:              Adjust trace levels

'* Author:              Olivier TAYEG
'* Date:                July '11
'* Change:              CR ALPHA 241634
'*                      The status NotConnected might indicate a bad quality

'* Author:              Nicole FLORIAN
'* Date:                September '12
'* Change:              CRs ALPHA 286429 and 286430

'* Author:              Nicole FLORIAN
'* Date:                October '12
'* Change:              CR ALPHA 314420
'*                      Add trace in the Property Let Value

'* Author:              Eric FOISSEY
'* Date:                July '13
'* Change:              CR ALPHA 338046 : GAMA ESA Zone animation
'*                      Add Connexion type Read All, to prevent connection problems on long list
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

'* Declarations
'* ------------------------------------------------------
Option Explicit

Public Enum enumOPCAccessMode
    c_OPCReadOnly           ' OPC item can be only Read when the quality is Good
    c_OPCReadQuality        ' OPC item can be only Read when the quality is Good or Bad
    c_OPCWriteOnly          ' OPC item can be only Written
    c_OPCReadWrite          ' OPC item can be Read when the quality is Good, and Written
    c_OPCReadWriteQuality   ' OPC item can be Read when the quality Good or Bad, and Written
    c_OPCReadAll   ' OPC item can be Read even when error
End Enum

'----------------------------------------------------------------
'Private data declarations
'----------------------------------------------------------------

' Name of the variable
Private m_strOPCPath As String

Private m_VarType As fvVariableType
Private m_AccessMode As enumOPCAccessMode
Private m_strAccessMode As String

' Embedded OPC variable object
Private WithEvents m_OPC_Variable As Variable
Attribute m_OPC_Variable.VB_VarHelpID = -1

' Reference to the Iconis_CLS_OPCSet object to which the variable belongs.
' This is used to callback the Iconis_CLS_OPCSet object
Private m_ParentOPCSetObject As Iconis_CLS_OPCSet
' Index in the OPCSet (used in the callback)
Private m_lIndex As Long

' Flag to indicate if the variable has been connected
Private m_bConnected As Boolean


'================================================================
'           Events definitions for the user object
'================================================================

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::OnRefresh
' Input:        @param Value [Variant]             value
'               @param Quality [Integer]           quality
' Output:       none
' Description:  Raised when the value is ready to use
'-------------------------------------------------------------------------------
Public Event OnRefresh(Value As Variant, Quality As Integer)


'----------------------------------------------------------------
'Public function and method declarations
'----------------------------------------------------------------


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::Init
' Input:        @param strVarName [String]                                  Variable path
'               @param varType [fvVariableType]                             ClientBuilder variable type
'               @param ParentOPCSetObject [Iconis_CLS_OPCSet]               OPCSet object to which the variable belong
' Output:       @return True        Variable connection success
'               @return False       Failure
' Description:  Connect a variable and associate it
'-------------------------------------------------------------------------------
Public Function Init(strOPCPath As String, VarType As fvVariableType, AccessMode As enumOPCAccessMode, ParentOPCSetObject As Iconis_CLS_OPCSet, lIndex As Long) As Boolean
On Error GoTo ErrorHandler
    
    ' Store the data
    m_strOPCPath = strOPCPath
    m_VarType = VarType
    m_AccessMode = AccessMode
    Select Case AccessMode
        Case c_OPCReadOnly
            m_strAccessMode = "RO"
        Case c_OPCWriteOnly
            m_strAccessMode = "WO"
        Case c_OPCReadWrite
            m_strAccessMode = "RW"
        Case c_OPCReadWriteQuality
            m_strAccessMode = "RW/Q"
        Case c_OPCReadQuality
            m_strAccessMode = "R/Q"
        Case c_OPCReadAll
            m_strAccessMode = "RA"
    End Select

    ' Memorize the parent object
    Set m_ParentOPCSetObject = ParentOPCSetObject
    m_lIndex = lIndex

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Init", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::DoConnect
' Input:        @param strVarName [String]                                  Variable path
'               @param varType [fvVariableType]                             ClientBuilder variable type
'               @param ParentOPCSetObject [Iconis_CLS_OPCSet]               OPCSet object to which the variable belong
' Output:       @return True        Variable connection success
'               @return False       Failure
' Description:  Connect a variable and associate it
'-------------------------------------------------------------------------------
Public Function DoConnect() As Boolean
On Error GoTo ErrorHandler
    
    ' Reset the object's status
    m_bConnected = False
    If Not m_OPC_Variable Is Nothing Then
        Variables.Remove (m_OPC_Variable.Name)
        Set m_OPC_Variable = Nothing
    End If
    
    ' Try to connect by adding to the Variables collection
    Set m_OPC_Variable = Variables.Add(m_strOPCPath, m_VarType)

    ' Enable the refreshments
    If m_OPC_Variable.EnableEvents Then
        ' Force a call to the ValueChange if the events are already enabled
        Call m_OPC_Variable_ValueChange
    Else
        m_OPC_Variable.EnableEvents = True
    End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "DoConnect", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::Connect
' Input:        @param strVarName [String]                                  Variable path
'               @param varType [fvVariableType]                             ClientBuilder variable type
'               @param ParentOPCSetObject [Iconis_CLS_OPCSet]               OPCSet object to which the variable belong
' Output:       @return True        Always return true
' Description:  Connect a variable and associate it
'-------------------------------------------------------------------------------
Public Function Connect(strOPCPath As String, VarType As fvVariableType, AccessMode As enumOPCAccessMode, ParentOPCSetObject As Iconis_CLS_OPCSet, lIndex As Long) As Boolean
On Error GoTo ErrorHandler
    
    m_strOPCPath = strOPCPath
    m_AccessMode = AccessMode
    m_bConnected = False

    ' Memorize the parent object
    Set m_ParentOPCSetObject = ParentOPCSetObject
    m_lIndex = lIndex
    
    ' Try to connect the variable by adding to the Variables collection
    If Not m_OPC_Variable Is Nothing Then
        Set m_OPC_Variable = Nothing
    End If
    Set m_OPC_Variable = Variables.Add(strOPCPath, VarType)
    CBTrace CBTRACE_VAR, "Iconis_CLS_OPCSet_Item", "Connect", "Connecting to """ & strOPCPath & """ - initial status=" & m_OPC_Variable.Status & "; initial quality=" & m_OPC_Variable.Quality

    ' Enable the refreshments
    If m_OPC_Variable.EnableEvents Then
        ' Force a call to the ValueChange if the events are already enabled
        Call m_OPC_Variable_ValueChange
    Else
        m_OPC_Variable.EnableEvents = True
    End If

    ' Everything is fine, return "True"
    Connect = True

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Connect", "Variable " & strOPCPath & " error:" & Err.Description)
    ' Execution error, make sure we return "False"
    Connect = False
End Function


'----------------------------------------------------------------
' Public Properties declarations
'----------------------------------------------------------------

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::get_bIsReadable
' Input:        none
' Output:       [Boolean]           result
' Description:  Is it correct to read the value from this OPC item?
'-------------------------------------------------------------------------------
Public Property Get bIsReadable() As Boolean
On Error GoTo ErrorHandler

    If m_AccessMode <> c_OPCWriteOnly Then
        bIsReadable = m_bConnected
    Else
        bIsReadable = False
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Property Get bIsReadable", Err.Description)
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::get_bIsWritable
' Input:        none
' Output:       [Boolean]           result
' Description:  Is it correct to write a new value to this OPC item?
'-------------------------------------------------------------------------------
Public Property Get bIsWritable() As Boolean
On Error GoTo ErrorHandler

    If Not m_OPC_Variable Is Nothing And m_AccessMode <> c_OPCReadOnly Then
        bIsWritable = (m_OPC_Variable.Status = fvVariableStatusGood) Or (m_OPC_Variable.Status = fvVariableStatusBad)
    Else
        bIsWritable = False
    End If
    
Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Property Get bIsWritable", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::get_strPath
' Input:        none
' Output:       @return [String]     Path
' Description:  Get the path to the item
'-------------------------------------------------------------------------------
Public Property Get strPath() As String
    strPath = m_strOPCPath
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::get_Value
' Input:        none
' Output:       [Variant]           value
' Description:  Obtain the value
'-------------------------------------------------------------------------------
Public Property Get Value() As Variant
On Error GoTo ErrorHandler

    ' Read the value only if it is allowed
    If bIsReadable() Then
        Value = m_OPC_Variable.Value
    Else
        CBTrace CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "get_Value", "Error: Incorrect access. Tried to read the Item """ & m_strOPCPath & """ (" & m_strAccessMode & ") - " & " [status=" & m_OPC_Variable.Status & "]"
        Set Value = Nothing
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Property Get Value", Err.Description)
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::set_Value
' Input:        newvalue [Variant]      value to set
' Output:       none
' Description:  Write the value
'-------------------------------------------------------------------------------
Public Property Let Value(newvalue As Variant)
On Error GoTo ErrorHandler
    
    ' Write the value only if it is allowed
    If bIsWritable() Then
        m_OPC_Variable.Value = newvalue
        CBTrace CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Write value", "OPC variable=" & m_OPC_Variable.Name & " - Value=" & newvalue
    Else
        CBTrace CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Write value", "Error: Incorrect access. Tried to write to the Item """ & m_strOPCPath & """ (" & m_strAccessMode & ") - " & " [status=" & m_OPC_Variable.Status & "]"
    End If

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Property Let Value", Err.Description)
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::get_Status
' Input:        none
' Output:       [FrontVue.fvVariableStatus]           status
' Description:  Obtain the ClientBuilder status
'-------------------------------------------------------------------------------
Public Property Get Status() As fvVariableStatus
On Error GoTo ErrorHandler

    ' Read the status only if the variable connection succeeded
    If Not m_OPC_Variable Is Nothing Then
        Status = m_OPC_Variable.Status
    ' Return the "Config Error" status if the variable connection failed
    Else
        Status = fvVariableStatusConfigError
    End If
    
Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Property Get status", Err.Description)
End Property


'---------------------------------------------------------------------------------------
' Name:         ForceRefresh
' Input:        none
' Output:       none
' Description:  Method ("callback") called from the "owner" Iconis_CLS_OPCSet objects
'               to ask the object to notify its value to its clients.
'---------------------------------------------------------------------------------------
Public Sub ForceRefresh()
On Error GoTo ErrorHandler

    RaiseEvent OnRefresh(m_OPC_Variable.Value, m_OPC_Variable.Quality)

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "ForceRefresh", Err.Description)
End Sub


'----------------------------------------------------------------
' Private function and method declarations
'----------------------------------------------------------------

'-----------------------------------------------
'Function:   Iconis_CLS_OPCSet_Item::Class_Initialize
'Scope:      Contructor
'Caller :    Built-in event
'-----------------------------------------------
Private Sub Class_Initialize()

   On Error GoTo ErrorHandler
    
    ' Ensure all object data are clean
    Set m_OPC_Variable = Nothing
    Set m_ParentOPCSetObject = Nothing
    
    m_bConnected = False
    
    Exit Sub
    
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Class_Initialize", Err.Description)
End Sub


'-----------------------------------------------
'Function:   Iconis_CLS_OPCSet_Item::Class_Terminate
'Scope:      Destructor
'Caller :    Built-in event
'-----------------------------------------------
Public Sub Class_Terminate()
On Error GoTo ErrorHandler
    
    CBTrace CBTRACE_VBA, "Iconis_CLS_OPCSet_Item", "Terminate", "Removing OPCSet item """ & m_strOPCPath & """"

    ' Disconnect from the OPC variable
    If Not m_OPC_Variable Is Nothing Then
        Variables.Remove m_OPC_Variable.Name
        Set m_OPC_Variable = Nothing
    End If

    ' Delete the local OPCSet object
    Set m_ParentOPCSetObject = Nothing
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_OPCSet_Item::m_OPC_Variable_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC Variable events from ClientBuilder
'               (change in value or quality)
'-------------------------------------------------------------------------------
Private Sub m_OPC_Variable_ValueChange()
    
    On Error GoTo ErrorHandler
    Dim bNewConnectedStatus As Boolean
    
    Select Case m_AccessMode
        Case c_OPCReadOnly, c_OPCReadWrite
            bNewConnectedStatus = (m_OPC_Variable.Status = fvVariableStatusGood)
        ' Restriction caused by ClientBuilder: sometimes the status "Not connected" is obtained when the quality is actually Bad/NotConnected.
        ' As a result, for the OPC Items of type WO, R/Q or RW/Q, the disconnection event never occurs
        Case c_OPCWriteOnly, c_OPCReadQuality, c_OPCReadWriteQuality
            bNewConnectedStatus = (m_OPC_Variable.Status = fvVariableStatusGood) Or (m_OPC_Variable.Status = fvVariableStatusBad) _
                                    Or (m_OPC_Variable.Status = fvVariableStatusNotConnected)
        Case c_OPCReadAll
            bNewConnectedStatus = True
    End Select

    If bNewConnectedStatus Then
        If m_bConnected Then
            ' Refresh event for a Readable plug
            If Not m_AccessMode = c_OPCWriteOnly Then
                CBTrace CBTRACE_VAR, "Iconis_CLS_OPCSet_Item", "m_OPC_Variable_ValueChange", "Item """ & m_strOPCPath & """ (" & m_strAccessMode & ") [status=" & m_OPC_Variable.Status & "] was refreshed with " & " value=" & CStr(m_OPC_Variable.Value)
                Call m_ParentOPCSetObject.ItemRefreshed(m_lIndex)
            End If
        Else
            ' Connection event
            m_bConnected = True
            CBTrace CBTRACE_VBA, "Iconis_CLS_OPCSet_Item", "m_OPC_Variable_ValueChange", "Item """ & m_strOPCPath & """ (" & m_strAccessMode & ") [status=" & m_OPC_Variable.Status & "] has been connected with " & "" & " value=" & CStr(m_OPC_Variable.Value)
            Call m_ParentOPCSetObject.ItemConnected(m_lIndex)
        End If
    Else
        If m_bConnected Then
            ' Disconnection event
            m_bConnected = False
            CBTrace CBTRACE_VAR, "Iconis_CLS_OPCSet_Item", "m_OPC_Variable_ValueChange", "Disconnection for item """ & m_strOPCPath & """ (" & m_strAccessMode & ") [status=" & m_OPC_Variable.Status & "]" & " value=" & CStr(m_OPC_Variable.Value)
            Call m_ParentOPCSetObject.ItemDisconnected(m_lIndex)
        Else
            ' We are disconnected
            ' Either we are waiting for the connection to establish (m_OPC_Variable.Status = fvVariableStatusWaiting)
            ' or there is a configuration error, which is traced in the log:
            If m_OPC_Variable.Status = fvVariableStatusConfigError Then
                CBTrace CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "m_OPC_Variable_ValueChange", "Error (configuration): Item """ & m_strOPCPath & """ (" & m_strAccessMode & ") " & " [status=" & m_OPC_Variable.Status & "] was not found"
            End If
        End If
    End If

    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet_Item", "m_OPC_Variable_ValueChange", "(" & m_OPC_Variable.Name & "):" & Err.Description)
    'Ignacio Hernandez (Jul 2011): If the string to use with the CBTRace function is too long, it fails...
    Resume Next
End Sub



