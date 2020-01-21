Attribute VB_Name = "Iconis_MOD_Win32API"
'* *******************************************************************************************
'* Copyright, ALSTOM Transport Information Solutions, 2009. All Rights Reserved.
'* The software is to be treated as confidential and it may not be copied, used or disclosed
'* to others unless authorised in writing by ALSTOM Transport Information Solutions.
'* *******************************************************************************************
'* Module:      Iconis_MOD_Win32API
'* *******************************************************************************************
'* Purpose:     Windows API services
'* *******************************************************************************************
'* Modification History:
'* Author:              Olivier Tayeg
'* Date:                November '09
'* Change:              All

'* Author:              Olivier Tayeg
'* Date:                September '10
'* Change:              CR ALPHA 199652
'*                      For the User Rights function, maximize the buffer to read big INI files

'* Author:              Olivier Tayeg
'* Date:                January '11
'* Change:              CR ALPHA 213810
'*                      For the Playback function, services to check if a process is running

'* Author:              Olivier Tayeg
'* Date:                April '11
'* Change:              CR ALPHA 218695
'*                      Services for the screen management

'* *******************************************************************************************
'* Ref:             1. REQUIREMENTS SPECIFICATION AND ARCHITECTURE DESCRIPTION(Y3-64 A428320)
'*                  2. OPERATIONAL HMI INTERFACE DESCRIPTION (Y3-64 A427846)
'* *******************************************************************************************

Option Explicit


'* *******************************************************************************************
' API for sound
'* *******************************************************************************************

' Flag values for uFlags parameter
Public Const SND_SYNC = &H0                '  play synchronously (default)
Public Const SND_ASYNC = &H1               '  play asynchronously
Public Const SND_NODEFAULT = &H2           '  silence not default, if sound not found
Public Const SND_MEMORY = &H4              '  lpszSoundName points to a memory file
Public Const SND_ALIAS = &H10000           '  name is a WIN.INI [sounds] entry
Public Const SND_FILENAME = &H20000        '  name is a file name
Public Const SND_RESOURCE = &H40004        '  name is a resource name or atom
Public Const SND_ALIAS_ID = &H110000       '  name is a WIN.INI [sounds] entry identifier
Public Const SND_ALIAS_START = 0           '  must be > 4096 to keep strings in same section of resource file
Public Const SND_LOOP = &H8                '  loop the sound until next sndPlaySound
Public Const SND_NOSTOP = &H10             '  don't stop any currently playing sound
Public Const SND_VALID = &H1F              '  valid flags          / ;Internal /
Public Const SND_NOWAIT = &H2000           '  don't wait if the driver is busy
Public Const SND_VALIDFLAGS = &H17201F     '  Set of valid flag bits.  Anything outside this range will raise an error
Public Const SND_RESERVED = &HFF000000     '  In particular these flags are reserved
Public Const SND_TYPE_MASK = &H170007

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::sndPlaySound
' Input:        lpszSoundName [String]  path to the file
'               uFlags [Long]         parameters (see list of flags SND_xxx)
' Output:       None.
' Description:  Play the sound file given in parameter
'-------------------------------------------------------------------------------
Public Declare Function sndPlaySound Lib "winmm.dll" Alias "sndPlaySoundA" (ByVal lpszSoundName As String, ByVal uFlags As Long) As Long

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::sndPlaySound
' Input:        None. Always use the default parameters.
' Output:       None.
' Description:  Mute the sound.
'-------------------------------------------------------------------------------
Public Declare Function sndMuteSound Lib "winmm.dll" Alias "sndPlaySoundA" (Optional ByVal lpszSoundName As Long = 0, Optional ByVal uFlags As Long = SND_FILENAME Or SND_ASYNC) As Long



'* *******************************************************************************************
' API Declarations for working with INI files (the .fvp and .fvl files are like INI files)
'* *******************************************************************************************

Private Declare Function GetPrivateProfileSection Lib "kernel32" Alias _
"GetPrivateProfileSectionA" (ByVal lpAppName As String, ByVal lpReturnedString As String, _
                             ByVal nSize As Long, ByVal lpFileName As String) As Long

