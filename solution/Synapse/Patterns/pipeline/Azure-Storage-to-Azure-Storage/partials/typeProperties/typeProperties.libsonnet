function(GenerateArm=false,SparkPoolName = "")
{


    "notebook": {
        "referenceName": "@if(contains(string(pipeline().parameters.TaskObject), 'ExecuteNotebook'), string(json(string(pipeline().parameters.TaskObject)).ExecuteNotebook), string(json(string(pipeline().parameters.TaskObject)).ExecutionEngine.JsonProperties.DeltaProcessingNotebook))",
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