using System;
using FunctionApp.Models;
using FunctionApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Functions
{
    // ReSharper disable once UnusedMember.Global
    public static class MsSqlGetAllTablesFromDatabaseSql
    {
        [FunctionName("MsSqlGetAllTablesFromDatabaseSQL")]
        // ReSharper disable once UnusedMember.Global
        public static IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req,
            ILogger log, ExecutionContext context)
        {
            if (context == null)
                throw new ArgumentException("Execution Context");
            Guid executionId = context.InvocationId;
            FrameworkRunner frp = new FrameworkRunner(log, executionId);

            FrameworkRunnerWorkerWithHttpRequest worker = MsSqlGetAllTablesFromDatabaseSqlCore;
            FrameworkRunnerResult result = frp.Invoke(req, "MsSqlGetAllTablesFromDatabaseSQL", worker);
            if (result.Succeeded)
            {
                return new OkObjectResult(JObject.Parse(result.ReturnObject));
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed...." });
            }

        }

        public static JObject MsSqlGetAllTablesFromDatabaseSqlCore(HttpRequest req,
            Logging.Logging logging)
        {
            string informationSchemaSql = @"
                            Select * from INFORMATION_SCHEMA.TABLES
                            where [Table_schema] not in ('sys') and TABLE_TYPE = 'BASE TABLE'       
                        ";

            JObject root = new JObject
            {
                ["InformationSchemaSQL"] = informationSchemaSql
            };

            logging.LogInformation("MsSqlGetAllTablesFromDatabaseSQL Function complete.");
            return root;
        }
    }

}