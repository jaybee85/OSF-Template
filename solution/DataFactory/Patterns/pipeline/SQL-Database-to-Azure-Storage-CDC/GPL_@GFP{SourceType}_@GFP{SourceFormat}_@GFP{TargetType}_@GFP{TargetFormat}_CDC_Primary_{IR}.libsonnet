function(GenerateArm="false",GFPIR="Azure",SourceType="SqlServerTable",SourceFormat="Table", TargetType="AzureBlobFS", TargetFormat="Parquet")

local generateArmAsBool = GenerateArm == "true";
local Wrapper = import '../static/partials/wrapper.libsonnet';

local typePropertiesInputOnly = import './partials/CDC_CopyActivity_TypeProperties_InputOnly.libsonnet';
local typePropertiesInputOutput = import './partials/CDC_CopyActivity_TypeProperties_InputOutput.libsonnet';
local SQL_Statement1 = "DECLARE  @from_lsn binary(10), @to_lsn binary(10);  \nSET @from_lsn =sys.fn_cdc_get_min_lsn('SalesLT.Customer');  \nSET @to_lsn = sys.fn_cdc_map_time_to_lsn('largest less than or equal',  GETDATE());\nSELECT count(1) changecount FROM cdc.fn_cdc_get_net_changes_SalesLT_Customer(@from_lsn, @to_lsn, 'all');";
local SQL_Statement2 = "SELECT sys.fn_cdc_map_time_to_lsn('largest less than or equal', GETDATE());";
local parameterDefaultValue = import './partials/parameterDefaultValue.libsonnet';
local AzureBlobFS_Parquet_CopyActivity_Output = import './partials/CDC_CopyActivity_AzureBlobFS_Parquet_Outputs.libsonnet';
local AzureBlobStorage_Parquet_CopyActivity_Output = import './partials/CDC_CopyActivity_AzureBlobStorage_Parquet_Outputs.libsonnet';
local AzureSqlTable_NA_CopyActivity_Inputs = import './partials/CDC_CopyActivity_AzureSqlTable_NA_Inputs.libsonnet';
local SqlServerTable_NA_CopyActivity_Inputs = import './partials/CDC_CopyActivity_SqlServerTable_NA_Inputs.libsonnet';

local name =  if(!generateArmAsBool) 
			then "GPL_"+SourceType+"_"+SourceFormat+"_"+TargetType+"_"+TargetFormat+"_CDC_" + "Primary_" + GFPIR 
			else "[concat(parameters('dataFactoryName'), '/','GPL_"+SourceType+"_"+SourceFormat+"_"+TargetType+"_"+TargetFormat+"_CDC_Primary_" + "', parameters('integrationRuntimeShortName'))]";

local copyActivityName = "Copy %(Source)s to %(Target)s" % {Source: SourceType, Target: TargetType};
local logSuccessActivityName = "%(ActivityName)s Succeed" % {ActivityName: copyActivityName};
local logStartedActivityName = "%(ActivityName)s Started" % {ActivityName: copyActivityName};
local logFailedActivityName = "%(ActivityName)s Failed" % {ActivityName: copyActivityName};

