$environment = Get-Content development.json | ConvertFrom-Json -Depth 10

foreach ($prop in $environment | Get-Member | Where-Object {$_.MemberType -eq 'NoteProperty'} )
{
  #Write-Host $prop.Definition.ty
  $property = $prop.Name
  $value = $environment.$property
  Write-Host $value.GetType()
  if($value.GetType().Name -eq "String")
  {
    Write-Host "cat ../terraform_layer2/staging/vars/terragrunt.hcl | hclq set inputs.$property ""$value"""
  }
  else 
  {
    if($value.GetType().Name -eq "Boolean")
    {
      Write-Host "cat ../terraform_layer2/staging/vars/terragrunt.hcl | hclq set inputs.$property" + $value.ToString().ToLower() 
    }
    else 
    {
      Write-Host "cat ../terraform_layer2/staging/vars/terragrunt.hcl | hclq set inputs.$property $value"
    }
  }

}
