USE [master]
GO
CREATE LOGIN [dms_login] WITH PASSWORD=N'Desire2Learn' MUST_CHANGE, DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO
USE [lrn-km-db1]
GO
CREATE USER [dms_login] FOR LOGIN [dms_login]
GO

--securables

use [master]
GO
GRANT VIEW ANY DATABASE TO [dms_login]
GO
use [master]
GO
GRANT VIEW SERVER STATE TO [dms_login]
GO
