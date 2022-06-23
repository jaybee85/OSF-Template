
DROP VIEW IF EXISTS [dbo].[vw_GradingAssignment];
GO

CREATE VIEW [dbo].[vw_GradingAssignment]
AS
SELECT 
    [RefId] AS [GradingAssignmentKey]
    ,[TeachingGroupRefId] AS [TeachingGroupKey]
    ,[StudentPersonalRefIdList] AS [StudentKey]
    ,[SchoolInfoRefId] AS [SchoolInfoKey]
    ,[GradingCategory] AS [GradingCategory]
    ,[Description] AS [Description]
    ,[PointsPossible]
    ,[CreateDate]
    ,[DueDate]
    ,[Weight]
    ,[DetailedDescriptionURL]
FROM
    OPENROWSET(
    BULK 'samples/sif/GradingAssignment/GradingAssignment/Snapshot/GradingAssignment/**',
    DATA_SOURCE ='sif_eds',
    FORMAT='PARQUET'
) 
WITH (
    [RefId] VARCHAR(36) ,
    [TeachingGroupRefId] VARCHAR(36) ,
    [StudentPersonalRefIdList] VARCHAR(36),
    [SchoolInfoRefId] VARCHAR(36) ,
    [GradingCategory] VARCHAR(255) ,
    [Description] VARCHAR (1000) ,
    [PointsPossible] VARCHAR(8000) ,
    [CreateDate] VARCHAR (8000) ,
    [DueDate] VARCHAR(8000) ,
    [Weight] VARCHAR(18) ,
    [DetailedDescriptionURL] VARCHAR(1000) 
) AS [result];

GO