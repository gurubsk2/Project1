using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;
using System.Runtime.Remoting;
using System.Runtime.Remoting.Channels;
using System.Runtime.Remoting.Channels.Tcp;

namespace IconisUtilities
{
    public abstract class RDDControlClient : MarshalByRefObject, IRDDControlClient
    {
        #region members
        protected string m_ID = "";
        protected bool m_bIsActive = false;
        protected string m_strConnectionString = "tcp://localhost:1234/RDDController"; 
        /// LifeCheck interval for controller presence
        protected Double m_dLifeCheckInterval = 1500; // in milliseconds
        ///Life check timer
        protected System.Timers.Timer m_LifeCheckTimer = null;
        /// controller 
        protected IRDDController m_Controller = null;
        ///  Trace management
        protected IconisTracer m_IconisTracer = null;
        #endregion

        protected RDDControlClient(string strID)
        {
            m_ID = strID;
        }

        #region IRDDControlClient implementation
        // true = active, false = passive
        public void SetNewState(bool bActive)
        {
            if (m_bIsActive != bActive)
            {
                m_bIsActive = bActive;
                HandleChangeActivity();
            }
        }

        // true = active, false = passive
        public bool IsActive() { return m_bIsActive; }

        // Name of the client (for instance : "PIMCom")
        public String GetID() { return m_ID; }
        #endregion

        // abstract method where the client handles the change of activity state
        protected abstract void HandleChangeActivity();

        protected void InitTraceManagement(string strPath, string strComponent)
        {
            m_IconisTracer = new IconisTracer();
            m_IconisTracer.StartTrace(strPath, strComponent);
        }

        /// <summary>
        /// Start this client manage the creation of the connection string, 
        /// the registration of the callback tcp channel to receive calls
        /// from the controller and the init of the lifecheck timer
        /// </summary>
        /// <param name="controllerIP"></param>
        /// <param name="controllerPort"></param>
        protected void RegToRDDController(string controllerIP, ulong controllerPort)
        {
            try
            {
                m_strConnectionString = "tcp://" + controllerIP + ":" + controllerPort.ToString() + "/RDDController";

                // Also register a Channel to use for callback from the server
                TcpChannel chan = new TcpChannel(0);
                ChannelServices.RegisterChannel(chan, false);

                ConnectToRDDController();

                m_LifeCheckTimer = new System.Timers.Timer(m_dLifeCheckInterval);
                m_LifeCheckTimer.Elapsed += new System.Timers.ElapsedEventHandler(LifeCheck);
                m_LifeCheckTimer.AutoReset = false;
                m_LifeCheckTimer.Enabled = true;
            }
            catch (System.Exception e)
            {
                if (m_IconisTracer != null)
                    m_IconisTracer.TraceError("RegToRDDController\t Caught Exception : " + e.Message);

                // re-throw exception to stop client and create the dump
                throw e;
            }
        }

        //! Get access to the other RDDController
        private void ConnectToRDDController()
        {
            m_Controller = System.Activator.GetObject(typeof(IRDDController), m_strConnectionString) as IRDDController;

            if (m_Controller != null)
            {
                m_Controller.RegisterClient(this);
                if (m_IconisTracer != null)
                    m_IconisTracer.TraceFunctional("ConnectToRDDController\tRegistered to RDDController");

                Console.WriteLine("Established connection with RDDController");
            }
            else
            {
                if (m_IconisTracer != null)
                    m_IconisTracer.TraceFunctional("ConnectToRDDController\tFailed to get Controller");
                if (m_Controller != null)
                {
                    Console.WriteLine("Lost connection with RDDController");
                    m_Controller = null;
                }
            }
        }

        /// <summary>
        /// Check controller is still alive
        /// </summary>
        /// <returns>true if controller up and alive, false otherwise</returns>
        private bool LifeCheckController()
        {
            try
            {
                if (m_Controller == null)
                {
                    ConnectToRDDController();
                }
                // re activate the life check timer
                m_LifeCheckTimer.Enabled = true;

                if (m_Controller != null && m_Controller.IsAlive() == true)
                    return true;
                else
                    return false;
            }
            catch (System.Exception)
            {
                m_LifeCheckTimer.Enabled = true;
                return false;
            }
        }

        /// <summary>
        /// Timer event processing.  Attempts to connect to RDD controller and check life status 
        /// </summary>
        /// <param name="source">unused</param>
        /// <param name="e">unused</param>
        private void LifeCheck(object source, System.Timers.ElapsedEventArgs e)
        {
            try
            {            
                // if controller no longer alive then force state to passive
                if (LifeCheckController() == false)
                {
                    SetNewState(false);
                }
            }
            catch (System.Exception)
            {
                // exception : force state to passive
                SetNewState(false);
            }
        }
    }
}
