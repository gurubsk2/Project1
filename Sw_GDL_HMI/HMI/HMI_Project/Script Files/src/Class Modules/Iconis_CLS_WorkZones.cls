VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_WorkZones"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_WorkZones
'* *******************************************************************************************
'* Purpose: Manages a WorkZone definitions - provides function to read the LCClient list and
'*          function to read the conditions names
'* *******************************************************************************************
'* Modification History:
'* Author:              Eric FOISSEY
'* Date:                January '13
'* Change:              All - CR ALPHA 335127

'* Author:              Eric FOISSEY
'* Date:                May '13
'* Change:              Boundaries management - CR ALPHA 335127 - Complement

'* Author:              Eric FOISSEY
'* Date:                July '13
'* Change:              CR ALPHA 335127 - Complement2 - optimisation - update the list only on value change

'* Author:              Eric FOISSEY
'* Date:                January '14
'* Change:              CR atvcm 503646- Trace, and Block UEID reading modification

'* Author:              Eric FOISSEY
'* Date:                January '14
'* Change:              CR atvcm 503646- Fixed in UEID modification

'* Author:              Abhishek PATIL
'* Date:                Feb '16
'* Change:              CR  XXXXXX
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit

' Constants
' ------------------------------------------------------
' Used to read the string (XML format) containing the list of condition definitions
Private Const c_strWorkZoneConditionNode As String = "WorkZonesCondition"
Private Const c_strWZCIDAttr As String = "ID"
Private Const c_strWZCNameAttr As String = "Name"

Private Const c_iNoRestrictionSpeed As Integer = 255

' Path of OPC variable containing the list of condition definitions
Private Const c_strXMLconditionListTag As String = ".WorkZonesConditionsList.Value"

' Used to read the string (XML format) containing the list of LC Client
Private Const c_strLCNode As String = "LC"
Private Const c_strLCCIDAttr As String = "ID"
Private Const c_strLCNameAttr As String = "Name"

' Path of OPC variable containing the list of LCs
Private Const c_strXMLLCsListTag As String = "IconisHMI.LCsList.Information.Value"

' Path of OPC variable containing the list of Source work zone boundaries
Private Const c_strXMLSourceWzListTag As String = "IconisHMI.CalculatedWorkZoneBoundaryList.Information.Value"
' Path of OPC variable containing the list of WZ defined
Private Const c_strXMLWZsAppliedListTag As String = ".WZAppliedXmlData.bstrValue"

' Path of OPC variable containing the list of WZ defined in session
Private Const c_strXMLWZsInSessionListTag As String = ".WZSessionXmlData.bstrValue"

'Path of OPC Variable containing the indicator of WZApplied on the first LC
Private Const c_strFirstLCTSRAppliedTag = "@FirstLC_TSRApplied%"
Private Const m_strTSRAppliedInitTag As String = ".TSRAppliedInit.Value"
'Path of OPC Variable containing the indicator of WZ list changed
Private Const c_strWZChangeNotifyTag = "@WZ_ChangeNotified%"
'Path of OPC Variable containing the indicator of WZ list changed
Private Const c_strWZInSessionChangeNotifyTag = "@WZInSession_ChangeNotified%"

' Used to read the string (XML format) containing the workzone definition
Private Const c_strWorkZoneNode As String = "WZ"
Private Const c_strWZIDAttr As String = "ID"
Private Const c_strWZSpeedAttr As String = "Speed"
Private Const c_strWZCond1Attr As String = "condition1"
Private Const c_strWZCond2Attr As String = "condition2"
Private Const c_strWZCond3Attr As String = "condition3"
Private Const c_strWZCond4Attr As String = "condition4"
Private Const c_strWZCond5Attr As String = "condition5"
Private Const c_strWZCond6Attr As String = "condition6"
Private Const c_strWZCond7Attr As String = "condition7"
Private Const c_strWZCond8Attr As String = "condition8"
Private Const c_strBlockNode As String = "Block"
Private Const c_strBlockIDAttr As String = "ID"

'used to read the block list and read their UEID
Private Const c_strBlockUEIDTag As String = ".UEID.Value"
Private Const c_strBlockListTag As String = "IconisHMI.FixedBlocksList.Value"
Private Const c_strBlockIDNode As String = "FixedBlock"

'used to read the speed restriction list associated with the current LC
Private Const c_strSpeedRestrictionTag As String = ".RestrictionSpeeds.Value"
Private Const c_strSpeedNode As String = "Speed"
Private Const c_strSpeedIDAttr As String = "ID"
Private Const c_strSpeedNoRestriction As String = "-"

Private Const c_strPrepDestinationBoundaryList = ".PrepWorkZonesBoundaryList"


'used to read the workzones boundaries
Private Const c_strWorkzoneBoundariesTag As String = ".WorkZonesBoundaries.Value"
Private Const c_strWZOriginNode As String = "WorkZonesBoundaryOrigin"
Private Const c_strWZDestinationNode As String = "PrepWorkZonesBoundary"
Private Const c_strBoundaryIDAttr As String = "ID"
Private Const c_strBoundaryNameAttr As String = "Name"
Private Const c_strBoundaryBlockAttr As String = "BlockID"
Private Const c_strBoundaryUEIDAttr As String = "UEID"
Private Const c_strBoundaryUEIDTag As String = ".UEID.Value"
' Class attributes
' ------------------------------------------------------
' LC IDs List
Private m_strLCIDs() As String
'AP-Feb16::LC Names List
Private m_strLCNames() As String
' Condition Names
Private m_strConditionsNames() As String
Private m_strConditionsIDs() As String


' Workzone List
Private m_strWZIDs() As String
Private m_strSpeedRestrictions() As String

Private m_strCondition1() As String
Private m_strCondition2() As String
Private m_strCondition3() As String
Private m_strCondition4() As String
Private m_strCondition5() As String
Private m_strCondition6() As String
Private m_strCondition7() As String
Private m_strCondition8() As String

Private m_strBlocks() As String

' Workzone List
Private m_strInSessionWZIDs() As String
Private m_strInSessionSpeedRestrictions() As String

Private m_strInSessionCondition1() As String
Private m_strInSessionCondition2() As String
Private m_strInSessionCondition3() As String
Private m_strInSessionCondition4() As String
Private m_strInSessionCondition5() As String
Private m_strInSessionCondition6() As String
Private m_strInSessionCondition7() As String
Private m_strInSessionCondition8() As String

Private m_strInSessionBlocks() As String

'Block list
Private m_strBlockID() As String
Private m_strBlockUEID() As String

'Speed Restriction List
Private m_strAvailableSpeedArray() As String

'Boundaries list
Private m_BoundariesList() As BoundaryDescription

Private m_strWorkzoneBoundaryslist() As String
Private m_strWorkzoneBoundarysAliaslist() As String

Private iWzBoundaryListItem As Integer
' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------
' OPC variable containing the list of the commands allowed
Private WithEvents m_OPC_XML_LCList As Variable
Attribute m_OPC_XML_LCList.VB_VarHelpID = -1
Private WithEvents m_OPC_XML_ConditionList As Variable
Attribute m_OPC_XML_ConditionList.VB_VarHelpID = -1

Private WithEvents m_OPC_XML_CurrentWZlist As Variable
Attribute m_OPC_XML_CurrentWZlist.VB_VarHelpID = -1
Private WithEvents m_OPC_XML_WZInSessionlist As Variable
Attribute m_OPC_XML_WZInSessionlist.VB_VarHelpID = -1
Private WithEvents m_OPC_TSRAppliedInit As Variable
Attribute m_OPC_TSRAppliedInit.VB_VarHelpID = -1

Private WithEvents m_OPC_XML_BlockList As Variable
Attribute m_OPC_XML_BlockList.VB_VarHelpID = -1
Private WithEvents m_OPC_XML_SpeedList As Variable
Attribute m_OPC_XML_SpeedList.VB_VarHelpID = -1

Private WithEvents m_OPC_XML_BoundaryList As Variable
Attribute m_OPC_XML_BoundaryList.VB_VarHelpID = -1

Private m_OPC_LCWZAppliedAnim As Variable
Attribute m_OPC_LCWZAppliedAnim.VB_VarHelpID = -1
Private m_OPC_WZNotify As Variable
Attribute m_OPC_WZNotify.VB_VarHelpID = -1
Private m_OPC_WZInSessionNotify As Variable

Private WithEvents m_OPCSet_BlockUEID As Iconis_CLS_OPCSet
Attribute m_OPCSet_BlockUEID.VB_VarHelpID = -1

