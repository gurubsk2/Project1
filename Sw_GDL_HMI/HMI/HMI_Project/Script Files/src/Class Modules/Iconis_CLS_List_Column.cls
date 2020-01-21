VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_List_Column"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2009. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_List_Column
'* *******************************************************************************************
'* Purpose:     Part of Iconis_CLS_List which manages a generic list.
'               It manages one column of data.
'* *******************************************************************************************
'* Modification History:

'* Author:              Olivier TAYEG
'* Date:                November '09
'* Change:              All

'* Author:              Nicole FLORIAN
'* Date:                September '12
'* Change:              CRs ALPHA 286429 and 286430

'* Author:              Nicole FLORIAN
'* Date:                October '12
'* Change:              CRs ALPHA 279744 and 315016
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

'* Declarations
'* ------------------------------------------------------
Option Explicit


'* Constants
'* ------------------------------------------------------
Public Enum enumSortOrder
    c_lSortOrderUnknown
    c_lSortOrderAscending
    c_lSortOrderDescending
End Enum


'* Variables
'* ------------------------------------------------------

' Name of the column
Private m_strName As String
 ' Suffix to complete the variable name
Private m_strSuffix As String
' ID of the column in the list
Private m_strColID As String
' Type of the OPC variables
Private m_type As fvVariableType

Private m_lListCount As Long
' Array of the hide property
Private m_bHidden() As Boolean
' Order of sort
Private m_order As enumSortOrder

' OPCSet for the variables used to display the column
Private WithEvents m_OPCSetlocal_Display As Iconis_CLS_OPCSet
Attribute m_OPCSetlocal_Display.VB_VarHelpID = -1
' Current values stored in the column
Private m_Values() As Variant
' Default value for the column
Private m_DefaultValue As Variant
' (Optional) source of data for the column. When a data source exists, m_Values reflects their values.
Private WithEvents m_OPCSet_DataSource As Iconis_CLS_OPCSet
Attribute m_OPCSet_DataSource.VB_VarHelpID = -1

' Normal position of the controls
Private m_lControlLeftCoordinate As Long


Private m_arrStrDisplayVariablePath() As String

' The parent list that owns the column
Private m_parentList As Iconis_CLS_List

' Length
Private m_lPhysicalLineCount As Long

' Semaphor to prevent the refresh events when the user object is updating a value
Private m_bLockRefresh As Boolean

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::strName
' Input:        none
' Output:       none
' Description:  Retrieve the name of the columns
'-------------------------------------------------------------------------------
Public Property Get strName() As String
    strName = m_strName
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::lCount
' Input:        none
' Output:       none
' Description:  Retrieve the size of the columns
'-------------------------------------------------------------------------------
Public Property Get lCount() As String
    lCount = m_lListCount
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::lControlLeftCoordinate
' Input:        none
' Output:       none
' Description:  Retrieve the left co-ordinate of the column
'-------------------------------------------------------------------------------
Public Property Get lControlLeftCoordinate() As Long
    lControlLeftCoordinate = m_lControlLeftCoordinate
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::DisplayVariable
' Input:        none
' Output:       none
' Description:  Retrieve the variable for each line of the column
'-------------------------------------------------------------------------------
Public Property Get DisplayVariable(line As Long) As Variant
    DisplayVariable = Variables(m_arrStrDisplayVariablePath(line)).Value
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::DisplayVariable
' Input:        none
' Output:       none
' Description:  Retrieve the variable for each line of the column
'-------------------------------------------------------------------------------
Public Property Let DisplayVariable(line As Long, Value As Variant)
    m_bLockRefresh = True
    Variables(m_arrStrDisplayVariablePath(line)).Value = Value
    m_bLockRefresh = False
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::Value
' Input:        none
' Output:       none
' Description:  Retrieve the value of the item in the column
'-------------------------------------------------------------------------------
Public Property Get Value(line As Long) As Variant
    Value = m_Values(line)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::Value
' Input:        none
' Output:       none
' Description:  Retrieve the value of the item in the column
'-------------------------------------------------------------------------------
Public Property Let Value(line As Long, newvalue As Variant)
    m_Values(line) = newvalue
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::bHidden
' Input:        none
' Output:       none
' Description:  Retrieve the hidden property
'-------------------------------------------------------------------------------
Public Property Get bHidden(line As Long) As Boolean
    bHidden = m_bHidden(line)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::Order
