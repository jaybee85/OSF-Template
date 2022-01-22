{
        "type": "SqlDWSink",
        "preCopyScript": {
            "value": "@{pipeline().parameters.TaskObject.Target.PreCopySQL}",
            "type": "Expression"
        },
        "allowPolyBase": true,
        "polyBaseSettings": {
            "rejectValue": 0,
            "rejectType": "value",
            "useTypeDefault": true
        },
        "tableOption": "autoCreate",
        "disableMetricsCollection": false
    }