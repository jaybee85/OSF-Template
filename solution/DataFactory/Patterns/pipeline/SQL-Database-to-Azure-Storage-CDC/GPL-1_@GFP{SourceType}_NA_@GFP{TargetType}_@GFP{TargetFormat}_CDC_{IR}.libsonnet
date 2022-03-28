
function(GenerateArm="false",GFPIR="IRA",SourceType="SqlServerTable",SourceFormat="NA",TargetType="AzureBlobFS",TargetFormat="Parquet")
local Wrapper = import '../static/partials/wrapper.libsonnet';
local ParentPipelineTemplate = import '../static/partials/ParentPipeline.libsonnet';
local Name = if(GenerateArm=="false") 
			then "GPL_"+SourceType+"_"+SourceFormat+"_"+TargetType+"_"+TargetFormat+"_CDC_"+GFPIR 
			else "[concat(parameters('dataFactoryName'), '/','GPL_"+SourceType+"_"+SourceFormat+"_"+TargetType+"_"+TargetFormat+"_CDC_" + "', parameters('integrationRuntimeShortName'))]";
local CalledPipelineName = if(GenerateArm=="false") 
			then "GPL_"+SourceType+"_"+SourceFormat+"_"+TargetType+"_"+TargetFormat+ "_CDC_Primary_"+GFPIR 
			else "[concat('GPL_"+SourceType+"_"+SourceFormat+"_"+TargetType+"_"+TargetFormat+"_CDC_Primary_" + "', parameters('integrationRuntimeShortName'))]";
local Folder =  if(GenerateArm=="false") 
					then "ADS Go Fast/Data Movement/SQL-Database-to-Azure-Storage-CDC/" + GFPIR + "/ErrorHandler/"
					else "[concat('ADS Go Fast/Data Movement/SQL-Database-to-Azure-Storage-CDC', parameters('integrationRuntimeShortName'), '/ErrorHandler/')]";

local pipeline = {} + ParentPipelineTemplate(Name, CalledPipelineName, Folder);
	
Wrapper(GenerateArm,pipeline)+{}