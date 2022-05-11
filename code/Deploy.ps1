Set-Location -Path "..\infra\"

$json = (Get-Content params.dev.json | ConvertFrom-Json).parameters | ConvertTo-Json
$json = $json.replace("""","\""")

$outputs = az deployment sub create --name dlz01 --location  "australiaeast" --subscription "Jorampon Internal Consumption" --template-file main.bicep --parameters $json

#Outputs
$outputs | Set-Content "outputs.json"

##Todo - Swap folder

#Inputs
$inputs = (Get-Content params.dev.json | ConvertFrom-Json)

foreach ($o in ($outputs | Get-Member)){
    if($o.MemberType -eq "NoteProperty"){
        foreach ($i in ($inputs.parameters | Get-Member)){
            if($i.Name -eq $o.Name -and $i.MemberType -eq "NoteProperty"){
                #Write-Host -ForegroundColor Yellow $i.Name
                #Write-Host -ForegroundColor Green $o.Name
                $inputs.parameters.($i.Name).value =  $outputs.($o.Name).value
            }
        }
    }
}

($inputs| ConvertTo-Json -Depth 10) | Set-Content "params.dev.json"



$json = (Get-Content params.dev.json | ConvertFrom-Json).parameters | ConvertTo-Json
$json = $json.replace("""","\""")

az deployment sub create --name dlz01 --location  "australiaeast" --subscription "Jorampon Internal Consumption" --template-file main.bicep --parameters $json