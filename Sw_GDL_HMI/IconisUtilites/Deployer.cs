using System;
using System.Collections.Generic;
using System.Threading;
using System.Net.NetworkInformation;
using System.Management;
using System.Diagnostics;
using System.Xml;

namespace Deployment
{
    /// <summary>
    /// Delegate to handle the event fired when the thread has started
    /// checking for a computer's availability on the network
    /// </summary>
    /// <param name="computer">Computer that has been checked</param>
    public delegate void OnComputerCheckingStartDelegate(DeploymentComputer computer);

    /// <summary>
    /// Delegate to handle the event fired when the thread has finished
    /// to check if one computer is available on the network
    /// </summary>
    /// <param name="computer">Computer that has been checked</param>
    /// <param name="bSuccess">Result flag</param>
    /// <param name="sResultDescription">Result description in case of errors</param>
    public delegate void OnComputerCheckingFinishDelegate(DeploymentComputer computer, bool bSuccess, string sResultDescription);

    /// <summary>
    /// Delegate to handle the event fired when the deployment of a computer has started
    /// </summary>
    /// <param name="computer">The computer being deployed</param>
    public delegate void OnComputerDeployementStartDelegate(DeploymentComputer computer);

    /// <summary>
    /// Delegate to handle the event fired when the deployment of a computer has finished
    /// </summary>
    /// <param name="computer">The computer deployed</param>
    public delegate void OnComputerDeployementFinishDelegate(DeploymentComputer computer, bool bSuccess, string sResultDescription);

    /// <summary>
    /// Delegate to handle the event fired when the reboot of a computer has started
    /// </summary>
    /// <param name="computer">The computer being rebooted</param>
    public delegate void OnRebootComputerStartDelegate(DeploymentComputer computer);

    /// <summary>
    /// Delegate to handle the event fired when the reboot of a computer has finished
    /// </summary>
    /// <param name="computer">The computer rebooted</param>
    public delegate void OnRebootComputerFinishDelegate(DeploymentComputer computer, int iResult, string sResultDescription);

    /// <summary>
    /// Delegate to handle the event fired when a deployment command is starting to execute
    /// </summary>
    /// <param name="computer">The computer being deployed</param>
    /// <param name="command">The command being executed</param>
    public delegate void OnDeploymentCommandStartDelegate(DeploymentComputer computer, DeploymentCommand command);

    /// <summary>
    /// Delegate to handle the event fired when a deployment command has finished being executed
    /// </summary>
    /// <param name="computer">The computer being deployed</param>
    /// <param name="command">The command executed</param>
    /// <param name="bSuccess">Result flag</param>
    /// <param name="sResultDescription">Result's description</param>
    public delegate void OnDeploymentCommandFinishDelegate(DeploymentComputer computer, DeploymentCommand command,
      bool bSuccess, string sResultDescription);


    /// <summary>
    /// Class that controls the threads responsible for making the deployment
    /// to the network computers and checking if they are available on the network
    /// </summary>
    public class Deployer
    {
        /// <summary>
        /// Reference to singleton object of this class
        /// </summary>
        private static Deployer deployer = null;

        /// <summary>
        /// event fired when the thread has started checking the availability of a computer
        /// </summary>
        public event OnComputerCheckingStartDelegate OnComputerCheckingStart;

        /// <summary>
        /// event fired when the thread has finished checking the availability of a computer
        /// </summary>
        public event OnComputerCheckingFinishDelegate OnComputerCheckingFinish;

        /// <summary>
        /// event fired when the deployment of a computer has started
        /// </summary>
        public event OnComputerDeployementStartDelegate OnComputerDeploymentStart;

        /// <summary>
        /// event fired when the deployment of a computer has finished
        /// </summary>
        public event OnComputerDeployementFinishDelegate OnComputerDeploymentFinish;

        /// <summary>
        /// event fired when the reboot of a computer has started
        /// </summary>
        public event OnRebootComputerStartDelegate OnRebootComputerStart;

        /// <summary>
        /// event fired when the reboot of a computer has finished
        /// </summary>
        public event OnRebootComputerFinishDelegate OnRebootComputerFinish;

        /// <summary>
        /// event fired when a deployment command has started being executed
        /// </summary>
        public event OnDeploymentCommandStartDelegate OnDeploymentCommandStart;

        /// <summary>
        /// event fired when a deployment command has finished being executed
        /// </summary>
        public event OnDeploymentCommandFinishDelegate OnDeploymentCommandFinish;

        /// <summary>
        /// Thread assigned to check computer availability
        /// </summary>
        private Thread thrCheckComputers;

        /// <summary>
        /// Thread to execute commands
        /// </summary>
        private Thread thrExecCommand;

        /// <summary>
        /// Class that checks availaiblity of computers
        /// </summary>
        private ComputerCheckingThread computerCheckingThread;

        /// <summary>
        /// Thread to execute commands
        /// </summary>
        private CommandThread commandThread;

        /// <summary>
        /// 
        /// </summary>
        private bool m_MultiThreading = false;

        /// <summary>
        /// Hidden constructor. This is a singleton class.
        /// </summary>
        private Deployer()
        {
            this.thrCheckComputers = null;
            this.thrExecCommand = null;
            this.computerCheckingThread = new ComputerCheckingThread();
            this.commandThread = new CommandThread();

            // Register to events in the computer checking thread
            this.computerCheckingThread.OnComputerCheckingStart += new OnComputerCheckingStartDelegate(computerChecker_OnComputerCheckingStart);
            this.computerCheckingThread.OnComputerCheckingFinish += new OnComputerCheckingFinishDelegate(computerChecker_OnComputerCheckingFinish);

            // Register to events in the command thread
            this.commandThread.OnComputerDeploymentStart += new OnComputerDeployementStartDelegate(commandThread_OnComputerDeploymentStart);
            this.commandThread.OnComputerDeploymentFinish += new OnComputerDeployementFinishDelegate(commandThread_OnComputerDeploymentFinish);
            this.commandThread.OnDeploymentCommandStart += new OnDeploymentCommandStartDelegate(commandThread_OnDeploymentCommandStart);
            this.commandThread.OnDeploymentCommandFinish += new OnDeploymentCommandFinishDelegate(commandThread_OnDeploymentCommandFinish);
            this.commandThread.OnRebootComputerStart += new OnRebootComputerStartDelegate(commandThread_OnRebootComputerStart);
            this.commandThread.OnRebootComputerFinish += new OnRebootComputerFinishDelegate(commandThread_OnRebootComputerFinish);
        }

        // TODO: implement the Observer design pattern (with a class inheriting from EventArgs)

        /// <summary>
        /// Handles the event fired when a command has started being reboot
        /// </summary>
        /// <param name="computer"></param>
        void commandThread_OnRebootComputerStart(DeploymentComputer computer)
        {
            if (this.OnRebootComputerStart != null)
                this.OnRebootComputerStart(computer);
        }

        /// <summary>
        /// Handles the event fired when a command has finished being reboot
        /// </summary>
        /// <param name="computer"></param>
        /// <param name="command"></param>
        /// <param name="bSuccess"></param>
        /// <param name="sResultDescription"></param>
        void commandThread_OnRebootComputerFinish(DeploymentComputer computer, int iResult, string sResultDescription)
        {
            if (this.OnRebootComputerFinish != null)
                this.OnRebootComputerFinish(computer, iResult, sResultDescription);
        }

        /// <summary>
        /// Handles the event fired when a command has finished being executed
        /// </summary>
        /// <param name="computer"></param>
        /// <param name="command"></param>
        /// <param name="bSuccess"></param>
        /// <param name="sResultDescription"></param>
        void commandThread_OnDeploymentCommandFinish(DeploymentComputer computer, DeploymentCommand command,
          bool bSuccess, string sResultDescription)
        {
            if (this.OnDeploymentCommandFinish != null)
                this.OnDeploymentCommandFinish(computer, command, bSuccess, sResultDescription);
        }

