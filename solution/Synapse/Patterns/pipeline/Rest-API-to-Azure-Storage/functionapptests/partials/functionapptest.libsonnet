local commons = import '../../../static/partials/functionapptest_commons.libsonnet';
local vars = import '../../../static/partials/secrets.libsonnet';
function(
    SynapsePipeline = "GPL_SparkNotebookExecution_Azure",
    Pattern = "REST API to Azure Storage",
    TestNumber = "-1",
    SourceFormat = "Rest",
    SourceType = "Rest",
    SourceRelativeUrl = "", 
    SourceRequestBody = "",
    SourceRequestMethod = "GET",
    SourceSystemAuthType = "MSI",
    SourceMaxConcurrentConnections = 0,
    TargetFormat = "Json",
    TargetType = "Json",
    TargetDataFilename = "Test.Json",
    TargetRelativePath = "",
    TargetSystemAuthType = "MSI",
    TestDescription = "",
    Purview = "Disabled",
    QualifiedIDAssociation = "TaskMasterId",
    UseNotebookActivity = "Enabled",
    PartitionSize = "Single",
    ExecuteNotebook = "RestAPINotebook"
    )
{
    local TaskMasterJson =     
    {
        "ExecuteNotebook": ExecuteNotebook,
        "Purview": Purview,
        "QualifiedIDAssociation": QualifiedIDAssociation,
        "PartitionSize": PartitionSize,
        "Source":{
            "Type": SourceFormat,
            "RelativeUrl": SourceRelativeUrl,
            "RequestBody": SourceRequestBody,
            "RequestMethod": SourceRequestMethod                       
            
        },

        "Target":{
            "Type":TargetFormat,
            "RelativePath":"",
            "DataFileName": TargetDataFilename,

        },
    },

    local TaskInstanceJson =  
    {
        
    },

    local SourceSystemJson = 
    {
            
    },

    local TargetSystemJson = 
    {   
         
    },
             
    "TaskInstanceJson":std.manifestJson(TaskInstanceJson),
    "TaskTypeId":-9,
    "TaskType":Pattern,
    "EngineName":vars.datafactory_name,
    "EngineResourceGroup":vars.resource_group_name,
    "EngineSubscriptionId":vars.subscription_id,
    "EngineJson":  '{"endpoint": "https://' + vars.synapse_workspace_name + '.dev.azuresynapse.net", "DeltaProcessingNotebook": "DeltaProcessingNotebook"}',
    "TaskMasterJson":std.manifestJson(TaskMasterJson),       
    "TaskMasterId":TestNumber,
    "SourceSystemId": -17,
    "SourceSystemJSON":std.manifestJson(SourceSystemJson),
    "SourceSystemType":SourceType,
    "SourceSystemServer":"N/A",
    "SourceKeyVaultBaseUrl":"https://" + vars.keyvault_name +".vault.azure.net",
    "SourceSystemAuthType":SourceSystemAuthType,
    "SourceSystemSecretName":"",
    "SourceSystemUserName":"",   
    "TargetSystemId": -8,
    "TargetSystemJSON":std.manifestJson(TargetSystemJson),
    "TargetSystemType":TargetType,
    "TargetSystemServer":"N/A",
    "TargetKeyVaultBaseUrl":"https://" + vars.keyvault_name +".vault.azure.net",
    "TargetSystemAuthType":TargetSystemAuthType,
    "TargetSystemSecretName":"",
	"TargetSystemUserName":"",
    "SynapsePipeline": SynapsePipeline,
    "TestDescription": "[" + TestNumber + "] " +  " Notebook execution test. NOTE: Please create a notebook in Synapse called Notebook1 to execute otherwise this wont work - the notebook can be blank.",
    "DependencyChainTag": "", 
    "UseNotebookActivity": UseNotebookActivity
}+commons

