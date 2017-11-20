/************************************************************
*   All scripts contained within are Copyright © 2015 of    *
*   SQLCloud Limited, whether they are derived or actual    *
*   works of SQLCloud Limited or its representatives        *
*************************************************************
*   All rights reserved. No part of this work may be        *
*   reproduced or transmitted in any form or by any means,  *
*   electronic or mechanical, including photocopying,       *
*   recording, or by any information storage or retrieval   *
*   system, without the prior written permission of the     *
*   copyright owner and the publisher.                      *
************************************************************/

/********************************************/
/* Implement Delayed Durability - In-Memory */
/********************************************/
-- In this section we will demonstrate the use of
-- delayed durability with in-memory structures


-- Enable Database for IMOLTP
USE [master]
GO
ALTER DATABASE Borg ADD FILEGROUP IMOLTP
CONTAINS MEMORY_OPTIMIZED_DATA
USE [master]
GO


-- Add container1 to filegroups.
ALTER DATABASE [Borg] 
	ADD FILE ( NAME = N'borg_imoltp_1', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\Borg_IMOLTP_1' )
	TO FILEGROUP [IMOLTP]
GO

-- Create In-Memory table
USE [Borg]
GO
CREATE TABLE AssimilationsIM 
	(id INT IDENTITY PRIMARY KEY NONCLUSTERED HASH
		WITH (BUCKET_COUNT=8000) NOT NULL, --bucket size compromises performance
		-- Bucket count (power of two), so 2^13 = 8192
	Assimilation_Date datetime DEFAULT getdate(), 
	NewBorg INT INDEX idxNewBorg NONCLUSTERED, 
	Details CHAR (50))
	WITH (MEMORY_OPTIMIZED=ON, --defines in-memory table
	DURABILITY = SCHEMA_AND_DATA) --default (also SCHEMA_ONLY)
/* Presenters note: In-Memory table durability is not related to delayed durability! */
GO



-- Ensure durability is set to default
USE master
GO
ALTER DATABASE [Borg] SET DELAYED_DURABILITY = 	
	DISABLED
	--ALLOWED 
	--FORCED


-- In SQLQueryStress
-- Now run code 3000 iterations, 10 threads = 30,000 transactions
-- Delayed Durability Transaction
BEGIN TRAN
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 10);
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 15);
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 5);
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 7);
COMMIT --WITH (DELAYED_DURABILITY = OFF)


-- Ensure durability is set to forced
USE master
GO
ALTER DATABASE [Borg] SET DELAYED_DURABILITY = 	
	--DISABLED
	--ALLOWED 
	FORCED


-- In SQLQueryStress
-- Now run code 3000 iterations, 10 threads = 30,000 transactions
-- Delayed Durability Transaction
BEGIN TRAN
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 10);
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 15);
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 5);
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 7);
COMMIT --WITH (DELAYED_DURABILITY = OFF)


-- Create Native Compilation Stored Procedure
USE [Borg]
GO

CREATE PROCEDURE dbo.InsertAssimilationsIM
	WITH NATIVE_COMPILATION, -- native proc
	SCHEMABINDING, -- prevent drop
	EXECUTE AS OWNER -- execution context required either OWNER/SELF/USER
AS
	BEGIN ATOMIC WITH -- Create tran if no open or create savepoint
		(TRANSACTION ISOLATION LEVEL = SNAPSHOT, -- SERIALIZABLE or REPEATABLE READ
		LANGUAGE = N'british', -- language required
		DELAYED_DURABILITY = ON -- not required
		)
	/* Presenters note: Delayed durability can be forced or allowed on database    */
	/* via ALTER DATABASE … SET DELAYED_DURABILITY = { DISABLED | ALLOWED | FORCED */
	/* using allowed means that native compilation procedure can use it through    */
	/* DELAYED_DURABILITY = ON                                                     */
		BEGIN
			INSERT INTO dbo.AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 10);
			INSERT INTO dbo.AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 15);
			INSERT INTO dbo.AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 5);
			INSERT INTO dbo.AssimilationsIM (assimilation_date, NewBorg) VALUES (GETDATE(), 7);
		END
	END
GO


-- In SQLQueryStress
-- Now run code 3000 iterations, 10 threads = 30,000 transactions
-- Delayed Durability Transaction
EXEC dbo.InsertAssimilationsIM