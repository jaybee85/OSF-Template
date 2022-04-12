using Microsoft.Azure.Management.Synapse;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using FunctionApp.Authentication;
using FunctionApp.Models.Options;
using Microsoft.Extensions.Options;
using Microsoft.Rest;
using System.Net.Http.Headers;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net.Http;
using Azure.Analytics.Synapse.Artifacts;
using Azure.Core;
using Microsoft.Azure.Management.DataFactory.Models;
using System.Linq;
using FunctionApp.Functions;
using FunctionApp.DataAccess;

namespace FunctionApp.Services
{
    public class AzureSynapseService
    {
        private readonly IAzureAuthenticationProvider _authProvider;
        private readonly IOptions<ApplicationOptions> _options;
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;

        public AzureSynapseService(IAzureAuthenticationProvider authProvider, IOptions<ApplicationOptions> options, TaskMetaDataDatabase taskMetaDataDatabase)
        {
            _authProvider = authProvider;
            _options = options;
            _taskMetaDataDatabase = taskMetaDataDatabase;
        }
        public async Task StartStopSynapseSqlPool(string SubscriptionId, string ResourceGroupName, string SynapseWorkspaceName, string SynapsePoolName, string Action, Logging.Logging logging)
        {
            try
            {
                string token = await _authProvider.GetAzureRestApiToken("https://management.azure.com/").ConfigureAwait(false);
                ServiceClientCredentials cred = new TokenCredentials(token);

                //https://management.azure.com/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.Synapse/workspaces/{workspace-name}/sqlPools/{database-name}/pause?api-version=2019-06-01-preview

                SynapseManagementClient synapseManagementClient = new SynapseManagementClient(cred);
                synapseManagementClient.SubscriptionId = SubscriptionId;
                //ToDo Add error handling
                var sqlPool = synapseManagementClient.SqlPools.Get(ResourceGroupName, SynapseWorkspaceName, SynapsePoolName);
                logging.LogInformation($"Synapse SQL pool ({SynapsePoolName}) is currently: {sqlPool.Status}");
                if (sqlPool.Status == "Paused" || sqlPool.Status == "Pausing")
                {
                    if (Action.ToLower() == "start")
                    {
                        logging.LogInformation($"Attempting to {Action} ({SynapsePoolName})");
                        synapseManagementClient.SqlPools.Resume(ResourceGroupName, SynapseWorkspaceName, SynapsePoolName);
                        logging.LogInformation($"{SynapsePoolName} now has the status: {sqlPool.Status}");
                    }
                    else
                    {
                        Exception error = new Exception("Cannot execute a " + Action + " action on the dedicated pool " + SynapsePoolName + ". Current status of pool: " + sqlPool.Status);
                        logging.LogErrors(error);
                        throw error;
                    }

                }
                else if (sqlPool.Status == "Online" || sqlPool.Status == "Resuming")
                {
                    if (Action.ToLower() == "pause")
                    {
                        logging.LogInformation($"Attempting to {Action} ({SynapsePoolName})");
                        synapseManagementClient.SqlPools.Pause(ResourceGroupName, SynapseWorkspaceName, SynapsePoolName);
                        logging.LogInformation($"{SynapsePoolName} now has the status: {sqlPool.Status}");
                    }
                    else
                    {
                        Exception error = new Exception("Cannot execute a " + Action + " action on the dedicated pool " + SynapsePoolName + ". Current status of pool: " + sqlPool.Status);
                        logging.LogErrors(error);
                        throw error;
                    }
                }



            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                logging.LogErrors(new Exception($"Initiation of SQLPool command failed for SqlPool: {SynapsePoolName} and Workspase: {SynapseWorkspaceName}" ));
                throw;

            }
        } 

