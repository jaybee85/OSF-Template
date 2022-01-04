using FunctionApp.Models.Options;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;

namespace FunctionApp.Authentication
{
    /// <summary>
    /// This class uses the Microsoft.Azure.Management packages. These packages are in low maintenance mode
    /// and are being phased out
    /// </summary>
    //[Obsolete(" Microsoft.Azure.Management packages. These packages are in low maintenance mode and are being phased out.")]
    public class MicrosoftAzureManagementAuthenticationProvider
    {
        private readonly DownstreamAuthOptionsDirect _authOptions;

        public MicrosoftAzureManagementAuthenticationProvider(DownstreamAuthOptionsDirect authOptions)
        {
            _authOptions = authOptions;
        }
        public AzureCredentials GetAzureCredentials(bool useMsi)
        {
            //MSI Login
            AzureCredentialsFactory f = new AzureCredentialsFactory();
            MSILoginInformation msi = new MSILoginInformation(MSIResourceType.AppService);
            AzureCredentials creds;

            if (useMsi == true)
            {
                //MSI
                creds = f.FromMSI(msi, AzureEnvironment.AzureGlobalCloud);
            }
            else
            {
                //Service Principal
                creds = f.FromServicePrincipal(_authOptions.ClientId, _authOptions.ClientSecret, _authOptions.TenantId, AzureEnvironment.AzureGlobalCloud);
            }

            return creds;
        }
    }
}
