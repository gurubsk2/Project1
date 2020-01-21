using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration.Install;
using System.ComponentModel;
using System.Diagnostics;
using System.Xml;
using ICSharpCode.SharpZipLib.Zip;
using Microsoft.Win32;
using System.IO;

namespace IconisUtilities
{
    public partial class IconisAnalyzer : Installer
    {

        protected static System.IO.DirectoryInfo m_InstallFolder = null;
        protected static System.IO.DirectoryInfo m_ConfFolder = null;

        protected static System.IO.DirectoryInfo m_TracesDirectory = null;
        protected static System.IO.DirectoryInfo m_RecorderDirectory = null;
        
        private static System.IO.DirectoryInfo m_DataPrepComponant = null;
        private static System.IO.DirectoryInfo m_DataPrepCommon = null;
        private static System.IO.DirectoryInfo m_DataPrepByComputer = null;
        
        protected static String sSymbols = null;
        protected static String sPath = null;

        private static String sType = null;
        private static String sComponant = null;

        private static String sModule;
        private static bool bOPCServer = false;

        private static bool bDataprepMode = false;
        private static bool bRunTimeMode = false;

        public bool getRunTimeMode()
        {
            return bRunTimeMode;
        }

        public bool getDataprepMode()
        {
            return bDataprepMode;
        }

        public void Error(String sReason)
        {
            eventStore.WriteEntry(sReason, EventLogEntryType.Error);
        }

        public void Info(String sReason)
        {
            eventStore.WriteEntry(sReason, EventLogEntryType.Information);
        }

       

        public IconisAnalyzer()
        {
            InitializeComponent();
            
        }

