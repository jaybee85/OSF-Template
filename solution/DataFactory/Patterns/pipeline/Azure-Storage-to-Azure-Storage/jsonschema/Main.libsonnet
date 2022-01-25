local partials = {
   "DelimitedText": import "Partial_DelimitedText.libsonnet",
   "Excel": import "Partial_Excel.libsonnet",
   "Json": import "Partial_Json.libsonnet",
   "Parquet": import "Partial_Parquet.libsonnet",
   "Binary": import "Partial_Binary.libsonnet"   
};

function(SourceType = "", SourceFormat = "Excel",TargetType = "AzureSqlTable", TargetFormat = "Excel")
{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "type": "object",
    "title": "TaskMasterJson",
    "properties": {
        "Source": partials[SourceFormat](),
        "Target": partials[TargetFormat]()
    },
    "required": [
        "Source",
        "Target"
    ]
}