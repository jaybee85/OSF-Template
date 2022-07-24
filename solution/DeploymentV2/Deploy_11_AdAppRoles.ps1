


#----------------------------------------------------------------------------------------------------------------
#   Web App Admin User
#----------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------
if ($gitDeploy -or $null -eq (az ad signed-in-user show) ) 
{
    if ($null -ne [System.Environment]::GetEnvironmentVariable('WEB_APP_ADMIN_USER') -and [System.Environment]::GetEnvironmentVariable('WEB_APP_ADMIN_USER') -ne "") {
        write-host "Adding Admin Role To WebApp for specific user"
        $authapp = (az ad app show --id $tout.aad_webreg_id) | ConvertFrom-Json
        $authappid = $authapp.appId
        $authappobjectid = (az ad sp show --id $authapp.appId | ConvertFrom-Json).id
        $body = '{"principalId": "@principalid","resourceId":"@resourceId","appRoleId": "@appRoleId"}' | ConvertFrom-Json
        $body.resourceId = $authappobjectid
        $body.appRoleId = ($authapp.appRoles | Where-Object {$_.value -eq "Administrator" }).id
        $body.principalId = [System.Environment]::GetEnvironmentVariable('WEB_APP_ADMIN_USER')
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