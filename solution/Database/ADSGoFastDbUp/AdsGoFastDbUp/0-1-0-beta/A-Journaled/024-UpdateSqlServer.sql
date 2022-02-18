Update SourceAndTargetSystems
Set SystemJson =      '         "Database" : "msdb"  , "Username" : "adminuser", "PasswordKeyVaultSecretName":"selfhostedsqlpw"   }',
	SystemKeyVaultUrl = 'https://$KeyVaultName$.vault.azure.net/',
	SystemServer = '(local)'
where Systemid = 14 