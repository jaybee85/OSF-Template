Update [dbo].[ExecutionEngine]
            Set 
			[EngineName] = '$DataFactoryName$', 
            [SystemType] = 'Datafactory',
			ResourceGroup = '$ResourceGroupName$',
            SubscriptionUid = '$SubscriptionId$',
            DefaultKeyVaultURL = 'https://$KeyVaultName$.vault.azure.net/', 
            LogAnalyticsWorkspaceId = '$LogAnalyticsWorkspaceId$',
            EngineJson = '{}'
        where EngineId = -1

Update [dbo].[ExecutionEngine]
            Set 
			[EngineName] = '$SynapseWorkspaceName$', 
			[SystemType] = 'Datafactory',
            ResourceGroup = '$ResourceGroupName$',
            SubscriptionUid = '$SubscriptionId$',
            DefaultKeyVaultURL = 'https://$KeyVaultName$.vault.azure.net/', 
            LogAnalyticsWorkspaceId = '$LogAnalyticsWorkspaceId$',
            EngineJson = '{
                "endpoint": "placeholderendpoint"
            }'
        where EngineId = -2


Update 
        [dbo].[SourceAndTargetSystems]
        Set 
            SystemServer = '$SqlServerName$.database.windows.net',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
            SystemJSON = '{ "Database" : "$SampleDatabaseName$" }'
        Where 
            SystemId = '-1'
        GO

        Update 
        [dbo].[SourceAndTargetSystems]
        Set 
            SystemServer = '$SqlServerName$.database.windows.net',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
            SystemJSON = '{ "Database" : "$StagingDatabaseName$" }'
        Where 
            SystemId = '-2'
        GO

        Update 
        [dbo].[SourceAndTargetSystems]
        Set 
            SystemServer = '$SqlServerName$.database.windows.net',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
            SystemJSON = '{ "Database" : "$MetadataDatabaseName$" }'
        Where 
            SystemId = '-11'
        GO


        Update 
        [dbo].[SourceAndTargetSystems]
        Set 
            SystemServer = 'https://$BlobStorageName$.blob.core.windows.net',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
            SystemJSON = '{ "Container" : "datalakeraw" }'
        Where 
            SystemId = '-3'
        GO

        Update 
        [dbo].[SourceAndTargetSystems]
        Set 
            SystemServer = 'https://$BlobStorageName$.blob.core.windows.net',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
            SystemJSON = '{ "Container" : "datalakelanding" }'
        Where 
            SystemId = '-7'
        GO

        Update 
        [dbo].[SourceAndTargetSystems]
        Set 
            SystemServer = 'https://$BlobStorageName$.blob.core.windows.net',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
            SystemJSON = '{ "Container" : "transientin" }'
        Where 
            SystemId = '-9'
        GO

        Update 
        [dbo].[SourceAndTargetSystems]
        Set 
            SystemServer = 'https://$AdlsStorageName$.dfs.core.windows.net',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
            SystemJSON = '{ "Container" : "datalakeraw" }'
        Where 
            SystemId = '-4'
        GO

        Update 
        [dbo].[SourceAndTargetSystems]
        Set 
        SystemServer = 'https://$AdlsStorageName$.dfs.core.windows.net',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
            SystemJSON = '{ "Container" : "datalakelanding" }'
        Where 
            SystemId = '-8'
        GO

        Update 
        [dbo].[SourceAndTargetSystems]
        Set 
            SystemServer = 'https://$AdlsStorageName$.dfs.core.windows.net',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
            SystemJSON = '{  "Database" : "msdb"  , "Username" : "adminuser", "PasswordKeyVaultSecretName":"selfhostedsqlpw"   }'
        Where 
            SystemId = '-14'
        GO

        Update 
        [dbo].[SourceAndTargetSystems]
        Set 
            SystemServer = '(local)',
            SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/'
        Where 
            SystemId = '-15'
        GO

