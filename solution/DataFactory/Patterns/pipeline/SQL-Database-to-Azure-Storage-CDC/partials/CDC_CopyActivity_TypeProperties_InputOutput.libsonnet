function(GenerateArm="false",GFPIR="IRA", SourceType="SqlServerTable", TargetType="AzureBlobFS",TargetFormat="Parquet", SQLStatement = "") 
local AzureBlobFS_Parquet_CopyActivity_Output = import './CDC_CopyActivity_AzureBlobFS_Parquet_Outputs.libsonnet';
local AzureBlobStorage_Parquet_CopyActivity_Output = import './CDC_CopyActivity_AzureBlobStorage_Parquet_Outputs.libsonnet';
local AzureSqlTable_NA_CopyActivity_Inputs = import './CDC_CopyActivity_AzureSqlTable_NA_Inputs.libsonnet';
local SqlServerTable_NA_CopyActivity_Inputs = import './CDC_CopyActivity_SqlServerTable_NA_Inputs.libsonnet';


if(SourceType=="AzureSqlTable"&&TargetType=="AzureBlobFS"&&TargetFormat=="Parquet") then
{
    "source": {
      "type": "AzureSqlSource",
      "sqlReaderQuery": {
        "value": SQLStatement,
        "type": "Expression"
      },
      "queryTimeout": "02:00:00",
      "partitionOption": "None"
    },
    "sink": {
      "type": "ParquetSink",
      "storeSettings": {
        "type": "AzureBlobFSWriteSettings"
      }
    },
    "enableStaging": false,
    "translator": {
        "type": "TabularTranslator",
        "typeConversion": true,
        "typeConversionSettings": {
            "allowDataTruncation": true,
            "treatBooleanAsNumber": false
        }
    }
} 
else if(SourceType=="AzureSqlTable"&&TargetType=="AzureBlobStorage"&&TargetFormat=="Parquet") then
{
    "source": {
      "type": "AzureSqlSource",
      "sqlReaderQuery": {
        "value": SQLStatement,
        "type": "Expression"
      },
      "queryTimeout": "02:00:00",
      "partitionOption": "None"
    },
    "sink": {
      "type": "ParquetSink",
      "storeSettings": {
        "type": "AzureBlobFSWriteSettings"
      }
    },
    "enableStaging": false,
    "translator": {
        "type": "TabularTranslator",
        "typeConversion": true,
        "typeConversionSettings": {
            "allowDataTruncation": true,
            "treatBooleanAsNumber": false
        }
    }
}
else if (SourceType=="SqlServerTable" && TargetType=="AzureBlobFS"&&TargetFormat=="Parquet") then
{
    "source": {
      "type": "SqlServerSource",
      "sqlReaderQuery": {
        "value": SQLStatement,
        "type": "Expression"
      },
      "queryTimeout": "02:00:00"
    },
    "sink": {
      "type": "ParquetSink",
      "storeSettings": {
        "type": "AzureBlobFSWriteSettings"
      }
    },
    "enableStaging": false,
    "translator": {
        "type": "TabularTranslator",
        "typeConversion": true,
        "typeConversionSettings": {
            "allowDataTruncation": true,
            "treatBooleanAsNumber": false
        }
    }
}
else if (SourceType=="SqlServerTable" && TargetType=="AzureBlobStorage"&&TargetFormat=="Parquet") then
{
    "source": {
      "type": "SqlServerSource",
      "sqlReaderQuery": {
        "value": SQLStatement,
        "type": "Expression"
      },
      "queryTimeout": "02:00:00"
    },
    "sink": {
      "type": "ParquetSink",
      "storeSettings": {
        "type": "AzureBlobFSWriteSettings"
      }
    },
    "enableStaging": false,
    "translator": {
        "type": "TabularTranslator",
        "typeConversion": true,
        "typeConversionSettings": {
            "allowDataTruncation": true,
            "treatBooleanAsNumber": false
        }
    }
} 
else 
  error 'CopyActivity_TypeProperties.libsonnet Failed: ' + GFPIR+","+SourceType+","+TargetType+","+TargetFormat