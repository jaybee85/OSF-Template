using System;
using System.IO;
using System.Threading.Tasks;
using FunctionApp.DataAccess;
using FunctionApp.Models;
using FunctionApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Functions
{
    /// <summary>
    /// The purpose of this function is to disable a TaskMaster object. 
    /// </summary>
    // ReSharper disable once UnusedMember.Global
    public class AdfDisableTaskMaster
    {
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;

        public AdfDisableTaskMaster(TaskMetaDataDatabase taskMetaDataDatabase)
        {
            _taskMetaDataDatabase = taskMetaDataDatabase;
        }
        /// <summary>
        /// Disable a TaskMast object in the database
        /// </summary>
        /// <param name="req"></param>
        /// <param name="log"></param>
        /// <param name="context"></param>
        /// <example>
        /// {
        ///     "TaskMasterId" : 3
        /// }
        /// </example>
        /// <returns></returns>
        [FunctionName("DisableTaskMaster")]
        // ReSharper disable once UnusedMember.Global
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log, ExecutionContext context)
        {
            Guid executionId = context.InvocationId;
            FrameworkRunner frp = new FrameworkRunner(log, executionId);
            FrameworkRunnerWorkerWithHttpRequest worker = DisableTaskMasterCore;
            Task<FrameworkRunnerResult> result = frp.Invoke(req, "DisableTaskMaster", worker);
            if (result.Result.Succeeded)
            {
                return new OkObjectResult(JObject.Parse(result.Result.ReturnObject));
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed...." });
            }
        }

        public async Task<JObject> DisableTaskMasterCore(HttpRequest req,
            Logging.Logging logging)
        {
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            dynamic taskMasterId = JObject.Parse(data.ToString())["TaskMasterId"];
            await _taskMetaDataDatabase.ExecuteSql(string.Format(@"Update [dbo].[TaskMaster] SET ActiveYN = '0' Where [TaskMasterId] = {0}", taskMasterId));

            JObject root = new JObject
            {
                ["Result"] = "Complete"
            };

            return root;
        }
    }
}