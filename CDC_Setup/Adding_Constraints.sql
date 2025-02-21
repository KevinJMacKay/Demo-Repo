CREATE TABLE Orders (
    OrderID int NOT NULL,
    OrderNumber int NOT NULL,
    PersonID int,
    PRIMARY KEY (OrderID),
    CONSTRAINT FK_PersonOrder FOREIGN KEY (PersonID)
    REFERENCES Persons1(ID)
);

USE [lrn-km-db1]
GO

INSERT INTO [dbo].[Orders]
           ([OrderID]
           ,[OrderNumber]
           ,[PersonID])
     VALUES
           (2
           ,1001
           ,2)
GO

select * from [dbo].[Orders]
select * from [dbo].[Persons1]

Update [dbo].[Orders]
Set OrderNumber = 1111
Where OrderID = 1

Delete from [dbo].[Orders]
Where OrderID = 2