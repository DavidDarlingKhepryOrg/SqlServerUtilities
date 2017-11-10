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

-- =============================================
-- Author:	David Darling
-- Create date: 2017-11-10
-- Description:	Find missing objects between the
-- 		specified old and new schemata.
-- =============================================

declare @oldSchema1 sysname; set @oldSchema1 = 'old_schema_name1';
declare @oldSchema2 sysname; set @oldSchema2 = NULL;
declare @newSchema1 sysname; set @newSchema1 = 'new_schema_name1';
declare @newSchema2 sysname; set @newSchema2 = 'new_schema_name2';

drop table if exists #r1;
drop table if exists #r2;
drop table if exists #t1;
drop table if exists #t2;
drop table if exists #v1;
drop table if exists #v2;

select
	*
into #r1
from
	INFORMATION_SCHEMA.ROUTINES
where
	ROUTINE_SCHEMA in (@oldSchema1, @oldSchema2)
order by
	ROUTINE_NAME;

-- select * from #r1;

select
	*
into #r2
from
	INFORMATION_SCHEMA.ROUTINES
where
	ROUTINE_SCHEMA in (@newSchema1, @newSchema2)
order by
	ROUTINE_NAME;

-- select * from #r2;

select
	*
into #t1
from
	INFORMATION_SCHEMA.TABLES
where
	TABLE_SCHEMA in (@oldschema1, @oldSchema2)
order by
	TABLE_NAME;

-- select * from #t1;

select
	*
into #t2
from
	INFORMATION_SCHEMA.TABLES
where
	TABLE_SCHEMA in (@newSchema1,@newSchema2)
order by
	TABLE_NAME;

-- select * from #t2;

select
	*
into #v1
from
	INFORMATION_SCHEMA.VIEWS
where
	TABLE_SCHEMA in (@oldSchema1, @oldSchema2)
order by
	TABLE_NAME;

-- select * from #v1;

select
	*
into #v2
from
	INFORMATION_SCHEMA.VIEWS
where
	TABLE_SCHEMA in (@newSchema1,@newSchema2)
order by
	TABLE_NAME;

-- select * from #v2;

select
	'Table' OBJECT_TYPE,
	#t1.TABLE_CATALOG OBJECT_CATALOG,
	#t1.TABLE_SCHEMA OBJECT_SCHEMA,
	#t1.TABLE_NAME [OBJECT_NAME],
	ca1.NOT_IN_SCHEMA
from
	#t1
left outer join
	#t2
on
	#t1.TABLE_NAME = #t2.TABLE_NAME
CROSS APPLY
	(select #t2.TABLE_SCHEMA NOT_IN_SCHEMA FROM #t2 GROUP BY #t2.TABLE_SCHEMA) ca1
where
	#t2.TABLE_NAME is null
union all
select
	'View' OBJECT_TYPE,
	#v1.TABLE_CATALOG OBJECT_CATALOG,
	#v1.TABLE_SCHEMA OBJECT_SCHEMA,
	#v1.TABLE_NAME [OBJECT_NAME],
	ca1.NOT_IN_SCHEMA
from
	#v1
left outer join
	#v2
on
	#v1.TABLE_NAME = #v2.TABLE_NAME
CROSS APPLY
	(select #v2.TABLE_SCHEMA NOT_IN_SCHEMA FROM #v2 GROUP BY #v2.TABLE_SCHEMA) ca1
where
	#v2.TABLE_NAME is null
union all
select
	'Routine' OBJECT_TYPE,
	#r1.ROUTINE_CATALOG OBJECT_CATALOG,
	#r1.ROUTINE_SCHEMA OBJECT_SCHEMA,
	#r1.ROUTINE_NAME [OBJECT_NAME],
	ca1.NOT_IN_SCHEMA
from
	#r1
left outer join
	#r2
on
	#r1.ROUTINE_NAME = #r2.ROUTINE_NAME
CROSS APPLY
	(select #r2.ROUTINE_SCHEMA NOT_IN_SCHEMA FROM #r2 GROUP BY #r2.ROUTINE_SCHEMA) ca1
where
	#r2.ROUTINE_NAME is null
order by
	OBJECT_TYPE,
	[OBJECT_NAME];

select
	'Table' OBJECT_TYPE,
	#t2.TABLE_CATALOG OBJECT_CATALOG,
	#t2.TABLE_SCHEMA OBJECT_SCHEMA,
	#t2.TABLE_NAME [OBJECT_NAME],
	ca1.NOT_IN_SCHEMA
from
	#t2
left outer join
	#t1
on
	#t2.TABLE_NAME = #t1.TABLE_NAME
CROSS APPLY
	(select #t1.TABLE_SCHEMA NOT_IN_SCHEMA FROM #t1 GROUP BY #t1.TABLE_SCHEMA) ca1
where
	#t1.TABLE_NAME is null
	
union all
select
	'View' OBJECT_TYPE,
	#v2.TABLE_CATALOG OBJECT_CATALOG,
	#v2.TABLE_SCHEMA OBJECT_SCHEMA,
	#v2.TABLE_NAME [OBJECT_NAME],
	ca1.NOT_IN_SCHEMA
from
	#v2
left outer join
	#v1
on
	#v2.TABLE_NAME = #v1.TABLE_NAME
CROSS APPLY
	(select #v1.TABLE_SCHEMA NOT_IN_SCHEMA FROM #v1 GROUP BY #v1.TABLE_SCHEMA) ca1
where
	#v1.TABLE_NAME is null
union all
select
	'Routine' OBJECT_TYPE,
	#r2.ROUTINE_CATALOG OBJECT_CATALOG,
	#r2.ROUTINE_SCHEMA OBJECT_SCHEMA,
	#r2.ROUTINE_NAME [OBJECT_NAME],
	ca1.NOT_IN_SCHEMA
from
	#r2
left outer join
	#r1
on
	#r2.ROUTINE_NAME = #r1.ROUTINE_NAME
CROSS APPLY
	(select #r1.ROUTINE_SCHEMA NOT_IN_SCHEMA FROM #r1 GROUP BY #r1.ROUTINE_SCHEMA) ca1
where
	#r1.ROUTINE_NAME is null
order by
	OBJECT_TYPE,
	[OBJECT_NAME];