        /// <summary>
        /// Handles the event fired when a command has started being executed
        /// </summary>
        /// <param name="computer"></param>
        /// <param name="command"></param>
        void commandThread_OnDeploymentCommandStart(DeploymentComputer computer, DeploymentCommand command)
        {
            if (this.OnDeploymentCommandStart != null)
                this.OnDeploymentCommandStart(computer, command);
        }

        /// <summary>
        /// Handles the event fired when the deployment has finished for a computer
        /// </summary>
        /// <param name="computer"></param>
        /// <param name="bSuccess"></param>
        /// <param name="sResultDescription"></param>
        void commandThread_OnComputerDeploymentFinish(DeploymentComputer computer, bool bSuccess, string sResultDescription)
        {
            if (this.OnComputerDeploymentFinish != null)
                this.OnComputerDeploymentFinish(computer, bSuccess, sResultDescription);
        }

        /// <summary>
        /// Handles the event fired when the deployment has started for a computer
        /// </summary>
        /// <param name="computer"></param>
        void commandThread_OnComputerDeploymentStart(DeploymentComputer computer)
        {
            if (this.OnComputerDeploymentStart != null)
                this.OnComputerDeploymentStart(computer);
        }

        /// <summary>
        /// Handles the event fired when the thread finishes to check the availability of a computer.
        /// Forwards the event.
        /// </summary>
        /// <param name="computer"></param>
        ///<param name="bSuccess"></param>
        /// <param name="sResultDescription">Result description in case of errors</param>
        void computerChecker_OnComputerCheckingFinish(DeploymentComputer computer, bool bSuccess, string sResultDescription)
        {
            if (this.OnComputerCheckingFinish != null)
                this.OnComputerCheckingFinish(computer, bSuccess, sResultDescription);
        }


        /// <summary>
        /// Handles the event fired when the thread starts to check the availability of a computer.
        /// Forwards the event.
        /// </summary>
        /// <param name="computer"></param>
        void computerChecker_OnComputerCheckingStart(DeploymentComputer computer)
        {
            if (this.OnComputerCheckingStart != null)
                this.OnComputerCheckingStart(computer);
        }

        /// <summary>
        /// Static method to get instance of this class
        /// </summary>
        public static Deployer GetInstance()
        {
            // create new instance if necessary
            if (Deployer.deployer == null)
            {
                Deployer.deployer = new Deployer();
            }

            return Deployer.deployer;
        }

        /// <summary>
        /// Checks availability in the network of all computers received in the 
        /// parameter
        /// </summary>
        /// <param name="lstComputers"></param>
        /// <exception cref="ArgumentNullException">If the list of computers is null</exception>
        public void CheckComputersAvailability(List<DeploymentComputer> lstComputers)
        {
            if (lstComputers == null)
            {
                throw new ArgumentNullException("Argument \"lstComputers\" is null");
            }

            // stop any threads before
            if ((this.thrCheckComputers != null) && (this.thrCheckComputers.IsAlive))
            {
                this.thrCheckComputers.Abort();
                this.thrCheckComputers.Join();
                this.thrCheckComputers = null;
            }

            // Create new thread to do it
            this.thrCheckComputers = new Thread(this.computerCheckingThread.CheckComputersAvailability);
            this.thrCheckComputers.Start(lstComputers);
        }

        /// <summary>
        /// Executes all commands to all computers
        /// </summary>
        /// <param name="lstComputers"></param>
        public void DeployMulti(List<DeploymentComputer> lstComputers)
        {
            m_MultiThreading = true;

            Deploy(lstComputers);
        }

        /// <summary>
        /// Executes all commands to all computers
        /// </summary>
        /// <param name="lstComputers"></param>
        public void Deploy(List<DeploymentComputer> lstComputers)
        {
            if (lstComputers == null)
            {
                throw new ArgumentNullException("Argument \"lstComputers\" is null");
            }

            // stop any threads before
            if ((this.thrExecCommand != null) && (this.thrExecCommand.IsAlive))
            {
                this.thrExecCommand.Abort();
                this.thrExecCommand.Join();
                this.thrExecCommand = null;
            }

            // Create new thread
            this.commandThread.MultiThreading = m_MultiThreading;
            this.thrExecCommand = new Thread(this.commandThread.Deploy);
            this.thrExecCommand.Start(lstComputers);
        }


        /// <summary>
        /// Stop the threads that check computer availability
        /// </summary>
        public void StopCheckingComputers()
        {
            try
            {
                // stops the thread
                if (this.thrCheckComputers.IsAlive)
                {
                    this.computerCheckingThread.RequestStop();
                    this.thrCheckComputers.Join();
                    this.thrCheckComputers = null;
                }
            }
            catch (Exception)
            {
                // do nothing
            }
        }

        /// <summary>
        /// Stop the thread that makes the deployment
        /// </summary>
        public void StopDeployment()
        {
            try
            {
                // stops the thread
                if (this.thrExecCommand.IsAlive)
                {
                    // command thread to stop
                    this.commandThread.RequestStop();

                    // thread has to finish current command to stop, so we kill the ongoing process
                    try
                    {
                        this.KillOngoingProcess();
                    }
                    catch
                    {
                        // no treatment for exceptions, if this thread cannot kill the ongoing process
                        // than we just wait until the process is terminated of killed manually
                    }

                    this.thrExecCommand.Join();
                    this.thrExecCommand = null;
                }
            }
            catch (Exception)
            {
                // do nothing
            }
        }

        /// <summary>
        /// Kills the ongoing command
        /// </summary>
        private void KillOngoingProcess()
        {
            // get ongoing process
            foreach (OngoingProcess ongoingProcess in commandThread.GetOngoingProcess())
            {
                if (ongoingProcess != null)
                {
                    // check if process is local
                    if (ongoingProcess.LocalProcess)
                    {
                        // Get process object
                        Process process = Process.GetProcessById(ongoingProcess.ProcessID);
                        {
                            // Get all processes with same name
                            foreach (Process p in Process.GetProcessesByName(process.ProcessName))
                            {
                                if (p != null)
                                {
                                    // kill it
                                    p.Kill();
                                }
                            }
                        }
                    }
                    else
                    {
                        // process is remote

                        // get all process running
                        ObjectQuery query = new ObjectQuery("Select * from Win32_Process Where ProcessID = '" +
                          ongoingProcess.ProcessID + "'");

                        // execute query
                        ManagementObjectSearcher objectSearcher = new ManagementObjectSearcher(ongoingProcess.WMIScope, query);

                        //Get the results
                        ManagementObjectCollection objsProcId = objectSearcher.Get();

                        // get the object representing the process
                        if (objsProcId.Count > 0)
                        {
                            foreach (ManagementObject objProcId in objsProcId)
                            {
                                // get the name of process
                                string sProcName = objProcId["Name"].ToString();

                                // kill all processes with this name
                                query.QueryString = "Select * from Win32_Process Where Name = '" + sProcName + "'";

                                // execute query
                                objectSearcher.Query = query;

                                // Get the results
                                ManagementObjectCollection objsProcName = objectSearcher.Get();

                                // kill all processes with same name
                                foreach (ManagementObject objProcName in objsProcName)
                                {
                                    // kill all (only 1 expected)
                                    objProcName.InvokeMethod("Terminate", new object[] { 0 });
                                }

                                // assuming only process with the given id was found, abort loop
                                break;
                            }
                        }
                    }
                }
            }
        }
    }


