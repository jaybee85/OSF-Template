local commons = import '../../../static/partials/functionapptest_commons.libsonnet';
local vars = import '../../../static/partials/secrets.libsonnet';
function(
    ADFPipeline = "GPL_AzureSqlTable_NA_AzureBlobStorage_Parquet_IRA",
    Pattern = "SQL Database to Azure Storage",
    TestNumber = "1",
    SourceFormat = "Azure SQL",
    SourceType = "Azure SQL",
    ExtractionSQL = "",
    DataFilename = "SalesLT.Customer.parquet",
    SchemaFileName = "SalesLT.Customer.json",
    SourceSystemAuthType = "MSI",
    TargetFormat = "Parquet",
    TargetType = "Azure Blob", 
    ChunkField = "",
    ChunkSize = 0,
    IncrementalType = "Full",
    IncrementalField = "",
    IncrementalColumnType = "",
    IncrementalValue = "0"
    )
{
    local TaskMasterJson =     
    {
        "Source":{
            "Type": SourceFormat,
            "IncrementalType": IncrementalType,
            "IncrementalColumnType":IncrementalColumnType,
            "IncrementalField":IncrementalField,
            "IncrementalValue":IncrementalValue,
            "TableSchema": "SalesLT",
            "TableName": "Customer",
            "ExtractionSQL": ExtractionSQL,                   
            "ChunkField":ChunkField,
            "ChunkSize":ChunkSize
        },
        "Target":{
            "Type":TargetFormat,
            "RelativePath":"/Tests/"+Pattern+"/"+TestNumber,
            "DataFileName": DataFilename,
            "SchemaFileName": SchemaFileName
        }
    },

    local TaskInstanceJson =  
    {
        "TargetRelativePath": "/Tests/"+Pattern+"/"+TestNumber+"/"
    },

    local SourceSystemJson = 
    {
        "Database": vars.sampledb_name,
        "UsernameKeyVaultSecretName":"",
        "PasswordKeyVaultSecretName":""        
    },

    local TargetSystemJson = 
    {
        "Container" : "datalakeraw" 
    },
             
    "TaskInstanceJson":std.manifestJson(TaskInstanceJson),
    "TaskType":Pattern,
    "TaskTypeId":3,
    "DataFactoryName":vars.datafactory_name,
    "DataFactoryResourceGroup":vars.resource_group_name,
    "DataFactorySubscriptionId":vars.subscription_id,
    "TaskMasterJson":std.manifestJson(TaskMasterJson),       
    "TaskMasterId":TestNumber,
    "SourceSystemId":if(SourceType == "Azure SQL") then 1 else 6,
    "SourceSystemJSON":std.manifestJson(SourceSystemJson),
    "SourceSystemType":SourceType,
    "SourceSystemServer":vars.sqlserver_name + ".database.windows.net",
    "SourceKeyVaultBaseUrl":"https://" + vars.keyvault_name +".vault.azure.net",
    "SourceSystemAuthType":SourceSystemAuthType,
    "SourceSystemSecretName":"",
    "SourceSystemUserName":"",   
    "TargetSystemId":if(SourceType == "Azure Blob") then 3 else 4,
    "TargetSystemJSON":std.manifestJson(TargetSystemJson),
    "TargetSystemType":TargetType,
    "TargetSystemServer":if(TargetType == "Azure Blob") then "https://" + vars.blobstorage_name + ".blob.core.windows.net" else "https://" + vars.adlsstorage_name + ".dfs.core.windows.net",
    "TargetKeyVaultBaseUrl":"https://" + vars.keyvault_name +".vault.azure.net",
    "TargetSystemAuthType":"MSI",
    "TargetSystemSecretName":"",
	"TargetSystemUserName":"",
    "ADFPipeline": ADFPipeline
}+commons

