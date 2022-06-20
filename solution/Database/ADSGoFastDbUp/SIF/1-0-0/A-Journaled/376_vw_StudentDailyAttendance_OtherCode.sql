CREATE VIEW dbo.vw_StudentDailyAttendance_OtherCode
AS
SELECT 
    RefId,
    OtherCodeList.Codeset,
    OtherCodeList.value
FROM OPENROWSET(
BULK 'samples/sif/StudentDailyAttendance/StudentDailyAttendance/Snapshot/StudentDailyAttendance/**',
DATA_SOURCE ='sif_eds',
FORMAT='PARQUET'
) 
WITH(
    RefId VARCHAR(50),
    AttendanceCode VARCHAR(MAX)
) AS SDA
CROSS APPLY OPENJSON(SDA.AttendanceCode,'$.OtherCodeList.OtherCode')
        WITH (
        Codeset VARCHAR(50),
        value VARCHAR(10),
        id int '$.sql:identity()'
    ) as OtherCodeList

-- SELECT * FROM dbo.vw_StudentDailyAttendance_OtherCode