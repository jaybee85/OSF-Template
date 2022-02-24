Update SourceAndTargetSystems
Set SystemJson =      '         "Database" : "msdb"  , "Username" : "adminuser", "PasswordKeyVaultSecretName":"selfhostedsqlpw"   }',
	SystemKeyVaultBaseUrl = 'https://$KeyVaultName$.vault.azure.net/',
	SystemServer = '(local)'
where Systemid = 14 