Private Declare Function GetPrivateProfileString Lib "kernel32" Alias _
"GetPrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, _
                            ByVal lpDefault As String, ByVal lpReturnedString As String, ByVal nSize As Long, _
                            ByVal lpFileName As String) As Long

Private Declare Function WritePrivateProfileSection Lib "kernel32" Alias _
"WritePrivateProfileSectionA" (ByVal lpAppName As String, ByVal lpString As String, _
                               ByVal lpFileName As String) As Long

Private Declare Function WritePrivateProfileString Lib "kernel32" Alias _
"WritePrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, _
                              ByVal lpString As Any, ByVal lpFileName As String) As Long



' API Declarations for working with the Windows Registry
Public Const REG_SZ As Long = 1
Public Const REG_DWORD As Long = 4

Public Const HKEY_CLASSES_ROOT = &H80000000
Public Const HKEY_CURRENT_USER = &H80000001
Public Const HKEY_LOCAL_MACHINE = &H80000002
Public Const HKEY_USERS = &H80000003

Public Const ERROR_NONE = 0
Public Const ERROR_BADDB = 1
Public Const ERROR_BADKEY = 2
Public Const ERROR_CANTOPEN = 3
Public Const ERROR_CANTREAD = 4
Public Const ERROR_CANTWRITE = 5
Public Const ERROR_OUTOFMEMORY = 6
Public Const ERROR_ARENA_TRASHED = 7
Public Const ERROR_ACCESS_DENIED = 8
Public Const ERROR_INVALID_PARAMETERS = 87
Public Const ERROR_NO_MORE_ITEMS = 259

Public Const KEY_QUERY_VALUE = &H1
Public Const KEY_SET_VALUE = &H2
Public Const KEY_ALL_ACCESS = &H3F

Public Const REG_OPTION_NON_VOLATILE = 0

Private Declare Function RegCloseKey Lib "advapi32.dll" _
(ByVal hKey As Long) As Long
Private Declare Function RegCreateKeyEx Lib "advapi32.dll" Alias _
    "RegCreateKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, _
                       ByVal Reserved As Long, ByVal lpClass As String, ByVal dwOptions _
                       As Long, ByVal samDesired As Long, ByVal lpSecurityAttributes _
                       As Long, phkResult As Long, lpdwDisposition As Long) As Long
Private Declare Function RegOpenKeyEx Lib "advapi32.dll" Alias _
    "RegOpenKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, _
                     ByVal ulOptions As Long, ByVal samDesired As Long, phkResult As _
                     Long) As Long
Private Declare Function RegQueryValueExString Lib "advapi32.dll" Alias _
    "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As _
                        String, ByVal lpReserved As Long, lpType As Long, ByVal lpData _
                        As String, lpcbData As Long) As Long
Private Declare Function RegQueryValueExLong Lib "advapi32.dll" Alias _
    "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As _
                        String, ByVal lpReserved As Long, lpType As Long, lpData As _
                        Long, lpcbData As Long) As Long
Private Declare Function RegQueryValueExNULL Lib "advapi32.dll" Alias _
    "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As _
                        String, ByVal lpReserved As Long, lpType As Long, ByVal lpData _
                        As Long, lpcbData As Long) As Long
Private Declare Function RegSetValueExString Lib "advapi32.dll" Alias _
    "RegSetValueExA" (ByVal hKey As Long, ByVal lpValueName As String, _
                      ByVal Reserved As Long, ByVal dwType As Long, ByVal lpValue As _
                      String, ByVal cbData As Long) As Long
Private Declare Function RegSetValueExLong Lib "advapi32.dll" Alias _
    "RegSetValueExA" (ByVal hKey As Long, ByVal lpValueName As String, _
                      ByVal Reserved As Long, ByVal dwType As Long, lpValue As Long, _
                      ByVal cbData As Long) As Long



'* *******************************************************************************************
' API Declarations for the command line parameters
'* *******************************************************************************************

Private Declare Function GetCommandLine Lib "kernel32" Alias "GetCommandLineA" () As Long
Private Declare Function lstrlen Lib "kernel32" Alias "lstrlenA" (ByVal lpString As Long) As Long
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (pDst As Any, pSrc As Any, ByVal ByteLen As Long)

'* *******************************************************************************************
' API Declarations to manage time zones
'* *******************************************************************************************

