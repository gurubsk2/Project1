using System;
using System.IO;
using System.Text;
using System.Data;
using System.Data.Common;

namespace IconisUtilities
{
    /// <summary>
    /// This class handle various useful methods for C# components
    /// </summary>
    public static class IconisTools
    {
        //! Compare two strings (return true if they match), with possible use of wild cards (?*) and parameter to ignore or not the case of the strings
        public static bool WildcardMatch(String str, String compare, bool ignoreCase)
        {
            if (ignoreCase)
                return WildcardMatch(str.ToLower(), compare.ToLower());
            else
                return WildcardMatch(str, compare);
        }

        //! Compare two strings (return true if they match), with possible use of wild cards (?*), case sensitive
        public static bool WildcardMatch(String str, String compare)
        {
            if (String.IsNullOrEmpty(compare))
                return str.Length == 0;
            int pS = 0;
            int pW = 0;
            int lS = str.Length;
            int lW = compare.Length;

            while (pS < lS && pW < lW && compare[pW] != '*')
            {
                char wild = compare[pW];
                if (wild != '?' && wild != str[pS])
                    return false;
                ++pW;
                ++pS;
            }

            int pSm = 0;
            int pWm = 0;
            while (pS < lS && pW < lW)
            {
                char wild = compare[pW];
                if (wild == '*')
                {
                    ++pW;
                    if (pW == lW)
                        return true;
                    pWm = pW;
                    pSm = pS + 1;
                }
                else if (wild == '?' || wild == str[pS])
                {
                    ++pW;
                    ++pS;
                }
                else
                {
                    pW = pWm;
                    pS = pSm;
                    ++pSm;
                }
            }
            while (pW < lW && compare[pW] == '*')
                ++pW;
            return pW == lW && pS == lS;
        }

        //! Execute an sql command on specified database
        public static void ExecuteSql(String DatabaseName, String Sql)
        {
            System.Data.SqlClient.SqlConnection masterConnection = new System.Data.SqlClient.SqlConnection();
            System.Data.SqlClient.SqlCommand Command = new System.Data.SqlClient.SqlCommand(Sql, masterConnection);

            masterConnection.ConnectionString = "Data Source=localhost;Initial Catalog=master;Integrated Security=True;Pooling=False";
            Command.Connection.Open();
            Command.Connection.ChangeDatabase(DatabaseName);
            try
            {
                Command.ExecuteNonQuery();
            }
            finally
            {
                Command.Connection.Close();
            }
        }

        //! Create a database and all the tables in it from a list of SQL files in goven folder
        public static void CreateDBAndExecuteSQlFiles(String strDatabase, String strDirectory, String strMask)
        {
            // Get the directory, list all the .sql files (depends of the mask) in it and execute them to create the tables 
            try
            {
                // Get the current Path for installation and add the name of conf file to load
                DirectoryInfo di = new DirectoryInfo(strDirectory);

                // Close all connections on the DB
                ExecuteSql("master", String.Format("IF EXISTS(SELECT * FROM sys.sysdatabases WHERE name='{0}') ALTER DATABASE {0} SET SINGLE_USER WITH ROLLBACK IMMEDIATE", strDatabase));
                // Drop the DB
                ExecuteSql("master", String.Format("IF EXISTS(SELECT * FROM sys.sysdatabases WHERE name='{0}') DROP DATABASE {0}", strDatabase));
                // Create the DB
                ExecuteSql("master", "CREATE DATABASE " + strDatabase);

                // For each .sql file
                FileInfo[] rgFiles = di.GetFiles(strMask);
                foreach (FileInfo fi in rgFiles)
                {
                    // check exact mask matching
                    if (WildcardMatch(fi.Name, strMask))
                    {
                        String strFullPath = fi.FullName;
                        String sqlCommand = System.IO.File.ReadAllText(strFullPath);
                        ExecuteSql(strDatabase, sqlCommand);
                    }
                }
            }
            catch (Exception e)
            {
                // trace error ?
                throw e;
            }
        }

        

    }
}
