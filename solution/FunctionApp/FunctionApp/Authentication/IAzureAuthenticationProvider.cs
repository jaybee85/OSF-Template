using System.Threading.Tasks;

namespace FunctionApp.Authentication
{
    public interface IAzureAuthenticationProvider
    {
        Task<string> GetAzureRestApiToken(string resourceName);
    }
}
