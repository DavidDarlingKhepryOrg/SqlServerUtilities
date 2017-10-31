SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		David Darling
-- Create date: 2017-10-31
-- Description:	This T-SQL procedure creates both a
-- server auditor as well as a database auditor.
-- In addition, it also adds auditing for
-- tables/views/functions (INSERT, UPDATE, DELETE, SELECT),
-- as well as stored procedures (EXECUTE).
-- =============================================
CREATE PROCEDURE dbo.utl_SetUpAuditing 
	-- Add the parameters for the stored procedure here
	@svrAuditName sysname = 'Server Audit SchoolDB',
	@dbAuditSpec sysname = 'Database Audit SchoolDB',
	@raiseMsgsAsErrors tinyint = 0
AS
BEGIN
	DECLARE @myCursor CURSOR;
	DECLARE @myName VARCHAR(50);
	DECLARE @sql NVARCHAR(MAX);

	-- SET NOCOUNT ON added to prevent extra result
	-- sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS (SELECT name FROM master.sys.server_audits WHERE name = @svrAuditName)
	BEGIN
		SET @sql = 'USE master; ALTER SERVER AUDIT [' + @svrAuditName + '] WITH (STATE = OFF);';
		IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
		EXECUTE sp_executesql @sql;
		SET @sql = 'USE master; DROP SERVER AUDIT [' + @svrAuditName + '];';
		IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
		EXECUTE sp_executesql @sql;
	END

	SET @sql = '
	USE master;
	CREATE SERVER AUDIT [' + @svrAuditName + ']
	TO FILE 
	( FILEPATH = N''C:\AuditLogs\SchoolDB''
	 ,MAXSIZE = 20 MB
	 ,MAX_FILES = 50
	 ,RESERVE_DISK_SPACE = OFF
	)
	WITH
	( QUEUE_DELAY = 1000  -- equal to 1 second
	 ,ON_FAILURE = CONTINUE
	);';
	IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR(@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
	EXECUTE sp_executesql @sql;

	IF EXISTS (SELECT name FROM sys.database_audit_specifications WHERE name = @dbAuditSpec)
	BEGIN
		SET @sql = 'ALTER DATABASE AUDIT SPECIFICATION [' + @dbAuditSpec + '] WITH (STATE = OFF);';
		IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
		EXECUTE sp_executesql @sql;

		SET @sql = 'DROP DATABASE AUDIT SPECIFICATION [' + @dbAuditSpec + '];';
		IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
		EXECUTE sp_executesql @sql;
	END

	SET @sql = 'CREATE DATABASE AUDIT SPECIFICATION [' + @dbAuditSpec + '] FOR SERVER AUDIT [' + @svrAuditName +'];';
	IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
	EXECUTE sp_executesql @sql;

	-- TYPE can be 'U' for USER_TABLE, 'V' for VIEW, and 'IF' for INLINE-TABLE-VALUE-FUNCTION
	SET @myCursor = CURSOR FOR SELECT [name] FROM sys.objects WHERE TYPE IN ('U','V','IF','TF') AND left([name],3) != 'sys';
	
	OPEN @myCursor;
	FETCH NEXT FROM @myCursor INTO @myName;
	
	while @@FETCH_STATUS = 0
	BEGIN
		SET @sql = 'ALTER DATABASE AUDIT SPECIFICATION [' + @dbAuditSpec + '] ' +
				   'FOR SERVER AUDIT [' + @svrAuditName + '] ADD (DELETE, INSERT, UPDATE, SELECT ON OBJECT::dbo.' + @myName + ' BY public);';
		IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
		EXECUTE sp_executesql @sql;

		FETCH NEXT FROM @myCursor INTO @myName;
	END;
	
	CLOSE @myCursor;
	DEALLOCATE @myCursor; 

	-- TYPE can be 'P' for STORED_PROCEDURE
	SET @myCursor = CURSOR FOR SELECT [name] FROM sys.objects WHERE TYPE = 'P' and left([name],3) != 'sp_';
	
	OPEN @myCursor;
	FETCH NEXT FROM @myCursor INTO @myName;
	
	while @@FETCH_STATUS = 0
	BEGIN
		SET @sql = 'ALTER DATABASE AUDIT SPECIFICATION [' + @dbAuditSpec + '] ' +
				   'FOR SERVER AUDIT [' + @svrAuditName +'] ADD (EXECUTE ON OBJECT::dbo.' + @myName + ' BY public);';
		IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
		EXECUTE sp_executesql @sql;

		FETCH NEXT FROM @myCursor INTO @myName;
	END;
	
	CLOSE @myCursor;
	DEALLOCATE @myCursor;

	SET @sql = 'USE master; ALTER SERVER AUDIT [' + @svrAuditName + '] WITH (STATE = ON);';
	IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
	EXECUTE sp_executesql @sql;

	SET @sql = 'ALTER DATABASE AUDIT SPECIFICATION [' + @dbAuditSpec + '] WITH (STATE = ON);';
	IF (ISNULL(@raiseMsgsAsErrors,0)) = 1 RAISERROR (@sql, 0, 1) WITH NOWAIT ELSE PRINT @sql;
	EXECUTE sp_executesql @sql;
 
END
GO