Private m_current_LCList As String
Private m_current_ConditionList As String
Private m_current_CurrentWZlist As String
Private m_current_WZInSessionlist As String
Private m_current_BlockList As String
Private m_current_SpeedList As String
Private m_current_BoundaryList As String
Private m_current_LC As String

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Init
' Input:        none
' Output:       none
' Description:  Init variables, create dictionnaries
'-------------------------------------------------------------------------------
Public Sub Init()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Init", "Begin Subroutine")
     
    m_current_LCList = ""
    m_current_ConditionList = ""
    m_current_CurrentWZlist = ""
    m_current_WZInSessionlist = ""
    m_current_BlockList = ""
    m_current_SpeedList = ""
    m_current_BoundaryList = ""
    ReDim m_strWorkzoneBoundaryslist(0)
    ReDim m_strWorkzoneBoundarysAliaslist(0)
    
    ReDim m_strLCIDs(0)
    ReDim m_strLCNames(0)
    ReDim m_strBlockID(0)
    ReDim m_strBlockUEID(0)

    Set m_OPCSet_BlockUEID = Nothing
    ' Add OPC variable containing the list of blocks
    Set m_OPC_XML_BlockList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strBlockListTag, fvVariableTypeText)
    If (m_OPC_XML_BlockList.EnableEvents = True) Then
        m_OPC_XML_BlockList_ValueChange
    Else
        m_OPC_XML_BlockList.EnableEvents = True
    End If

    ' Add OPC variable containing the animations for the button
    Set m_OPC_LCWZAppliedAnim = Variables.Add(c_strFirstLCTSRAppliedTag, fvVariableTypeRegister)
    m_OPC_LCWZAppliedAnim.Value = 3 'unknown status displayed as long as no list is set
    
    ' Add OPC variable that provides the update of workzone
    Set m_OPC_WZNotify = Variables.Add(c_strWZChangeNotifyTag, fvVariableTypeBit)
    Set m_OPC_WZInSessionNotify = Variables.Add(c_strWZInSessionChangeNotifyTag, fvVariableTypeBit)
    
    ' Add OPC variable containing the list of LCs
    Set m_OPC_XML_LCList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strXMLLCsListTag, fvVariableTypeText)
    If (m_OPC_XML_LCList.EnableEvents = True) Then
        m_OPC_XML_LCList_ValueChange
    Else
        m_OPC_XML_LCList.EnableEvents = True
    End If

    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Init", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::m_OPC_XML_BoundaryList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of workzones boundaries
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_BoundaryList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_BoundaryList_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_BoundaryList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPC_XML_BoundaryList_ValueChange", "The status of " & m_OPC_XML_BoundaryList.Name & " is Waiting")
    ElseIf (m_OPC_XML_BoundaryList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_BoundaryList_ValueChange", "The status of " & m_OPC_XML_BoundaryList.Name & " is Config Error")
    ElseIf (m_OPC_XML_BoundaryList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_BoundaryList_ValueChange", "The status of " & m_OPC_XML_BoundaryList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_BoundaryList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_BoundaryList_ValueChange", "The Quality of " & m_OPC_XML_BoundaryList.Name & " is not good")
    Else
        If (m_current_BoundaryList <> m_OPC_XML_BoundaryList.Value Or m_current_BoundaryList = "") Then
           ReadXMLCalucaltedWorkZoneBoundaryListString
           m_current_BoundaryList = m_OPC_XML_BoundaryList.Value
           ReadWZBoundaryData
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_BoundaryList_ValueChange", Err.Description)
End Sub
'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::ReadXMLCalucaltedWorkZoneBoundaryListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) form the plug caluclaed work zone boundaries
'               containing the list of workzone boundary for the LC
'-------------------------------------------------------------------------------
Private Sub ReadXMLCalucaltedWorkZoneBoundaryListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "ReadXMLCalucaltedWorkZoneBoundaryListString", "Begin Subroutine")

   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oBoundaryList As IXMLDOMNodeList
   Dim oBoundary As IXMLDOMElement
  
   Dim oBoundaryDestination As IXMLDOMElement
  
   Dim strDestination As String
   
   Dim iCounter As Integer
   Dim StrQuery As String
   strXMLString = m_OPC_XML_BoundaryList.Value
   
   ' Empty the data lists of boundaries array
   ReDim m_strWorkzoneBoundaryslist(0)
   ReDim m_strWorkzoneBoundarysAliaslist(0)
    
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
          If Not (oDoc Is Nothing) Then
          
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "workzone boundaries origins"
                    Set oBoundaryList = oDoc.documentElement.getElementsByTagName("WorkZoneBoundary")
                    If Not (oBoundaryList Is Nothing) Then
                        If (oBoundaryList.length > 0) Then
                            ReDim m_strWorkzoneBoundaryslist(oBoundaryList.length - 1)
                            ReDim m_strWorkzoneBoundarysAliaslist(oBoundaryList.length - 1)
                            iCounter = 0
                            For Each oBoundary In oBoundaryList
                                ' read the attributes
                                m_strWorkzoneBoundaryslist(iCounter) = oBoundary.getAttribute(c_strBoundaryIDAttr)
                                m_strWorkzoneBoundarysAliaslist(iCounter) = oBoundary.getAttribute(c_strBoundaryNameAttr)
                                iCounter = iCounter + 1
                            Next oBoundary
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLCalucaltedWorkZoneBoundaryListString", _
                                         "No Boundary has been defined in the OPC variable [" & m_OPC_XML_BoundaryList.Name & "]")
                        End If
                        Set oBoundaryList = Nothing
                    End If
                End If
            Else
                 Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLCalucaltedWorkZoneBoundaryListString", _
                             "The content of the OPC variable [" & m_OPC_XML_BoundaryList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLCalucaltedWorkZoneBoundaryListString", _
                     "The OPC variable [" & m_OPC_XML_BoundaryList.Name & "] is empty")
    End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLCalucaltedWorkZoneBoundaryListString", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::SetCurrentLC
' Input:        [LCID] string : ID of the LC to read
' Output:       none
' Description:  initialize the data to read the workzone IDs
'-------------------------------------------------------------------------------
Public Sub SetCurrentLC(ByVal LCID As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "SetCurrentLC", "Begin Subroutine")
    
    '*clear all tab
    ReDim m_strWZIDs(0)
    ReDim m_strSpeedRestrictions(0)
    
    ReDim m_strConditionsNames(0)
    
    ReDim m_strCondition1(0)
    ReDim m_strCondition2(0)
    ReDim m_strCondition3(0)
    ReDim m_strCondition4(0)
    ReDim m_strCondition5(0)
    ReDim m_strCondition6(0)
    ReDim m_strCondition7(0)
    ReDim m_strCondition8(0)
    ReDim m_strBlocks(0)
    
    '*clear all tab
    ReDim m_strInSessionWZIDs(0)
    ReDim m_strInSessionSpeedRestrictions(0)
    
    ReDim m_strInSessionCondition1(0)
    ReDim m_strInSessionCondition2(0)
    ReDim m_strInSessionCondition3(0)
    ReDim m_strInSessionCondition4(0)
    ReDim m_strInSessionCondition5(0)
    ReDim m_strInSessionCondition6(0)
    ReDim m_strInSessionCondition7(0)
    ReDim m_strInSessionCondition8(0)
    ReDim m_strInSessionBlocks(0)
    
    ' speed array
    ReDim m_strAvailableSpeedArray(0)
    
    ' boundaries array
    ReDim m_BoundariesList(0)
    ReDim m_strWorkzoneBoundaryslist(0)
    ReDim m_strWorkzoneBoundarysAliaslist(0)
    m_current_ConditionList = ""
    m_current_CurrentWZlist = ""
    m_current_WZInSessionlist = ""
    m_current_BlockList = ""
    m_current_SpeedList = ""
    m_current_BoundaryList = ""
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_ConditionList Is Nothing) Then
        Variables.Remove (m_OPC_XML_ConditionList.Name)
        Set m_OPC_XML_ConditionList = Nothing
    End If
    ' Add OPC variable containing the list of workzone conditions
    Set m_OPC_XML_ConditionList = Variables.Add(Iconis_MOD_General.GetOPCCluster & LCID & c_strXMLconditionListTag, fvVariableTypeText)
    If (m_OPC_XML_ConditionList.EnableEvents = True) Then
        m_OPC_XML_ConditionList_ValueChange
    Else
        m_OPC_XML_ConditionList.EnableEvents = True
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_CurrentWZlist Is Nothing) Then
        Variables.Remove (m_OPC_XML_CurrentWZlist.Name)
        Set m_OPC_XML_CurrentWZlist = Nothing
    End If
    
    If Not (m_OPC_XML_SpeedList Is Nothing) Then
        Variables.Remove (m_OPC_XML_SpeedList.Name)
        Set m_OPC_XML_SpeedList = Nothing
    End If
    
    ' Add OPC variable containing the list of speed restrictions
    Set m_OPC_XML_SpeedList = Variables.Add(Iconis_MOD_General.GetOPCCluster & LCID & c_strSpeedRestrictionTag, fvVariableTypeText)
    If (m_OPC_XML_SpeedList.EnableEvents = True) Then
        m_OPC_XML_SpeedList_ValueChange
    Else
        m_OPC_XML_SpeedList.EnableEvents = True
    End If
    
    ' Add OPC variable containing the list of workzone definitions
    Set m_OPC_XML_CurrentWZlist = Variables.Add(Iconis_MOD_General.GetOPCCluster & LCID & c_strXMLWZsAppliedListTag, fvVariableTypeText)
    If (m_OPC_XML_CurrentWZlist.EnableEvents = True) Then
        m_OPC_XML_CurrentWZlist_ValueChange
    Else
        m_OPC_XML_CurrentWZlist.EnableEvents = True
    End If
    
    ' Add OPC variable containing the list of workzone in session
    Set m_OPC_XML_WZInSessionlist = Variables.Add(Iconis_MOD_General.GetOPCCluster & LCID & c_strXMLWZsInSessionListTag, fvVariableTypeText)
    If (m_OPC_XML_WZInSessionlist.EnableEvents = True) Then
        m_OPC_XML_WZInSessionlist_ValueChange
    Else
        m_OPC_XML_WZInSessionlist.EnableEvents = True
    End If
    
    ' Add OPC variable containing the list of workzone boundaries
    Set m_OPC_XML_BoundaryList = Variables.Add(Iconis_MOD_General.GetOPCCluster & c_strXMLSourceWzListTag, fvVariableTypeAny)
    If (m_OPC_XML_BoundaryList.EnableEvents = True) Then
        m_OPC_XML_BoundaryList_ValueChange
    Else
        m_OPC_XML_BoundaryList.EnableEvents = True
    End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "SetCurrentLC", Err.Description)
