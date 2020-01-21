VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmAbout 
   Caption         =   "Guadalajara - Versión instalada"
   ClientHeight    =   2280
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   7755
   OleObjectBlob   =   "frmAbout.frm.frx":0000
End
Attribute VB_Name = "frmAbout"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False


'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2008. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Form Name: About
'* *******************************************************************************************
'* Purpose:     It manages opening of the:
'*                  - Installed Version Mimic
'*
'* *******************************************************************************************
'* Modification History:
'* Author:              Chaitra Purohit
'* Date:                July '16
'* Change:              CR#atvcm00731692
    
'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************
   
'* Declarations
'* ******************************************************

Private Sub UserForm_Initialize()
    On Error Resume Next
    Dim TextLine As String
    Dim sFileDateTime As String
    
    If Dir(ThisProject.Path & "\install.log") = "" Then
        MsgBox "File not found: install.log"
        Exit Sub
    End If
    
    Open ThisProject.Path & "\install.log" For Input As #1   ' Open file.

    Do While Not EOF(1)    ' Loop until end of file.
        Line Input #1, TextLine    ' Read line into variable.

        If Left(TextLine, 9) = "Installed" Then
            
            lbl_NumeroVersao1.Caption = Split(TextLine, " ")(4) & " - " & Split(TextLine, " ")(3)
            lbl_NumeroVersao2.Caption = Format(FileDateTime(ThisProject.Path & "\install.log"), "DD/MM/YYYY - HH:MM:SS")

        End If
    Loop
    Close #1    ' Close file.
End Sub

Private Sub cmdClose_Click()
    Unload Me
End Sub

Private Sub cmdClose_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    'ESC para Sair do FORM
    If KeyAscii = 27 Then
        Unload Me
    End If
End Sub

