VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_RollingStock"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_RollingStock
'* *******************************************************************************************
'* Purpose: Manages a rolling-stock (train)
'* *******************************************************************************************
'* Modification History:
'* Author:              Nicole FLORIAN
'* Date:                March '12
'* Change:              All - CR ALPHA 270259

'* Author:              Eric Foissey
'* Date:                March '13
'* Change:              CR ALPHA 318963 : connexion problem to data, set readQuality
'*                      instead of ReadOnly
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
' Used in the lists
Private Const c_strItemSeparator As String = ";"

' Used to build the string containing the composition of the train
' (Car ID are separated by this character)
Private Const c_strCarSeparator As String = "-"

' Used to build the modification notification
Private Const c_strRSIDParam As String = "id"
Private Const c_strTypeParam As String = "type"
Private Const c_strCompositionParam As String = "composition"

' Used to read the string (XML format) containing the list (composition) of cars of train
Private Const c_strCarNode As String = "Car"
Private Const c_strIDAttr As String = "ID"

' Path of OPC variables
Private Const c_strRSID As String = ".ATCTrainID.Value"
Private Const c_strType As String = ".TrainTypeEnum.Value"
Private Const c_strComposition As String = ".RSM.bstrTrainComposition"
' Path of the variable containing a notification of parameter modification or disconnection
Private Const c_strModifNotificationTag As String = "@RSMModificationNotification%"

' Class attributes
' ------------------------------------------------------
' Path of the OPC variable (HMITrain) associated the train
Private m_strPath As String
' Train RS ID
Private m_strRSID As String
' Train Type
Private m_strType As String
' Train Composition
Private m_strComposition As String
' Collection of counters of the train
Private m_Counters As New Collection

' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------
Dim WithEvents m_OPCSet_TrainVariables As Iconis_CLS_OPCSet
Attribute m_OPCSet_TrainVariables.VB_VarHelpID = -1
Private WithEvents m_OPCItem_txtRSID As Iconis_CLS_OPCSet_Item
Attribute m_OPCItem_txtRSID.VB_VarHelpID = -1
Private WithEvents m_OPCItem_txtType As Iconis_CLS_OPCSet_Item
Attribute m_OPCItem_txtType.VB_VarHelpID = -1
Private WithEvents m_OPCItem_txtComposition As Iconis_CLS_OPCSet_Item
Attribute m_OPCItem_txtComposition.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::Init
' Input:        [String]   ID of the train (name of the OPC variable)
'               [Integer]  Number of KM counters
''              [String]   List of "propertytrainbag" name of each counter
' Output:       none
' Description:  Init OPC and local variables
'-------------------------------------------------------------------------------
Public Sub Init(ByVal strTrainID As String, ByVal iNbCounter As Integer, _
                ByVal strCounterList As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "Init", "Begin Subroutine")
    Dim CounterArray() As String
    Dim I As Integer
    Dim DistanceCounterManager As Iconis_CLS_DistanceCounter
    

    ' Init class attribute
    m_strPath = Iconis_MOD_General.GetOPCCluster & strTrainID
   
    ' Connect to the server OPC variables
    Set m_OPCSet_TrainVariables = Iconis_MOD_General.CreateNew_Iconis_CLS_OPCSet
    ' CR-318963 : change connection option to ReadQuality instead of ReadOnly
    Set m_OPCItem_txtRSID = m_OPCSet_TrainVariables.AddItem(m_strPath & c_strRSID, fvVariableTypeText, c_OPCReadQuality)
    Set m_OPCItem_txtType = m_OPCSet_TrainVariables.AddItem(m_strPath & c_strType, fvVariableTypeText, c_OPCReadQuality)
    Set m_OPCItem_txtComposition = m_OPCSet_TrainVariables.AddItem(m_strPath & c_strComposition, fvVariableTypeText, c_OPCReadQuality)
    ' Connect the variables
    m_OPCSet_TrainVariables.DoConnect (m_strPath)
    
    ' Extract the list of of "HMIPropertyBagTrain" name of each counter into an array
    CounterArray = Split(strCounterList, c_strItemSeparator)
    For I = 0 To iNbCounter - 1
        ' Create an instance of Iconis_CLS_DistanceCounter class module
        Set DistanceCounterManager = New Iconis_CLS_DistanceCounter
        If Not (DistanceCounterManager Is Nothing) Then
            ' Init the instance
            DistanceCounterManager.Init m_strPath, I + 1, CounterArray(I)
            ' Memorize the instance in a collection of counters
            m_Counters.Add DistanceCounterManager, CounterArray(I)
        End If
    Next
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "Init", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "Class_Terminate", "Begin Subroutine")
    Dim I As Integer
    
    If Not (m_Counters Is Nothing) Then
        For I = 1 To m_Counters.Count
            m_Counters.Remove 1
        Next
        Set m_Counters = Nothing
    End If
    
    If Not (m_OPCSet_TrainVariables Is Nothing) Then
        m_OPCSet_TrainVariables.Destroy
        Set m_OPCSet_TrainVariables = Nothing
    End If
    Set m_OPCItem_txtRSID = Nothing
    Set m_OPCItem_txtType = Nothing
    Set m_OPCItem_txtComposition = Nothing
        
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::Get_TrainPath
' Input:        none
' Output:       [String] The path of the OPC variable
' Description:  Returns the path of the OPC variable (HMITrain) associated to
'               the train
'-------------------------------------------------------------------------------
Public Property Get TrainPath() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "Get_TrainPath", "Begin Property")

    TrainPath = m_strPath

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "Get_TrainPath", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::Get_TrainRSID
' Input:        none
' Output:       [String] The RS ID
' Description:  Returns the RS ID of the train
'-------------------------------------------------------------------------------
Public Property Get TrainRSID() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "Get_TrainRSID", "Begin Property")

    TrainRSID = m_strRSID

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "Get_TrainRSID", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::Get_TrainType
' Input:        none
' Output:       [String] The type
' Description:  Returns the type of the train
'-------------------------------------------------------------------------------
Public Property Get TrainType() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "Get_TrainType", "Begin Property")

    TrainType = m_strType

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "Get_TrainType", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::Get_TrainComposition
' Input:        none
' Output:       [String] The composition
' Description:  Returns the composition of the train
'-------------------------------------------------------------------------------
Public Property Get TrainComposition() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "Get_TrainComposition", "Begin Property")

    TrainComposition = m_strComposition

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "Get_TrainCompositione", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::GetCounters
' Input:        none
' Output:       [Collection]   Collection of counters
' Description:  Returns the collection of counters of a train
'-------------------------------------------------------------------------------
Public Function GetCounters() As Collection
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "GetCounters", "Begin Function")
   
    If Not (m_Counters Is Nothing) Then
        Set GetCounters = m_Counters
    Else
        Set GetCounters = Nothing
    End If
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "GetCounters", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::m_OPCItem_txtRSID_OnRefresh
' Input:        [Variant] Value
'               [Integer] Quality
' Output:       none
' Description:  Update the RSID of the train
'-------------------------------------------------------------------------------
Private Sub m_OPCItem_txtRSID_OnRefresh(Value As Variant, Quality As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "m_OPCItem_txtRSID_OnRefresh", "Begin Subroutine")
    
    If (StrComp(Value, m_strRSID, vbTextCompare) <> 0) Then
        ' Update the class attribute
        m_strRSID = Value
        ' Set the variable containing the notification ->
        ' <TrainPath>;"id";<NewValue>
        If Not (Variables.Item(c_strModifNotificationTag) Is Nothing) Then
            Variables.Item(c_strModifNotificationTag).Value = m_strPath & c_strItemSeparator & c_strRSIDParam & _
                                                              c_strItemSeparator & Value
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "m_OPCItem_txtRSID_OnRefresh", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::m_OPCItem_txtType_OnRefresh
' Input:        [Variant] Value
'               [Integer] Quality
' Output:       none
' Description:  Update the type of the train
'-------------------------------------------------------------------------------
Private Sub m_OPCItem_txtType_OnRefresh(Value As Variant, Quality As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "m_OPCItem_txtType_OnRefresh", "Begin Subroutine")
    
    If (StrComp(Value, m_strType, vbTextCompare) <> 0) Then
        ' Update the class attribute
        m_strType = Value
        ' Set the variable containing the notification ->
        ' <TrainPath>;"type";<NewValue>
        If Not (Variables.Item(c_strModifNotificationTag) Is Nothing) Then
            Variables.Item(c_strModifNotificationTag).Value = m_strPath & c_strItemSeparator & c_strTypeParam & _
                                                              c_strItemSeparator & Value
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "m_OPCItem_txtType_OnRefresh", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::m_OPCItem_txtComposition_OnRefresh
' Input:        [Variant] Value
'               [Integer] Quality
' Output:       none
' Description:  If the value has changed, update the class attribute and
'               and set the variable containing the notification
'-------------------------------------------------------------------------------
Private Sub m_OPCItem_txtComposition_OnRefresh(Value As Variant, Quality As Integer)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "m_OPCItem_txtComposition_OnRefresh", "Begin Subroutine")
    Dim strNewComposition As String
    
    ' Read the XML format string containing the train composition
    strNewComposition = ReadCompositionString(Value)
    ' Check if the new value is different from the current value
    If (StrComp(strNewComposition, m_strComposition, vbTextCompare) <> 0) Then
        ' Update the class attribute
        m_strComposition = strNewComposition
        ' Set the variable containing the notification ->
        ' <TrainPath>;"composition";<NewValue>
        If Not (Variables.Item(c_strModifNotificationTag) Is Nothing) Then
            Variables.Item(c_strModifNotificationTag).Value = m_strPath & c_strItemSeparator & c_strCompositionParam & _
                                                              c_strItemSeparator & strNewComposition
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "m_OPCItem_txtComposition_OnRefresh", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_RollingStock::ReadCompositionString
' Input:        none
' Output:       none
' Description:  Read the XML format string conatining the composition of train
'-------------------------------------------------------------------------------
Private Function ReadCompositionString(ByVal strXMLString As String) As String
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_RollingStock", "ReadCompositionString", "Begin Function")
   
   Dim oDoc As DOMDocument
   Dim oCarsList As IXMLDOMNodeList
   Dim oCar As IXMLDOMElement
   Dim strID As String
   Dim strComposition As String
   Dim iNbCar As Integer
   
   If (strXMLString <> "") Then
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Car"
                    Set oCarsList = oDoc.documentElement.selectNodes(c_strCarNode)
                    If Not (oCarsList Is Nothing) Then
                        If (oCarsList.length > 0) Then
                            For Each oCar In oCarsList
                                ' ID attribute
                                strID = Format(oCar.getAttribute(c_strIDAttr))
                                If (strID <> "") Then
                                    If (iNbCar < oCarsList.length - 1) Then
                                        strComposition = strComposition & strID & c_strCarSeparator
                                    Else ' Last car
                                        strComposition = strComposition & strID
                                    End If
                                End If
                                iNbCar = iNbCar + 1
                            Next oCar
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "ReadCompositionString", _
                                         "No car has been defined in the OPC variable [" & m_OPCItem_txtComposition.strPath & "]")
                        End If
                        Set oCarsList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "ReadCompositionString", _
                             "The content of the OPC variable [" & m_OPCItem_txtComposition.strPath & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "ReadCompositionString", _
                     "The OPC variable [" & m_OPCItem_txtComposition.strPath & "] is empty")
    End If
    
    ' Return the composition in the following format: <Car1_ID>-<Car2_ID>-...-<CarN_ID>
    ReadCompositionString = strComposition
     
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_RollingStock", "ReadCompositionString", Err.Description)
End Function
