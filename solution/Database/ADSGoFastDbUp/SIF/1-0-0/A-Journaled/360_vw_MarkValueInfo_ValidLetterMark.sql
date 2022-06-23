
DROP VIEW IF EXISTS dbo.vw_MarkValueInfo_ValidLetterMark;
GO

CREATE VIEW [dbo].[vw_MarkValueInfo_ValidLetterMark]
AS
SELECT 
	MVI.[RefId] AS [MarkInfoKey],
	LML.Code,
    LML.NumericEquivalent
FROM
OPENROWSET(
BULK 'samples/sif/MarkValueInfo/MarkValueInfo/Snapshot/MarkValueInfo/*',
DATA_SOURCE ='sif_eds',
FORMAT='PARQUET'
) 
WITH (
    [RefId] VARCHAR(50),	
    [ValidLetterMarkList] VARCHAR(MAX) 
)
AS MVI
CROSS APPLY OPENJSON(MVI.ValidLetterMarkList,'$.ValidLetterMark')
        WITH (
        Code VARCHAR(3),
        NumericEquivalent INT,
        id int '$.sql:identity()'
    ) as LML
;


-- SELECT * FROM dbo.vw_MarkValueInfo_ValidLetterMark