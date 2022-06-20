USE [sif2];
GO

DROP VIEW IF EXISTS dbo.vw_TeachingGroup_Period;
GO

CREATE VIEW dbo.vw_TeachingGroup_Period
AS
SELECT DISTINCT
    TG.RefId,
    PeriodList.DayId,
    PeriodList.PeriodId
FROM OPENROWSET(
BULK 'samples/sif/TeachingGroup/TeachingGroup/Snapshot/TeachingGroup/**',
DATA_SOURCE ='sif_eds',
FORMAT='PARQUET'
) 
WITH(
    RefId VARCHAR(50),
    TeachingGroupPeriodList VARCHAR(MAX)   
) AS TG
CROSS APPLY OPENJSON(TG.TeachingGroupPeriodList,'$.TeachingGroupPeriod')
        WITH (
        DayId VARCHAR(3),
        PeriodId INT,
        id int '$.sql:identity()'
    ) as PeriodList
;

-- SELECT * FROM vw_TeachingGroup_Period;