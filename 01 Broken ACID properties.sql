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

/**********************************/
/* Nested transactions are a myth */
/**********************************/
-- In this section we will demonstrate that nested transactions
-- are nothing more than a transaction counter increment
USE Borg
GO
CHECKPOINT --clear log for db in SIMPLE recovery
SELECT * FROM [dbo].[vw_logrecords] 
	WHERE (AllocUnitName IS NULL OR AllocUnitName = 'dbo.Species.idxName')
	AND [Transaction ID] <> '0000:00000000'
	ORDER BY [Current LSN] DESC
-- run again until no results


BEGIN TRAN
SELECT @@TRANCOUNT 'Open Transactions'


-- Check for LOP_BEGIN_XACT log record
SELECT * FROM [dbo].[vw_logrecords] 
	WHERE (AllocUnitName IS NULL OR AllocUnitName = 'dbo.Species.idxName')
	AND [Transaction ID] <> '0000:00000000'
	ORDER BY [Current LSN] DESC


-- Note that the begin tran log record is deferred and not yet created


-- Insert first record in table
INSERT INTO Species ([Name], [Description]) VALUES
('Vulcan','Vulcans are a warp-capable humanoid species from the planet Vulcan, widely known for their logical minds and stoic culture.')


-- Check for LOP_BEGIN_XACT log record
SELECT * FROM [dbo].[vw_logrecords] 
	WHERE (AllocUnitName IS NULL 
		OR AllocUnitName = 'dbo.Species.idxName')
		AND [Transaction ID] IN 
			(SELECT [Transaction ID] 
				FROM [dbo].[vw_logrecords] 
				WHERE AllocUnitName = 'dbo.Species.idxName'
			)
		ORDER BY [Current LSN] DESC


-- Notice that begin log record has now been created


-- Begin nested transaction
BEGIN TRAN
SELECT @@TRANCOUNT 'Open Transactions'


-- Insert next record in table
INSERT INTO Species ([Name], [Description]) VALUES
('Vorta','Vorta are a member race of the Dominion.')


-- Check for the second LOP_BEGIN_XACT log record
SELECT * FROM [dbo].[vw_logrecords] 
	WHERE (AllocUnitName IS NULL 
		OR AllocUnitName = 'dbo.Species.idxName')
		AND [Transaction ID] IN 
			(SELECT [Transaction ID] 
				FROM [dbo].[vw_logrecords] 
				WHERE AllocUnitName = 'dbo.Species.idxName'
			)
		ORDER BY [Current LSN] DESC

-- Notice there is no begin log record this time!


-- Lets commit our inner transaction
COMMIT
SELECT @@TRANCOUNT 'Open Transactions'


-- Notice open "Transaction" count decremented to 1


-- Check for LOP_COMMIT_XACT log record
SELECT * FROM [dbo].[vw_logrecords] 
	WHERE (AllocUnitName IS NULL 
		OR AllocUnitName = 'dbo.Species.idxName')
		AND [Transaction ID] IN 
			(SELECT [Transaction ID] 
				FROM [dbo].[vw_logrecords] 
				WHERE AllocUnitName = 'dbo.Species.idxName'
			)
		ORDER BY [Current LSN] DESC

-- Notice that while trancount had decreased, 
-- No transaction *really* committed


-- Lets commit our outer transaction
COMMIT
SELECT @@TRANCOUNT 'Open Transactions'


-- Check for LOP_COMMIT_XACT log record-- Check for the second LOP_BEGIN_XACT log record
SELECT * FROM [dbo].[vw_logrecords] 
	WHERE (AllocUnitName IS NULL 
		OR AllocUnitName = 'dbo.Species.idxName')
		AND [Transaction ID] IN 
			(SELECT [Transaction ID] 
				FROM [dbo].[vw_logrecords] 
				WHERE AllocUnitName = 'dbo.Species.idxName'
			)
		ORDER BY [Current LSN] DESC

-- Notice that transaction count was zero and 
-- we now HAVE our outer commit log record!


/*******************************************/
/* SQL Server compromises ACID - Atomicity */
/*******************************************/
-- In this section we will demonstrate how SQL Server
-- already compromises some of the ACID properties


-- Create simple table with a primary key constraint
USE Borg
GO
CREATE TABLE Weapons 
	(id INT PRIMARY KEY CLUSTERED, -- notice the constraint! 
	name VARCHAR(20), 
	quantity INT)
GO


-- Run a transaction that attempts to break 
-- the primary key constraint
BEGIN TRAN
	INSERT INTO Weapons VALUES (1, 'Photon Rifle', 1000);
	INSERT INTO Weapons VALUES (2, 'Shoulder Blaster', 4301);
	INSERT INTO Weapons VALUES (3, 'Laser Pistol', 404);
	INSERT INTO Weapons VALUES (4, 'Klingon Sword', 100);
	INSERT INTO Weapons VALUES (1, 'BFG', 19); -- notice the 1 key again! 
COMMIT TRAN


-- Check that transactions are either
-- committed or rolled back
SELECT @@TRANCOUNT 'Transaction Count'


-- Let's query that "empty" table
SELECT * FROM Weapons


/*******************************************/
/* SQL Server compromises ACID - Isolation */
/*******************************************/
-- In this section we will demonstrate how SQL Server
-- already compromises some of the ACID properties


-- In SQLQueryStress
-- Run 1000 iterations, 1 threads = 1000 decrements
-- Remember we currently have 1000 Photon Rifle
DECLARE @id INT = 1
DECLARE @newquantity INT
BEGIN TRANSACTION
	-- assign and decrement sales quantity 
	-- value of weapon type 1
	SELECT @newquantity = quantity - 1 
		FROM Weapons WHERE id = @id
	-- update value of new quantity
	UPDATE Weapons SET quantity = @newquantity 
		WHERE id = @id
COMMIT


-- What is the final quantity?
SELECT * from Weapons


-- Reset weapon 1 quantity
UPDATE Weapons SET quantity = 1000 WHERE id = 1
SELECT * from Weapons


-- In SQLQueryStress
-- Now re-run same code 100 iterations, 10 threads = 1000 decrements
-- Remember we currently have 1000 Photon Rifle
DECLARE @id INT = 1
DECLARE @newquantity INT
BEGIN TRANSACTION
	--assign and decrement sales quantity value of weapon type 1
	SELECT @newquantity = quantity - 1 FROM Weapons WHERE id = @id
	--update value of new quantity
	UPDATE Weapons SET quantity = @newquantity WHERE id = @id
COMMIT


-- What is the final quantity?
SELECT * from Weapons


-- But there are some "fixes"


-- Reset weapon 1 quantity
UPDATE Weapons SET quantity = 1000 WHERE id = 1
SELECT * from Weapons


-- In SQLQueryStress
-- Now run following code 100 iterations, 10 threads = 1000 decrements
-- Remember we currently have 1000 Photon Rifle
DECLARE @id INT = 1
DECLARE @newquantity INT
BEGIN TRANSACTION
		--decrement and update sales quantity value of weapon type 1
		UPDATE Weapons SET quantity = quantity - 1 WHERE id = @id
COMMIT


-- What is the final quantity?
SELECT * from Weapons


-- Fixed!