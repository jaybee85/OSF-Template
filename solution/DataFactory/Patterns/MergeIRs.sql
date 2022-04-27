            Merge dbo.IntegrationRuntime Tgt
            using (
            Select * from OPENJSON('[
  {
    "is_azure": true,
    "is_managed_vnet": true,
    "name": "Azure-Integration-Runtime",
    "short_name": "Azure",
    "valid_pipeline_patterns": [
      {
        "Folder": "*",
        "SourceFormat": "*",
        "SourceType": "*",
        "TargetFormat": "*",
        "TargetType": "*",
        "TaskTypeId": "*"
      }
    ],
    "valid_source_systems": [
      "*"
    ]
  },
  {
    "is_azure": false,
    "is_managed_vnet": false,
    "name": "Onprem-Integration-Runtime",
    "short_name": "OnPrem",
    "valid_pipeline_patterns": [
      {
        "Folder": "Azure-Storage-to-Azure-Storage",
        "SourceFormat": "*",
        "SourceType": "*",
        "TargetFormat": "*",
        "TargetType": "*",
        "TaskTypeId": "*"
      },
      {
        "Folder": "Execute-SQL-Statement",
        "SourceFormat": "*",
        "SourceType": "*",
        "TargetFormat": "*",
        "TargetType": "*",
        "TaskTypeId": "*"
      },
      {
        "Folder": "SQL-Database-to-Azure-Storage",
        "SourceFormat": "*",
        "SourceType": "*",
        "TargetFormat": "*",
        "TargetType": "*",
        "TaskTypeId": "*"
      },
      {
        "Folder": "SQL-Database-to-Azure-Storage-CDC",
        "SourceFormat": "*",
        "SourceType": "*",
        "TargetFormat": "*",
        "TargetType": "*",
        "TaskTypeId": "*"
      }
    ],
    "valid_source_systems": [
      "-14",
      "-15",
      "-9"
    ]
  }
]') WITH 
            (
                name varchar(200), 
                short_name varchar(20), 
                is_azure bit, 
                is_managed_vnet bit     
            )
            ) Src on Src.short_name = tgt.IntegrationRuntimeName 
            when NOT matched by TARGET then insert
            (IntegrationRuntimeName, EngineId, ActiveYN)
            VALUES (Src.short_name,1,1);