    /// <summary>
    /// Thread to check computer availability
    /// </summary>
    public class ComputerCheckingThread
    {
        /// <summary>
        /// Variable that indicates if a thread should be terminated
        /// Volatile tells the compiler this variable will be used by multiple threads
        /// </summary>
        private volatile bool bShouldStop;

        /// <summary>
        /// Event fired when it starts to check a computer availability
        /// </summary>
        public event OnComputerCheckingStartDelegate OnComputerCheckingStart;

        /// <summary>
        /// Event fired when it finishes to check a computer availability
        /// </summary>
        public event OnComputerCheckingFinishDelegate OnComputerCheckingFinish;

        /// <summary>
        /// Constructor.
        /// </summary>
        public ComputerCheckingThread()
        {
            this.bShouldStop = false;
        }

        /// <summary>
        /// Thread that checks if all computers in the list received are available
        /// on the network
        /// </summary>
        /// <param name="data">list of computers, this parameter will be casted to
        /// an object of type List of DeploymentComputer</param>
        /// <exception cref="InvalidCastException">Thrown if the object received
        /// cannot be parsed to a list of DeploymentComputer</exception>
        public void CheckComputersAvailability(object data)
        {
            // try to cast it to List
            List<DeploymentComputer> lstComputers;
                
            lstComputers = data as List<DeploymentComputer>;

            if (lstComputers != null)
            {
                // for each computer
                foreach (DeploymentComputer computer in lstComputers)
                {
                    // check if thread should be terminated
                    if (this.bShouldStop)
                    {
                        // reset the flag for next thread
                        this.bShouldStop = false;
                        break;
                    }

                    // only for selected computers
                    if (computer.Selected)
                    {
                        // Fire start event
                        this.OnComputerCheckingStart(computer);

                        // pinging the computer
                        Ping ping = new Ping();
                        PingReply pingReply = null;
                        string sResultDescription = "";
                        bool bSuccess = false;
                        try
                        {
                            pingReply = ping.Send(computer.NetworkName, 10000);
                            bSuccess = (pingReply.Status == IPStatus.Success);
                            sResultDescription = pingReply.Status.ToString();
                        }
                        catch (PingException e)
                        {
                            // not possible to get the pingReply status because the object is null
                            sResultDescription = e.Message;
                        }

                        // fire the finish event
                        this.OnComputerCheckingFinish(computer, bSuccess, sResultDescription);

                        // release resources
                        ping = null;
                        pingReply = null;
                        sResultDescription = null;
                    }
                }
            }
        }

        /// <summary>
        /// Requests the thread to be terminated
        /// </summary>
        public void RequestStop()
        {
            // set flag
            this.bShouldStop = true;
        }

    }

    /// <summary>
    /// Thread to make the deployment
    /// </summary>
    public class CommandThread
    {
        /// <summary>
        /// Variable that indicates if a thread should be terminated
        /// Volatile tells the compiler this variable will be used by multiple threads
        /// </summary>
        private volatile bool bShouldStop;

        /// <summary>
        /// event fired when the deployment of a computer has started
        /// </summary>
        public event OnComputerDeployementStartDelegate OnComputerDeploymentStart;

        /// <summary>
        /// event fired when the deployment of a computer has finished
        /// </summary>
        public event OnComputerDeployementFinishDelegate OnComputerDeploymentFinish;

        /// <summary>
        /// event fired when the deployment of a computer has started
        /// </summary>
        public event OnRebootComputerStartDelegate OnRebootComputerStart;

        /// <summary>
        /// event fired when the deployment of a computer has finished
        /// </summary>
        public event OnRebootComputerFinishDelegate OnRebootComputerFinish;

        /// <summary>
        /// event fired when a deployment command has started being executed
        /// </summary>
        public event OnDeploymentCommandStartDelegate OnDeploymentCommandStart;

        /// <summary>
        /// event fired when a deployment command has finished being executed
        /// </summary>
        public event OnDeploymentCommandFinishDelegate OnDeploymentCommandFinish;

        /// <summary>
        /// Structure holding information about the ongoing process
        /// Marked as volatile so it the process can be killed by another thread
        /// </summary>
        private volatile List<OngoingProcess> ongoingProcess = new List<OngoingProcess>();

        /// <summary>
        /// Indicates if a multithreading data copy is in progress
        /// </summary>
        private bool m_bDataCopyInProgress = false;

        /// <summary>
        /// Indicates if a multithreading is requested
        /// </summary>
        private bool m_bMultiThreading = false;
        public bool MultiThreading
        {
            get { return m_bMultiThreading; }
            set { m_bMultiThreading = value; }
        }

        /// <summary>
        /// Constructor.
        /// </summary>
        public CommandThread()
        {
            this.bShouldStop = false;
        }

        /// <summary>
        /// Gets the structure with information about the ongoing process
        /// </summary>
        /// <returns>Reference to structure OngoingProcess or null there are
        /// no ongoing process</returns>
        public List<OngoingProcess> GetOngoingProcess()
        {
            return this.ongoingProcess;
        }

        /// <summary>
        /// Thread that makes the deployment
        /// </summary>
        /// <param name="data">list of computers to be deployed, this parameter will be casted to
        /// an object of type List of DeploymentComputer</param>
        /// <exception cref="InvalidCastException">Thrown if the object received
        /// cannot be parsed to a list of DeploymentComputer</exception>
        /// <exception cref="ArgumentException">Thrown if the list of computers doesn't have the dataprep computer</exception>
        public void Deploy(object data)
        {
            // try to cast it to List
            List<DeploymentComputer> lstComputers;

            lstComputers = data as List<DeploymentComputer>;

            if (lstComputers != null)
            {

                // get the dataprep computer
                DataPrepComputer dataPrepComputer = null;
                foreach (DeploymentComputer computer in lstComputers)
                {
                    if (computer.GetType() == typeof(DataPrepComputer))
                    {
                        dataPrepComputer = computer as DataPrepComputer;
                    }
                }

                // check if it was found
                // TODO: Dataprep computer check disabled
                //if (dataPrepComputer == null)
                //{
                //    throw new ArgumentException("List of computers does not include the computer with the original DataPrep folder");
                //}

                List<Thread> listInstallation = new List<Thread>();

                List<UInt32> lstComputersId = new List<uint>();
                // for each computer
                foreach (DeploymentComputer computer in lstComputers)
                {
                    lstComputersId.Add(computer.Id);
                }
            
                // for each computer
                foreach (UInt32 currentId in lstComputersId)
                {
                    System.Console.WriteLine("Deploying computer " + currentId.ToString());

                    DeploymentComputer computer = null;
                    foreach (DeploymentComputer Temp in lstComputers)
                    {
                        if (currentId == Temp.Id)
                        {
                            computer = Temp;
                            break;
                        }
                    }

                    if (computer == null)
                    {
                        System.Console.WriteLine("Id " + currentId.ToString() + " didn't correspond to any computer");
                        continue;
                    }
                    System.Console.WriteLine("Id " + currentId.ToString() + " correspond to computer " + computer.NetworkName);

                    // only for selected computers (ignore data prep computer)
                    if ((computer.Selected) && (computer.GetType() != typeof(DataPrepComputer)))
                    {
                        // check if thread should be terminated
                        if (this.bShouldStop)
                        {
                            // reset the flag for next thread
                            this.bShouldStop = false;
                            return;
                        }

                        if (m_bMultiThreading == true)
                        {
                            bool bDataTobeCopied = false;
                            foreach (DeploymentCommand command in computer.Commands)
                            {
                                if ((command.Type == DeploymentCommand.TypeCmd.DataPrepCopyCmd) || (command.Type == DeploymentCommand.TypeCmd.DeployCmd))
                                {
                                    bDataTobeCopied = true;
                                    break;
                                }
                            }

                            if (bDataTobeCopied == true)
                            {
                                System.Console.WriteLine("Computer : " + computer.NetworkName + " : Some DataPrep command shall be done, waiting for previous DataPrep processing");

                                while (m_bDataCopyInProgress == true)
                                {
                                    Thread.Sleep(1000);
                                    // check if thread should be terminated
                                    if (this.bShouldStop)
                                    {
                                        // reset the flag for next thread
                                        this.bShouldStop = false;
                                        return;
                                    }
                                }

                                System.Console.WriteLine("Computer : " + computer.NetworkName + " : No other DataPrep processing in progress, starting deployment");

                                m_bDataCopyInProgress = true;
                            }

                            Thread ThreadInstallComputer = new Thread(delegate()
                            {
                                // install computer
                                this.InstallComputer(computer, dataPrepComputer);
                            });

                            ThreadInstallComputer.Start();

                            listInstallation.Add(ThreadInstallComputer);
                        }
                        else
                        {
                            this.InstallComputer(computer, dataPrepComputer);
                        }
                    }
                }

                foreach (Thread Previous in listInstallation)
                {
                    Previous.Join();
                }

                // Reboot local computer at last
                DeploymentComputer cLocal = null;

                // Reboot each computer
                foreach (DeploymentComputer computer in lstComputers)
                {
                    // only for selected computers (ignore data prep computer)
                    if ((computer.Selected) && (computer.GetType() != typeof(DataPrepComputer)))
                    {
                        // check if thread should be terminated
                        if (this.bShouldStop)
                        {
                            // reset the flag for next thread
                            this.bShouldStop = false;
                            return;
                        }

                        if (!computer.IsLocalHost)
                        {
                            // install computer
                            this.RebootComputer(computer);
                        }
                        else
                        {
                            cLocal = computer;
                        }
                    }
                }

                if (cLocal != null) this.RebootComputer(cLocal);
            }
        }


