function(GenerateArm=false,SparkPoolName = "")
{


    "notebook": {
        "referenceName": "@string(json(string(pipeline().parameters.TaskObject)).ExecutionEngine.JsonProperties.Properties.DeltaProcessingNotebook)",
        "type": "NotebookReference"
    },
    "parameters": {
        "TaskObject": {
            "value": {
                "value": "@string(pipeline().parameters.TaskObject)",
                "type": "Expression"
            },
            "type": "string"
        }
    },
    "snapshot": true,
    "sparkPool": {
        "referenceName": SparkPoolName,
        "type": "BigDataPoolReference"
    }
}