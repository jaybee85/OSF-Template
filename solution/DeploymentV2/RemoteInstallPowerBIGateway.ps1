#$irKey1 = az datafactory integration-runtime list-auth-key --factory-name $env:AdsOpts_CD_Services_DataFactory_Name --name $env:AdsOpts_CD_Services_DataFactory_OnPremVnetIr_Name --resource-group $env:AdsOpts_CD_ResourceGroup_Name --query authKey1 --out tsv
#Write-Debug " irKey1 retrieved."
               
$ScriptUri = "https://gist.githubusercontent.com/jrampono/91076c406345c1d2487a82b1f106dfaa/raw/7454cf85786c3f047d321b98d5c77ad3676be21a/test.ps1"

#Run  Remote Script
az vm run-command create --name "test2" --vm-name $tout.selfhostedsqlvm_name --resource-group $tout.resource_group_name --parameters test=hello --script-uri $ScriptUri

#Check Results
az vm run-command show --name "test2" --vm-name $tout.selfhostedsqlvm_name --resource-group $tout.resource_group_name --instance-view