' Input:        none
' Output:       none
' Description:  Retrieve the order of the column
'-------------------------------------------------------------------------------
Public Property Get Order() As enumSortOrder
    Order = m_order
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::Order
' Input:        none
' Output:       none
' Description:  Retrieve the order of the column
'-------------------------------------------------------------------------------
Public Property Let Order(Value As enumSortOrder)
    m_order = Value
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::Init
' Input:        parentList [Iconis_CLS_List]        parent list
'               strName [String]                    name of the column
'               columnType [fvVariableType]         type of variables to update the column
'               lLineCount [Long]                   number of variables in the column
'               lControlLeftCoordinate [Long]       coordinate of the control
'               strBranch[String]                   branch for the data source paths
'               strNameSuffix [String]              suffix for the data source paths
' Output:       none
' Description:  Initialize a column.
'               The path uses the following schema:
'                   for i in [0..lLineCount-1]: <strBranch>.<strName><i>.<strNameSuffix>%
'-------------------------------------------------------------------------------
Public Function Init(parentList As Iconis_CLS_List, strName As String, columnType As fvVariableType, _
                     lLineCount As Long, lControlLeftCoordinate As Long, _
                     StrBranch As String, Optional strNameSuffix As String = "", _
                     Optional defaultValue As Variant) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "NewColumn", "Begin Function")

    Dim I As Long
    Dim strVarnames() As String
   
    Set m_parentList = parentList

    ' Store the initialization data
    m_strName = strName
    m_strSuffix = strNameSuffix
    m_lPhysicalLineCount = lLineCount
    m_type = columnType
    m_order = c_lSortOrderUnknown
    m_lControlLeftCoordinate = lControlLeftCoordinate
    If (IsMissing(defaultValue)) Then
        Select Case columnType
            Case fvVariableTypeText, fvVariableTypeAny
                m_DefaultValue = ""
            Case fvVariableTypeBit
                m_DefaultValue = False
            Case fvVariableTypeRegister
                m_DefaultValue = -1
            Case Else
        End Select
    Else
        m_DefaultValue = defaultValue
    End If
    
    ' Compute the column ID
    m_strColID = m_parentList.FormColumnID(m_strName, m_strSuffix)

    ' No data has been received yet: the column is empty
    m_lListCount = 0

    ' Manage a OPCSet to connect all the OPC variables used to display the column
    ReDim m_arrStrDisplayVariablePath(0 To lLineCount - 1)
    If Not m_OPCSetlocal_Display Is Nothing Then
        m_OPCSetlocal_Display.Destroy
        Set m_OPCSetlocal_Display = Nothing
    End If
    Set m_OPCSetlocal_Display = New Iconis_CLS_OPCSet
    
    For I = 0 To lLineCount - 1
        m_arrStrDisplayVariablePath(I) = StrBranch & m_strName & I & m_strSuffix & "%"
    Next I
    m_OPCSetlocal_Display.Connect m_arrStrDisplayVariablePath, columnType, c_OPCSetTypeRead, "Iconis_CLS_List_Column::" & strName
    For I = 0 To lLineCount - 1
        DisplayVariable(I) = m_DefaultValue
    Next I

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "Init", Err.Description)
End Function



'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::ResetData
' Input:        none
' Output:       none
' Description:  Fill the column with its default value
'-------------------------------------------------------------------------------
Public Function ResetData()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List_Column", "ResetData", "Begin Function")

    Dim I As Long
    
    ' Reset the data
    For I = 0 To UBound(m_Values)
        m_Values(I) = m_DefaultValue
        m_parentList.Value(m_strColID, I) = m_DefaultValue
        m_bHidden(I) = False
    Next I

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "ResetData", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::UseDataSource
' Input:        arrStrPath [String()]        Path to OPC item to use, for each line
' Output:       none
' Description:  Provide a data source for a column. The caller gives all the OPC paths.
'-------------------------------------------------------------------------------
Public Function UseDataSource(arrStrPath() As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "UseDataSource", "Begin Function")

    Dim I As Long
    
    ' The array gives the length of the column
    m_lListCount = UBound(arrStrPath) + 1
    
    ' No data has been received yet: the column is empty
    ReDim m_Values(0 To m_lListCount - 1)
    ReDim m_bHidden(0 To m_lListCount - 1)
    
    ResetData
    
    ' Remove any existing binding
    If Not m_OPCSet_DataSource Is Nothing Then
        m_OPCSet_DataSource.Destroy
        Set m_OPCSet_DataSource = Nothing
    End If
    ' Perform the binding
    Set m_OPCSet_DataSource = New Iconis_CLS_OPCSet
    m_OPCSet_DataSource.Connect arrStrPath, m_type, c_OPCSetTypeConnection, "Iconis_CLS_List_Column::DataSource(" & strName & ")"

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "UseDataSource", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::FillColumn
' Input:        Values [Variant()]              values to write
' Output:       @return True if successful
'                       False in case of a failure
' Description:  Write a set of data to the column. Updating a data source is not yet managed.
'-------------------------------------------------------------------------------
Public Function FillColumn(Values() As Variant) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List_Column", "FillColumn", "Begin Function")

    ' The array gives the length of the column
    m_lListCount = UBound(Values) + 1

    ' Store the data
    m_Values = Values

    ReDim m_bHidden(0 To m_lListCount - 1)
    
    FillColumn = True

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "ReadPlatformXMLDescription", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::FillHiddenProperty
' Input:        Values [Boolean()]              value of the hidden property for each line
' Output:       @return True if successful
'                       False in case of a failure
' Description:  Write the hidden property for each line in the column
'-------------------------------------------------------------------------------
Public Function FillHiddenProperty(arHidden() As Boolean) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List_Column", "FillHiddenProperty", "Begin Function")

    ' The array gives the length column
    If m_lListCount <> UBound(arHidden) + 1 Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "FillHiddenProperty", _
                     "Error: Inconsistent array size: " & UBound(arHidden) + 1 & " hidden properties were provided, while " & m_lListCount & " were expected.")
    Else
        ' Store the data
        m_bHidden = arHidden
    
        FillHiddenProperty = True
    End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "FillHiddenProperty", Err.Description)
