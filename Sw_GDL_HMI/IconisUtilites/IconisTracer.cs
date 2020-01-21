using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;

namespace IconisUtilities
{
    /// <summary>
    /// This class handle traces for an Iconis related C# component
    /// The formatting of the resulting trace is aimed to be coherent 
    /// with traces generated on ATS server
    /// </summary>
    public class IconisTracer
    {
        /// Internal trace listener
        private IconisTextWriterTraceListener m_IconisListener = null;

        /// Management of trace configuration
        private IconisTraceSwitch m_TraceSwitch = new IconisTraceSwitch();

        /// <summary>
        /// Name of the component, used in trace
        /// </summary>
        private string m_strComponentName;

        //! Init the traces management
        public void StartTrace(string strPath, string strComponentName)
        {
            m_strComponentName = strComponentName;
            m_IconisListener = new IconisTextWriterTraceListener(strPath, strComponentName);
            m_IconisListener.MaxNumberOfLines = 50000; 

            // NB: do not clear previous listeners
            Trace.Listeners.Add(m_IconisListener);
            Trace.AutoFlush = true;
        }

        //! Trace an error message, without args
        public void TraceError(string message)
        {
            Trace.WriteLine("	          ERROR\t\t1\t" + m_strComponentName + "\t\t" + message);
        }

        //! Trace an error message, with one parameter for string formatting (optimized with String.Format())
        public void TraceError(string message, object arg1)
        {
            Trace.WriteLine("	          ERROR\t\t1\t" + m_strComponentName + "\t\t" + String.Format(message, arg1));
        }

        //! Trace an error message, with two args for string formatting (optimized with String.Format())
        public void TraceError(string message, object arg1, object arg2)
        {
            Trace.WriteLine("	          ERROR\t\t1\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2));
        }

        //! Trace an error message, with three args for string formatting (optimized with String.Format())
        public void TraceError(string message, object arg1, object arg2, object arg3)
        {
            Trace.WriteLine("	          ERROR\t\t1\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2, arg3));
        }

        //! Trace an error message, with any number of args for string formatting (optimized with String.Format())
        public void TraceError(string message, params object[] args)
        {
            Trace.WriteLine("	          ERROR\t\t1\t" + m_strComponentName + "\t\t" + String.Format(message, args));
        }

        //! Trace a warning message, without args
        public void TraceWarning(string message)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.WARNING, ICONISTraceLevel.LEVEL_2))
                Trace.WriteLine("	        WARNING\t\t2\t" + m_strComponentName + "\t\t" + message);
        }

