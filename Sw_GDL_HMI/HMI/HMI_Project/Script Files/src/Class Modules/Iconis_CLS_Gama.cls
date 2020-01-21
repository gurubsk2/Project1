VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Iconis_CLS_Gama"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2013. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Class:       Iconis_CLS_Gama
'* *******************************************************************************************
'* Purpose: Manages the definitions used for Gama - provides function to read the Gama list
'*          from Fixed block
'* *******************************************************************************************
'* Modification History:
'* Author:              Eric FOISSEY
'* Date:                February '14
'* Change:              Copied from Shared Library

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION
'* *******************************************************************************************

Option Explicit

'* Type
'* ------------------------------------------------------

'* Type to describe one block
Private Type BlockDescription
    ' ID
    strID As String
    ' KpBegin
    lKpBegin As Long
    ' KpEnd
    lKpEnd As Long
End Type

'* Type to describe one elementary gama
Private Type EGamaDescription
    ' ID
    strID As String
    ' Name
    strName As String
    ' KpBegin
    StrKpBegin As String
    ' KpEnd
    StrKpEnd As String
    ' index
    startIndex As Long
End Type

' Constants
' ------------------------------------------------------

'used to read the block list and the gama list associated
Private Const c_strAnimationGamaZoneTag As String = ".GAMAZone%"
Private Const c_strAnimationESAZoneTag As String = ".ESAZone%"

Private Const c_strBlockGamaZoneTag As String = ".GAMAZone.Value"
Private Const c_strBlockESAZoneTag As String = ".ESAZone.Value"

Private Const c_strESAStatusTag As String = ".ESAStatus.Value"

Private Const c_strEGamaStatusTag As String = ".EGAMAStatus.Value"
Private Const c_strEGamaTrackStatusTag As String = ".EGAMATrackStatus.Value"

Private Const c_strBlockListTag As String = "IconisHMI.FixedBlocksList.Information.Value"
Private Const c_strBlockIDNode As String = "FixedBlock"
Private Const c_strElementaryGamaNode As String = "ElementaryGama"
'Private Const c_strTZElementaryGamaNode As String = "ElementaryGama"
Private Const c_strElementaryESANode As String = "ElementaryESA"

'used to read the gama list and the block list associated
Private Const c_strGamaListTag As String = "IconisHMI.GAMAsList.Information.Value"
Private Const c_strGamaNode As String = "GAMA"
Private Const c_strBlockNode As String = "Block"

'used to read the attribute
Private Const c_strBlockIDAttr As String = "ID"
Private Const c_strGamaIDAttr As String = "ID"
Private Const c_strGamaNameAttr As String = "Name"

Private Const c_strKPBeginAttr As String = "KPBegin"
Private Const c_strKPEndAttr As String = "KPEnd"


Private Const c_strGamaSeparator As String = ";"

Private Const c_iColorGamaInvalid = 7
Private Const c_iColorGamaRed = 0
Private Const c_iColorGamaInvisible = 1

Private Const c_iColorESAInvalid = 7
Private Const c_iColorESAActive = 1
Private Const c_iColorESAInactive = 0

Private Const c_iGrantedPermissive = 1
Private Const c_iRemovedRestrictive = 0

Private Const c_iActive = 0
Private Const c_iInactive = 1

' Class attributes
' ------------------------------------------------------
'gama list read according the block
Private m_BlocksDesc() As BlockDescription
Private m_EGamasDesc() As EGamaDescription
Private m_ESADesc() As EGamaDescription

'Block list read according the gama
Private m_strGamaID() As String
Private m_strGamaName() As String
Private m_strBlockList() As String

Private m_GamaPresence As Boolean

Private m_CurrentFixedBlockDesc As String

' Local OPC variables
' ------------------------------------------------------

' OPC server's variables
' ------------------------------------------------------
' OPC variable containing the list of the fixed block
Private WithEvents m_OPC_XML_BlockList As Variable
Attribute m_OPC_XML_BlockList.VB_VarHelpID = -1
' OPC variable containing the list of the gama
Private WithEvents m_OPC_XML_GamaList As Variable
Attribute m_OPC_XML_GamaList.VB_VarHelpID = -1

' OPC Set containing the list of block GamaZone for old animation
Private WithEvents m_OPCSet_BlockData As Iconis_CLS_OPCSet
Attribute m_OPCSet_BlockData.VB_VarHelpID = -1

' OPC Set containing the list of elementary gama status variables for new animation
Private WithEvents m_OPCSet_EGAMAData As Iconis_CLS_OPCSet
Attribute m_OPCSet_EGAMAData.VB_VarHelpID = -1

' OPC Set containing the list of block ESAZone for old animation
Private WithEvents m_OPCSet_BlockESA_old As Iconis_CLS_OPCSet
Attribute m_OPCSet_BlockESA_old.VB_VarHelpID = -1

' OPC Set containing the list of elementary ESA status variables for new animation
Private WithEvents m_OPCSet_BlockESA_new As Iconis_CLS_OPCSet
Attribute m_OPCSet_BlockESA_new.VB_VarHelpID = -1
'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Class_Initialize
' Input:        none
' Output:       none
' Description:  Init variables, create dictionnaries
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Class_Initialize", "Begin Subroutine")
    
    m_CurrentFixedBlockDesc = ""
    m_GamaPresence = True
    
    ReDim m_BlocksDesc(0)
    ReDim m_EGamasDesc(0)
    ReDim m_ESADesc(0)
    
    Set m_OPCSet_BlockData = Nothing
    Set m_OPCSet_EGAMAData = Nothing
    Set m_OPCSet_BlockESA_old = Nothing
    Set m_OPCSet_BlockESA_new = Nothing
    
    ' Add OPC variable containing the list of blocks
    Set m_OPC_XML_BlockList = Variables.Add(MOD_Deployment.CBTCLevel1Cluster & c_strBlockListTag, fvVariableTypeText)
    If (m_OPC_XML_BlockList.EnableEvents = True) Then
        m_OPC_XML_BlockList_ValueChange
    Else
        m_OPC_XML_BlockList.EnableEvents = True
    End If
    
    ' Add OPC variable containing the list of blocks
    Set m_OPC_XML_GamaList = Variables.Add(MOD_Deployment.CBTCLevel1Cluster & c_strGamaListTag, fvVariableTypeText)
    If (m_OPC_XML_GamaList.EnableEvents = True) Then
        m_OPC_XML_GamaList_ValueChange
    Else
        m_OPC_XML_GamaList.EnableEvents = True
    End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Class_Initialize", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Class_Terminate
