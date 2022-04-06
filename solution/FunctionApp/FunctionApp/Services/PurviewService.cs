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
using FunctionApp.DataAccess;
using System.Text.RegularExpressions;

namespace FunctionApp.Services
{
    public class PurviewService
    {
        private readonly IAzureAuthenticationProvider _authProvider;
        private readonly IOptions<ApplicationOptions> _options;
        private readonly IHttpClientFactory _httpClientFactory;

        public PurviewService(IAzureAuthenticationProvider authProvider, IOptions<ApplicationOptions> options, IHttpClientFactory httpClientFactory)
        {
            _authProvider = authProvider;
            _options = options;
            _httpClientFactory = httpClientFactory;
        }
        public async Task<string> ExecuteRequest(string PurviewAccountName, string Method,  string APIURIDomain, string APIURIPath, string APIVersion, JObject PostBody, Logging.Logging logging)
        {
            
            try
            {
                using var c = _httpClientFactory.CreateClient(HttpClients.PurviewHttpClientName);
                if (c.DefaultRequestHeaders.Authorization == null)
                {
                    await Task.Delay(2000);
                }
                var postContent = new StringContent(PostBody.ToString(), System.Text.Encoding.UTF8, "application/json");

                HttpResponseMessage response;
                if (Method.ToLower() == "get")
                {
                    response = await c.GetAsync($"https://{PurviewAccountName}{APIURIDomain}{APIURIPath}?&api-version={APIVersion}");
                }
                else
                {
                    response = await c.PostAsync($"https://{PurviewAccountName}{APIURIDomain}{APIURIPath}?&api-version={APIVersion}", postContent);
                }

                HttpContent responseContent = response.Content;
                var res = await response.Content.ReadAsStringAsync();
                return res;


            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                logging.LogErrors(new Exception("Purview ExecuteRequest Failed"));
                throw;
            }

        }

        public async Task<JObject> PurviewMetaDataCheck(JObject metadata,
        Logging.Logging logging)
            {
            var e = new Exception();
            List<string> children = new List<string>() { "TaskObject", "SourceHttpPath", "TargetHttpPath", "SourceColumns", "TargetColumns" };
            try
            {
                //Checking All our relevant parent levels objects exist

                foreach (var child in children)
                {
                    if (Helpers.JsonHelpers.CheckForJsonProperty(child, metadata) == false)
                    { 
                        e = new Exception("[" + child + "] not found and is necessary to properly log to Purview");
                        logging.LogErrors(e);
                        throw e;
                    }
                }

                //Checking our Taskobject children
                children = new List<string>() { "Source", "Target", "ExecutionEngine", "TMOptionals" };
                JObject parent = (JObject)metadata["TaskObject"];
                foreach (var child in children)
                {
                    if (Helpers.JsonHelpers.CheckForJsonProperty(child, parent) == false)
                    {
                        e = new Exception("[" + child + "] not found and is necessary to properly log to Purview");
                        logging.LogErrors(e);
                        throw e;
                    }
                }

                //Checking our Source children
                children = new List<string>() { "System", "Instance", "DataFileName", "WriteSchemaToPurview" };
                JObject subParent = (JObject)parent["Source"];
                foreach (var child in children)
                {
                    if (Helpers.JsonHelpers.CheckForJsonProperty(child, subParent) == false)
                    {
                        e = new Exception("[" + child + "] not found and is necessary to properly log to Purview");
                        logging.LogErrors(e);
                        throw e;
                    }
                }

                //Checking our Target children
                children = new List<string>() { "System", "Instance", "DataFileName", "WriteSchemaToPurview" };
                subParent = (JObject)parent["Target"];
                foreach (var child in children)
                {
                    if (Helpers.JsonHelpers.CheckForJsonProperty(child, subParent) == false)
                    {
                        e = new Exception("[" + child + "] not found and is necessary to properly log to Purview");
                        logging.LogErrors(e);
                        throw e;
                    }
                }

                //Checking our ExecutionEngine children
                children = new List<string>() { "JsonProperties", "ADFPipeline" };
                subParent = (JObject)parent["ExecutionEngine"];
                foreach (var child in children)
                {
                    if (Helpers.JsonHelpers.CheckForJsonProperty(child, subParent) == false)
                    {
                        e = new Exception("[" + child + "] not found and is necessary to properly log to Purview");
                        logging.LogErrors(e);
                        throw e;
                    }
                }

                //Checking our TMOptionals children
                children = new List<string>() { "QualifiedIDAssociation" };
                subParent = (JObject)parent["TMOptionals"];
                foreach (var child in children)
                {
                    if (Helpers.JsonHelpers.CheckForJsonProperty(child, subParent) == false)
                    {
                        e = new Exception("[" + child + "] not found and is necessary to properly log to Purview");
                        logging.LogErrors(e);
                        throw e;
                    }
                    
                }


                return await (PurviewGetMetaDataCore(metadata, logging));

            }
            catch (Exception error)
            {
                logging.LogErrors(error);
                logging.LogErrors(new Exception("Purview PurviewMetaDataCheck Failed"));
                throw;
            }


        }