        /// <summary>
        /// Executes commands for a given computer
        /// </summary>
        /// <param name="computer">Computer to deploy</param>
        private void InstallComputer(DeploymentComputer computer, DataPrepComputer dataPrepComputer)
        {
            System.Console.WriteLine("Installing Computer : " + computer.NetworkName + " From Computer " + dataPrepComputer.NetworkName);

            computer.Deployed = false;
            if (computer.NumberOfCommands <= 0)
            {
                System.Console.WriteLine("Nothing to do");

                // fire event
                this.OnComputerDeploymentFinish(computer, true, "No commands to execute");
                return;
            }

            bool bZipToBeDone = false;
            Int32 iDataTobeCopied = 0;
            foreach (DeploymentCommand command in computer.Commands)
            {
                if ((command.Type == DeploymentCommand.TypeCmd.DataPrepCopyCmd) || (command.Type == DeploymentCommand.TypeCmd.DeployCmd))
                {
                    ++iDataTobeCopied;
                    if ((bZipToBeDone == false) && (computer.equals(dataPrepComputer) == false))
                    {
                        if (command.Type == DeploymentCommand.TypeCmd.DeployCmd)
                        {
                            if (command.SourcePath.Zip == true)
                            {
                                bZipToBeDone = true;
                            }
                        }
                        else
                        {
                            List<DataPrepComputer> lstGeneralDataPrep = dataPrepComputer.Computers;
                            foreach (DataPrepComputer dpComputer in lstGeneralDataPrep)
                            {
                                if (dpComputer.Zip == true)
                                {
                                    bZipToBeDone = true;
                                }
                            }

                            // Copy the Dataprep files
                            List<DataPrepPathZip> lstSimpleCommand = computer.DataPrepPath;
                            foreach (DataPrepPathZip sSinglecommand in lstSimpleCommand)
                            {
                                if (sSinglecommand.Zip == true)
                                {
                                    bZipToBeDone = true;
                                }
                            }
                        }
                    }
                }
            }

            System.Console.WriteLine("Computer : " + computer.NetworkName + " : There is " + iDataTobeCopied.ToString() + " DataPrep command to be done");

            // fire event
            this.OnComputerDeploymentStart(computer);

            // Create management object
            ManagementScope managementScope = null;

            // processing is different for localhost and remote machines
            bool bLocalProcess = false;
            if (!computer.IsLocalHost)
            {
                // Configure connection
                ConnectionOptions connectionOptions = new ConnectionOptions();
                connectionOptions.Username = computer.Username;
                connectionOptions.Password = computer.Password;
                connectionOptions.Impersonation = ImpersonationLevel.Impersonate;
                connectionOptions.Authentication = AuthenticationLevel.PacketPrivacy;
                managementScope = new ManagementScope(@"\\" + computer.NetworkName + @"\root\cimv2", connectionOptions);
            }
            else
            {
                // for localhost
                bLocalProcess = true;
                managementScope = new ManagementScope(@"\\" + computer.NetworkName + @"\root\cimv2");
            }

            managementScope.Options.EnablePrivileges = true;
            // Connect
            try
            {
                managementScope.Connect();
            }
            catch (Exception ex)
            {
                // failed to connect to computer
                this.OnComputerDeploymentFinish(computer, false, ex.Message);
                managementScope = null;
                if (bZipToBeDone == true) m_bDataCopyInProgress = false;
                return;
            }

            // Search on remote computer if a previous installation was done
            if (computer.UnInstallation == true)
            {
                this.AddUninstallCommand(computer);
                this.OnComputerDeploymentStart(computer); // To update the list of command
            }

            // check if thread should be terminated
            if (this.bShouldStop)
            {
                // send event
                this.OnComputerDeploymentFinish(computer, false, "Installation stopped by user");
                if (bZipToBeDone == true) m_bDataCopyInProgress = false;
                return;
            }

            if (bZipToBeDone)
            {
                System.Console.WriteLine("Computer : " + computer.NetworkName + " : A Zip command is requested, copying IZip");

                if (CopyZipManagementFiles(computer, dataPrepComputer) == false)
                {
                    System.Console.WriteLine("Computer : " + computer.NetworkName + " : Error while copying IZip, aborting Zip functionality");

                    //Error while copying IZip desactivating Zip function
                    foreach (DeploymentCommand command in computer.Commands)
                    {
                        if (command.Type == DeploymentCommand.TypeCmd.DeployCmd)
                        {
                            if (command.SourcePath.Zip == true)
                            {
                                command.SourcePath.Zip = false;
                            }
                        }
                        else if (command.Type == DeploymentCommand.TypeCmd.DataPrepCopyCmd)
                        {
                            List<DataPrepComputer> lstGeneralDataPrep = dataPrepComputer.Computers;
                            foreach (DataPrepComputer dpComputer in lstGeneralDataPrep)
                            {
                                dpComputer.Zip = false;
                            }

                            // Copy the Dataprep files
                            List<DataPrepPathZip> lstSimpleCommand = computer.DataPrepPath;
                            foreach (DataPrepPathZip sSinglecommand in lstSimpleCommand)
                            {
                                sSinglecommand.Zip = false;
                            }
                        }
                    }
                    bZipToBeDone = false;
                }
            }

            // run each command
            bool bCmdFailed = false;
            foreach (DeploymentCommand command in computer.Commands)
            {
                System.Console.WriteLine("Computer : " + computer.NetworkName + " : Starting command " + command.CommandLine);

                // fire event
                this.OnDeploymentCommandStart(computer, command);

                try
                {
                    // Check the command type
                    switch (command.Type)
                    {
                        case DeploymentCommand.TypeCmd.DataPrepCopyCmd:
                            this.CopyDataPrep(managementScope, computer, dataPrepComputer);
                            --iDataTobeCopied;
                            if (iDataTobeCopied == 0)
                            {
                                m_bDataCopyInProgress = false;
                                System.Console.WriteLine("Computer : " + computer.NetworkName + " : There is no longer DataPrep command remaining");
                            }
                            break;

                        case DeploymentCommand.TypeCmd.DataPrepRemoveCmd:
                            this.RemoveDataPrep(computer);
                            break;

                        case DeploymentCommand.TypeCmd.DeployCmd:
                            this.CopyData(managementScope, command.Source, computer, command.SourcePath, command.TargetPath, command.CopyFile);
                            --iDataTobeCopied;
                            if (iDataTobeCopied == 0)
                            {
                                m_bDataCopyInProgress = false;
                                System.Console.WriteLine("Computer : " + computer.NetworkName + " : There is no longer DataPrep command remaining");
                            }
                            break;

                        case DeploymentCommand.TypeCmd.RunCmd:
                            this.RunRemoteCommand(managementScope, bLocalProcess, computer, command);
                            break;
                    }

                    // fire event
                    if (this.bShouldStop == false)
                    {
                        this.OnDeploymentCommandFinish(computer, command, true, "Success");

                        System.Console.WriteLine("Computer : " + computer.NetworkName + " : Command " + command.CommandLine + " complete");
                    }
                }
                catch (Exception ex)
                {
                    // exception during command execution
                    bCmdFailed = true;

                    if ((bZipToBeDone == true) && (iDataTobeCopied > 0)) m_bDataCopyInProgress = false;

                    // fire event of command terminated
                    this.OnDeploymentCommandFinish(computer, command, false, ex.Message);
                }

                //
                // the following checks should be made inside the
                // catch block, but when running processes with WMI it is not
                // possible to get the exit code to know if the process finished
                // with error or not, so it is not possible to generate an exception
                // (on windows vista or later it is possible).
                //

                // check if thread should be terminated
                if (this.bShouldStop)
                {
                    // send event
                    this.OnComputerDeploymentFinish(computer, false, "Installation stopped by user");
                    return;
                }

                // check if last command failed
                if (bCmdFailed)
                {
                    this.OnComputerDeploymentFinish(computer, false, "Failed to install computer");
                    return;
                }
            }

            if (bZipToBeDone) RemoveZipManagementFiles(computer, dataPrepComputer);

            computer.Deployed = true;

            // Computer deployment complete
            managementScope = null;
            this.OnComputerDeploymentFinish(computer, true, "All commands executed");
        }

