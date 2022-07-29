param (
    [Parameter(Mandatory=$true)]
    [string]$user="",
    [Parameter(Mandatory=$true)]
    [string]$sqlserver_name="",
    [Parameter(Mandatory=$true)]
    [string]$database=""
)

$token=$(az account get-access-token --resource=https://database.windows.net --query accessToken --output tsv)

$sqlcommand = "
IF '$user' = 'sql_aad_admin'
BEGIN 
    GOTO ExitLabel
END


IF NOT EXISTS (SELECT *
FROM [sys].[database_principals]
WHERE [type] = N'E' AND [name] = N'$user') 
BEGIN
    CREATE USER [$user] FROM EXTERNAL PROVIDER;		
END
ALTER ROLE db_datareader ADD MEMBER [$user];
ALTER ROLE db_datawriter ADD MEMBER [$user];
GRANT EXECUTE ON SCHEMA::[dbo] TO [$user];


ExitLabel:
GO
"

write-host "Granting MSI Privileges on $database DB to $user"
Invoke-Sqlcmd -ServerInstance "$sqlserver_name.database.windows.net,1433" -Database $database -AccessToken $token -query $sqlcommand    