        public async Task<JObject> PurviewGetMetaDataCore(JObject metadata,
        Logging.Logging logging)
        {

            try
            {


                string purviewAccount = metadata["TaskObject"]["ExecutionEngine"]["JsonProperties"]["PurviewAccountName"].ToString();
                List<String> datasets = new List<String>();
                string[] toIterate = { "SourceColumns", "TargetColumns" };
                string QualifiedName = "";
                string modifiedRelativePath = "";

                for (int i = 0; i < toIterate.Length; i++)
                {
                    string choice = Regex.Match(toIterate[i], @"^.*?(?=Columns)").ToString();
                    string containerPartial = Regex.Match(metadata["TaskObject"][choice]["System"]["SystemServer"].ToString(), @"(?<=https://)(\w+)").ToString();

                    // Setting up Input/Output Entities
                    //Note - This will be expanded on as we expand more types to be read into purview. At the moment it assumes the items are read from a restricted set of sources
                    string datasetType = "azure_datalake_gen2_resource_set";
                    string datasetPath = "/azure_storage_account#" + containerPartial + ".core.windows.net/azure_datalake_gen2_service#" + metadata["TaskObject"][choice]["System"]["SystemServer"].ToString() + "/" + "azure_datalake_gen2_filesystem#" + metadata["TaskObject"][choice]["System"]["Container"].ToString() + "/azure_datalake_gen2_path#" + metadata["TaskObject"][choice]["Instance"][choice + "RelativePath"].ToString() + "azure_datalake_gen2_resource_set#" + metadata["TaskObject"][choice]["DataFileName"].ToString();
                    //string datasetName = "";
                    //At the moment it only support resource sets -> This is for datalake gen2.
                    switch (metadata["TaskObject"][choice]["System"]["Type"].ToString())
                    {
                        case "Delta":
                            modifiedRelativePath = Regex.Replace(metadata["TaskObject"][choice]["Instance"][choice + "RelativePath"].ToString(), "[0-9]{2,}", "{N}");
                            modifiedRelativePath = modifiedRelativePath.Trim(new Char[] { '/' });
                            QualifiedName = metadata["TaskObject"][choice]["System"]["SystemServer"] + "/" + metadata["TaskObject"][choice]["System"]["Container"].ToString().Trim(new Char[] { '/' }) + "/" + modifiedRelativePath + "/" + metadata["TaskObject"][choice]["DataFileName"].ToString().Trim(new Char[] { '/' }) + "/{SparkPartitions}";
                            break;
                        default:
                            //datasetName = metadata["TaskObject"][choice]["DataFileName"].ToString().Split(new Char[] { ',', '.' })[0];
                            modifiedRelativePath = Regex.Replace(metadata["TaskObject"][choice]["Instance"][choice + "RelativePath"].ToString(), "[0-9]{2,}", "{N}");
                            modifiedRelativePath = modifiedRelativePath.Trim(new Char[] { '/' });
                            QualifiedName = metadata["TaskObject"][choice]["System"]["SystemServer"] + "/" + metadata["TaskObject"][choice]["System"]["Container"].ToString().Trim(new Char[] { '/' }) + "/" + modifiedRelativePath + "/" + metadata["TaskObject"][choice]["DataFileName"].ToString().Trim(new Char[] { '/' });
                            break;
                    }
                    JObject dataset = JObject.FromObject(new
                    {
                        typeName = datasetType,
                        attributes = new
                        {
                            qualifiedName = QualifiedName,
                            name = metadata["TaskObject"][choice]["DataFileName"],
                            path = datasetPath,
                            description = (String)null,
                            objectType = (String)null
                        },
                        status = "ACTIVE"
                    });


                    JObject datasetJson = new JObject(new JProperty("entity", dataset));
                    var datasetConv = datasetJson.ToString();
                    var datasetBody = JObject.Parse(datasetConv);
                    JObject datasetGuid = JObject.Parse(ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/entity", "2021-07-01", datasetBody, logging).Result);
                    //This is for the process at the end
                    datasets.Add(datasetGuid["guidAssignments"].First.Last.ToString());

                    //If the dataset has columns at all, we need to create a schema, a dataset-schema relationship, columns and a schema-column relationship.
                    if (metadata["TaskObject"][choice]["WriteSchemaToPurview"].ToString() == "Enabled")
                    {
                        if (metadata[toIterate[i]].HasValues)
                        {

                            // Setting up Schema entity
                            JObject schema = JObject.FromObject(new
                            {
                                typeName = "tabular_schema",
                                attributes = new
                                {
                                    owner = (String)null,
                                    replicatedTo = (String)null,
                                    replicatedFrom = (String)null,
                                    qualifiedName = metadata[choice + "HttpPath"] + "#__tabular_schema",
                                    name = metadata[choice + "HttpPath"] + "#__tabular_schema",
                                    description = (String)null,
                                },
                                status = "ACTIVE"
                            });

                            JObject schemaJson = new JObject(new JProperty("entity", schema));
                            var schemaConv = schemaJson.ToString();
                            var schemaBody = JObject.Parse(schemaConv);
                            var schemaGuid = JObject.Parse(ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/entity", "2021-07-01", schemaBody, logging).Result);


                            //Relationship for Dataset and schema
                            JObject dsRelationship = JObject.FromObject(new
                            {
                                typeName = "tabular_schema_datasets",
                                end1 = new
                                {
                                    guid = datasetGuid["guidAssignments"].First.Last.ToString()
                                },
                                end2 = new
                                {
                                    guid = schemaGuid["guidAssignments"].First.Last.ToString()
                                },
                                label = "r:" + datasetGuid["guidAssignments"].First.Last.ToString() + "_" + schemaGuid["guidAssignments"].First.Last.ToString(),
                                status = "ACTIVE"
                            });
                            //JObject dsRelJson = new JObject(new JProperty("relationship", dsRelationship));
                            var dsRelConv = dsRelationship.ToString();
                            var dsRelBody = JObject.Parse(dsRelConv);
                            JObject dsRelGuid = JObject.Parse(ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/relationship", "2021-07-01", dsRelBody, logging).Result);





                            JArray entities = new JArray();
                            //Setting up Column entities
                            foreach (var column in metadata[toIterate[i]])
                            {
                                //Convert our dataframe datatype to atlas API compatible
                                string conversion;
                                switch (column["type"].ToString())
                                {
                                    case "int":
                                        conversion = "INT32";
                                        break;
                                    case "boolean":
                                        conversion = "BOOLEAN";
                                        break;
                                    case "timestamp":
                                        conversion = "INT96";
                                        break;
                                    default:
                                        conversion = "UTF8";
                                        break;
                                }
                                JObject entity = JObject.FromObject(new
                                {
                                    typeName = "column",
                                    attributes = new
                                    {
                                        owner = (String)null,
                                        replicatedTo = (String)null,
                                        replicatedFrom = (String)null,
                                        qualifiedName = metadata[choice + "HttpPath"] + "#__tabular_schema//" + column["name"].ToString(),
                                        name = column["name"].ToString(),
                                        description = (String)null,
                                        type = conversion,
                                    },
                                    status = "ACTIVE"
                                });
                                entities.Add(entity);
                            }
                            JObject colJson = new JObject(new JProperty("entities", entities));
                            string colConv = colJson.ToString();
                            JObject colBody = JObject.Parse(colConv);
                            JObject colGuids = JObject.Parse(ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/entity/bulk", "2021-07-01", colBody, logging).Result);
                            var cols = colGuids["guidAssignments"];
                            //Setting up Schema/Column Relationship
                            foreach (var col in cols)
                            {
                                JObject scRelationship = JObject.FromObject(new
                                {
                                    typeName = "tabular_schema_columns",
                                    end1 = new
                                    {
                                        guid = schemaGuid["guidAssignments"].First.Last.ToString()
                                    },
                                    end2 = new
                                    {
                                        guid = col.First.ToString()
                                    },
                                    label = "r:" + schemaGuid["guidAssignments"].First.Last.ToString() + "_" + col.First.ToString(),
                                    status = "ACTIVE"
                                });
                                //JObject scRelJson = new JObject(new JProperty("relationship", scRelationship));
                                var scRelConv = scRelationship.ToString();
                                var scRelBody = JObject.Parse(scRelConv);
                                JObject scRelGuid = JObject.Parse(ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/relationship", "2021-07-01", scRelBody, logging).Result);

                            }

                        }
                    }

                }
                //Finally we want to link up the dataset objects to the process
                // Setting up the final process entity 

                if (metadata["TaskObject"]["TMOptionals"]["QualifiedIDAssociation"].ToString() == "ExecutionId")
                {
                    QualifiedName = "Synapse_Pipeline_Execution_UID_" + metadata["TaskObject"]["ExecutionUid"];
                }
                else if (metadata["TaskObject"]["TMOptionals"]["QualifiedIDAssociation"].ToString() == "TaskMasterId")
                {
                    QualifiedName = "Synapse_Pipeline_TaskMasterId_" + metadata["TaskObject"]["TaskMasterId"];
                }
                else
                {
                    logging.LogInformation("No valid QualifiedIDAssociation found - using TaskMasterId");
                    QualifiedName = "TaskMasterId_" + metadata["TaskObject"]["TaskMasterId"];
                }
                JObject process = JObject.FromObject(new
                {
                    typeName = "azure_synapse_pipeline",
                    status = "ACTIVE",
                    attributes = new
                    {
                        inputs = new JArray(JObject.FromObject(new { guid = datasets[0] })),
                        outputs = new JArray(JObject.FromObject(new { guid = datasets[1] })),
                        qualifiedName = QualifiedName,
                        name = metadata["TaskObject"]["ExecutionEngine"]["ADFPipeline"] + "_" + DateTime.Now.ToString("dd/MM/yyyy HH:mm")
                    },
                });

                JObject processJson = new JObject(new JProperty("entity", process));
                var processConv = processJson.ToString();
                var processBody = JObject.Parse(processConv);
                var processGuid = JObject.Parse(ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/entity", "2021-07-01", processBody, logging).Result);

                //
                return JObject.FromObject(new
                {
                    Result = "Complete"
                });
            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                logging.LogErrors(new Exception("PurviewGetMetaDataCore Failed"));
                return JObject.FromObject(new
                {
                    Result = "Failure: " + e 
                });
                throw;
            }
        }

    }
}
