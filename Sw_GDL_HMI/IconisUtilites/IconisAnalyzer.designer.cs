namespace IconisUtilities
{
    partial class IconisAnalyzer
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        
        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
       
        #region Component Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.eventStore = new System.Diagnostics.EventLog();
            ((System.ComponentModel.ISupportInitialize)(this.eventStore)).BeginInit();
            // 
            // eventStore
            // 
            this.eventStore.Log = "ALSTOM";
            this.eventStore.Source = "IconisAnalyzer";
            this.eventStore.EntryWritten += new System.Diagnostics.EntryWrittenEventHandler(this.eventStore_EntryWritten);
            ((System.ComponentModel.ISupportInitialize)(this.eventStore)).EndInit();

        }

        #endregion

        private System.Diagnostics.EventLog eventStore;
       

    }
}