End Sub
'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Class_Terminate", "Begin Subroutine")
   
    ' Empty the data lists
    ReDim m_strConditionsNames(0)
    ReDim m_strLCIDs(0)
    ReDim m_strLCNames(0)
    ReDim m_strWZIDs(0)
    ReDim m_strSpeedRestrictions(0)
    
    ReDim m_strCondition1(0)
    ReDim m_strCondition2(0)
    ReDim m_strCondition3(0)
    ReDim m_strCondition4(0)
    ReDim m_strCondition5(0)
    ReDim m_strCondition6(0)
    ReDim m_strCondition7(0)
    ReDim m_strCondition8(0)
    ReDim m_strBlocks(0)
    
    ReDim m_strInSessionWZIDs(0)
    ReDim m_strInSessionSpeedRestrictions(0)
    
    ReDim m_strInSessionCondition1(0)
    ReDim m_strInSessionCondition2(0)
    ReDim m_strInSessionCondition3(0)
    ReDim m_strInSessionCondition4(0)
    ReDim m_strInSessionCondition5(0)
    ReDim m_strInSessionCondition6(0)
    ReDim m_strInSessionCondition7(0)
    ReDim m_strInSessionCondition8(0)
    ReDim m_strInSessionBlocks(0)
    
    ReDim m_strBlockID(0)
    ReDim m_strBlockUEID(0)
    
    ' boundaries array
    ReDim m_BoundariesList(0)

    If Not (m_OPCSet_BlockUEID Is Nothing) Then
        m_OPCSet_BlockUEID.Destroy
        Set m_OPCSet_BlockUEID = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_LCList Is Nothing) Then
        Variables.Remove (m_OPC_XML_LCList.Name)
        Set m_OPC_XML_LCList = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_ConditionList Is Nothing) Then
        Variables.Remove (m_OPC_XML_ConditionList.Name)
        Set m_OPC_XML_ConditionList = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_CurrentWZlist Is Nothing) Then
        Variables.Remove (m_OPC_XML_CurrentWZlist.Name)
        Set m_OPC_XML_CurrentWZlist = Nothing
    End If
        
    If Not (m_OPC_XML_WZInSessionlist Is Nothing) Then
        Variables.Remove (m_OPC_XML_WZInSessionlist.Name)
        Set m_OPC_XML_WZInSessionlist = Nothing
    End If
    
    If Not (m_OPC_XML_SpeedList Is Nothing) Then
        Variables.Remove (m_OPC_XML_SpeedList.Name)
        Set m_OPC_XML_SpeedList = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_LCWZAppliedAnim Is Nothing) Then
        Variables.Remove (m_OPC_LCWZAppliedAnim.Name)
        Set m_OPC_LCWZAppliedAnim = Nothing
    End If
    
    If Not (m_OPC_WZNotify Is Nothing) Then
        Variables.Remove (m_OPC_WZNotify.Name)
        Set m_OPC_WZNotify = Nothing
    End If
    
    If Not (m_OPC_WZInSessionNotify Is Nothing) Then
        Variables.Remove (m_OPC_WZInSessionNotify.Name)
        Set m_OPC_WZInSessionNotify = Nothing
    End If
    
    If Not (m_OPC_TSRAppliedInit Is Nothing) Then
        Variables.Remove (m_OPC_TSRAppliedInit.Name)
        Set m_OPC_TSRAppliedInit = Nothing
    End If
    
    If Not (m_OPC_XML_BoundaryList Is Nothing) Then
        Variables.Remove (m_OPC_XML_BoundaryList.Name)
        Set m_OPC_XML_BoundaryList = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_BlockList Is Nothing) Then
        Variables.Remove (m_OPC_XML_BlockList.Name)
        Set m_OPC_XML_BlockList = Nothing
    End If
    
    m_current_LCList = ""
    m_current_ConditionList = ""
    m_current_CurrentWZlist = ""
    m_current_WZInSessionlist = ""
    m_current_BlockList = ""
    m_current_SpeedList = ""
    m_current_BoundaryList = ""
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Class_Terminate", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::m_OPC_XML_LineMode_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of commands allowed
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_LCList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_LCList_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_LCList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPC_XML_LCList_ValueChange", "The status of " & m_OPC_XML_LCList.Name & " is Waiting")
    ElseIf (m_OPC_XML_LCList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_LCList_ValueChange", "The status of " & m_OPC_XML_LCList.Name & " is Config Error")
    ElseIf (m_OPC_XML_LCList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_LCList_ValueChange", "The status of " & m_OPC_XML_LCList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_LCList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_LCList_ValueChange", "The Quality of " & m_OPC_XML_LCList.Name & " is not good")
    Else
        If (m_current_LCList <> m_OPC_XML_LCList.Value) Then
            m_current_LCList = m_OPC_XML_LCList.Value
            ' Read the string
            ReadLCListString
        End If
        
        'initialize the animation of TSR/WZ applied
        If (Get_LCID(0) <> "") Then
            '* Add variable containing the value of TSR Applied Init for the current LC
            Set m_OPC_TSRAppliedInit = Variables.Add(Iconis_MOD_General.GetOPCCluster & Get_LCID(0) & m_strTSRAppliedInitTag, fvVariableTypeRegister)
            If ((m_OPC_TSRAppliedInit.EnableEvents = True) And (m_OPC_TSRAppliedInit.Status = fvVariableStatusGood)) Then
                m_OPC_TSRAppliedInit_ValueChange
            Else
                m_OPC_TSRAppliedInit.EnableEvents = True
            End If
        Else
            'if no LC read then WZ applied is set to unknown
            If Not (m_OPC_LCWZAppliedAnim Is Nothing) Then
                m_OPC_LCWZAppliedAnim.Value = 3
            End If
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_LCList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::ReadLCListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of LC
'-------------------------------------------------------------------------------
Private Sub ReadLCListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "ReadLCListString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oLCList As IXMLDOMNodeList
   Dim oLC As IXMLDOMElement

   Dim iCounter As Integer
   
   strXMLString = m_OPC_XML_LCList.Value
   
    ' Empty the data lists
    ReDim m_strLCIDs(0)
    ReDim m_strLCNames(0)
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Table"
                    Set oLCList = oDoc.documentElement.getElementsByTagName(c_strLCNode)
                    If Not (oLCList Is Nothing) Then
                        If (oLCList.length > 0) Then
                            ReDim Preserve m_strLCIDs(oLCList.length - 1)
                            ReDim Preserve m_strLCNames(oLCList.length - 1)
                            
                            iCounter = 0
                            For Each oLC In oLCList
                                ' Name attribute
                                m_strLCIDs(iCounter) = oLC.getAttribute(c_strLCCIDAttr)
                                m_strLCNames(iCounter) = oLC.getAttribute(c_strLCNameAttr)
                                iCounter = iCounter + 1
                            Next oLC
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadLCListString", _
                                         "No LC has been defined in the OPC variable [" & m_OPC_XML_LCList.Name & "]")
                        End If
                        Set oLCList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadLCListString", _
                             "The content of the OPC variable [" & m_OPC_XML_LCList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadLCListString", _
                     "The OPC variable [" & m_OPC_XML_LCList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadLCListString", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_LCID
