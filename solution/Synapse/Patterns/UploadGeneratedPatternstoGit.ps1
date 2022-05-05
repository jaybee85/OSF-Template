Import-Module .\GatherOutputsFromTerraform.psm1 -force
$tout = GatherOutputsFromTerraform

function RemoveRepetitiveChars ($string, $char) {
    $string = $string.Split($char).where{$_} -join $char
    return $string
}


$CurrentFolderPath = $PWD
$baseDirectory = "../../../.." 
$folderName = "TempRepo"
$Directory = "$($baseDirectory)/$($folderName)"
$Directory = RemoveRepetitiveChars -string $Directory -char "/"

if($tout.datafactory_name -eq "") {
    $tout.datafactory_name = Read-Host "Enter the name of the data factory"
}
if($tout.resource_group_name -eq "") {
    $tout.resource_group_name = Read-Host "Enter the name of the resource group"
}
if($tout.resource_group_id -eq "") {
    $tout.resource_group_id = Read-Host "Enter the id of the resource group"
}
if($tout.keyvault_name -eq "") {
    $tout.keyvault_name = Read-Host "Enter the name of the key vault"
}
if($tout.functionapp_name -eq "") {
    $tout.functionapp_name = Read-Host "Enter the name of the function app"
}


function UploadADFItem ($items, $directory, $subFolder) {
    
    if ($items.count -gt 0) {
        $items | Foreach-Object -Parallel {
            $_tout = $using:tout
            $_directory = $using:directory
            $_subFolder = $using:subFolder
            $guid = [guid]::NewGuid()
            $lsName = $_.BaseName 
            $fileName = $_.FullName
            $jsonobject = $_ | Get-Content | ConvertFrom-Json
            $name = $jsonobject.name

            $dir = "$($_directory)/$($_tout.synapse_git_repository_name)"
            if ($($_tout.synapse_git_repository_root_folder) -ne "") {
                $dir = $dir + "$($_tout.synapse_git_repository_root_folder)/"
            }
            $dir = $dir + "/" +  $_subFolder + "/" + $name + ".json"
            $dir = $dir.Split("/").where{$_} -join "/"

            #ParseOut the Name Attribute
            #Persist File Back
            $jsonobject | ConvertTo-Json  -Depth 100 | set-content $_

            #Make a copy of the file in the repo 
            Copy-Item -Path $fileName -Destination "$($dir)" -Force
            write-host ($lsName) -ForegroundColor Yellow -BackgroundColor DarkGreen
                        
            
        }
    }
}


#Set up Temp Repo space
New-Item -Path "$($baseDirectory)" -Name "$($folderName)" -ItemType "directory"
if($tout.synapse_git_integration_type -eq "devops") 
{
#https://dev.azure.com/microsoft/_git/lockBoxProject
#https://microsoft@dev.azure.com/microsoft/lockBoxProject/_git/lockBoxProject
#NOTE -> This may need to be changed to include tenant + owner (with if conditional)
$owner = $tout.synapse_git_repository_base_url | Select-String -Pattern "dev.azure.com/(.*?)/"
$owner = $owner.Matches.Groups[1].Value
$GitURL = "$($owner)@dev.azure.com/$($owner)/$($tout.synapse_git_devops_project_name)/_git/$($tout.synapse_git_repository_name)"
}
else 
{
#https://github.com/microsoft/azure-data-services-go-fast-codebase
$owner = $tout.synapse_git_repository_base_url | Select-String -Pattern "github.com/(.*?)/"
$owner = $owner.Matches.Groups[1].Value
$GitURL = "github.com/$($owner)/$($tout.synapse_git_repository_name)"


}
$GitURL = RemoveRepetitiveChars -string $GitURL -char "/"
$GitURL = "https://" + $GitURL


Write-Host $GitURL
Write-Host "$($Directory)/$($tout.synapse_git_repository_name)"
Write-Host "$($tout.synapse_git_repository_branch_name)"