Public Type FILETIME
    dwLowDateTime As Long
    dwHighDateTime As Long
End Type
Public Type SYSTEMTIME
    wYear As Integer
    wMonth As Integer
    wDayOfWeek As Integer
    wDay As Integer
    wHour As Integer
    wMinute As Integer
    wSecond As Integer
    wMilliseconds As Integer
End Type


Public Type TIME_ZONE_INFORMATION
    Bias As Long
    StandardName(0 To 31) As Integer
    StandardDate As SYSTEMTIME
    StandardBias As Long
    DaylightName(0 To 31) As Integer
    DaylightDate As SYSTEMTIME
    DaylightBias As Long
End Type

Private Declare Function FileTimeToLocalFileTime Lib "kernel32" (lpFileTime As FILETIME, lpLocalFileTime As FILETIME) As Long
Private Declare Function LocalFileTimeToFileTime Lib "kernel32" (lpLocalFileTime As FILETIME, lpFileTime As FILETIME) As Long
Private Declare Function FileTimeToSystemTime Lib "kernel32" (lpFileTime As FILETIME, lpSystemTime As SYSTEMTIME) As Long
Private Declare Function SystemTimeToFileTime Lib "kernel32" (lpSystemTime As SYSTEMTIME, lpFileTime As FILETIME) As Long
Private Declare Function GetTimeZoneInformation Lib "kernel32" (lpTimeZoneInformation As TIME_ZONE_INFORMATION) As Long


'* *******************************************************************************************
' API Declarations to manage running processes
'* *******************************************************************************************

Private Declare Function WaitForSingleObject Lib "kernel32" ( _
    ByVal hHandle As Long, _
    ByVal dwMilliseconds As Long) As Long
Private Declare Function OpenProcess Lib "kernel32.dll" ( _
    ByVal dwDesiredAccess As Long, _
    ByVal bInheritHandle As Long, _
    ByVal dwProcessId As Long) As Long
Private Declare Function CloseHandle Lib "kernel32" ( _
    ByVal hObject As Long) As Long

Private Declare Function EnumProcesses Lib "PSAPI.DLL" ( _
   lpidProcess As Long, _
   ByVal cb As Long, _
   cbNeeded As Long) As Long
Private Declare Function EnumProcessModules Lib "PSAPI.DLL" ( _
    ByVal hProcess As Long, _
    lphModule As Long, _
    ByVal cb As Long, _
    lpcbNeeded As Long) As Long
Private Declare Function GetModuleBaseName Lib "PSAPI.DLL" Alias "GetModuleBaseNameA" ( _
    ByVal hProcess As Long, _
    ByVal hModule As Long, _
    ByVal lpFileName As String, _
    ByVal nSize As Long) As Long

Private Const PROCESS_VM_READ = &H10
Private Const PROCESS_QUERY_INFORMATION = &H400

Private Const SYNCHRONIZE = &H100000


'* *******************************************************************************************
' API Declarations to manage the screen
'* *******************************************************************************************
Private Declare Function GetSystemMetrics Lib "user32.dll" (ByVal nIndex As Long) As Long
Const SM_CXSCREEN = 0
Const SM_CYSCREEN = 1
 

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::RegSetValueAsVariant
' Input:        lhKey [Long]        Handle to the key
'               sValueName [String] Name of the value
'               lType [Long]        Type of the value
'               vValue [Variant]    Value to set
' Output:       [Long]              0 in case of a success
' Description:  Wrapper for the API functions RegSetValueEx{String|Long}.
'               Handles only the types 'String' and 'DWORD'
'-------------------------------------------------------------------------------
Public Function RegSetValueAsVariant(ByVal hKey As Long, sValueName As String, lType As Long, vValue As Variant) As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "RegSetValueAsVariant", "Begin Subroutine")
    
    Dim lValue As Long
    Dim sValue As String
    
    Select Case lType
        Case REG_SZ
            sValue = vValue & Chr$(0)
            RegSetValueAsVariant = RegSetValueExString(hKey, sValueName, 0&, lType, sValue, Len(sValue))
        Case REG_DWORD
            lValue = vValue
            RegSetValueAsVariant = RegSetValueExLong(hKey, sValueName, 0&, lType, lValue, 4)
    End Select

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "RegSetValueAsVariant", Err.Description)
End Function


