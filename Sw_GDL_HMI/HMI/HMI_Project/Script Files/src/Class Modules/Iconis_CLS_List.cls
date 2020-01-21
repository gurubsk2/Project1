VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_List"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2009. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_List
'* *******************************************************************************************
'* Purpose:     It manages a generic list.
'               The list is made of columns of objects.
'               One column - variables.
'* *******************************************************************************************
'* Modification History:

'* Author:              Olivier TAYEG
'* Date:                November '09
'* Change:              All

'* Author:              Nicole FLORIAN
'* Date:                June '10
'* Change:              CR ALPHA 187315
'*                      Possibility to use a horizontal list

'* Author:              Olivier TAYEG
'* Date:                July '10
'* Change:              CR ALPHA 187908
'*                      Control of the hidden property

'* Author:              Olivier TAYEG
'* Date:                July '11
'* Change:              CR ALPHA 231955
'*                      Incorrect display when the list was scrolled and it is rebuilt.
'*                      Add a semaphor on the scrollbar.

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

' Coordinates used to hide the controls
' Let's hope no mimic will ever be larger than this...
Const c_lHiddenControlAbscissa As Long = 20000
Const c_lHiddenControlOrdinate As Long = 20000


'* Variables
'* ------------------------------------------------------

' Description of the columns
Dim m_collColumns As Collection

' Number of physical lines in the list
Dim m_lLineCount As Long
' Actual size of the list
Dim m_lActualLineCount As Long

' Size of the list
Dim m_lItemsCount As Long

' Boolean indicating if the list is displayed horizontally or not
Dim m_bHorizontalList As Boolean

' Mimic containing the controls
Private m_MimicContainer As Mimic
' Branch used
Private m_strMimicBranch As String
' Scrollbar used to navigate in the list
Private WithEvents m_ScrollBar As MSForms.ScrollBar
Attribute m_ScrollBar.VB_VarHelpID = -1

' State of the list
Private m_bInitialized As Boolean

' Display position in the list
Private m_lCurrentPosition As Long


'=======================================================================================================================================
'                                                   User events
'=======================================================================================================================================


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::ItemChanged
' Input:        @param strColumnID [String] ID of the column
'               @param line [Long]          Row number
'               @param Value [Variant]      New value
' Output:       none
' Description:  Raised when an item has been updated in the list.
'-------------------------------------------------------------------------------
Public Event ItemChanged(strColumnID As String, line As Long, Value As Variant)



'=======================================================================================================================================
'                                                  Public functions
'=======================================================================================================================================

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::Init
' Input:        @param container    parent mimic
'               @param strBranch    parent branch
'               @param lLineCount   size of the list
'               @param ScrollBar    scrollbar used by the list
' Output:       none
' Description:  Initialize the list.
'-------------------------------------------------------------------------------
Public Sub Init(container As Mimic, StrBranch As String, lLineCount As Long, ScrollBar As MSForms.ScrollBar, Optional bHorizontalList As Boolean = False)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "Init", "Begin Function")

    Set m_MimicContainer = container
    If StrBranch <> "" Then
        m_strMimicBranch = StrBranch & "."
    Else
        m_strMimicBranch = ""
    End If
    m_lLineCount = lLineCount
    m_bHorizontalList = bHorizontalList
    
    Set m_ScrollBar = ScrollBar
    
    Set m_collColumns = New Collection

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "Init", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::Destroy
' Input:        none
' Output:       none
' Description:  Destroy the object. To be called by user object.
'-------------------------------------------------------------------------------
Public Function Destroy()
On Error GoTo ErrorHandler
    
    Dim I As Long
    
    If Not m_collColumns Is Nothing Then
        For I = 1 To m_collColumns.Count
            ' Since collections are reindexed automatically, delete and remove the first member on each iteration
            m_collColumns.Remove 1
        Next I
        Set m_collColumns = Nothing
    End If
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet", "Destroy", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::NewColumn
' Input:        @param strName [String]                 name of the column, prefix of the local variable
'               @param columnType [fvVariableType]      type of the local variable
'               @param lControlLeftCoordinate [Long]    original abcissa of the control
'               @param strNameSuffix [String]           suffix of the local variable
'               @param columnType [String]              type of the local variable
' Output:       @return True if successful
'                       False in case of a failure
' Description:  Declare a new column in the list, animated through a set of local variables
'               (whose path is given by prefix+suffix) and a set of controls (whose
'               initial location may be given before hiding)
'-------------------------------------------------------------------------------
Public Function NewColumn(strName As String, columnType As fvVariableType, _
                          Optional lControlLeftCoordinate As Long = -1, _
                          Optional strNameSuffix As String = "", _
                          Optional defaultValue As Variant) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "NewColumn", "Begin Function")

    Dim I As Long
    Dim column As New Iconis_CLS_List_Column
    Dim strVarnames() As String

    ' Manage the controls
    If lControlLeftCoordinate = -1 Then
        ' No left coordinate given, we'll take the first control's coordinate
        If (m_bHorizontalList = False) Then
            lControlLeftCoordinate = m_MimicContainer.Graphics.Item(strName & I).Left
        Else
            lControlLeftCoordinate = m_MimicContainer.Graphics.Item(strName & I).Top
        End If
    End If

    ' Create the column
    column.Init Me, strName, columnType, m_lLineCount, _
                lControlLeftCoordinate, m_strMimicBranch, strNameSuffix, defaultValue

    ' Add this new column
    m_collColumns.Add column, FormColumnID(strName, strNameSuffix)

    NewColumn = True

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "NewColumn", Err.Description)
End Function



