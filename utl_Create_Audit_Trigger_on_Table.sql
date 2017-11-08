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
-- =============================================
-- Author:	David Darling
-- Create date: 2017-11-07
-- Description:	Creates an auditing trigger
--		on the specified table
-- =============================================
CREATE PROCEDURE [dbo].[utl_Create_Audit_Trigger_on_Table] 
	@data_schema_name sysname = 'dbo', 
	@data_table_name sysname = 'TestTable',
	@data_trigger_prefix sysname = 'trg',
	@data_trigger_suffix sysname = 'Auditor',
	@audit_schema_name sysname = 'auditing',
	@audit_table_name sysname = 'Audit',
	@primary_key_column_name sysname = 'ID'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC ('
	CREATE TRIGGER ['+@data_schema_name+'].['+@data_trigger_prefix+'_'+@data_table_name+'_'+@data_trigger_suffix+'] ON ['+@data_schema_name+'].['+@data_table_name+'] FOR INSERT, UPDATE, DELETE
	AS
	BEGIN
		SET NOCOUNT ON;

		  INSERT INTO ['+@audit_schema_name+'].['+@audit_table_name+'] (PartitionKey, [TxType], PK, FieldName, OldValue, NewValue)
		  SELECT
			 '''+@data_table_name+''' as PartitionKey,
			 CASE
				 WHEN NOT EXISTS (SELECT '+@primary_key_column_name+' FROM deleted WHERE '+@primary_key_column_name+' = ISNULL(ins.PK,del.PK)) THEN ''I''
				 WHEN NOT EXISTS (SELECT '+@primary_key_column_name+' FROM inserted WHERE '+@primary_key_column_name+' = ISNULL(ins.PK,del.PK)) THEN ''D''
				 ELSE ''U'' END as [TxType],
			 ISNULL(ins.PK,del.PK) as PK,
			 ISNULL(ins.FieldName,del.FieldName) as FieldName,
			 del.FieldValue as OldValue,
			 ins.FieldValue as NewValue
		  FROM 
		  (	SELECT
			  insRowTbl.PK,
			  attr.insRow.value(''local-name(.)'', ''nvarchar(128)'') as FieldName,
			  attr.insRow.value(''.'', ''nvarchar(max)'') as FieldValue
			FROM
			( Select      
				i.'+@primary_key_column_name+' as PK,
				convert(xml, (select i.* for xml raw)) as insRowCol
			  from inserted as i) as insRowTbl
			  CROSS APPLY insRowTbl.insRowCol.nodes(''/row/@*'') as attr(insRow)) as ins
			  FULL OUTER JOIN 
				(SELECT
					 delRowTbl.PK,
					 attr.delRow.value(''local-name(.)'', ''nvarchar(128)'') as FieldName,
					 attr.delRow.value(''.'', ''nvarchar(max)'') as FieldValue
				 FROM (Select      
						d.'+@primary_key_column_name+' as PK,
						convert(xml, (select d.* for xml raw)) as delRowCol
						from deleted as d
					  ) as delRowTbl
			  CROSS APPLY delRowTbl.delRowCol.nodes(''/row/@*'') as attr(delRow)) as del on ins.PK = del.PK and ins.FieldName = del.FieldName
			  WHERE isnull(ins.FieldName,del.FieldName) not in ('''+@primary_key_column_name+''')
				 and ((ins.FieldValue is null and del.FieldValue is not null) or (ins.FieldValue is not null and del.FieldValue is null) or (ins.FieldValue != del.FieldValue))

	END')
END
