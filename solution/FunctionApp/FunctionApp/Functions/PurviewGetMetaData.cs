/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using FunctionApp.Authentication;
using FunctionApp.DataAccess;
using FunctionApp.Models;
using FunctionApp.Models.Options;
using FunctionApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Management.Compute.Fluent;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Core;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Functions
{
    public class PurviewGetMetaData
    {
        private readonly PurviewService _purviewService;
        private readonly ApplicationOptions _options;
        private Logging.Logging _funcAppLogger = new Logging.Logging();

        public PurviewGetMetaData(IOptions<ApplicationOptions> options, PurviewService purviewService)
        {
            _purviewService = purviewService;
            _options = options?.Value;
        }
        [FunctionName("PurviewGetMetaData")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequest req, ILogger log, ExecutionContext context)
        {
            var executionId = System.Guid.NewGuid();
            ActivityLogItem activityLogItem = new ActivityLogItem
            {
                LogSource = "AF",
                ExecutionUid = executionId
            };
            _funcAppLogger.InitializeLog(log, activityLogItem);

            string requestBody = new StreamReader(req.Body).ReadToEndAsync().Result;
            JObject metadata = JsonConvert.DeserializeObject<JObject>(requestBody);
            string purviewAccount = metadata["TaskObject"]["ExecutionEngine"]["JsonProperties"]["PurviewAccountName"].ToString();

            List<String> datasets = new List<String>();
            string[] toIterate = { "SourceColumns", "TargetColumns" };

            for (int i = 0; i < toIterate.Length; i++)
            {
                string choice = Regex.Match(toIterate[i], @"^.*?(?=Columns)").ToString();
                string containerPartial = Regex.Match(metadata["TaskObject"][choice]["System"]["SystemServer"].ToString(), @"(?<=https://)(\w+)").ToString();

                // Setting up Input/Output Entities
                //Note - This will be expanded on as we expand more types to be read into purview. At the moment it assumes the items are read from a restricted set of sources
                string datasetType = "azure_datalake_gen2_resource_set";
                string datasetPath = "/azure_storage_account#" + containerPartial + ".core.windows.net/azure_datalake_gen2_service#" + metadata["TaskObject"][choice]["System"]["SystemServer"].ToString() + "/" + "azure_datalake_gen2_filesystem#" + metadata["TaskObject"][choice]["System"]["Container"].ToString() + "/azure_datalake_gen2_path#" + metadata["TaskObject"][choice]["Instance"][choice + "RelativePath"].ToString() + "azure_datalake_gen2_resource_set#" + metadata["TaskObject"][choice]["DataFileName"].ToString();
                //string datasetName = "";
                string datasetQualifiedName = "";
                string modifiedRelativePath = "";
                //At the moment it only support resource sets -> This is for datalake gen2.
                switch (metadata["TaskObject"][choice]["System"]["Type"].ToString())
                {
                    case "Delta":
                        modifiedRelativePath = Regex.Replace(metadata["TaskObject"][choice]["Instance"][choice + "RelativePath"].ToString(), "[0-9]{2,}", "{N}");
                        datasetQualifiedName = metadata["TaskObject"][choice]["System"]["SystemServer"] + "/" + metadata["TaskObject"][choice]["System"]["Container"] + "/" + modifiedRelativePath + "/" + metadata["TaskObject"][choice]["DataFileName"] + "/{SparkPartitions}";
                        break;
                    default:
                        //datasetName = metadata["TaskObject"][choice]["DataFileName"].ToString().Split(new Char[] { ',', '.' })[0];
                        modifiedRelativePath = Regex.Replace(metadata["TaskObject"][choice]["Instance"][choice + "RelativePath"].ToString(), "[0-9]{2,}", "{N}");
                        datasetQualifiedName = metadata["TaskObject"][choice]["System"]["SystemServer"] + "/" + metadata["TaskObject"][choice]["System"]["Container"] + "/" + modifiedRelativePath + "/" + metadata["TaskObject"][choice]["DataFileName"];
                        break;
                }
                JObject dataset = JObject.FromObject(new
                {
                    typeName = datasetType,
                    attributes = new
                    {
                        qualifiedName = datasetQualifiedName,
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
                JObject datasetGuid = JObject.Parse(_purviewService.ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/entity", "2021-07-01", datasetBody, _funcAppLogger).Result);
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
                        var schemaGuid = JObject.Parse(_purviewService.ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/entity", "2021-07-01", schemaBody, _funcAppLogger).Result);


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
                        JObject dsRelGuid = JObject.Parse(_purviewService.ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/relationship", "2021-07-01", dsRelBody, _funcAppLogger).Result);





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
                        JObject colGuids = JObject.Parse(_purviewService.ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/entity/bulk", "2021-07-01", colBody, _funcAppLogger).Result);
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
                            JObject scRelGuid = JObject.Parse(_purviewService.ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/relationship", "2021-07-01", scRelBody, _funcAppLogger).Result);

                        }

                    }
                }

            }
            //Finally we want to link up the dataset objects to the process
            // Setting up the final process entity 
            JObject process = JObject.FromObject(new
            {
                typeName = "azure_synapse_pipeline",
                status = "ACTIVE",
                attributes = new
                {
                    inputs = new JArray(JObject.FromObject(new { guid = datasets[0] })),
                    outputs = new JArray(JObject.FromObject(new { guid = datasets[1] })),
                    qualifiedName = "Synapse_Pipeline_Execution_UID_" + metadata["TaskObject"]["ExecutionUid"],
                    name = metadata["TaskObject"]["ExecutionEngine"]["ADFPipeline"] + "_" + DateTime.Now.ToString("dd/MM/yyyy HH:mm")
                },
            });

            JObject processJson = new JObject(new JProperty("entity", process));
            var processConv = processJson.ToString();
            var processBody = JObject.Parse(processConv);
            var processGuid = JObject.Parse(_purviewService.ExecuteRequest(purviewAccount, "post", ".catalog.purview.azure.com", "/api/atlas/v2/entity", "2021-07-01", processBody, _funcAppLogger).Result);

            //
            return new OkObjectResult(new JObject
            {
                ["Result"] = "Complete"
            });
        }

    }
}