local pipeline = {
	"name": name,
    "properties": {
        "activities": [
            {
                "name": "GetChangeCount",
                "type": "Lookup",
                "dependsOn": [
                    {
                        "activity": "Set SQL Statement 1",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": typePropertiesInputOnly(GenerateArm,GFPIR,SourceType, TargetType, TargetFormat, SQL_Statement1)
            },
            {
                "name": "HasChangedRows",
                "type": "IfCondition",
                "dependsOn": [
                    {
                        "activity": "GetChangeCount",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "expression": {
                        "value": "@greater(int(activity('GetChangeCount').output.firstRow.changecount),0)",
                        "type": "Expression"
                    },
                    "ifTrueActivities": [
                        {
                            "name": "Set SQL Statement 2",
                            "type": "SetVariable",
                            "dependsOn": [
                                {
                                    "activity": "SetWatermark",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "variableName": "SQLStatement2",
                                "value": {
                                    "value": "@pipeline().parameters.TaskObject.Source.SQLStatement",
                                    "type": "Expression"
                                }
                            }
                        },
                        {
                            "name": "IncrementalCopy",
                            "type": "Copy",
                            "dependsOn": [
                                {
                                    "activity": "Set SQL Statement 2",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "policy": {
                                "timeout": "7.00:00:00",
                                "retry": 0,
                                "retryIntervalInSeconds": 30,
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": typePropertiesInputOutput(GenerateArm,GFPIR,SourceType, TargetType, TargetFormat),
                            "inputs": (if(SourceType=="AzureSqlTable") then AzureSqlTable_NA_CopyActivity_Inputs(GenerateArm,GFPIR) else SqlServerTable_NA_CopyActivity_Inputs(GenerateArm,GFPIR)),
                            "outputs":(if(TargetType=="AzureBlobFS") then AzureBlobFS_Parquet_CopyActivity_Output(GenerateArm,GFPIR) else AzureBlobStorage_Parquet_CopyActivity_Output(GenerateArm,GFPIR))
                            
                        },
                        {
                            "name": "GetLSNLatest",
                            "type": "Lookup",
                            "dependsOn": [],
                            "policy": {
                                "timeout": "7.00:00:00",
                                "retry": 0,
                                "retryIntervalInSeconds": 30,
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": typePropertiesInputOnly(GenerateArm,GFPIR,SourceType, TargetType, TargetFormat, SQL_Statement1)

                        },
                        {
                            "name": "SetWatermark",
                            "type": "SetVariable",
                            "dependsOn": [
                                {
                                    "activity": "GetLSNLatest",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "variableName": "NewWatermark",
                                "value": {
                                    "value": "@activity('GetLSNLatest').output",
                                    "type": "Expression"
                                }
                            }
                        },
                        {
                            "name": "AF Persist Parquet Metadata",
                            "type": "AzureFunctionActivity",
                            "dependsOn": [
                                {
                                    "activity": "Get Parquet Metadata",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "policy": {
                                "timeout": "7.00:00:00",
                                "retry": 0,
                                "retryIntervalInSeconds": 30,
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": {
                                "functionName": "TaskExecutionSchemaFile",
                                "method": "POST",
                                "body": {
                                    "value": "@json(\n concat(\n '{\"TaskInstanceId\":\"', \n string(pipeline().parameters.TaskObject.TaskInstanceId), \n '\",\"ExecutionUid\":\"', \n string(pipeline().parameters.TaskObject.ExecutionUid), \n '\",\"RunId\":\"', \n string(pipeline().RunId), \n '\",\"StorageAccountName\":\"', \n string(pipeline().parameters.TaskObject.Target.System.SystemServer), \n '\",\"StorageAccountContainer\":\"', \n string(pipeline().parameters.TaskObject.Target.System.Container), \n '\",\"RelativePath\":\"', \n string(pipeline().parameters.TaskObject.Target.Instance.TargetRelativePath), \n '\",\"SchemaFileName\":\"', \n string(pipeline().parameters.TaskObject.Target.SchemaFileName), \n '\",\"SourceType\":\"', \n string(pipeline().parameters.TaskObject.Source.System.Type), \n '\",\"TargetType\":\"', \n if(\n    contains(\n    string(pipeline().parameters.TaskObject.Target.System.SystemServer),\n    '.dfs.core.windows.net'\n    ),\n   'ADLS',\n   'Azure Blob'), \n '\",\"Data\":',\n string(activity('Get Parquet Metadata').output),\n ',\"MetadataType\":\"Parquet\"}')\n)",
                                    "type": "Expression"
                                }
                            },
                            "linkedServiceName": {
                                "referenceName": "SLS_AzureFunctionApp",
                                "type": "LinkedServiceReference"
                            }
                        },
                        {
                            "name": "Get Parquet Metadata",
                            "type": "GetMetadata",
                            "dependsOn": [
                                {
                                    "activity": "IncrementalCopy",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "policy": {
                                "timeout": "7.00:00:00",
                                "retry": 0,
                                "retryIntervalInSeconds": 30,
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": {
                                "dataset": {
                                    "referenceName": "GDS_AzureBlobStorage_Parquet_Azure",
                                    "type": "DatasetReference",
                                    "parameters": {
                                        "FileName": {
                                            "value": "@pipeline().parameters.TaskObject.Target.DataFileName",
                                            "type": "Expression"
                                        },
                                        "RelativePath": {
                                            "value": "@pipeline().parameters.TaskObject.Target.Instance.TargetRelativePath",
                                            "type": "Expression"
                                        },
                                        "StorageAccountContainerName": {
                                            "value": "@pipeline().parameters.TaskObject.Target.System.Container",
                                            "type": "Expression"
                                        },
                                        "StorageAccountEndpoint": {
                                            "value": "@pipeline().parameters.TaskObject.Target.System.SystemServer",
                                            "type": "Expression"
                                        }
                                    }
                                },
                                "fieldList": [
                                    "structure"
                                ],
                                "storeSettings": {
                                    "type": "AzureBlobStorageReadSettings"
                                }
                            }
                        },
                        {
                            "name": "AF Set New Watermark",
                            "type": "ExecutePipeline",
                            "dependsOn": [
                                {
                                    "activity": "AF Persist Parquet Metadata",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "pipeline": {
                                    "referenceName": "SPL_AzureFunction",
                                    "type": "PipelineReference"
                                },
                                "waitOnCompletion": false,
                                "parameters": {
                                    "Body": {
                                        "value": "@json(concat('{\"TaskInstanceId\":\"', string(pipeline().parameters.TaskObject.TaskInstanceId), '\",\"ExecutionUid\":\"', string(pipeline().parameters.TaskObject.ExecutionUid), '\",\"RunId\":\"', string(pipeline().RunId), '\",\"TaskMasterId\":\"', string(pipeline().parameters.TaskObject.TaskMasterId),'\",\"TaskMasterWaterMarkColumnType\":\"', 'lsn','\",\"WaterMarkValue\":\"', variables('NewWatermark'), '\"}'))",
                                        "type": "Expression"
                                    },
                                    "FunctionName": "WaterMark",
                                    "Method": "Post"
                                }
                            }
                        },
                        {
                            "name": "Pipeline AF Log - Copy Failed",
                            "type": "ExecutePipeline",
                            "dependsOn": [
                                {
                                    "activity": "IncrementalCopy",
                                    "dependencyConditions": [
                                        "Failed"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "pipeline": {
                                    "referenceName": "SPL_AzureFunction",
                                    "type": "PipelineReference"
                                },
                                "waitOnCompletion": false,
                                "parameters": {
                                    "Body": {
                                        "value": "@json(concat('{\"TaskInstanceId\":\"', string(pipeline().parameters.TaskObject.TaskInstanceId), '\",\"ExecutionUid\":\"', string(pipeline().parameters.TaskObject.ExecutionUid), '\",\"RunId\":\"', string(pipeline().RunId), '\",\"LogTypeId\":1,\"LogSource\":\"ADF\",\"ActivityType\":\"Copy SQL to Storage\",\"StartDateTimeOffSet\":\"', string(pipeline().TriggerTime), '\",\"EndDateTimeOffSet\":\"', string(utcnow()), '\",\"Comment\":\"', string(activity('IncrementalCopy').error.message), '\",\"Status\":\"Failed\"}'))",
                                        "type": "Expression"
                                    },
                                    "FunctionName": "Log",
                                    "Method": "Post"
                                }
                            }
                        },
                        {
                            "name": "Pipeline AF Log - Copy Succeed",
                            "type": "ExecutePipeline",
                            "dependsOn": [
                                {
                                    "activity": "IncrementalCopy",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "pipeline": {
                                    "referenceName": "SPL_AzureFunction",
                                    "type": "PipelineReference"
                                },
                                "waitOnCompletion": false,
                                "parameters": {
                                    "Body": {
                                        "value": "@json(concat('{\"TaskInstanceId\":\"', string(pipeline().parameters.TaskObject.TaskInstanceId), '\",\"ExecutionUid\":\"', string(pipeline().parameters.TaskObject.ExecutionUid), '\",\"RunId\":\"', string(pipeline().RunId), '\",\"LogTypeId\":1,\"LogSource\":\"ADF\",\"ActivityType\":\"Copy SQL to Storage\",\"StartDateTimeOffSet\":\"', string(pipeline().TriggerTime), '\",\"EndDateTimeOffSet\":\"', string(utcnow()), '\",\"RowsInserted\":\"', string(activity('IncrementalCopy').output.rowsCopied), '\",\"Comment\":\"\",\"Status\":\"Complete\"}'))",
                                        "type": "Expression"
                                    },
                                    "FunctionName": "Log",
                                    "Method": "Post"
                                }
                            }
                        }
                    ]
                }
            },
            {
                "name": "Set SQL Statement 1",
                "type": "SetVariable",
                "dependsOn": [],
                "userProperties": [],
                "typeProperties": {
                    "variableName": "SQLStatement1",
                    "value": {
                        "value": "@replace(\n replace(\n   pipeline().parameters.SQLStatementParam1,\n   '<Schema>',\n   string(pipeline().parameters.TaskObject.Source.TableSchema)\n   ),\n '<Table>',string(pipeline().parameters.TaskObject.Source.TableName))",
                        "type": "Expression"
                    }
                }
            }
        ],
        "parameters": {
            "TaskObject": {
                "type": "object",
                "defaultValue": {
                    "TaskInstanceId": 1,
                    "TaskMasterId": 2,
                    "TaskStatus": "InProgress",
                    "TaskType": "SQL Database to Azure Storage",
                    "Enabled": 1,
                    "ExecutionUid": "8448eabb-9ba4-4779-865b-29e973431273",
                    "NumberOfRetries": 0,
                    "DegreeOfCopyParallelism": 1,
                    "KeyVaultBaseUrl": "https://ark-stg-kv-ads-irud.vault.azure.net/",
                    "ScheduleMasterId": "-4",
                    "TaskGroupConcurrency": "10",
                    "TaskGroupPriority": 0,
                    "TaskExecutionType": "ADF",
                    "ExecutionEngine": {
                        "EngineId": -1,
                        "EngineName": "ark-stg-adf-ads-irud",
                        "SystemType": "Datafactory",
                        "ResourceGroup": "dlzdev04",
                        "SubscriptionId": "ed1206e0-17c7-4bc2-ad4b-f8d4dab9284f",
                        "ADFPipeline": "GPL_AzureSqlTable_NA_AzureBlobFS_Parquet_Azure",
                        "EngineJson": "{}",
                        "TaskDatafactoryIR": "Azure"
                    },
                    "Source": {
                        "System": {
                            "SystemId": -1,
                            "SystemServer": "ark-stg-sql-ads-irud.database.windows.net",
                            "AuthenticationType": "MSI",
                            "Type": "Azure SQL",
                            "Username": null,
                            "Database": "Samples"
                        },
                        "Instance": {
                            "TargetRelativePath": ""
                        },
                        "ChunkField": "",
                        "ChunkSize": 0,
                        "ExtractionSQL": "",
                        "IncrementalType": "Full",
                        "TableName": "Customer",
                        "TableSchema": "SalesLT",
                        "Type": "Table",
                        "IncrementalSQLStatement": "",
                        "SQLStatement": "SELECT * FROM SalesLT.Customer"
                    },
                    "Target": {
                        "System": {
                            "SystemId": -8,
                            "SystemServer": "https://arkstgdlsadsirudadsl.dfs.core.windows.net",
                            "AuthenticationType": "MSI",
                            "Type": "ADLS",
                            "Username": null,
                            "Container": "datalakelanding"
                        },
                        "Instance": {
                            "TargetRelativePath": ""
                        },
                        "DataFileName": "TestFile.parquet",
                        "RelativePath": "",
                        "SchemaFileName": "TestFile.json",
                        "Type": "Parquet"
                    }
                }
            },
            "SQLStatementParam2": {
                "type": "string",
                "defaultValue": "DECLARE @from_lsn binary(10), @to_lsn binary(10);  SET @from_lsn = sys.fn_cdc_get_min_lsn('<Schema>_<Table>');  SET @to_lsn = sys.fn_cdc_map_time_to_lsn('largest less than or equal',  GETDATE()); SELECT * FROM cdc.fn_cdc_get_net_changes_<Schema>_<Table>(@from_lsn, @to_lsn, 'all')"
            },
            "SQLStatementParam1": {
                "type": "string",
                "defaultValue": "DECLARE  @from_lsn binary(10), @to_lsn binary(10);   SET @from_lsn = sys.fn_cdc_get_min_lsn('<Schema>_<Table>');   SET @to_lsn = sys.fn_cdc_map_time_to_lsn('largest less than or equal',  GETDATE()); SELECT count(1) changecount FROM cdc.fn_cdc_get_net_changes_<Schema>_<Table>(@from_lsn, @to_lsn, 'all')"
            }
        },
        "variables": {
            "SQLStatement1": {
                "type": "String"
            },
            "SQLStatement2": {
                "type": "String"
            },
            "NewWatermark": {
                "type": "String"
            }
        },
        "annotations": [],
        "lastPublishTime": "2022-03-22T03:55:20Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
};
Wrapper(GenerateArm,pipeline)+{}