USE [master]
GO

CREATE TABLE [dbo].TLOG_SHRINK_LOG(
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LogType] [varchar](20) NOT NULL,
	[ExecDateTime] [datetime] NOT NULL,
	[DatabaseName] [varchar](100) NOT NULL,
	[ErrorMessage] [varchar](max) NULL,
	[ErrorSeverity] [int] NULL,
	[Errorstate] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO