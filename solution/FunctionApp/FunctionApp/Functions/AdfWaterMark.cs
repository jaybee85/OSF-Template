using System;
using System.Data;
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
    public class AdfWaterMark
    {
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;

        public AdfWaterMark(TaskMetaDataDatabase taskMetaDataDatabase)
        {
            _taskMetaDataDatabase = taskMetaDataDatabase;
        }
        [FunctionName("WaterMark")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log, ExecutionContext context)
        {
            Guid executionId = context.InvocationId;
            FrameworkRunner frp = new FrameworkRunner(log, executionId);

            FrameworkRunnerWorkerWithHttpRequest worker = UpdateWaterMark;
            FrameworkRunnerResult result = await frp.Invoke(req, "UpdateWaterMark", worker);
            if (result.Succeeded)
            {
                return new OkObjectResult(JObject.Parse(result.ReturnObject));
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed...." });
            }

        }
        public async Task<JObject> UpdateWaterMark(HttpRequest req,
            Logging.Logging LogHelper)
        {
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);

            dynamic taskMasterId = JObject.Parse(data.ToString())["TaskMasterId"];
            dynamic taskMasterWaterMarkColumnType = JObject.Parse(data.ToString())["TaskMasterWaterMarkColumnType"];
            dynamic waterMarkValue = JObject.Parse(data.ToString())["WaterMarkValue"];

            if (!string.IsNullOrEmpty(waterMarkValue.ToString()))
            {
                using DataTable dt = new DataTable();
                dt.Columns.Add(new DataColumn("TaskMasterId", typeof(long)));
                dt.Columns.Add(new DataColumn("TaskMasterWaterMarkColumnType", typeof(string)));
                dt.Columns.Add(new DataColumn("TaskMasterWaterMark_DateTime", typeof(DateTime)));
                dt.Columns.Add(new DataColumn("TaskMasterWaterMark_BigInt", typeof(long)));
                dt.Columns.Add(new DataColumn("TaskMasterWaterMark_String", typeof(string)));
                dt.Columns.Add(new DataColumn("ActiveYN", typeof(bool)));
                dt.Columns.Add(new DataColumn("UpdatedOn", typeof(DateTime)));

                DataRow dr = dt.NewRow();
                dr["TaskMasterId"] = taskMasterId;
                dr["TaskMasterWaterMarkColumnType"] = taskMasterWaterMarkColumnType;
                if (taskMasterWaterMarkColumnType == "DateTime")
                {
                    dr["TaskMasterWaterMark_DateTime"] = waterMarkValue;
                    dr["TaskMasterWaterMark_BigInt"] = DBNull.Value;
                    dr["TaskMasterWaterMark_String"] = DBNull.Value;

                }
                else if (taskMasterWaterMarkColumnType == "BigInt")
                {
                    dr["TaskMasterWaterMark_DateTime"] = DBNull.Value;
                    dr["TaskMasterWaterMark_BigInt"] = waterMarkValue;
                    dr["TaskMasterWaterMark_String"] = DBNull.Value;

                }
                else if (taskMasterWaterMarkColumnType == "lsn" || taskMasterWaterMarkColumnType == "string")
                {
                    dr["TaskMasterWaterMark_DateTime"] = DBNull.Value;
                    dr["TaskMasterWaterMark_BigInt"] = DBNull.Value;
                    dr["TaskMasterWaterMark_String"] = waterMarkValue;

                }
                else
                {
                    throw new ArgumentException(string.Format("Invalid WaterMark ColumnType = '{0}'", taskMasterWaterMarkColumnType));
                }

                dr["ActiveYN"] = 1;
                dr["UpdatedOn"] = DateTime.UtcNow;
                dt.Rows.Add(dr);

                string tempTableName = $"#Temp_TaskMasterWaterMark_{Guid.NewGuid()}";
                await _taskMetaDataDatabase.AutoBulkInsertAndMerge(dt, tempTableName, "TaskMasterWaterMark");
            }

            JObject root = new JObject
            {
                ["Result"] = "Complete"
            };

            return root;
        }
    }
}