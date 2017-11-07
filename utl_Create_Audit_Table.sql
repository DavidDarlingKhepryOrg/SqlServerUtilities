SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [auditing].[Audit](
	[PartitionKey] [nvarchar](128) NULL,
	[RowKey] [bigint] IDENTITY(1,1) NOT NULL,
	[TxType] [char](1) NULL,
	[PK] [int] NULL,
	[FieldName] [nvarchar](128) NULL,
	[OldValue] [nvarchar](max) NULL,
	[NewValue] [nvarchar](max) NULL,
	[TxDateUTC] [datetime] NULL,
	[SystemUser] [nvarchar](128) NULL,
	[CurrentUser] [nvarchar](128) NULL,
 CONSTRAINT [PK_Audit] PRIMARY KEY CLUSTERED 
(
	[RowKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [auditing].[Audit] ADD  CONSTRAINT [DF_Audit_TxDateUTC]  DEFAULT (getutcdate()) FOR [TxDateUTC]
GO

ALTER TABLE [auditing].[Audit] ADD  CONSTRAINT [DF_Audit_SystemUser]  DEFAULT (suser_sname()) FOR [SystemUser]
GO

ALTER TABLE [auditing].[Audit] ADD  CONSTRAINT [DF_Audit_CurrentUser]  DEFAULT (user_name()) FOR [CurrentUser]
GO