'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::RegQueryValueAsVariant
' Input:        lhKey [Long]        Handle to the key
'               sValueName [String] Name of the value to find
' Output:       vValue [Variant]    Value corresponding to the key,value
'               [Long]              0 in case of a success
' Description:  Wrapper for the API functions RegQueryValueEx{String|Long}.
'               Handles only the types 'String' and 'DWORD'
'-------------------------------------------------------------------------------
Public Function RegQueryValueAsVariant(ByVal lhKey As Long, ByVal szValueName As String, vValue As Variant) As Long
On Error GoTo QueryValueExError
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "RegQueryValueAsVariant", "Begin Subroutine")
    
    Dim cch As Long
    Dim lrc As Long
    Dim lType As Long
    Dim lValue As Long
    Dim sValue As String
    
    
    ' Determine the size and type of data to be read
    lrc = RegQueryValueExNULL(lhKey, szValueName, 0&, lType, 0&, cch)
    If lrc <> ERROR_NONE Then Error 5
    
    Select Case lType
        ' For strings
        Case REG_SZ
            sValue = String(cch, 0)
    
            lrc = RegQueryValueExString(lhKey, szValueName, 0&, lType, sValue, cch)
            If lrc = ERROR_NONE Then
                vValue = Left$(sValue, cch - 1)
            Else
                vValue = Empty
            End If
        
        ' For DWORDS
        Case REG_DWORD
            lrc = RegQueryValueExLong(lhKey, szValueName, 0&, lType, lValue, cch)
            If lrc = ERROR_NONE Then
                vValue = lValue
            End If
        
        ' All other data types not supported
        Case Else
            lrc = -1
    End Select

QueryValueExExit:
       RegQueryValueAsVariant = lrc
       Exit Function

QueryValueExError:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "RegQueryValueAsVariant", Err.Description)
    Resume QueryValueExExit
End Function



'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::WindowsRegistry_QueryValue
' Input:        lPlace [Long]       e.g. HKEY_CLASSES_ROOT, HKEY_CLASSES_USER
'               sKeyName [String]   Name of the key
'               sValueName [String] Name of the value to find
' Output:       [Variant]           Value corresponding to the key,value
' Description:  Find a value in the Registry
'-------------------------------------------------------------------------------
Public Function WindowsRegistry_QueryValue(lPlace As Long, sKeyName As String, sValueName As String) As Variant
    Dim lRetVal As Long         'result of the API functions
    Dim hKey As Long         'handle of opened key
    Dim vValue As Variant      'setting of queried value

    lRetVal = RegOpenKeyEx(lPlace, sKeyName, 0, _
    KEY_QUERY_VALUE, hKey)
    lRetVal = RegQueryValueAsVariant(hKey, sValueName, vValue)
    RegCloseKey (hKey)
    WindowsRegistry_QueryValue = vValue
End Function



'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::FileExists
' Input:        strFilename   path to the file
' Output:       boolean       to indicate the existence of the file
' Description:  Check for the existence of a file.
'               The file may be hidden or system.
'-------------------------------------------------------------------------------
Public Function FileExists(strFilename As String) As Boolean
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "FileExists", "Begin Subroutine")
    
    FileExists = Dir$(strFilename, vbReadOnly Or vbHidden Or vbSystem) <> ""

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "FileExists", Err.Description)
End Function

'-------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::FileCheckWriteAccessRights
' Input:        strFilename [String] path to the file
' Output:       none
' Description:  Remove the eventual read-only attribute on the file
'-------------------------------------------------------------------------------
Public Function FileCheckWriteAccessRights(strFilename As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "FileCheckWriteAccessRights", "Begin Subroutine")
    
    Dim lAttr As Long
    
    lAttr = GetAttr(strFilename)
    If lAttr And vbReadOnly Then
        SetAttr strFilename, lAttr And Not vbReadOnly
    End If

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "FileCheckWriteAccessRights", Err.Description)
End Function


