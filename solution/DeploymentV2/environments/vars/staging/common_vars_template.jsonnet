function (featuretemplatenam="full_deployment")
local locals = import './common_vars_values.jsonc';
local featuretemplates = {
    "basic_deployment" : import './../../featuretemplates/full_deployment.jsonc',
    "full_deployment" : import './../../featuretemplates/full_deployment.jsonc',
    "functional_tests" : import './../../featuretemplates/full_deployment.jsonc',
};

local featuretemplate =     [  // Object comprehension.
    {
        ["CICDSecretName"]: "",
        ["EnvVarName"]: "TF_VAR_" + sd.Name,
        ["HCLName"]: "",
        ["Value"]: sd.Value,
    }
    for sd in featuretemplates[featuretemplatenam]
    ];


{    
    "Variables": [            
        /*Attributes: 
            CICDSecretName: Name of the Secret that will hold the value in CICD. This mapps to the Env section of the CICD yaml",
            EnvVarName:     Name to be used when creating local environment Variable if this is blank no local environment variable will be created
            HCLName:        Name to be used when common_vars.yaml which is injected into HCL file. If this is blank it will not be included in HCL
        */  
        /*
            Environment Only Vars 
            - these are not used in local console based deployments. Only when runnning in git hub
        */
         {
            "CICDSecretName": "WEB_APP_ADMIN_USER",
            "EnvVarName": "WEB_APP_ADMIN_USER",
            "HCLName": "",
            "Value": locals.WEB_APP_ADMIN_USER
        },
        {
            "CICDSecretName": "ARM_SYNAPSE_WORKSPACE_NAME",
            "EnvVarName": "ARM_SYNAPSE_WORKSPACE_NAME",
            "HCLName": "",
            "Value": locals.ARM_SYNAPSE_WORKSPACE_NAME
        },
        {
            "CICDSecretName": "ARM_KEYVAULT_NAME",
            "EnvVarName": "keyVaultName",
            "HCLName": "",
            "Value": locals.ARM_KEYVAULT_NAME
        },
        {
            "CICDSecretName": "ARM_DATALAKE_NAME",
            "EnvVarName": "datalakeName",
            "HCLName": "",
            "Value": locals.ARM_DATALAKE_NAME
        },
        /*
            Required for Automated CICD Deployment 
        */
        {
            "CICDSecretName": "ARM_CLIENT_ID",
            "EnvVarName": "ARM_CLIENT_ID",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "ARM_PAL_PARTNER_ID",
            "EnvVarName": "ARM_PAL_PARTNER_ID",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "ARM_CLIENT_SECRET",
            "EnvVarName": "ARM_CLIENT_SECRET",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "ARM_SUBSCRIPTION_ID",
            "EnvVarName": "ARM_SUBSCRIPTION_ID",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "ARM_TENANT_ID",
            "EnvVarName": "ARM_TENANT_ID",
            "HCLName": "tenant_id",
            "Value": locals.tenant_id
        },

        /*
            HCL Common Vars & Terraform Customisations 
        */
        {                    
            "CICDSecretName": "",
            "EnvVarName": "",
            "HCLName": "owner_tag",
            "Value": locals.owner_tag
        },
        {
            "CICDSecretName": "",
            "EnvVarName": "",
            "HCLName": "deployment_principal_layers1and3",
            "Value": locals.deployment_principal_layers1and3
        },
        {
            "CICDSecretName": "",
            "EnvVarName": "",
            "HCLName": "resource_location",
            "Value": locals.resource_location
        },
        {
            "CICDSecretName": "ENVIRONMENT_TAG",
            "EnvVarName": "TF_VAR_environment_tag",
            "HCLName": "environment_tag",
            "Value": locals.environment_tag
        },
        {
            "CICDSecretName": "ARM_DOMAIN",
            "EnvVarName": "TF_VAR_domain",
            "HCLName": "domain",
            "Value": locals.domain
        },
        {
            "CICDSecretName": "",
            "EnvVarName": "",
            "HCLName": "subscription_id",
            "Value": locals.subscription_id
        },
        {
            "CICDSecretName": "",
            "EnvVarName": "",
            "HCLName": "prefix",
            "Value": locals.prefix
        },
        {
            "CICDSecretName": "ARM_RESOURCE_GROUP_NAME",            
            "EnvVarName": "TF_VAR_resource_group_name",
            "HCLName": "resource_group_name",
            "Value": locals.resource_group_name
        },
        {
            "CICDSecretName": "",
            "EnvVarName": "",
            "HCLName": "ip_address",
            "Value": locals.ip_address
        },
        {
            "CICDSecretName": "",
            "EnvVarName": "",
            "HCLName": "ip_address2",
            "Value": locals.ip_address2
        },
        {            
            "CICDSecretName": "",            
            "EnvVarName": "",            
            "HCLName": "synapse_administrators",
            "Value": locals.synapse_administrators
        },
        {            
            "CICDSecretName": "ARM_STORAGE_NAME",            
            "EnvVarName": "TF_VAR_state_storage_account_name",            
            "HCLName": "",
            "Value": "#####"
        },
        {            
            "CICDSecretName": "ARM_SYNAPSE_PASSWORD",            
            "EnvVarName": "TF_VAR_synapse_sql_password",            
            "HCLName": "",
            "Value": "#####"
        },
        {            
            "CICDSecretName": "ARM_JUMPHOST_PASSWORD",            
            "EnvVarName": "TF_VAR_jumphost_password",            
            "HCLName": "",
            "Value": "#####"
        },        
        {            
            "CICDSecretName": "WEB_APP_ADMIN_SECURITY_GROUP",            
            "EnvVarName": "TF_VAR_web_app_admin_security_group",            
            "HCLName": "",
            "Value": "#####"
        },
        /*
            Git Integration Set-Up
        */
        {
            "CICDSecretName": "GIT_REPOSITORY_NAME",
            "EnvVarName": "TF_VAR_adf_git_repository_name",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "GIT_SYNAPSE_REPOSITORY_BRANCH_NAME",
            "EnvVarName": "TF_VAR_synapse_git_repository_branch_name",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "GIT_PAT",
            "EnvVarName": "TF_VAR_synapse_git_pat",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "GIT_USER_NAME",
            "EnvVarName": "TF_VAR_synapse_git_user_name",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "GIT_EMAIL_ADDRESS",
            "EnvVarName": "TF_VAR_synapse_git_email_address",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "GIT_ADF_REPOSITORY_NAME",
            "EnvVarName": "TF_VAR_adf_git_repository_name",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "GIT_ADF_REPOSITORY_BRANCH_NAME",
            "EnvVarName": "TF_VAR_adf_git_repository_branch_name",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "GIT_ADF_PAT",
            "EnvVarName": "TF_VAR_adf_git_pat",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "GIT_ADF_USER_NAME",
            "EnvVarName": "TF_VAR_adf_git_user_name",
            "HCLName": "",
            "Value": "#####"
        },
        {
            "CICDSecretName": "GIT_ADF_EMAIL_ADDRESS",
            "EnvVarName": "TF_VAR_adf_git_email_address",
            "HCLName": "",
            "Value": "#####"
        }
    ]+featuretemplate
}