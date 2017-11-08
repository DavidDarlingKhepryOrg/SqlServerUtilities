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
-- Description:	Table-by-table, create an audit
--		trigger for each user-table
-- =============================================
CREATE PROCEDURE [dbo].[utl_Create_Audit_Trigger_on_Tables]
	@data_schema_name sysname = 'dbo', 
	@data_trigger_prefix sysname = 'trg',
	@data_trigger_suffix sysname = 'Auditor',
	@audit_schema_name sysname = 'auditing',
	@audit_table_name sysname = 'Audit',
	@drop_existing_audit_trigger tinyint = 0,
	@raiseMsgsAsErrors tinyint = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE	@return_value int;
	DECLARE @data_table_name sysname;
	DECLARE @primary_key_column_name sysname;
	DECLARE @myCursor CURSOR;
	DECLARE @trigger_name sysname;
	DECLARE @sql nvarchar(max);

	-- TYPE can be 'U' for USER_TABLE, 'V' for VIEW, and 'IF' for INLINE-TABLE-VALUE-FUNCTION
	-- SET @myCursor = CURSOR FOR SELECT [name] FROM sys.objects WHERE TYPE IN ('U') AND left([name],3) != 'sys';
	SET @myCursor = CURSOR FOR
						SELECT
							t.TABLE_NAME,
							k.COLUMN_NAME
						FROM
							INFORMATION_SCHEMA.TABLES t
						INNER JOIN
							INFORMATION_SCHEMA.KEY_COLUMN_USAGE k
						ON
							t.TABLE_CATALOG = k.TABLE_CATALOG
							and
							t.TABLE_SCHEMA = k.TABLE_SCHEMA
							and
							t.TABLE_NAME = k.TABLE_NAME
						WHERE t.TABLE_SCHEMA in (@data_schema_name)
						AND t.TABLE_TYPE in ('BASE TABLE')
						AND LEFT(t.TABLE_NAME,3) != 'sys'
						AND LEFT(k.CONSTRAINT_NAME,3) = 'PK_';
							  	
	OPEN @myCursor;
	FETCH NEXT FROM @myCursor INTO @data_table_name, @primary_key_column_name;
	
	while @@FETCH_STATUS = 0
	BEGIN

		SET @trigger_name = @data_trigger_prefix+'_'+@data_table_name+'_'+@data_trigger_suffix;

		IF (@drop_existing_audit_trigger = 1)
		BEGIN
			SET @sql = 'DROP TRIGGER IF EXISTS ' + @trigger_name;
			PRINT @sql;
			EXEC sp_executesql @sql;
		END

		
		IF NOT EXISTS (select name from sys.triggers where name = @trigger_name)
		BEGIN
			EXEC	@return_value = [dbo].[usp_Create_Audit_Trigger_on_Table]
					@data_schema_name = @data_schema_name,
					@data_table_name = @data_table_name,
					@data_trigger_prefix = @data_trigger_prefix,
					@data_trigger_suffix = @data_trigger_suffix,
					@audit_schema_name = @audit_schema_name,
					@audit_table_name = @audit_table_name,
					@primary_key_column_name = @primary_key_column_name;
			PRINT 'Trigger ' + @trigger_name + ' created successfully!';
			PRINT '';

			SELECT	'Data Table Name' = @data_table_name, 'Return Value' = @return_value;

			-- IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
		END
		ELSE
		BEGIN
			PRINT 'Trigger ' + @trigger_name + ' not created as it already exists!';
		END

		FETCH NEXT FROM @myCursor INTO @data_table_name, @primary_key_column_name;
	END;
	
	CLOSE @myCursor;
	DEALLOCATE @myCursor; 

END
