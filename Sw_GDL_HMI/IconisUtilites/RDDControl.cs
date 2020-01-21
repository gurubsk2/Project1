using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;

namespace IconisUtilities
{
    /// <summary>
    /// The IRDDControlClient interface is used to allow standardized communication between RDDController and a C# component
    /// Provides the following functions
    /// -- Set the active/passive state
    /// </summary>
    public interface IRDDControlClient
    {
        // true = active, false = passive
        void SetNewState(bool bActive);

        // true = active, false = passive
        bool IsActive();

        // Name of the client (for instance : "PIMCom")
        String GetID();
    }

    /// <summary>
    /// The IRDDController interface is used to allow standardized communication between RDDController and a C# component
    /// Provides the following functions
    /// -- Register an IRDDControlClient
    /// -- Unregister an IRDDControlClient
    /// -- Get current state (active/passive)
    /// </summary>
    public interface IRDDController
    {
        /// Register an RDDClient
        void RegisterClient(IRDDControlClient client);

        /// Unregister an RDDClient
        void UnregisterClient(String strID);

        /// When a client want to become inactive (for any reason)
        void ForceInactivity(IRDDControlClient client);

        /// Check if given client is alive and active (called once when a client register)
        /// returns true if client active, false if it has not been found or is inactive
        bool IsClientActive(String strID);

        /// Check this controller is still alive
        bool IsAlive();

        /// Specify the object that became inactive on the other server
        void ClientBecomeInactiveOnOtherServer(String strClientID);

        /// Handle the case when both RDDController were running before finding each other, the master one always get the priority
        bool HasCallerPriority(long lStartTimeValue);
    }
}
