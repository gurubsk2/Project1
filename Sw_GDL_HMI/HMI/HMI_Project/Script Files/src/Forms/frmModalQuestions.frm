VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmModalQuestions 
   Caption         =   "UserForm1"
   ClientHeight    =   1500
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   5550
   OleObjectBlob   =   "frmModalQuestions.frm.frx":0000
End
Attribute VB_Name = "frmModalQuestions"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False








Private Sub btOK_Click()
    bFormMsgQuestion = True
    Unload Me
End Sub

Private Sub btCancela_Click()
    Unload Me
End Sub


Private Sub UserForm_Initialize()
    btCancela.SetFocus
    
End Sub

