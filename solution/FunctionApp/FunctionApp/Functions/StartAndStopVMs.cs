/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/

using System.IO;
using System.Linq;
using System.Threading.Tasks;
using FunctionApp.Authentication;
using FunctionApp.DataAccess;
using FunctionApp.Models;
using FunctionApp.Models.Options;
using FunctionApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Management.Compute.Fluent;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Core;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Functions
{
    public class StartAndStopVMs
    {
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;
#pragma warning disable CS0618
        // We need to update this us use the new provider at some point.
        private readonly MicrosoftAzureManagementAuthenticationProvider _legacyAuthProvider;
        private readonly ApplicationOptions _options;

        public StartAndStopVMs(IOptions<ApplicationOptions> options, TaskMetaDataDatabase taskMetaDataDatabase, MicrosoftAzureManagementAuthenticationProvider legacyAuthProvider)
        {
            _taskMetaDataDatabase = taskMetaDataDatabase;
            _legacyAuthProvider = legacyAuthProvider;
            _options = options?.Value;
        }
        [FunctionName("StartAndStopVMs")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req, ILogger log, ExecutionContext context, System.Security.Claims.ClaimsPrincipal principal)
        {
            bool allowed = false;
            var roles = principal.Claims.Where(e => e.Type == "roles").Select(e => e.Value);

            foreach (string r in roles)
            {
                if (r == "All") { allowed = true; }
            }

            if (!allowed && !_options.ServiceConnections.CoreFunctionsURL.Contains("localhost"))
            {
                string err = "Request was rejected as user is not allowed to perform this action";
                log.LogError(err);
                return new BadRequestObjectResult(new { Error = err });
            }

            System.Guid executionId = context.InvocationId;
            FrameworkRunner frp = new FrameworkRunner(log, executionId);

            FrameworkRunnerWorkerWithHttpRequest worker = StartAndStopVMsCore;
            FrameworkRunnerResult result = frp.Invoke(req, "StartAndStopVMs", worker);
            if (result.Succeeded)
            {
                return new OkObjectResult(JObject.Parse(result.ReturnObject));
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed...." });
            }
        }


        public async Task<JObject> StartAndStopVMsCore(HttpRequest req, Logging.Logging logging)
        {
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            JObject data = JsonConvert.DeserializeObject<JObject>(requestBody);
            string taskInstanceId = data["TaskInstanceId"].ToString();
            string executionUid = data["ExecutionUid"].ToString();
            try
            {
                logging.LogInformation("StartAndStopVMs function processed a request.");
                string subscription = data["Target"]["SubscriptionUid"].ToString();
                string vmName = data["Target"]["VMname"].ToString();
                string vmResourceGroup = data["Target"]["ResourceGroup"].ToString();
                string vmAction = data["Target"]["Action"].ToString();

                Microsoft.Azure.Management.Fluent.Azure.IAuthenticated azureAuth = Microsoft.Azure.Management.Fluent.Azure.Configure()
                        .WithLogLevel(HttpLoggingDelegatingHandler.Level.BodyAndHeaders)
                        .Authenticate(_legacyAuthProvider.GetAzureCredentials(_options.UseMSI));
                IAzure azure = azureAuth.WithSubscription(subscription);
                logging.LogInformation("Selected subscription: " + azure.SubscriptionId);
                IVirtualMachine vm = azure.VirtualMachines.GetByResourceGroup(vmResourceGroup, vmName);
                if (vm.PowerState == PowerState.Deallocated && vmAction.ToLower() == "start")
                {
                    logging.LogInformation("VM State is: " + vm.PowerState.Value.ToString());
                    vm.StartAsync().Wait(5000);
                    logging.LogInformation("VM Start Initiated: " + vm.Name);
                }

                if (vm.PowerState != PowerState.Deallocated && vmAction.ToLower() == "stop")
                {
                    logging.LogInformation("VM State is: " + vm.PowerState.Value.ToString());
                    vm.DeallocateAsync().Wait(5000);
                    logging.LogInformation("VM Stop Initiated: " + vm.Name);
                }

                JObject root = new JObject { ["Result"] = "Complete" };

                if (vmName != null)
                {   root["Result"] = "Complete";
                   
                }
                else
                { 
                    root["Result"] = "Please pass a name, resourcegroup and action to request body";
                    _taskMetaDataDatabase.LogTaskInstanceCompletion(System.Convert.ToInt64(taskInstanceId), System.Guid.Parse(executionUid), TaskInstance.TaskStatus.FailedRetry, System.Guid.Empty, "Task missing VMname, ResourceGroup or SubscriptionUid in Target element.");
                    return root;
                }
                //Update Task Instance
                _taskMetaDataDatabase.LogTaskInstanceCompletion(System.Convert.ToInt64(taskInstanceId), System.Guid.Parse(executionUid), TaskInstance.TaskStatus.Complete, System.Guid.Empty, "");

                return root;
            }
            catch (System.Exception taskException)
            {
                logging.LogErrors(taskException);
                _taskMetaDataDatabase.LogTaskInstanceCompletion(System.Convert.ToInt64(taskInstanceId), System.Guid.Parse(executionUid), TaskInstance.TaskStatus.FailedRetry, System.Guid.Empty, "Failed when trying to start or stop VM");

                JObject root = new JObject
                {
                    ["Result"] = "Failed"
                };

                return root;

            }
        }
#pragma warning restore CS0618


    }
}