'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::Ini_Read
' Input:        strFilename [String]   Name of the INI file
'               strSection [String]    Name of the section
'               strKey [String]        Name of the key
' Output:       [String]               Value corresponding to the key
' Description:  Read a value from an INI file
'---------------------------------------------------------------------------------------
Public Function Ini_Read(strFilename As String, strSection As String, strKey As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "Ini_Read", "Begin Subroutine")
    
    Dim RetVal As String * 65526
    Dim v As Long
    v = GetPrivateProfileString(strSection, strKey, "", RetVal, 65526, strFilename)
    Ini_Read = Left(RetVal, v)

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "Ini_Read", Err.Description)
End Function

'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::Ini_ReadSection
' Input:        strFilename [String]   Name of the INI file
'               strSection [String]    Name of the section
' Output:       [String]               Value corresponding to the section
' Description:  Read a whole section from an INI file
'---------------------------------------------------------------------------------------
Public Function Ini_ReadSection(strFilename As String, strSection As String) As String
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "Ini_ReadSection", "Begin Subroutine")
    
    Dim RetVal As String * 65526
    Dim v As Long
    v = GetPrivateProfileSection(strSection, RetVal, 65526, strFilename)
    Ini_ReadSection = Left(RetVal, v)

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "Ini_ReadSection", Err.Description)
End Function

'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::Ini_Write
' Input:        strFilename [String]   Name of the INI file
'               strSection [String]    Name of the section
'               strKey [String]        Name of the key
'               strValue [String]      Value to write into the key
' Output:       none
' Description:  Write a value to an INI file
'---------------------------------------------------------------------------------------
Public Sub Ini_Write(strFilename As String, strSection As String, strKey As String, strValue As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "Ini_Write", "Begin Subroutine")
    
    WritePrivateProfileString strSection, strKey, strValue, strFilename

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "Ini_Write", Err.Description)
End Sub

'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::Ini_WriteSection
' Input:        strFilename [String]   Name of the INI file
'               strSection [String]    Name of the section
'               strValue [String]      Section to write
' Output:       none
' Description:  Write a whole section into an INI file
'---------------------------------------------------------------------------------------
Public Sub Ini_WriteSection(strFilename As String, strSection As String, strValue As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "Ini_WriteSection", "Begin Subroutine")
    
    WritePrivateProfileSection strSection, strValue, strFilename

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "Ini_WriteSection", Err.Description)
End Sub



'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::GetCommandLineString
' Input:        none
' Output:       @return [String]    command line
' Description:  Return the command line parameters
'---------------------------------------------------------------------------------------
Private Function GetCommandLineString() As String

    Dim RetStr As Long
    Dim SLen As Long
    Dim Buffer As String

    'Get a pointer to a string, which contains the command line
    RetStr = GetCommandLine

    'Get the length of that string
    SLen = lstrlen(RetStr)

    If SLen > 0 Then
        'Create a buffer
        GetCommandLineString = Space$(SLen)
        'Copy to the buffer
        CopyMemory ByVal GetCommandLineString, ByVal RetStr, SLen
    End If

End Function



