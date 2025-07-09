DECLARE @current_tracefilename VARCHAR(500);
DECLARE @0_tracefilename VARCHAR(500);
DECLARE @indx INT;
SELECT @current_tracefilename = path
FROM sys.traces
WHERE is_default = 1;
SET @current_tracefilename = REVERSE(@current_tracefilename);
SELECT @indx = PATINDEX('%\%', @current_tracefilename);
SET @current_tracefilename = REVERSE(@current_tracefilename);
SET @0_tracefilename = LEFT(@current_tracefilename, LEN(@current_tracefilename) - @indx) + '\log.trc';
SELECT t.DatabaseName, 
       te.name, 
       t.Filename, 
       CONVERT(DECIMAL(10, 3), t.Duration / 1000000e0) AS TimeTakenSeconds, 
       t.StartTime, 
       t.EndTime, 
       (t.IntegerData * 8.0 / 1024) AS "ChangeInSize MB", 
       t.ApplicationName, 
       t.HostName, 
       t.LoginName
FROM ::fn_trace_gettable(@0_tracefilename, DEFAULT) t
     INNER JOIN sys.trace_events AS te ON t.EventClass = te.trace_event_id
	 INNER JOIN sys.databases d ON t.DatabaseName = d.name AND d.name NOT IN ('master', 'tempdb', 'model', 'msdb')
WHERE(te.trace_event_id >= 92
      AND te.trace_event_id <= 95) AND t.DatabaseName <> 'tempdb'
ORDER BY t.StartTime;


