using System;
using System.Collections.Generic;

namespace Deployment
{
    /// <summary>
    /// Stores the properties of a command to be executed on a computer
    /// </summary>
    public class DeploymentCommand
    {
        // TODO: specialize commands by inheritance
        // The logic of the command should be put inside this class (code to report here from the deployer)
        public enum TypeCmd
        {
            DeployCmd,
            DataPrepCopyCmd,
            DataPrepRemoveCmd,
            RunCmd
        };

        private TypeCmd CommandType;
        private DataPrepPathZip sSourcePath;
        private DeploymentComputer SourceMachine;
        private DataPrepPathZip sTargetPath;
        private bool bCopyFile;

        public DeploymentComputer Source
        {
            get { return SourceMachine; }
            set { SourceMachine = value; }
        }

        public DataPrepPathZip SourcePath
        {
            get { return sSourcePath; }
            set { sSourcePath = value; }
        }
        public DataPrepPathZip TargetPath
        {
            get { return sTargetPath; }
            set { sTargetPath = value; }
        }
        public bool CopyFile
        {

            get { return bCopyFile; }
            set { bCopyFile = value; }
        }

        /// <summary>
        /// Command to executed on a target machine
        /// </summary>
        private string sCommand;

        /// <summary>
        /// Working directory to executed on a target machine
        /// </summary>
        private string sWorkingDirectory;

        /// <summary>
        /// Command's description
        /// </summary>
        private string sDescription;

        /// <summary>
        /// Gets or sets the command's description
        /// </summary>
        public string Description
        {
            get { return this.sDescription; }
            set { this.sDescription = value; }
        }

        public TypeCmd Type
        {
            get { return this.CommandType; }
            set { this.CommandType = value; }
        }

        /// <summary>
        /// Gets the command line for this command
        /// </summary>
        public string CommandLine
        {
            get { return this.sCommand; }
        }

        /// <summary>
        /// Gets the working directory for this command
        /// </summary>
        public string WorkingDirectory
        {
            get { return this.sWorkingDirectory; }
        }

        /// <summary>
        /// Constructor. Initializes members. This constructor sets the flag which indicates if this is the command
        /// to copy the dataprep folder to false.
        /// </summary>
        /// <exception cref="ArgumentException">Thrown if the command line is empty or null</exception>
        /// <param name="sCommand">The command line to be executed.</param>
        /// <param name="sWorkingDirectory">The working directory for the command to be executed.</param>
        /// <param name="sDescription">Command's description</param>
        public DeploymentCommand(string sCommand, string sWorkingDirectory, string sDescription)
        {
            // check command line
            if ((sCommand == null) || (sCommand.Length == 0))
            {
                throw new ArgumentException("The command line is empty");
            }

            // Set members
            this.sCommand = sCommand;
            this.sWorkingDirectory = sWorkingDirectory;
            this.sDescription = sDescription;
            this.Type = TypeCmd.RunCmd;
        }

        /// <summary>
        /// Constructor. Initializes members. This constructor sets the flag which indicates if this is the command
        /// to copy the dataprep folder to false.
        /// </summary>
        /// <exception cref="ArgumentException">Thrown if the command line is empty or null</exception>
        /// <param name="sCommand">The command line to be executed.</param>
        /// <param name="sWorkingDirectory">The working directory for the command to be executed.</param>
        /// <param name="sDescription">Command's description</param>
        public DeploymentCommand(DeploymentComputer SourceMachine, DataPrepPathZip sSourcePath, DataPrepPathZip sTargetPath, bool bFile, string sDescription)
        {
            // Set members
            this.SourceMachine = SourceMachine;
            this.sSourcePath = sSourcePath;
            this.sTargetPath = sTargetPath;
            this.bCopyFile = bFile;
            this.sDescription = sDescription;
            this.Type = TypeCmd.DeployCmd;
        }

        /// <summary>
        /// Default constructor.
        /// </summary>
        public DeploymentCommand()
        {
            // initialize members with default values
            this.sCommand = "";
            this.sWorkingDirectory = "";
            this.sDescription = "";
            this.Type = TypeCmd.RunCmd;
        }
    }
}
