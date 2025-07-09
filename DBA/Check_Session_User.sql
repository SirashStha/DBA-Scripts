--Check Session
SELECT session_id, login_name
FROM sys.dm_exec_sessions
WHERE login_name = 'sa'

--Kill Session with session id
KILL 56