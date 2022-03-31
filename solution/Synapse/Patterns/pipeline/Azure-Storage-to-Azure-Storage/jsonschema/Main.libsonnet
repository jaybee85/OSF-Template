local partials = {
   "Parquet": import "Partial_Parquet.libsonnet",
   "Delta": import "Partial_Delta.libsonnet"   
};


function(SourceType = "Parquet", SourceFormat = "Delta",TargetType = "AzureSqlTable", TargetFormat = "Delta")
{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "type": "object",
    "title": "TaskMasterJson",
    "properties": {
        "Purview": {
            "type": "string",
            "default": "Disabled",
            "enum": [
                "Enabled",
                "Disabled"
            ],
            "options": {
                "infoText": "Use this to enable the pipeline to be written to purview. Note: This will not work if Purview is not enabled and configured with the ExecutionEngine."
            }
        },
        "QualifiedIDAssociation": {
            "type": "string",
            "default": "TaskMasterId",
            "enum": [
                "ExecutionId",
                "TaskMasterId"
            ],
            "options": {
                "infoText": "This is used to enable Purview to direct the QualifiedID (UID) to attach itself to the chosen ID. Note: If attached to the ExecutionId each indiviudal run of the pipeline will have a lineage."
            }
        },      
        "Source": partials[SourceFormat](),
        "Target": partials[TargetFormat]()
    },
    "required": [
        "Source",
        "Target",
        "Purview"
    ]
}