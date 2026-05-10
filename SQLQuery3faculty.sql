--part1
--create a database
create database Faculty;
go

use Faculty;
go

--create department ,professor, course table
create table Department(
    Department_id int primary key identity(001, 1),  -- Start at 001, increment by 1
	Department_name varchar (100) not null unique,
	Budget decimal (12, 2),
	Establishment_year int
);

create table Professor(
    Professor_id int primary key identity(1001,5), --starts at 1001, incremennt by 5
	Fullname varchar (100) not null,
	Email varchar (100) unique,
	Hire_date date default getdate(),
	Department_id int not null,
	foreign key (Department_id) references Department(Department_id)
);

create table Course(
    Course_code varchar(10) primary key,
	Course_name varchar(100) not null,
	Credits int, check (Credits IN (1,2,3,4,5)),
	Professor_id int not null,
	foreign key (Professor_id) references Professor(Professor_id),
);
go

--part2
--alter professor table to add Professor_phoneNumber
if not exists (select 1 from sys.objects where name = 'Professor_phoneNumber')
begin
   alter table dbo.professor
   add Professor_phoneNumber varchar(15);
   print 'Professor_phoneNumber created';
end
else
   print 'Professor_phoneNumber already exists.';

--inserting records to each table (course, department, Professor tables)

set identity_insert Department on;

insert into Department(Department_id, Department_name, Budget, Establishment_year)
values
(001, 'Agriculture', 500000, 2005),
(002, 'Computer Science', 120000, 2012),
(003, 'Business Administration', 900000, 2008),
(004, 'Mechanical Engineering', 150000, 2010),
(005, 'Mass Communication', 700000, 2015)

set identity_insert Department off;

Set identity_insert Professor on;

insert into Professor (Professor_id, Fullname, Email, Hire_date, Department_id)
values
(1, 'Dr. Ahmed Musa', 'ahmed.musa@uni.edu', '2005-06-12', 001),
(2, 'Dr. Grace Okafor', 'grace.okafor@uni.edu', '2012-09-23', 002),
(3, 'Dr. John Adeyemi', 'john.adeyemi@uni.edu', '2008-03-15', 003),
(4, 'Dr. Fatima Bello', 'fatima.bello@uni.edu', '2010-11-30', 004),
(5, 'Dr. Samuel Eze', 'samuel.eze@uni.edu', '2015-07-19', 005);

set identity_insert Professor off;

INSERT INTO Course (Course_code, Course_name, Credits, Professor_id)
VALUES 
('CSC101', 'Introduction to Computer Science', 3, 1),
('CSC102', 'Data Structures', 4, 2),
('CSC103', 'Database Systems', 3, 3),
('CSC104', 'Operating Systems', 4, 4),
('CSC105', 'Software Engineering', 3, 5);



--using join query join all three tables
select c.Course_name, p.Fullname, d.Department_name
from Course c
join professor p on c.Professor_id = p.Professor_id
join Department d on p.Department_id = d.department_id;
go

--update the budget on department table by 10%
update Department
set Budget = Budget * 1.10

--delete operating systems course on the course table
delete from Course
where Course_name = 'operating systems';

--create users
create user FacultyAdmin without login;
create user FacultyReader without login;
create user FacultyWriter without login;
go

--granting each user
grant select, insert, update, delete,alter on Department to FacultyAdmin;
grant backup database to FacultyAdmin;
grant create table to FacultyAdmin;

grant select on Professor to FacultyReader;
revoke insert, update, delete, alter on  Professor from FacultyReader;

grant select, insert, update, delete on Course to FacultyWriter;
deny alter on schema ::dbo to FacultyWriter;
revoke create table to FacultyWriter;
revoke alter on Course from FacultyWriter;


--   PART 7



  -- 1. ATOMICITY
--   Transfer budget between departments


BEGIN TRANSACTION

UPDATE Department
SET Budget = Budget - 5000
WHERE Department_id = 1;

UPDATE Department
SET Budget = Budget + 5000
WHERE Department_id = 2;

COMMIT;

-- If error occurs:
-- ROLLBACK;


/* =========================================
   SAVEPOINT + PARTIAL ROLLBACK
========================================= */

BEGIN TRANSACTION

UPDATE Department
SET Budget = Budget - 2000
WHERE Department_id = 1;

SAVE TRANSACTION SavePoint1;

UPDATE Department
SET Budget = Budget + 2000
WHERE Department_id = 2;

-- Undo second update only
ROLLBACK TRANSACTION SavePoint1;

COMMIT;


/* =========================================
   2. CONSISTENCY
   CHECK constraint violation
========================================= */

ALTER TABLE Department
ADD CONSTRAINT chk_budget
CHECK (Budget > 0);

BEGIN TRANSACTION

UPDATE Department
SET Budget = -1000
WHERE Department_id = 1;

-- This violates CHECK constraint

ROLLBACK;


--   3. ISOLATION
  -- READ COMMITTED

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION

SELECT *
FROM Department;

COMMIT;

-- Open another query window/session
-- and run another transaction simultaneously
-- to demonstrate isolation

BEGIN TRANSACTION

UPDATE Department
SET Budget = Budget + 1000
WHERE Department_id = 1;

COMMIT;

DBCC CHECKDB ('Faculty');