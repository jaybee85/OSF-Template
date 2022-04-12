using System;
using System.Data.SqlClient;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using FunctionApp.DataAccess;
using FunctionApp.Models.Options;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace FunctionApp.Functions
{
    /// <summary>
    /// The purpose of this function is to perform the execution of scheduled task instances. It simply iterates over the
    /// available task runners and triggers them to begin executing their tasks
    /// </summary>
    // Azure Function, don't delete unused class/method 
    // ReSharper disable once UnusedMember.Global
    public class AdfRunFrameworkTasksTimerTrigger
    {
        private readonly IOptions<ApplicationOptions> _options;
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;
        private readonly IHttpClientFactory _httpClientFactory;

        public AdfRunFrameworkTasksTimerTrigger(IOptions<ApplicationOptions> options, TaskMetaDataDatabase taskMetaDataDatabase, IHttpClientFactory httpClientFactory)
        {
            _options = options;
            _taskMetaDataDatabase = taskMetaDataDatabase;
            _httpClientFactory = httpClientFactory;
        }

        /// <summary>
        ///             "0 */5 * * * *" once every five minutes
        ///              "0 0 * * * *"   once at the top of every hour
        ///              "0 0 */2 * * *" once every two hours
        ///              "0 0 9-17 * * *"    once every hour from 9 AM to 5 PM
        ///              "0 30 9 * * *"  at 9:30 AM every day
        ///              "0 30 9 * * 1-5"    at 9:30 AM every weekday
        ///              "0 30 9 * Jan Mon"  at 9:30 AM every Monday in January
        /// 
        /// </summary>
        /// <param name="myTimer"></param>
        /// <param name="log"></param>
        /// <param name="context"></param>
        [FunctionName("RunFrameworkTasksTimerTrigger")]         
        public async Task Run([TimerTrigger("0 */2 * * * *")] TimerInfo myTimer, ILogger log, ExecutionContext context)
        {
           await Core(log);        
        }

        public async Task Core(ILogger log)
        {
            //log.LogInformation("FunctionAppDirectory:" + context.FunctionAppDirectory);
            if (_options.Value.TimerTriggers.EnableRunFrameworkTasks)
            {
                using var client = _httpClientFactory.CreateClient(HttpClients.CoreFunctionsHttpClientName);
                if (client.DefaultRequestHeaders.Authorization == null)
                {
                    await Task.Delay(2000);
                }

                using SqlConnection con = await _taskMetaDataDatabase.GetSqlConnection();

                // Get a list of framework task runners that are currently idle
                var frameworkTaskRunners = con.QueryWithRetry("Exec dbo.GetFrameworkTaskRunners");

                foreach (var runner in frameworkTaskRunners)
                {
                    int taskRunnerId = ((dynamic)runner).TaskRunnerId;
                    using (FileStream fs = File.Create($"./runners/hb_{taskRunnerId.ToString()}_{DateTime.Now.ToString("yyyyMMddhhmm")}.txt"))
                    {
                        Byte[] info = new System.Text.UTF8Encoding(true).GetBytes("");
                        fs.Write(info, 0, info.Length);
                    }


                    try
                    {
                        // Trigger the Http triggered function
                        var secureFunctionApiurl = $"{_options.Value.ServiceConnections.CoreFunctionsURL}/api/RunFrameworkTasksHttpTrigger?TaskRunnerId={taskRunnerId}";

                        using HttpRequestMessage httpRequestMessage = new HttpRequestMessage
                        {
                            Method = HttpMethod.Get,
                            RequestUri = new Uri(secureFunctionApiurl)
                        };

                        //Todo Add some error handling in case function cannot be reached. Note Wait time is there to provide sufficient time to complete post before the HttpClientFactory is disposed.
                        var httpTask = client.SendAsync(httpRequestMessage).Wait(3000);

                    }
                    catch (Exception)
                    {
                        con.ExecuteWithRetry($"[dbo].[UpdFrameworkTaskRunner] {taskRunnerId}");
                        throw;
                    }
                }
            }
        }


    }
}