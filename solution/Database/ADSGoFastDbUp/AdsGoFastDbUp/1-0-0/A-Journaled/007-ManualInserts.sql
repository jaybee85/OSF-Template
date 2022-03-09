UPDATE [dbo].[ExecutionEngine]
SET EngineName = '$DataFactoryName$'
	,SystemType = 'Datafactory'
	,ResourceGroup = '$ResourceGroupName$'
	,SubscriptionUid = '$SubscriptionId$'
	,DefaultKeyVaultURL = 'https://$KeyVaultName$.vault.azure.net/'
	,LogAnalyticsWorkspaceId = '$LogAnalyticsWorkspaceId$'
	,EngineJson = '{}'
WHERE EngineId = '-1'
GO

UPDATE [dbo].[ExecutionEngine]
SET EngineName = '$SynapseWorkspaceName$'
	,SystemType = 'Synapse'
	,ResourceGroup = '$ResourceGroupName$'
	,SubscriptionUid = '$SubscriptionId$'
	,DefaultKeyVaultURL = 'https://$KeyVaultName$.vault.azure.net/'
	,LogAnalyticsWorkspaceId = '$LogAnalyticsWorkspaceId$'
	,EngineJson = '{
            "endpoint": "https://$SynapseWorkspaceName$.dev.azuresynapse.net"
        }'
WHERE EngineId = '-2'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = '$SqlServerName$.database.windows.net'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
	,SystemJSON = '{ "Database" : "$SampleDatabaseName$" }'
WHERE SystemId = '-1'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = '$SqlServerName$.database.windows.net'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
	,SystemJSON = '{ "Database" : "$StagingDatabaseName$" }'
WHERE SystemId = '-2'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = '$SqlServerName$.database.windows.net'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
	,SystemJSON = '{ "Database" : "$MetadataDatabaseName$" }'
WHERE SystemId = '-11'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = 'https://$BlobStorageName$.blob.core.windows.net'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
	,SystemJSON = '{ "Container" : "datalakeraw" }'
WHERE SystemId = '-3'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = 'https://$BlobStorageName$.blob.core.windows.net'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
	,SystemJSON = '{ "Container" : "datalakelanding" }'
WHERE SystemId = '-7'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = 'https://$BlobStorageName$.blob.core.windows.net'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
	,SystemJSON = '{ "Container" : "transientin" }'
WHERE SystemId = '-9'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = 'https://$AdlsStorageName$.dfs.core.windows.net'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
	,SystemJSON = '{ "Container" : "datalakeraw" }'
WHERE SystemId = '-4'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = 'https://$AdlsStorageName$.dfs.core.windows.net'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
	,SystemJSON = '{ "Container" : "datalakelanding" }'
WHERE SystemId = '-8'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = 'https://$AdlsStorageName$.dfs.core.windows.net'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
	,SystemJSON = '{  "Database" : "msdb"  , "Username" : "adminuser", "PasswordKeyVaultSecretName":"selfhostedsqlpw"   }'
WHERE SystemId = '-14'
GO

UPDATE [dbo].[SourceAndTargetSystems]
SET SystemServer = '(local)'
	,SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
WHERE SystemId = '-15'
GO