' Input:        [integer] index of LC ( from 0 to n )
' Output:       [String] LC ID for the index
' Description:  Returns the LC IDs of the index passed in parameters
'-------------------------------------------------------------------------------
Public Function Get_LCID(ByVal index As Integer) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_LCID", "Begin Property")
    
    Dim Res_txt As String
    
    Res_txt = ""
    If (index <= UBound(m_strLCIDs)) Then
        Res_txt = m_strLCIDs(index)
    End If

    Get_LCID = Res_txt
    
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_LCID", Err.Description)
End Function
'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_LCName
' Author:       Abhishek Patil
' Input:        [integer] index of LC ( from 0 to n )
' Output:       [String] LC Name for the index
' Description:  Returns the LC Names of the index passed in parameters
'-------------------------------------------------------------------------------
Public Function Get_LCName(ByVal index As Integer) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_LCName", "Begin Property")
    
    Dim Res_txt As String
    
    Res_txt = ""
    If (index <= UBound(m_strLCNames)) Then
        Res_txt = m_strLCNames(index)
    End If

    Get_LCName = Res_txt
    
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_LCName", Err.Description)
End Function
'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::m_OPC_XML_ConditionList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of parameters
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_ConditionList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_ConditionList_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_ConditionList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPC_XML_ConditionList_ValueChange", "The status of " & m_OPC_XML_ConditionList.Name & " is Waiting")
    ElseIf (m_OPC_XML_ConditionList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_ConditionList_ValueChange", "The status of " & m_OPC_XML_ConditionList.Name & " is Config Error")
    ElseIf (m_OPC_XML_ConditionList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_ConditionList_ValueChange", "The status of " & m_OPC_XML_ConditionList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_ConditionList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_ConditionList_ValueChange", "The Quality of " & m_OPC_XML_ConditionList.Name & " is not good")
    Else
    
        If (m_current_ConditionList <> m_OPC_XML_ConditionList.Value) Then
            m_current_ConditionList = m_OPC_XML_ConditionList.Value
            ' Read the string
             ReadXMLConditionListString
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_ConditionList_ValueChange", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::ReadXMLConditionListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of conditions
'-------------------------------------------------------------------------------
Private Sub ReadXMLConditionListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "ReadXMLConditionListString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oConditionList As IXMLDOMNodeList
   Dim oCondition As IXMLDOMElement

   Dim iCounter As Integer
   
   strXMLString = m_OPC_XML_ConditionList.Value
   
    ' Empty the data lists
    ReDim m_strConditionsNames(0)
    
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Condition"
                    Set oConditionList = oDoc.documentElement.getElementsByTagName(c_strWorkZoneConditionNode)
                    If Not (oConditionList Is Nothing) Then
                        If (oConditionList.length > 0) Then
                            ReDim m_strConditionsNames(oConditionList.length - 1)
                            ReDim m_strConditionsIDs(oConditionList.length - 1)
                            iCounter = 0
                            For Each oCondition In oConditionList
                                ' Name attribute
                                m_strConditionsIDs(iCounter) = oCondition.getAttribute(c_strWZCIDAttr)
                                m_strConditionsNames(iCounter) = Format(oCondition.getAttribute(c_strWZCNameAttr))
                                iCounter = iCounter + 1
                            Next oCondition
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLConditionListString", _
                                         "No Conditions has been defined in the OPC variable [" & m_OPC_XML_ConditionList.Name & "]")
                        End If
                        Set oConditionList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLConditionListString", _
                             "The content of the OPC variable [" & m_OPC_XML_ConditionList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLConditionListString", _
                     "The OPC variable [" & m_OPC_XML_ConditionList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLConditionListString", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_ConditionText
' Input:        [integer] index of Condition ( from 1 to 8 )
' Output:       [String] text associated with the condition
' Description:  Returns the text of the condition
'-------------------------------------------------------------------------------
Public Function Get_ConditionText(ByVal index As Integer) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_ConditionText", "Begin Property")
    
    Dim Res_txt As String
    Dim iCounter As Integer
    
    Res_txt = ""
    
    For iCounter = 0 To UBound(m_strConditionsIDs)
        If (Val(m_strConditionsIDs(iCounter)) = index) Then
            Res_txt = m_strConditionsNames(iCounter)
            iCounter = UBound(m_strConditionsIDs)
        End If
    Next iCounter
    
    Get_ConditionText = Res_txt
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_ConditionText", Err.Description)
End Function


