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
using System.IO;

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

        public async Task StartSparkSession(Uri endpoint, string taskName,  string poolName, Logging.Logging logging, string sessionFolder)
        {
            int tryCount = 0;
            while (tryCount < 10)
            { 
                var res = await StartSparkSessionCore(endpoint, taskName, poolName, logging, sessionFolder);
                if (res == "succeeded")
                {
                    logging.LogInformation("Task Named " + taskName + " Succeeded. Attempts: " + tryCount.ToString());
                    break; 
                }
                logging.LogWarning($"Task Named {taskName} Failed To Start. Result status was '{res}' Attempt Number {tryCount.ToString()}");
                tryCount++;
                await Task.Delay(1000);
            }
        }

        public async Task<string> StartSparkSessionCore(Uri endpoint, string taskName, string poolName, Logging.Logging logging, string sessionFolder)
        {

            try
            {
                var c = await GetSynapseClient();
                var guid = Guid.NewGuid();
                //Get Sessions Waiting To Start
                DirectoryInfo folder = Directory.CreateDirectory(Path.Combine(sessionFolder, "sessions"));
                var files = folder.GetFiles();
                var matchedFiles = files.Where(f => f.Name.StartsWith($"cs_"));
                int sessionsWaitingToStart = 0;
                List<int> snums = new List<int>();
                if (matchedFiles.Any())
                {
                    foreach (var f in matchedFiles)
                    {
                        int s = System.Convert.ToInt16(f.Name.Split("_")[1]);
                        snums.Add(s);
                    }

                    var snumsd = snums.Distinct();
                    sessionsWaitingToStart = snums.Max()+1;
                }

                //TODO: Need to centralise this information so that multiple function executions do not pick up the same idle sesson.. for now will put into a static maybe
                //Get Idle Sessions
                JObject sessions= new JObject();
                sessions["sessions"] = new JArray();
                int reqSessionCount = 20;
                int reqFromSession = 0;
                while (reqSessionCount >= 20)
                {
                    JObject tmpSessions = JObject.Parse(await GetFromSynapseApi(endpoint, $"livyApi/versions/2019-01-01/sparkPools/{poolName}/sessions?from={reqFromSession}&size=20&detailed=True", logging));
                    foreach (var s in tmpSessions["sessions"])
                    {
                        ((JArray)sessions["sessions"]).Add(s);                        
                    }
                    reqSessionCount = System.Convert.ToInt16(tmpSessions["total"]);
                    reqFromSession += reqSessionCount;
                }
                
                int sessionCount = 0 + sessionsWaitingToStart;
                string idleSession = "";
               
                foreach (JObject s in sessions["sessions"])
                {
                    if (Helpers.JsonHelpers.CheckForJsonProperty("livyInfo", s))
                    {
                        JObject li = (JObject)s["livyInfo"];
                        if (Helpers.JsonHelpers.CheckForJsonProperty("startingAt", li))
                        {
                            //Session number for current loop iteration
                            var loopSession = s["id"].ToString();
                            double timeSinceStarted = 0;
                            if (!string.IsNullOrEmpty(s["livyInfo"]["startingAt"].ToString()))
                            {
                                timeSinceStarted = (DateTime.Now - (DateTime)s["livyInfo"]["startingAt"]).TotalSeconds;
                            }

                            if (s["state"].ToString() == "idle" & timeSinceStarted > 180)
                            {
                                if (string.IsNullOrEmpty(idleSession))
                                {
                                    
                                    //Check if heartbeat files exist
                                    files = folder.GetFiles();
                                    matchedFiles = files.Where(f => f.Name.StartsWith($"us_{loopSession.ToString()}_"));
                                    if (matchedFiles.Any())
                                    {
                                        //Skip this session and move on to the next
                                        //logging.LogInformation($"Processing Task {taskName}. Session {loopSession} for application AdsGoFast {sessionCount} is idle but marked for use.");
                                    }
                                    else
                                    {
                                        //Write a session heartbeat file
                                        logging.LogInformation($"Processing Task {taskName}. PreExisting Session number {loopSession} detected for application AdsGoFast {sessionCount}. Signaling intent to use...");
                                        WriteSessionHeartBeat(folder, loopSession, guid, "us");
                                        idleSession = loopSession;
                                    }
                                }
                                sessionCount += 1;
                            }
                            if (s["state"].ToString() == "idle" & timeSinceStarted <= 180)
                            {
                                logging.LogInformation($"Processing Task {taskName}. PreExisting Session number {loopSession} for application AdsGoFast {sessionCount} ignored as it has only just been created and will most likely be used by its creator.");
                                sessionCount += 1;
                            }
                            if (s["state"].ToString() == "busy")
                            {
                                sessionCount += 1;
                                logging.LogInformation($"Processing Task {taskName}. PreExisting Session number {loopSession} for application AdsGoFast {sessionCount} ignored as it is busy.");
                            }
                        }
                    }
                }               


                //If no idle sessions then create new one
                if (string.IsNullOrEmpty(idleSession) && (sessionCount <= 2))
                {
                    var startTimer = DateTime.Now;
                    string sessionName = "AdsGoFast_" + (sessionCount + 1).ToString();
                    string jsonContent = "{\"tags\": null,\"Name\": \"" + sessionName + "\", \"driverMemory\": \"4g\",  \"driverCores\": 1,  \"executorMemory\": \"2g\", \"executorCores\": 2, \"numExecutors\": 2, \"artifactId\": \"dldj\"}";
                    WriteSessionHeartBeat(folder, sessionCount.ToString(), guid, "cs");
                    await Task.Delay(1000);
                    files = folder.GetFiles();
                    matchedFiles = files.Where(f => f.Name.StartsWith($"cs_{sessionCount}_"));
                    Guid minGuid = Guid.Empty;
                    //If the runner is not idle check the heartbeat files to ensure it hasn't previously failed on start
                    foreach (var f in matchedFiles)
                    {
                        Guid GuidInFileStr = Guid.Parse(f.Name.Replace($"cs_{sessionCount}_", "").Replace(".txt", ""));
                        if (Guid.Empty.CompareTo(minGuid) == 0) { minGuid = GuidInFileStr; }
                        if (minGuid.CompareTo(GuidInFileStr) == -1)
                        { minGuid = GuidInFileStr; }
                    }

                    //If current thread has wrote the first heartbeat then allow it to continue
                    if (minGuid == guid)
                    {
                        JObject newSession = JObject.Parse(await PostToSynapseApi(endpoint, $"livyApi/versions/2019-11-01-preview/sparkPools/{poolName}/sessions?detailed=True", jsonContent, logging));
                        idleSession = newSession["id"].ToString();
                       
                        WriteSessionHeartBeat(folder, idleSession, guid, "us");
                        //Wait for session to start
                        if (newSession["state"].ToString() == "not_started")
                        {
                            //Will Wait for up to 100 seconds
                            for (int i = 0; i < 20; i++)
                            {
                                await Task.Delay(5000);
                                var startUpTime = (DateTime.Now - startTimer).TotalSeconds;
                                JObject session = JObject.Parse(await GetFromSynapseApi(endpoint, $"livyApi/versions/2019-01-01/sparkPools/{poolName}/sessions/{idleSession}", logging));
                                if (session["state"].ToString() == "idle")
                                {
                                    logging.LogInformation($"Processing Task {taskName}. Session {idleSession}. Started in {startUpTime.ToString()} seconds.");
                                    //Wait a tiny bit longer just to make sure session is ready
                                    await Task.Delay(3000);
                                    foreach (var f in matchedFiles)
                                    {
                                        f.Delete();
                                    }
                                    break;
                                }
                                else
                                {
                                    logging.LogInformation($"Processing Task {taskName}. Waiting for Session {idleSession} for application {sessionName}. Current state is {session["state"].ToString()}. Startup time has been {startUpTime.ToString()} seconds.");
                                }
                            }
                        }
                    }
                    else
                    {
                        logging.LogInformation($"Processing Task {taskName}. This thread has been aborted due to a session concurrency issue. Beginning Retry. Application: {sessionName}");
                        return "retry";
                    }



                }

                //Run code
                //TODO: Get the notebook and consolidate all cells into single statement
                //Check to see if there is any session contention                              
                var files2 = folder.GetFiles();
                var matchedFiles2 = files2.Where(f => f.Name.StartsWith($"us_{idleSession.ToString()}_"));
                if (matchedFiles2.Any())
                {
                    Guid minGuid = Guid.Empty;
                    //If the runner is not idle check the heartbeat files to ensure it hasn't previously failed on start
                    foreach (var f in matchedFiles2)
                    {
                        Guid GuidInFileStr = Guid.Parse(f.Name.Replace($"us_{idleSession}_", "").Replace(".txt", ""));
                        if (Guid.Empty.CompareTo(minGuid) == 0) { minGuid = GuidInFileStr; }
                        if (minGuid.CompareTo(GuidInFileStr) == -1)
                        { minGuid = GuidInFileStr; }
                    }

                    //If current thread has wrote the first heartbeat then allow it to continue
                    if (minGuid == guid)
                    {
                        string code = "";
                        //Get the Notebook 
                        JObject Notebook = JObject.Parse(await GetFromSynapseApi(endpoint, $"/notebooks/DeltaProcessingNotebook?api-version=2020-12-01",logging));
                        foreach (JObject cell in Notebook["properties"]["cells"])
                        {
                            bool cellIsParam = false;
                            if (cell["cell_type"].ToString() == "code")
                            {
                                var metadataBool = Helpers.JsonHelpers.CheckForJsonProperty("metadata",cell);
                                if (metadataBool)
                                {
                                    var tagsBool = Helpers.JsonHelpers.CheckForJsonProperty("tags", (JObject)cell["metadata"]);
                                    if (tagsBool)
                                    {
                                        if (((JArray)cell["metadata"]["tags"]).ToList().Contains("parameters"))
                                        {
                                            cellIsParam = true;
                                            //TODO Insert the TaskObject
                                        }
                                    }
                                    
                                }

                                if(!cellIsParam)
                                {
                                    foreach (var line in cell["source"])
                                    {
                                        code += line.ToString();
                                    }
                                    code += System.Environment.NewLine;
                                }
                            }                           
                        }                        

                        JObject postContent = new JObject();
                        postContent["code"] = code;
                        postContent["kind"] = "pyspark";
                       

                        JObject statement = JObject.Parse(await PostToSynapseApi(endpoint, $"livyApi/versions/2019-11-01-preview/sparkPools/{poolName}/sessions/{idleSession}/statements", Newtonsoft.Json.JsonConvert.SerializeObject(postContent), logging));
                        //Delete the files and reset the runner as it has failed to start previously                            
                        foreach (var f in matchedFiles2)
                        {
                            f.Delete();
                        }
                        //TODO

                        logging.LogInformation($"Processing Task {taskName}. PySpark Statement Created and Executed.");
                        return "succeeded";
                    }
                    else
                    {
                        logging.LogInformation($"Processing Task {taskName}. This thread has been aborted due to a session concurrency issue. Beginning Retry.");
                        return "retry"; 
                    }
                }
                else
                {
                    logging.LogInformation($"Processing Task {taskName}. No existing idle sessions found and no available new session slots.");
                    return "nosessions"; 
                }



            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                return "failed";
            }

        }
        public async Task<string> PostToSynapseApi(Uri endpoint,  string Path, string postContent, Logging.Logging logging)
        {

            try
            {
                var c = await GetSynapseClient();
                JObject jsonContent = new JObject();                
                var postStringContent = new StringContent(postContent, System.Text.Encoding.UTF8, "application/json");
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

        private void WriteSessionHeartBeat(DirectoryInfo folder, string id, Guid guid, string prefix)
        {
            //Write a session heartbeat file                                
            string FileName = Path.Combine(folder.FullName, $"{prefix}_{id}_{guid.ToString()}.txt");
            using (FileStream fs = File.Create(FileName))
            {
                Byte[] info = new System.Text.UTF8Encoding(true).GetBytes("");
                fs.Write(info, 0, info.Length);
            }
        }
    }
}
