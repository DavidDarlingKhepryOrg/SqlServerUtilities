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
-- Author:		David Darling
-- Create date: 2017-11-08
-- Description:	Merge (Update or Insert) rows
-- =============================================
CREATE PROCEDURE [dbo].[mrg_TestTable_IU] 
	@model varchar(50) = NULL,
	@description varchar(255) = NULL,
	@ID bigint OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result
	-- sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	MERGE dbo.TestTable AS Target
	USING
	(
		SELECT
			@model as model,
			@description as description,
			@ID as ID
	)
	AS Source
	ON
		Target.ID = Source.ID
	WHEN MATCHED THEN
		UPDATE SET
			Target.model = ISNULL(@model, Target.model),
			Target.[description] = ISNULL(@description, Target.[description])
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (model, [description])
		VALUES (@model, @description);

	SET @ID = ISNULL(@ID, SCOPE_IDENTITY());

	-- OUTPUT $action, Inserted.*, Deleted.*;
END
