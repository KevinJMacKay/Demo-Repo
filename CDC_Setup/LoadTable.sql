/*
USE [lrn-km-db1]
GO

CREATE TABLE [dbo].[Table_1](
	[text1] [nchar](25) NULL,
	[int1] [int] NULL,
	[date1] [date] NULL
) ON [PRIMARY]
GO

TRUNCATE TABLE Table_1

*/

declare @text1 char(15)
declare @int1 int
declare @Date1 Date
set @text1 = 'Test text'
set @int1 = 1
set @Date1 = GETDATE()

while (@int1 <= 10000)
	Begin
		INSERT INTO Table_1
		SELECT @text1 + CONVERT(CHAR, @int1),@int1, @Date1
		Set @int1 = @int1+1		
	end


--select count(*) from Table_1


--DECLARE @Counter INT 
--SET @Counter=1
--WHILE ( @Counter <= 10)
--BEGIN
--    PRINT 'The counter value is = ' + CONVERT(VARCHAR,@Counter)
--    SET @Counter  = @Counter  + 1
--END

select * from Table_1
where  text1 like '%1%'

