local Template_Azure_Storage_to_Azure_Storage = function(SourceType, SourceFormat, TargetType, TargetFormat)
{
        "Folder": "Azure-Storage-to-Azure-Storage",
        "GFPIR": "Azure",
        "SourceType": SourceType,
        "SourceFormat": SourceFormat,
        "TargetType": TargetType,
        "TargetFormat": TargetFormat,
        "TaskTypeId":-2,
        "Pipeline":"GPL_SparkNotebookExecution_Primary_Auto"
};



#Azure_Storage_to_Azure_Storage 
[   
    #Parquet to Delta

    Template_Azure_Storage_to_Azure_Storage("AzureBlobStorage","Parquet","AzureBlobStorage","Delta"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobFS","Parquet","AzureBlobFS","Delta"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobFS","Parquet","AzureBlobStorage","Delta"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobStorage","Parquet","AzureBlobFS","Delta")

    #Delta to Delta

    #Delta to Parquet


]