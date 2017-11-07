SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		  David Darling
-- Create date: 2017-11-07
-- Description:	Table-by-table, create an audit
--				      trigger for each user-table
-- =============================================
CREATE PROCEDURE [dbo].[utl_Create_Audit_Trigger_on_Tables]
	@data_schema_name sysname = 'dbo', 
	@data_trigger_prefix sysname = 'trg',
	@data_trigger_suffix sysname = 'Auditor',
	@audit_schema_name sysname = 'auditing',
	@audit_table_name sysname = 'Audit',
	@primary_key_column_name sysname = 'ID',
	@raiseMsgsAsErrors tinyint = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE	@return_value int;
	DECLARE @data_table_name sysname;
	DECLARE @myCursor CURSOR;

	-- TYPE can be 'U' for USER_TABLE, 'V' for VIEW, and 'IF' for INLINE-TABLE-VALUE-FUNCTION
	-- SET @myCursor = CURSOR FOR SELECT [name] FROM sys.objects WHERE TYPE IN ('U') AND left([name],3) != 'sys';
	SET @myCursor = CURSOR FOR
						SELECT [TABLE_NAME]
						FROM INFORMATION_SCHEMA.TABLES
						WHERE TABLE_TYPE in ('BASE TABLE')
							  and TABLE_SCHEMA in (@data_schema_name);
							  	
	OPEN @myCursor;
	FETCH NEXT FROM @myCursor INTO @data_table_name;
	
	while @@FETCH_STATUS = 0
	BEGIN

		EXEC	@return_value = [dbo].[utl_Create_Audit_Trigger_on_Table]
				@data_schema_name = @data_schema_name,
				@data_table_name = @data_table_name,
				@data_trigger_prefix = @data_trigger_prefix,
				@data_trigger_suffix = @data_trigger_suffix,
				@audit_schema_name = @audit_schema_name,
				@audit_table_name = @audit_table_name,
				@primary_key_column_name = @primary_key_column_name;

		SELECT	'Data Table Name' = @data_table_name, 'Return Value' = @return_value;

		-- IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;

		FETCH NEXT FROM @myCursor INTO @data_table_name;
	END;
	
	CLOSE @myCursor;
	DEALLOCATE @myCursor; 

END
GO