End Function


'---------------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::Class_Terminate
' Input:        none
' Output:       none
' Description:  Destructor
'---------------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List_Column", "Class_Terminate", "Begin Function")
    
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "Class_Terminate", "Terminating instance """ & m_strName & """")
    ' Destroy the OPCSet objects
    If Not m_OPCSetlocal_Display Is Nothing Then
        m_OPCSetlocal_Display.Destroy
        Set m_OPCSetlocal_Display = Nothing
    End If
    If Not m_OPCSet_DataSource Is Nothing Then
        m_OPCSet_DataSource.Destroy
        Set m_OPCSet_DataSource = Nothing
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "Class_Terminate", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::m_OPCSet_DataSource_OnConnection
' Input:        arrValue [Variant()]                the value
'               arrStatus [fvVariableStatus()]      the corresponding statuses
' Output:       none
' Description:  When the data source is ready, store the data.
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_DataSource_OnConnection(arrValue() As Variant, arrStatus() As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List_Column", "m_OPCSet_DataSource_OnConnection", "Begin Function")
    
    ' Store the data
    Dim I As Long
    For I = 0 To UBound(arrValue)
        If arrStatus(I) = fvVariableStatusGood Then
            m_Values(I) = arrValue(I)
        Else
            m_Values(I) = m_DefaultValue
        End If
    Next I
    If UBound(arrValue) > 0 Then
        m_lListCount = UBound(arrValue) + 1
    End If

    ReDim m_bHidden(0 To m_lListCount - 1)
    
    ' Provoke a refresh on the parent
    m_parentList.Display

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "m_OPCSet_DataSource_OnRead", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::m_OPCSet_DataSource_OnDisconnection
' Input:        arrValue [Variant()]                the value
'               arrStatus [fvVariableStatus()]      the corresponding statuses
' Output:       none
' Description:  When the data source is disconnected, switch back to default values
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_DataSource_OnDisconnection()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List_Column", "m_OPCSet_DataSource_OnDisconnection", "Begin Function")
    
    ' Reset the data
    ResetData
    
    ' Provoke a new refresh on the parent
    m_parentList.Display

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List_Column", "m_OPCSet_DataSource_OnDisconnection", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::m_OPCSetlocal_Display_OnRefresh
' Input:        lIndex [Long]                   index of the value refreshed
'               Value [Variant()]               value
'               status [fvVariableStatus()]     status
' Output:       none
' Description:  Raised for a databound column when a data source value changes:
'               Store the value in the list
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_DataSource_OnRefresh(lIndex As Long, Value As Variant, Status As fvVariableStatus)
    If Status = fvVariableStatusGood Then
        m_parentList.Value(m_strColID, lIndex) = Value
    Else
        If (IsNull(m_DefaultValue) = False) Then
            m_parentList.Value(m_strColID, lIndex) = m_DefaultValue
        End If
    End If
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List_Column::m_OPCSetlocal_Display_OnRefresh
' Input:        lIndex [Long]                   index of the value refreshed
'               Value [Variant()]               value
'               status [fvVariableStatus()]     status
' Output:       none
' Description:  Notify the parent that a display variable has been changed,
'               usually meaning a user entry
'-------------------------------------------------------------------------------
Private Sub m_OPCSetlocal_Display_OnRefresh(lIndex As Long, Value As Variant, Status As fvVariableStatus)
    If m_lListCount > 0 And Not m_bLockRefresh Then
        m_parentList.ItemChanged m_strName, m_strSuffix, lIndex, Value
    End If
End Sub


