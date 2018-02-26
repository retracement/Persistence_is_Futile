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

/*******************/
/* On-Disk Logging */
/*******************/
-- See how many log records exist in the SQL Server transaction log
-- for the on-disk Assimilations table


-- Clear on-disk table to allow re-load to generate log records
USE Borg
GO
TRUNCATE TABLE [dbo].[Assimilations]


-- Run block until no results
CHECKPOINT --clear log for db in SIMPLE recovery
SELECT * FROM [dbo].[vw_logrecords] 
	WHERE (AllocUnitName IS NULL OR AllocUnitName = 'dbo.Species.idxName')
	AND [Transaction ID] <> '0000:00000000'
	ORDER BY [Current LSN] DESC


-- Insert 4 records into the ondisk table
BEGIN TRAN
		INSERT INTO Assimilations (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 10);
		INSERT INTO Assimilations (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 15);
		INSERT INTO Assimilations (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 5);
		INSERT INTO Assimilations (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 7);
COMMIT


-- Look at the log and return topmost on-disk transaction
-- Find [Transaction ID] for most recent LOP_INSERT_ROWS record
DECLARE @TransactionID NVARCHAR(14)
DECLARE @CurrentLSN NVARCHAR(23)
SELECT TOP 1 @TransactionID =
        [Transaction ID], @CurrentLSN = [Current LSN]
	FROM    sys.fn_dblog(NULL, NULL)
	WHERE   Operation = 'LOP_INSERT_ROWS' --the on-disk logical insert record
	ORDER BY [Current LSN] DESC;

SELECT  *
	FROM    sys.fn_dblog(NULL, NULL)
	WHERE   [Transaction ID] = @TransactionID
	ORDER BY [Current LSN] DESC;
GO


/*********************/
/* In-Memory Logging */
/*********************/
-- See how many log records exist in the SQL Server transaction log
-- for the in-memory AssimilationsIM table


-- Clear on-disk table to allow re-load to generate log records
DELETE FROM [dbo].[AssimilationsIM] -- TRUNCATE not supported with IM


-- Insert 4 records into the in-memory table
BEGIN TRAN
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 10);
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 15);
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 5);
		INSERT INTO AssimilationsIM (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 7);
COMMIT


-- Look at the log and return topmost In-Memory OLTP transaction
-- Find [Transaction ID] & [Current LSN] for most recent LOP_HK record
DECLARE @TransactionID NVARCHAR(14)
DECLARE @CurrentLSN NVARCHAR(23)
SELECT TOP 1 @TransactionID =
        [Transaction ID], @CurrentLSN = [Current LSN]
		--TOP 1 [Transaction ID], [Current LSN]
	FROM    sys.fn_dblog(NULL, NULL)
	WHERE   Operation = 'LOP_HK' --the hekaton logical op record
	ORDER BY [Current LSN] DESC;

SELECT 
	@TransactionID AS '[Transaction ID]',
	@CurrentLSN AS '[Current LSN]'

-- Show those log records for [Transaction ID] of the LOP_HK
SELECT  *
	FROM    sys.fn_dblog(NULL, NULL)
	WHERE   [Transaction ID] = @TransactionID;

-- Break open log record for Hekaton log record LSN
SELECT  
	[Current LSN],
	[Transaction ID],
	Operation,
	operation_desc,
	tx_end_timestamp,
	total_size--,
	--OBJECT_NAME(table_id) AS TableName
	FROM    sys.fn_dblog_xtp(NULL, NULL)
	WHERE   [Current LSN] = @CurrentLSN;
GO