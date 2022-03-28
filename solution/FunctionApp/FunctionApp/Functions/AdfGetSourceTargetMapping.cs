using System;
using System.IO;
using System.Threading.Tasks;
using FunctionApp.Authentication;
using FunctionApp.Helpers;
using FunctionApp.Models;
using FunctionApp.Models.Options;
using FunctionApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.WindowsAzure.Storage.Auth;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Functions
{
    /// <summary>
    /// Get Source and Target Mapping (SQL to Parquet and Parquet to SQL)
    /// </summary>
    // ReSharper disable once UnusedMember.Global
    public class AdfGetSourceTargetMapping
    {
        private readonly IOptions<ApplicationOptions> _options;
        private readonly IAzureAuthenticationProvider _authProvider;

        public AdfGetSourceTargetMapping(IOptions<ApplicationOptions> options,
            IAzureAuthenticationProvider authProvider)
        {
            _options = options;
            _authProvider = authProvider;
        }
        [FunctionName("GetSourceTargetMapping")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log, ExecutionContext context)
        {
            Guid executionId = context.InvocationId;
            FrameworkRunner frp = new FrameworkRunner(log, executionId);
            FrameworkRunnerWorkerWithHttpRequest worker = GetSourceTargetMappingCore;
            FrameworkRunnerResult result = await frp.Invoke(req, "GetSourceTargetMapping", worker);
            if (result.Succeeded)
            {
                return new OkObjectResult(JObject.Parse(result.ReturnObject));
            }
            return new BadRequestObjectResult(new { Error = "Execution Failed...." });
        }


        public async Task<JObject> GetSourceTargetMappingCore(HttpRequest req,
        Logging.Logging logging)
        {
            using var reader = new StreamReader(req.Body);
            var requestBody = await reader.ReadToEndAsync();
            JObject data = JsonConvert.DeserializeObject<JObject>(requestBody);
            return await GetSourceTargetMappingCore(data, logging);
        }

        public async Task<JObject> GetSourceTargetMappingCore(JObject data, 
            Logging.Logging logging)
        {
           
            string storageAccountName = data["StorageAccountName"].ToString();
            string storageAccountContainer = data["StorageAccountContainer"].ToString();
            string relativePath = data["RelativePath"].ToString();
            string metadataType = data["MetadataType"].ToString();
            string sourceType = data["SourceType"].ToString();
            string targetType = data["TargetType"].ToString();
            string schemaFileName = data["SchemaFileName"].ToString();

            storageAccountName = storageAccountName.Replace(".dfs.core.windows.net", "").Replace("https://", "").Replace(".blob.core.windows.net", "");
            var storageToken = new TokenCredential(await _authProvider.GetAzureRestApiToken($"https://{storageAccountName}.blob.core.windows.net").ConfigureAwait(false));

            string schemaStructure = await AzureBlobStorageService.ReadFile(storageAccountName, storageAccountContainer, relativePath, schemaFileName, storageToken);

            JArray arr = (JArray)JsonConvert.DeserializeObject(schemaStructure);
            JObject root = SqlDataTypeHelper.CreateMappingBetweenSourceAndTarget(arr, sourceType, targetType, metadataType);

            logging.LogInformation("GetSourceTargetMapping Function complete.");
            return root;
        }
    }
}