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
            "infoText": "Use this to enable the pipeline to be written to purview. Note: This will not work if Purview is not enabled and configured with the ExecutionEngine."
        },
        "QualifiedIDAssociation": {
            "type": "string",
            "default": "TaskMasterID",
            "enum": [
                "ExecutionID",
                "TaskMasterID"
            ],
            "infoText": "This is used to enable Purview to direct the QualifiedID (UID) to attach itself to the relevant ID. Note: If attached to the ExecutionID each indiviudal run of the pipeline with have a lineage."
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