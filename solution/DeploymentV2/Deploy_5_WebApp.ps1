#----------------------------------------------------------------------------------------------------------------
#   Building & Deploy Web App
#----------------------------------------------------------------------------------------------------------------
if ($skipWebApp) {
    Write-Host "Skipping Building & Deploying Web Application"    
}
else {
    Write-Host "Building & Deploying Web Application"
    #Move From Workflows to Function App
    Set-Location $deploymentFolderPath
    Set-Location "../WebApplication"
    dotnet restore
    dotnet publish --no-restore --configuration Release --output '..\DeploymentV2\bin\publish\unzipped\webapplication\'
    #Move back to workflows 
    Set-Location $deploymentFolderPath
    Set-Location "./bin/publish"
    $Path = (Get-Location).Path + "/zipped/webapplication" 
    New-Item -ItemType Directory -Force -Path $Path
    $Path = $Path + "/Publish.zip"
    Compress-Archive -Path '.\unzipped\webapplication\*' -DestinationPath $Path -force

    $result = az webapp deployment source config-zip --resource-group $resource_group_name --name $webapp_name --src $Path
    if ($gitDeploy) 
    {
        if ($AddSpecificUserAsWebAppAdmin) {
            write-host "Adding Admin Role To WebApp for specific user"
            $authapp = (az ad app show --id $tout.aad_webreg_id) | ConvertFrom-Json
            $authappid = $authapp.appId
            $authappobjectid = (az ad sp show --id $authapp.appId | ConvertFrom-Json).id
            $body = '{"principalId": "@principalid","resourceId":"@resourceId","appRoleId": "@appRoleId"}' | ConvertFrom-Json
            $body.resourceId = $authappobjectid
            $body.appRoleId = ($authapp.appRoles | Where-Object {$_.value -eq "Administrator" }).id
            $body.principalId = $specificuser
            $body = ($body | ConvertTo-Json -compress | Out-String).Replace('"','\"')
    
            $result = az rest --method post --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$authappobjectid/appRoleAssignedTo" --headers '{\"Content-Type\":\"application/json\"}' --body $body
        }
    }
    else 
    {
        if ($AddCurrentUserAsWebAppAdmin) {                
            write-host "Adding Admin Role To WebApp"
            $authapp = (az ad app show --id $tout.aad_webreg_id) | ConvertFrom-Json
            $cu = az ad signed-in-user show | ConvertFrom-Json
            $callinguser = $cu.id
            $authappid = $authapp.appId
            $authappobjectid =  (az ad sp show --id $authapp.appId | ConvertFrom-Json).id
    
            $body = '{"principalId": "@principalid","resourceId":"@resourceId","appRoleId": "@appRoleId"}' | ConvertFrom-Json
            $body.resourceId = $authappobjectid
            $body.appRoleId =  ($authapp.appRoles | Where-Object {$_.value -eq "Administrator" }).id
            $body.principalId = $callinguser
            $body = ($body | ConvertTo-Json -compress | Out-String).Replace('"','\"')
    
            $result = az rest --method post --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$authappobjectid/appRoleAssignedTo" --headers '{\"Content-Type\":\"application/json\"}' --body $body
        }
    }

    Set-Location $deploymentFolderPath
}