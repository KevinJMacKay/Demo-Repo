--truncate table Table_1
declare @text1 char(15)
declare @int1 int
declare @Date1 Date
set @text1 = 'Test text'
set @int1 = 1
set @Date1 = GETDATE()

while (@int1 <= 1000)
	Begin
		INSERT INTO Table_1
		SELECT @text1 + CONVERT(CHAR, @int1),@int1, @Date1
		Set @int1 = @int1+1		
	end


select count(*) from Table_1


DECLARE @Counter INT 
SET @Counter=1
WHILE ( @Counter <= 10)
BEGIN
    PRINT 'The counter value is = ' + CONVERT(VARCHAR,@Counter)
    SET @Counter  = @Counter  + 1
END