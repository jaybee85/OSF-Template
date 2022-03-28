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
    public class GetSqlCreateStatementFromSchema
    {
        private readonly IOptions<ApplicationOptions> _options;
        private readonly IAzureAuthenticationProvider _authProvider;

        public GetSqlCreateStatementFromSchema(IOptions<ApplicationOptions> options, IAzureAuthenticationProvider authProvider)
        {
            _options = options;
            _authProvider = authProvider;
        }

        [FunctionName("GetSQLCreateStatementFromSchema")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log, ExecutionContext context)
        {
            Guid executionId = context.InvocationId;

            FrameworkRunner frp = new FrameworkRunner(log, executionId);

            FrameworkRunnerWorkerWithHttpRequest worker = GetSqlCreateStatementFromSchemaCore;
            FrameworkRunnerResult result = await frp.Invoke(req, "GetSQLCreateStatementFromSchema", worker);
            if (result.Succeeded)
            {
                return new OkObjectResult(JObject.Parse(result.ReturnObject));
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed...." });
            }

        }

        public async Task<JObject> GetSqlCreateStatementFromSchemaCore(HttpRequest req, Logging.Logging logging)
        {

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            JObject data = JsonConvert.DeserializeObject<JObject>(requestBody);

            return await GetSqlCreateStatementFromSchemaCore(data, logging);

        }

        public async Task<JObject> GetSqlCreateStatementFromSchemaCore(JObject data, Logging.Logging logging)
        {           
            string createStatement;
            JArray arr;

            if (data["Data"] != null)
            {
                //Need to swap logic for parquet vs sql etc
                arr = (JArray)data["Data"]["value"];
            }
            else if (data["SchemaFileName"] != null)
            {
                string storageAccountName = data["StorageAccountName"].ToString();
                string storageAccountContainer = data["StorageAccountContainer"].ToString();
                string relativePath = data["RelativePath"].ToString();
                string schemaFileName = data["SchemaFileName"].ToString();
                string targetType = "";//data["TargetType"].ToString();

                if (relativePath.StartsWith("/")) { relativePath = relativePath.Remove(0, 1); }

                storageAccountName = storageAccountName.Replace(".dfs.core.windows.net", "").Replace("https://", "").Replace(".blob.core.windows.net", "");

                TokenCredential storageToken = new TokenCredential(await _authProvider.GetAzureRestApiToken($"https://{storageAccountName}.blob.core.windows.net"));

                arr = (JArray)JsonConvert.DeserializeObject( await AzureBlobStorageService.ReadFile(storageAccountName, storageAccountContainer, relativePath, schemaFileName, storageToken));
            }
            else
            {
                throw new ArgumentException("Not Valid parameters to GetSQLCreateStatementFromSchema Function!");
            }

            bool dropIfExist = data["DropIfExist"] == null ? false : (bool)data["DropIfExist"];

            createStatement = GenerateSqlStatementTemplates.GetCreateTable(arr, data["TableSchema"].ToString(), data["TableName"].ToString(), data["TargetType"].ToString(), dropIfExist);
            createStatement += Environment.NewLine + "Select 1";

            JObject root = new JObject
            {
                ["CreateStatement"] = createStatement
            };

            return root;
        }
    }
}