'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::m_OPC_XML_CurrentWZlist_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of WorkZone definition
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_CurrentWZlist_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_CurrentWZlist_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_CurrentWZlist.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPC_XML_CurrentWZlist_ValueChange", "The status of " & m_OPC_XML_CurrentWZlist.Name & " is Waiting")
    ElseIf (m_OPC_XML_CurrentWZlist.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_CurrentWZlist_ValueChange", "The status of " & m_OPC_XML_CurrentWZlist.Name & " is Config Error")
    ElseIf (m_OPC_XML_CurrentWZlist.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_CurrentWZlist_ValueChange", "The status of " & m_OPC_XML_CurrentWZlist.Name & " is Not Connected")
    ElseIf (m_OPC_XML_CurrentWZlist.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_CurrentWZlist_ValueChange", "The Quality of " & m_OPC_XML_CurrentWZlist.Name & " is not good")
    Else
        If (m_current_CurrentWZlist <> m_OPC_XML_CurrentWZlist.Value) Then
            m_current_CurrentWZlist = m_OPC_XML_CurrentWZlist.Value
    
           ' Read the string
            ReadXMLWZsListString
        End If
    End If

    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_CurrentWZlist_ValueChange", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::m_OPC_XML_WZInSessionlist_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of WorkZone definition
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_WZInSessionlist_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_WZInSessionlist_ValueChange", "Begin Subroutine")

    'If (m_OPC_XML_WZInSessionlist.Status = fvVariableStatusWaiting) Then
    '    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPC_XML_WZInSessionlist_ValueChange", "The status of " & m_OPC_XML_WZInSessionlist.Name & " is Waiting")
    'ElseIf (m_OPC_XML_WZInSessionlist.Status = fvVariableStatusConfigError) Then
    '    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_WZInSessionlist_ValueChange", "The status of " & m_OPC_XML_WZInSessionlist.Name & " is Config Error")
    'ElseIf (m_OPC_XML_WZInSessionlist.Status = fvVariableStatusNotConnected) Then
    '    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_WZInSessionlist_ValueChange", "The status of " & m_OPC_XML_WZInSessionlist.Name & " is Not Connected")
    'Else
    If (m_OPC_XML_WZInSessionlist.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_WZInSessionlist_ValueChange", "The Quality of " & m_OPC_XML_WZInSessionlist.Name & " is not good")
    Else
        If (m_current_WZInSessionlist <> m_OPC_XML_WZInSessionlist.Value) Then
           m_current_WZInSessionlist = m_OPC_XML_WZInSessionlist.Value
           ' Read the string
            ReadXMLInSessionWZsListString
        End If
    End If

    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_WZInSessionlist_ValueChange", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::ReadXMLWZsListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of Workzones
'-------------------------------------------------------------------------------
Private Sub ReadXMLWZsListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "ReadXMLWZsListString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oWZList As IXMLDOMNodeList
   Dim oWZ As IXMLDOMElement
   
   Dim oBlockList As IXMLDOMNodeList
   Dim oBlock As IXMLDOMElement
   
   Dim str_Temp As String
   
   Dim iCounter As Integer
 
    strXMLString = m_OPC_XML_CurrentWZlist.Value
   
    ' Empty the data lists
    ReDim m_strWZIDs(0)
    ReDim m_strSpeedRestrictions(0)
    
    ReDim m_strCondition1(0)
    ReDim m_strCondition2(0)
    ReDim m_strCondition3(0)
    ReDim m_strCondition4(0)
    ReDim m_strCondition5(0)
    ReDim m_strCondition6(0)
    ReDim m_strCondition7(0)
    ReDim m_strCondition8(0)
    ReDim m_strBlocks(0)
        
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Condition"
                    Set oWZList = oDoc.documentElement.getElementsByTagName(c_strWorkZoneNode)
                    If Not (oWZList Is Nothing) Then
                        If (oWZList.length > 0) Then
                            ReDim m_strWZIDs(oWZList.length - 1)
                            ReDim m_strSpeedRestrictions(oWZList.length - 1)
                                
                            ReDim m_strCondition1(oWZList.length - 1)
                            ReDim m_strCondition2(oWZList.length - 1)
                            ReDim m_strCondition3(oWZList.length - 1)
                            ReDim m_strCondition4(oWZList.length - 1)
                            ReDim m_strCondition5(oWZList.length - 1)
                            ReDim m_strCondition6(oWZList.length - 1)
                            ReDim m_strCondition7(oWZList.length - 1)
                            ReDim m_strCondition8(oWZList.length - 1)
                            ReDim m_strBlocks(oWZList.length - 1)
                            
                            iCounter = 0
                            For Each oWZ In oWZList
                                ' read the attributes
                                m_strWZIDs(iCounter) = oWZ.getAttribute(c_strWZIDAttr)
                                m_strSpeedRestrictions(iCounter) = Format(oWZ.getAttribute(c_strWZSpeedAttr))
                                
                                m_strCondition1(iCounter) = Format(oWZ.getAttribute(c_strWZCond1Attr))
                                m_strCondition2(iCounter) = Format(oWZ.getAttribute(c_strWZCond2Attr))
                                m_strCondition3(iCounter) = Format(oWZ.getAttribute(c_strWZCond3Attr))
                                m_strCondition4(iCounter) = Format(oWZ.getAttribute(c_strWZCond4Attr))
                                m_strCondition5(iCounter) = Format(oWZ.getAttribute(c_strWZCond5Attr))
                                m_strCondition6(iCounter) = Format(oWZ.getAttribute(c_strWZCond6Attr))
                                m_strCondition7(iCounter) = Format(oWZ.getAttribute(c_strWZCond7Attr))
                                m_strCondition8(iCounter) = Format(oWZ.getAttribute(c_strWZCond8Attr))
                                
                                'read the block
                                Set oBlockList = oWZ.getElementsByTagName(c_strBlockNode)
                                m_strBlocks(iCounter) = ""
                                
                                For Each oBlock In oBlockList
                                    str_Temp = oBlock.getAttribute(c_strBlockIDAttr)
                                    
                                    If (str_Temp <> "") Then
                                        If (m_strBlocks(iCounter) <> "") Then
                                            m_strBlocks(iCounter) = m_strBlocks(iCounter) + ";" + str_Temp
                                        Else
                                            m_strBlocks(iCounter) = str_Temp
                                        End If
                                    End If
                                Next oBlock
                                iCounter = iCounter + 1
                            Next oWZ
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLWZsListString", _
                                         "No Workzone has been defined in the OPC variable [" & m_OPC_XML_CurrentWZlist.Name & "]")
                        End If
                        Set oWZList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLWZsListString", _
                             "The content of the OPC variable [" & m_OPC_XML_CurrentWZlist.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLWZsListString", _
                     "The OPC variable [" & m_OPC_XML_CurrentWZlist.Name & "] is empty")
    End If
       
    If Not (m_OPC_WZNotify Is Nothing) Then
        m_OPC_WZNotify.Value = True
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLWZsListString", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::ReadXMLInSessionWZsListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of Workzones
'-------------------------------------------------------------------------------
Private Sub ReadXMLInSessionWZsListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "ReadXMLInSessionWZsListString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oWZList As IXMLDOMNodeList
   Dim oWZ As IXMLDOMElement
   
   Dim oBlockList As IXMLDOMNodeList
   Dim oBlock As IXMLDOMElement
   
   Dim str_Temp As String
   Dim iCounter As Integer

    strXMLString = m_OPC_XML_WZInSessionlist.Value
    ' Empty the data lists
    ReDim m_strInSessionWZIDs(0)
    ReDim m_strInSessionSpeedRestrictions(0)

    ReDim m_strInSessionCondition1(0)
    ReDim m_strInSessionCondition2(0)
    ReDim m_strInSessionCondition3(0)
    ReDim m_strInSessionCondition4(0)
    ReDim m_strInSessionCondition5(0)
    ReDim m_strInSessionCondition6(0)
    ReDim m_strInSessionCondition7(0)
    ReDim m_strInSessionCondition8(0)
    ReDim m_strInSessionBlocks(0)
        
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Condition"
                    Set oWZList = oDoc.documentElement.getElementsByTagName(c_strWorkZoneNode)
                    If Not (oWZList Is Nothing) Then
                        If (oWZList.length > 0) Then
                    
                            ReDim m_strInSessionWZIDs(oWZList.length - 1)
                            ReDim m_strInSessionSpeedRestrictions(oWZList.length - 1)
                            
                            ReDim m_strInSessionCondition1(oWZList.length - 1)
                            ReDim m_strInSessionCondition2(oWZList.length - 1)
                            ReDim m_strInSessionCondition3(oWZList.length - 1)
                            ReDim m_strInSessionCondition4(oWZList.length - 1)
                            ReDim m_strInSessionCondition5(oWZList.length - 1)
                            ReDim m_strInSessionCondition6(oWZList.length - 1)
                            ReDim m_strInSessionCondition7(oWZList.length - 1)
                            ReDim m_strInSessionCondition8(oWZList.length - 1)
                            ReDim m_strInSessionBlocks(oWZList.length - 1)
                            iCounter = 0
                            For Each oWZ In oWZList
                                ' read the attributes
                                m_strInSessionWZIDs(iCounter) = oWZ.getAttribute(c_strWZIDAttr)
                                m_strInSessionSpeedRestrictions(iCounter) = Format(oWZ.getAttribute(c_strWZSpeedAttr))
                                
                                m_strInSessionCondition1(iCounter) = Format(oWZ.getAttribute(c_strWZCond1Attr))
                                m_strInSessionCondition2(iCounter) = Format(oWZ.getAttribute(c_strWZCond2Attr))
                                m_strInSessionCondition3(iCounter) = Format(oWZ.getAttribute(c_strWZCond3Attr))
                                m_strInSessionCondition4(iCounter) = Format(oWZ.getAttribute(c_strWZCond4Attr))
                                m_strInSessionCondition5(iCounter) = Format(oWZ.getAttribute(c_strWZCond5Attr))
                                m_strInSessionCondition6(iCounter) = Format(oWZ.getAttribute(c_strWZCond6Attr))
                                m_strInSessionCondition7(iCounter) = Format(oWZ.getAttribute(c_strWZCond7Attr))
                                m_strInSessionCondition8(iCounter) = Format(oWZ.getAttribute(c_strWZCond8Attr))
                                
                                'read the block
                                Set oBlockList = oWZ.getElementsByTagName(c_strBlockNode)
                                m_strInSessionBlocks(iCounter) = ""
                                For Each oBlock In oBlockList
                                    str_Temp = oBlock.getAttribute(c_strBlockIDAttr)
                                    
                                    If (str_Temp <> "") Then
                                        If (m_strInSessionBlocks(iCounter) <> "") Then
                                            m_strInSessionBlocks(iCounter) = m_strInSessionBlocks(iCounter) + ";" + str_Temp
                                        Else
                                            m_strInSessionBlocks(iCounter) = str_Temp
                                        End If
                                    End If
                                Next oBlock
                                iCounter = iCounter + 1
                            Next oWZ
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLInSessionWZsListString", _
                                         "No Workzone has been defined in the OPC variable [" & m_OPC_XML_WZInSessionlist.Name & "]")
                        End If
                        Set oWZList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLInSessionWZsListString", _
                             "The content of the OPC variable [" & m_OPC_XML_WZInSessionlist.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLInSessionWZsListString", _
                     "The OPC variable [" & m_OPC_XML_WZInSessionlist.Name & "] is empty")
    End If
       
    If Not (m_OPC_WZInSessionNotify Is Nothing) Then
        m_OPC_WZInSessionNotify.Value = True
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLWZsListString", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_WZSpeed
' Input:        [integer] ID of the workzone
' Output:       [String] text associated with the speedrestriction
' Description:  Returns the speed restriction of the workzone
'-------------------------------------------------------------------------------
Public Function Get_WZSpeed(ByVal WZID As Integer) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_WZSpeed", "Begin Property")
    
    Dim Res_txt As String
    Dim iCounter As Integer
    
    Res_txt = ""
    
    For iCounter = 0 To UBound(m_strWZIDs)
        If (Val(m_strWZIDs(iCounter)) = WZID) Then
            Res_txt = m_strSpeedRestrictions(iCounter)
            iCounter = UBound(m_strWZIDs)
        End If
    Next iCounter
    
    If (Val(Res_txt) = c_iNoRestrictionSpeed) Then
        Res_txt = "-"
    End If
    Get_WZSpeed = Res_txt
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_WZSpeed", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_WZcondition
' Input:        [integer] ID of the workzone
'               [integer] index of the condition
' Output:       [String] text associated with the speedrestriction
' Description:  Returns the text of the condition
'-------------------------------------------------------------------------------
Public Function Get_WZcondition(ByVal WZID As Integer, ByVal CondIndex As Integer) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_WZcondition", "Begin Property")
    
    Dim Res_value As Boolean
    Dim iCounter As Integer
    
    Res_value = False
    
    For iCounter = 0 To UBound(m_strWZIDs)
        If (Val(m_strWZIDs(iCounter)) = WZID) Then
            Select Case CondIndex
            Case 1
               Res_value = m_strCondition1(iCounter)
            Case 2
               Res_value = m_strCondition2(iCounter)
            Case 3
               Res_value = m_strCondition3(iCounter)
            Case 4
               Res_value = m_strCondition4(iCounter)
            Case 5
               Res_value = m_strCondition5(iCounter)
            Case 6
               Res_value = m_strCondition6(iCounter)
            Case 7
               Res_value = m_strCondition7(iCounter)
            Case 8
               Res_value = m_strCondition8(iCounter)
            Case Else
               Res_value = False
            End Select
            
            iCounter = UBound(m_strWZIDs)
        End If
    Next iCounter

    Get_WZcondition = Res_value
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_WZcondition", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_CurrentWZIDs ()
' Input:
' Output:       [String()]array of the WorkZone IDs for the current LC
' Description:  returns the current workzone IDs
'-------------------------------------------------------------------------------
Public Function Get_CurrentWZIDs() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_CurrentWZIDs", "Begin Property")
    
    Get_CurrentWZIDs = m_strWZIDs
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_CurrentWZIDs", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_WZInSessionSpeed
' Input:        [integer] ID of the workzone
' Output:       [String] text associated with the speedrestriction
' Description:  Returns the text of the speed restriction of the workzone in session
'-------------------------------------------------------------------------------
Public Function Get_WZInSessionSpeed(ByVal WZID As Integer) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_WZInSessionSpeed", "Begin Property")
    
    Dim Res_txt As String
    Dim iCounter As Integer
    
    Res_txt = ""
    
    For iCounter = 0 To UBound(m_strInSessionWZIDs)
        If (Val(m_strInSessionWZIDs(iCounter)) = WZID) Then
            Res_txt = m_strInSessionSpeedRestrictions(iCounter)
            iCounter = UBound(m_strInSessionWZIDs)
        End If
    Next iCounter
    
    If (Val(Res_txt) = c_iNoRestrictionSpeed) Then
        Res_txt = "-"
    End If
    Get_WZInSessionSpeed = Res_txt
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_WZInSessionSpeed", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_WZInSessioncondition
' Input:        [integer] ID of the workzone
'               [integer] index of the condition
' Output:       [String] text associated with the speedrestriction
' Description:  Returns the text of the condition
'-------------------------------------------------------------------------------
Public Function Get_WZInSessioncondition(ByVal WZID As Integer, ByVal CondIndex As Integer) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_WZInSessioncondition", "Begin Property")
    
    Dim Res_value As Boolean
    Dim iCounter As Integer
    
    Res_value = False
    
    For iCounter = 0 To UBound(m_strInSessionWZIDs)
        If (Val(m_strInSessionWZIDs(iCounter)) = WZID) Then
            Select Case CondIndex
            Case 1
               Res_value = m_strInSessionCondition1(iCounter)
            Case 2
               Res_value = m_strInSessionCondition2(iCounter)
            Case 3
               Res_value = m_strInSessionCondition3(iCounter)
            Case 4
               Res_value = m_strInSessionCondition4(iCounter)
            Case 5
               Res_value = m_strInSessionCondition5(iCounter)
            Case 6
               Res_value = m_strInSessionCondition6(iCounter)
            Case 7
               Res_value = m_strInSessionCondition7(iCounter)
            Case 8
               Res_value = m_strInSessionCondition8(iCounter)
            Case Else
               Res_value = False
            End Select
            
            iCounter = UBound(m_strInSessionWZIDs)
        End If
    Next iCounter

    Get_WZInSessioncondition = Res_value
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_WZInSessioncondition", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_CurrentInSessionWZIDs ()
' Input:
' Output:       [String()]array of the WorkZone IDs for the current LC
' Description:  returns the current workzone IDs
'-------------------------------------------------------------------------------
Public Function Get_CurrentInSessionWZIDs() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_CurrentInSessionWZIDs", "Begin Property")
    
    Get_CurrentInSessionWZIDs = m_strInSessionWZIDs
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_CurrentInSessionWZIDs", Err.Description)
End Function

