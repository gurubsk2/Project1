using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using IconisUtilities;
using System.ComponentModel;
using System.IO;

namespace HMI_GDLAnalyser
{
    [RunInstaller(true)]
    public class HMI_GDLAnalyser : IconisAnalyzer
    {
        protected override void OnAfterInstall(System.Collections.IDictionary savedState)
        {
            base.OnAfterInstall(savedState);
            if (File.Exists(@"D:\IconisHMI\HMI_GDL.zip"))
            {
                UnZipFiles(@"D:\IconisHMI\HMI_GDL.zip", @"D:\IconisHMI");
                if (File.Exists(@"D:\IconisHMI\GDLShortcut.zip"))
                    UnZipFiles(@"D:\IconisHMI\GDLShortcut.zip", @"D:\IconisHMI\GDLshortcut");
            }
            if (File.Exists(@"D:\IconisHMI\Gudalajara_Videowall.zip"))
            {
                UnZipFiles(@"D:\IconisHMI\Gudalajara_Videowall.zip", @"D:\IconisHMI");
            }
            if (File.Exists(@"D:\IconisHMI\Gudalajara_VideowallShortcut.zip"))
            {
                UnZipFiles(@"D:\IconisHMI\Gudalajara_VideowallShortcut.zip", @"D:\IconisHMI\Gudalajara_VideowallShortcut");
            }

            if (Directory.Exists(@"D:\IconisHMI\HMI"))
            {
                Directory.Delete(@"D:\IconisHMI\HMI", true);
            }
            
            
            
            if (!System.IO.Directory.Exists(@"C:\ProgramData\Alstom\ICONIS\S2K\Client Builder\Settings"))
            {
                System.IO.Directory.CreateDirectory(@"C:\ProgramData\Alstom\ICONIS\S2K\Client Builder\Settings");
            }
            try
            {
                File.Copy(@"D:\IconisHMI\HMI_GDL\Working Files\CBTraceConfig.ini", @"C:\ProgramData\Alstom\ICONIS\S2K\Client Builder\Settings\CBTraceConfig.ini", true);
            }
            catch (Exception) { }

            // condition shortcut copy




            //


            //FileInfo[] files = dir.GetFiles();
            //foreach (FileInfo file in files)
            //{
            //if (file.Name.Contains("CBTraceConfig.ini"))
            //{
            //    string tempath = Path.Combine(@"C:\ProgramData\Alstom\ICONIS\S2K\Client Builder\Settings", file.Name);
            //    file.CopyTo(tempath, false);
            //}

            if (Directory.Exists(@"D:\IconisHMI\GDLShortcut\GDLShortcut"))
            {

                DirectoryInfo dir = new DirectoryInfo(@"D:\IconisHMI\GDLShortcut\GDLShortcut");
                FileInfo[] files = dir.GetFiles();
                foreach (FileInfo file in files)
                {
                    if (file.Name.Contains("Guadalajara.fvp"))
                    {
                        string tempath = Path.Combine(@"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup", file.Name);
                        file.CopyTo(tempath, false);
                    }

                }
            }

           
            // videowall

            if (Directory.Exists(@"D:\IconisHMI\Gudalajara_VideowallShortcut"))
            {
                DirectoryInfo dirVideowall = new DirectoryInfo(@"D:\IconisHMI\Gudalajara_VideowallShortcut\Gudalajara_VideowallShortcut");
                FileInfo[] filesVideowall = dirVideowall.GetFiles();
                foreach (FileInfo file in filesVideowall)
                {
                    if (file.Name.Contains("Gudalajara_Videowall.fvp"))
                    {
                        string tempath = Path.Combine(@"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup", file.Name);
                        file.CopyTo(tempath, false);
                    }

                }
            }








            //}

        }
        protected override void OnBeforeUninstall(System.Collections.IDictionary savedState)
        {
            base.OnBeforeUninstall(savedState);
            if (File.Exists(@"D:\IconisHMI\Gudalajara_Videowall.zip"))
            {
                UninstallZipFiles(@"D:\IconisHMI\Gudalajara_Videowall.zip", @"D:\IconisHMI\Gudalajara_Videowall");
            }

            if (File.Exists(@"D:\IconisHMI\HMI_GDL.zip"))
            {
                UninstallZipFiles(@"D:\IconisHMI\HMI_GDL.zip", @"D:\IconisHMI\HMI_GDL");
            }

            if (File.Exists(@"D:\IconisHMI\GDLShortcut.zip"))
            {
                UninstallZipFiles(@"D:\IconisHMI\GDLShortcut.zip", @"D:\IconisHMI\GDLshortcut");
            }

           
            
            DirectoryInfo dir = new DirectoryInfo(@"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\");
            FileInfo[] files = dir.GetFiles();
            foreach (FileInfo file in files)
            {
                if (file.Name.Contains("Guadalajara.fvp"))
                {
                    file.Delete();
                }
                if (file.Name.Contains("Gudalajara_Videowall.fvp"))
                {
                    file.Delete();
                }
                
            }



            try
            {
                if (Directory.Exists(@"D:\IconisHMI\HMI_GDL"))
                {
                    Directory.Delete(@"D:\IconisHMI\HMI_GDL", true);
                }
                if (Directory.Exists(@"D:\IconisHMI\Gudalajara_Videowall"))
                {
                    Directory.Delete(@"D:\IconisHMI\Gudalajara_Videowall", true);
                    {
                        if (Directory.Exists(@"D:\IconisHMI\GDLshortcut"))
                        {
                            Directory.Delete(@"D:\IconisHMI\GDLshortcut", true);
                        }
                    }
                }
                if (Directory.Exists(@"D:\IconisHMI\Gudalajara_VideowallShortcut"))
                {
                    Directory.Delete(@"D:\IconisHMI\Gudalajara_VideowallShortcut", true);
                }
            }
            catch (Exception ex)
            {

            }


        }


    }
}

