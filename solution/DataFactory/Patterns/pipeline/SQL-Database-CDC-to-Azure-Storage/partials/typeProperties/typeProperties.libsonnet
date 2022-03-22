function(GenerateArm="false",GFPIR="{IRA}",SourceType="AzureBlobFS",SourceFormat="Binary", TargetType="AzureBlobFS", TargetFormat="Binary")
{
                    "source": {
                        "type": "AzureSqlSource",
                        "sqlReaderQuery": {
                            "value": "@variables('SQLStatement1')",
                            "type": "Expression"
                        },
                        "queryTimeout": "02:00:00",
                        "partitionOption": "None"
                    },
                    "dataset": {
                        "referenceName": "GDS_AzureSqlTable_NA_Azure",
                        "type": "DatasetReference",
                        "parameters": {
                            "Database": "@pipeline().parameters.TaskObject.Source.System.Database",
                            "Schema": "@pipeline().parameters.TaskObject.Source.TableSchema",
                            "Server": "@pipeline().parameters.TaskObject.Source.System.SystemServer",
                            "Table": "@pipeline().parameters.TaskObject.Source.TableName"
                        }
                    }
}