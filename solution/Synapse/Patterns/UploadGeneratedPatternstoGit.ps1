Import-Module .\GatherOutputsFromTerraform.psm1 -force
$tout = GatherOutputsFromTerraform
$CurrentFolderPath = $PWD
$baseDirectory = "../../../.." 
$folderName = "TempRepo"
$Directory = "$($baseDirectory)/$($folderName)"


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
            $dir = "$($_directory)/$($_tout.synapse_git_repository_name)"
            if ($($_tout.synapse_git_repository_root_folder) -ne "") {
                $dir = $dir + "$($_tout.synapse_git_repository_root_folder)/"
            }
            $dir = $dir + $_subFolder
            
            #ParseOut the Name Attribute
            $name = $jsonobject.name
            #Persist File Back
            $jsonobject | ConvertTo-Json  -Depth 100 | set-content $_

            #Make a copy of the file in the repo 
            Copy-Item -Path $fileName -Destination "$($dir)$($name).json" -Force
            write-host ($lsName) -ForegroundColor Yellow -BackgroundColor DarkGreen
                        
            
        }
    }
}


$UploadGDS = $false
$UploadGLS = $false

if($UploadGLS -eq $true)
{
    $items = (Get-ChildItem -Path "./output/" -Include "GLS*.json" -Verbose -recurse)
    UploadADFItem -items $items 
    $items = (Get-ChildItem -Path "./output/" -Include "SLS*.json" -Verbose -recurse)
    UploadADFItem -items $items 
}

if($UploadGDS -eq $true)
{
    $items = (Get-ChildItem -Path "./output/" -Include "GDS*.json" -Verbose -recurse)
    UploadADFItem -items $items
}
$GitURL = "https://github.com/" + $($tout.synapse_git_account_name) + "/" + $($tout.synapse_git_repository_name)
Write-Host $GitURL
Write-Host "$($Directory)/$($tout.synapse_git_repository_name)"
Write-Host "$($tout.synapse_git_repository_branch_name)"

#Set up Repo space
New-Item -Path "$($baseDirectory)" -Name "$($folderName)" -ItemType "directory"

#Clone Repo
git clone -b "$($tout.synapse_git_repository_branch_name)" "$($GitURL)" "$($Directory)/$($tout.synapse_git_repository_name)" 

#Check for Folders / Create
$FolderPath = "$($Directory)/$($tout.synapse_git_repository_name)$($tout.synapse_git_repository_root_folder)/"
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
$subFolder = "./integrationRuntime" 
$items = (Get-ChildItem -Path "./output/" -Include ("IR_*.json")  -Verbose -recurse)
write-host $items
UploadADFItem -items $items -directory $Directory -subFolder $subFolder

Write-Host "_____________________________"
Write-Host "Copying Linked Services to Temporary Repo /linkedService folder"
Write-Host "_____________________________"
$subFolder = "./linkedService/" 
$items = (Get-ChildItem -Path "./output/" -Include ("LS_*.json")  -Verbose -recurse)
UploadADFItem -items $items -directory $Directory -subFolder $subFolder

#Commit and remove
Set-Location "$($Directory)/$($tout.synapse_git_repository_name)"
git add .
git commit -m "deployment commit"
git push origin $($tout.synapse_git_repository_branch_name)
Set-Location $CurrentFolderPath
Remove-Item $Directory -Recurse -Force