        public void initIconisAnalyzer()
        {

            if (base.Context.Parameters.ContainsKey("Type"))
            {
                sType = base.Context.Parameters["Type"].ToUpper();
            }
            else
            {
                sType = String.Empty;
            } 

            if (base.Context.Parameters.ContainsKey("ComposantName"))
            {
                sComponant = base.Context.Parameters["ComposantName"];
                this.eventStore.Source = sComponant;
            }
            else
            {
                sComponant = String.Empty;
            }
                   

            string sdataprep = string.Empty;
            string sdataprepcheck = string.Empty;
            
            if (base.Context.Parameters.ContainsKey("DATAPREP"))
            {
                sdataprep = base.Context.Parameters["DATAPREP"].ToUpper();
            }
            else
            {
                sdataprep = string.Empty;
            }

            if (base.Context.Parameters.ContainsKey("DC"))
            {
                sdataprepcheck = base.Context.Parameters["DC"].ToUpper();
            }
            else
            {
                sdataprepcheck = string.Empty;
            }


            if (!sdataprep.Equals("") || sdataprepcheck.Equals("1"))
            {
                bDataprepMode = true;
            }
           
            string sruntime = string.Empty;
            string sruntimecheck = string.Empty;

            if (base.Context.Parameters.ContainsKey("RUNTIME"))
            {
                sruntime = base.Context.Parameters["RUNTIME"].ToUpper();
            }
            else
            {
                sruntime = string.Empty;
            }

            if (base.Context.Parameters.ContainsKey("RC"))
            {
                sruntimecheck = base.Context.Parameters["RC"].ToUpper();
            }
            else
            {
                sruntimecheck = string.Empty;
            }
            if (!sruntime.Equals("") || sruntimecheck.Equals("1"))
            {
                bRunTimeMode = true;
            }
            
            if (base.Context.Parameters.ContainsKey("Module"))
            {
                sModule = base.Context.Parameters["Module"];
            }
            else
            {
                sModule = String.Empty;
            }

            string sModuleCheck = string.Empty;
            if (base.Context.Parameters.ContainsKey("MC"))
            {
                sModuleCheck = base.Context.Parameters["MC"];
                if (sModuleCheck != string.Empty)
                {
                    sModule = sModuleCheck;
                }
            }
            

            string sOPC = string.Empty;

            if (base.Context.Parameters.ContainsKey("OPC"))
            {
                sOPC = base.Context.Parameters["OPC"];
                if (sOPC != null || sOPC != String.Empty)
                {
                    bOPCServer = true;
                }
            }
            
            
            m_DataPrepComponant = new System.IO.DirectoryInfo(@"D:\Dataprep\OUTPUT\" + sComponant);
            m_DataPrepCommon = new System.IO.DirectoryInfo(@"D:\Dataprep\OUTPUT\" + sComponant + @"\Common");
            m_DataPrepByComputer = new System.IO.DirectoryInfo(@"D:\Dataprep\OUTPUT\" + sComponant + @"\ByComputer");

            if (sType.Equals("SVR"))
            {
                m_InstallFolder = new System.IO.DirectoryInfo(@"D:\IconisTM4");
                m_ConfFolder = new System.IO.DirectoryInfo(@"D:\IconisTM4\IconisAppl");
                sSymbols = m_InstallFolder.FullName + @"\Symbols";
                sPath = m_InstallFolder.FullName + @"\IconisBin";
            }

            if (sType.Equals("FEP"))
            {
                m_InstallFolder = new System.IO.DirectoryInfo(@"D:\IconisFEP");
                m_ConfFolder = new System.IO.DirectoryInfo(@"D:\IconisFEP\FEPAppl");
                m_TracesDirectory = new System.IO.DirectoryInfo(@"D:\IconisFEP\Log\Traces");
                m_RecorderDirectory = new System.IO.DirectoryInfo(@"D:\IconisFEP\Log\Recorder");
                sSymbols = m_InstallFolder.FullName + @"\Symbols";
                sPath = m_InstallFolder.FullName + @"\FEPBin";
            }
        }


        protected override void OnBeforeRollback(System.Collections.IDictionary savedState)
        {

            initIconisAnalyzer(); 
            
            Info("Enter OnBeforeRollback " + sComponant);

            Info("End OnBeforeRollback " + sComponant);

            base.OnBeforeRollback(savedState);
        }


        protected override void OnAfterInstall(System.Collections.IDictionary savedState)
        {
            initIconisAnalyzer(); 
            
            Info("Enter OnAfterInstall " + sComponant);

            base.OnAfterInstall(savedState);

            if (bDataprepMode)
            {
                Info("Enter DataprepMode onAfterInstall " + sComponant);
                switch (sType)
                {
                    case "SVR":
                        UpdateIMCConf();
                        
                        UpdateIDCConf();
                        break;

                    case "FEP":
                        UpdateIMCConf();
                        break;

                    default:
                        break;
                }
                Info("End DataprepMode onAfterInstall " + sComponant);
            }

            if (bRunTimeMode)
            {
                Info("Enter RunTimeMode onAfterInstall " + sComponant);
                
                switch (sType)
                {
                    case "SVR": 
                        CopyFromDataprep();

                        AddEnvironmentVariable();
                        break;
                    case "FEP":   
                        CopyFromDataprep();

                        AddEnvironmentVariable();
                        if (sModule != null || sModule != String.Empty)
                        {
                            string[] listModule = sModule.Split(',');
                            foreach (string module in listModule)
                            {
                                if (!module.Equals(""))
                                {
                                    InstallModule(module, bOPCServer);
                                }
                            }
                        }
                        break;
                    default:
                        break;

                }
                Info("End RunTimeMode onAfterInstall " + sComponant);
            }

            Info("End OnAfterInstall " + sComponant);
        }

        public void UpdateIMCConf()
        {
            Info("Enter UpdateIMCConf " + sComponant);
            Info("End UpdateIMCConf " + sComponant);
        }

        public void UpdateIDCConf()
        {
            Info("Enter UpdateIDCConf " + sComponant);
            Info("End UpdateIDCConf " + sComponant);
        }

        protected override void OnBeforeUninstall(System.Collections.IDictionary savedState)
        {
            initIconisAnalyzer(); 
            
            Info("Enter OnBeforeUninstall " + sComponant);

            if (bRunTimeMode)
            {
                Info("Enter RunTimeMode OnBeforeUninstall " + sComponant);

                switch (sType)
                {
                    case "FEP":
                        if (sModule != null || sModule != String.Empty)
                        {
                            string[] listModule = sModule.Split(',');
                            foreach (string module in listModule)
                            {
                                if (!module.Equals(""))
                                {
                                    UnInstallModule(module);
                                }
                            }
                        }
                        break;
                    default:
                        break;

                }
                Info("End RunTimeMode OnBeforeUninstall " + sComponant);

            }

            Info("End OnBeforeUninstall " + sComponant);

            base.OnBeforeUninstall(savedState);

        }

        public void CopyFromDataprep()
        {
            Info("Enter CopyFromDataprep " + sComponant);

            CopyCommunData();
            CopyByComputerData(false);


            Info("End CopyFromDataprep " + sComponant);
            
        }

        public void CopyFromDataprepWithRename()
        {
            Info("Enter CopyFromDataprepWithRename " + sComponant);
            
            CopyCommunData();
            CopyByComputerData(true);

            Info("End CopyFromDataprepWithRename " + sComponant);

        }

        public void CopyCommunData()
        {
            try
            {
                if (m_DataPrepCommon.Exists == true)
                {
                    // Files generated by IDP
                    System.IO.FileInfo[] files = m_DataPrepCommon.GetFiles("*");

                    foreach (System.IO.FileInfo file in files)
                    {
                        if (m_ConfFolder.Exists == false)
                        {
                            System.IO.Directory.CreateDirectory(m_ConfFolder.FullName.ToString());
                        }
                        file.CopyTo(m_ConfFolder.FullName + "\\" + file.Name, true);
                    }
                }
            }
            catch
            {
                Error("ERROR: Catch exception during file copy.");
            }
        }

        public void CopyByComputerData(bool bRenaming)
        {
            try
            {
                if (m_DataPrepByComputer.Exists == true)
                {
                    // Files generated by IDP
                    System.IO.FileInfo[] files = m_DataPrepByComputer.GetFiles("*" + System.Environment.MachineName + "*");

                    foreach (System.IO.FileInfo file in files)
                    {
                        if (m_ConfFolder.Exists == false)
                        {
                            System.IO.Directory.CreateDirectory(m_ConfFolder.FullName.ToString());
                        }

                        String sFileName = file.Name;
                            
                        if (bRenaming)
                        {
                            int index = sFileName.IndexOf(System.Environment.MachineName);
                            if (index == 0)
                            {
                                sFileName = sFileName.Remove(index, System.Environment.MachineName.Length);
                            }
                            else if (index > 0)
                            {
                                sFileName = sFileName.Remove(index - 1, System.Environment.MachineName.Length + 1);
                            }
                        }
                        file.CopyTo(m_ConfFolder.FullName + "\\" + file.Name, true);
                    }
                }
            }
            catch
            {
                Error("ERROR: Catch exception during file copy.");
            }
        }

        public void AddEnvironmentVariable()
        {
            Info("Enter AddEnvironmentVariable " + sComponant);

            try
            {
                // Set Symbols Environment Variables
                string sSymbolPath = string.Empty;
                sSymbolPath = System.Environment.GetEnvironmentVariable("_NT_SYMBOL_PATH", EnvironmentVariableTarget.Machine);
                string sResultSymbolPath;
                try
                {
                    if (sSymbolPath == string.Empty)
                    {
                        sResultSymbolPath = sSymbols;
                    }
                    else if (sSymbolPath.Contains(sSymbols))
                    {
                        sResultSymbolPath = sSymbolPath;
                    }
                    else
                    {
                        sResultSymbolPath = sSymbolPath + ";" + sSymbols;
                    }
                }
                catch
                {
                    sResultSymbolPath = sSymbols;
                }

                System.Environment.SetEnvironmentVariable("_NT_SYMBOL_PATH", sResultSymbolPath, EnvironmentVariableTarget.Machine);

                // Set Iconis binaries Environment Variables
                sSymbolPath = string.Empty;
                sSymbolPath = System.Environment.GetEnvironmentVariable("Path", EnvironmentVariableTarget.Machine);

                try
                {
                    if (sSymbolPath == string.Empty)
                    {
                        sResultSymbolPath = sPath;
                    }
                    else if (sSymbolPath.Contains(sPath))
                    {
                        sResultSymbolPath = sSymbolPath;
                    }
                    else
                    {
                        sResultSymbolPath = sSymbolPath + ";" + sPath;
                    }
                }
                catch
                {
                    sResultSymbolPath = sPath;
                }

                System.Environment.SetEnvironmentVariable("Path", sResultSymbolPath, EnvironmentVariableTarget.Machine);
            }
            catch
            {
                Error("ERROR: Catch exception during _NT_SYMBOL_PATH and Path environment set.");
            }

            Info("End AddEnvironmentVariable " + sComponant);



        }

        public void RemoveEnvironmentVariable()
        {
            Info("Enter RemoveEnvironmentVariable " + sComponant);
            // Remove Symbols Environment Variables
            try
            {
                String sSymbolPath = System.Environment.GetEnvironmentVariable("_NT_SYMBOL_PATH", EnvironmentVariableTarget.Machine);
            
                int index = sSymbolPath.IndexOf(sSymbols);
                String sResultSymbolPath = sSymbolPath;
                if (index == 0)
                {
                    sResultSymbolPath = sSymbolPath.Remove(index, sSymbols.Length);
                }
                else if (index > 0)
                {
                    sResultSymbolPath = sSymbolPath.Remove(index - 1, sSymbols.Length + 1);
                }
                System.Environment.SetEnvironmentVariable("_NT_SYMBOL_PATH", sResultSymbolPath, EnvironmentVariableTarget.Machine);
            }
            catch (Exception ex)
            {
                Error(ex.Message);
            }

            // Remove Path Environment Variables
            try
            {
                String sSymbolPath = System.Environment.GetEnvironmentVariable("Path", EnvironmentVariableTarget.Machine);
            
                int index = sSymbolPath.IndexOf(sPath);
                string sResultSymbolPath = sSymbolPath;
                if (index == 0)
                {
                    sResultSymbolPath = sSymbolPath.Remove(index, sPath.Length);
                }
                else if (index > 0)
                {
                    sResultSymbolPath = sSymbolPath.Remove(index - 1, sPath.Length + 1);
                }
                System.Environment.SetEnvironmentVariable("Path", sResultSymbolPath, EnvironmentVariableTarget.Machine);
            }
            catch (Exception ex)
            {
                Error(ex.Message);
            }

            Info("End RemoveEnvironmentVariable " + sComponant);
            
        }

        /*private void Clean()
        {
            // Find all IconisAppl files
            System.IO.FileInfo[] files = m_IconisApplDirectory.GetFiles("*");

            foreach (System.IO.FileInfo file in files)
            {
                file.Delete();
            }

            // Remove persistence sharing
            if (m_persistenceDir.Exists)
            {
                string arg = "share Persistence /delete";
                ProcessStartInfo processInfo = new ProcessStartInfo(@"net", arg);
                Process.Start(processInfo);
            }

            // Remove all cache file
            System.IO.FileInfo[] cachefiles = m_S2KBinDirectory.GetFiles("ApplicationLoadingCache*.CSLoading");

            foreach (System.IO.FileInfo file in cachefiles)
            {
                try
                {
                    file.Delete();
                }
                catch
                {
                }
            }

        }*/

        private void RegisterRegFile(string sArgs)
        {
            Info("Enter RegisterRegFile " + sArgs);
            System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(System.Environment.SystemDirectory + @"\regedt32.exe");
            procstart.Arguments = "/s " + sArgs;
            System.Diagnostics.Process proc = new System.Diagnostics.Process();
            proc.StartInfo = procstart;

            if (proc.Start() == false)
            {
                Error("Can not register " + sArgs);
            }
            else
            {
                try
                {
                    proc.WaitForExit();

                    int iReturnCode = proc.ExitCode;
                    if (iReturnCode != 0)
                    {
                        Error("ERROR4: RegisterRegFile failed for " + sArgs + " ErrCode " + iReturnCode);
                    }
                }
                catch
                {
                    Error("Catch exception: RegisterRegFile for " + sArgs);
                }

            }
            Info("Wait before exit RegisterRegFile " + sArgs);
            System.Threading.Thread.Sleep(1000);
            Info("Exit RegisterRegFile " + sArgs);
        }

        private void RegisterOPCHMI(string smodulename)
        {
            Info("Enter RegisterOPCHMI " + smodulename);
            System.Diagnostics.Process proc = new System.Diagnostics.Process();
            if (smodulename.ToLower().Contains("feprdd") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(sPath +@"\Redundancy_OPCServer.exe");
                procstart.Arguments = "-RegServer";
                proc.StartInfo = procstart;
            }
            else if (smodulename.ToLower().Contains("ascv") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(sPath + @"\ASCV_OPCServer.exe");
                procstart.Arguments = "-RegServer -" + smodulename;
                proc.StartInfo = procstart;
            }
            else if (smodulename.ToLower().Contains("atcu200") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(sPath + @"\ATC_OPCServer.exe");
                procstart.Arguments = "-RegServer -" + smodulename;
                proc.StartInfo = procstart;
            }
            else if (smodulename.ToLower().Contains("atcu300") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(sPath + @"\ATCShell.exe");
                procstart.Arguments = "-RegServer -" + smodulename;
                proc.StartInfo = procstart;
            }
            else if (smodulename.ToLower().Contains("hwmc") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(sPath + @"\HWMC_OPCServer.exe");
                procstart.Arguments = "-RegServer -" + smodulename;
                proc.StartInfo = procstart;
            }
            else // manage instance of rdd and OPCHMI on FEP computer
            {
                string newOPCHMIname = "OPCHMI";
                if (smodulename != null || smodulename!=string.Empty)
                {
                    newOPCHMIname = newOPCHMIname +"_" + smodulename;
                }
                newOPCHMIname = newOPCHMIname + ".exe";
                
                System.Diagnostics.ProcessStartInfo procstart=null;
                try
                {
                    File.Copy(Path.Combine(sPath, "OPCHMI.EXE"), Path.Combine(sPath + @"\" + newOPCHMIname), true);

                    if (File.Exists(Path.Combine(sPath + @"\" + newOPCHMIname)))
                    {
                        Info("New File Created :" + Path.Combine(sPath + @"\" + newOPCHMIname));
                    }
                    else
                    {
                        Error("Failed to copy the OPCHMI.EXE as " + sPath + @"\" + newOPCHMIname);
                    }
                }
                catch (Exception ex)
                {
                    Error(ex.Message + smodulename);
                    Error("Failed to copy the OPCHMI.EXE as " + sPath + @"\" + newOPCHMIname);
                    //procstart = new System.Diagnostics.ProcessStartInfo(sPath + @"\OPCHMI.EXE");                    
                }
                
                procstart = new System.Diagnostics.ProcessStartInfo(sPath + @"\" + newOPCHMIname);
                procstart.Arguments = "-RegServer -" + smodulename;
                proc.StartInfo = procstart;
            }

            if (proc.Start() == false)
            {
                Error("ERROR4: Cannot execute register command for " + smodulename);
            }
            else
            {
                try
                {
                    proc.WaitForExit();

                    int iReturnCode = proc.ExitCode;
                    if (iReturnCode != 0)
                    {
                        Error("ERROR4: Register failed for " + smodulename + " ErrCode " + iReturnCode);
                    }
                }
                catch
                {
                    Error("Catch exception: RegisterOPCHMI for " + smodulename);
                }
            }
           Info("Exit RegisterOPCHMI " + smodulename);

        }

        public void InstallModule(string smodulename, bool bIsOPCServer)
        {
            try
            {
                // Find registry file associated
                System.IO.FileInfo[] regfiles = m_ConfFolder.GetFiles(smodulename + "*.REG");

                foreach (System.IO.FileInfo reg in regfiles)
                {
                    RegisterRegFile(reg.FullName);
                }
            }
            catch
            {
                Error("Catch exception: Register key for " + smodulename);
            }

            
            
            try
            {
                if (bIsOPCServer == true)
                {
                    // Register OPC Server
                    RegisterOPCHMI(smodulename);
                }
            }
            catch
            {
                Error("Catch exception: Register OPC Server for " + smodulename);
            }


            try
            {
                // Create Directories
                m_TracesDirectory.CreateSubdirectory(smodulename);
                m_RecorderDirectory.CreateSubdirectory(smodulename);
            }
            catch
            {
                Error("Catch exception: create directories for " + smodulename);
            }
        }

        public void UnInstallModule(string smodulename)
        {
            UnRegisterOPCHMI(smodulename);
            UnRegisterRegFile(smodulename);
        }

        private void UnRegisterOPCHMI(string smodulename)
        {

            string newOPCHMIname = null;
            System.Diagnostics.Process proc = new System.Diagnostics.Process();
            if (smodulename.ToLower().Contains("feprdd") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(@"D:\IconisFEP\FEPBin\Redundancy_OPCServer.exe");
                procstart.Arguments = "-UnRegServer";
                proc.StartInfo = procstart;
            }
            else if (smodulename.ToLower().Contains("ascv") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(@"D:\IconisFEP\FEPBin\ASCV_OPCServer.exe");
                procstart.Arguments = "-UnRegServer -" + smodulename;
                proc.StartInfo = procstart;
            }
            else if (smodulename.ToLower().Contains("atcu200") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(@"D:\IconisFEP\FEPBin\ATC_OPCServer.exe");
                procstart.Arguments = "-UnRegServer -" + smodulename;
                proc.StartInfo = procstart;
            }
            else if (smodulename.ToLower().Contains("atcu300") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(@"D:\IconisFEP\FEPBin\ATCShell.exe");
                procstart.Arguments = "-UnRegServer -" + smodulename;
                proc.StartInfo = procstart;
            }
            else if (smodulename.ToLower().Contains("hwmc") == true)
            {
                System.Diagnostics.ProcessStartInfo procstart = new System.Diagnostics.ProcessStartInfo(@"D:\IconisFEP\FEPBin\HWMC_OPCServer.exe");
                procstart.Arguments = "-UnRegServer -" + smodulename;
                proc.StartInfo = procstart;
            }
            else
            {

                newOPCHMIname = "OPCHMI";
                if (smodulename != null || smodulename != string.Empty)
                {
                    newOPCHMIname = newOPCHMIname + "_" + smodulename;
                }
                newOPCHMIname = newOPCHMIname + ".exe";

                System.Diagnostics.ProcessStartInfo procstart = null;
                 
                
                Info("UnRegisterOPCHMI " +newOPCHMIname +" file");
                            
                procstart = new System.Diagnostics.ProcessStartInfo(@"D:\IconisFEP\FEPBin" + @"\" + newOPCHMIname);
                procstart.Arguments = "-UnRegServer -" + smodulename;
                proc.StartInfo = procstart;
            }

            if (proc.Start() == false)
            {
                Error("ERROR6: Cannot execute unregister command for " + smodulename);
            }
            else
            {
                try
                {
                    proc.WaitForExit();
                    int iReturnCode = proc.ExitCode;
                    if (iReturnCode != 0)
                    {
                        Error("ERROR6: Unregister failed for " + smodulename);
                    }
                    else
                    {

                        if (newOPCHMIname != "OPCHMI.exe") 
                        {
                            File.Delete(Path.Combine(@"D:\IconisFEP\FEPBin\" + newOPCHMIname));
                        }
                    }
                }
                catch(Exception ex)
                {
                    Info("Exception Messsage  :" + ex.Message);
                    Error("ERROR6: Unregister failed for " + smodulename);
                }
            }
        }

        private void UnRegisterRegFile(string smodulename)
        {
            try
            {
                Microsoft.Win32.RegistryKey keyuser = Microsoft.Win32.Registry.CurrentUser;
                if (keyuser == null) return;
                Microsoft.Win32.RegistryKey keysoft = keyuser.OpenSubKey("Software");
                if (keysoft == null) return;
                Microsoft.Win32.RegistryKey keyiconis = keysoft.OpenSubKey("Iconis", true);
                if (keyiconis == null) return;

                Microsoft.Win32.RegistryKey keyOpcServer;

                if (smodulename.ToLower().Contains("feprdd_") == false)
                {
                    Microsoft.Win32.RegistryKey keyGenericOpc = keyiconis.OpenSubKey("Iconis Generic OPC Server", true);
                    if (keyGenericOpc == null) return;

                    keyOpcServer = keyGenericOpc.OpenSubKey(smodulename, true);
                    if (keyOpcServer == null) return;
                }
                else
                {
                    Microsoft.Win32.RegistryKey keyGenericOpc = keyiconis.OpenSubKey("ATS FEP-REDUNDANCY-OPC Server", true);
                    if (keyGenericOpc == null) return;

                    keyOpcServer = keyGenericOpc.OpenSubKey("FEP_redundancy_configuration", true);
                    if (keyOpcServer == null) return;
                }

                string[] ValueNames = keyOpcServer.GetValueNames();

                foreach (string Value in ValueNames)
                {
                    if (Value.Equals("CLSID") == false)
                    {
                        keyOpcServer.DeleteValue(Value);
                    }
                }

            }
            catch
            {
            }
        }


        private void MergeFiles(System.IO.FileInfo FileSpecific, System.IO.FileInfo FileProduct, string Node, string NodeList, string FileDest)
        {
            if (FileSpecific.Exists && FileProduct.Exists)
            {
                XmlDocument docProduct = new XmlDocument();
                XmlDocument docSpecific = new XmlDocument();
                try
                {
                    docSpecific.Load(FileSpecific.FullName);
                }
                catch
                {
                    Error("Xml Load Error " + FileSpecific.FullName);
                    return;
                }
                try
                {
                    docProduct.Load(FileProduct.FullName);
                }
                catch
                {
                    Error("Xml Load Error " + FileProduct.FullName);
                    return;
                }

                try
                {
                    XmlNode xmlNode = docProduct.SelectSingleNode(Node);
                    XmlNodeList xmlNodeList = docSpecific.SelectNodes(NodeList);
                    foreach (XmlNode xmlFile in xmlNodeList)
                    {
                        try
                        {
                            Info("AppendChild");
                            XmlNode newBook = docProduct.ImportNode(xmlFile, true);
                            xmlNode.AppendChild(newBook);
                        }
                        catch (Exception ex)
                        {
                            Error("Xml SelectSingleNode1 Error " + ex.ToString());
                        }
                        try
                        {
                            docProduct.Save(FileDest);
                        }
                        catch
                        {
                            Error("Xml save Error");
                        }
                    }
                }
                catch
                {
                    Error("Xml SelectSingleNode Error");
                    return;
                }
                
            }
            else
            {
                Error("Xml Files not found " + FileProduct.FullName + " " + FileSpecific.FullName);
            }
        }

        public void UnZipFiles(string zipPathAndFile, string outputFolder)
        {
            Info("Begin UnZipFiles " + zipPathAndFile + " - " + outputFolder);

            ZipInputStream s = new ZipInputStream(File.OpenRead(zipPathAndFile));
            ZipEntry theEntry;
            string tmpEntry = String.Empty;
            while ((theEntry = s.GetNextEntry()) != null)
            {
                string directoryName = outputFolder;
                string fileName = Path.GetFileName(theEntry.Name);
                // create directory 
                if (directoryName != "")
                {
                    Directory.CreateDirectory(directoryName);
                }
                if (fileName != String.Empty)
                {
                    string fullPath = directoryName + "\\" + theEntry.Name;
                    fullPath = fullPath.Replace("\\ ", "\\");
                    string fullDirPath = Path.GetDirectoryName(fullPath);
                    if (!Directory.Exists(fullDirPath))
                    {
                        Directory.CreateDirectory(fullDirPath);
                    }

                    FileStream streamWriter = File.Create(fullPath);
                    int size = 2048;
                    byte[] data = new byte[2048];
                    while (true)
                    {
                        try
                        {
                            size = s.Read(data, 0, data.Length);
                        }
                        catch
                        {
                            break;
                        }
                        if (size > 0)
                        {
                            streamWriter.Write(data, 0, size);
                        }
                        else
                        {
                            break;
                        }
                    }
                    streamWriter.Close();
                }
            }
            s.Close();

            Info("End UnZipFiles " + zipPathAndFile + " - " + outputFolder);
        }

        /// <summary>
        /// Remove all the files that were uncompressed from a ZIP archive.
        /// After this operation, remove all the folders left empty.
        /// </summary>
        /// <param name="zipPathAndFile">Path to the ZIP archive</param>
        /// <param name="outputFolder">Where the files were unzipped</param>
        public void UninstallZipFiles(string zipPathAndFile, string outputFolder)
        {
            Info("Begin uninstallation of zip files " + zipPathAndFile + " - " + outputFolder);

            ZipInputStream s;
            ZipEntry theEntry;

            // Browse the ZIP archive to enumerate the files to remove
            s = new ZipInputStream(File.OpenRead(zipPathAndFile));
            while ((theEntry = s.GetNextEntry()) != null)
            {
                string directoryName = outputFolder;
                string fileName = Path.GetFileName(theEntry.Name);

                if (fileName != String.Empty)
                {
                    string fullPath = directoryName + "\\" + theEntry.Name;
                    fullPath = fullPath.Replace("\\ ", "\\");
                    string fullDirPath = Path.GetDirectoryName(fullPath);

                    // Remove the file
                    try
                    {
                        File.Delete(fullPath);
                    }
                    catch
                    {
                        // Not logged because the capacity of the event store is limited
                    }

                }
            }
            s.Close();

            // Reopen the ZIP archive to clean all the empty directories
            s = new ZipInputStream(File.OpenRead(zipPathAndFile));
            while ((theEntry = s.GetNextEntry()) != null)
            {
                string directoryName = outputFolder;
                string fileName = Path.GetFileName(theEntry.Name);

                if (fileName != String.Empty)
                {
                    string fullPath = directoryName + "\\" + theEntry.Name;
                    fullPath = fullPath.Replace("\\ ", "\\");
                    string fullDirPath = Path.GetDirectoryName(fullPath);

                    try
                    {
                        if (IsDirectoryEmpty(fullDirPath))
                            Directory.Delete(fullDirPath);
                    }
                    catch
                    {
                        // Not logged because the capacity of the event store is limited
                    }
                }
            }
            s.Close();

            Info("End uninstallation of zip files");
        }

        /// <summary>
        /// Returns whether a directory is empty (i.e. contains no files and no subdirectories)
        /// </summary>
        /// <param name="path">Path</param>
        /// <returns>true if empty directory</returns>
        public bool IsDirectoryEmpty(string path)
        {
            string[] dirs = Directory.GetDirectories(path);
            string[] files = Directory.GetFiles(path);

            return (dirs.Length == 0 && files.Length == 0);
        }

        private void eventStore_EntryWritten(object sender, EntryWrittenEventArgs e)
        {

        }

    }


}