'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::ResetData
' Input:        none
' Output:       none
' Description:  Empty the data
'-------------------------------------------------------------------------------
Public Function ResetData()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "ResetData", "Begin Function")

    Dim column As Iconis_CLS_List_Column
    
    m_lItemsCount = 0
    
    For Each column In m_collColumns
        column.ResetData
    Next column

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "ResetData", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::BindColumnToSource
' Input:        @param strName [String]                 name of the column, prefix
'               @param Values [Variant()]               initial values
'               @param strNameSuffix [String]           suffix of the local variable
' Output:       @return True if successful
'                       False in case of a failure
' Description:  Record the initial values of a column
'-------------------------------------------------------------------------------
Public Function BindColumnToSource(strName As String, arrPaths() As String, Optional strNameSuffix As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "BindColumnToSource", "Begin Function")

    Dim column As Iconis_CLS_List_Column

    m_lItemsCount = UBound(arrPaths) + 1

    Set column = m_collColumns.Item(FormColumnID(strName, strNameSuffix))
    column.UseDataSource arrPaths

On Error GoTo 0
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "BindColumnToSource", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::FillColumn
' Input:        @param strName [String]                 name of the column, prefix
'               @param Values [Variant()]               initial values
'               @param strNameSuffix [String]           suffix of the local variable
' Output:       @return True if successful
'                       False in case of a failure
' Description:  Record an array of initial values for a column
'-------------------------------------------------------------------------------
Public Function FillColumn(strName As String, Values() As Variant, Optional strNameSuffix As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "FillColumn", "Begin Function")

    Dim column As Iconis_CLS_List_Column

    m_lItemsCount = UBound(Values) + 1

    Set column = m_collColumns.Item(FormColumnID(strName, strNameSuffix))
    column.FillColumn Values

On Error GoTo 0
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "FillColumn", Err.Description)
End Function



'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::FillColumnHiddenProperty
' Input:        @param strName [String]                 name of the column, prefix
'               @param arHidden [Variant()]             whether each line is hidden
'               @param strNameSuffix [String]           suffix of the local variable
' Output:       @return True if successful
'                       False in case of a failure
' Description:  Record the initial hidden status for each line in a column
'-------------------------------------------------------------------------------
Public Function FillColumnHiddenProperty(strName As String, arHidden() As Boolean, Optional strNameSuffix As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "FillColumnHiddenProperty", "Begin Function")

    Dim column As Iconis_CLS_List_Column

    Set column = m_collColumns.Item(FormColumnID(strName, strNameSuffix))
    column.FillHiddenProperty arHidden

