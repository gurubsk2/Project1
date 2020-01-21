VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_Platform"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2012. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_Platform
'* *******************************************************************************************
'* Purpose: Manages a platform
'* *******************************************************************************************
'* Modification History:
'* Author:              Nicole FLORIAN
'* Date:                August '12
'* Change:              All - CR ALPHA 270265

'* Author:              Nicole FLORIAN
'* Date:                November '12
'* Change:              CR ALPHA 322784
'*                      Remove two traces in the "ReadReachablePointsXMLString" subroutine

'* Author:              Eric FOISSEY
'* Date:                September '13
'* Change:              CR atvcm 176330 : add read KP function

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
' Used to read the string (XML format) containing the list of reachable points with maneuvers from the platform
Private Const c_strPointNode As String = "Point"
Private Const c_strNameAttr As String = "Name"
Private Const c_strIDAttr As String = "ID"

' Path of OPC variable containing the list of reachable points with maneuvers from the platform
Private Const c_strReachablePointTag As String = ".ReachablePointsWithManeuvers.Value"

' Class attributes
' ------------------------------------------------------
' Platform ID
Private m_strID As String
' Platform Name
Private m_strName As String
' Station ID
Private m_strStationID As String
' Station Name
Private m_strStationName As String
' Dictionary of reachable points
Private m_ReachablePoints As Object
' KP of the platform
Private m_dKP As Double

' Flag indicating if the value of the OPC variable containing the list
' of points reachable from the platform has been received
Private m_ReachablePointFlag As Boolean

' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------
' OPC variable containing the list of the points reachable from the platform
Private WithEvents m_OPC_ReachablePointList As Variable
Attribute m_OPC_ReachablePointList.VB_VarHelpID = -1

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::Init
' Input:        [String]   ID of the platform (name of the OPC variable)
'               [String]   Name of the platform
'               [String]   ID of the station (name of the OPC variable) to which
'                          the platform belongs
'               [String]   Name of the station (name of the OPC variable) to which
'                          the platform belongs
'               [double]   KP of the platform (optional)
' Output:       none
' Description:  Init variables
'-------------------------------------------------------------------------------
Public Sub Init(ByVal strID As String, ByVal strName As String, ByVal strStationID As String, ByVal strStationName As String, Optional ByVal dKP As Double)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platform", "Init", "Begin Subroutine")
  
    ' Init attributes
    m_strID = strID
    m_strName = strName
    m_strStationID = strStationID
    m_strStationName = strStationName
    m_dKP = dKP
    
    ' Init dictionary
    Set m_ReachablePoints = Nothing
    Set m_ReachablePoints = CreateObject("Scripting.Dictionary")
    
    ' Add OPC variable containing the list of points reachable from the platform
    Set m_OPC_ReachablePointList = Variables.Add(MOD_Deployment.Level2Cluster & strID & c_strReachablePointTag, fvVariableTypeText)
    If (m_OPC_ReachablePointList.EnableEvents = True) Then
        m_OPC_ReachablePointList_ValueChange
    Else
        m_OPC_ReachablePointList.EnableEvents = True
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "Init", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platform", "Class_Terminate", "Begin Subroutine")
    Dim I As Integer
    
    ' Empty dictionary
    If Not (m_ReachablePoints Is Nothing) Then
        If (m_ReachablePoints.Count > 0) Then
            m_ReachablePoints.removeAll
        End If
        Set m_ReachablePoints = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_ReachablePointList Is Nothing) Then
        Variables.Remove (m_OPC_ReachablePointList.Name)
        Set m_OPC_ReachablePointList = Nothing
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "Class_Terminate", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::Get_PlatformID
' Input:        none
' Output:       [String] The ID of the platform
' Description:  Returns the ID of the platform
'-------------------------------------------------------------------------------
Public Property Get PlatformID() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platform", "Get_PlatformID", "Begin Property")

    PlatformID = m_strID

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "Get_PlatformID", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::Get_PlatformName
' Input:        none
' Output:       [String] The name of the platform
' Description:  Returns the name of the platform
'-------------------------------------------------------------------------------
Public Property Get PlatformName() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platform", "Get_PlatformName", "Begin Property")

    PlatformName = m_strName

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "Get_PlatformName", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::Get_PlatformKP
' Input:        none
' Output:       [double] The KP of the platform
' Description:  Returns the KP of the platform
'-------------------------------------------------------------------------------
Public Property Get PlatformKP() As Double
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platform", "Get_PlatformKP", "Begin Property")

    PlatformKP = m_dKP

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "Get_PlatformKP", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::Get_PlatformStationID
' Input:        none
' Output:       [String] The ID of the station
' Description:  Returns the ID of the station to which the platform belongs
'-------------------------------------------------------------------------------
Public Property Get PlatformStationID() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platform", "Get_PlatformStationID", "Begin Property")

    PlatformStationID = m_strStationID

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "Get_PlatformStationID", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::Get_PlatformStationName
' Input:        none
' Output:       [String] The name of the station
' Description:  Returns the name of the station to which the Platform belong
'-------------------------------------------------------------------------------
Public Property Get PlatformStationName() As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platform", "Get_PlatformStationName", "Begin Property")

    PlatformStationName = m_strStationName

