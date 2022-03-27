function(seed=0)
local tests =
[
    {
        "Active": true,        
        "Pattern": "SQL Database to Azure Storage CDC",         
        "SourceFormat":"Table",
        "SourceType":"SQL Server",
        "ExtractionSQL":"",
        "DataFilename":"SalesLT.Customer.parquet",
        "SchemaFileName":"SalesLT.Customer.json",
        "SourceSystemAuthType": "MSI",
        "TargetFormat":"Parquet",
        "TargetType": "Azure Blob", 
        "ADFPipeline": "GPL_SqlServerTable_NA_AzureBlobStorage_Parquet_CDC", 
        "Description": "WatermarkCDC",
        "ChunkField":"",
        "ChunkSize":0,
        "IncrementalType": "Watermark",
        "TaskDatafactoryIR":"OnPrem"
    },
    {
        "Active": true,
        "Pattern": "SQL Database to Azure Storage CDC",               
        "SourceFormat":"Table",
        "SourceType":"SQL Server",
        "ExtractionSQL":"",
        "DataFilename":"SalesLT.Customer.parquet",
        "SchemaFileName":"SalesLT.Customer.json",
        "SourceSystemAuthType": "MSI",
        "TargetFormat":"Parquet",
        "TargetType": "ADLS",
        "ADFPipeline": "GPL_SqlServerTable_NA_AzureBlobFS_Parquet_CDC",
        "Description": "WatermarkCDC",
        "ChunkField":"",
        "ChunkSize":0,
        "IncrementalType": "Watermark",
        "TaskDatafactoryIR":"OnPrem"
    }    
];

local template = import "./partials/functionapptest.libsonnet";

local process = function(index, t)
template(
    t.ADFPipeline,
    t.Pattern, 
    seed+index,//t.TestNumber,
    t.SourceFormat,
    t.SourceType,
    t.ExtractionSQL,
    t.DataFilename,
    t.SchemaFileName,
    t.SourceSystemAuthType,
    t.TargetFormat,
    t.TargetType,
    t.ChunkField,
    t.ChunkSize,
    t.IncrementalType,
    t.Description,
    t.TaskDatafactoryIR
);


std.mapWithIndex(process, tests)

