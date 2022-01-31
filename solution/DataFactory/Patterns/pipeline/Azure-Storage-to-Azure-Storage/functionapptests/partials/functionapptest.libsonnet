local commons = import '../../../static/partials/functionapptest_commons.libsonnet';
local vars = import '../../../static/partials/secrets.libsonnet';
function(
    ADFPipeline = "GPL_AzureBlobStorage_ParquetAzureSqlTable_NA",
    Pattern = "Azure Storage to SQL Database",
    TestNumber = "1",
    SourceFormat = "Azure SQL",
    SourceType = "Azure SQL",
    SourceDataFilename = "SalesLT.Customer.parquet",
    SourceSchemaFileName = "SalesLT.Customer.json",
    SourceSystemAuthType = "MSI",
    SourceSkipLineCount = "",
    SourceFirstRowAsHeader ="FirstRowAsHeader",    
    SourceSheetName = "",
    SourceMaxConcurrentConnections = 0,
    SourceRecursively = "false",
    SourceDeleteAfterCompletion = "",
    TargetFormat = "Azure SQL",
    TargetType = "Azure SQL",
    TargetDataFilename = "SalesLT.Customer.parquet",
    TargetSchemaFileName = "SalesLT.Customer.json",
    TargetSystemAuthType = "MSI",
    TargetSkipLineCount = "",
    TargetFirstRowAsHeader ="FirstRowAsHeader",    
    TargetSheetName = "",
    TargetMaxConcurrentConnections = 0,
    TargetRecursively = "false",
    TargetDeleteAfterCompletion = "",
    TestDescription = "",
    )
{
    local TaskMasterJson =     
    {
        "Source":{
            "Type": SourceFormat,                       
            "RelativePath": "samples/",
            "DataFileName": SourceDataFilename,
            "SchemaFileName": SourceSchemaFileName,
            "SkipLineCount": SourceSkipLineCount,
            "FirstRowAsHeader":SourceFirstRowAsHeader,
            "SheetName":SourceSheetName,
            "MaxConcurrentConnections": SourceMaxConcurrentConnections,
            "Recursively": SourceRecursively,
            "DeleteAfterCompletion": SourceDeleteAfterCompletion,
        },
        "Target":{
            "Type":TargetFormat,
            "RelativePath": "samples/storage-to-storage-copy/",
            "DataFileName": TargetDataFilename,
            "SchemaFileName": TargetSchemaFileName,
            "SkipLineCount": TargetSkipLineCount,
            "FirstRowAsHeader":TargetFirstRowAsHeader,
            "SheetName":TargetSheetName,
            "MaxConcurrentConnections": TargetMaxConcurrentConnections,
            "Recursively": TargetRecursively,
            "DeleteAfterCompletion": TargetDeleteAfterCompletion
        }
    },

    local TaskInstanceJson =  
    {
        "SourceRelativePath": "samples/",
        "TargetRelativePath": "samples/storage-to-storage-copy/"
    },

    local SourceSystemJson = 
    {
        "Container" : "datalakeraw"       
    },

    local TargetSystemJson = 
    {   
        "Container" : "datalakeraw"    
    },
             
    "TaskInstanceJson":std.manifestJson(TaskInstanceJson),
    "TaskTypeId":2,
    "TaskType":Pattern,
    "DataFactoryName":vars.datafactory_name,
    "DataFactoryResourceGroup":vars.resource_group_name,
    "DataFactorySubscriptionId":vars.subscription_id,
    "TaskMasterJson":std.manifestJson(TaskMasterJson),       
    "TaskMasterId":TestNumber,
    "SourceSystemId":if(SourceType == "Azure Blob") then 3 else 4,
    "SourceSystemJSON":std.manifestJson(SourceSystemJson),
    "SourceSystemType":SourceType,
    "SourceSystemServer":if(SourceType == "Azure Blob") then "https://" + vars.blobstorage_name + ".blob.core.windows.net" else "https://" + vars.adlsstorage_name + ".dfs.core.windows.net",
    "SourceKeyVaultBaseUrl":"https://" + vars.keyvault_name +".vault.azure.net",
    "SourceSystemAuthType":SourceSystemAuthType,
    "SourceSystemSecretName":"",
    "SourceSystemUserName":"",   
    "TargetSystemId":if(TargetType == "Azure Blob") then 3 else 4,
    "TargetSystemJSON":std.manifestJson(TargetSystemJson),
    "TargetSystemType":TargetType,
    "TargetSystemServer":if(SourceType == "Azure Blob") then "https://" + vars.blobstorage_name + ".blob.core.windows.net" else "https://" + vars.adlsstorage_name + ".dfs.core.windows.net",
    "TargetKeyVaultBaseUrl":"https://" + vars.keyvault_name +".vault.azure.net",
    "TargetSystemAuthType":TargetSystemAuthType,
    "TargetSystemSecretName":"",
	"TargetSystemUserName":"",
    "ADFPipeline": ADFPipeline,
    "TestDescription": "[" + TestNumber + "] " + ADFPipeline + " -- " + TestDescription
}+commons