        public async Task<string> RunSynapsePipeline(Uri endpoint, string pipelineName, Dictionary<string, object> pipelineParams, Logging.Logging logging)
        {
            
            try
            {
                string token = await _authProvider.GetAzureRestApiToken("https://dev.azuresynapse.net").ConfigureAwait(false); 
                HttpClient c = new HttpClient();
                c.DefaultRequestHeaders.Accept.Clear();
                c.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                c.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
                JObject jsonContent = new JObject();
                jsonContent["TaskObject"] = JsonConvert.SerializeObject(pipelineParams["TaskObject"]);
                var postContent = new StringContent(jsonContent.ToString(), System.Text.Encoding.UTF8, "application/json");
                HttpResponseMessage response = await c.PostAsync($"{endpoint.ToString()}/pipelines/{pipelineName}/createRun?api-version=2020-12-01", postContent);
                HttpContent responseContent = response.Content;
                var status = response.StatusCode;
                var content = await responseContent.ReadAsStringAsync();
                if (response.StatusCode != System.Net.HttpStatusCode.Accepted)
                {
                    throw new Exception($"Synapse Pipeline Activation via Rest Failed. StatusCode: {status}; Message: {content}");
                }

                return content;

            }
            catch (Exception e)
            {
                logging.LogErrors(e);                
                throw e;
            }

        }

        public async Task StartSparkSession(Uri endpoint, string sessionName,  string poolName, Logging.Logging logging)
        {

            try
            {
                var c = await GetSynapseClient();
                //TODO: Need to centralise this information so that multiple function executions do not pick up the same idle sesson.. for now will put into a static maybe
                //Get Idle Sessions
                JObject sessions = JObject.Parse(await GetFromSynapseApi(endpoint, $"livyApi/versions/2019-01-01/sparkPools/{poolName}/sessions?detailed=True", logging));
                int sessionCount = 0;
                string idleSession = "";
                foreach (JObject s in sessions["sessions"])
                {
                    if (Helpers.JsonHelpers.CheckForJsonProperty("livyInfo", s))
                    {
                        JObject li = (JObject)s["livyInfo"];
                        if (Helpers.JsonHelpers.CheckForJsonProperty("startingAt", li))
                        {
                            var timeSinceStarted = (DateTime.Now - (DateTime)s["livyInfo"]["startingAt"]).TotalSeconds;
                            if (s["state"].ToString() == "idle" & timeSinceStarted > 180)
                            {                                
                                idleSession = s["id"].ToString();
                                logging.LogInformation($"PreExisting Session number {idleSession} Selected");
                                sessionCount += 1;
                            }
                            if (s["state"].ToString() == "idle" & timeSinceStarted <= 180)
                            {
                                logging.LogInformation($"PreExisting Session number {s["id"].ToString()} Ignored as it has only just been created and will most likely be used by its creator.");
                                sessionCount += 1;
                            }
                            if (s["state"].ToString() == "busy")
                            {
                                sessionCount += 1;
                                logging.LogInformation($"PreExisting Session number {s["id"].ToString()} Ignored as it is busy.");
                            }
                        }
                    }
                }

                

                if (sessionCount > 5)
                {
                    //TODO: Throw Error && Fail the task -- Set task to untried with message that there are no spark sessions available
                    // await _taskMetaDataDatabase.LogTaskInstanceCompletion((Int64)taskInstanceId, (Guid)postObjectExecutionUid, taskStatus, (Guid)adfRunUid, (String)comment);
                }


                //If no idle sessions then create new one
                if (string.IsNullOrEmpty(idleSession) && (sessionCount <=5))
                {
                    var startTimer = DateTime.Now;
                    string jsonContent = "{\"tags\": null,\"Name\": \"" + sessionName + "\", \"driverMemory\": \"4g\",  \"driverCores\": 4,  \"executorMemory\": \"2g\", \"executorCores\": 2, \"numExecutors\": 2, \"artifactId\": \"dldj\"}";                    
                    JObject newSession = JObject.Parse(await PostToSynapseApi(endpoint, $"livyApi/versions/2019-11-01-preview/sparkPools/{poolName}/sessions?detailed=True", jsonContent, logging));
                    idleSession = newSession["id"].ToString();
                    //Wait for session to start
                    if (newSession["state"].ToString() == "not_started")
                    {                                                
                        //Will Wait for up to 100 seconds
                        for(int i = 0; i < 20; i++)
                        {
                            await Task.Delay(5000);
                            var startUpTime = (DateTime.Now - startTimer).TotalSeconds;
                            JObject session = JObject.Parse(await GetFromSynapseApi(endpoint, $"livyApi/versions/2019-01-01/sparkPools/{poolName}/sessions/{idleSession}", logging));
                            if (session["state"].ToString() == "idle")
                            {
                                logging.LogInformation($"Session {idleSession} Started in {startUpTime.ToString()} seconds.");
                                //Wait a tiny bit longer just to make sure session is ready
                                await Task.Delay(5000);
                                break;
                            }
                            else
                            {
                                logging.LogInformation($"Waiting for Session {idleSession}. Current state is {session["state"].ToString()}");
                            }
                        }
                    }

                }

                //Run code
                //TODO: Get the notebook and consolidate all cells into single statement
                string code = "{\"code\": \"print('Hello')\", \"kind\":\"pyspark\"}";                
                JObject statement = JObject.Parse(await PostToSynapseApi(endpoint, $"livyApi/versions/2019-11-01-preview/sparkPools/{poolName}/sessions/{idleSession}/statements", code, logging));
                logging.LogInformation("Statement Created");

            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                throw e;
            }

        }

