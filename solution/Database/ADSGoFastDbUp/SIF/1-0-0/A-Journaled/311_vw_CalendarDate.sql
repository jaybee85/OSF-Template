
DROP VIEW IF EXISTS dbo.vw_CalendarDate;
GO 

CREATE VIEW dbo.vw_CalendarDate
as
SELECT *

FROM OPENROWSET(
BULK 'samples/sif/CalendarDate/CalendarDate/Snapshot/CalendarDate/**',
DATA_SOURCE ='sif_eds',
FORMAT='PARQUET'
) WITH (

CalendarDateRefId	VARCHAR(50) 
, [Date]	            VARCHAR (50)                      
, CalendarSummaryRefId	VARCHAR (50)
, SchoolInfoRefId	    VARCHAR (50)
, SchoolYear	        VARCHAR(4)
, CalendarDateType	    VARCHAR(20)  '$.CalendarDateType.Code'
, CalendarDateNumber	INT 
, StudentAttendanceCountsTowardAttendance     VARCHAR(255)  '$.StudentAttendance.CountsTowardAttendance'
, StudentAttendanceValue	     FLOAT  '$.StudentAttendance.AttendanceValue'
, TeacherAttendanceCountsTowardAttendance      VARCHAR(255)  '$.TeacherAttendance.CountsTowardAttendance'
, TeacherAttendanceValue   FLOAT      '$.TeacherAttendance.AttendanceValue'
, AdministratorAttendanceCountsTowardAttendance VARCHAR(255) 	'$.AdministratorAttendance.CountsTowardAttendance'
, AdministratorAttendanceValue FLOAT   '$.AdministratorAttendance.AttendanceValue'

)
as r
go

