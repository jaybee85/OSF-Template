function(GenerateArm="false",GFPIR="IRA", SourceType="SqlServerTable", TargetType="AzureBlobFS",TargetFormat="Parquet", SQL_Statement = "") 
local AzureBlobFS_Parquet_CopyActivity_Output = import './CDC_CopyActivity_AzureBlobFS_Parquet_Outputs.libsonnet';
local AzureBlobStorage_Parquet_CopyActivity_Output = import './CDC_CopyActivity_AzureBlobStorage_Parquet_Outputs.libsonnet';
local AzureSqlTable_NA_CopyActivity_Dataset = import './CDC_CopyActivity_AzureSqlTable_NA_Dataset.libsonnet';
local SqlServerTable_NA_CopyActivity_Dataset = import './CDC_CopyActivity_SqlServerTable_NA_Dataset.libsonnet';


if(SourceType=="AzureSqlTable") then
{
    "source": {
      "type": "AzureSqlSource",
      "sqlReaderQuery": {
        "value": SQL_Statement,
        "type": "Expression"
      },
      "queryTimeout": "02:00:00",
      "partitionOption": "None"
    },
    "dataset": AzureSqlTable_NA_CopyActivity_Dataset(GenerateArm,GFPIR)
} 

else if (SourceType=="SqlServerTable") then
{
    "source": {
      "type": "SqlServerSource",
      "sqlReaderQuery": {
        "value": SQL_Statement,
        "type": "Expression"
      },
      "queryTimeout": "02:00:00",
      "partitionOption": "None"
    },
    "dataset": SqlServerTable_NA_CopyActivity_Dataset(GenerateArm,GFPIR)
} 
else 
  error 'CopyActivity_TypeProperties.libsonnet Failed: ' + GFPIR+","+SourceType+","+TargetType+","+TargetFormat