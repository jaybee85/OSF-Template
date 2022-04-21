function(GenerateArm="false", GFPIR="Azure")
{
  local referenceName = "GDS_AzureSqlTable_NA_",
  "source": {
    "type": "AzureSqlSource",
    "sqlReaderQuery": {
      "value": "@pipeline().parameters.TaskObject.SQLStatement",
      "type": "Expression"
    },
    "queryTimeout": "02:00:00",
    "partitionOption": "None"
  },
  "dataset": {    
    "referenceName":if(GenerateArm=="false") 
                    then referenceName + GFPIR
                    else "[concat('"+referenceName+"', parameters('integrationRuntimeShortName'))]",   
    "type": "DatasetReference",
    "parameters": {
      "Schema": {
        "value": "NA",
        "type": "Expression"
      },
      "Table": {
        "value": "NA",
        "type": "Expression"
      },
      "Server": {
        "value": "@pipeline().parameters.TaskObject.Source.System.SystemServer",
        "type": "Expression"
      },
      "Database": {
        "value": "@pipeline().parameters.TaskObject.Source.System.Database",
        "type": "Expression"
      }
    }
  },
  "firstRowOnly": false
}