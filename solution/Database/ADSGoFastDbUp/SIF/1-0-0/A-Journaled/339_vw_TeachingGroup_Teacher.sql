

DROP VIEW IF EXISTS dbo.vw_TeachingGroup_Teacher;
GO

CREATE VIEW dbo.vw_TeachingGroup_Teacher
AS
SELECT DISTINCT
    TG.RefId,
    TeacherList.Association,
    TeacherList.StaffPersonalRefId
FROM OPENROWSET(
BULK 'samples/sif/TeachingGroup/TeachingGroup/Snapshot/TeachingGroup/**',
DATA_SOURCE ='sif_eds',
FORMAT='PARQUET'
) 
WITH(
    RefId VARCHAR(50),
    TeacherList VARCHAR(MAX)   
) AS TG
CROSS APPLY OPENJSON(TG.TeacherList,'$.TeachingGroupTeacher')
        WITH (
        Association VARCHAR(100),
        StaffPersonalRefId VARCHAR(50),
        StaffLocalId  VARCHAR(50),
        [Name] NVARCHAR(MAX) '$.Name' AS JSON,
        id int '$.sql:identity()'
    ) as TeacherList
;

-- SELECT * FROM vw_TeachingGroup_Teacher




