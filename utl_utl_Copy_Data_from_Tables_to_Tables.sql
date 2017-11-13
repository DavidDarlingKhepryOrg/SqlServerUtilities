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
-- Author:	    David Darling
-- Create date: 2017-11-13
-- Description:	Table-by-table, create an audit
--		          trigger for each user-table
-- =============================================
ALTER PROCEDURE [dbo].[utl_Copy_Data_from_Tables_to_Tables]
	@src_database_name sysname NULL = 'SourceDbName',
	@src_schema_name sysname NULL = 'SourceSchemaName',
	@src_table_prefix sysname NULL = 'SRC_',
	@tgt_database_name sysname NULL = 'TargetDbName',
	@tgt_schema_name sysname NULL = 'TargetSchemaName',
	@tgt_table_prefix sysname NULL = 'TGT_',
	@truncate_tables bit NULL = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE	@return_value int;
	DECLARE @src_table_name sysname;
	DECLARE @tgt_table_name sysname;
	DECLARE @myCursor CURSOR;
	DECLARE @sql nvarchar(max);

	DECLARE @retry_tables TABLE
	(
		tgt_table_name sysname,
		src_table_name sysname
	);

	print @tgt_database_name;
	print @tgt_schema_name;
	print @tgt_table_prefix;

	SET @myCursor = CURSOR FOR
						SELECT
							tgt.TABLE_NAME
						FROM
							INFORMATION_SCHEMA.TABLES tgt
						WHERE
							tgt.TABLE_CATALOG = @tgt_database_name
						AND
							tgt.TABLE_SCHEMA = @tgt_schema_name
						AND
							@tgt_table_prefix = '' or tgt.TABLE_NAME like @tgt_table_prefix
						ORDER BY
							tgt.TABLE_NAME;

	OPEN @myCursor;
	FETCH NEXT FROM @myCursor INTO @tgt_table_name;
	
	while @@FETCH_STATUS = 0
	BEGIN
		
		PRINT @tgt_table_name;

		SET @src_table_name = '[' + @src_database_name + '].[' + @src_schema_name + '].[' + @src_table_prefix + @tgt_table_name + ']';
		set @tgt_table_name = '[' + @tgt_database_name + '].[' + @tgt_schema_name + '].[' + @tgt_table_name + ']';

		IF (@truncate_tables = 1)
		BEGIN
			SET @sql = 'DELETE FROM ' + @tgt_table_name + ';';
			PRINT @sql;
			EXEC sp_executesql @sql;
		END

		SET @sql = 'INSERT INTO ' + @tgt_table_name + ' SELECT * FROM ' + @src_table_name + ';';

		begin try
			PRINT @sql;
			EXEC sp_executesql @sql;
		end try
		begin catch
			PRINT 'Failure: ' + @sql;
			INSERT INTO @retry_tables (tgt_table_name, src_table_name) VALUES(@tgt_table_name, @src_table_name);
		end catch;

		PRINT '';

		FETCH NEXT FROM @myCursor INTO @tgt_table_name
	END;

	PRINT '======================================================';
	PRINT 'RETRY ANY TABLES THAT FAILED TO COPY IN THE FIRST PASS';
	PRINT '======================================================';
	PRINT '';
	
	CLOSE @myCursor;
	DEALLOCATE @myCursor; 
	SET @myCursor = CURSOR FOR
						SELECT
							tgt_table_name,
							src_table_name
						FROM
							@retry_tables tgt
						ORDER BY
							tgt_table_name desc;

	OPEN @myCursor;
	FETCH NEXT FROM @myCursor INTO @tgt_table_name, @src_table_name;
	
	while @@FETCH_STATUS = 0
	BEGIN
		
		PRINT @tgt_table_name;

		IF (@truncate_tables = 1)
		BEGIN
			SET @sql = 'DELETE FROM ' + @tgt_table_name + ';';
			PRINT @sql;
			EXEC sp_executesql @sql;
		END

		SET @sql = 'INSERT INTO ' + @tgt_table_name + ' SELECT * FROM ' + @src_table_name + ';';

		begin try
			PRINT @sql;
			EXEC sp_executesql @sql;
		end try
		begin catch
			PRINT 'Failure: ' + @sql;
		end catch;

		PRINT '';

		FETCH NEXT FROM @myCursor INTO @tgt_table_name, @src_table_name
	END;
	
	CLOSE @myCursor;
	DEALLOCATE @myCursor; 

END
