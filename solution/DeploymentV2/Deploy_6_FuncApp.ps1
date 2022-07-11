
#----------------------------------------------------------------------------------------------------------------
#   Building & Deploy Function App
#----------------------------------------------------------------------------------------------------------------
if ($skipFunctionApp) {
    Write-Host "Skipping Building & Deploying Function Application"    
}
else {
    Write-Host "Building & Deploying Function Application"
    Set-Location $deploymentFolderPath
    Set-Location "..\FunctionApp\FunctionApp"
    dotnet restore
    dotnet publish --no-restore --configuration Release --output '..\..\DeploymentV2\bin\publish\unzipped\functionapp\'
    
    Set-Location $deploymentFolderPath
    Set-Location "./bin/publish"
    $Path = (Get-Location).Path + "/zipped/functionapp" 
    New-Item -ItemType Directory -Force -Path $Path
    $Path = $Path + "/Publish.zip"
    Compress-Archive -Path '.\unzipped\functionapp\*' -DestinationPath $Path -force
    
    $result = az functionapp deployment source config-zip --resource-group $resource_group_name --name $functionapp_name --src $Path

    #Make sure we are running V6.0 --TODO: Move this to terraform if possible -- This is now done!
    $result = az functionapp config set --net-framework-version v6.0 -n $functionapp_name -g $resource_group_name
    $result = az functionapp config appsettings set --name $functionapp_name --resource-group $resource_group_name --settings FUNCTIONS_EXTENSION_VERSION=~4

    Set-Location $deploymentFolderPath
}
