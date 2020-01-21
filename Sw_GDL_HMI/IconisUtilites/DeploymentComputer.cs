using System;
using System.Collections.Generic;

namespace Deployment
{
    /// <summary>
    /// Store the properties and list of commands to be run on each computer
    /// </summary>
    public class DeploymentComputer
    {
        /// <summary>Name or IP address of computer </summary>
        private string sName;

        /// <summary>
        /// Gets the computer's name
        /// </summary>
        public string Name
        {
            get { return sName; }
        }

        private string sNetworkName;
        /// <summary>
        /// Get the computer's network name, used in the \\NetworkName construction
        /// </summary>
        public string NetworkName
        {
            get
            {
                if (this.IsLocalHost)
                    return "127.0.0.1";
                if (sNetworkName != null)
                {
                    if (sNetworkName.Length != 0)
                        return sNetworkName;
                }
                return sName;
            }
            set
            {
                sNetworkName = value;
            }
        }

        private bool bDeployed;
        /// <summary>
        /// Gets the state of the computer deployment
        /// </summary>
        public bool Deployed
        {
            get { return bDeployed; }
            set { bDeployed = value; }
        }

        /// <summary>computer's description</summary>
        private string sDescription;

        /// <summary>
        /// Gets the computer's description
        /// </summary>
        public string Description
        {
            get { return sDescription; }
        }

        /// <summary>
        /// Path to where the dataprep folder will be copied to
        /// </summary>
        private List<DataPrepPathZip> sDataPrepPath = new List<DataPrepPathZip>();

        /// <summary>
        /// Gets the path to where the dataprep folder will be copied to
        /// </summary>
        public List<DataPrepPathZip> DataPrepPath
        {
            get { return this.sDataPrepPath; }
        }

        /// <summary>
        /// Reboot or not the computer after installation
        /// </summary>
        private bool bToReboot;

        /// <summary>
        /// Gets or sets the user with administrative rights for this computer
        /// </summary>
        public bool ToReboot
        {
            get { return this.bToReboot; }
            set { this.bToReboot = value; }
        }

        /// <summary>
        /// user with administrative rights for this computer
        /// </summary>
        private string sUsername;

        /// <summary>
        /// Gets or sets the user with administrative rights for this computer
        /// </summary>
        public string Username
        {
            get { return this.sUsername; }
            set { this.sUsername = value; }
        }

        /// <summary>
        /// Password to access this computer
        /// </summary>
        private string sPassword;

        /// <summary>
        /// Gets or sets the password to access this computer
        /// </summary>
        public string Password
        {
            get { return this.sPassword; }
            set { this.sPassword = value; }
        }

        /// <summary>
        /// Flag indicating whether this computer is marked for deployment or not
        /// </summary>
        private bool bSelected;

        /// <summary>
        /// Gets or sets the flag indicating wheter this computer is marked for deployment
        /// </summary>
        public bool Selected
        {
            get { return this.bSelected; }
            set { bSelected = value; }
        }

        /// <summary>
        /// Flag indicating whether this computer has to be uninstall before install
        /// </summary>
        private bool bUnInstallation;

        /// <summary>
        /// Gets or sets the flag indicating wheter this computer has to be uninstall before install
        /// </summary>
        public bool UnInstallation
        {
            get { return this.bUnInstallation; }
            set { bUnInstallation = value; }
        }

        /// <summary>
        /// List of commands to be applied for this computer
        /// </summary>
        private List<DeploymentCommand> lstCommands;

        /// <summary>
        /// Gets the number of commands to executed for this computer
        /// </summary>
        public int NumberOfCommands
        {
            get { return this.lstCommands.Count; }
        }

        /// <summary>
        /// Gets the list of commands for this computer
        /// </summary>
        public List<DeploymentCommand> Commands
        {
            get { return this.lstCommands; }
        }

        /// <summary>
        /// DataPrep Information to remove DataPrep
        /// </summary>
        private DataPrepInfo dpRemovalInfos;

        /// <summary>
        /// access to the DataPrep information to remove
        /// </summary>
        public DataPrepInfo RemovalInfos
        {
            get { return this.dpRemovalInfos; }
        }

        private static UInt32 CurrentId = 0;
        private UInt32 Identifier = 0;
        public UInt32 Id
        {
            get { return Identifier; }
            set { Identifier = value; }
        }

        /// <summary>
        /// Constructor. Initializes members.
        /// </summary>
        /// <exception cref="ArgumentException">Thrown if name is empty or null</exception>
        /// <param name="sName"></param>
        /// <param name="description"></param>
        public DeploymentComputer(string sName, string sDescription)
        {
            // Check parameter name
            if ((sName == null) || (sName.Length == 0))
            {
                throw new ArgumentException("Parameter \"Name\" is invalid");
            }

            // set parameters
            this.sName = sName;
            this.sDescription = sDescription;
            this.sUsername = string.Empty;
            this.sPassword = string.Empty;
            this.bDeployed = false;
            this.bToReboot = true;
            this.bUnInstallation = false;

            // initialize list of commands
            lstCommands = new List<DeploymentCommand>();

            // initialize flags
            this.bSelected = true;
            this.dpRemovalInfos = new DataPrepInfo(true);
            this.Identifier = ++CurrentId;
        }