' Input:        none
' Output:       none
' Description:  Object destructor
'-------------------------------------------------------------------------------
Private Sub Class_Terminate()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Class_Terminate", "Begin Subroutine")
    
    ' Empty the data lists
    ReDim m_BlocksDesc(0)
    ReDim m_EGamasDesc(0)
    ReDim m_ESADesc(0)
    
    ' Empty the data lists
    ReDim m_strGamaID(0)
    ReDim m_strBlockList(0)
    ReDim m_strGamaName(0)
    
    If Not (m_OPCSet_BlockData Is Nothing) Then
        m_OPCSet_BlockData.Destroy
        Set m_OPCSet_BlockData = Nothing
    End If
    
    If Not (m_OPCSet_EGAMAData Is Nothing) Then
        m_OPCSet_EGAMAData.Destroy
        Set m_OPCSet_EGAMAData = Nothing
    End If
    
    If Not (m_OPCSet_BlockESA_old Is Nothing) Then
        m_OPCSet_BlockESA_old.Destroy
        Set m_OPCSet_BlockESA_old = Nothing
    End If
    
    If Not (m_OPCSet_BlockESA_new Is Nothing) Then
        m_OPCSet_BlockESA_new.Destroy
        Set m_OPCSet_BlockESA_new = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_BlockList Is Nothing) Then
        Variables.Remove (m_OPC_XML_BlockList.Name)
        Set m_OPC_XML_BlockList = Nothing
    End If
    
    ' Unsubscribe the variable previously subscribed
    If Not (m_OPC_XML_GamaList Is Nothing) Then
        Variables.Remove (m_OPC_XML_GamaList.Name)
        Set m_OPC_XML_GamaList = Nothing
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Class_Terminate", Err.Description)
End Sub

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPC_XML_BlockList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of block definitions
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_BlockList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Gama", "m_OPC_XML_BlockList_ValueChange", "Begin Subroutine")
    
    If (m_OPC_XML_BlockList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPC_XML_BlockList_ValueChange", "The status of " & m_OPC_XML_BlockList.Name & " is Waiting")
    ElseIf (m_OPC_XML_BlockList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPC_XML_BlockList_ValueChange", "The status of " & m_OPC_XML_BlockList.Name & " is Config Error")
    ElseIf (m_OPC_XML_BlockList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Gama", "m_OPC_XML_BlockList_ValueChange", "The status of " & m_OPC_XML_BlockList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_BlockList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Gama", "m_OPC_XML_BlockList_ValueChange", "The Quality of " & m_OPC_XML_BlockList.Name & " is not good")
    Else
   
       ' Read the string
        ReadXMLBlocksListString
        
        If (m_CurrentFixedBlockDesc <> m_OPC_XML_BlockList.Value) Then
            m_CurrentFixedBlockDesc = m_OPC_XML_BlockList.Value
            StartBlockAnimation
        End If
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPC_XML_BlockList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::ReadXMLBlocksListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of blocks
'-------------------------------------------------------------------------------
Private Sub ReadXMLBlocksListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "ReadXMLBlocksListString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oBlockList As IXMLDOMNodeList
   Dim oBlock As IXMLDOMElement
   Dim oGamaList As IXMLDOMNodeList
   Dim oGama As IXMLDOMElement
   Dim oAttr As IXMLDOMAttribute
   
   Dim oESAList As IXMLDOMNodeList
   Dim oESA As IXMLDOMElement
   
   Dim str_Temp As String
   
   Dim I As Integer
   Dim j As Integer
   Dim k As Integer
   
   strXMLString = m_OPC_XML_BlockList.Value
   
    ' Empty the data lists
    ReDim m_BlocksDesc(0)
    ReDim m_EGamasDesc(0)
    ReDim m_ESADesc(0)
    
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
                            ReDim m_BlocksDesc(oBlockList.length - 1)
                            ReDim m_EGamasDesc(oBlockList.length - 1)
                            ReDim m_ESADesc(oBlockList.length - 1)
                            I = 0
                            j = 0
                            k = 0
                            
                            For Each oBlock In oBlockList
                                ' read the attributes
                                m_BlocksDesc(I).strID = oBlock.getAttribute(c_strBlockIDAttr)
                                Set oAttr = oBlock.getAttributeNode(c_strKPBeginAttr)
                                
                                If (oAttr Is Nothing) Then
                                    m_BlocksDesc(I).lKpBegin = 0
                                Else
                                    m_BlocksDesc(I).lKpBegin = oAttr.Value
                                End If
                                
                                Set oAttr = oBlock.getAttributeNode(c_strKPEndAttr)
                                
                                If (oAttr Is Nothing) Then
                                    m_BlocksDesc(I).lKpEnd = 0
                                Else
                                    m_BlocksDesc(I).lKpEnd = oAttr.Value
                                End If
                                
                                Set oGamaList = oBlock.getElementsByTagName(c_strElementaryGamaNode)
                                m_EGamasDesc(I).strID = ""
                                m_EGamasDesc(I).strName = ""
                                m_EGamasDesc(I).StrKpBegin = ""
                                m_EGamasDesc(I).StrKpEnd = ""
                                m_EGamasDesc(I).startIndex = j
                                If Not (oGamaList Is Nothing) Then
                                    For Each oGama In oGamaList
                                        j = j + 1
                                        ' read the attributes
                                        str_Temp = oGama.getAttribute(c_strGamaIDAttr)
                                        
                                        If (str_Temp <> "") Then
                                            If (m_EGamasDesc(I).strID = "") Then
                                                m_EGamasDesc(I).strID = str_Temp
                                            Else
                                                m_EGamasDesc(I).strID = m_EGamasDesc(I).strID + c_strGamaSeparator + str_Temp
                                            End If
                                        End If
                                        
                                        str_Temp = oGama.getAttribute(c_strGamaNameAttr)
                                        
                                        If (str_Temp <> "") Then
                                            If (m_EGamasDesc(I).strName = "") Then
                                                m_EGamasDesc(I).strName = str_Temp
                                            Else
                                                m_EGamasDesc(I).strName = m_EGamasDesc(I).strName + c_strGamaSeparator + str_Temp
                                            End If
                                        End If
                                        
                                        Set oAttr = oGama.getAttributeNode(c_strKPBeginAttr)
                                        If (oAttr Is Nothing) Then
                                            If (m_EGamasDesc(I).StrKpBegin = "") Then
                                                m_EGamasDesc(I).StrKpBegin = "0"
                                            Else
                                                m_EGamasDesc(I).StrKpBegin = m_EGamasDesc(I).StrKpBegin + c_strGamaSeparator + "0"
                                            End If
                                        Else
                                            If (m_EGamasDesc(I).StrKpBegin = "") Then
                                                m_EGamasDesc(I).StrKpBegin = oAttr.Value
                                            Else
                                                m_EGamasDesc(I).StrKpBegin = m_EGamasDesc(I).StrKpBegin + c_strGamaSeparator + oAttr.Value
                                            End If
                                        End If
                                                                            
                                        Set oAttr = oGama.getAttributeNode(c_strKPEndAttr)
                                        If (oAttr Is Nothing) Then
                                            If (m_EGamasDesc(I).StrKpEnd = "") Then
                                                m_EGamasDesc(I).StrKpEnd = "0"
                                            Else
                                                m_EGamasDesc(I).StrKpEnd = m_EGamasDesc(I).StrKpEnd + c_strGamaSeparator + "0"
                                            End If
                                        Else
                                            If (m_EGamasDesc(I).StrKpEnd = "") Then
                                                m_EGamasDesc(I).StrKpEnd = oAttr.Value
                                            Else
                                                m_EGamasDesc(I).StrKpEnd = m_EGamasDesc(I).StrKpEnd + c_strGamaSeparator + oAttr.Value
                                            End If
                                        End If
                                        
                                    Next oGama
                                End If
                                Set oGamaList = Nothing
                                
                                Set oESAList = oBlock.getElementsByTagName(c_strElementaryESANode)
                                m_ESADesc(I).strID = ""
                                m_ESADesc(I).strName = ""
                                m_ESADesc(I).StrKpBegin = ""
                                m_ESADesc(I).StrKpEnd = ""
                                m_ESADesc(I).startIndex = k
                                If Not (oESAList Is Nothing) Then
                                    For Each oESA In oESAList
                                        k = k + 1
                                        ' read the attributes
                                        str_Temp = oESA.getAttribute(c_strGamaIDAttr)
                                        
                                        If (str_Temp <> "") Then
                                            If (m_ESADesc(I).strID = "") Then
                                                m_ESADesc(I).strID = str_Temp
                                            Else
                                                m_ESADesc(I).strID = m_ESADesc(I).strID + c_strGamaSeparator + str_Temp
                                            End If
                                        End If
                                        
                                        str_Temp = oESA.getAttribute(c_strGamaNameAttr)
                                        
                                        If (str_Temp <> "") Then
                                            If (m_ESADesc(I).strName = "") Then
                                                m_ESADesc(I).strName = str_Temp
                                            Else
                                                m_ESADesc(I).strName = m_ESADesc(I).strName + c_strGamaSeparator + str_Temp
                                            End If
                                        End If
                                        
                                        Set oAttr = oESA.getAttributeNode(c_strKPBeginAttr)
                                        If (oAttr Is Nothing) Then
                                            If (m_ESADesc(I).StrKpBegin = "") Then
                                                m_ESADesc(I).StrKpBegin = "0"
                                            Else
                                                m_ESADesc(I).StrKpBegin = m_ESADesc(I).StrKpBegin + c_strGamaSeparator + "0"
                                            End If
                                        Else
                                            If (m_ESADesc(I).StrKpBegin = "") Then
                                                m_ESADesc(I).StrKpBegin = oAttr.Value
                                            Else
                                                m_ESADesc(I).StrKpBegin = m_ESADesc(I).StrKpBegin + c_strGamaSeparator + oAttr.Value
                                            End If
                                        End If
                                                                            
                                        Set oAttr = oESA.getAttributeNode(c_strKPEndAttr)
                                        If (oAttr Is Nothing) Then
                                            If (m_ESADesc(I).StrKpEnd = "") Then
                                                m_ESADesc(I).StrKpEnd = "0"
                                            Else
                                                m_ESADesc(I).StrKpEnd = m_ESADesc(I).StrKpEnd + c_strGamaSeparator + "0"
                                            End If
                                        Else
                                            If (m_ESADesc(I).StrKpEnd = "") Then
                                                m_ESADesc(I).StrKpEnd = oAttr.Value
                                            Else
                                                m_ESADesc(I).StrKpEnd = m_ESADesc(I).StrKpEnd + c_strGamaSeparator + oAttr.Value
                                            End If
                                        End If
                                        
                                    Next oESA
                                End If
                                Set oESAList = Nothing
                                I = I + 1
                            Next oBlock
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadXMLBlocksListString", _
                                         "No Blocks has been defined in the OPC variable [" & m_OPC_XML_BlockList.Name & "]")
                        End If
                        Set oBlockList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadXMLBlocksListString", _
                             "The content of the OPC variable [" & m_OPC_XML_BlockList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadXMLBlocksListString", _
                     "The OPC variable [" & m_OPC_XML_BlockList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadXMLBlocksListString", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_ListofAllBlocks
' Input:        --
' Output:       [String] List of all blocks
' Description:  Returns the blocks in the line
'-------------------------------------------------------------------------------
Public Function Get_ListofAllBlocks() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_ListofAllBlocks", "Begin Function")
    
    Dim I As Integer
    Dim temp_strBlockList As String
    temp_strBlockList = ""
    
    For I = 0 To UBound(m_BlocksDesc)
        If (temp_strBlockList <> "") Then
            temp_strBlockList = temp_strBlockList + c_strGamaSeparator + m_BlocksDesc(I).strID
        Else
            temp_strBlockList = m_BlocksDesc(I).strID
        End If
    Next I
    
    Get_ListofAllBlocks = Split(temp_strBlockList, c_strGamaSeparator)
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_ListofAllBlocks", Err.Description)
End Function
'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_GamaList (String BlockID)
' Input:        [string] block ID
' Output:       [String] Gama List of the block
' Description:  Returns the current gama list of the block
'-------------------------------------------------------------------------------
Public Function Get_GamaList(ByVal BlockID As String) As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_GamaList", "Begin Function")
    
    Dim I As Integer
    Dim index As Integer
    
    index = 0
    
    For I = 0 To UBound(m_BlocksDesc)
        If (m_BlocksDesc(I).strID = BlockID) Then
            index = I
            I = UBound(m_BlocksDesc)
        End If
    Next I
    
    Get_GamaList = Split(m_EGamasDesc(index).strID, c_strGamaSeparator)
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_GamaList", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_EGamaName (String EGamaID)
' Input:        [string] ElementaryGama ID
' Output:       [String] Gama Name of the gama ID
' Description:  Returns the current gama name
'-------------------------------------------------------------------------------
Public Function Get_EGamaName(ByVal EGamaID As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_EGamaName", "Begin Function")
    
    Dim I As Integer
    Dim j As Integer

    Dim tmpGamaList() As String
    Dim strName As String
        
    For I = 0 To UBound(m_EGamasDesc)
        tmpGamaList = Split(m_EGamasDesc(I).strID, c_strGamaSeparator)
        For j = 0 To UBound(tmpGamaList)
            If (tmpGamaList(j) = EGamaID) Then
                tmpGamaList = Split(m_EGamasDesc(I).strName, c_strGamaSeparator)
                strName = tmpGamaList(j)
                I = UBound(m_BlocksDesc)
                Exit For
            End If
        Next j
    Next I
    
    Get_EGamaName = strName
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_EGamaName", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_EGamaBlockID (String EGamaID)
' Input:        [string] ElementaryGama ID
' Output:       [String] Gama Name List of the block
' Description:  Returns the current gama list of the block
'-------------------------------------------------------------------------------
Public Function Get_EGamaBlockID(ByVal EGamaID As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_EGamaBlockID", "Begin Function")
    
    Dim I As Integer
    Dim j As Integer
    Dim index As Integer
    Dim tmpGamaList() As String
    
    index = 0
    
    For I = 0 To UBound(m_EGamasDesc)
        tmpGamaList = Split(m_EGamasDesc(I).strID, c_strGamaSeparator)
        For j = 0 To UBound(tmpGamaList)
            If (tmpGamaList(j) = EGamaID) Then
                index = I
                I = UBound(m_BlocksDesc)
                Exit For
            End If
        Next j
    Next I
    
    Get_EGamaBlockID = m_BlocksDesc(index).strID
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_EGamaBlockID", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_GamaNameList (String BlockID)
' Input:        [string] block ID
' Output:       [String] Gama Name List of the block
' Description:  Returns the current gama list of the block
'-------------------------------------------------------------------------------
Public Function Get_GamaNameList(ByVal BlockID As String) As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_GamaList", "Begin Function")
    
    Dim I As Integer
    Dim index As Integer
    
    index = 0
    
    For I = 0 To UBound(m_BlocksDesc)
        If (m_BlocksDesc(I).strID = BlockID) Then
            index = I
            I = UBound(m_BlocksDesc)
        End If
    Next I
    
    Get_GamaNameList = Split(m_EGamasDesc(index).strName, c_strGamaSeparator)
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_GamaList", Err.Description)
End Function

'-----------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPC_XML_GamaList_ValueChange
' Input:        none
' Output:       none
' Description:  Manage the OPC variable containing the list of block definitions
'-----------------------------------------------------------------------------------
Private Sub m_OPC_XML_GamaList_ValueChange()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Gama", "m_OPC_XML_GamaList_ValueChange", "Begin Subroutine")

    If (m_OPC_XML_GamaList.Status = fvVariableStatusWaiting) Then
        Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPC_XML_GamaList_ValueChange", "The status of " & m_OPC_XML_GamaList.Name & " is Waiting")
    ElseIf (m_OPC_XML_GamaList.Status = fvVariableStatusConfigError) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPC_XML_GamaList_ValueChange", "The status of " & m_OPC_XML_GamaList.Name & " is Config Error")
    ElseIf (m_OPC_XML_GamaList.Status = fvVariableStatusNotConnected) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Gama", "m_OPC_XML_GamaList_ValueChange", "The status of " & m_OPC_XML_GamaList.Name & " is Not Connected")
    ElseIf (m_OPC_XML_GamaList.Quality <> 192) Then
        Call CBTrace(CBTRACE_VAR, "Iconis_CLS_Gama", "m_OPC_XML_GamaList_ValueChange", "The Quality of " & m_OPC_XML_GamaList.Name & " is not good")
    Else
       ' Read the string
        ReadXMLGamaListString
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPC_XML_GamaList_ValueChange", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::ReadXMLGamaListString
' Input:        none
' Output:       none
' Description:  Read the string (XML format) containing the list of gama
'-------------------------------------------------------------------------------
Private Sub ReadXMLGamaListString()
On Error GoTo ErrorHandler
   Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "ReadXMLGamaListString", "Begin Subroutine")
   
   Dim strXMLString As String
   Dim oDoc As DOMDocument
   Dim oBlockList As IXMLDOMNodeList
   Dim oBlock As IXMLDOMElement
   Dim oGamaList As IXMLDOMNodeList
   Dim oGama As IXMLDOMElement
   
   Dim str_Temp As String
   
   Dim I As Integer
   
   strXMLString = m_OPC_XML_GamaList.Value

    ' Empty the data lists
    ReDim m_strGamaID(0)
    ReDim m_strGamaName(0)
    ReDim m_strBlockList(0)
    
   If (strXMLString <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(strXMLString) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "Condition"
                    Set oGamaList = oDoc.documentElement.getElementsByTagName(c_strGamaNode)
                    If Not (oGamaList Is Nothing) Then
                        If (oGamaList.length > 0) Then
                            ReDim m_strGamaID(oGamaList.length - 1)
                            ReDim m_strGamaName(oGamaList.length - 1)
                            ReDim m_strBlockList(oGamaList.length - 1)
                            
                            I = 0
                            For Each oGama In oGamaList
                                ' read the attributes
                                m_strGamaID(I) = oGama.getAttribute(c_strGamaIDAttr)
                                m_strGamaName(I) = oGama.getAttribute(c_strGamaNameAttr)
                                
                                Set oBlockList = oGama.getElementsByTagName(c_strBlockNode)
                                m_strBlockList(I) = ""
                                For Each oBlock In oBlockList
                                    ' read the attributes
                                    str_Temp = oBlock.getAttribute(c_strBlockIDAttr)
                                    
                                    If (str_Temp <> "") Then
                                        If (m_strBlockList(I) = "") Then
                                            m_strBlockList(I) = str_Temp
                                        Else
                                            m_strBlockList(I) = m_strBlockList(I) + c_strGamaSeparator + str_Temp
                                        End If
                                    End If
                                Next oBlock
                                Set oBlockList = Nothing
                                I = I + 1
                            Next oGama
                        Else
                            Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadXMLGamaListString", _
                                         "No Gama has been defined in the OPC variable [" & m_OPC_XML_GamaList.Name & "]")
                        End If
                        Set oGamaList = Nothing
                    End If
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadXMLGamaListString", _
                             "The content of the OPC variable [" & m_OPC_XML_GamaList.Name & "] has not been loaded")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadXMLGamaListString", _
                     "The OPC variable [" & m_OPC_XML_GamaList.Name & "] is empty")
    End If
       
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadXMLGamaListString", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_GamaNames ()
' Input:
' Output:       [String] list of GAMA Names
' Description:  Returns the list of GAMA Names
'-------------------------------------------------------------------------------
Public Function Get_GamaNames() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_GamaNames", "Begin Function")
    
    Get_GamaNames = m_strGamaName
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_GamaNames", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_BlockList (String GamaID)
' Input:        [string] Gama ID
' Output:       [String] block List associated with the gama
' Description:  Returns the current block list associated with the gama
'-------------------------------------------------------------------------------
Public Function Get_BlockList(ByVal GamaID As String) As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_BlockList", "Begin Function")
    
    Dim I As Integer
    Dim index As Integer
    
    index = 0
    
    For I = 0 To UBound(m_strGamaID)
        If (m_strGamaID(I) = GamaID) Then
            index = I
            I = UBound(m_strGamaID)
        End If
    Next I
    
    Get_BlockList = Split(m_strBlockList(index), c_strGamaSeparator)
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_BlockList", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_GamaID (String GamaName)
' Input:        [string] Gama Name
' Output:       [String] Gama ID associated with the gama Name
' Description:  Returns the current Gama ID associated with the gama Name
'-------------------------------------------------------------------------------
Public Function Get_GamaID(ByVal GamaName As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_GamaID", "Begin Function")
    
    Dim I As Integer
    Dim index As Integer
    
    index = 0
    
    For I = 0 To UBound(m_strGamaName)
        If (m_strGamaName(I) = GamaName) Then
            index = I
            Exit For
        End If
    Next I
    
    Get_GamaID = m_strGamaID(index)
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_GamaID", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_GamaName (String GamaID)
' Input:        [string] Gama ID
' Output:       [String] Gama Name associated with the gama ID
' Description:  Returns the current Gama Name associated with the Gama ID
'-------------------------------------------------------------------------------
Public Function Get_GamaName(ByVal GamaID As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_GamaName", "Begin Function")
    
    Dim I As Integer
    Dim index As Integer
    
    index = 0
    
    For I = 0 To UBound(m_strGamaName)
        If (m_strGamaID(I) = GamaID) Then
            index = I
            Exit For
        End If
    Next I
    
    Get_GamaName = m_strGamaName(index)
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_GamaName", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::Get_GamaPresence
' Input:
' Output:       [boolean] true if new Gama interface is active
' Description:  Returns the activation status of the new gama presence
'-------------------------------------------------------------------------------
Public Function Get_GamaPresence() As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "Get_GamaPresence", "Begin Function")
    
    Get_GamaPresence = m_GamaPresence
    
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "Get_GamaPresence", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::StartBlockAnimation
' Input:        -
' Output:       -
' Description:  used current block list and current GamaPresence indicator to manage OPCSet
' for block animation
'-------------------------------------------------------------------------------
Public Sub StartBlockAnimation()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "StartBlockAnimation", "Begin Subroutine")
    
    Dim I As Integer
    Dim j As Integer
    Dim eGamaList() As String
    Dim eESAList() As String
    Dim StrVar As String
    Dim VarToUpdate As Variable

    If Not (m_OPCSet_BlockData Is Nothing) Then
        m_OPCSet_BlockData.Destroy
        Set m_OPCSet_BlockData = Nothing
    End If
    
    If Not (m_OPCSet_EGAMAData Is Nothing) Then
        m_OPCSet_EGAMAData.Destroy
        Set m_OPCSet_EGAMAData = Nothing
    End If
    
    If Not (m_OPCSet_BlockESA_old Is Nothing) Then
        m_OPCSet_BlockESA_old.Destroy
        Set m_OPCSet_BlockESA_old = Nothing
    End If
    
    If Not (m_OPCSet_BlockESA_new Is Nothing) Then
        m_OPCSet_BlockESA_new.Destroy
        Set m_OPCSet_BlockESA_new = Nothing
    End If
    
    
    If (m_GamaPresence = False) Then
        'keep the old animation, create OPCSet on block gamazone
        'each time a gamazone changes, the display should be updated
        Set m_OPCSet_BlockData = Iconis_MOD_General.CreateNew_Iconis_CLS_OPCSet
        
        For I = 0 To UBound(m_BlocksDesc)
            m_OPCSet_BlockData.AddItem MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(I).strID & c_strBlockGamaZoneTag, fvVariableTypeText, c_OPCReadQuality
        Next I
        
        m_OPCSet_BlockData.DoConnect "GamaBlockAnimation"
        
        'keep the old animation, create OPCSet on block ESA zone
        'each time a ESAZone changes, ESA zone display should be updated
        Set m_OPCSet_BlockESA_old = Iconis_MOD_General.CreateNew_Iconis_CLS_OPCSet
        
        For I = 0 To UBound(m_BlocksDesc)
            m_OPCSet_BlockESA_old.AddItem MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(I).strID & c_strBlockESAZoneTag, fvVariableTypeText, c_OPCReadQuality
        Next I
        
        m_OPCSet_BlockESA_old.DoConnect "ESABlockAnimation"
        
    Else
        'new animation, create OPCSet that follows each EGama Gamazone status, and NoVStatus
        'each time a gamazone changes, the gamazone should be regenerated by HMI module according eGama status
        Set m_OPCSet_EGAMAData = Iconis_MOD_General.CreateNew_Iconis_CLS_OPCSet
 
        For I = 0 To UBound(m_BlocksDesc)
            eGamaList = Split(m_EGamasDesc(I).strID, c_strGamaSeparator)
            For j = 0 To UBound(eGamaList)
                m_OPCSet_EGAMAData.AddItem MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(I).strID & "." & eGamaList(j) & c_strEGamaStatusTag, fvVariableTypeRegister, c_OPCReadAll
                m_OPCSet_EGAMAData.AddItem MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(I).strID & "." & eGamaList(j) & c_strEGamaTrackStatusTag, fvVariableTypeRegister, c_OPCReadAll
            
                StrVar = MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(I).strID

                Set VarToUpdate = Variables.Add(StrVar & c_strAnimationGamaZoneTag, fvVariableTypeText)
                VarToUpdate.Value = GetGAMAZoneForBlock(0, True)
            Next j
        Next I
        
        m_OPCSet_EGAMAData.DoConnect "GamaNewBlockAnimation"
        
        'new animation, create OPCSet that follows each ESA status
        'each time a ESA changes, the ESAZone information should be regenerated by HMI module according ESA status
        Set m_OPCSet_BlockESA_new = Iconis_MOD_General.CreateNew_Iconis_CLS_OPCSet
 
        For I = 0 To UBound(m_BlocksDesc)
            eESAList = Split(m_ESADesc(I).strID, c_strGamaSeparator)
            
            For j = 0 To UBound(eESAList)
                m_OPCSet_BlockESA_new.AddItem MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(I).strID & "." & eESAList(j) & c_strESAStatusTag, fvVariableTypeRegister, c_OPCReadAll
           
                StrVar = MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(I).strID

                Set VarToUpdate = Variables.Add(StrVar & c_strAnimationESAZoneTag, fvVariableTypeText)
                VarToUpdate.Value = GetESAZoneForBlock(0, True)
            Next j
        Next I
        
        m_OPCSet_BlockESA_new.DoConnect "ESANewBlockAnimation"
    End If
    
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "StartBlockAnimation", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPCSet_BlockData_OnConnection
' Input:        -
' Output:       -
' Description:  on connection update the data displayed in the block
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_BlockData_OnConnection(arrValue() As Variant, arrStatus() As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPCSet_BlockData_OnConnection", "Begin Subroutine")
    Dim I As Long

    For I = 0 To UBound(arrValue)
        m_OPCSet_BlockData_OnRefresh I, arrValue(I), arrStatus(I)
    Next I
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPCSet_BlockData_OnConnection", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPCSet_BlockData_OnRefresh
' Input:        -
' Output:       -
' Description:  used current block list to do block animation
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_BlockData_OnRefresh(lIndex As Long, Value As Variant, Status As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPCSet_BlockData_OnRefresh", "Begin Subroutine")
    Dim VarToUpdate As Variable
    
    If (Status <> fvVariableStatusGood) Then
        'remove the variable to display it as invalid
        Variables.Remove (MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(lIndex).strID & c_strAnimationGamaZoneTag)
    Else
        Set VarToUpdate = Variables.Add(MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(lIndex).strID & c_strAnimationGamaZoneTag, fvVariableTypeText)
        VarToUpdate.Value = Value
    End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPCSet_BlockData_OnRefresh", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPCSet_BlockESA_new_OnConnection
' Input:        -
' Output:       -
' Description:  on connection update the data displayed in the block
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_BlockESA_new_OnConnection(arrValue() As Variant, arrStatus() As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPCSet_BlockESA_new_OnConnection", "Begin Subroutine")
    Dim I As Long

    For I = 0 To UBound(arrValue)
        m_OPCSet_BlockESA_new_OnRefresh I, arrValue(I), arrStatus(I)
    Next I
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPCSet_BlockESA_new_OnConnection", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPCSet_BlockESA_new_OnRefresh
' Input:        -
' Output:       -
' Description:  used current block list and current ESA indicator to manage OPCSet
' for block animation
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_BlockESA_new_OnRefresh(lIndex As Long, Value As Variant, Status As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPCSet_BlockESA_new_OnRefresh", "Begin Subroutine")
    Dim VarToUpdate As Variable
    Dim StrVar As String
    Dim strtemp As String
    Dim ESAList() As String
    Dim I As Integer
    Dim blockindex As Long
    Dim ESAIndex As Long
    
    '* get the index of the ESAZone to animate
    ESAIndex = lIndex

    blockindex = 0
    For I = 0 To UBound(m_ESADesc)
        ESAList = Split(m_ESADesc(I).strID, c_strGamaSeparator)
        If (ESAIndex > UBound(ESAList)) Then
            ESAIndex = ESAIndex - (UBound(ESAList) + 1)
        Else
            blockindex = I
            Exit For
        End If
    Next I
    
    '*retrieve the branch to animate
    strtemp = "." & ESAList(ESAIndex) & c_strESAStatusTag

    StrVar = m_OPCSet_BlockESA_new.Item(lIndex).strPath
    StrVar = Replace(StrVar, strtemp, "")

    Set VarToUpdate = Variables.Add(StrVar & c_strAnimationESAZoneTag, fvVariableTypeText)
    VarToUpdate.Value = GetESAZoneForBlock(blockindex)
  
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPCSet_BlockESA_new_OnRefresh", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPCSet_BlockESA_old_OnConnection
' Input:        -
' Output:       -
' Description:  on connection update the data displayed in the block
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_BlockESA_old_OnConnection(arrValue() As Variant, arrStatus() As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPCSet_BlockESA_old_OnConnection", "Begin Subroutine")
    Dim I As Long

    For I = 0 To UBound(arrValue)
        m_OPCSet_BlockESA_old_OnRefresh I, arrValue(I), arrStatus(I)
    Next I
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPCSet_BlockESA_old_OnConnection", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPCSet_BlockESA_old_OnRefresh
' Input:        -
' Output:       -
' Description:  used current block list to do block animation of ESA for Old interface
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_BlockESA_old_OnRefresh(lIndex As Long, Value As Variant, Status As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPCSet_BlockESA_old_OnRefresh", "Begin Subroutine")
    Dim VarToUpdate As Variable
    
    If (Status <> fvVariableStatusGood) Then
        'remove the variable to display it as invalid
        Variables.Remove (MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(lIndex).strID & c_strAnimationESAZoneTag)
    Else
        Set VarToUpdate = Variables.Add(MOD_Deployment.CBTCLevel1Cluster & m_BlocksDesc(lIndex).strID & c_strAnimationESAZoneTag, fvVariableTypeText)
        VarToUpdate.Value = Value
    End If
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPCSet_BlockESA_old_OnRefresh", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPCSet_EGAMAData_OnConnection
' Input:        -
' Output:       -
' Description:  on connection update the data displayed in the block
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_EGAMAData_OnConnection(arrValue() As Variant, arrStatus() As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPCSet_EGAMAData_OnConnection", "Begin Subroutine")
    Dim I As Long

    For I = 0 To UBound(arrValue)
        m_OPCSet_EGAMAData_OnRefresh I, arrValue(I), arrStatus(I)
    Next I
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPCSet_EGAMAData_OnConnection", Err.Description)
End Sub

'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::m_OPCSet_EGAMAData_OnRefresh
' Input:        -
' Output:       -
' Description:  used current block list and current GamaPresence indicator to manage OPCSet
' for block animation
'-------------------------------------------------------------------------------
Private Sub m_OPCSet_EGAMAData_OnRefresh(lIndex As Long, Value As Variant, Status As fvVariableStatus)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "m_OPCSet_EGAMAData_OnRefresh", "Begin Subroutine")
    Dim VarToUpdate As Variable
    Dim EGamaIndex As Integer
    Dim StrVar As String
    Dim strtemp As String
    Dim eGamaList() As String
    Dim I As Integer
    Dim blockindex As Long
    
    '* get the index of the GAMAZone to animate
    EGamaIndex = lIndex
    If (lIndex Mod 2 <> 0) Then
        EGamaIndex = lIndex - (lIndex Mod 2)
    End If
    EGamaIndex = EGamaIndex / 2
    
    blockindex = 0
    For I = 0 To UBound(m_EGamasDesc)
        eGamaList = Split(m_EGamasDesc(I).strID, c_strGamaSeparator)
        If (EGamaIndex > UBound(eGamaList)) Then
            EGamaIndex = EGamaIndex - (UBound(eGamaList) + 1)
        Else
            blockindex = I
            Exit For
        End If
    Next I
    
    '*retrieve the branch to animate
    Select Case (lIndex Mod 2)
    Case 0:
        strtemp = "." & eGamaList(EGamaIndex) & c_strEGamaStatusTag
    Case 1:
        strtemp = "." & eGamaList(EGamaIndex) & c_strEGamaTrackStatusTag
    End Select
    
    StrVar = m_OPCSet_EGAMAData.Item(lIndex).strPath
    StrVar = Replace(StrVar, strtemp, "")

    Set VarToUpdate = Variables.Add(StrVar & c_strAnimationGamaZoneTag, fvVariableTypeText)
    VarToUpdate.Value = GetGAMAZoneForBlock(blockindex)
  
Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "m_OPCSet_EGAMAData_OnRefresh", Err.Description)
End Sub


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::GetGAMAZoneForBlock
' Input:        current gama index to read
' Output:       -
' Description:  read the GAMA Status and NoVGAMAStatus, generate the gamazone information
'-------------------------------------------------------------------------------
Private Function GetGAMAZoneForBlock(lBlockIndex As Long, Optional IsDummy As Boolean = False) As Byte()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "GetGAMAZoneForBlock", "Begin Function")
    
    Dim eGamaKpBeginList() As String
    Dim eGamaKpEndList() As String
    
    Dim ByteArray() As Byte
    Dim ByteArray2() As Byte
    Dim TempStr As String
    
    Dim iBeginBlock As Long
    Dim iEndBlock As Long
    Dim iNbZone As Integer
    Dim I As Integer
    
    Dim iBeginZone As Long
    Dim iEndZone As Long
    Dim Color As Byte
    
    Dim GamaInfoValidity As Boolean
    Dim GamaStatus As Integer
    Dim GamaTrackStatus As Integer
    Dim GamaNoVStatus As Integer
    Dim GamaNoVTrackStatus As Integer
        
    Dim iTempData As Integer

    iBeginBlock = 0
    iEndBlock = 0
    iNbZone = 0
    iBeginZone = 0
    iEndZone = 0
    Color = c_iColorGamaInvalid

    If (IsDummy = True) Then
        iBeginBlock = 0
        iEndBlock = 100
        iNbZone = 1
        iBeginZone = 0
        iEndZone = 100
        
        ReDim ByteArray(11 + iNbZone * 13)
        
        'fill the datable header
        iTempData = iBeginBlock And &HFF
        ByteArray(0) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 8)) And &HFF
        ByteArray(1) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 16)) And &HFF
        ByteArray(2) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 24)) And &HFF
        ByteArray(3) = CByte(iTempData)
        
        iTempData = iEndBlock And &HFF
        ByteArray(4) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 8)) And &HFF
        ByteArray(5) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 16)) And &HFF
        ByteArray(6) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 24)) And &HFF
        ByteArray(7) = CByte(iTempData)
    
        iTempData = iNbZone And &HFF
        ByteArray(8) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 8)) And &HFF
        ByteArray(9) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 16)) And &HFF
        ByteArray(10) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 24)) And &HFF
        ByteArray(11) = CByte(iTempData)
        
               
        'fill the byte array for the current elementary gama
        iTempData = iBeginZone And &HFF
        ByteArray(12) = CByte(iTempData)
        iTempData = (iBeginZone \ (2 ^ 8)) And &HFF
        ByteArray(13) = CByte(iTempData)
        iTempData = (iBeginZone \ (2 ^ 16)) And &HFF
        ByteArray(14) = CByte(iTempData)
        iTempData = (iBeginZone \ (2 ^ 24)) And &HFF
        ByteArray(15) = CByte(iTempData)
            
        iTempData = iEndZone And &HFF
        ByteArray(16) = CByte(iTempData)
        iTempData = (iEndZone \ (2 ^ 8)) And &HFF
        ByteArray(17) = CByte(iTempData)
        iTempData = (iEndZone \ (2 ^ 16)) And &HFF
        ByteArray(18) = CByte(iTempData)
        iTempData = (iEndZone \ (2 ^ 24)) And &HFF
        ByteArray(19) = CByte(iTempData)
            
        ByteArray(20) = Color
            
        ByteArray(21) = 0
        ByteArray(22) = 0
        ByteArray(23) = 0
        ByteArray(24) = 0
    Else

        If (lBlockIndex <= UBound(m_BlocksDesc)) Then
            iBeginBlock = m_BlocksDesc(lBlockIndex).lKpBegin
            iEndBlock = m_BlocksDesc(lBlockIndex).lKpEnd
            
            If (m_EGamasDesc(lBlockIndex).strID = "") Then
                '* no gamazone
                iNbZone = 0
                ReDim ByteArray(11)
            Else
                eGamaKpBeginList = Split(m_EGamasDesc(lBlockIndex).StrKpBegin, c_strGamaSeparator)
                eGamaKpEndList = Split(m_EGamasDesc(lBlockIndex).StrKpEnd, c_strGamaSeparator)
                iNbZone = UBound(eGamaKpBeginList) + 1
                
                ReDim ByteArray(11 + iNbZone * 13)
            End If
        End If

    
        'fill the datable header
        iTempData = iBeginBlock And &HFF
        ByteArray(0) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 8)) And &HFF
        ByteArray(1) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 16)) And &HFF
        ByteArray(2) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 24)) And &HFF
        ByteArray(3) = CByte(iTempData)
        
        iTempData = iEndBlock And &HFF
        ByteArray(4) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 8)) And &HFF
        ByteArray(5) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 16)) And &HFF
        ByteArray(6) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 24)) And &HFF
        ByteArray(7) = CByte(iTempData)
    
        iTempData = iNbZone And &HFF
        ByteArray(8) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 8)) And &HFF
        ByteArray(9) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 16)) And &HFF
        ByteArray(10) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 24)) And &HFF
        ByteArray(11) = CByte(iTempData)
        
        '*fill the datatable for each gama zone of the block to update
        For I = 0 To (iNbZone - 1)
            iBeginZone = eGamaKpBeginList(I)
            If (iBeginZone < iBeginBlock) Then
                iBeginZone = iBeginBlock
            End If
            
            iEndZone = eGamaKpEndList(I)
            If (iEndZone > iEndBlock) Then
                iEndZone = iEndBlock
            End If
            '* read the elementary gama information
            GamaInfoValidity = ((m_OPCSet_EGAMAData.Item((m_EGamasDesc(lBlockIndex).startIndex + I) * 2).Status = fvVariableStatusGood) _
                                And (m_OPCSet_EGAMAData.Item((m_EGamasDesc(lBlockIndex).startIndex + I) * 2 + 1).Status = fvVariableStatusGood))
            
            GamaStatus = m_OPCSet_EGAMAData.Item((m_EGamasDesc(lBlockIndex).startIndex + I) * 2).Value
            GamaTrackStatus = m_OPCSet_EGAMAData.Item((m_EGamasDesc(lBlockIndex).startIndex + I) * 2 + 1).Value
        
            '* calculate the color code
            Color = c_iColorGamaInvalid
            If (GamaInfoValidity) Then
                If ((GamaStatus = c_iRemovedRestrictive) And (GamaTrackStatus = c_iRemovedRestrictive)) Then
                    Color = c_iColorGamaRed
                Else
                    Color = c_iColorGamaInvisible
                End If
            End If
                
            'fill the byte array for the current elementary gama
            iTempData = iBeginZone And &HFF
            ByteArray(12 + (13 * I)) = CByte(iTempData)
            iTempData = (iBeginZone \ (2 ^ 8)) And &HFF
            ByteArray(12 + (13 * I) + 1) = CByte(iTempData)
            iTempData = (iBeginZone \ (2 ^ 16)) And &HFF
            ByteArray(12 + (13 * I) + 2) = CByte(iTempData)
            iTempData = (iBeginZone \ (2 ^ 24)) And &HFF
            ByteArray(12 + (13 * I) + 3) = CByte(iTempData)
            
            iTempData = iEndZone And &HFF
            ByteArray(12 + (13 * I) + 4) = CByte(iTempData)
            iTempData = (iEndZone \ (2 ^ 8)) And &HFF
            ByteArray(12 + (13 * I) + 5) = CByte(iTempData)
            iTempData = (iEndZone \ (2 ^ 16)) And &HFF
            ByteArray(12 + (13 * I) + 6) = CByte(iTempData)
            iTempData = (iEndZone \ (2 ^ 24)) And &HFF
            ByteArray(12 + (13 * I) + 7) = CByte(iTempData)
            
            ByteArray(12 + (13 * I) + 8) = Color
            
            ByteArray(12 + (13 * I) + 9) = 0
            ByteArray(12 + (13 * I) + 10) = 0
            ByteArray(12 + (13 * I) + 11) = 0
            ByteArray(12 + (13 * I) + 12) = 0
        Next I
    End If
    'format the bytearray, for the multizone
    Dim str As String
    ReDim ByteArray2(((UBound(ByteArray) + 1) * 4) - 1)
    For I = 0 To UBound(ByteArray)
        str = Hex(ByteArray(I))
        If (Len(str) < 2) Then
            str = "0" & str
        End If
    
        Dim x() As Byte
        x = StrConv(str, vbFromUnicode)
        
        ByteArray2(4 * I) = x(0)
        ByteArray2((4 * I) + 1) = 0
        ByteArray2((4 * I) + 2) = x(1)
        ByteArray2((4 * I) + 3) = 0
    Next I

    GetGAMAZoneForBlock = ByteArray2
  
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "GetGAMAZoneForBlock", Err.Description)
End Function

