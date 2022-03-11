function(GenerateArm="false", SparkPoolName = "")

local generateArmAsBool = GenerateArm == "true";
local Wrapper = import '../static/partials/wrapper.libsonnet';

local typeProperties = import './partials/typeProperties/typeProperties.libsonnet';

local parameterDefaultValue = import './partials/parameterDefaultValue.libsonnet';

local name =  "GPL_SparkNotebookExecution_Primary_Auto";

local ActivityName = "CallSynapseNotebook";


local pipeline = {
	"name": name,
	"properties": {
		"activities": [
            {
                "name": "DeltaProcessingNotebook",
                "type": "SynapseNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": typeProperties(generateArmAsBool, SparkPoolName),
            },
			
		],
		"parameters": parameterDefaultValue(),
		"annotations": [],
		"lastPublishTime": "2020-08-05T04:14:00Z"
	},
	"type": "Microsoft.Synapse/workspaces/pipelines"
};
Wrapper(GenerateArm,pipeline)+{}