On Error GoTo 0
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "FillColumnHiddenProperty", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::Display
' Input:        none
' Output:       none
' Description:  Display the list
'-------------------------------------------------------------------------------
Public Sub Display()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "Display", "Begin Function")

    ' Check the validity of the data in entry
    Dim j As Long
    Dim bError As Boolean
    bError = False
    For j = 1 To m_collColumns.Count
        With m_collColumns(j)
            If .lCount <> m_lItemsCount Then
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "Display", _
                "The list defined in " & m_MimicContainer.Name & " [" & m_MimicContainer.Branch & "] has been wrongly defined. Column " & .strName & " has " & .lCount & " items instead of " & m_lItemsCount)
                bError = True
            End If
        End With
    Next j

    If Not bError Then
        ' Adapt the controls to the list of platforms
        If (m_lItemsCount > m_lLineCount) Then
            ' There are more item than the list enables to display
            ' All controls are used to display the list
            m_lActualLineCount = m_lLineCount
            ' The scrollbar is configured for the actual number of items
            m_ScrollBar.Min = 0
            m_ScrollBar.Max = m_lItemsCount - m_lLineCount
            m_ScrollBar.ProportionalThumb = True
            m_ScrollBar.SmallChange = 1
            m_ScrollBar.LargeChange = 1
            m_ScrollBar.Enabled = False
            m_ScrollBar.Value = 0
            m_ScrollBar.Enabled = True
        Else
            ' There are less items than the list enables to display
            ' The controls that are useless shall be hidden
            m_lActualLineCount = m_lItemsCount
            ' No scrolling
            m_ScrollBar.Enabled = False
        End If
    
        ' Initial display
        ShowListControls
        Scroll 0, True
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "Display", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::get_Count
' Input:        none
' Output:       @return The number of platforms managed in this list
' Description:  Get the number of platforms
'-------------------------------------------------------------------------------
Public Property Get Count() As Integer
    Count = m_lItemsCount
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::ShowAllControls
' Input:        none
' Output:       none
' Description:  All the controls are returned to their initial position.
'               Call from Mimic_Design to be able to edit the list controls in your mimic.
'-------------------------------------------------------------------------------
Public Sub ShowAllControls()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "ShowAllControls", "Begin Subroutine")

    Dim I As Long
    Dim j As Long

    If m_bHorizontalList = False Then
        ' For each control
        For I = 0 To m_lLineCount - 1
            For j = 1 To m_collColumns.Count
                ' Display the control
                m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Left = m_collColumns(j).lControlLeftCoordinate
            Next j
        Next I
    Else
        ' For each control
        For I = 0 To m_lLineCount - 1
            For j = 1 To m_collColumns.Count
                ' Display the control
                m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Top = m_collColumns(j).lControlLeftCoordinate
            Next j
        Next I
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "ShowAllControls", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::FormColumnID
' Input:        @param strName [String]         Name of the column, prefix of the local variable
'               @param strNameSuffix [String]   Suffix of the local variable
' Output:       @return [String]                ID of the column
' Description:  Computes the ID for a column
'-------------------------------------------------------------------------------
Public Function FormColumnID(strName As String, strNameSuffix As String) As String
    If strNameSuffix <> "" Then
        FormColumnID = strName & ":" & strNameSuffix
    Else
        FormColumnID = strName
    End If
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::get_Value
' Input:        @param strColumnID [String] ID of the column
'               @param index [Long]         Index in the list (row number)
' Output:       @return The value
' Description:  Get the value at the column, row given
'-------------------------------------------------------------------------------
Public Property Get Value(strColumnID As String, index As Long) As Variant
    If index >= m_lCurrentPosition And index <= m_lCurrentPosition + m_lActualLineCount - 1 Then
        Value = m_collColumns(strColumnID).DisplayVariable(index - m_lCurrentPosition)
    Else
        Value = m_collColumns(strColumnID).Value(index)
    End If
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::set_Value
' Input:        @param strColumnID [String] ID of the column
'               @param index [Long]         Index in the list (row number)
'               @param newvalue [Variant]   The value to store in that place
' Output:       none
' Description:  Enables to change the value of an item in the list
'-------------------------------------------------------------------------------
Public Property Let Value(strColumnID As String, index As Long, newvalue As Variant)
    If index >= m_lCurrentPosition And index <= m_lCurrentPosition + m_lActualLineCount - 1 Then
        m_collColumns(strColumnID).DisplayVariable(index - m_lCurrentPosition) = newvalue
    Else
        m_collColumns(strColumnID).Value(index) = newvalue
    End If
