
if ($skipNetworking -or $tout.is_vnet_isolated -eq $false) {
    Write-Host "Skipping Private Link Connnections"    
}
else {
    #------------------------------------------------------------------------------------------------------------
    # Approve the Private Link Connections that get generated from the Managed Private Links in ADF
    #------------------------------------------------------------------------------------------------------------
    Write-Host "Approving Private Link Connections"
    $links = az network private-endpoint-connection list -g $resource_group_name -n $keyvault_name --type 'Microsoft.KeyVault/vaults' |  ConvertFrom-Json
    foreach($link in $links){
        if($link.properties.privateLinkServiceConnectionState.status -eq  "Pending"){
            $id_parts = $link.id.Split("/");
            Write-Host "- " + $id_parts[$id_parts.length-1]
            $result = az network private-endpoint-connection approve -g $resource_group_name -n $id_parts[$id_parts.length-1] --resource-name $keyvault_name --type Microsoft.Keyvault/vaults --description "Approved by Deploy.ps1"
        }
    }
    $links = az network private-endpoint-connection list -g $resource_group_name -n $sqlserver_name --type 'Microsoft.Sql/servers' |  ConvertFrom-Json
    foreach($link in $links){
        if($link.properties.privateLinkServiceConnectionState.status -eq  "Pending"){
            $id_parts = $link.id.Split("/");
            Write-Host "- " + $id_parts[$id_parts.length-1]
            $result = az network private-endpoint-connection approve -g $resource_group_name -n $id_parts[$id_parts.length-1] --resource-name $sqlserver_name --type Microsoft.Sql/servers --description "Approved by Deploy.ps1"
        }
    }
    
    $links = az network private-endpoint-connection list -g $resource_group_name -n $synapse_workspace_name --type 'Microsoft.Synapse/workspaces' |  ConvertFrom-Json
    foreach($link in $links){
        if($link.properties.privateLinkServiceConnectionState.status -eq  "Pending"){
            $id_parts = $link.id.Split("/");
            Write-Host "- " + $id_parts[$id_parts.length-1]
            $result = az network private-endpoint-connection approve -g $resource_group_name -n $id_parts[$id_parts.length-1] --resource-name $synapse_workspace_name --type Microsoft.Synapse/workspaces --description "Approved by Deploy.ps1"
        }
    }

    $links = az network private-endpoint-connection list -g $resource_group_name -n $blobstorage_name --type 'Microsoft.Storage/storageAccounts' |  ConvertFrom-Json
    foreach($link in $links){
        if($link.properties.privateLinkServiceConnectionState.status -eq  "Pending"){
            $id_parts = $link.id.Split("/");
            Write-Host "- " + $id_parts[$id_parts.length-1]
            $result = az network private-endpoint-connection approve -g $resource_group_name -n $id_parts[$id_parts.length-1] --resource-name $blobstorage_name --type Microsoft.Storage/storageAccounts --description "Approved by Deploy.ps1"
        }
    }
    $links = az network private-endpoint-connection list -g $resource_group_name -n $adlsstorage_name --type 'Microsoft.Storage/storageAccounts' |  ConvertFrom-Json
    foreach($link in $links){
        if($link.properties.privateLinkServiceConnectionState.status -eq "Pending"){
            $id_parts = $link.id.Split("/");
            Write-Host "- " + $id_parts[$id_parts.length-1]
            $result = az network private-endpoint-connection approve -g $resource_group_name -n $id_parts[$id_parts.length-1] --resource-name $adlsstorage_name --type Microsoft.Storage/storageAccounts --description "Approved by Deploy.ps1"
        }
    }
}