        private void AddUninstallCommand(DeploymentComputer computer)
        {
            // logon to remote computer
            string sArgs = @"use \\" + computer.NetworkName + @"\D$ /user:" + computer.Username + " " + computer.Password;

            // Create and set process property object      
            ProcessStartInfo processInfo = new ProcessStartInfo();
            processInfo.FileName = "net";
            processInfo.Arguments = sArgs;
            processInfo.CreateNoWindow = true;
            processInfo.UseShellExecute = false;
            processInfo.WindowStyle = ProcessWindowStyle.Hidden;

            Process process = null;
            process = Process.Start(processInfo);
            OngoingProcess ongoing = new OngoingProcess(process.Id, true, null, null);
            ongoingProcess.Add(ongoing);
            process.WaitForExit();
            ongoingProcess.Remove(ongoing);

            // get exit code
            if (process.ExitCode != 0)
            {
                return;
            }

            // close process
            process.Close();
            process = null;

            System.IO.DirectoryInfo dirRemoteDataPrep = new System.IO.DirectoryInfo(@"\\" + computer.NetworkName + @"\D$\\DataPrep\Output\Deployment\ByComputer");
            if (dirRemoteDataPrep.Exists == true)
            {
                System.IO.FileInfo[] listfiles = dirRemoteDataPrep.GetFiles("*.xml", System.IO.SearchOption.TopDirectoryOnly);
                // Search a file with the computer name

                foreach (System.IO.FileInfo file in listfiles)
                {
                    // Load the XML configuration file into a XMLDocument
                    XmlDocument xmlDocConfig = null;
                    try
                    {
                        xmlDocConfig = new XmlDocument();
                        xmlDocConfig.Load(file.FullName);
                    }
                    catch
                    {
                        continue;
                    }

                    // input information
                    XmlNodeList xmlNdDataPrepComputer = xmlDocConfig.SelectNodes(@"./Deployment/DataPrepSource/DataPrepComputer");

                    // Computers
                    XmlNodeList xmlNdComputers = xmlDocConfig.SelectNodes(@"/Deployment/Computers/Computer");
                    foreach (XmlNode xmlNdComputer in xmlNdComputers)
                    {
                        XmlElement xmlElmt = xmlNdComputer as XmlElement;
                        if (xmlElmt == null)
                        {
                            continue;
                        }

                        // Get name
                        string sName = xmlElmt.GetAttribute(@"Name");
                        if (sName == computer.Name)
                        {
                            // Add Uninstall Command
                            XmlNodeList xmlNdCommands = xmlNdComputer.SelectNodes(@"./UnInstallCommand");
                            if (xmlNdCommands.Count == 0)
                            {
                                // Nothing deployed previously on this computer 
                                return;
                            }
                            // Add DataPrep removal
                            XmlNode xmlNdDataPrep = xmlNdComputer.SelectSingleNode(@"./DataPrep");
                            if (xmlNdDataPrep != null)
                            {
                                computer.addDataPrepCommand(false);

                                // Remove global Directories
                                int index = 0;
                                foreach (XmlNode xmlSingleComputer in xmlNdDataPrepComputer)
                                {
                                    XmlElement xmlSingleElement = xmlSingleComputer as XmlElement;
                                    if (xmlSingleElement == null) continue;

                                    string sDataPrepInputPath = xmlSingleElement.GetAttribute("Path");
                                    sDataPrepInputPath = sDataPrepInputPath.Replace(@":\", @"$\\");
                                    System.IO.DirectoryInfo newdirtoremove = new System.IO.DirectoryInfo(@"\\" + computer.NetworkName + @"\" + sDataPrepInputPath);

                                    computer.RemovalInfos.InsertNewDirectory(index, newdirtoremove);
                                    ++index;
                                }

                                // Remove single files
                                index = 0;
                                XmlNodeList xmlsingleDataPrep = xmlNdDataPrep.SelectNodes(@"./DataPrepSingle");
                                foreach (XmlNode xmlsingle in xmlsingleDataPrep)
                                {
                                    XmlElement xmleltSingle = xmlsingle as XmlElement;
                                    if (xmleltSingle == null) continue;

                                    string sSingle = xmleltSingle.GetAttribute(@"Path");
                                    sSingle = sSingle.Replace(@":\", @"$\\");
                                    System.IO.FileInfo newfiletoremove = new System.IO.FileInfo(@"\\" + computer.NetworkName + @"\" + sSingle);

                                    computer.RemovalInfos.InsertNewFile(index, newfiletoremove);
                                    ++index;
                                }
                            }

                            int indexcommand = 0;
                            foreach (XmlNode xmlNdCommand in xmlNdCommands)
                            {
                                // command line
                                XmlElement xmlelt = xmlNdCommand as XmlElement;
                                if (xmlelt == null)
                                {
                                    continue;
                                }

                                XmlElement xmlndElement;

                                xmlndElement = xmlNdCommand as XmlElement;

                                if (xmlndElement != null)
                                {
                                    string sCommandLine = xmlndElement.GetAttribute(@"CommandLine");

                                    // working directory
                                    string sWorkingDirectory = xmlndElement.GetAttribute(@"WorkingDirectory");

                                    // description
                                    string sCmdDescription = xmlndElement.GetAttribute(@"Description");

                                    // Add command to computer
                                    computer.insertCommand(indexcommand, sCommandLine, sWorkingDirectory, sCmdDescription);
                                }

                                ++indexcommand;
                            }

                            return;
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Reboot a given computer
        /// </summary>
        /// <param name="computer">Computer to reboot</param>
        private void RebootComputer(DeploymentComputer computer)
        {
            try
            {
                // fire event
                this.OnRebootComputerStart(computer);

                if (computer.ToReboot == false)
                {
                    this.OnRebootComputerFinish(computer, 1, "Reboot procedure skipped");
                    return;
                }

                // Create management object
                ManagementScope managementScope = null;

                // processing is different for localhost and remote machines
                if (!computer.IsLocalHost)
                {
                    // Configure connection
                    ConnectionOptions connectionOptions = new ConnectionOptions();
                    connectionOptions.Username = computer.Username;
                    connectionOptions.Password = computer.Password;
                    connectionOptions.Impersonation = ImpersonationLevel.Impersonate;
                    connectionOptions.Authentication = AuthenticationLevel.PacketPrivacy;
                    managementScope = new ManagementScope(@"\\" + computer.NetworkName + @"\root\cimv2", connectionOptions);
                }
                else
                {
                    // for localhost
                    managementScope = new ManagementScope(@"\\" + computer.NetworkName + @"\root\cimv2");
                }

                // Connect
                try
                {
                    managementScope.Connect();
                }
                catch (Exception ex)
                {
                    // failed to connect to computer
                    this.OnRebootComputerFinish(computer, -1, "Exception : " + ex.Message);
                    managementScope = null;
                    return;
                }

                // check if thread should be terminated
                if (this.bShouldStop)
                {
                    // send event
                    this.OnRebootComputerFinish(computer, -1, "Reboot stopped by user");
                    return;
                }

                System.Management.ObjectQuery oQuery = new System.Management.ObjectQuery("SELECT * FROM Win32_OperatingSystem");
                ManagementObjectSearcher queryResult = new ManagementObjectSearcher(managementScope, oQuery);
                ManagementObjectCollection queryCollection1 = queryResult.Get();
                foreach (ManagementObject mo in queryCollection1)
                {
                    string[] ss ={ "" };
                    object oresult = mo.InvokeMethod("Reboot", ss);
                    string sRetVal = oresult.ToString();

                    // Win32_OperatingSystem:Reboot() method should return 0
                    // Check method result
                    int iResult = int.Parse(sRetVal);
                    if (iResult != 0)
                    {
                        if (iResult == 997) this.OnRebootComputerFinish(computer, 1, "Pending Reboot procedure");
                        else this.OnRebootComputerFinish(computer, -1, "Failure during reboot procedure (" + sRetVal + ")");
                        return;
                    }
                }

                // Computer reboot complete
                managementScope = null;
                this.OnRebootComputerFinish(computer, 0, "Reboot command successful");

            }
            catch (Exception ex)
            {
                this.OnRebootComputerFinish(computer, -1, "Exception : " + ex.ToString());
            }
        }

        /// <summary>
        /// Copies the dataprep folder from the dataprep computer to the target computer
        /// </summary>
        /// <param name="computer">The target computer</param>
        /// <param name="dataPrepComputer">The dataprep computer</param>
        /// <param name="sArguments">The path to the folder or a file</param>
        /// <param name="bFile">Whether </param>
        /// <exception cref="ArgumentException">Thrown if there's an error with the computers' path properties</exception>
        /// <exception cref="Win32Exception">Thrown if the commands cannot be executed in this computer</exception>
        /// <exception cref="Exception">Thrown if an error occurs during the login on the dataprep computer,
        /// creation or copy of dataprep folder in the target machine</exception>
        private void CopyDirectoryOrFile(ManagementScope management, DeploymentComputer dataPrepComputer, DeploymentComputer computer, DataPrepPathZip sSourcePath, DataPrepPathZip sTargetPath, bool bFile)
        {
            
            // get the drive letter and folder tree from the dataprep paths
            string sInputDataPrepDriveLetter = string.Empty;
            string sInputDataPrepFolderTree = string.Empty;
            string sOutputDriverLetter = string.Empty;
            string sOutputFolderTree = string.Empty;
            string sSourceName = sSourcePath.Path;
            string sTargetName = sTargetPath.Path;

            string sZipTarget = string.Empty;
            if ((sSourcePath.Zip) || (sTargetPath.Zip))
            {
                sSourceName += ".zip";
                sTargetName += ".zip";

                string sValue = System.Environment.CurrentDirectory + @"\IZip.exe /a " + sSourceName + ((bFile == true) ? " /f " : " ") + sSourcePath.Path;

                System.IO.FileInfo zipfile = new System.IO.FileInfo(sSourceName);
                if (bFile)
                {
                    sZipTarget = zipfile.DirectoryName;
                }
                else
                {
                    sZipTarget = sTargetPath.Path;
                }
                if (zipfile.Exists == false)
                {
                    DeploymentCommand IZip = new DeploymentCommand(sValue, "", "");

                    // Start IZip to create a temporary file
                    ManagementScope localmanagement = new ManagementScope(@"\\" + dataPrepComputer.NetworkName + @"\root\cimv2");

                    System.Console.WriteLine("Zip file : " + sValue);

                    RunRemoteCommand(localmanagement, true, null, IZip);

                    System.Console.WriteLine("File Zipped : " + sValue);
                }

                bFile = true;
            }

            try
            {
                this.SplitDriveAndPath(sSourceName, out sInputDataPrepDriveLetter, out sInputDataPrepFolderTree);
                this.SplitDriveAndPath(sTargetName, out sOutputDriverLetter, out sOutputFolderTree);
            }
            catch (ArgumentException ex)
            {
                throw ex;
            }

            // logon to dataprep computer
            string sArgs = "use \\\\" + dataPrepComputer.NetworkName + "\\" + sInputDataPrepDriveLetter + "$ /user:" +
                dataPrepComputer.Username + " " + dataPrepComputer.Password;
            if (dataPrepComputer.IsLocalHost)
            {
                sArgs = "use \\\\" + dataPrepComputer.NetworkName + "\\" + sInputDataPrepDriveLetter + "$";
            }

            // Create and set process property object      
            ProcessStartInfo processInfo = new ProcessStartInfo();
            processInfo.FileName = "net";
            processInfo.Arguments = sArgs;
            processInfo.CreateNoWindow = true;
            processInfo.UseShellExecute = false;
            processInfo.WindowStyle = ProcessWindowStyle.Hidden;

            //System.Windows.Forms.MessageBox.Show("net " + sArgs);

            // Execute process, blocks thread until task is completed
            Process process = null;
            try
            {
                process = Process.Start(processInfo);
                OngoingProcess ongoing = new OngoingProcess(process.Id, true, null, null);
                ongoingProcess.Add(ongoing);
                process.WaitForExit();
                ongoingProcess.Remove(ongoing);

                // get exit code
                if (process.ExitCode != 0)
                {
                    throw new Exception("Failed to logon Computer " + dataPrepComputer + ". Exit code " + process.ExitCode);
                }

                // close process
                process.Close();
                process = null;


                //
                // log on to target computer
                //
                sArgs = "use \\\\" + computer.NetworkName + "\\" + sInputDataPrepDriveLetter + "$ /user:" +
                    computer.Username + " " + computer.Password;
                processInfo.FileName = "net";
                processInfo.Arguments = sArgs;

                process = Process.Start(processInfo);
                OngoingProcess ongoing2 = new OngoingProcess(process.Id, true, null, null);
                ongoingProcess.Add(ongoing2);
                process.WaitForExit();
                ongoingProcess.Remove(ongoing2);

                // get exit code
                if (process.ExitCode != 0)
                {
                    throw new Exception("Failed to logon to target computer. Exit code " + process.ExitCode);
                }

                // close process
                process.Close();
                process = null;

                // OK, now copy dataprep folder
                // block thread until task completes
                // /k: keep attributes
                // /h: copy hidden files
                // /e: copy folder structure
                // /i: destination is a folder
                // /y: overwrite if already exists
                string sxcopyArgument;
                if (bFile == true)
                {
                    System.IO.FileInfo localfile = new System.IO.FileInfo("\\\\" + dataPrepComputer.NetworkName + "\\" + sInputDataPrepDriveLetter + "$" + sInputDataPrepFolderTree);
                    if (localfile.Exists == false)
                    {
                        throw new Exception(localfile.FullName + " didn't exist");
                    }
                    else
                    {
                        string remoteFileName = " \\\\" + computer.NetworkName + "\\" + sOutputDriverLetter + "$" + sOutputFolderTree;
                        if (!sOutputFolderTree.EndsWith("\\"))
                            remoteFileName = remoteFileName + "\\";
                        System.IO.FileInfo remotefile = new System.IO.FileInfo(" \\\\" + computer.NetworkName + "\\" + sOutputDriverLetter + "$" + sOutputFolderTree);
                        // Create the directory hierarchy if not existing
                        if (remotefile.Directory.Exists == false)
                            remotefile.Directory.Create();

                        System.Console.WriteLine("source " + localfile.FullName);
                        System.Console.WriteLine("dest " + remotefile.FullName);

                        System.IO.File.Copy(localfile.FullName, remotefile.FullName, true);
                        if (remotefile.Exists == false)
                        {
                            throw new Exception("Copy to " + remotefile.FullName + " failed");
                        }

                        if ((sSourcePath.Zip) || (sTargetPath.Zip))
                        {
                            string sCommand = System.Environment.CurrentDirectory + @"\IZip.exe /x " + sSourceName + " " + sZipTarget;
                            // Start IZip extraction
                            DeploymentCommand IZip = new DeploymentCommand(sCommand, "", "");

                            System.Console.WriteLine("UnZip file : " + sCommand);

                           // Start IZip to extract temporary file
                            RunRemoteCommand(management, false, null, IZip);

                            System.Console.WriteLine("File Unzipped : " + sCommand);
                        }
                    }
                }
                else
                {
                    processInfo.FileName = "xcopy";
                    sxcopyArgument = " /k/h/e/i/y";
                    sArgs = "\\\\" + dataPrepComputer.NetworkName + "\\" + sInputDataPrepDriveLetter + "$" + sInputDataPrepFolderTree
                          + " \\\\" + computer.NetworkName + "\\" + sOutputDriverLetter + "$" + sOutputFolderTree
                          + sxcopyArgument;

                    System.Console.WriteLine("xcopy " + sArgs);

                    //if (bFile == true) System.Windows.Forms.MessageBox.Show("Arg : " + sArgs);
                    processInfo.Arguments = sArgs;
                    process = Process.Start(processInfo);
                    OngoingProcess ongoing3 = new OngoingProcess(process.Id, true, null, null);
                    ongoingProcess.Add(ongoing3);
                    process.WaitForExit();
                    ongoingProcess.Remove(ongoing3);

                    // get exit code
                    if (process.ExitCode != 0)
                    {
                        throw new Exception("Failed to copy folder " + sSourcePath.Path + ". Exit code " + process.ExitCode);
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                // release resources
                if (process != null)
                {
                    process.Close();
                }
                process = null;
                processInfo = null;
                sArgs = string.Empty;
            }
        }

        /// <summary>
        /// Copies the dataprep folder from the dataprep computer to the target computer
        /// </summary>
        /// <param name="computer">The target computer</param>
        /// <param name="dataPrepComputer">The dataprep computer</param>
        /// <param name="sArguments">The path to the folder or a file</param>
        /// <param name="bFile">Whether </param>
        /// <exception cref="ArgumentException">Thrown if there's an error with the computers' path properties</exception>
        /// <exception cref="Win32Exception">Thrown if the commands cannot be executed in this computer</exception>
        /// <exception cref="Exception">Thrown if an error occurs during the login on the dataprep computer,
        /// creation or copy of dataprep folder in the target machine</exception>
        private void CopyDirectoryOrFile(ManagementScope management, DeploymentComputer dataPrepComputer, DeploymentComputer computer, DataPrepPathZip sPath, bool bFile)
        {
            CopyDirectoryOrFile(management, dataPrepComputer, computer, sPath, sPath, bFile);
        }

        /// <summary>
        /// Remove the dataprep folder from the target computer
        /// </summary>
        /// <param name="computer">The target computer</param>
        private void RemoveDataPrep(DeploymentComputer computer)
        {
            foreach (System.IO.FileInfo filecurrent in computer.RemovalInfos.Files)
            {
                if (filecurrent.Exists == true) filecurrent.Delete();
            }

            foreach (System.IO.DirectoryInfo dircurrent in computer.RemovalInfos.Directories)
            {
                if (dircurrent.Exists == true) dircurrent.Delete(true);
            }
        }

        /// <summary>
        /// Copies the dataprep folder from the dataprep computer to the target computer
        /// </summary>
        /// <param name="computer">The target computer</param>
        /// <param name="dataPrepComputer">The dataprep computer</param>
        /// <exception cref="ArgumentException">Thrown if there's an error with the computers' path properties</exception>
        /// <exception cref="Win32Exception">Thrown if the commands cannot be executed in this computer</exception>
        /// <exception cref="Exception">Thrown if an error occurs during the login on the dataprep computer,
        /// creation or copy of dataprep folder in the target machine</exception>
        private void CopyDataPrep(ManagementScope management, DeploymentComputer computer, DataPrepComputer dataPrepComputer)
        {
            // Nothing to do if source and destination are the same machine on the network
            if (computer.equals(dataPrepComputer))
            {
                return;
            }

            List<DataPrepComputer> lstGeneralDataPrep = dataPrepComputer.Computers;
            foreach (DataPrepComputer dpComputer in lstGeneralDataPrep)
            {
                bool bFile = System.IO.File.Exists(dpComputer.PathZip.Path);
                CopyDirectoryOrFile(management, dpComputer, computer, dpComputer.PathZip, bFile);
            }

            // Copy the Dataprep files
            List<DataPrepPathZip> lstSimpleCommand = computer.DataPrepPath;
            foreach (DataPrepPathZip sSinglecommand in lstSimpleCommand)
            {
                bool bFile = System.IO.File.Exists(sSinglecommand.Path);
                CopyDirectoryOrFile(management, dataPrepComputer, computer, sSinglecommand, bFile);
            }
        }

        /// <summary>
        /// Copies some data from a source computer to a target computer
        /// </summary>
        private void CopyData(ManagementScope management, DeploymentComputer Source, DeploymentComputer Target, DataPrepPathZip sourcePath, DataPrepPathZip targetPath, bool bFile)
        {
            // Nothing to do if the data source and destination are the same
            if (Source.equals(Target) && sourcePath.Equals(targetPath))
            {
                return;
            }

            // Copy the data
            CopyDirectoryOrFile(management, Source, Target, sourcePath, targetPath, bFile);
        }

        /// <summary>
        /// Run a command on a remote computer
        /// </summary>
        private void RunRemoteCommand(ManagementScope managementScope, bool bLocalProcess, DeploymentComputer computer, DeploymentCommand command)
        {
            int iKillTimeMax = 0;

            // Objects to handle process
            ManagementClass processClass = null;
            ManagementBaseObject methodParams = null;
            InvokeMethodOptions methodOptions = null;
            ManagementBaseObject methodInvokeOutputs = null;

            try
            {

                processClass = new ManagementClass("Win32_Process");
                processClass.Scope = managementScope;

                // Get an input parameters object for this method
                // Method "Create" cannot create interactive process on remote machines
                // If necessary, method "Win32_ScheduledJob.Create"
                methodParams = processClass.GetMethodParameters("Create");

                // Fill in input parameter values
                methodParams["CommandLine"] = command.CommandLine;
                if (command.WorkingDirectory.Length != 0) methodParams["CurrentDirectory"] = command.WorkingDirectory;

                // this will execute the command.
                methodOptions = new InvokeMethodOptions(null, System.TimeSpan.MaxValue);
                methodInvokeOutputs = processClass.InvokeMethod("Create", methodParams, methodOptions);

                // Get procID and "Create" method return value
                string sRetVal = methodInvokeOutputs["ReturnValue"].ToString();

                // Win32_Process:Create() method should return 0
                // Check method result
                if (int.Parse(sRetVal) != 0)
                {
                    // Create method failed
                    throw new Exception("Failed to create process : Return Code = " + sRetVal);
                }

                // process was created successfully
                string sProcID = methodInvokeOutputs["ProcessID"].ToString();
                OngoingProcess ongoing = new OngoingProcess(int.Parse(sProcID), bLocalProcess, computer, managementScope);
                ongoingProcess.Add(ongoing);

                iKillTimeMax = 60; // 1 minutes : Time to wait until process dies

                ManagementObjectCollection objsProcId;
                do
                {
                    // Check that the process is still alive
                    ObjectQuery query = new ObjectQuery("Select * from Win32_Process Where ProcessID = '" +
                      ongoing.ProcessID + "'");

                    // execute query
                    ManagementObjectSearcher objectSearcher = new ManagementObjectSearcher(ongoing.WMIScope, query);

                    // Get the results
                    objsProcId = objectSearcher.Get();

                    if (objsProcId.Count == 0)
                    {
                        ongoingProcess.Remove(ongoing);
                        break;
                    }

                    if (this.bShouldStop == true)
                    {
                        --iKillTimeMax;
                    }

                    Thread.Sleep(1000);
                }
                while (iKillTimeMax > 0);

                if (computer != null)
                {
                    if (this.bShouldStop == true)
                    {
                        if (iKillTimeMax <= 0)
                        {
                            this.OnDeploymentCommandFinish(computer, command, false, "Process keep alive");
                        }
                        else
                        {
                            this.OnDeploymentCommandFinish(computer, command, false, "Process stopped");
                        }
                    }
                }
                ongoingProcess.Remove(ongoing);
            }
            finally
            {
                // release resources
                processClass = null;
                methodParams = null;
                methodOptions = null;
                methodInvokeOutputs = null;
            }
        }

        /// <summary>
        /// Requests the thread to be terminated
        /// </summary>
        public void RequestStop()
        {
            // set flag
            this.bShouldStop = true;
        }

        /// <summary>
        /// Splits the drive letter and the remaining folder tree from a given path in the following format:
        /// D:\path1\path2.
        /// </summary>
        /// <param name="sPath">The input path</param>
        /// <param name="sDriveLetter">Receives the drive letter</param>
        /// <param name="sFolderTree">Receives the folder structure in the format: \path1\path2</param>
        /// <exception cref="ArgumentException">Thrown if the input path is null or empty</exception>
        private void SplitDriveAndPath(string sPath, out string sDriveLetter, out string sFolderTree)
        {
            // initialize output parameters
            sDriveLetter = string.Empty;
            sFolderTree = string.Empty;

            // check path
            if ((sPath == null) || (sPath.Length == 0))
            {
                throw new ArgumentException("Path is invalid");
            }

            // get the drive letter as the first character in the string
            sDriveLetter = sPath.Substring(0, 1);

            // get the remaining path (ignore drive letter and ':' character)
            sFolderTree = sPath.Substring(2);
        }

        private bool CopyZipManagementFiles(DeploymentComputer computer, DataPrepComputer dataPrepComputer)
        {
            if (computer.equals(dataPrepComputer))
            {
                return false;
            }

            DataPrepPathZip executable = new DataPrepPathZip();
            executable.Path = System.Environment.CurrentDirectory + @"\IZip.exe";
            executable.Zip = false;

            {
                System.IO.FileInfo localfile = new System.IO.FileInfo(executable.Path);
                if (localfile.Exists == false) return false;
            }

            DataPrepPathZip binary = new DataPrepPathZip();
            binary.Path = System.Environment.CurrentDirectory + @"\ICSharpCode.SharpZipLib.dll";
            binary.Zip = false;

            {
                System.IO.FileInfo localfile = new System.IO.FileInfo(binary.Path);
                if (localfile.Exists == false) return false;
            }

            CopyDirectoryOrFile(null, dataPrepComputer, computer, executable, true);
            CopyDirectoryOrFile(null, dataPrepComputer, computer, binary, true);

            return true;
        }

        private void RemoveZipManagementFiles(DeploymentComputer computer, DataPrepComputer dataPrepComputer)
        {
            if (computer.equals(dataPrepComputer))
            {
                return;
            }

            DataPrepPathZip executable = new DataPrepPathZip();
            executable.Path = @"\\" + computer.NetworkName + @"\\" + (System.Environment.CurrentDirectory.Replace(@":\", @"$\\")) + @"\IZip.exe";
            executable.Zip = false;

            {
                System.IO.FileInfo localfile = new System.IO.FileInfo(executable.Path);
                if (localfile.Exists == true)
                {
                    localfile.Delete();
                }
            }

            DataPrepPathZip binary = new DataPrepPathZip();
            binary.Path = @"\\" + computer.NetworkName + @"\\" + (System.Environment.CurrentDirectory.Replace(@":\", @"$\\")) + @"\ICSharpCode.SharpZipLib.dll";
            binary.Zip = false;

            {
                System.IO.FileInfo localfile = new System.IO.FileInfo(binary.Path);
                if (localfile.Exists == true)
                {
                    localfile.Delete();
                }
            }
        }

    }

    /// <summary>
    /// Class that holds the information about an ongoing process
    /// </summary>
    public class OngoingProcess
    {
        /// <summary>
        /// the process id
        /// </summary>
        private int iProcessID;

        /// <summary>
        /// Gets the process id
        /// </summary>
        public int ProcessID
        {
            get { return this.iProcessID; }
        }

        /// <summary>
        /// Flag that indicates if the process is local or remote
        /// </summary>
        private bool bLocalProcess;

        /// <summary>
        /// Gets the flag indicating if the process is local or remote
        /// </summary>
        public bool LocalProcess
        {
            get { return this.bLocalProcess; }
        }

        /// <summary>
        /// The computer on which the process is run (only matters if process is remote)
        /// </summary>
        private DeploymentComputer remoteComputer;

        /// <summary>
        /// Gets the computer on which the process is run (only matters if process is remote)
        /// </summary>
        public DeploymentComputer RemoteComputer
        {
            get { return this.remoteComputer; }
        }

        /// <summary>
        /// WMI management scope for remote connections
        /// </summary>
        private ManagementScope managementScope;

        /// <summary>
        /// Gets the WMI management scope for remote connections
        /// </summary>
        public ManagementScope WMIScope
        {
            get { return this.managementScope; }
        }

        /// <summary>
        /// Constructor, initializes private members.
        /// </summary>
        /// <param name="iProcessID">The process ID</param>
        /// <param name="bLocalProcess">Flag of local or remote process</param>
        /// <param name="remoteComputer">Thre computer case thr process is remote</param>
        /// <param name="managementScope">WMI management scope for remote connections</param>
        public OngoingProcess(int iProcessID, bool bLocalProcess, DeploymentComputer remoteComputer,
      ManagementScope managementScope)
        {
            this.iProcessID = iProcessID;
            this.bLocalProcess = bLocalProcess;
            this.remoteComputer = remoteComputer;
            this.managementScope = managementScope;
        }
    }
}
