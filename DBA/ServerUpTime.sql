SELECT @@servername as ServerName

, SQLServer_UpTime_YY

, SQLServer_UpTime_MM

, SQLServer_UpTime_DD

, (SQLServer_UpTime_mi % 1440) / 60 as NoHours

, (SQLServer_UpTime_mi % 60) as NoMinutes

from (

SELECT datediff(yy, login_time, getdate()) as SQLServer_UpTime_YY

, datediff(mm, dateadd(yy,datediff(yy, login_time, getdate()),login_time) , getdate()) as SQLServer_UpTime_MM

, datediff(dd, dateadd(mm,datediff(mm, dateadd(yy,datediff(yy, login_time, getdate()),login_time) , getdate()) ,login_time) , getdate()) as SQLServer_UpTime_DD

, datediff(mi, login_time, getdate()) as SQLServer_UpTime_mi

FROM sys.dm_exec_sessions

WHERE session_id = 1

) a

go