function()
{
    "type": "object",
    "properties": {
        "Type": {
            "type": "string",
            "enum": [
                "Binary"
            ],
            "options": {
                "hidden": true
            }
        },
        "RelativePath": {
            "type": "string",
            "description": "Path of the file to be copied. You can use pattern match characters eg. *. See https://docs.microsoft.com/en-us/azure/data-factory/connector-azure-blob-storage?tabs=data-factory#blob-storage-as-a-source-type",
            "options": {
                "inputAttributes": {
                    "placeholder": "eg. AwSample/dbo/Customer/{yyyy}/{MM}/{dd}/{hh}/"
                },
                "infoText": "Path of the file to be copied. You can use pattern match characters eg. *. See https://docs.microsoft.com/en-us/azure/data-factory/connector-azure-blob-storage?tabs=data-factory#blob-storage-as-a-source-type"
            }
        },
        "DataFileName": {
            "type": "string",
            "description": "Name of the file to be copied. You can use pattern match characters eg. *. See https://docs.microsoft.com/en-us/azure/data-factory/connector-azure-blob-storage?tabs=data-factory#blob-storage-as-a-source-type",
            "options": {
                "inputAttributes": {
                    "placeholder": "eg. *.parquet"
                },
                "infoText": "Name of the file to be copied. You can use pattern match characters eg. *. See https://docs.microsoft.com/en-us/azure/data-factory/connector-azure-blob-storage?tabs=data-factory#blob-storage-as-a-source-type"
            }
        },
        "Recursively": {
            "type": "string",
            "enum": [
                "true",
                "false"
            ],
            "default": "true",
            "options": {
                "infoText": "Set to true if you want the framework to copy files from subfolders."
            }
        },
        "DeleteAfterCompletion": {
            "type": "string",
            "enum": [
                "true",
                "false"
            ],
            "default": "true",
            "options": {
                "infoText": "Set to true if you want the framework to remove the source file after a successsful copy."
            }
        }
    },
    "required": [
        "Type",
        "RelativePath",
        "DataFileName",
        "Recursively",
        "MaxConcorrentConnections",
        "DeleteAfterCompletion"
    ]
}
