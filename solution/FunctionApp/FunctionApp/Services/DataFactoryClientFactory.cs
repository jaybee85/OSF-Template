/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/

using System.Threading.Tasks;
using FunctionApp.Authentication;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.Rest;

namespace FunctionApp.Services
{
    public class DataFactoryClientFactory
    {
        private readonly IAzureAuthenticationProvider _authProvider;

        public DataFactoryClientFactory(IAzureAuthenticationProvider authProvider)
        {
            _authProvider = authProvider;
        }
        public async Task<DataFactoryManagementClient> CreateDataFactoryClient(string SubscriptionId)
        {
            string token = await _authProvider.GetAzureRestApiToken("https://management.azure.com/").ConfigureAwait(false);
            ServiceClientCredentials cred = new TokenCredentials(token);

            DataFactoryManagementClient adfClient = new DataFactoryManagementClient(cred)
            {
                SubscriptionId = SubscriptionId
            };

            return adfClient;
        }
    }
}