'* Subroutine: ReadGamaListFromXML
'* update the display of the list of elementary gama
'* ************************************************************************************************
Public Function ReadGamaListFromXML(ByVal GamaListXML) As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "ReadGamaListFromXML", "Begin Function")
   
   Dim oDoc As DOMDocument
   Dim oGamaList As IXMLDOMNodeList
   Dim oGama As IXMLDOMElement
   Dim oAttr As IXMLDOMAttribute
   
   Dim str_Temp As String
   Dim str_result As String
   
   Dim I As Integer
   Dim j As Integer
    
   str_result = ""
   If (GamaListXML <> "") Then
                        
        Set oDoc = New DOMDocument
        If Not (oDoc Is Nothing) Then
            ' Load the XML document from the specified string
            If (oDoc.loadXML(GamaListXML) = True) Then
                If Not (oDoc.documentElement Is Nothing) Then
                    ' Find all the nodes "ElementaryGama"
                    Set oGamaList = oDoc.documentElement.getElementsByTagName(c_strTZElementaryGamaNode)
                    
                    If Not (oGamaList Is Nothing) Then
                        For Each oGama In oGamaList
                            ' read the attributes
                            str_Temp = oGama.getAttribute(c_strGamaIDAttr)
                                        
                            If (str_Temp <> "") Then
                                If (str_result = "") Then
                                    str_result = str_Temp
                                Else
                                    str_result = str_result + c_strGamaSeparator + str_Temp
                                End If
                            End If
                        Next oGama
                    End If
                    Set oGamaList = Nothing
                End If
            Else
                Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadGamaListFromXML", _
                             "The content of the OPC variable [GamaListXML] has not been loaded ")
            End If
            Set oDoc = Nothing
        End If
    Else
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadGamaListFromXML", _
                     "The OPC variable [GamaListXML] is empty")
    End If
    
    ReadGamaListFromXML = Split(str_result, c_strGamaSeparator)
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "ReadGamaListFromXML", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_CLS_Gama::GetESAZoneForBlock
' Input:        bloc index to animate
' Output:       -
' Description:  read the ESA Status of the block, generate the ESAzone information
'-------------------------------------------------------------------------------
Private Function GetESAZoneForBlock(lBlockIndex As Long, Optional IsDummy As Boolean = False) As Byte()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_CLS_Gama", "GetESAZoneForBlock", "Begin Function")
    
    Dim eESAKpBeginList() As String
    Dim eESAKpEndList() As String
    
    Dim ByteArray() As Byte
    Dim ByteArray2() As Byte
    Dim TempStr As String
    
    Dim iBeginBlock As Long
    Dim iEndBlock As Long
    Dim iNbZone As Integer
    Dim I As Integer
    
    Dim iBeginZone As Long
    Dim iEndZone As Long
    Dim Color As Byte
    
    Dim ESAInfoValidity As Boolean
    Dim ESAStatus As Integer

    Dim iTempData As Integer

    iBeginBlock = 0
    iEndBlock = 0
    iNbZone = 0
    iBeginZone = 0
    iEndZone = 0
    Color = c_iColorESAInvalid

    If (IsDummy = True) Then
        iBeginBlock = 0
        iEndBlock = 100
        iNbZone = 1
        iBeginZone = 0
        iEndZone = 100
        
        ReDim ByteArray(11 + iNbZone * 13)
        
        'fill the datable header
        iTempData = iBeginBlock And &HFF
        ByteArray(0) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 8)) And &HFF
        ByteArray(1) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 16)) And &HFF
        ByteArray(2) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 24)) And &HFF
        ByteArray(3) = CByte(iTempData)
        
        iTempData = iEndBlock And &HFF
        ByteArray(4) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 8)) And &HFF
        ByteArray(5) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 16)) And &HFF
        ByteArray(6) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 24)) And &HFF
        ByteArray(7) = CByte(iTempData)
    
        iTempData = iNbZone And &HFF
        ByteArray(8) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 8)) And &HFF
        ByteArray(9) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 16)) And &HFF
        ByteArray(10) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 24)) And &HFF
        ByteArray(11) = CByte(iTempData)
        
               
        'fill the byte array for the current elementary esa
        iTempData = iBeginZone And &HFF
        ByteArray(12) = CByte(iTempData)
        iTempData = (iBeginZone \ (2 ^ 8)) And &HFF
        ByteArray(13) = CByte(iTempData)
        iTempData = (iBeginZone \ (2 ^ 16)) And &HFF
        ByteArray(14) = CByte(iTempData)
        iTempData = (iBeginZone \ (2 ^ 24)) And &HFF
        ByteArray(15) = CByte(iTempData)
            
        iTempData = iEndZone And &HFF
        ByteArray(16) = CByte(iTempData)
        iTempData = (iEndZone \ (2 ^ 8)) And &HFF
        ByteArray(17) = CByte(iTempData)
        iTempData = (iEndZone \ (2 ^ 16)) And &HFF
        ByteArray(18) = CByte(iTempData)
        iTempData = (iEndZone \ (2 ^ 24)) And &HFF
        ByteArray(19) = CByte(iTempData)
            
        ByteArray(20) = Color
            
        ByteArray(21) = 0
        ByteArray(22) = 0
        ByteArray(23) = 0
        ByteArray(24) = 0
    Else

        If (lBlockIndex <= UBound(m_BlocksDesc)) Then
            iBeginBlock = m_BlocksDesc(lBlockIndex).lKpBegin
            iEndBlock = m_BlocksDesc(lBlockIndex).lKpEnd
            
            If (m_ESADesc(lBlockIndex).strID = "") Then
                '* no esazone
                iNbZone = 0
                ReDim ByteArray(11)
            Else
                eESAKpBeginList = Split(m_ESADesc(lBlockIndex).StrKpBegin, c_strGamaSeparator)
                eESAKpEndList = Split(m_ESADesc(lBlockIndex).StrKpEnd, c_strGamaSeparator)
                iNbZone = UBound(eESAKpBeginList) + 1
                
                ReDim ByteArray(11 + iNbZone * 13)
            End If
        End If

    
        'fill the datable header
        iTempData = iBeginBlock And &HFF
        ByteArray(0) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 8)) And &HFF
        ByteArray(1) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 16)) And &HFF
        ByteArray(2) = CByte(iTempData)
        iTempData = (iBeginBlock \ (2 ^ 24)) And &HFF
        ByteArray(3) = CByte(iTempData)
        
        iTempData = iEndBlock And &HFF
        ByteArray(4) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 8)) And &HFF
        ByteArray(5) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 16)) And &HFF
        ByteArray(6) = CByte(iTempData)
        iTempData = (iEndBlock \ (2 ^ 24)) And &HFF
        ByteArray(7) = CByte(iTempData)
    
        iTempData = iNbZone And &HFF
        ByteArray(8) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 8)) And &HFF
        ByteArray(9) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 16)) And &HFF
        ByteArray(10) = CByte(iTempData)
        iTempData = (iNbZone \ (2 ^ 24)) And &HFF
        ByteArray(11) = CByte(iTempData)
        
        '*fill the datatable for each esa zone of the block to update
        For I = 0 To (iNbZone - 1)
            iBeginZone = eESAKpBeginList(I)
            If (iBeginZone < iBeginBlock) Then
                iBeginZone = iBeginBlock
            End If
            
            iEndZone = eESAKpEndList(I)
            If (iEndZone > iEndBlock) Then
                iEndZone = iEndBlock
            End If
            
            '* read the elementary esa information
            ESAInfoValidity = ((m_OPCSet_BlockESA_new.Item((m_ESADesc(lBlockIndex).startIndex + I)).Status = fvVariableStatusGood))
            
            ESAStatus = m_OPCSet_BlockESA_new.Item((m_ESADesc(lBlockIndex).startIndex + I)).Value
            
            '* calculate the color code
            Color = c_iColorESAInvalid
            If (ESAInfoValidity) Then
                If (ESAStatus = c_iActive) Then
                    Color = c_iColorESAActive
                Else
                    Color = c_iColorESAInactive
                End If
            End If
                
            'fill the byte array for the current elementary esa
            iTempData = iBeginZone And &HFF
            ByteArray(12 + (13 * I)) = CByte(iTempData)
            iTempData = (iBeginZone \ (2 ^ 8)) And &HFF
            ByteArray(12 + (13 * I) + 1) = CByte(iTempData)
            iTempData = (iBeginZone \ (2 ^ 16)) And &HFF
            ByteArray(12 + (13 * I) + 2) = CByte(iTempData)
            iTempData = (iBeginZone \ (2 ^ 24)) And &HFF
            ByteArray(12 + (13 * I) + 3) = CByte(iTempData)
            
            iTempData = iEndZone And &HFF
            ByteArray(12 + (13 * I) + 4) = CByte(iTempData)
            iTempData = (iEndZone \ (2 ^ 8)) And &HFF
            ByteArray(12 + (13 * I) + 5) = CByte(iTempData)
            iTempData = (iEndZone \ (2 ^ 16)) And &HFF
            ByteArray(12 + (13 * I) + 6) = CByte(iTempData)
            iTempData = (iEndZone \ (2 ^ 24)) And &HFF
            ByteArray(12 + (13 * I) + 7) = CByte(iTempData)
            
            ByteArray(12 + (13 * I) + 8) = Color
            
            ByteArray(12 + (13 * I) + 9) = 0
            ByteArray(12 + (13 * I) + 10) = 0
            ByteArray(12 + (13 * I) + 11) = 0
            ByteArray(12 + (13 * I) + 12) = 0
        Next I
    End If
    'format the bytearray, for the multizone
    Dim str As String
    ReDim ByteArray2(((UBound(ByteArray) + 1) * 4) - 1)
    For I = 0 To UBound(ByteArray)
        str = Hex(ByteArray(I))
        If (Len(str) < 2) Then
            str = "0" & str
        End If
    
        Dim x() As Byte
        x = StrConv(str, vbFromUnicode)
        
        ByteArray2(4 * I) = x(0)
        ByteArray2((4 * I) + 1) = 0
        ByteArray2((4 * I) + 2) = x(1)
        ByteArray2((4 * I) + 3) = 0
    Next I

    GetESAZoneForBlock = ByteArray2
  
Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_CLS_Gama", "GetESAZoneForBlock", Err.Description)
End Function

