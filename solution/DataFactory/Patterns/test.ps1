Import-Module .\GatherOutputsFromTerraform.psm1 -force
$tout = GatherOutputsFromTerraform
$newfolder = "./output/"

if (!(Test-Path "./output"))
{
    New-Item -itemType Directory -Name "output"
}
else
{
    Write-Information "Output Folder already exists"
}

#Remove Previous Outputs
Get-ChildItem ./output | foreach {
    Remove-item $_ -force
}
#create tout json to be used for git integration
$toutjson = $tout | ConvertTo-Json -Depth 10 | Set-Content($newfolder + "tout.json")


if($($tout.adf_git_toggle_integration)) {
    #LINKED SERVICES
    $folder = "./linkedService/"
    Write-Host "_____________________________"
    Write-Host "Generating ADF linked services for Git Integration: " 
    Write-Host "_____________________________"
    #GLS
    $files = (Get-ChildItem -Path $folder -Filter "GLS*" -Verbose)
    foreach ($ir in $tout.integration_runtimes)
    {    
        $shortName = $ir.short_name
        $fullName = $ir.name
        foreach ($file in $files){
            $schemafiletemplate = (Get-ChildItem -Path ($folder) -Filter "$($file.PSChildName)"  -Verbose)
            $newName = ($file.PSChildName).Replace(".libsonnet",".json")
            $newName = "LS_" + $newName
            $newName = $newname.Replace("(IRName)", $shortName)
            (jsonnet --tla-str shortIRName="$shortName" --tla-str fullIRName="$fullName" $schemafiletemplate | Set-Content($newfolder + $newName))
        }
    }
    #SLS
    $files = (Get-ChildItem -Path $folder -Filter "SLS*" -Verbose)
    foreach ($file in $files){
        $schemafiletemplate = (Get-ChildItem -Path ($folder) -Filter "$($file.PSChildName)"  -Verbose)
        $newName = ($file.PSChildName).Replace(".libsonnet",".json")
        $newName = "LS_" + $newName
        (jsonnet $schemafiletemplate | Set-Content($newfolder + $newName))
    }
    #DATASETS
    $folder = "./dataset/"
    Write-Host "_____________________________"
    Write-Host "Generating ADF datasets for Git Integration: " 
    Write-Host "_____________________________"
    #GDS
    $files = (Get-ChildItem -Path $folder -Filter "GDS*" -Verbose)
    foreach ($ir in $tout.integration_runtimes)
    {    
        $shortName = $ir.short_name
        $fullName = $ir.name
        foreach ($file in $files){
            $schemafiletemplate = (Get-ChildItem -Path ($folder) -Filter "$($file.PSChildName)"  -Verbose)
            $newName = ($file.PSChildName).Replace(".libsonnet",".json")
            $newName = $newname.Replace("(IRName)", $shortName)
            (jsonnet --tla-str shortIRName="$shortName" --tla-str fullIRName="$fullName" $schemafiletemplate | Set-Content($newfolder + $newName))
        }
    }

    #MANAGED VIRTUAL NETWORK

    $folder = "./managedVirtualNetwork/"
    $files = (Get-ChildItem -Path $folder -Filter "*.libsonnet" -Verbose)
    Write-Host "_____________________________"
    Write-Host "Generating ADF managed virtual networks for Git Integration: " 
    Write-Host "_____________________________"
    foreach ($file in $files)
    {
        $schemafiletemplate = (Get-ChildItem -Path ($folder) -Filter "$($file.PSChildName)"  -Verbose)
        $newName = ($file.PSChildName).Replace(".libsonnet",".json")
        $newName = "MVN_" + $newName
        (jsonnet $schemafiletemplate | Set-Content($newfolder + $newName))
    }

    #managedPrivateEndpoint/default folder within MANAGED VIRTUAL NETWORK
    $folder = "./managedVirtualNetwork/default/managedPrivateEndpoint"
    #if our vnet isolation isnt on, we only want the standard files
    if ($tout.is_vnet_isolated) {
        $files = (Get-ChildItem -Path $folder -Filter *is_vnet_isolated*)
        Write-Host "_____________________________"
        Write-Host "Generating ADF managed private endpoints for Git Integration: " 
        Write-Host "_____________________________"
        foreach ($file in $files)
        {
            $schemafiletemplate = (Get-ChildItem -Path ($folder) -Filter "$($file.PSChildName)"  -Verbose)
            $newName = ($file.PSChildName).Replace(".libsonnet",".json")
            $newName = "MVN_default-managedPrivateEndpoint_" + $newName
            $newName = $newname.Replace("[is_vnet_isolated]", "")

            (jsonnet $schemafiletemplate | Set-Content($newfolder + $newName))
        }
    }

    #INTEGRATION RUNTIMES
    $folder = "./integrationRuntime/"
    Write-Host "_____________________________"
    Write-Host "Generating ADF integration runtimes for Git Integration: " 
    Write-Host "_____________________________"
    #IR
    foreach ($ir in $tout.integration_runtimes)
    {    
        $shortName = $ir.short_name
        $fullName = $ir.name
        if($ir.is_azure)
        {
            $files = (Get-ChildItem -Path $folder -Filter *is_azure*)
            foreach ($file in $files)
            {
                $schemafiletemplate = (Get-ChildItem -Path ($folder) -Filter "$($file.PSChildName)"  -Verbose)
                $newName = ($file.PSChildName).Replace(".libsonnet",".json")
                $newName = $newName.Replace("[is_azure]", "")
                $newName = $newName.Replace("(IRName)", $shortName)
                $newName = "IR_" + $newName
                (jsonnet --tla-str fullIRName="$fullName" $schemafiletemplate | Set-Content($newfolder + $newName))
            }
        }
        else
        { 
            $files = (Get-ChildItem -Path $folder -Exclude *is_azure*)
            foreach ($file in $files)
            {
                $schemafiletemplate = (Get-ChildItem -Path ($folder) -Filter "$($file.PSChildName)"  -Verbose)
                $newName = ($file.PSChildName).Replace(".libsonnet",".json")
                $newName = $newName.Replace("(IRName)", $shortName)
                $newName = "IR_" + $newName
                (jsonnet --tla-str fullIRName="$fullName" $schemafiletemplate | Set-Content($newfolder + $newName))
            }
        }

    }
    $folder = "./factory/"
    Write-Host "_____________________________"
    Write-Host "Generating ADF factories for Git Integration: " 
    Write-Host "_____________________________"
    #FA
    $files = (Get-ChildItem -Path $folder -Filter "*.libsonnet" -Verbose)
    foreach ($file in $files){
        $schemafiletemplate = (Get-ChildItem -Path ($folder) -Filter "$($file.PSChildName)"  -Verbose)
        $newName = ($file.PSChildName).Replace(".libsonnet",".json")
        $newName = $newName.Replace("(DatafactoryName)", $($tout.datafactory_name))
        $newName = "FA_" + $newName
        (jsonnet $schemafiletemplate | Set-Content($newfolder + $newName))
    }

    #REPLACING PRINCIPALID grabbed from az datafactory
    #REASON: PRINCIPALID Contains a GUID on these files that I cannot identify where it is retrieved from otherwise

    $files = (Get-ChildItem -Path $newFolder -Filter FA*)
    foreach ($file in $files)
    {
        $fileSysObj = Get-Content $file -raw | ConvertFrom-Json
        $fileAZ = az datafactory show --name $fileSysObj.name --resource-group $($tout.resource_group_name)
        $fileAZ = $fileAZ | ConvertFrom-Json
        $fileSysObj.identity.principalId = $fileAZ.identity.principalId
        $fileSysObj | ConvertTo-Json -depth 32| Set-Content($($newfolder) + $($file.PSChildName))
    }
   
}