'* Subroutine: m_OPC_TSRAppliedInit_ValueChange
'* Purpose: Manage the OPC variable containing the workzone presence
'* ************************************************************************************************
Private Sub m_OPC_TSRAppliedInit_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPC_TSRAppliedInit_ValueChange", "Begin Subroutine")
    
    '* Reset variable used in the animation of tab
    If (m_OPC_TSRAppliedInit.Status = fvVariableStatusWaiting) Then
        m_OPC_LCWZAppliedAnim.Value = 3 '* invalid value not in range
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPC_TSRAppliedInit_ValueChange", "The status of " & m_OPC_TSRAppliedInit.Name & " is Waiting")
    ElseIf (m_OPC_TSRAppliedInit.Status = fvVariableStatusConfigError) Then
        m_OPC_LCWZAppliedAnim.Value = 3 '* invalid value not in range
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_TSRAppliedInit_ValueChange", "The status of " & m_OPC_TSRAppliedInit.Name & " is Config Error")
    ElseIf (m_OPC_TSRAppliedInit.Status = fvVariableStatusNotConnected) Then
        m_OPC_LCWZAppliedAnim.Value = 3 '* invalid value not in range
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_TSRAppliedInit_ValueChange", "The status of " & m_OPC_TSRAppliedInit.Name & " is Not Connected")
    ElseIf (m_OPC_TSRAppliedInit.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_TSRAppliedInit_ValueChange", "The Quality of " & m_OPC_TSRAppliedInit.Name & " is not good")
        m_OPC_LCWZAppliedAnim.Value = 3 '* invalid value not in range
    Else
        m_OPC_LCWZAppliedAnim.Value = m_OPC_TSRAppliedInit.Value
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_TSRAppliedInit_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_CurrentBlockUEIDUsed ()
' Input:
' Output:       [String()]array of the Block UEIDs used by the workzone
' Description:  Returns the list of the block UEIDs by the current edited workzone
'-------------------------------------------------------------------------------
Public Function Get_CurrentBlockUEIDUsed() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_CurrentBlockUEIDUsed", "Begin Function")
    
    Dim iCounter As Integer
    Dim j As Integer
    Dim k As Integer
    Dim l_found As Boolean
    Dim l_first As Boolean
    
    Dim tmp_arr() As String
    Dim res_arr() As String
    l_first = True
    
    For iCounter = 0 To UBound(m_strBlocks)
        If (m_strBlocks(iCounter) <> "") Then
            tmp_arr = Split(m_strBlocks(iCounter), ";")
            
            For j = 0 To UBound(tmp_arr)
                l_found = False
                
                If (l_first) Then
                    ReDim res_arr(0)
                    res_arr(0) = tmp_arr(j)
                    l_first = False
                Else
                    For k = 0 To UBound(res_arr)
                        If (res_arr(k) = tmp_arr(j)) Then
                            l_found = True
                            k = UBound(res_arr)
                        End If
                    Next k
                
                    If (l_found = False) Then
                        ReDim Preserve res_arr(UBound(res_arr) + 1)
                        res_arr(UBound(res_arr)) = tmp_arr(j)
                    End If
                End If
            Next j
        End If
    Next iCounter
    
    Get_CurrentBlockUEIDUsed = res_arr
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_CurrentBlockUEIDUsed", Err.Description)
End Function



'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_CurrentBlockInSessionUEIDUsed ()
' Input:
' Output:       [String()]array of the Block UEIDs used by the workzone
' Description:  Returns the list of block UEID used in session
'-------------------------------------------------------------------------------
Public Function Get_CurrentBlockInSessionUEIDUsed() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_CurrentBlockInSessionUEIDUsed", "Begin Function")
    
    Dim iCounter As Integer
    Dim j As Integer
    Dim k As Integer
    Dim l_found As Boolean
    Dim l_first As Boolean
    
    Dim tmp_arr() As String
    Dim res_arr() As String
    l_first = True
    
    For iCounter = 0 To UBound(m_strInSessionBlocks)
        If (m_strInSessionBlocks(iCounter) <> "") Then
            tmp_arr = Split(m_strInSessionBlocks(iCounter), ";")
            
            For j = 0 To UBound(tmp_arr)
                l_found = False
                
                If (l_first) Then
                    ReDim res_arr(0)
                    res_arr(0) = tmp_arr(j)
                    l_first = False
                Else
                    For k = 0 To UBound(res_arr)
                        If (res_arr(k) = tmp_arr(j)) Then
                            l_found = True
                            k = UBound(res_arr)
                        End If
                    Next k
                
                    If (l_found = False) Then
                        ReDim Preserve res_arr(UBound(res_arr) + 1)
                        res_arr(UBound(res_arr)) = tmp_arr(j)
                    End If
                End If
            Next j
        End If
    Next iCounter
    
    Get_CurrentBlockInSessionUEIDUsed = res_arr
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_CurrentBlockInSessionUEIDUsed", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_BlockID (String BlockUEID)
' Input:        [string] block UEID
' Output:       [String] block ID
' Description:  Returns the current block ID
'-------------------------------------------------------------------------------
Public Function Get_BlockID(ByVal BlockUEID As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_BlockID", "Begin Function")
    
    Dim iCounter As Integer
    Dim index As Integer
    
    index = 0
    
    For iCounter = 0 To UBound(m_strBlockID)
        If (m_strBlockUEID(iCounter) = BlockUEID) Then
            index = iCounter
            iCounter = UBound(m_strBlockID)
        End If
    Next iCounter
    
    Get_BlockID = m_strBlockID(index)
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_BlockID", Err.Description)
End Function


'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::m_OPC_XML_BlockList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of block definitions
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_BlockList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_BlockList_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_BlockList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPC_XML_BlockList_ValueChange", "The status of " & m_OPC_XML_BlockList.Name & " is Waiting")
    ElseIf (m_OPC_XML_BlockList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_BlockList_ValueChange", "The status of " & m_OPC_XML_BlockList.Name & " is Config Error")
    ElseIf (m_OPC_XML_BlockList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_BlockList_ValueChange", "The status of " & m_OPC_XML_BlockList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_BlockList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_BlockList_ValueChange", "The Quality of " & m_OPC_XML_BlockList.Name & " is not good")
    Else
        If (m_current_BlockList <> m_OPC_XML_BlockList.Value) Then
            m_current_BlockList = m_OPC_XML_BlockList.Value
            ' Read the string
            ReadXMLBlocksListString
        End If
        
    End If

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_BlockList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::ReadXMLBlocksListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of blocks
'-------------------------------------------------------------------------------
Private Sub ReadXMLBlocksListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "ReadXMLBlocksListString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oBlockList As IXMLDOMNodeList
   Dim oBlock As IXMLDOMElement
   Dim VarUEID As Variable
   Dim strUEID As String
   
   Dim iCounter As Integer

   Set VarUEID = Nothing
   
   strXMLString = m_OPC_XML_BlockList.Value
   
    ' Empty the data lists
    ReDim m_strBlockID(0)
    ReDim m_strBlockUEID(0)
    
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Condition"
                    Set oBlockList = oDoc.documentElement.getElementsByTagName(c_strBlockIDNode)
                    If Not (oBlockList Is Nothing) Then
                        If (oBlockList.length > 0) Then
                            ReDim m_strBlockID(oBlockList.length - 1)
                            ReDim m_strBlockUEID(oBlockList.length - 1)
                            
                            If Not (m_OPCSet_BlockUEID Is Nothing) Then
                                m_OPCSet_BlockUEID.Destroy
                                Set m_OPCSet_BlockUEID = Nothing
                            End If
                            
                            Set m_OPCSet_BlockUEID = Iconis_MOD_General.CreateNew_Iconis_CLS_OPCSet
                            iCounter = 0
                            For Each oBlock In oBlockList
                                ' read the attributes
                                m_strBlockID(iCounter) = oBlock.getAttribute(c_strBlockIDAttr)
                                
                                ' add to the OPCSet to read the UEID
                                m_OPCSet_BlockUEID.AddItem Iconis_MOD_General.GetOPCCluster & m_strBlockID(iCounter) & c_strBlockUEIDTag, fvVariableTypeText, c_OPCReadAll
                                iCounter = iCounter + 1
                            Next oBlock
                            
                            m_OPCSet_BlockUEID.DoConnect "Block UIED List"

                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLBlocksListString", _
                                         "No Blocks has been defined in the OPC variable [" & m_OPC_XML_BlockList.Name & "]")
                        End If
                        Set oBlockList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLBlocksListString", _
                             "The content of the OPC variable [" & m_OPC_XML_BlockList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLBlocksListString", _
                     "The OPC variable [" & m_OPC_XML_BlockList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLWZsListString", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::m_OPC_XML_SpeedList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of speed definitions
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_SpeedList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_SpeedList_ValueChange", "Begin Subroutine")
   
    If (m_OPC_XML_SpeedList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPC_XML_SpeedList_ValueChange", "The status of " & m_OPC_XML_SpeedList.Name & " is Waiting")
    ElseIf (m_OPC_XML_SpeedList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_SpeedList_ValueChange", "The status of " & m_OPC_XML_SpeedList.Name & " is Config Error")
    ElseIf (m_OPC_XML_SpeedList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_SpeedList_ValueChange", "The status of " & m_OPC_XML_SpeedList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_SpeedList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPC_XML_SpeedList_ValueChange", "The Quality of " & m_OPC_XML_SpeedList.Name & " is not good")
    Else
        If (m_current_SpeedList <> m_OPC_XML_SpeedList.Value) Then
            m_current_SpeedList = m_OPC_XML_SpeedList.Value
            ' Read the string
             ReadXMLSpeedListString
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPC_XML_SpeedList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::ReadXMLSpeedListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of speed restriction for the LC
'-------------------------------------------------------------------------------
Private Sub ReadXMLSpeedListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "ReadXMLSpeedListString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oSpeedList As IXMLDOMNodeList
   Dim oSpeed As IXMLDOMElement
   
   Dim iCounter As Integer
   
   strXMLString = m_OPC_XML_SpeedList.Value
  
   ' Empty the data lists
   ReDim m_strAvailableSpeedArray(0)
   'create the no restriction speed
   m_strAvailableSpeedArray(0) = c_strSpeedNoRestriction
    
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "speed"
                    Set oSpeedList = oDoc.documentElement.getElementsByTagName(c_strSpeedNode)
                    If Not (oSpeedList Is Nothing) Then
                        If (oSpeedList.length > 0) Then
                            ReDim Preserve m_strAvailableSpeedArray(oSpeedList.length)
                            
                            iCounter = 1
                            For Each oSpeed In oSpeedList
                                ' read the attributes
                                m_strAvailableSpeedArray(iCounter) = oSpeed.getAttribute(c_strSpeedIDAttr)
                                iCounter = iCounter + 1
                            Next oSpeed
                            
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLSpeedListString", _
                                         "No Speed restriction has been defined in the OPC variable [" & m_OPC_XML_SpeedList.Name & "]")
                        End If
                        Set oSpeedList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLSpeedListString", _
                             "The content of the OPC variable [" & m_OPC_XML_SpeedList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLSpeedListString", _
                     "The OPC variable [" & m_OPC_XML_SpeedList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadXMLSpeedListString", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_SpeedRestrictionList
' Input:        -
' Output:       [String()] array of speed restrictions list
' Description:  Returns the list of speed restrictions for the current LC
'-------------------------------------------------------------------------------
Public Function Get_SpeedRestrictionList() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_SpeedRestrictionList", "Begin Function")
    
    Get_SpeedRestrictionList = m_strAvailableSpeedArray
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_SpeedRestrictionList", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::ReadWZBoundaryData
' Input:        none
' Output:       none
' Description:  Read the Destination workzone bounaries for each source Workzone and
'               the list  containing the list of workzone boundary for the LC
'-------------------------------------------------------------------------------
Public Sub ReadWZBoundaryData()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "ReadWZBoundaryData", "Begin Subroutine")
    
    Dim strXMLString As String
    Dim oDoc As DOMDocument
    Dim oBoundaryList As IXMLDOMNodeList
    Dim oBoundary As IXMLDOMElement
    Dim oBoundaryDestination As IXMLDOMElement
    
    Dim strDestination As String
   
    Dim iCounter As Integer
    Dim WzPrepDestinationList As Variable
    Dim strQuerry As String
    Dim sBoundaryListItem As Variable
    
    ReDim m_BoundariesList(UBound(m_strWorkzoneBoundaryslist) + 1)
    ' Empty the data lists of boundaries array
    iCounter = 0
    For iWzBoundaryListItem = 0 To UBound(m_strWorkzoneBoundaryslist)
        
        If Not IsNull(m_strWorkzoneBoundaryslist(iCounter)) Then
            strQuerry = Iconis_MOD_General.GetOPCCluster & m_strWorkzoneBoundarysAliaslist(iWzBoundaryListItem) & c_strPrepDestinationBoundaryList
            Set WzPrepDestinationList = Variables.Add(Iconis_MOD_General.GetOPCCluster & m_strWorkzoneBoundarysAliaslist(iWzBoundaryListItem) & c_strPrepDestinationBoundaryList, fvVariableTypeText)
            'DDb
            strQuerry = Iconis_MOD_General.GetOPCCluster & m_strWorkzoneBoundarysAliaslist(iWzBoundaryListItem) & c_strBoundaryUEIDTag
            Set sBoundaryListItem = Variables.Add(Iconis_MOD_General.GetOPCCluster & m_strWorkzoneBoundarysAliaslist(iWzBoundaryListItem) & c_strBoundaryUEIDTag, fvVariableTypeText)
            'DDe
            If Check_OPC_Variable(WzPrepDestinationList) Then
                strXMLString = WzPrepDestinationList.Value
                
                If (strXMLString <> "") Then
                
            '        strQuerry = Iconis_MOD_General.GetOPCCluster & m_strWorkzoneBoundaryslist(iWzBoundaryListItem) & c_strBoundaryUEIDTag
                    
             '       Set sBoundaryListItem = Variables.Add(Iconis_MOD_General.GetOPCCluster & m_strWorkzoneBoundaryslist(iWzBoundaryListItem) & c_strBoundaryUEIDTag, fvVariableTypeText)
                    iCounter = iCounter + 1
                    m_BoundariesList(iCounter).strID = m_strWorkzoneBoundarysAliaslist(iWzBoundaryListItem)
                    
                    ' Check the Quality of the OPC Plug
                 
                    If Check_OPC_Variable(sBoundaryListItem) Then
                        m_BoundariesList(iCounter).strUEID = sBoundaryListItem.Value
                    End If
                    m_BoundariesList(iCounter).strName = m_strWorkzoneBoundarysAliaslist(iWzBoundaryListItem)
                    m_BoundariesList(iCounter).strBlock = ""
                    m_BoundariesList(iCounter).strAliasName = m_strWorkzoneBoundarysAliaslist(iWzBoundaryListItem)
                    strDestination = ""
                    Set oDoc = New DOMDocument
                    If Not (oDoc Is Nothing) Then
                    ' Load the XML document from the specified string from prepration destination boundary list
                        If (oDoc.loadXML(strXMLString) = True) Then
                            If Not (oDoc.documentElement Is Nothing) Then
                                Set oBoundaryList = oDoc.documentElement.getElementsByTagName(c_strWZDestinationNode)
                                For Each oBoundaryDestination In oBoundaryList
                                    If (strDestination = "") Then
                                        strDestination = oBoundaryDestination.getAttribute(c_strBoundaryUEIDAttr)
                                    Else
                                        strDestination = strDestination + ";" + oBoundaryDestination.getAttribute(c_strBoundaryUEIDAttr)
                                    End If
                                Next oBoundaryDestination ' next destnation boundary
                                m_BoundariesList(iCounter).strDestination = strDestination
                            End If
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadWZBoundaryData", _
                                 "The content of the OPC variable [" & strQuerry & "] has not been loaded")
                        End If
                    End If
                Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadWZBoundaryData", _
                                 "The content of the OPC variable [" & c_strPrepDestinationBoundaryList & "] has not been loaded")
                End If
            End If
        End If
    Next iWzBoundaryListItem
    Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "ReadWZBoundaryData", Err.Description)
