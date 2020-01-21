using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;
using System.Timers;
using System.Xml;

namespace IconisUtilities
{

    //! Static class used to keep all individual stats
    public static class PerfStats
    {
        //! Class to keep individual stat about a single part of code
        private class PerfStat
        {
            //! Name of the performance stat used to keep tracks of it( can be "ClassName::MethodName")
            private String m_strMethodName;
            //! Total number of calls to the monitored code
            private UInt64 m_nbCalls;
            //! Total time spent in the monitored code since the beginning
            private TimeSpan m_totalTime;
            //! Max time spent in a single call
            private TimeSpan m_slowestCall;

            //! Constructor without a call
            public PerfStat(String name)
            {
                m_strMethodName = name;
                m_nbCalls = 0;
                m_totalTime = TimeSpan.Zero;
                m_slowestCall = TimeSpan.Zero;
            }

            //! Constructor with already some time spent in the code
            public PerfStat(String name, TimeSpan ts)
            {
                m_strMethodName = name;
                m_nbCalls = 1;
                m_totalTime = m_slowestCall = ts;
            }

            // Get method name
            public String MethodName() { return m_strMethodName; }

            // Add a call with the given time used
            public void AddCall(TimeSpan ts)
            {
                ++m_nbCalls;
                m_totalTime = m_totalTime.Add(ts);
                if (ts > m_slowestCall)
                    m_slowestCall = ts;
            }

            //! converts as displayable string
            public override String ToString()
            {
                if (m_nbCalls > 0)
                {
                    if (m_totalTime.TotalSeconds >= 1)
                        return String.Format("{0} - Called [{1}] times - slowest call [{5}]ms - time/call [{2}]ms  - total time [{3}s:{4}ms]",
                            m_strMethodName, m_nbCalls, (m_totalTime.TotalMilliseconds / m_nbCalls), Math.Round(m_totalTime.TotalSeconds, 0), m_totalTime.Milliseconds, m_slowestCall.TotalMilliseconds);
                    else
                        return String.Format("{0} - Called [{1}] times - slowest call [{4}]ms - time/call [{2}]ms - total time [{3}ms]",
                            m_strMethodName, m_nbCalls, (m_totalTime.TotalMilliseconds / m_nbCalls), m_totalTime.Milliseconds, m_slowestCall.TotalMilliseconds);
                }
                else
                    return String.Format("{0} - Not Called", m_strMethodName);
            }
        }

        //! list of individual perf stat
        private static List<PerfStat> _perfStats = new List<PerfStat>();
        //! Counter to keep track of the total time used by the program
        private static Stopwatch _GlobalStopWatch = new Stopwatch();

        //! Is performance monitoring active ?
        private static bool _bPerfMonitoringActive = false;

        //! Timer to output the stats
        private static Timer _timer = new System.Timers.Timer();

        //! tracer
        private static IconisTracer _tracer = null;

        //! Start monitoring
        public static void StartMonitoring(IconisTracer tracer)
        {
            if (_bPerfMonitoringActive == false)
            {
                _bPerfMonitoringActive = true;
                // interval in milliseconds (default = 30min = 1800s)
                _timer.Interval = 1800000;
                _timer.Elapsed += new System.Timers.ElapsedEventHandler(timer_Elapsed);
                _timer.Enabled = true;
                _GlobalStopWatch.Start();
                _tracer = tracer;
            }
        }

        //! Stop monitoring
        public static void StopMonitoring()
        {
            _GlobalStopWatch.Stop();
            _bPerfMonitoringActive = false;            
            _timer.Enabled = false;
        }

        //! Stop and reset monitoring info
        public static void StopAndResetMonitoring()
        {
            _GlobalStopWatch.Reset();
            _bPerfMonitoringActive = false;
            _timer.Enabled = false;
            _GlobalStopWatch.Stop();
            _perfStats.Clear();
        }

        //! output frequency in milliseconds(0 = disable timer)
        public static Double OutputFrequency
        {
            get
            {
                if (_timer.Enabled == true)
                    return _timer.Interval;
                else
                    return 0;
            }
            set
            {
                if (value > 0)
                {
                    _timer.Interval = value;
                }
                else
                {
                    _timer.Enabled = false;
                }
            }
        }

        //! Get total time since monitoring starts
        public static TimeSpan GetTimeSinceStart()
        {
            return _GlobalStopWatch.Elapsed;
        }

        //! Is active ?
        public static bool IsActive() { return _bPerfMonitoringActive; }

        //! Add a call to a Perf Stat, used by PerfHelper
        public static void AddCall(String strName, TimeSpan ts)
        {
            if (_bPerfMonitoringActive == false)
                return;

            for (int i = 0; i < _perfStats.Count; ++i)
            {
                if (_perfStats[i].MethodName() == strName)
                {
                    _perfStats[i].AddCall(ts);
                    return;
                }
            }

            // not found, add in list
            _perfStats.Add(new PerfStat(strName, ts));
        }

        //! build a string to represent the stats
        public static String AsString()
        {
            TimeSpan time = _GlobalStopWatch.Elapsed;
            String str = String.Format("Total elapsed time since program monitoring starts = [{0}h {1}m {2}s {3}ms]",
                Math.Round(time.TotalHours, 0), time.Minutes, time.Seconds, time.Milliseconds);
            foreach (PerfStat st in _perfStats)
            {
                str += "\n";
                str += st.ToString();                
            }
            return str;
        }

        //! Trace in specified tracer
        public static void TraceInfos(IconisTracer icoTracer)
        {
            if (icoTracer != null)
            {
                TimeSpan time = _GlobalStopWatch.Elapsed;
                String str = String.Format("Total elapsed time since program monitoring starts = [{0}h {1}m {2}s {3}ms]",
                    Math.Round(time.TotalHours, 0), time.Minutes, time.Seconds, time.Milliseconds);

                icoTracer.TracePerformance(str);

                foreach (PerfStat st in _perfStats)
                {
                    icoTracer.TracePerformance(st.ToString());
                }
            }
        }

        //! Called by the timer
        private static void timer_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            TraceInfos(_tracer);
        }
    }

    //! Helper to manage performance tracing
    public class PerfHelper : IDisposable
    {
        //! Build the perf helper, immediately start the counter
        public PerfHelper(String name)
        {
            if (PerfStats.IsActive())
            {
                _strName = name;
                stopwatch = Stopwatch.StartNew();
            }
        }

        //! Stop the counter (it cannot be started again), add info in PerfStats
        public void Stop()
        {
            if (stopwatch != null && stopwatch.IsRunning)
            {
                stopwatch.Stop();
                PerfStats.AddCall(_strName, stopwatch.Elapsed);
            }
        }

        // Called when the object is disposed (to be used with -> using(PerfHelper....) {code to monitor...} )
        public void Dispose()
        {
            Stop();
        }

        //! Private stop watch to get the time taken by the code to monitor (between creation and call to 'Stop')
        private Stopwatch stopwatch = null;

        //! ID used to monitor the perf (for instance as "ClassName::MethodName" )
        private String _strName;
    }
}
