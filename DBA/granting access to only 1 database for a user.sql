--Creating Login and granting access to only 1 database

--Step 1: (create a new user)
create LOGIN General WITH PASSWORD='infodev', CHECK_POLICY = OFF;

-- Step 2:(deny view to any database)
USE master;
GO
DENY VIEW ANY DATABASE TO General; 

 -- step 3 (then authorized the user for that specific database , you have to use the  master by doing use master as below)
USE master;
GO
ALTER AUTHORIZATION ON DATABASE::INFINITY_055_001 TO General;
GO

----------------------------------------------------------------------------------------------------







