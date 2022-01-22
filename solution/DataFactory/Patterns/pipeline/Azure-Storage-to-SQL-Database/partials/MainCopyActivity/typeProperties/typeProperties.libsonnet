function(GenerateArm=false,GFPIR="{IRA}",SourceType="AzureBlobStorage",SourceFormat="Excel", TargetType="AzureSqlDWTable", TargetFormat="Excel")
{
    local source = import './source/source.libsonnet',	
    local sink   = import './sink/sink.libsonnet',	

    "source": source(SourceType, SourceFormat),
    "sink": sink(TargetType),
    "enableStaging": false,
    "parallelCopies": {
        "value": "@pipeline().parameters.TaskObject.DegreeOfCopyParallelism",
        "type": "Expression"
    },
    "translator": {
        "value": "@if(and(not(equals(coalesce(pipeline().parameters.TaskObject.Source.SchemaFileName,''),'')),bool(pipeline().parameters.TaskObject.Target.AutoCreateTable)),activity('AF Get Mapping').output.value, null)",
        "type": "Expression"
    }
}
