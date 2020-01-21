VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} FRM_LogOn 
   Caption         =   "Security - Log-on"
   ClientHeight    =   2610
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   4935
   OleObjectBlob   =   "FRM_LogOn.frm.frx":0000
End
Attribute VB_Name = "FRM_LogOn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False



Private Sub UserForm_Initialize()
On Error GoTo ErrorHandler
Call Me.Move(Int(1360 / 2) - Int(Me.Width / 2), Int(962 / 2) - Int(Me.Height / 2))
txtUsername.Value = ""
txtPassword.Value = ""
Exit Sub
ErrorHandler:
     Call CBTrace(CBTRACEF_ALWAYS, "FRMLogOn", "UserForm_Initialize", Err.Description)
End Sub

Private Sub btnCancel_Click()
Unload Me
End Sub

Private Sub btnOk_Click()
On Error GoTo ErrorHandler
Dim bLogOn As Boolean
Dim bRetLogOn As Boolean
If txtUsername.Value <> "" And txtPassword.Value <> "" Then
    
    bLogOn = MOD_LogOn.UserUnique(txtUsername.Value)
    If bLogOn = False Then '* User Not Logged in anywher
        If CorrectUser(txtUsername.Value) = True Then
            bRetLogOn = ThisProject.LogonUser(False, txtUsername.Value, txtPassword.Value)
            If bRetLogOn = True Then '* User login is GOOD one
                MOD_LogOn.LogonusingKey
                '* Configure Territories
                Unload Me
            End If
        Else
            '* User is not Authorized for Current WKS
            MsgBox "User " & txtUsername.Value & " is not Authorized to Log in WorkStation " & ThisSystem.ComputerName, vbInformation, "User Login Error"
            Unload Me
        End If
    Else
        MsgBox "User " & txtUsername.Value & " is already logged in WorkStation " & ThisProject.strWKSName, vbInformation, "User Login Error"
        Unload Me
    End If
Else
'* Msg Wrong password
MsgBox "Please enter a UserName and Password ", vbInformation, "User Login Error"
Unload Me
End If

Exit Sub
ErrorHandler:
     Call CBTrace(CBTRACEF_ALWAYS, "FRMLogOn", "btnOk_Click", Err.Description)
End Sub