Exit Property
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "Get_PlatformStationName", Err.Description)
End Property

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::GetReachablePoints
' Input:        none
' Output:       [Collection]   Collection of reachable points
' Description:  Returns the list of points reachable from the platform
'-------------------------------------------------------------------------------
Public Function GetReachablePoints() As Object
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platform", "GetReachablePoints", "Begin Function")
   
    If Not (m_ReachablePoints Is Nothing) Then
        Set GetReachablePoints = m_ReachablePoints
    Else
        Set GetReachablePoints = Nothing
    End If
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "GetReachablePoints", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::ReadReachablePointsXMLString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of platforms
'-------------------------------------------------------------------------------
Private Sub ReadReachablePointsXMLString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platform", "ReadReachablePointsXMLString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oPointList As IXMLDOMNodeList
   Dim oPoint As IXMLDOMElement
   Dim strName As String
   Dim strID As String
   
   strXMLString = m_OPC_ReachablePointList.Value
   If (strXMLString <> "") Then
                       
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Point"
                    Set oPointList = oDoc.documentElement.selectNodes(c_strPointNode)
                    If Not (oPointList Is Nothing) Then
                        If (oPointList.length > 0) Then
                            For Each oPoint In oPointList
                                ' Name attribute
                                strName = Format(oPoint.getAttribute(c_strNameAttr))
                                ' ID attribute
                                strID = Format(oPoint.getAttribute(c_strIDAttr))
                                                                             
                                If ((strID <> "") And (strName <> "")) Then
                                    ' Memorize the instance in the dictionary
                                    m_ReachablePoints.Add strName, strID
                                End If
                                
                            Next oPoint
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "ReadReachablePointsXMLString", _
                                         "No point has been defined in the OPC variable [" & m_OPC_ReachablePointList.Name & "]")
                        End If
                        Set oPointList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "ReadReachablePointsXMLString", _
                             "The content of the OPC variable [" & m_OPC_ReachablePointList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "ReadReachablePointsXMLString", _
                     "The OPC variable [" & m_OPC_ReachablePointList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "ReadReachablePointsXMLString", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_Platform::m_OPC_ReachablePointList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of reachable points
'               with maneuvers from the platform
'-----------------------------------------------------------------------------------
Private Sub m_OPC_ReachablePointList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Platform", "m_OPC_ReachablePointList_ValueChange", "Begin Subroutine")
    
    If (m_OPC_ReachablePointList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Platforms", "m_OPC_ReachablePointList_ValueChange", "The status of " & m_OPC_ReachablePointList.Name & " is Waiting")
    ElseIf (m_OPC_ReachablePointList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platforms", "m_OPC_ReachablePointList_ValueChange", "The status of " & m_OPC_ReachablePointList.Name & " is Config Error")
    ElseIf (m_OPC_ReachablePointList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Platforms", "m_OPC_ReachablePointList_ValueChange", "The status of " & m_OPC_ReachablePointList.Name & " is Not Connected")
    ElseIf (m_OPC_ReachablePointList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Platforms", "m_OPC_ReachablePointList_ValueChange", "The Quality of " & m_OPC_ReachablePointList.Name & " is not good")
    Else
        If (m_ReachablePointFlag = False) Then
            ' Set the flag indicating that data have been received
            m_ReachablePointFlag = True
            ' Read the string
            ReadReachablePointsXMLString
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Platform", "m_OPC_ReachablePointList_ValueChange", Err.Description)
End Sub
