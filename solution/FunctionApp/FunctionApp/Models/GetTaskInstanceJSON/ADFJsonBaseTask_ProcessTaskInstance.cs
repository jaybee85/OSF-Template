/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/

using System;
using System.Threading.Tasks;
using FunctionApp.Helpers;
using FunctionApp.Services;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Models.GetTaskInstanceJSON
{
    public partial class AdfJsonBaseTask : GetTaskInstanceJsonResult
    {

        public async Task ProcessTaskInstance(TaskTypeMappingProvider ttm)
        {
            //Validate TaskInstance based on JSON Schema
            var mappings = await ttm.GetAllActive();
            var mapping = TaskTypeMappingProvider.LookupMappingForTaskMaster(mappings, SourceSystemType, TargetSystemType, _taskMasterJsonSource["Type"].ToString(), _taskMasterJsonTarget["Type"].ToString(), TaskTypeId, TaskExecutionType);
            string mappingSchema = mapping.TaskInstanceJsonSchema;
            if (mappingSchema != null)
            {
                TaskIsValid = await JsonHelpers.ValidateJsonUsingSchema(_logging, mappingSchema, TaskInstanceJson, "Failed to validate TaskInstance JSON for TaskTypeMapping: " + mapping.MappingName + ". ");
            }

            if (TaskIsValid)
            {
                ProcessTaskInstance_Default();
            }
        }

        /// <summary>
        /// Default Method which merges Source & Target attributes on TaskInstanceJson with existing Source and Target Attributes on TaskObject payload.
        /// </summary>
        public void ProcessTaskInstance_Default()
        {

            JObject Source = (JObject)_jsonObjectForAdf["Source"];
            JObject Target = (JObject)_jsonObjectForAdf["Target"];
            JObject Instance = new JObject();

            Instance.Merge(_taskInstanceJson, new JsonMergeSettings
            {
                // union array values together to avoid duplicates
                MergeArrayHandling = MergeArrayHandling.Union
            });

            Source["Instance"] = Instance;
            Target["Instance"] = Instance;


        }
    }
}
