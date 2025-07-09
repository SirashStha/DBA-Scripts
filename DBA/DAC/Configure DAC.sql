EXEC sp_configure 'remote access', 0;
GO
RECONFIGURE;
GO

sp_configure 'remote admin connections', 1;
GO

SELECT *
FROM sys.configurations
WHERE value <> value_in_use;
