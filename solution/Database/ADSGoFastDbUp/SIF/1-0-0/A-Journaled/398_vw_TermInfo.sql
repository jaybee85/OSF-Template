DROP VIEW IF EXISTS [dbo].[vw_TermInfo];
GO

CREATE VIEW [dbo].[vw_TermInfo]
AS
SELECT 
    [RefId] AS [TermInfoKey]
    ,[SchoolInfoRefId] AS [SchoolInfoKey]
    ,[SchoolYear] AS [SchoolYear]
    ,[StartDate] AS [StartDate]
    ,[EndDate] AS [EndDate]
    ,[Description] AS [Description]
    ,[RelativeDuration]
    ,[TermCode]
    ,[Track]
    ,[TermSpan]
    ,[MarkingTerm] 
    ,[SchedulingTerm]
    ,[AttendanceTerm]
FROM
    OPENROWSET(
    BULK 'samples/sif/TermInfo/TermInfo/Snapshot/TermInfo/*.snappy.parquet',
    --BULK 'samples/sif/TeachingGroup/TeachingGroup/Snapshot/TeachingGroup/**'
     DATA_SOURCE ='sif_eds',
    FORMAT='PARQUET'
    ----) AS [result]

) WITH (
[RefId] VARCHAR(36) ,
[SchoolInfoRefId] VARCHAR(36) ,
[SchoolYear] VARCHAR(4),
[StartDate] VARCHAR(10) ,
[EndDate] VARCHAR(10) ,
[Description] VARCHAR (255) ,
[RelativeDuration] VARCHAR(18) ,
[TermCode] VARCHAR (50) ,
[Track] VARCHAR(100) ,
[TermSpan] VARCHAR(20) ,
[MarkingTerm] VARCHAR(2) ,
[SchedulingTerm] VARCHAR(2) ,
[AttendanceTerm] VARCHAR(2) 
) AS [result];

GO