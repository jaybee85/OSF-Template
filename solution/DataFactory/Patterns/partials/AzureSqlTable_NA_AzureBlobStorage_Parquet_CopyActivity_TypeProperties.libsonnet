function(GFPIR="IRA") {
  "source": {
    "type": "AzureSqlSource",
    "sqlReaderQuery": {
      "value": "@variables('SQLStatement')",
      "type": "Expression"
    },
    "queryTimeout": "02:00:00"
  },
  "sink": {
    "type": "ParquetSink",
    "storeSettings": {
      "type": "AzureBlobStorageWriteSettings"
    }
  },
  "enableStaging": false,
  "parallelCopies": {
    "value": "@pipeline().parameters.TaskObject.DegreeOfCopyParallelism",
    "type": "Expression"
  },
  "translator": {
    "value": "@pipeline().parameters.Mapping",
    "type": "Expression"
  }
}

