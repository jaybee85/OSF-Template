using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Net.Http;
using System.Threading.Tasks;
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
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Table;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using SendGrid;
using SendGrid.Helpers.Mail;

namespace FunctionApp.Functions
{
    public class AzStorageCacheFileListHttpTrigger
    {
        private readonly IOptions<ApplicationOptions> _options;
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;

        public AzStorageCacheFileListHttpTrigger(IOptions<ApplicationOptions> options, TaskMetaDataDatabase taskMetaDataDatabase)
        {
            _options = options;
            _taskMetaDataDatabase = taskMetaDataDatabase;
        }

        [FunctionName("AZStorageCacheFileListHttpTrigger")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,  ILogger log, ExecutionContext context)
        {
            Guid executionId = context.InvocationId;
            FrameworkRunner frp = new FrameworkRunner(log, executionId);

            FrameworkRunnerWorkerWithHttpRequest worker = GetAzureStorageListingsCore;
            FrameworkRunnerResult result = await frp.Invoke(req, "AZStorageCacheFileListHttpTrigger", worker);
            if (result.Succeeded)
            {
                return new OkObjectResult(JObject.Parse(result.ReturnObject));
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed...." });
            }
        }



        public async Task<dynamic> GetAzureStorageListingsCore(HttpRequest req, Logging.Logging logging)
        {
            string requestBody = await new System.IO.StreamReader(req.Body).ReadToEndAsync();
            dynamic taskInformation = JsonConvert.DeserializeObject(requestBody);
            string taskInstanceId = taskInformation["TaskInstanceId"].ToString();
            string executionUid = taskInformation["ExecutionUid"].ToString();
            try
            {

                string storageAccountName = taskInformation["Source"]["StorageAccountName"];
                //The name is actually the base url so we need to parse it to get the name only
                storageAccountName = storageAccountName.Split('.')[0].Replace("https://", "");
                string storageAccountToken = taskInformation["Source"]["StorageAccountToken"];
                Int64 sourceSystemId = taskInformation["Source"]["SystemId"];

                using SqlConnection con = await _taskMetaDataDatabase.GetSqlConnection();

                var res = con.QueryWithRetry(
                    $"Select Max(PartitionKey) MaxPartitionKey from AzureStorageListing where SystemId = {sourceSystemId.ToString()}");

                string maxPartitionKey = DateTime.UtcNow.AddDays(-1).ToString("yyyy-MM-dd hh:mm");

                foreach (var r in res)
                {
                    if (r.MaxPartitionKey != null)
                    {
                        maxPartitionKey = DateTime.Parse(r.MaxPartitionKey).AddMinutes(-1).ToString("yyyy-MM-dd hh:mm");
                    }
                }

                using (HttpClient sourceClient = new HttpClient())
                {

                    //Now use the SAS URI to connect rather than the MSI / Service Principal as AD Based Auth not yet avail for tables
                    var storageCredentials = new StorageCredentials(storageAccountToken);
                    var sourceStorageAccount = new CloudStorageAccount(storageCredentials: storageCredentials, accountName: storageAccountName, endpointSuffix: "core.windows.net", useHttps: true);
                    var client = sourceStorageAccount.CreateCloudTableClient();

                    CloudTable table = client.GetTableReference("Filelist");

                    TableQuery<DynamicTableEntity> query = new TableQuery<DynamicTableEntity>().Where(TableQuery.GenerateFilterCondition("PartitionKey", QueryComparisons.GreaterThan, maxPartitionKey.ToString()));

                    using DataTable dt = new DataTable();
                    DataColumn dc = new DataColumn();
                    dc.ColumnName = "PartitionKey";
                    dc.DataType = typeof(string);
                    dt.Columns.Add(dc);
                    DataColumn dc1 = new DataColumn();
                    dc1.ColumnName = "RowKey";
                    dc1.DataType = typeof(string);
                    dt.Columns.Add(dc1);
                    DataColumn dc2 = new DataColumn();
                    dc2.ColumnName = "SystemId";
                    dc2.DataType = typeof(Int64);
                    dt.Columns.Add(dc2);
                    DataColumn dc3 = new DataColumn();
                    dc3.ColumnName = "FilePath";
                    dc3.DataType = typeof(string);
                    dt.Columns.Add(dc3);

                    string filelist = "";
                    TableContinuationToken token = null;
                    do
                    {
                        TableQuerySegment<DynamicTableEntity> resultSegment = await table.ExecuteQuerySegmentedAsync(query, token);
                        token = resultSegment.ContinuationToken;

                        //load into data table
                        foreach (var entity in resultSegment.Results)
                        {

                            DataRow dr = dt.NewRow();
                            dr["PartitionKey"] = entity.PartitionKey;
                            dr["RowKey"] = entity.RowKey;
                            dr["SystemId"] = sourceSystemId;
                            dr["FilePath"] = entity.Properties["FilePath"].StringValue;
                            dt.Rows.Add(dr);
                            filelist += entity.Properties["FilePath"].StringValue + Environment.NewLine;

                        }
                    } while (token != null);


                    if (dt.Rows.Count > 0)
                    {
                        SqlTable t = new SqlTable();
                        t.Schema = "dbo";
                        string tableGuid = Guid.NewGuid().ToString();
                        t.Name = $"#AzureStorageListing{tableGuid}";

                        TaskMetaDataDatabase.BulkInsert(dt, t, true, con);
                        Dictionary<string, string> sqlParams = new Dictionary<string, string>
                        {
                            { "TempTable", t.QuotedSchemaAndName() },
                            { "SourceSystemId", sourceSystemId.ToString()}
                        };

                        string mergeSql = GenerateSqlStatementTemplates.GetSql(System.IO.Path.Combine(EnvironmentHelper.GetWorkingFolder(), _options.Value.LocalPaths.SQLTemplateLocation), "MergeIntoAzureStorageListing", sqlParams);
                        con.ExecuteWithRetry(mergeSql, 120);
                        if ((JArray)taskInformation["Alerts"] != null)
                        {
                            foreach (var jToken in (JArray)taskInformation["Alerts"])
                            {
                                var alert = (JObject)jToken;
                                //Only Send out for Operator Level Alerts
                                if (alert["AlertCategory"].ToString() == "Task Specific Operator Alert")
                                {
                                    await AlertOperator(sourceSystemId, alert["AlertEmail"].ToString(), "", filelist);
                                }
                            }
                        }
                    }

                    con.Close();
                    con.Dispose();
                    await _taskMetaDataDatabase.LogTaskInstanceCompletion(Convert.ToInt64(taskInstanceId), Guid.Parse(executionUid), TaskInstance.TaskStatus.Complete, Guid.Empty, "");


                }
            }

            catch (Exception e)
            {
                logging.LogErrors(e);
                _taskMetaDataDatabase.LogTaskInstanceCompletion(Convert.ToInt64(taskInstanceId), Guid.Parse(executionUid), TaskInstance.TaskStatus.FailedRetry, Guid.Empty, "Failed when trying to Generate Sas URI and Send Email");

                JObject root = new JObject
                {
                    ["Result"] = "Failed"
                };

                return root;

            }
            return new { };

        }



        public static async Task AlertOperator(Int64 SourceSystemId, string EmailRecipient, string EmailRecipientName, string FileList)
        {
            //Send Email 
            string senderEmail = Environment.GetEnvironmentVariable("DefaultSentFromEmailAddress");
            string senderDescription = Environment.GetEnvironmentVariable("DefaultSentFromEmailName"); ;
            string subject = $"New files in Watched Azure Storage account. SourceSystemId is {SourceSystemId}";

            string plainTextContent =
                $"New files have been dropped into a watched Azure Storage account. SourceSystemId is {SourceSystemId}. Files found are: {Environment.NewLine}{FileList}";

            var apiKey = Environment.GetEnvironmentVariable("SENDGRID_APIKEY");
            var client = new SendGridClient(apiKey);
            var msg = new SendGridMessage()
            {
                From = new EmailAddress(senderEmail, senderDescription),
                Subject = subject,
                PlainTextContent = plainTextContent
            };
            msg.AddTo(new EmailAddress(EmailRecipient, EmailRecipientName));
            var res = await client.SendEmailAsync(msg);

        }

    }

}