'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::GetCommandLineParameters
' Input:        none
' Output:       none
' Description:  Return an array containing the command line parameters
'---------------------------------------------------------------------------------------
Public Function GetCommandLineParameters() As String()
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "GetCommandLineParameters", "Begin Subroutine")
    
    Dim I As Integer
    Dim lStart As Integer
    Dim strLine As String
    Dim arReturn() As String
    Dim lCount As Integer
    Dim sep As String
    
    strLine = GetCommandLineString

    lCount = 0
    ReDim arReturn(0)
    I = 1
    
    Do While I < Len(strLine)
        ' Find the first character that is not a blank
        Do
            sep = Mid(strLine, I, 1)
            I = I + 1
        Loop While I < Len(strLine) And sep = " "
        
        ' Now we want to find the next separator:
        ' a blank if the first character is not a quote (")
        ' else a quote
        If sep = """" Then
            ' Skip the quote
            lStart = I
        Else
            sep = " "
            lStart = I - 1
        End If

        ' Find the next separator
        I = InStr(lStart + 1, strLine, sep)
        ' Not found: pretend the separator is after the end of the string
        If I = 0 Then
            I = Len(strLine) + 1
        End If
        
        ' Make space in the return array
        If UBound(arReturn) < lCount Then
            ReDim Preserve arReturn(0 To lCount)
        End If

        ' Extract the parameter
        arReturn(lCount) = Trim(Mid(strLine, lStart, I - lStart))
        lCount = lCount + 1

        ' Go after the separator
        I = I + 1
    Loop

    GetCommandLineParameters = arReturn

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "GetCommandLineParameters", Err.Description)
End Function

'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::DateToSystemTime
' Input:        @param  the_date    [Date]          date (VB) to convert
'               @param  system_time [SYSTEMTIME]    container for the system date returned
' Output:       none
' Description:  Convert a Date into a SYSTEMTIME.
'---------------------------------------------------------------------------------------
Private Sub DateToSystemTime(ByVal the_date As Date, ByRef system_time As SYSTEMTIME)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "DateToSystemTime", "Begin Subroutine")

    With system_time
        .wYear = Year(the_date)
        .wMonth = Month(the_date)
        .wDay = Day(the_date)
        .wHour = Hour(the_date)
        .wMinute = Minute(the_date)
        .wSecond = Second(the_date)
    End With

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "DateToSystemTime", Err.Description)
End Sub

'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::DateToSystemTime
' Input:        @param  system_time [SYSTEMTIME]    system date to convert
'               @param  the_date    [Date]          date (VB) returned
' Output:       none
' Description:  Convert a SYSTEMTIME into a Date.
'---------------------------------------------------------------------------------------
Private Sub SystemTimeToDate(system_time As SYSTEMTIME, ByRef the_date As Date)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "SystemTimeToDate", "Begin Subroutine")

    With system_time
        the_date = DateSerial(.wYear, .wMonth, .wDay) + _
                   TimeSerial(.wHour, .wMinute, .wSecond)
    End With

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "SystemTimeToDate", Err.Description)
End Sub


'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::LocalTimeToUTC
' Input:        @param  the_date    [Date]          date in local time
' Output:       @return             [Date]          date translated to UTC
' Description:  Convert a local time to UTC.
'---------------------------------------------------------------------------------------
Public Function LocalTimeToUTC(ByVal the_date As Date) As Date
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "LocalTimeToUTC", "Begin Subroutine")

    Dim system_time As SYSTEMTIME
    Dim local_file_time As FILETIME
    Dim utc_file_time As FILETIME

    ' Convert into a SYSTEMTIME.
    DateToSystemTime the_date, system_time

    ' Convert to a FILETIME.
    SystemTimeToFileTime system_time, local_file_time

    ' Convert to a UTC time.
    LocalFileTimeToFileTime local_file_time, utc_file_time

    ' Convert to a SYSTEMTIME.
    FileTimeToSystemTime utc_file_time, system_time

    ' Convert to a Date.
    SystemTimeToDate system_time, the_date

    LocalTimeToUTC = the_date

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "LocalTimeToUTC", Err.Description)
End Function


'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::UTCToLocalTime
' Input:        @param  the_date    [Date]          date in UTC
' Output:       @return             [Date]          date translated to local time
' Description:  Convert a UTC time into local time.
'---------------------------------------------------------------------------------------
Public Function UTCToLocalTime(ByVal the_date As Date) As Date
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "UTCToLocalTime", "Begin Subroutine")
    
    Dim system_time As SYSTEMTIME
    Dim local_file_time As FILETIME
    Dim utc_file_time As FILETIME

    ' Convert into a SYSTEMTIME.
    DateToSystemTime the_date, system_time

    ' Convert to a UTC time.
    SystemTimeToFileTime system_time, utc_file_time

    ' Convert to a FILETIME.
    FileTimeToLocalFileTime utc_file_time, local_file_time

    ' Convert to a SYSTEMTIME.
    FileTimeToSystemTime local_file_time, system_time

    ' Convert to a Date.
    SystemTimeToDate system_time, the_date

    UTCToLocalTime = the_date

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "UTCToLocalTime", Err.Description)
End Function



'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::ShellAndWait
' Input:        @param  program_name [String]           path to the program to execute
'               @param  window_style [VbAppWinStyle]    style of the window
'               @param  lTimeout [Long]                 maximum time before the program is killed
' Output:       none
' Description:  Start the indicated program and wait for its exit within a timeout
'---------------------------------------------------------------------------------------
Public Sub ShellAndWait(ByVal program_name As String, Optional ByVal window_style As VbAppWinStyle = vbNormalFocus, Optional ByVal lTimeout As Long = 0)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "ShellAndWait", "Begin Subroutine")
    
    Dim process_id As Long
    Dim process_handle As Long

    ' Start the program.
    'If FileExists(program_name) Then
        Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "ShellAndWait", "Starting-up """ & program_name & """")
        process_id = Shell(program_name, window_style)
        ' Wait for the program to finish.
        process_handle = OpenProcess(SYNCHRONIZE, 0, process_id)
        If process_handle <> 0 Then
            WaitForSingleObject process_handle, lTimeout
            CloseHandle process_handle
        End If
    'Else
    '    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "ShellAndWait", "Error: The path """ & program_name & """ cannot be found")
    'End If


Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "ShellAndWait", "Failed to execute " & program_name & vbCrLf & Err.Description)
End Sub


'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::IsProcessRunning
' Input:        @param  sProcess [String]           name of the process to look for
' Output:       @return true if the process is running
'               @return false if the process is not running
' Description:  Finds out if a process given by name is running
'---------------------------------------------------------------------------------------
Public Function IsProcessRunning(ByVal sProcess As String) As Boolean
    Const MAX_PATH As Long = 260
    Dim lProcesses() As Long, lModules() As Long, N As Long, lRet As Long, hProcess As Long
    Dim sName As String
   
    sProcess = UCase$(sProcess)
   
    ReDim lProcesses(1023) As Long
    If EnumProcesses(lProcesses(0), 1024 * 4, lRet) Then
        For N = 0 To (lRet \ 4) - 1
            hProcess = OpenProcess(PROCESS_QUERY_INFORMATION Or PROCESS_VM_READ, 0, lProcesses(N))
            If hProcess Then
                ReDim lModules(1023)
                If EnumProcessModules(hProcess, lModules(0), 1024 * 4, lRet) Then
                    sName = String$(MAX_PATH, vbNullChar)
                    GetModuleBaseName hProcess, lModules(0), sName, MAX_PATH
                    sName = Left$(sName, InStr(sName, vbNullChar) - 1)
                    If Len(sName) = Len(sProcess) Then
                        If sProcess = UCase$(sName) Then IsProcessRunning = True: Exit Function
                    End If
                End If
            End If
            CloseHandle hProcess
        Next N
    End If
End Function


'-------------------------------------------------------------------------------
' Name:         touch
' Input:        sPath   [String]
' Output:       none
' Description:  Create an empty file
'-------------------------------------------------------------------------------
Public Sub touch(sPath As String)
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "touch", "Begin Subroutine")
    
    Dim iFilenumber As Integer
    iFilenumber = FreeFile()
    Open sPath For Output As iFilenumber
    Close iFilenumber

Exit Sub
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "touch", Err.Description)
End Sub


'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::GetHorizontalResolution
' Input:        none
' Output:       @return [Long] Resolution
' Description:  Finds out if a process given by name is running
'---------------------------------------------------------------------------------------
Public Function GetHorizontalResolution() As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "GetHorizontalResolution", "Begin Subroutine")
    
    GetHorizontalResolution = 0
    GetHorizontalResolution = GetSystemMetrics(SM_CXSCREEN)

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "GetHorizontalResolution", Err.Description)
End Function


'---------------------------------------------------------------------------------------
' Name:         Iconis_MOD_Win32API::GetVerticalResolution
' Input:        none
' Output:       @return [Long] Resolution
' Description:  Finds out if a process given by name is running
'---------------------------------------------------------------------------------------
Public Function GetVerticalResolution() As Long
On Error GoTo ErrorHandler
    Call CBTrace(CBTRACE_VBA, "Iconis_MOD_Win32API", "GetVerticalResolution", "Begin Subroutine")

   GetVerticalResolution = 0
   GetVerticalResolution = GetSystemMetrics(SM_CYSCREEN)

Exit Function
ErrorHandler:
    Call CBTrace(CBTRACEF_ALWAYS, "Iconis_MOD_Win32API", "GetVerticalResolution", Err.Description)
End Function

