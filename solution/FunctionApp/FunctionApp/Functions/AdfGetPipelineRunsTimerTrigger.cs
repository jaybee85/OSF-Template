using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using FormatWith;
using FunctionApp.DataAccess;
using FunctionApp.Helpers;
using FunctionApp.Models;
using FunctionApp.Models.Options;
using FunctionApp.Services;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Functions
{
    /// <summary>
    /// The purpose of this function is to periodically query the log analytics workspace for the solution and copy
    /// the details of ADF pipeline executions into the ADFPipelineRun table.
    /// </summary>
    public class AdfGetPipelineRunsTimerTrigger
    {
        private readonly IOptions<ApplicationOptions> _appOptions;
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;
        private readonly IHttpClientFactory _httpClientFactory;

        public AdfGetPipelineRunsTimerTrigger(IOptions<ApplicationOptions> appOptions, TaskMetaDataDatabase taskMetaDataDatabase, IHttpClientFactory httpClientFactory)
        {
            _appOptions = appOptions;
            _taskMetaDataDatabase = taskMetaDataDatabase;
            _httpClientFactory = httpClientFactory;
        }

        [FunctionName("GetADFPipelineRunsTimerTrigger")]
        public async Task Run([TimerTrigger("0 */5 * * * *")] TimerInfo myTimer, ILogger log, ExecutionContext context)
        {
            Guid executionId = context.InvocationId;

            if (_appOptions.Value.TimerTriggers.EnableGetADFStats)
            {
                FrameworkRunner fr = new FrameworkRunner(log, executionId);
                FrameworkRunnerWorker worker = GetAdfPipelineRuns;
                FrameworkRunnerResult result = await fr.Invoke("GetADFPipelineRunsTimerTrigger", worker);
            }
        }

        public async Task<dynamic> GetAdfPipelineRuns(Logging.Logging logging)
        {
            using var client = _httpClientFactory.CreateClient(HttpClients.LogAnalyticsHttpClientName);
            if (client.DefaultRequestHeaders.Authorization == null)
            {
                await Task.Delay(2000);
            }
            using SqlConnection conRead = await _taskMetaDataDatabase.GetSqlConnection();

            //Get Last Request Date
            var maxTimesGen = conRead.QueryWithRetry(@"
                                    Select a.*,  MaxPipelineTimeGenerated from 
                                        ExecutionEngine a left join 
                                        ( Select b.EngineId, MaxPipelineTimeGenerated = Max(MaxPipelineTimeGenerated) 
                                        from ADFPipelineRun b
                                        group by b.EngineId) b on a.EngineId = b.EngineId");

            DateTimeOffset maxPipelineTimeGenerated = DateTimeOffset.UtcNow.AddDays(-30);


            foreach (var executionengine in maxTimesGen)
            {
                if (executionengine.MaxPipelineTimeGenerated != null)
                {
                    maxPipelineTimeGenerated = ((DateTimeOffset)executionengine.MaxPipelineTimeGenerated).AddMinutes(-180);
                }

                string workspaceId = executionengine.LogAnalyticsWorkspaceId.ToString();

                Dictionary<string, object> kqlParams = new Dictionary<string, object>
                {
                    {"MaxPipelineTimeGenerated", maxPipelineTimeGenerated.ToString("yyyy-MM-dd HH:mm:ss.ff K") },
                    {"SubscriptionId", ((string)executionengine.SubscriptionUid.ToString()).ToUpper()},
                    {"ResourceGroupName", ((string)executionengine.ResourceGroup.ToString()).ToUpper() },
                    {"EngineName", ((string)executionengine.EngineName.ToString()).ToUpper() },
                    {"EngineId", executionengine.EngineId.ToString()  }
                };
                string kql = "";
                switch (executionengine.SystemType.ToString())
                {
                    case "Datafactory":
                        kql = File.ReadAllText(Path.Combine(Path.Combine(EnvironmentHelper.GetWorkingFolder(), _appOptions.Value.LocalPaths.KQLTemplateLocation), "GetADFPipelineRuns.kql"));
                        break;
                    case "Synapse":
                        kql = File.ReadAllText(Path.Combine(Path.Combine(EnvironmentHelper.GetWorkingFolder(), _appOptions.Value.LocalPaths.KQLTemplateLocation), "GetSynapsePipelineRuns.kql"));
                        break;
                }

                kql = kql.FormatWith(kqlParams, MissingKeyBehaviour.ThrowException, null, '{', '}');

                JObject jsonContent = new JObject();
                jsonContent["query"] = kql;

                var postContent = new StringContent(jsonContent.ToString(), System.Text.Encoding.UTF8, "application/json");

                var response = await client.PostAsync($"https://api.loganalytics.io/v1/workspaces/{workspaceId}/query", postContent);

                logging.LogInformation(response.ToString());

                if (response.StatusCode == System.Net.HttpStatusCode.OK)
                {
                    //Start to parse the response content
                    HttpContent responseContent = response.Content;
                    var content = await response.Content.ReadAsStringAsync();
                    var tables = ((JArray)(JObject.Parse(content)["tables"]));

                    if (tables.Count > 0)
                    {
                        using DataTable dt = new DataTable();

                        var rows = (JArray)(tables[0]["rows"]);
                        var columns = (JArray)(tables[0]["columns"]);
                        foreach (JObject c in columns)
                        {
                            DataColumn dc = new DataColumn();
                            dc.ColumnName = c["name"].ToString();
                            dc.DataType = GetAdfStats.GetKustoDataTypeMapper[c["type"].ToString()];
                            dt.Columns.Add(dc);
                        }

                        foreach (JArray r in rows)
                        {
                            DataRow dr = dt.NewRow();
                            for (int i = 0; i < columns.Count; i++)
                            {
                                dr[i] = ((JValue)r[i]).Value;
                            }
                            dt.Rows.Add(dr);
                        }

                        SqlTable t = new SqlTable();
                        t.Schema = "dbo";
                        string tableGuid = Guid.NewGuid().ToString();
                        t.Name = $"#ADFPipelineRun{tableGuid}";
                        using (SqlConnection conWrite = await _taskMetaDataDatabase.GetSqlConnection())
                        {
                            TaskMetaDataDatabase.BulkInsert(dt, t, true, conWrite);
                            Dictionary<string, string> sqlParams = new Dictionary<string, string>
                            {
                                { "TempTable", t.QuotedSchemaAndName() },
                                { "EngineId", executionengine.EngineId.ToString()}
                            };

                            string mergeSql = GenerateSqlStatementTemplates.GetSql(Path.Combine(EnvironmentHelper.GetWorkingFolder(), _appOptions.Value.LocalPaths.SQLTemplateLocation), "MergeIntoADFPipelineRun", sqlParams);

                            conWrite.ExecuteWithRetry(mergeSql);
                            conWrite.Close();
                            conWrite.Dispose();
                        }

                    }

                    else
                    {
                        logging.LogErrors(new Exception("Kusto query failed getting ADFPipeline Stats."));
                    }
                }
            }

            return new { };

        }

    }
}