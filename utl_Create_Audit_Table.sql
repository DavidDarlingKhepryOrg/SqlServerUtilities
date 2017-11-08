/*
Copyright 2017 David Darling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

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

