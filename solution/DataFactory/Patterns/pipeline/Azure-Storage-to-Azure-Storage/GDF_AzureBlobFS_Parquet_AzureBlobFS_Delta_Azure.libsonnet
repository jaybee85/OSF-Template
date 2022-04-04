{
    "name": "GDF_AzureBlobFS_Parquet_AzureBlobFS_Parquet_Azure",
    "properties": {
        "type": "MappingDataFlow",
        "typeProperties": {
            "sources": [
                {
                    "dataset": {
                        "referenceName": "GDS_AzureBlobFS_Parquet_Azure",
                        "type": "DatasetReference"
                    },
                    "name": "source1"
                }
            ],
            "sinks": [
                {
                    "linkedService": {
                        "referenceName": "GLS_AzureBlobFS_Azure",
                        "type": "LinkedServiceReference"
                    },
                    "name": "sink1"
                }
            ],
            "transformations": [],
            "scriptLines": [
                "parameters{",
                "     TargetContainer as string ('datalakeraw'),",
                "     TargetFolderPath as string ('deltatest')",
                "}",
                "source(allowSchemaDrift: true,",
                "     validateSchema: false,",
                "     ignoreNoFilesFound: false,",
                "     format: 'parquet') ~> source1",
                "source1 sink(allowSchemaDrift: true,",
                "     validateSchema: false,",
                "     format: 'delta',",
                "     compressionType: 'gzip',",
                "     compressionLevel: 'Fastest',",
                "     fileSystem: ($TargetContainer),",
                "     folderPath: ($TargetFolderPath),",
                "     mergeSchema: false,",
                "     autoCompact: false,",
                "     optimizedWrite: false,",
                "     vacuum: 0,",
                "     deletable:false,",
                "     insertable:true,",
                "     updateable:false,",
                "     upsertable:false,",
                "     umask: 0022,",
                "     preCommands: [],",
                "     postCommands: [],",
                "     skipDuplicateMapInputs: true,",
                "     skipDuplicateMapOutputs: true) ~> sink1"
            ]
        }
    }
}