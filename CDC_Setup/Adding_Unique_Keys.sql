CREATE TABLE Persons1 (
    ID int NOT NULL UNIQUE,
    LastName varchar(255) NOT NULL,
    FirstName varchar(255),
    Age int
);

------------------

CREATE TABLE Persons2 (
    ID int NOT NULL,
    LastName varchar(255) NOT NULL,
    FirstName varchar(255),
    Age int,
    CONSTRAINT UC_Person UNIQUE (ID,LastName)
);

------------------

CREATE TABLE Persons3 (
    ID int NOT NULL,
    LastName varchar(255) NOT NULL,
    FirstName varchar(255),
    Age int
);

ALTER TABLE Persons3
ADD UNIQUE (ID);

------------------

CREATE TABLE Persons4 (
    ID int NOT NULL,
    LastName varchar(255) NOT NULL,
    FirstName varchar(255),
    Age int
);

ALTER TABLE Persons4
ADD CONSTRAINT UC_Person4 UNIQUE (ID,LastName);

------------------

ALTER TABLE Persons
DROP CONSTRAINT UC_Person;