End Property


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::Sort
' Input:        @param trColumnID [String] ID of the column
' Output:       @return [enumSortOrder] Final sort order of the list
' Description:  Sort a column. Each time this is called, the order of sorting is reversed.
'       (The initial Sort is Ascending because of the initialization values.)
'-------------------------------------------------------------------------------
Public Function Sort(strColumnID As String) As enumSortOrder
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "Sort", "Begin Function")
    
    Dim I As Long
    Dim j As Long
    Dim lNewPosition As Long
    Dim sortColumn As Iconis_CLS_List_Column
    
    SaveCurrentControlValues
    
    Set sortColumn = m_collColumns(strColumnID)

    If sortColumn.Order = c_lSortOrderDescending Then
        sortColumn.Order = c_lSortOrderAscending
    Else
        sortColumn.Order = c_lSortOrderDescending
    End If
    
    ' The new position is where the first line has been going...
    lNewPosition = m_lCurrentPosition
    
    For I = 0 To m_lItemsCount - 1
        ' Find smallest or highest (according to sort order)
        Dim extremum As Variant
        Dim lIndexExtremum As Long
        
        lIndexExtremum = I
        extremum = sortColumn.Value(I)
        
        If sortColumn.Order = c_lSortOrderAscending Then
            For j = I + 1 To m_lItemsCount - 1
                If sortColumn.Value(j) < extremum Then
                    lIndexExtremum = j
                    extremum = sortColumn.Value(j)
                End If
            Next j
        Else
            For j = I + 1 To m_lItemsCount - 1
                If sortColumn.Value(j) > extremum Then
                    lIndexExtremum = j
                    extremum = sortColumn.Value(j)
                End If
            Next j
        End If
        
        If lNewPosition = I Then
            lNewPosition = lIndexExtremum
        ElseIf lNewPosition = lIndexExtremum Then
            lNewPosition = I
        End If
        
        ' For every column in a line, swap the value with the corresponding value in the line containing the extremum
        For j = 1 To m_collColumns.Count
            extremum = m_collColumns(j).Value(lIndexExtremum)
            m_collColumns(j).Value(lIndexExtremum) = m_collColumns(j).Value(I)
            m_collColumns(j).Value(I) = extremum
        Next j
    Next I
    
    Scroll lNewPosition, True

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "Sort", Err.Description)
End Function


'=======================================================================================================================================
'                                              Internal (private) functions
'=======================================================================================================================================

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::ShowListControls
' Input:        none
' Output:       none
' Description:  Show the controls needed for the list, and hide the others
'-------------------------------------------------------------------------------
Private Sub ShowListControls()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "ShowListControls", "Begin Subroutine")

    Dim I As Long
    Dim j As Long
    Dim column As Variant

    If m_lLineCount < m_lItemsCount Then
        m_lActualLineCount = m_lLineCount
    Else
        m_lActualLineCount = m_lItemsCount
    End If

    If m_bHorizontalList = False Then
        ' Show the visible elements
        For I = 0 To m_lActualLineCount - 1
            For j = 1 To m_collColumns.Count
                ' Display the control
                m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Left = m_collColumns(j).lControlLeftCoordinate
            Next j
        Next I
        ' Hide the other elements
        For I = m_lActualLineCount To m_lLineCount - 1
            For j = 1 To m_collColumns.Count
                ' Hide the control
                m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Left = c_lHiddenControlAbscissa
            Next j
        Next I
    Else
        ' Show the visible elements
        For I = 0 To m_lActualLineCount - 1
            For j = 1 To m_collColumns.Count
                ' Display the control
                m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Top = m_collColumns(j).lControlLeftCoordinate
            Next j
        Next I
        ' Hide the other elements
        For I = m_lActualLineCount To m_lLineCount - 1
            For j = 1 To m_collColumns.Count
                ' Hide the control
                m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Top = c_lHiddenControlOrdinate
            Next j
        Next I
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "ShowListControls", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::Scroll
' Input:        @param lNewPosition New position in the list
'               @param bInitialize  Indicates if this is the first display.
'                                   On a first display, the existing values are not stored.
' Output:       none
' Description:  Display the list at the given position
'-------------------------------------------------------------------------------
Private Sub Scroll(lNewPosition As Long, Optional bInitialize As Boolean = False)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "Scroll", "Begin Subroutine")

    Dim I As Long
    Dim j As Long
    
    ' Make sure the position of the first line stays within a range
    If lNewPosition < 0 Then
        lNewPosition = 0
    End If
    If lNewPosition > m_lItemsCount - m_lActualLineCount Then
        lNewPosition = m_lItemsCount - m_lActualLineCount
    End If

    If m_lCurrentPosition <> lNewPosition Or bInitialize Then
        If Not (bInitialize) Then
            ' After initialization, the values entered in the controls are valid and are saved
            SaveCurrentControlValues
        End If

        ' Go to the new position
        m_lCurrentPosition = lNewPosition
    End If

    If m_bHorizontalList = False Then
        ' Fill the controls with the appropriate values
        For I = 0 To m_lActualLineCount - 1
            For j = 1 To m_collColumns.Count
                ' Display value
                m_collColumns(j).DisplayVariable(I) = m_collColumns(j).Value(m_lCurrentPosition + I)
    
                ' Display status
                If m_collColumns(j).bHidden(lNewPosition + I) Then
                    m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Left = c_lHiddenControlAbscissa
                Else
                    m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Left = m_collColumns(j).lControlLeftCoordinate
                End If
            Next j
        Next I
    Else
        ' Fill the controls with the appropriate values
        For I = 0 To m_lActualLineCount - 1
            For j = 1 To m_collColumns.Count
                ' Display value
                m_collColumns(j).DisplayVariable(I) = m_collColumns(j).Value(m_lCurrentPosition + I)

                ' Display status
                If m_collColumns(j).bHidden(lNewPosition + I) Then
                    m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Top = c_lHiddenControlOrdinate
                Else
                    m_MimicContainer.Graphics.Item(m_collColumns(j).strName & I).Top = m_collColumns(j).lControlLeftCoordinate
                End If
            Next j
        Next I
    End If
    
    ' Store the value into the scrollbar
    m_ScrollBar.Value = m_lCurrentPosition
    ' Focus on the mimic to avoid a blinking scrollbar
    m_MimicContainer.Activate
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "ScrollBarPlatformsList_Change", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::SaveCurrentControlValues
' Input:        none
' Output:       none
' Description:  Save the user-entered values at the current position into the list
'-------------------------------------------------------------------------------
Private Sub SaveCurrentControlValues()