        //! Trace a warning message, with one parameter for string formatting (optimized with String.Format())
        public void TraceWarning(string message, object arg1)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.WARNING, ICONISTraceLevel.LEVEL_2))
                Trace.WriteLine("	        WARNING\t\t2\t" + m_strComponentName + "\t\t" + String.Format(message, arg1));
        }

        //! Trace a warning message, with two args for string formatting (optimized with String.Format())
        public void TraceWarning(string message, object arg1, object arg2)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.WARNING, ICONISTraceLevel.LEVEL_2))
                Trace.WriteLine("	        WARNING\t\t2\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2));
        }

        //! Trace a warning message, with three args for string formatting (optimized with String.Format())
        public void TraceWarning(string message, object arg1, object arg2, object arg3)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.WARNING, ICONISTraceLevel.LEVEL_2))
                Trace.WriteLine("	        WARNING\t\t2\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2, arg3));
        }

        //! Trace a warning message, with any number of args for string formatting (optimized with String.Format())
        public void TraceWarning(string message, params object[] args)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.WARNING, ICONISTraceLevel.LEVEL_2))
                Trace.WriteLine("	        WARNING\t\t2\t" + m_strComponentName + "\t\t" + String.Format(message, args));
        }

        //! Trace an debug message, without args
        public void TraceDebug(string message)
        {
            TraceDebugLvl(ICONISTraceLevel.LEVEL_3, message);
        }

        //! Trace a debug message, with 1 arg
        public void TraceDebug(string message, object arg1)
        {
            TraceDebugLvl(ICONISTraceLevel.LEVEL_3, message, arg1);
        }

        //! Trace a debug message, with 2 args
        public void TraceDebug(string message, object arg1, object arg2)
        {
            TraceDebugLvl(ICONISTraceLevel.LEVEL_3, message, arg1, arg2);
        }

        //! Trace a debug message, with 3 args
        public void TraceDebug(string message, object arg1, object arg2, object arg3)
        {
            TraceDebugLvl(ICONISTraceLevel.LEVEL_3, message, arg1, arg2, arg3);
        }

        //! Trace a debug message, with any number of args (>3)
        public void TraceDebug(string message, params object[] obj)
        {
            TraceDebugLvl(ICONISTraceLevel.LEVEL_3, message, obj);
        }

        //! Trace a debug message of any level, no argument
        public void TraceDebugLvl(ICONISTraceLevel lvl, string message)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.DEBUG, lvl))
                Trace.WriteLine("	          DEBUG\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + message);
        }

        //! Trace a debug message of any level, one arg
        public void TraceDebugLvl(ICONISTraceLevel lvl, string message, object arg1)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.DEBUG, lvl))
                Trace.WriteLine("	          DEBUG\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, arg1));
        }

        //! Trace a debug message of any level, two args
        public void TraceDebugLvl(ICONISTraceLevel lvl, string message, object arg1, object arg2)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.DEBUG, lvl))
                Trace.WriteLine("	          DEBUG\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2));
        }

        //! Trace a debug message of any level, three args
        public void TraceDebugLvl(ICONISTraceLevel lvl, string message, object arg1, object arg2, object arg3)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.DEBUG, lvl))
                Trace.WriteLine("	          DEBUG\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2, arg3));
        }

        //! Trace a debug message of any level, any number of arguments
        public void TraceDebugLvl(ICONISTraceLevel lvl, string message, params object[] args)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.DEBUG, lvl))
            {
                Trace.WriteLine("	          DEBUG\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, args));
            }
        }
        //! Trace a functional message of level 3, no argument
        public void TraceFunctional(string message)
        {
            TraceFunctionalLvl(ICONISTraceLevel.LEVEL_3, message);
        }
        //! Trace a functional message of level 3, 1 argument
        public void TraceFunctional(string message, object arg1)
        {
            TraceFunctionalLvl(ICONISTraceLevel.LEVEL_3, message, arg1);
        }
        //! Trace a functional message of level 3, 2 arguments
        public void TraceFunctional(string message, object arg1, object arg2)
        {
            TraceFunctionalLvl(ICONISTraceLevel.LEVEL_3, message, arg1, arg2);
        }
        //! Trace a functional message of level 3, 3 arguments
        public void TraceFunctional(string message, object arg1, object arg2, object arg3)
        {
            TraceFunctionalLvl(ICONISTraceLevel.LEVEL_3, message, arg1, arg2, arg3);
        }
        //! Trace a functional message of level 3, any number of arguments
        public void TraceFunctional(string message, params object[] p)
        {
            TraceFunctionalLvl(ICONISTraceLevel.LEVEL_3, message, p);
        }

        //! Trace a functional message of any level, no arg
        public void TraceFunctionalLvl(ICONISTraceLevel lvl, string message)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.FUNCTIONAL, lvl))
            {
                Trace.WriteLine("	     FUNCTIONAL\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + message);
            }
        }

        //! Trace a functional message of any level, 1 argument
        public void TraceFunctionalLvl(ICONISTraceLevel lvl, string message, object arg1)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.FUNCTIONAL, lvl))
            {
                Trace.WriteLine("	     FUNCTIONAL\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, arg1));
            }
        }

        //! Trace a functional message of any level, 2 arguments
        public void TraceFunctionalLvl(ICONISTraceLevel lvl, string message, object arg1, object arg2)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.FUNCTIONAL, lvl))
            {
                Trace.WriteLine("	     FUNCTIONAL\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2));
            }
        }

        //! Trace a functional message of any level, 3 arguments
        public void TraceFunctionalLvl(ICONISTraceLevel lvl, string message, object arg1, object arg2, object arg3)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.FUNCTIONAL, lvl))
            {
                Trace.WriteLine("	     FUNCTIONAL\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2, arg3));
            }
        }

        //! Trace a functional message of any level, any number of arguments
        public void TraceFunctionalLvl(ICONISTraceLevel lvl, string message, params object[] args)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.FUNCTIONAL, lvl))
            {
                Trace.WriteLine("	     FUNCTIONAL\t\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, args));
            }
        }

        //! Trace an performance message, without args
        public void TracePerformance(string message)
        {
            TracePerformanceLvl(ICONISTraceLevel.LEVEL_3, message);
        }

        //! Trace a performance message, with 1 arg
        public void TracePerformance(string message, object arg1)
        {
            TracePerformanceLvl(ICONISTraceLevel.LEVEL_3, message, arg1);
        }

        //! Trace a performance message, with 2 args
        public void TracePerformance(string message, object arg1, object arg2)
        {
            TracePerformanceLvl(ICONISTraceLevel.LEVEL_3, message, arg1, arg2);
        }

        //! Trace a performance message, with 3 args
        public void TracePerformance(string message, object arg1, object arg2, object arg3)
        {
            TracePerformanceLvl(ICONISTraceLevel.LEVEL_3, message, arg1, arg2, arg3);
        }

        //! Trace a performance message, with any number of args (>3)
        public void TracePerformance(string message, params object[] obj)
        {
            TracePerformanceLvl(ICONISTraceLevel.LEVEL_3, message, obj);
        }

        //! Trace a functional message of any level, no arg
        public void TracePerformanceLvl(ICONISTraceLevel lvl, string message)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.PERFORMANCE, lvl))
            {
                Trace.WriteLine("	     PERFORMANCE\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + message);
            }
        }

        //! Trace a functional message of any level, 1 argument
        public void TracePerformanceLvl(ICONISTraceLevel lvl, string message, object arg1)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.PERFORMANCE, lvl))
            {
                Trace.WriteLine("	     PERFORMANCE\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, arg1));
            }
        }

        //! Trace a functional message of any level, 2 arguments
        public void TracePerformanceLvl(ICONISTraceLevel lvl, string message, object arg1, object arg2)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.PERFORMANCE, lvl))
            {
                Trace.WriteLine("	     PERFORMANCE\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2));
            }
        }

        //! Trace a functional message of any level, 3 arguments
        public void TracePerformanceLvl(ICONISTraceLevel lvl, string message, object arg1, object arg2, object arg3)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.PERFORMANCE, lvl))
            {
                Trace.WriteLine("	     PERFORMANCE\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, arg1, arg2, arg3));
            }
        }

        //! Trace a functional message of any level, any number of arguments
        public void TracePerformanceLvl(ICONISTraceLevel lvl, string message, params object[] args)
        {
            if (m_TraceSwitch.IsTraceable(ICONISTraceType.PERFORMANCE, lvl))
            {
                Trace.WriteLine("	     PERFORMANCE\t" + ((ulong)lvl).ToString() + "\t" + m_strComponentName + "\t\t" + String.Format(message, args));
            }
        }
        
        // Check if traces DEBUG level 3 are activated
        public bool IsTraceableDebug()
        {
            return m_TraceSwitch.IsTraceable(ICONISTraceType.DEBUG, ICONISTraceLevel.LEVEL_3);
        }

        // Check if traces FUNCTIONAL level 3 are activated
        public bool IsTraceableFunctional()
        {
            return m_TraceSwitch.IsTraceable(ICONISTraceType.FUNCTIONAL, ICONISTraceLevel.LEVEL_3);
        }

        // Check if traces PERFORMANCE level 3 are activated
        public bool IsTraceablePerformance()
        {
            return m_TraceSwitch.IsTraceable(ICONISTraceType.PERFORMANCE, ICONISTraceLevel.LEVEL_3);
        }

        // Check if traces of given type and level are activated
        public bool IsTraceable(ICONISTraceType type, ICONISTraceLevel lvl)
        {
            return m_TraceSwitch.IsTraceable(type, lvl);
        }

        /// Set the activated trace types
        public void SetActivatedTraceTypes(ulong lTypeMask)
        {
            m_TraceSwitch.SetActivatedTraceTypes(lTypeMask);
        }

        /// Add an trace type and level
        public void ActivateTraceType(ICONISTraceType type)
        {
            m_TraceSwitch.ActivateTraceType(type);
        }


        /// Get or Set the activated trace level
        public ICONISTraceLevel CurrentTraceLevel
        {
            get
            {
                return m_TraceSwitch.CurrentTraceLevel;
            }
            set
            {
                m_TraceSwitch.CurrentTraceLevel = value;
            }
        }

        /// <summary>
        /// Get or set the max number of lines in trace file (excluding header and footer)
        /// </summary>
        public long MaxNumberOfLines
        {
            get
            {
                if (m_IconisListener != null)
                    return m_IconisListener.MaxNumberOfLines;
                else
                    return 0;
            }
            set
            {
                if (m_IconisListener != null)
                    m_IconisListener.MaxNumberOfLines = value;
            }
        }
    }
}
