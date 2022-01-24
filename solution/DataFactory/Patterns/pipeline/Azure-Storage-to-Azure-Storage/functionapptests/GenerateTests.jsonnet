function(seed=0)
local tests =
[
    //****************************************************************/
    //**                    Storage to Storage Tests                 */
    //****************************************************************/
    //GPL_AzureBlobFS_Binary_AzureBlobFS_Binary_FullLoad
    {        
        "Active": true,        
        "Pattern": "Azure Storage to SQL Database",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Binary",
        "SourceType":"ADLS",        
        "SourceDataFilename":"SalesLT.Customer*.parquet",
        "SourceSourceSystemAuthType": "MSI",
        "SourceSchemaFileName":"SalesLT.Customer*.json", 
        "SourceSkipLineCount":"",
        "SourceFirstRowAsHeader": "false",
        "SourceSheetName":"",
        "SourceMaxConcurrentConnections":0,
        "SourceRecursively":"false",
        "SourceDeleteAfterCompletion":"false",
        
        "TargetFormat":"Binary",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer.parquet",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        
        "Description": "FullLoad",  
        "ADFPipeline": "GPL_AzureBlobFS_Binary_AzureBlobFS_Binary" 
       
    },
    {        
        "Active": true,        
        "Pattern": "Azure Storage to SQL Database",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Binary",
        "SourceType":"ADLS",        
        "SourceDataFilename":"SalesLT.Customer*.parquet",
        "SourceSourceSystemAuthType": "MSI",
        "SourceSchemaFileName":"SalesLT.Customer*.json", 
        "SourceSkipLineCount":"",
        "SourceFirstRowAsHeader": "false",
        "SourceSheetName":"",
        "SourceMaxConcurrentConnections":0,
        "SourceRecursively":"false",
        "SourceDeleteAfterCompletion":"false",
        
        "TargetFormat":"Binary",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer.parquet",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        
        "Description": "FullLoad",  
        "ADFPipeline": "GPL_AzureBlobFS_Binary_AzureBlobFS_Binary" 
       
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
    t.SourceDataFilename,
    t.SourceSchemaFileName,
    t.SourceSourceSystemAuthType,
    t.SourceSkipLineCount,
    t.SourceFirstRowAsHeader,
    t.SourceSheetName,
    t.SourceMaxConcurrentConnections,
    t.SourceRecursively,
    t.SourceDeleteAfterCompletion,
    t.TargetFormat,
    t.TargetType,
    t.TargetDataFilename,
    t.TargetSchemaFileName,
    t.TargetSourceSystemAuthType,
    t.TargetSkipLineCount,
    t.TargetFirstRowAsHeader,
    t.TargetSheetName,
    t.TargetMaxConcurrentConnections,
    t.TargetRecursively,
    t.TargetDeleteAfterCompletion,
);


std.mapWithIndex(process, tests)

