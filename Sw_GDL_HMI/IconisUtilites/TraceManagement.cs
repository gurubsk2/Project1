using System;
using System.IO;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace IconisUtilities
{
    sealed public class MiniDumper
    {
        [Flags]
        public enum Typ : uint
        {
            // From dbghelp.h:
            MiniDumpNormal = 0x00000000,
            MiniDumpWithDataSegs = 0x00000001,
            MiniDumpWithFullMemory = 0x00000002,
            MiniDumpWithHandleData = 0x00000004,
            MiniDumpFilterMemory = 0x00000008,
            MiniDumpScanMemory = 0x00000010,
            MiniDumpWithUnloadedModules = 0x00000020,
            MiniDumpWithIndirectlyReferencedMemory = 0x00000040,
            MiniDumpFilterModulePaths = 0x00000080,
            MiniDumpWithProcessThreadData = 0x00000100,
            MiniDumpWithPrivateReadWriteMemory = 0x00000200,
            MiniDumpWithoutOptionalData = 0x00000400,
            MiniDumpWithFullMemoryInfo = 0x00000800,
            MiniDumpWithThreadInfo = 0x00001000,
            MiniDumpWithCodeSegs = 0x00002000,
            MiniDumpWithoutAuxiliaryState = 0x00004000,
            MiniDumpWithFullAuxiliaryState = 0x00008000,
            MiniDumpWithPrivateWriteCopyMemory = 0x00010000,
            MiniDumpIgnoreInaccessibleMemory = 0x00020000,
            MiniDumpValidTypeFlags = 0x0003ffff,
        };

        //typedef struct _MINIDUMP_EXCEPTION_INFORMATION {
        //    DWORD ThreadId;
        //    PEXCEPTION_POINTERS ExceptionPointers;
        //    BOOL ClientPointers;
        //} MINIDUMP_EXCEPTION_INFORMATION, *PMINIDUMP_EXCEPTION_INFORMATION;
        [StructLayout(LayoutKind.Sequential, Pack = 4)]  // Pack=4 is important! So it works also for x64!
        struct MiniDumpExceptionInformation
        {
            public uint ThreadId;
            public IntPtr ExceptioonPointers;
            [MarshalAs(UnmanagedType.Bool)]
            public bool ClientPointers;
        }

        //BOOL
        //WINAPI
        //MiniDumpWriteDump(
        //    __in HANDLE hProcess,
        //    __in DWORD ProcessId,
        //    __in HANDLE hFile,
        //    __in MINIDUMP_TYPE DumpType,
        //    __in_opt PMINIDUMP_EXCEPTION_INFORMATION ExceptionParam,
        //    __in_opt PMINIDUMP_USER_STREAM_INFORMATION UserStreamParam,
        //    __in_opt PMINIDUMP_CALLBACK_INFORMATION CallbackParam
        //    );
        [DllImport("dbghelp.dll",
          EntryPoint = "MiniDumpWriteDump",
          CallingConvention = CallingConvention.StdCall,
          CharSet = CharSet.Unicode,
          ExactSpelling = true, SetLastError = true)]
        static extern bool MiniDumpWriteDump(
          IntPtr hProcess,
          uint processId,
          IntPtr hFile,
          uint dumpType,
          ref MiniDumpExceptionInformation expParam,
          IntPtr userStreamParam,
          IntPtr callbackParam);

        [DllImport("kernel32.dll", EntryPoint = "GetCurrentThreadId", ExactSpelling = true)]
        static extern uint GetCurrentThreadId();

        [DllImport("kernel32.dll", EntryPoint = "GetCurrentProcess", ExactSpelling = true)]
        static extern IntPtr GetCurrentProcess();

        [DllImport("kernel32.dll", EntryPoint = "GetCurrentProcessId", ExactSpelling = true)]
        static extern uint GetCurrentProcessId();

        public static bool Write(string fileName)
        {
            return Write(fileName, Typ.MiniDumpWithFullMemory);
        }
        public static bool Write(string fileName, Typ dumpTyp)
        {
            using (System.IO.FileStream fs = new System.IO.FileStream(fileName, System.IO.FileMode.Create, System.IO.FileAccess.Write, System.IO.FileShare.None))
            {
                MiniDumpExceptionInformation exp;
                exp.ThreadId = GetCurrentThreadId();
                exp.ClientPointers = false;
                exp.ExceptioonPointers = System.Runtime.InteropServices.Marshal.GetExceptionPointers();
                bool bRet = MiniDumpWriteDump(
                  GetCurrentProcess(),
                  GetCurrentProcessId(),
                  fs.SafeFileHandle.DangerousGetHandle(),
                  (uint)dumpTyp,
                  ref exp,
                  IntPtr.Zero,
                  IntPtr.Zero);
                return bRet;
            }
        }
    }
    
    /// <summary>
    /// Class used to write an ICONIS trace file, this is a trace Listener
    /// It provides mechanism to limit the number of lines in a trace file
    /// and automatically change file when the current one is full
    /// </summary>
    public class IconisTextWriterTraceListener : TextWriterTraceListener
    {
        // 
        private string m_strTraceDirectory;
        private string m_strComponentName;
        private long m_lCurrentFileNumber;
        private long m_lCurrentNbOfLines = 0;

        const string strFormatDate = "MM/dd HH:mm:ss.";

        // max number of lines
        private long m_MaxNumberOfLines = 50000;
        //! Get or Set the max number of lines in the trace file
        public long MaxNumberOfLines
        {
            get
            {
                return MaxNumberOfLines;
            }
            set
            {
                m_MaxNumberOfLines = value;
            }
        }

        public IconisTextWriterTraceListener(string path, string strComponent)
        {
            m_strTraceDirectory = path;
            m_strComponentName = strComponent;
            m_lCurrentFileNumber = 1;

            string filename = GenerateFileName();
            string fileWithPath = Path.Combine(m_strTraceDirectory, filename);
            Writer = new StreamWriter(fileWithPath, true);

            WriteFileHeader();
        }

        //! Override of trace listener method to trace a line, use to count the number of lines and manage max size
        public override void WriteLine(string message)
        {   
            base.WriteLine(sDate + message);

            ++m_lCurrentNbOfLines;
            CheckFileMaxLength();
        }

        //! Simple override of base listener Write method
        public override void Write(string message)
        {
            base.Write(message);
        }

        /// <summary>
        /// Get the current Date with the right formatting
        /// </summary>
        private string sDate
        {
            get
            {
                return (DateTime.Now.ToString(strFormatDate) + DateTime.Now.Millisecond.ToString("D3"));
            }
        }

        /// <summary>
        /// Generate a new file name
        /// </summary>
        /// <returns>Name of the new file</returns>
        private string GenerateFileName()
        {
            const string format = "yyyy_MM_dd_HH_mm_ss";
            string filename = m_strComponentName + "_" + DateTime.Now.ToString(format) + "(" +
                m_lCurrentFileNumber.ToString("D5") + ").txt";

            return filename;
        }

        /// <summary>
        /// Check if current trace file has reached max size, if so get a new file
        /// to continue tracing
        /// </summary>
        private void CheckFileMaxLength()
        {
            if (m_lCurrentNbOfLines >= m_MaxNumberOfLines)
            {
                ChangeFile();
            }
        }

        /// Force to change trace file
        public void ChangeFile()
        {
            long oldNum = m_lCurrentFileNumber;
            ++m_lCurrentFileNumber;
            string filename = GenerateFileName();

            WriteFileFooter(oldNum, filename);

            string fileWithPath = Path.Combine(m_strTraceDirectory,filename);
            Writer.Close();
            Writer = new StreamWriter(fileWithPath, true);

            WriteFileHeader();

            m_lCurrentNbOfLines = 0;
        }

        /// <summary>
        /// Write the file header (always the same)
        /// </summary>
        private void WriteFileHeader()
        {
            // TODO
        }

        /// <summary>
        /// Write the end of a trace file (indicating next file name)
        /// </summary>
        private void WriteFileFooter(long currentNumber, string nextFileName)
        {
            base.WriteLine("***** End of file number " + currentNumber.ToString("D5") + " *****");
            base.WriteLine("***** Next file is : " + nextFileName + " *****");
        }
    }

    public enum ICONISTraceType
    {
        ERROR = 0,
        WARNING = 1,
        DEBUG = 2,
        FUNCTIONAL = 4,
        PERFORMANCE = 8
    }

    public enum ICONISTraceLevel
    {
        LEVEL_1 = 1, // the less verbose
        LEVEL_2 = 2,
        LEVEL_3 = 3,
        LEVEL_4 = 4,
        LEVEL_5 = 5,
        LEVEL_6 = 6 // the most verbose
    }

    /// <summary>
    /// Class used to manage ICONIS trace Level
    /// </summary>
    public class IconisTraceSwitch
    {
        /// Selected traces (ERROR cannot be turned off)
        private ulong m_ActivatedTraceMask = 0;

        /// Selected trace level
        private ICONISTraceLevel m_SelectedTraceLevel = ICONISTraceLevel.LEVEL_1;

        /// Constructor
        public IconisTraceSwitch()
        {
            m_ActivatedTraceMask = 0;
            m_SelectedTraceLevel = ICONISTraceLevel.LEVEL_1;
        }

        /// Constructor
        public IconisTraceSwitch(ulong lMask, ICONISTraceLevel lvl)
        {
            m_ActivatedTraceMask = lMask;
            m_SelectedTraceLevel = lvl;
        }

        /// Set the activated trace types
        public void SetActivatedTraceTypes(ulong lTypeMask)
        {
            m_ActivatedTraceMask = lTypeMask;
        }

        /// Add a trace type
        public void ActivateTraceType(ICONISTraceType newType)
        {
            m_ActivatedTraceMask = (m_ActivatedTraceMask | ((ushort)newType));
        }

        /// Get activated trace types as a string
        public String GetActivatedTraceTypesAsString()
        {
            String str = "ERROR";
            if ((m_ActivatedTraceMask & ((ulong)ICONISTraceType.WARNING)) != 0)
                str += ";WARNING";
            if ((m_ActivatedTraceMask & ((ulong)ICONISTraceType.DEBUG)) != 0)
                str += ";DEBUG";
            if ((m_ActivatedTraceMask & ((ulong)ICONISTraceType.FUNCTIONAL)) != 0)
                str += ";FUNCTIONAL";
            if ((m_ActivatedTraceMask & ((ulong)ICONISTraceType.PERFORMANCE)) != 0)
                str += ";PERFORMANCE";

            return str;
        }

        /// Set the activated trace level
        public ICONISTraceLevel CurrentTraceLevel
        {
            get
            {
                return m_SelectedTraceLevel;
            }
            set
            {
                m_SelectedTraceLevel = value;
            }
        }

        ///check if a trace is activated
        public bool IsTraceable(ICONISTraceType type, ICONISTraceLevel lvl)
        {
            if (type == ICONISTraceType.ERROR)
                return true;

            if (lvl > m_SelectedTraceLevel)
                return false;

            if ((m_ActivatedTraceMask & ((ulong)type)) != 0)
                return true;

            return false;
        }
    }
}
