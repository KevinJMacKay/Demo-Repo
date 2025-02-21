USE [master]
GO
CREATE LOGIN [dms_login] WITH PASSWORD=N'Desire2Learn', DEFAULT_DATABASE=[master]
GO
USE [lrn-km-db1]
GO
CREATE USER [dms_login] FOR LOGIN [dms_login]
GO

/*
USE [lrn-km-db1]
GO
DROP USER [dms_login]
GO
USE [master]
GO
DROP LOGIN [dms_login]
GO

*/

--securables

use [master]
GO
GRANT VIEW ANY DATABASE TO [dms_login]
GO
use [master]
GO
GRANT VIEW SERVER STATE TO [dms_login]
GO
------------
USE [master]
CREATE LOGIN [dms_login] WITH PASSWORD=N'Desire2Learn', DEFAULT_DATABASE=[master]

USE [lrn-km-db1]
CREATE USER [dms_login] FOR LOGIN [dms_login]
GRANT VIEW DEFINITION TO [dms_login]
GRANT VIEW DATABASE STATE TO [dms_login]
ALTER ROLE [db_datareader] ADD MEMBER [dms_login]
GO

USE master
GRANT VIEW SERVER STATE TO [dms_login]
GRANT VIEW ANY DEFINITION TO [dms_login]
GO