        public async Task<string> PostToSynapseApi(Uri endpoint,  string Path, string postContent, Logging.Logging logging)
        {

            try
            {
                var c = await GetSynapseClient();
                JObject jsonContent = new JObject();
                jsonContent = JObject.Parse(postContent);
                var postStringContent = new StringContent(jsonContent.ToString(), System.Text.Encoding.UTF8, "application/json");
                HttpResponseMessage response = await c.PostAsync($"{endpoint.ToString()}/{Path}", postStringContent);
                HttpContent responseContent = response.Content;
                var status = response.StatusCode;
                var content = await responseContent.ReadAsStringAsync();
                if (response.StatusCode != System.Net.HttpStatusCode.Accepted && response.StatusCode != System.Net.HttpStatusCode.OK)
                {
                    throw new Exception($"PostToSynapseApi Failed via Rest Failed. StatusCode: {status}; Message: {content}");
                }

                return content;

            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                throw e;
            }

        }

        public async Task<string> GetFromSynapseApi(Uri endpoint, string Path, Logging.Logging logging)
        {

            try
            {
                var c = await GetSynapseClient();                
                HttpResponseMessage response = await c.GetAsync($"{endpoint.ToString()}/{Path}");
                HttpContent responseContent = response.Content;
                var status = response.StatusCode;
                var content = await responseContent.ReadAsStringAsync();
                if (response.StatusCode != System.Net.HttpStatusCode.Accepted && response.StatusCode != System.Net.HttpStatusCode.OK)
                {
                    throw new Exception($"GetFromSynapseApi Failed via Rest Failed. StatusCode: {status}; Message: {content}");
                }

                return content;

            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                throw e;
            }

        }


        public async Task<string> GetSparkSession(Uri endpoint, string SessionName, Logging.Logging logging)
        {

            try
            {
                var c = await GetSynapseClient();

                HttpResponseMessage response = await c.GetAsync($"{endpoint.ToString()}/livyApi/versions/2019-11-01-preview/sparkPools/adsdevsynspads/sessions?detailed=True");
                HttpContent responseContent = response.Content;
                var status = response.StatusCode;
                var content = await responseContent.ReadAsStringAsync();
                if (response.StatusCode != System.Net.HttpStatusCode.Accepted)
                {
                    throw new Exception($"Synapse Pipeline Activation via Rest Failed. StatusCode: {status}; Message: {content}");
                }

                return content;

            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                throw e;
            }

        }

        public async Task<HttpClient> GetSynapseClient()
        {
            string token = await _authProvider.GetAzureRestApiToken("https://dev.azuresynapse.net");
            HttpClient c = new HttpClient();
            c.DefaultRequestHeaders.Accept.Clear();
            c.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            c.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            return c;
        }
    }
}
