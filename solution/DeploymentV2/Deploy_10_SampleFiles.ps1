


#----------------------------------------------------------------------------------------------------------------
#   Deploy Sample Files
#----------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------
if($skipSampleFiles) {
    Write-Host "Skipping Sample Files"    
}
else 
{
    Set-Location $deploymentFolderPath
    Set-Location "../SampleFiles/"
    Write-Host "Deploying Sample files"
    if ($tout.is_vnet_isolated -eq $true)
    {
        $result = az storage account update --resource-group $resource_group_name --name $adlsstorage_name --default-action Allow
    }

    $result = az storage container create --name "datalakelanding" --account-name $adlsstorage_name --auth-mode login
    $result = az storage container create --name "datalakeraw" --account-name $adlsstorage_name --auth-mode login
    $result = az storage container create --name "datalakeraw" --account-name $blobstorage_name --auth-mode login
    $result = az storage container create --name "transientin" --account-name $blobstorage_name --auth-mode login

    $result = az storage blob upload-batch --overwrite --destination "datalakeraw" --account-name $adlsstorage_name --source ./ --destination-path samples/ --auth-mode login
    $result = az storage blob upload-batch --overwrite --destination "datalakeraw" --account-name $blobstorage_name --source ./ --destination-path samples/ --auth-mode login

    if ($tout.is_vnet_isolated -eq $true)
    {
        $result = az storage account update --resource-group $resource_group_name --name $adlsstorage_name --default-action Deny
    }

    Set-Location $deploymentFolderPath

}