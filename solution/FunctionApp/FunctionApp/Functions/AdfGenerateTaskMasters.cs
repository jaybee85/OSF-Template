using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using FunctionApp.DataAccess;
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
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Functions
{

    /// <summary>
    /// The purpose of this function is to auto-generate task master objects within the metadata
    /// database using a list of tables and a default TaskMaster template. Using this function you
    /// can quickly configure the pipelines for multiple tables/data stores.
    /// </summary>
    /// <example>
    /// {
    ///     "TableList" : [{
    ///         "TABLE_SCHEMA" : "LeighSchema",
    ///          "TABLE_NAME"  :  "LeighTable"
    ///     }],
    ///     "JsonTemplate" : {
    ///       "TaskMasterName": "AdventureWorks2017 {@TableSchema@}.{@TableName@} Data Lake to SQL",
    ///       "TaskTypeId": 1,
    ///       "TaskGroupId": 6,
    ///       "ScheduleMasterId": 2,
    ///        "SourceSystemId": 3,
    ///         "TargetSystemId": 2,
    ///            "DegreeOfCopyParallelism": 1,
    ///         "AllowMultipleActiveInstances": 0,
    ///         "TaskDatafactoryIR": "SH IR",
    ///         "Source": {
    ///             "Type": "Parquet",
    ///             "RelativePath": "AdventureWorks2017/{@TableSchema@}/{@TableName@}/{yyyy}/{MM}/{dd}/{hh}/{mm}/",
    ///             "DataFileName": "{@TableSchema@}.{@TableName@}.parquet",
    ///             "SchemaFileName": "{@TableSchema@}.{@TableName@}.json"
    ///         },
    ///         "Target": {
    ///             "Type": "Table",
    ///             "TableSchema": "{@TableSchema@}",
    ///             "TableName": "{@TableName@}",
    ///             "StagingTableSchema": "{@TableSchema@}",
    ///             "StagingTableName": "stg_{@TableName@}",
    ///             "AutoCreateTable": "True",
    ///             "PreCopySQL": "IF OBJECT_ID(''{@TableSchema@}.stg_{@TableName@}'') IS NOT NULL \r\n Truncate Table {@TableSchema@}.stg_{@TableName@}",
    ///             "PostCopySQL": "",
    ///             "MergeSQL": "",
    ///             "AutoGenerateMerge": "True"
    ///         },
    ///      "ActiveYN": 1,
    ///      "DependencyChainTag": "{@TableSchema@}.{@TableName@}",
    ///      "DataFactoryId":1
    ///     }
    /// }
    ///
    /// </example>
    // ReSharper disable once UnusedMember.Global
    public class AdfGenerateTaskMasters
    {
        private readonly IOptions<ApplicationOptions> _options;
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;

        public AdfGenerateTaskMasters(IOptions<ApplicationOptions> options, TaskMetaDataDatabase taskMetaDataDatabase)
        {
            _options = options;
            _taskMetaDataDatabase = taskMetaDataDatabase;
        }

        [FunctionName("GenerateTaskMasters")]
        public IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log, ExecutionContext context)
        {
            Guid executionId = context.InvocationId;
            FrameworkRunner frp = new FrameworkRunner(log, executionId);

            FrameworkRunnerWorkerWithHttpRequest worker = GenerateTaskMastersCore;
            FrameworkRunnerResult result = frp.Invoke(req, "GenerateTaskMasters", worker);
            if (result.Succeeded)
            {
                return new OkObjectResult(JObject.Parse(result.ReturnObject));
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed...." });
            }

        }

        private dynamic GenerateTaskMastersCore(HttpRequest req, Logging.Logging logging)
        {
            string requestBody = new StreamReader(req.Body).ReadToEndAsync().Result;
            JObject data = JsonConvert.DeserializeObject<JObject>(requestBody);
            JArray tables = JArray.Parse(data["TableList"].ToString());
            JObject jsontemplate = JObject.Parse(data["JsonTemplate"].ToString());

            using DataTable dt = new DataTable();
            dt.Columns.Add(new DataColumn("TaskMasterName", typeof(string)));
            dt.Columns.Add(new DataColumn("TaskTypeId", typeof(Int64)));
            dt.Columns.Add(new DataColumn("TaskGroupId", typeof(Int64)));
            dt.Columns.Add(new DataColumn("ScheduleMasterId", typeof(Int64)));
            dt.Columns.Add(new DataColumn("SourceSystemId", typeof(Int64)));
            dt.Columns.Add(new DataColumn("TargetSystemId", typeof(Int64)));
            dt.Columns.Add(new DataColumn("DegreeOfCopyParallelism", typeof(Int16)));
            dt.Columns.Add(new DataColumn("AllowMultipleActiveInstances", typeof(bool)));
            dt.Columns.Add(new DataColumn("TaskDatafactoryIR", typeof(string)));
            dt.Columns.Add(new DataColumn("ActiveYN", typeof(bool)));
            dt.Columns.Add(new DataColumn("DependencyChainTag", typeof(string)));
            dt.Columns.Add(new DataColumn("DataFactoryId", typeof(Int64)));
            dt.Columns.Add(new DataColumn("TaskMasterJSON", typeof(string)));

            foreach (JToken t in tables)
            {
                DataRow dr = dt.NewRow();
                dr["TaskMasterName"] = jsontemplate["TaskMasterName"].ToString().Replace("{@TableSchema@}", t["TABLE_SCHEMA"].ToString()).Replace("{@TableName@}", t["TABLE_NAME"].ToString());
                dr["TaskTypeId"] = jsontemplate["TaskTypeId"];
                dr["TaskGroupId"] = jsontemplate["TaskGroupId"];
                dr["ScheduleMasterId"] = jsontemplate["ScheduleMasterId"];
                dr["SourceSystemId"] = jsontemplate["SourceSystemId"];
                dr["TargetSystemId"] = jsontemplate["TargetSystemId"];
                dr["DegreeOfCopyParallelism"] = jsontemplate["DegreeOfCopyParallelism"];
                dr["AllowMultipleActiveInstances"] = jsontemplate["AllowMultipleActiveInstances"];
                dr["TaskDatafactoryIR"] = jsontemplate["TaskDatafactoryIR"];
                dr["ActiveYN"] = jsontemplate["ActiveYN"];
                dr["DependencyChainTag"] = jsontemplate["DependencyChainTag"].ToString().Replace("{@TableSchema@}", t["TABLE_SCHEMA"].ToString()).Replace("{@TableName@}", t["TABLE_NAME"].ToString());
                dr["DataFactoryId"] = jsontemplate["DataFactoryId"];
                dr["TaskDatafactoryIR"] = jsontemplate["TaskDatafactoryIR"];

                JObject taskMasterJson = new JObject
                {
                    ["Source"] = JObject.Parse(JsonHelpers.GetStringValueFromJson(logging, "Source", jsontemplate, null, true).Replace("{@TableSchema@}", t["TABLE_SCHEMA"].ToString()).Replace("{@TableName@}", t["TABLE_NAME"].ToString())),
                    ["Target"] = JObject.Parse(JsonHelpers.GetStringValueFromJson(logging, "Target", jsontemplate, null, true).Replace("{@TableSchema@}", t["TABLE_SCHEMA"].ToString()).Replace("{@TableName@}", t["TABLE_NAME"].ToString()))
                };

                dr["TaskMasterJSON"] = JObject.Parse(taskMasterJson.ToString());

                dt.Rows.Add(dr);
            }

            string tempTableName = "#TempTaskMaster" + Guid.NewGuid().ToString();
            SqlTable tempSqlTable = new SqlTable
            {
                Name = tempTableName
            };
            SqlConnection con = _taskMetaDataDatabase.GetSqlConnection();
            TaskMetaDataDatabase.BulkInsert(dt, tempSqlTable, true, con);

            Dictionary<string, string> sqlParams = new Dictionary<string, string>
            {
                { "TempTableName", tempTableName }
            };

            string sql = GenerateSqlStatementTemplates.GetSql(Path.Combine(EnvironmentHelper.GetWorkingFolder(), _options.Value.LocalPaths.SQLTemplateLocation), "GenerateTaskMasters", sqlParams);
            TaskMetaDataDatabase.ExecuteSql(sql, con);

            return new { }; //Return Empty Object
        }
    }
}