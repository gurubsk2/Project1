using System;
using System.Collections.Generic;
using System.Text;

namespace Deployment
{
    /// <summary>
    /// Store the properties and list of dataprep command to be run on each computer
    /// </summary>
    public class DataPrepInfo
    {
        /// <summary>List of Directories to be copied/removed </summary>
        private List<System.IO.DirectoryInfo> lstDirectories;

        /// <summary>
        /// Gets the list of directories
        /// </summary>
        public List<System.IO.DirectoryInfo> Directories
        {
            get { return lstDirectories; }
        }

        public void AddNewDirectory ( System.IO.DirectoryInfo newDir )
        {
            lstDirectories.Add(newDir);
        }

        public void InsertNewDirectory(int Index, System.IO.DirectoryInfo newDir)
        {
            lstDirectories.Insert(Index, newDir);
        }

        /// <summary>List of Files to be copied/removed </summary>
        private List<System.IO.FileInfo> lstFiles;

        /// <summary>
        /// Gets the list of files
        /// </summary>
        public List<System.IO.FileInfo> Files
        {
            get { return lstFiles; }
        }

        public void AddNewFile(System.IO.FileInfo newFile)
        {
            lstFiles.Add(newFile);
        }

        public void InsertNewFile(int Index, System.IO.FileInfo newFile)
        {
            lstFiles.Insert(Index,newFile);
        }

        /// <summary>flags indicating if the information is for addition or removal</summary>
        private bool bRemoval;

        /// <summary>
        /// Indicates if information is for addition or removal
        /// </summary>
        public bool IsRemoval
        {
            get { return bRemoval; }
        }

        public DataPrepInfo(bool bIsForRemoval)
        {
            this.bRemoval = bIsForRemoval;
            this.lstDirectories = new List<System.IO.DirectoryInfo>();
            this.lstFiles = new List<System.IO.FileInfo>();
        }
    }
}
