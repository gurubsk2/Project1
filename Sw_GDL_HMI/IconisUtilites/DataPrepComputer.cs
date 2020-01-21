using System;
using System.Collections.Generic;

namespace Deployment
{
  /// <summary>
  /// Holds information about the dataprep source computer and paths of dataprep folder
  /// </summary>
    public class DataPrepPathZip
    {
        public DataPrepPathZip()
        {
            sPath = "";
            bZip = false;
        }

        private string sPath;
        public string Path
        {
            get { return sPath; }
            set { sPath = value; }
        }
        private bool bZip;
        public bool Zip
        {
            get { return bZip; }
            set { bZip = value; }
        }
    }

  public class DataPrepComputer : DeploymentComputer
  {
    /// <summary>
    /// Input path of DataPrep folder
    /// </summary>
    private string sPath;

    /// <summary>
    /// Gets the path of the dataprep folder
    /// </summary>
    public string Path
    {
      get { return this.sPath; }
    }

    /// <summary>
    /// Indicate if the dataprep information will have to be zipped/unzipped
    /// </summary>
    private bool bZip;

    /// <summary>
    /// Retrieved/Set the Zip parameter
    /// </summary>
    public bool Zip
    {
        get { return this.bZip; }
        set { bZip = value; }
    }

      public DataPrepPathZip PathZip
      {
          get
          {
              DataPrepPathZip NewInfo = new DataPrepPathZip();
              NewInfo.Path = sPath;
              NewInfo.Zip = bZip;
              return NewInfo;
          }
      }

    private List<DataPrepComputer> lstComputers = new List<DataPrepComputer>();

    /// <summary>
    /// Gets the list of dataprep computer
    /// </summary>
    public List<DataPrepComputer> Computers
    {
      get { return this.lstComputers; }
    }
    
    /// <summary>
    /// Constructor. Calls the base construcot and sets the data members
    /// </summary>
    /// <param name="sName"></param>
    /// <param name="sPath"></param>
    /// <exception cref="ArgumentException">Thrown if the computer's name or input path
    /// or version are empty or null</exception>
    public DataPrepComputer(string sName, string sPath) : 
      base(sName, "DataPrep Computer")
    {
      // base constructor checks the name

      // set members
      this.sPath = sPath;
    }
  }
}
