using System.Threading.Tasks;
using FunctionApp.Models.Options;
using Microsoft.IdentityModel.Clients.ActiveDirectory;

namespace FunctionApp.Authentication
{
    /// <summary>
    /// This provider is used for Azure App Services only. 
    /// </summary>
    /// <remarks>Consider using the Azure.Identity package and provider instead. This is no longer the preferred method</remarks>
    public class MicrosoftAzureServicesAppAuthenticationProvider: IAzureAuthenticationProvider
    {
        private readonly bool _useMsi;
        private readonly AuthOptions _authOptions;

        public MicrosoftAzureServicesAppAuthenticationProvider(AuthOptions authOptions, bool useMsi)
        {
            _useMsi = useMsi;
            _authOptions = authOptions;
        }
        public async Task<string> GetAzureRestApiToken(string resourceName)
        {
            try
            {
                if (_useMsi)
                {
                    Microsoft.Azure.Services.AppAuthentication.AzureServiceTokenProvider tokenProvider = new Microsoft.Azure.Services.AppAuthentication.AzureServiceTokenProvider();
                    return await tokenProvider.GetAccessTokenAsync(resourceName).ConfigureAwait(false);
                }
                else
                {

                    AuthenticationContext context =
                        new AuthenticationContext("https://login.windows.net/" + _authOptions.TenantId);
                    ClientCredential cc = new ClientCredential(_authOptions.ClientId, _authOptions.ClientSecret);
                    AuthenticationResult result =  await context.AcquireTokenAsync(resourceName, cc).ConfigureAwait(false);
                    return result.AccessToken;
                }
            }
            catch (System.Exception e)
            {
                throw e;
                return "Failed to GetAzureRestApiToken";
            }
        }
    }
}
