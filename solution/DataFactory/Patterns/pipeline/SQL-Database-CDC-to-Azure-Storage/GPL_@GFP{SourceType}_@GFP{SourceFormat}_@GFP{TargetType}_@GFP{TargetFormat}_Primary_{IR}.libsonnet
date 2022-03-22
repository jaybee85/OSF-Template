function(GenerateArm="false",GFPIR="{IRA}",SourceType="AzureBlobFS",SourceFormat="Binary", TargetType="AzureBlobFS", TargetFormat="Binary")

local generateArmAsBool = GenerateArm == "true";
local Wrapper = import '../static/partials/wrapper.libsonnet';

local typeProperties = import './partials/typeProperties/typeProperties.libsonnet';

local parameterDefaultValue = import './partials/parameterDefaultValue.libsonnet';

local name =  if(!generateArmAsBool) 
			then "GPL_"+SourceType+"_"+SourceFormat+"_"+TargetType+"_"+TargetFormat+"_" + "Primary_" + GFPIR 
			else "[concat(parameters('dataFactoryName'), '/','GPL_"+SourceType+"_"+SourceFormat+"_"+TargetType+"_"+TargetFormat+"_Primary_" + "', parameters('integrationRuntimeShortName'))]";

local copyActivityName = "Copy %(Source)s to %(Target)s" % {Source: SourceType, Target: TargetType};
local logSuccessActivityName = "%(ActivityName)s Succeed" % {ActivityName: copyActivityName};
local logStartedActivityName = "%(ActivityName)s Started" % {ActivityName: copyActivityName};
local logFailedActivityName = "%(ActivityName)s Failed" % {ActivityName: copyActivityName};

local pipeline = {
	"name": name,
	"properties": {
		"activities": [
            {
                "name": GetChangeCount,
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
                "typeProperties": typeProperties(generateArmAsBool, GFPIR, SourceType, SourceFormat, TargetType, TargetFormat),
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
                            "typeProperties": {
                                "source": {
                                    "type": "AzureSqlSource",
                                    "sqlReaderQuery": {
                                        "value": "@variables('SQLStatement2')",
                                        "type": "Expression"
                                    },
                                    "queryTimeout": "02:00:00",
                                    "partitionOption": "None"
                                },
                                "sink": {
                                    "type": "ParquetSink",
                                    "storeSettings": {
                                        "type": "AzureBlobFSWriteSettings"
                                    },
                                    "formatSettings": {
                                        "type": "ParquetWriteSettings"
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
                            },
                            "inputs": [
                                {
                                    "referenceName": "GDS_AzureSqlTable_NA_Azure",
                                    "type": "DatasetReference",
                                    "parameters": {
                                        "Database": "@pipeline().parameters.TaskObject.Source.System.Database",
                                        "Schema": "@pipeline().parameters.TaskObject.Source.TableSchema",
                                        "Server": "@pipeline().parameters.TaskObject.Source.System.SystemServer",
                                        "Table": "@pipeline().parameters.TaskObject.Source.TableName"
                                    }
                                }
                            ],
                            "outputs": [
                                {
                                    "referenceName": "GDS_AzureBlobFS_Parquet_Azure",
                                    "type": "DatasetReference",
                                    "parameters": {
                                        "FileName": "@pipeline().parameters.TaskObject.Target.DataFileName",
                                        "RelativePath": "@pipeline().parameters.TaskObject.Target.RelativePath",
                                        "StorageAccountContainerName": "@pipeline().parameters.TaskObject.Target.System.Container",
                                        "StorageAccountEndpoint": "@pipeline().parameters.TaskObject.Target.System.SystemServer"
                                    }
                                }
                            ]
                        },
                        {
                            "name": "Set SQL Statement 2",
                            "type": "SetVariable",
                            "dependsOn": [],
                            "userProperties": [],
                            "typeProperties": {
                                "variableName": "SQLStatement2",
                                "value": {
                                    "value": "@pipeline().parameters.TaskObject.Source.SQLStatement",
                                    "type": "Expression"
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
                "defaultValue":{}
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
            }
        },
        "annotations": []
    },
	"type": "Microsoft.DataFactory/factories/pipelines"
};
Wrapper(GenerateArm,pipeline)+{}