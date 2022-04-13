/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text.RegularExpressions;
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
    public class PurviewGetMetaData
    {
        private readonly PurviewService _purviewService;
        private readonly ApplicationOptions _options;
        private Logging.Logging _funcAppLogger = new Logging.Logging();

        public PurviewGetMetaData(IOptions<ApplicationOptions> options, PurviewService purviewService)
        {
            _purviewService = purviewService;
            _options = options?.Value;
        }
        [FunctionName("PurviewGetMetaData")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req, ILogger log, ExecutionContext context)
        {
            var executionId = System.Guid.NewGuid();
            ActivityLogItem activityLogItem = new ActivityLogItem
            {
                LogSource = "AF",
                ExecutionUid = executionId
            };
            _funcAppLogger.InitializeLog(log, activityLogItem);

            string requestBody = new StreamReader(req.Body).ReadToEndAsync().Result;
            JObject metadata = JsonConvert.DeserializeObject<JObject>(requestBody);
            var result = (_purviewService.PurviewMetaDataCheck(metadata, _funcAppLogger).Result);

            if (result["Result"].ToString() == "Complete")
            {
                return new OkObjectResult("Purview Metadata upload complete");
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed: " + result["Result"].ToString() });
            }

        }

    }
}
