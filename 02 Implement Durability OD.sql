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

/******************************************/
/* Implement Delayed Durability - On disk */
/******************************************/
-- In this section we will demonstrate the use of
-- delayed durability with on-disk structures


-- On server1 in Perfmon ensure the
-- following database counters added:
-- Counter set MSSQL$<instance>:Databases/ Borg (instance of object)
-- 	* Log Flushes/sec
--	* Transactions/sec


-- Ensure database durability is set to default
USE master
GO
ALTER DATABASE [Borg] SET DELAYED_DURABILITY = 	
	DISABLED --|ALLOWED|FORCED


-- In SQLQueryStress
-- Now run code 3000 iterations, 10 threads = 30,000 transactions
-- Delayed Durability Transaction
BEGIN TRAN
		INSERT INTO Assimilations (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 10);
		INSERT INTO Assimilations (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 15);
		INSERT INTO Assimilations (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 5);
		INSERT INTO Assimilations (assimilation_date, NewBorg) 
			VALUES (GETDATE(), 7);
COMMIT --WITH (DELAYED_DURABILITY = OFF)


-- Switch to server1 and notice that log flushes quite high


-- Force Delayed Durability on Database
USE master
GO
ALTER DATABASE [Borg] SET DELAYED_DURABILITY = FORCED
	--DISABLED|ALLOWED 


-- Delayed Durability Transaction
-- In SQLQueryStress
-- Now run same code 3000 iterations, 10 threads = 30,000 transactions
-- Delayed Durability Transaction
BEGIN TRAN
		INSERT INTO Assimilations (assimilation_date, NewBorg) VALUES (GETDATE(), 10);
		INSERT INTO Assimilations (assimilation_date, NewBorg) VALUES (GETDATE(), 15);
		INSERT INTO Assimilations (assimilation_date, NewBorg) VALUES (GETDATE(), 5);
		INSERT INTO Assimilations (assimilation_date, NewBorg) VALUES (GETDATE(), 7);
COMMIT --WITH (DELAYED_DURABILITY = ON)

-- Switch to server1 and notice that log flushes lower
-- and transactions/sec should be higher