function(seed=0)
local tests =
[
    //****************************************************************/
    //**                    Storage to Storage Tests                 */
    //****************************************************************/
    //GPL_AzureBlobFS_Binary_AzureBlobFS_Binary_FullLoad
    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Parquet",
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
        "SourceWriteSchemaToPurview": "Disabled",
        
        "TargetFormat":"Delta",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",

        "Description": "File copy between datalake zones - parquet to delta - Disabled: Purview / CDCSource / SparkTableCreate",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure", 

        "Purview": "Disabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Disabled",
        "SparkTableCreate": "Disabled",
        "SparkTableDBName": "",
        "SparkTableName": ""

       
    },

    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Parquet",
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
        "SourceWriteSchemaToPurview": "Disabled",

        
        "TargetFormat":"Delta",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",

        "Description": "File copy between datalake zones - parquet to delta - Disabled: Purview / CDCSource - Enabled: SparkTableCreate",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure", 

        "Purview": "Disabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Disabled",
        "SparkTableCreate": "Enabled",
        "SparkTableDBName": "TestDB",
        "SparkTableName": "TestTable"

       
    },

    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Parquet",
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
        "SourceWriteSchemaToPurview": "Disabled",

        "TargetFormat":"Delta",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",

        "Description": "File copy between datalake zones - parquet to delta - Disabled: SparkTableCreate / CDCSource - Enabled: Purview",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure", 

        "Purview": "Enabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Disabled",
        "SparkTableCreate": "Disabled",
        "SparkTableDBName": "",
        "SparkTableName": ""

       
    },

    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Parquet",
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
        "SourceWriteSchemaToPurview": "Disabled",

        "TargetFormat":"Delta",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",

        "Description": "File copy between datalake zones - parquet to delta - Disabled: SparkTableCreate / Purview - Enabled: CDCSource",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure", 

        "Purview": "Disabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Enabled",
        "SparkTableCreate": "Disabled",
        "SparkTableDBName": "",
        "SparkTableName": ""

       
    },

    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Parquet",
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
        "SourceWriteSchemaToPurview": "Disabled",

        "TargetFormat":"Delta",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",

        "Description": "File copy between datalake zones - parquet to delta - Disabled: CDCSource - Enabled: SparkTableCreate / Purview",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure", 

        "Purview": "Enabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Disabled",
        "SparkTableCreate": "Enabled",
        "SparkTableDBName": "TestDB",
        "SparkTableName": "TestTable2"

       
    },

    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Parquet",
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
        "SourceWriteSchemaToPurview": "Disabled",
        
        "TargetFormat":"Delta",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",

        "Description": "File copy between datalake zones - parquet to delta - Disabled: Purview - Enabled: SparkTableCreate / CDCSource",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure", 

        "Purview": "Disabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Enabled",
        "SparkTableCreate": "Enabled",
        "SparkTableDBName": "TestDB",
        "SparkTableName": "TestTable3"

       
    },

    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Parquet",
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
        "SourceWriteSchemaToPurview": "Disabled",

        "TargetFormat":"Delta",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",

        "Description": "File copy between datalake zones - parquet to delta - Disabled: SparkTableCreate - Enabled: Purview / CDCSource",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure", 

        "Purview": "Enabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Enabled",
        "SparkTableCreate": "Disabled",
        "SparkTableDBName": "",
        "SparkTableName": ""

       
    },

    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Parquet",
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
        "SourceWriteSchemaToPurview": "Disabled",
        
        "TargetFormat":"Delta",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",

        "Description": "File copy between datalake zones - parquet to delta - Enabled: Purview / CDCSource / SparkTableCreate",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure", 

        "Purview": "Enabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Enabled",
        "SparkTableCreate": "Enabled",
        "SparkTableDBName": "TestDB",
        "SparkTableName": "TestTable4"

       
    },



    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Delta",
        "SourceType":"ADLS",        
        "SourceDataFilename":"SalesLT_Customer_Delta/SalesLT.Customer/",
        "SourceSourceSystemAuthType": "MSI",
        "SourceSchemaFileName":"SalesLT.Customer*.json", 
        "SourceSkipLineCount":"",
        "SourceFirstRowAsHeader": "false",
        "SourceSheetName":"",
        "SourceMaxConcurrentConnections":0,
        "SourceRecursively":"false",
        "SourceDeleteAfterCompletion":"false",
        "SourceWriteSchemaToPurview": "Disabled",
        
        "TargetFormat":"Delta",
        "TargetType":"ADLS",        
        "TargetDataFilename":"DeltaTable/SalesLT.Customer",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",

        "Description": "File copy between datalake zones - delta to delta",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure",

        "Purview": "Disabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Disabled",
        "SparkTableCreate": "Disabled",
        "SparkTableDBName": "",
        "SparkTableName": "" 
       
    },


    {        
        "Active": true,        
        "Pattern": "Azure Storage to Azure Storage",         
        "SourceSystemAuthType": "MSI",
        
        "SourceFormat":"Delta",
        "SourceType":"ADLS",        
        "SourceDataFilename":"SalesLT_Customer_Delta/SalesLT.Customer/",
        "SourceSourceSystemAuthType": "MSI",
        "SourceSchemaFileName":"SalesLT.Customer*.json", 
        "SourceSkipLineCount":"",
        "SourceFirstRowAsHeader": "false",
        "SourceSheetName":"",
        "SourceMaxConcurrentConnections":0,
        "SourceRecursively":"false",
        "SourceDeleteAfterCompletion":"false",
        "SourceWriteSchemaToPurview": "Disabled",

        "TargetFormat":"Parquet",
        "TargetType":"ADLS",        
        "TargetDataFilename":"SalesLT.Customer*.parquet",
        "TargetSchemaFileName":"SalesLT.Customer.json",
        "TargetSourceSystemAuthType":"MSI", 
        "TargetSkipLineCount":"",
        "TargetFirstRowAsHeader": "false",
        "TargetSheetName":"",
        "TargetMaxConcurrentConnections":0,
        "TargetRecursively":"false",
        "TargetDeleteAfterCompletion":"false",
        "TargetWriteSchemaToPurview": "Disabled",
        
        "Description": "File copy between datalake zones - delta to parquet",  
        "SynapsePipeline": "GPL_SparkNotebookExecution_Primary_Azure",

        "Purview": "Disabled",
        "QualifiedIDAssociation": "TaskMasterId",
        "CDCSource": "Disabled",
        "SparkTableCreate": "Disabled",
        "SparkTableDBName": "",
        "SparkTableName": "" 
       
    }

];

local template = import "./partials/functionapptest.libsonnet";

local process = function(index, t)
template(
    t.SynapsePipeline,
    t.Pattern, 
    seed-index,//t.TestNumber,
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
    t.SourceWriteSchemaToPurview,
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
    t.TargetWriteSchemaToPurview,
    t.Description,
    t.Purview,
    t.QualifiedIDAssociation,
    t.CDCSource,
    t.SparkTableCreate,
    t.SparkTableDBName,
    t.SparkTableName
);


std.mapWithIndex(process, tests)

