USE [INFINITY_032_002]
GO

DROP TABLE IF EXISTS [GLTRAN_DETL_NEW]
GO

CREATE TABLE [dbo].[GLTRAN_DETL_NEW](
	[VCH_NO] [varchar](50) NOT NULL,
	[AC_NO] [varchar](50) NOT NULL,
	[GL_CODE] [varchar](50) NOT NULL,
	[CUR_CODE] [varchar](50) NOT NULL,
	[TRAN_CODE] [varchar](50) NULL,
	[PREV_BAL] [decimal](18, 2) NULL,
	[AMT] [decimal](18, 2) NULL,
	[LCY_AMT] [decimal](18, 2) NULL,
	[DESC1] [varchar](200) NULL,
	[DESC2] [varchar](200) NULL,
	[DESC3] [varchar](200) NULL,
	[REF_NO] [varchar](50) NULL,
	[INST_CODE] [varchar](50) NULL,
	[INST_NO] [varchar](50) NULL,
	[BANK_CODE] [varchar](50) NULL,
	[BANK_BR_CODE] [varchar](50) NULL,
	[PURPOSE_CODE] [varchar](50) NULL,
	[OVDRN] [varchar](50) NULL,
	[OVDRN_AMT] [decimal](18, 2) NULL,
	[EXCH_RATE] [decimal](18, 2) NULL,
	[INTR_BR_CODE] [varchar](50) NULL,
	[VALUE_DATE] [date] NULL,
	[EVENING_COUNTER] [varchar](50) NULL,
	[COA_SERIAL_NO] [varchar](50) NOT NULL,
	[BR_CODE] [varchar](50) NULL,
	[PRODUCT_CODE] [varchar](50) NULL,
	[INST_DATE] [date] NULL,
	[TRAN_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[SOURCE_OF_FUND] [int] NULL
) ON [PS_YEARLY_TRANSACTIONS]([VALUE_DATE])
GO


