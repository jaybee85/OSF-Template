function(GenerateArm=false,SparkPoolName = "")
{


    "notebook": {
        "referenceName": "@pipeline().parameters.TaskObject.NotebookName",
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