resource "null_resource" "metadatadb_admins" {
  for_each = (var.azure_sql_aad_administrators)  
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${each.key} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.metadatadb_name}"    
  }
  
} 

resource "null_resource" "stagingdb_admins" {
  for_each = (var.azure_sql_aad_administrators)  
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${each.key} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.stagingdb_name}"    
  }
  
} 

resource "null_resource" "sampledb_admins" {
  for_each = (var.azure_sql_aad_administrators)  
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${each.key} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.sampledb_name}"    
  }
  
} 

//Puview 
resource "null_resource" "purview_access_sampledb" {
  count   = var.deploy_purview ? 1 : 0
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${data.terraform_remote_state.layer2.outputs.purview_name} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.sampledb_name}"    
  }
  
} 

resource "null_resource" "purview_access_stagingdb" {
  count   = var.deploy_purview ? 1 : 0
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${data.terraform_remote_state.layer2.outputs.purview_name} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.stagingdb_name}"    
  }
  
}

//Puview SP
resource "null_resource" "purview_sp_access_sampledb" {
  count   = var.deploy_purview ? 1 : 0
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${data.terraform_remote_state.layer2.outputs.purview_sp_name} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.sampledb_name}"    
  }
  
} 

resource "null_resource" "purview_sp_access_stagingdb" {
  count   = var.deploy_purview ? 1 : 0
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${data.terraform_remote_state.layer2.outputs.purview_sp_name} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.stagingdb_name}"    
  }

}

//Data Factory
resource "null_resource" "datafactory_access_sampledb" {
  count   = var.deploy_data_factory ? 1 : 0
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${data.terraform_remote_state.layer2.outputs.datafactory_name} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.sampledb_name}"    
  }
  
} 

resource "null_resource" "datafactory_access_stagingdb" {
  count   = var.deploy_data_factory ? 1 : 0
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${data.terraform_remote_state.layer2.outputs.datafactory_name} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.stagingdb_name}"    
  }
  
}

resource "null_resource" "datafactory_access_metadatadb" {
  count   = var.deploy_data_factory ? 1 : 0
  provisioner "local-exec" {
    working_dir = path.module
    command = "pwsh -file database.ps1 -user ${data.terraform_remote_state.layer2.outputs.datafactory_name} -sqlserver_name ${data.terraform_remote_state.layer2.outputs.sqlserver_name} -database ${data.terraform_remote_state.layer2.outputs.metadatadb_name}"    
  }
  
}

