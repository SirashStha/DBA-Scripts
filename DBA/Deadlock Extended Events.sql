CREATE EVENT SESSION [DeadlockMonitor] ON SERVER 
ADD EVENT sqlserver.lock_deadlock(
    ACTION (sqlserver.sql_text, sqlserver.tsql_stack)
) 
ADD TARGET package0.event_file (SET filename = N'DeadlockMonitor.xel', max_file_size = 5)
WITH (STARTUP_STATE = ON);
GO

-- Start the session
ALTER EVENT SESSION [DeadlockMonitor] ON SERVER STATE = START;

-- Stop the session when you no longer need it
ALTER EVENT SESSION [DeadlockMonitor] ON SERVER STATE = STOP;

-- Read the event file
SELECT * 
FROM sys.fn_xe_file_target_read_file('DeadlockMonitor*.xel', NULL, NULL, NULL);
