/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using FunctionApp.Authentication;
using FunctionApp.DataAccess;
using FunctionApp.Helpers;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.Azure.Management.DataFactory.Models;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Services
{
    public class DataFactoryPipelineProvider
    {
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;
        private readonly IAzureAuthenticationProvider _authProvider;
        private readonly DataFactoryClientFactory _dataFactoryClientFactory;

        public DataFactoryPipelineProvider(TaskMetaDataDatabase taskMetaDataDatabase, IAzureAuthenticationProvider authProvider, DataFactoryClientFactory dataFactoryClientFactory)
        {
            _taskMetaDataDatabase = taskMetaDataDatabase;
            _authProvider = authProvider;
            _dataFactoryClientFactory = dataFactoryClientFactory;
        }
        public async Task QueryPipelineRuns(string subscriptionId, string resourceGroup, string factoryName, string runGroupId, DateTime startDt, DateTime endDt, Logging.Logging logging)
        {
            #region QueryPipelineRuns

            logging.LogInformation("Query ADF Pipeline Runs.");
            string outputString = string.Empty;

            DataTable dt = new DataTable();
            dt.Columns.Add(new DataColumn("ExecutionUid", typeof(Guid)));
            dt.Columns.Add(new DataColumn("TaskInstanceId", typeof(Int64)));
            dt.Columns.Add(new DataColumn("TaskMasterId", typeof(Int64)));
            dt.Columns.Add(new DataColumn("DurationInMs", typeof(Int64)));
            dt.Columns.Add(new DataColumn("IsLastest", typeof(Boolean)));
            dt.Columns.Add(new DataColumn("LastUpdated", typeof(DateTime)));
            dt.Columns.Add(new DataColumn("RunId", typeof(Guid)));
            dt.Columns.Add(new DataColumn("PipelineName", typeof(String)));
            dt.Columns.Add(new DataColumn("RunStart", typeof(DateTime)));
            dt.Columns.Add(new DataColumn("RunEnd", typeof(DateTime)));
            dt.Columns.Add(new DataColumn("RunDimensions", typeof(String)));
            dt.Columns.Add(new DataColumn("Status", typeof(String)));


            DataTable activityDt = new DataTable();
            activityDt.Columns.Add(new DataColumn("ActivityName", typeof(String)));
            activityDt.Columns.Add(new DataColumn("RunId", typeof(Guid)));
            activityDt.Columns.Add(new DataColumn("ActivityRunStart", typeof(DateTime)));
            activityDt.Columns.Add(new DataColumn("ActivityRunEnd", typeof(DateTime)));
            activityDt.Columns.Add(new DataColumn("ActivityRunId", typeof(Guid)));
            activityDt.Columns.Add(new DataColumn("ActivityType", typeof(String)));
            activityDt.Columns.Add(new DataColumn("DurationInMs", typeof(Int64)));
            activityDt.Columns.Add(new DataColumn("OutPut", typeof(String)));
            activityDt.Columns.Add(new DataColumn("PipelineName", typeof(String)));
            activityDt.Columns.Add(new DataColumn("PipelineRunId", typeof(String)));
            activityDt.Columns.Add(new DataColumn("Status", typeof(String)));

            using (var client = await _dataFactoryClientFactory.CreateDataFactoryClient(subscriptionId).ConfigureAwait(false))
            {
                //Get pipeline status with provided run id
                RunFilterParameters filterParameterActivityRuns = new RunFilterParameters();
                filterParameterActivityRuns.LastUpdatedAfter = startDt;
                filterParameterActivityRuns.LastUpdatedBefore = endDt.AddHours(+2);

                RunFilterParameters filterParameter = new RunFilterParameters();
                filterParameter.LastUpdatedAfter = startDt;
                filterParameter.LastUpdatedBefore = endDt;

                IList<string> rungroupid = new List<string> { runGroupId };
                IList<RunQueryFilter> filter = new List<RunQueryFilter>();
                filter.Add(new RunQueryFilter
                {
                    Operand = RunQueryFilterOperand.RunGroupId,
                    OperatorProperty = RunQueryFilterOperator.Equals,
                    Values = rungroupid
                });

                filterParameter.Filters = filter;

                logging.LogInformation("API PipelineRuns.QueryByFactory Start");
                var pipelineRunsQueryResponse = client.PipelineRuns.QueryByFactory(resourceGroup, factoryName, filterParameter);
                logging.LogInformation("API PipelineRuns.QueryByFactory End");
                var enumerator = pipelineRunsQueryResponse.Value.GetEnumerator();
                int item = 0;

                while (true)
                {
                    for (bool hasMoreRuns = enumerator.MoveNext(); hasMoreRuns;)
                    {
                        var pipelineRuns = enumerator.Current;
                        hasMoreRuns = enumerator.MoveNext();
                        var runId = pipelineRuns.RunId;
                        item += 1;

                        logging.LogInformation(
                            $"PipelineRuns.QueryByFactory RunId {runId} Current Item {item} of {pipelineRunsQueryResponse.Value.Count}");

                        DataRow dr = dt.NewRow();
                        string param = string.Empty;
                        foreach (var element in pipelineRuns.Parameters)
                        {
                            param = element.Value;
                            break;
                        }
                        dr["ExecutionUid"] = JsonHelpers.GetStringValueFromJson(logging, "ExecutionUid", JObject.Parse(param), null, true);
                        dr["TaskInstanceId"] = JsonHelpers.GetStringValueFromJson(logging, "TaskInstanceId", JObject.Parse(param), null, true);
                        dr["TaskMasterId"] = JsonHelpers.GetStringValueFromJson(logging, "TaskMasterId", JObject.Parse(param), null, true);
                        dr["DurationInMs"] = pipelineRuns.DurationInMs ?? (object)DBNull.Value;
                        dr["IsLastest"] = pipelineRuns.IsLatest ?? (object)DBNull.Value;
                        dr["LastUpdated"] = pipelineRuns.LastUpdated ?? (object)DBNull.Value;
                        dr["RunId"] = pipelineRuns.RunId;
                        dr["PipelineName"] = pipelineRuns.PipelineName ?? (object)DBNull.Value;
                        dr["RunStart"] = pipelineRuns.RunStart ?? (object)DBNull.Value;
                        dr["RunEnd"] = pipelineRuns.RunEnd ?? (object)DBNull.Value;
                        dr["RunDimensions"] = pipelineRuns.PipelineName ?? (object)DBNull.Value;
                        dr["Status"] = pipelineRuns.Status ?? (object)DBNull.Value;
                        dt.Rows.Add(dr);

                        QueryActivityRuns(subscriptionId, resourceGroup, factoryName, runId, runId, filterParameterActivityRuns, logging, ref activityDt);
                    }


                    if (pipelineRunsQueryResponse.ContinuationToken == null)
                        break;

                    filterParameter.ContinuationToken = pipelineRunsQueryResponse.ContinuationToken;
                    pipelineRunsQueryResponse = client.PipelineRuns.QueryByFactory(resourceGroup, factoryName, filterParameter);
                    enumerator = pipelineRunsQueryResponse.Value.GetEnumerator();
                    item = 0;
                }

            }

            if (activityDt.Rows.Count > 0)
            {
                string tempTableName = "#Temp_ADFActivities_" + Guid.NewGuid().ToString();
                _taskMetaDataDatabase.AutoBulkInsertAndMerge(activityDt, tempTableName, "ADFActivity");
            }


            if (dt.Rows.Count > 0)
            {
                string tempTableName = "#Temp_ADFPipelineRun_" + Guid.NewGuid().ToString();
                _taskMetaDataDatabase.AutoBulkInsertAndMerge(dt, tempTableName, "ADFPipelineRun");
            }

            #endregion

        }

        private void QueryActivityRuns(string subscriptionId, string resourceGroup, string factoryName, string runId, string parentRunId, RunFilterParameters filterParameterActivityRuns, Logging.Logging logging, ref DataTable dt)
        {
            logging.LogInformation($"QueryActivityRuns - RunId {runId}");

            using var client = _dataFactoryClientFactory.CreateDataFactoryClient(subscriptionId).Result;

            //Get pipeline status with provided run id
            logging.LogInformation($"QueryActivityRuns - RunId {runId} - API QueryByPipelineRun Start");
            ActivityRunsQueryResponse activityRunsQueryResponse = client.ActivityRuns.QueryByPipelineRun(resourceGroup, factoryName, runId, filterParameterActivityRuns);
            logging.LogInformation($"QueryActivityRuns - RunId {runId} - API QueryByPipelineRun End");
            var enumeratorActivity = activityRunsQueryResponse.Value.GetEnumerator();

            for (bool hasMoreActivityRuns = enumeratorActivity.MoveNext(); hasMoreActivityRuns;)
            {
                var activityRun = enumeratorActivity.Current;
                hasMoreActivityRuns = enumeratorActivity.MoveNext();

                DataRow dr = dt.NewRow();
                dr["ActivityName"] = activityRun.ActivityName ?? (object)DBNull.Value;
                dr["RunId"] = parentRunId;
                dr["ActivityRunStart"] = activityRun.ActivityRunStart ?? (object)DBNull.Value;
                dr["ActivityRunEnd"] = activityRun.ActivityRunEnd ?? (object)DBNull.Value;
                dr["ActivityRunId"] = activityRun.ActivityRunId ?? (object)DBNull.Value;
                dr["ActivityType"] = activityRun.ActivityType ?? (object)DBNull.Value;
                dr["DurationInMs"] = activityRun.DurationInMs ?? (object)DBNull.Value;
                dr["OutPut"] = activityRun.Output ?? (object)DBNull.Value;
                dr["PipelineName"] = activityRun.PipelineName ?? (object)DBNull.Value;
                dr["PipelineRunId"] = activityRun.PipelineRunId ?? (object)DBNull.Value;
                dr["Status"] = activityRun.Status ?? (object)DBNull.Value;
                dt.Rows.Add(dr);

                if (activityRun.ActivityType == "ExecutePipeline")
                {
                    string pipelineRunId = JsonHelpers.GetStringValueFromJson(logging, "pipelineRunId", (JObject)activityRun.Output, null, true);
                    if (!String.IsNullOrEmpty(pipelineRunId))
                        QueryActivityRuns(subscriptionId, resourceGroup, factoryName, pipelineRunId, parentRunId, filterParameterActivityRuns, logging, ref dt);
                    else
                        logging.LogInformation(
                            $"QueryActivityRuns - RunId Is null  for {(JObject)activityRun.Output} ");
                }
            }
        }


        public async Task<dynamic> GetLongRunningPipelines(Logging.Logging logging)
        {
            logging.LogDebug("Get GetActivePipelines called.");
            using var con = await _taskMetaDataDatabase.GetSqlConnection();
            dynamic res = con.QueryWithRetry(@" Select  * 
                from [dbo].[TaskInstanceExecution] 
                where Status in ('InProgress',  'Queued')
                and datediff(minute, StartDateTime, GetUtcDate()) > 30
                order by StartDateTime desc");
            return res;
        }
        /// <summary>
        /// Returns a list of long running pipelines. These will be checked to ensure that they are still in-progress.
        /// </summary>
        /// <param name="logging"></param>
        /// <returns></returns>
        public async Task<short> CountActivePipelines(Logging.Logging logging)
        {
            logging.LogDebug("Get CountActivePipelines called.");
            using var con = await _taskMetaDataDatabase.GetSqlConnection();
            IEnumerable<short> res = con.QueryWithRetry<short>(@"
            
            Select 
            count(*) ActiveCount 
            from [dbo].[TaskInstance] 
            where LastExecutionStatus in ('InProgress',  'Queued') or (LastExecutionStatus in ('Untried',  'FailedRetry') and TaskRunnerId is not null)

            ");
            return res.First();
        }
        public async Task<JObject> CheckPipelineStatus(string subscriptionId, string resourceGroup, string factoryName, string pipelineName, string runId, Logging.Logging logging)
        {
            //Create a data factory management client
            logging.LogInformation("Creating ADF connectivity client.");
            string outputString;

            using (var client = await _dataFactoryClientFactory.CreateDataFactoryClient(subscriptionId).ConfigureAwait(false))
            {
                //Get pipeline status with provided run id
                PipelineRun pipelineRun;
                pipelineRun = await client.PipelineRuns.GetAsync(resourceGroup, factoryName, runId);
                logging.LogInformation("Checking ADF pipeline status.");

                //Create simple status for Data Factory Until comparison checks
                string simpleStatus;

                if (pipelineRun.Status == "InProgress")
                {
                    simpleStatus = "Running";
                }
                else
                {
                    simpleStatus = "Done";
                }

                logging.LogInformation("ADF pipeline status: " + pipelineRun.Status);

                // TODO: Why build up the json as a string and then parse it? Why not create it as a json object from the start?
                //Final return detail
                outputString = "{ \"PipelineName\": \"" + pipelineName +
                                        "\", \"RunId\": \"" + pipelineRun.RunId +
                                        "\", \"SimpleStatus\": \"" + simpleStatus +
                                        "\", \"Status\": \"" + pipelineRun.Status +
                                        "\" }";

            }
            JObject outputJson = JObject.Parse(outputString);
            return outputJson;
        }
    }
}
