namespace FunctionApp.Helpers
{
    public static class EnvironmentHelper
    {
        public static string GetWorkingFolder()
        {
            var localApplicationPath = System.Environment.GetEnvironmentVariable("AzureWebJobsScriptRoot");
            var azureApplicationPath = $"{System.Environment.GetEnvironmentVariable("HOME")}\\site\\wwwroot";

            return localApplicationPath ?? azureApplicationPath;
        }
    }
}