End Sub
'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_BoundaryDescriptions
' Input:        -
' Output:       [BoundaryDescription()] array of boundary descriptions
' Description:  Returns the list of boundaries definitions for the current LC
'-------------------------------------------------------------------------------
Public Function Get_BoundaryDescriptions() As BoundaryDescription()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_BoundaryDescriptions", "Begin Function")
    
    Get_BoundaryDescriptions = m_BoundariesList
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_BoundaryDescriptions", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_BoundaryDescription
' Input:        [String] UEID of the boundary searched
' Output:       [BoundaryDescription] boundary descriptions for the UEID
' Description:  Returns the boundaries definition corresponding to the UEID in parameter
'-------------------------------------------------------------------------------
Public Function Get_BoundaryDescription(ByVal UEID As String) As BoundaryDescription
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_BoundaryDescription", "Begin Function")
    
    Dim iCounter As Integer
    Dim BDesc As BoundaryDescription
    
    BDesc.strUEID = "-1"

    For iCounter = 0 To UBound(m_BoundariesList)
        
        If (m_BoundariesList(iCounter).strUEID = UEID) Then
            BDesc = m_BoundariesList(iCounter)
            Exit For
        End If
    Next iCounter
    Get_BoundaryDescription = BDesc
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_BoundaryDescription", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_BoundaryDescriptionFromName
' Input:        [String] UEID of the boundary searched
' Output:       [BoundaryDescription] boundary descriptions for the UEID
' Description:  Returns the boundaries definition corresponding to the UEID in parameter
'-------------------------------------------------------------------------------
Public Function Get_BoundaryDescriptionFromName(ByVal Name As String) As BoundaryDescription
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_BoundaryDescriptionFromName", "Begin Function")
    
    Dim iCounter As Integer
    Dim BDesc As BoundaryDescription
    
    BDesc.strUEID = "-1"
    
    For iCounter = 0 To UBound(m_BoundariesList)
        
        If (m_BoundariesList(iCounter).strName = Name) Then
            BDesc = m_BoundariesList(iCounter)
            Exit For
        End If
    Next iCounter
    Get_BoundaryDescriptionFromName = BDesc
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_BoundaryDescriptionFromName", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::Get_BoundaryDescriptionFromAliasName
' Input:        [String] AliasName of the boundary searched
' Output:       [BoundaryDescription] boundary descriptions for the AliasName
' Description:  Returns the boundaries definition corresponding to the AliasName in parameter
'-------------------------------------------------------------------------------
Public Function Get_BoundaryDescriptionFromAliasName(ByVal Name As String) As BoundaryDescription
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "Get_BoundaryDescriptionFromAliasName", "Begin Function")
    
    Dim iCounter As Integer
    Dim BDesc As BoundaryDescription
    
    BDesc.strUEID = "-1"
    
    For iCounter = 0 To UBound(m_BoundariesList)
        
        If (m_BoundariesList(iCounter).strAliasName = Name) Then
            BDesc = m_BoundariesList(iCounter)
            Exit For
        End If
    Next iCounter
    Get_BoundaryDescriptionFromAliasName = BDesc
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "Get_BoundaryDescriptionFromAliasName", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_WorkZones::m_OPCSet_BlockUEID_OnConnection
' Input:        [Variant] arrValue : array of UEID of the block
' Output:       [fvVariableStatus]arrStatus :  array of status of the UEID
' Description:  manage the connection on the OPCset associated to the list of block UEID
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_BlockUEID_OnConnection(arrValue() As Variant, arrStatus() As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPCSet_BlockUEID_OnConnection", "Begin Function")

    Dim strUEID As String
    Dim iCounter As Long
    
    For iCounter = 0 To UBound(arrValue)
        strUEID = ""
        
        If (arrStatus(iCounter) = fvVariableStatusWaiting) Then
            Call CBTrace(CBTRACE_VBA, "Iconis_CLS_WorkZones", "m_OPCSet_BlockUEID_OnConnection", "The status of " & m_OPCSet_BlockUEID.Item(iCounter).strPath & " is Waiting")
        ElseIf (arrStatus(iCounter) = fvVariableStatusConfigError) Then
            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPCSet_BlockUEID_OnConnection", "The status of " & m_OPCSet_BlockUEID.Item(iCounter).strPath & " is Config Error")
        ElseIf (arrStatus(iCounter) = fvVariableStatusNotConnected) Then
            Call CBTrace(CBTRACE_VAR, "Iconis_CLS_WorkZones", "m_OPCSet_BlockUEID_OnConnection", "The status of " & m_OPCSet_BlockUEID.Item(iCounter).strPath & " is Not Connected")
        Else
            strUEID = arrValue(iCounter)
        End If
        
        m_strBlockUEID(iCounter) = strUEID

    Next iCounter
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_WorkZones", "m_OPCSet_BlockUEID_OnConnection", Err.Description)
End Sub
