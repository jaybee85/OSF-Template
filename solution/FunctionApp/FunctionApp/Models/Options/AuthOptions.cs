namespace FunctionApp.Models.Options
{
    public abstract class AuthOptions
    {
        public string Audience { get; set; }
        public string Instance { get; set; }
        public string TenantId { get; set; }
        public string Tenant { get; set; }
        public string Domain { get; set; }
        public string ClientId { get; set; }
        public string ClientSecret { get; set; }
        public string CallbackPath { get; set; }
        public string SignedOutCallbackPath { get; set; }
    }
    public class DownstreamAuthOptionsDirect : AuthOptions
    {
    }

    public class DownstreamAuthOptionsViaAppReg : AuthOptions
    {
    }
}