On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "SaveCurrentControlValues", "Begin Subroutine")

    Dim I As Long
    Dim j As Long

    For I = 0 To m_lActualLineCount - 1
        For j = 1 To m_collColumns.Count
            m_collColumns(j).Value(m_lCurrentPosition + I) = m_collColumns(j).DisplayVariable(I)
        Next j
    Next I

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "SaveCurrentControlValues", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::m_Scrollbar_Change
' Input:        none
' Output:       none
' Description:  Scroll the list to the new position of the scrollbar
'-------------------------------------------------------------------------------
Private Sub m_Scrollbar_Change()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_List", "m_Scrollbar_Change", "Begin Subroutine")

    ' Check semaphor
    If m_ScrollBar.Enabled Then
        Scroll m_ScrollBar.Value
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_List", "m_Scrollbar_Change", Err.Description)
End Sub


'=======================================================================================================================================
'                                           Callback functions (declared as Public)
'=======================================================================================================================================

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::ItemChanged
' Input:        @param strColumnName [String]       Name of the column
'               @param strColumnSuffix [String]     Suffix for the column name
'               @param i                            Row number
'               @param value [Variant]              New value
' Description:  Send a notification to the user object when the display
'               variable (managing the item) has changed.
'-------------------------------------------------------------------------------
Public Sub ItemChanged(strColumnName As String, strNameSuffix As String, I As Long, Value As Variant)
    ' NB: the user object may modify the same variable again; the reentrance is prevented by ClientBuilder itself
    ' (the ValueChange event of a Variable object is shielded for reentrance)
    RaiseEvent ItemChanged(FormColumnID(strColumnName, strNameSuffix), m_lCurrentPosition + I, Value)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::Class_Initialize
' Input:        none
' Output:       none
' Description:  Constructor
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
    m_lLineCount = 0
    m_lItemsCount = 0
    
    m_lCurrentPosition = 0
    m_lActualLineCount = 0
    
    m_bHorizontalList = False
    
    Set m_ScrollBar = Nothing
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_List::Class_Terminate
' Input:        none
' Output:       none
' Description:  Destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler

    CBTrace CBTRACEF_ALWAYS, "Iconis_CLS_List", "Class_Terminate", "Terminating instance """ & m_MimicContainer.Name & """"
    Call Destroy

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_OPCSet", "Class_Terminate", Err.Description)
End Sub