        /// <summary>
        /// Return whether this computer is the computer running the program.
        /// </summary>
        /// <returns></returns>
        public bool IsLocalHost
        {
            get { return    (this.Name.ToLower() == "localhost")
                         || (this.Name == "127.0.0.1")
                         || (string.Compare(this.Name, System.Environment.MachineName, true) == 0); }
        }

        
        /// <summary>
        /// Return true if two computers have the same address on the network.
        /// </summary>
        /// <param name="other"></param>
        /// <returns></returns>
        public bool equals(DeploymentComputer other)
        {
            if (other == null)
                return false;
            return (this.Name == other.Name
                || (this.IsLocalHost && other.IsLocalHost));
        }

        /// <summary>
        /// Insert at the beginning the command line to the list of commands for this computer
        /// </summary>
        /// <exception cref="ArgumentNullException">Thrown if commandLine is empty</exception>
        /// <param name="index">index where to insert the command</param>
        /// <param name="sCommandLine">Command line to be executed</param>
        /// <param name="sWorkingDirectory">Working Directory</param>
        /// <param name="sDescription">Command's description</param>
        public void insertCommand(int index, string sCommandLine, string sWorkingDirectory, string sDescription)
        {
            // Create new command
            this.lstCommands.Insert(index, new DeploymentCommand(sCommandLine, sWorkingDirectory, sDescription));
        }

        /// <summary>
        /// Adds the command line to the list of commands for this computer
        /// </summary>
        /// <exception cref="ArgumentNullException">Thrown if commandLine is empty</exception>
        /// <param name="sCommandLine">Command line to be executed</param>
        /// <param name="sDescription">Command's description</param>
        public void addCommand(string sCommandLine, string sWorkingDirectory, string sDescription)
        {
            // Create new command
            this.lstCommands.Add(new DeploymentCommand(sCommandLine, sWorkingDirectory, sDescription));
        }

        /// <summary>
        /// Adds a command to the list of commands to copy the dataprep folder
        /// to this computer
        /// </summary>
        /// <param name="sDataPrepPath">The path where the data prep will be copied to</param>
        /// <exception cref="ArgumentException">Thrown if the output dataprep path is empty or null</exception>
        public void addDataPrepCommand(bool bCopy)
        {
            // add data prep command to list
            DeploymentCommand command = new DeploymentCommand();
            if (bCopy == true)
            {
                command.Type = DeploymentCommand.TypeCmd.DataPrepCopyCmd;
                command.Description = "Copy DataPrep folder";
            }
            else
            {
                command.Type = DeploymentCommand.TypeCmd.DataPrepRemoveCmd;
                command.Description = "Remove DataPrep folder";
            }
            this.lstCommands.Insert(0, command);
        }

        /// <summary>
        /// Adds a single command to the list of commands to copy the dataprep folder
        /// to this computer
        /// </summary>
        /// <param name="sDataPrepPath">The path where the data prep will be copied to</param>
        /// <exception cref="ArgumentException">Thrown if the output dataprep path is empty or null</exception>
        public void addDataPrepSingleCommand(string sDataPrepSinglePath, bool bZip)
        {
            if (sDataPrepSinglePath.Length != 0)
            {
                DataPrepPathZip NewInfo = new DataPrepPathZip();
                NewInfo.Path = sDataPrepSinglePath;
                NewInfo.Zip = bZip;
                this.sDataPrepPath.Add(NewInfo);
            }
        }

        /// <summary>
        /// Adds a command to the list of commands to deploy one or several files
        /// to this computer
        /// </summary>
        /// <param name="sDataPrepPath">The path where the data prep will be copied to</param>
        /// <exception cref="ArgumentException">Thrown if the output dataprep path is empty or null</exception>
        public void addDeployCommand(DeploymentComputer sourceMachine, string sourcePath, string sourceDest, bool bFile, string description)
        {
            DataPrepPathZip sourceInfo = new DataPrepPathZip();
            sourceInfo.Path = sourcePath;

            DataPrepPathZip destInfo = new DataPrepPathZip();
            destInfo.Path = sourceDest;


            // Add deploy command to list
            DeploymentCommand command = new DeploymentCommand(sourceMachine, sourceInfo, destInfo, bFile, description);
            
            this.lstCommands.Add(command);
        }


        /// <summary>
        /// Overriden ToString() method.
        /// </summary>
        /// <returns>Returns a string composed of the computer's name and description</returns>
        public override string ToString()
        {
            return this.sName + " (" + this.sDescription + ")";
        }
    }
}
