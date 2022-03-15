local Template_Azure_Storage_to_Azure_Storage = function(SourceType, SourceFormat, TargetType, TargetFormat)
{
        "Folder": "Azure-Storage-to-Azure-Storage",
        "GFPIR": "Azure",
        "SourceType": SourceType,
        "SourceFormat": SourceFormat,
        "TargetType": TargetType,
        "TargetFormat": TargetFormat,
        "TaskTypeId":-2,
        "Pipeline":"GPL_SparkNotebookExecution_Primary"
};

local Template_Execute_Notebook = function(SourceType, SourceFormat, TargetType, TargetFormat)
{
        "Folder": "Execute-Notebook",
        "GFPIR": "Azure",
        "SourceType": SourceType,
        "SourceFormat": SourceFormat,
        "TargetType": TargetType,
        "TargetFormat": TargetFormat,
        "TaskTypeId":-5,
        "Pipeline":"GPL_SparkNotebookExecution_Primary"
};




#Azure_Storage_to_Azure_Storage 
[   
    #Parquet to Delta

    Template_Azure_Storage_to_Azure_Storage("AzureBlobStorage","Parquet","AzureBlobStorage","Delta"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobStorage","Parquet","AzureBlobFS","Delta"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobFS","Parquet","AzureBlobFS","Delta"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobFS","Parquet","AzureBlobStorage","Delta"),



    #Delta to Delta

    Template_Azure_Storage_to_Azure_Storage("AzureBlobStorage","Delta","AzureBlobStorage","Delta"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobStorage","Delta","AzureBlobFS","Delta"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobFS","Delta","AzureBlobFS","Delta"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobFS","Delta","AzureBlobStorage","Delta"),

    #Delta to Parquet


    Template_Azure_Storage_to_Azure_Storage("AzureBlobStorage","Delta","AzureBlobStorage","Parquet"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobStorage","Delta","AzureBlobFS","Parquet"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobFS","Delta","AzureBlobFS","Parquet"),

    Template_Azure_Storage_to_Azure_Storage("AzureBlobFS","Delta","AzureBlobStorage","Parquet")

]
+
#Execute Notebook 
[
    Template_Execute_Notebook("N/A","Notebook-Optional","N/A","Notebook-Optional")

]