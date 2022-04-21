function(GenerateArm="false", GFPIR="Azure", SourceType="AzureBlobFS")
{

    local AzureSqlTable = import './typesettings/AzureSqlTable.libsonnet',
    local SqlServerTable = import './typesettings/SqlServerTable.libsonnet',
    local AzureSqlDWTable = import './typesettings/AzureSqlDWTable.libsonnet',

    local SourceType = {
		"AzureSqlTable" : AzureSqlTable(GenerateArm, GFPIR),
    "SqlServerTable" : SqlServerTable(GenerateArm, GFPIR),
    "AzureSqlDWTable" : AzureSqlDWTable(GenerateArm, GFPIR)
	  },
    
    
    SourceType:SourceType   
}