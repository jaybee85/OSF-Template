local Target = {
    "AzureSqlTable" : import './types/azuresql.libsonnet',
    "AzureSqlDWTable" : import './types/synapse.libsonnet'	
};


function(TargetType="AzureSqlDWTable")
Target[TargetType]