#Clone Repo
$FolderPath = "$($Directory)/$($tout.synapse_git_repository_name)"
$FolderPath = RemoveRepetitiveChars -string $FolderPath -char "/"
git clone -b "$($tout.synapse_git_repository_branch_name)" "$($GitURL)" "$($FolderPath)" 
$FolderPath = "$($FolderPath)/$($tout.synapse_git_repository_root_folder)/"
$FolderPath = RemoveRepetitiveChars -string $FolderPath -char "/"

#Check for Folders / Create
if (Test-Path -Path "$FolderPath") {
    "Root folder exists, skipping."
} else {
    Write-Host "Creating Root folder in repo"
    New-Item -Path $FolderPath -Name "pipeline" -ItemType "directory"
}

if (Test-Path -Path "$FolderPath/pipeline") {
    "pipeline folder exists, skipping."
} else {
    Write-Host "Creating pipeline folder in repo"
    New-Item -Path $FolderPath -Name "pipeline" -ItemType "directory"
}

if (Test-Path -Path "$FolderPath/notebook") {
    "notebook folder exists, skipping."
} else {
    Write-Host "Creating notebook folder in repo"
    New-Item -Path $FolderPath -Name "notebook" -ItemType "directory"
}

if (Test-Path -Path "$FolderPath/linkedService") {
    "linkedService folder exists, skipping."
} else {
    Write-Host "Creating linkedService folder in repo"
    New-Item -Path $FolderPath -Name "linkedService" -ItemType "directory"
}

if (Test-Path -Path "$FolderPath/integrationRuntime") {
    "integrationRuntime folder exists, skipping."
} else {
    Write-Host "Creating integrationRuntime folder in repo"
    New-Item -Path $FolderPath -Name "integrationRuntime" -ItemType "directory"
}

if (Test-Path -Path "$FolderPath/managedVirtualNetwork") {
    "managedVirtualNetwork folder exists, skipping."
} else {
    Write-Host "Creating managedVirtualNetwork folder in repo"
    New-Item -Path $FolderPath -Name "managedVirtualNetwork" -ItemType "directory"
}


#Move Items into rep
Write-Host "_____________________________"
Write-Host "Copying Pipelines to Temporary Repo /pipeline folder"
Write-Host "_____________________________"
$subFolder = "pipeline/"
$items = (Get-ChildItem -Path "./output/" -Include ("SPL_*.json", "GPL0_*.json","GPL1_*.json", "GPL2_*.json", "GPL-1_*.json", "GPL_*.json")  -Verbose -recurse)
UploadADFItem -items $items -directory $Directory -subFolder $subFolder

Write-Host "_____________________________"
Write-Host "Copying Notebooks to Temporary Repo /notebook folder"
Write-Host "_____________________________"
$subFolder = "notebook/"
$items = (Get-ChildItem -Path "./output/" -Include ("NB_*.json")  -Verbose -recurse)
UploadADFItem -items $items -directory $Directory -subFolder $subFolder

Write-Host "_____________________________"
Write-Host "Copying Integration Runtimes to Temporary Repo /integrationRuntime folder"
Write-Host "_____________________________"
$subFolder = "integrationRuntime/" 
$items = (Get-ChildItem -Path "./output/" -Include ("IR_*.json")  -Verbose -recurse)
write-host $items
UploadADFItem -items $items -directory $Directory -subFolder $subFolder

Write-Host "_____________________________"
Write-Host "Copying Linked Services to Temporary Repo /linkedService folder"
Write-Host "_____________________________"
$subFolder = "linkedService/" 
$items = (Get-ChildItem -Path "./output/" -Include ("LS_*.json")  -Verbose -recurse)
UploadADFItem -items $items -directory $Directory -subFolder $subFolder

#Commit and remove
Set-Location "$($Directory)/$($tout.synapse_git_repository_name)"
git add .
git commit -m "deployment commit"
git push origin $($tout.synapse_git_repository_branch_name)
Set-Location $CurrentFolderPath
Remove-Item $Directory -Recurse -Force
