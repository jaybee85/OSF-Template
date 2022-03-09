/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/

using System;
using System.Reflection;
using FunctionApp.Helpers;
using FunctionApp.Services;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Models.GetTaskInstanceJSON
{
   
    /// <summary>
    /// Handles creation of Base Object that needs to be sent to ADF or AF includes internal properties etc that are not in the POCO
    /// </summary>
    public partial class AdfJsonBaseTask : GetTaskInstanceJsonResult
    {
        private readonly Logging.Logging _logging;
        private JObject _jsonObjectForAdf;
        private JObject _taskMasterJson;
        private JObject _sourceSystemJson;
        private JObject _targetSystemJson;
        private JObject _taskMasterJsonSource;
        private JObject _taskMasterJsonTarget;
        private JObject _taskInstanceJson;

        public bool TaskIsValid { get; private set; }

        public AdfJsonBaseTask(GetTaskInstanceJsonResult T, Logging.Logging logging)
        {
            this._logging = logging;
            foreach (PropertyInfo sourcePropertyInfo in T.GetType()
                                .GetProperties(
                                        BindingFlags.Public
                                        | BindingFlags.Instance))
            {                
                PropertyInfo targetPropertyInfo = GetType().GetProperty(sourcePropertyInfo.Name, BindingFlags.Public | BindingFlags.Instance);
                if (null != targetPropertyInfo && targetPropertyInfo.CanWrite)
                {
                    targetPropertyInfo.SetValue(this, sourcePropertyInfo.GetValue(T), null);
                }
            }
        }

        /// <summary>
        /// Adds the default attributes common across all task types
        /// </summary>
        /// <param name="ExecutionUid"></param>
        public void CreateJsonObjectForAdf(Guid ExecutionUid)
        {
            _jsonObjectForAdf = new JObject
            {
                ["TaskInstanceId"] = TaskInstanceId,
                ["TaskMasterId"] = TaskMasterId,
                ["TaskStatus"] = TaskStatus,
                ["TaskType"] = TaskType,
                ["Enabled"] = 1,
                ["ExecutionUid"] = ExecutionUid,
                ["NumberOfRetries"] = NumberOfRetries,
                ["DegreeOfCopyParallelism"] = DegreeOfCopyParallelism,
                ["KeyVaultBaseUrl"] = SourceKeyVaultBaseUrl == null ? TargetKeyVaultBaseUrl : SourceKeyVaultBaseUrl,
                ["ScheduleMasterId"] = ScheduleMasterId,
                ["TaskGroupConcurrency"] = TaskGroupConcurrency,
                ["TaskGroupPriority"] = TaskGroupPriority,
                ["TaskExecutionType"] = TaskExecutionType
            };

            JObject executionEngine = new JObject
            {
                ["EngineId"] = EngineId,
                ["EngineName"] = EngineName,
                ["ResourceGroup"] = EngineResourceGroup,
                ["SubscriptionId"] = EngineSubscriptionId,
                ["ADFPipeline"] = AdfPipeline,
                ["TaskDatafactoryIR"] = TaskDatafactoryIr
            };
            _jsonObjectForAdf["ExecutionEngine"] = executionEngine;
            

        }

        public JObject GetJsonObjectForAdf()
        {
            return _jsonObjectForAdf;
        }

        public void CreateInternalObjectsForProcessingJsonFields()
        {
            _taskMasterJson = new JObject();

            _taskMasterJsonSource = new JObject();
            if (JsonHelpers.IsValidJson(TaskMasterJson))
            {
                _taskMasterJson = JObject.Parse(TaskMasterJson);
                if (JsonHelpers.CheckForJsonProperty("Source", JObject.Parse(TaskMasterJson)))
                {
                    _taskMasterJsonSource = (JObject)_taskMasterJson["Source"];
                }
            }

            _taskMasterJsonTarget = new JObject();            
            if (JsonHelpers.IsValidJson(TaskMasterJson))
            {
                _taskMasterJson = JObject.Parse(TaskMasterJson);
                if (JsonHelpers.CheckForJsonProperty("Target", JObject.Parse(TaskMasterJson)))
                {
                    _taskMasterJsonTarget = (JObject)_taskMasterJson["Target"];
                }
            }

            _targetSystemJson = new JObject();
            if (JsonHelpers.IsValidJson(TargetSystemJson))
            {
                _targetSystemJson = JObject.Parse(TargetSystemJson);
            }

            _sourceSystemJson = new JObject();
            if (JsonHelpers.IsValidJson(SourceSystemJson))
            {
                _sourceSystemJson = JObject.Parse(SourceSystemJson);
            }


            _taskInstanceJson = new JObject();
            if (JsonHelpers.IsValidJson(TaskInstanceJson))
            {
                _taskInstanceJson = JObject.Parse(TaskInstanceJson);
            }
        }

        public JObject ProcessRoot(TaskTypeMappingProvider ttm, SourceAndTargetSystemJsonSchemasProvider sourceTargetSchemaProvider)
        {
            CreateInternalObjectsForProcessingJsonFields();
            ProcessSourceSystem(sourceTargetSchemaProvider);
            ProcessTargetSystem(sourceTargetSchemaProvider);
            ProcessTaskInstance(ttm);
            ProcessTaskMaster(ttm);
            return _jsonObjectForAdf; 

        }

        public void ProcessSourceSystem(SourceAndTargetSystemJsonSchemasProvider schemaProvider)
        {
            JObject Source = ((JObject)_jsonObjectForAdf["Source"]) == null
                ? new JObject()
                : (JObject)_jsonObjectForAdf["Source"];

            JObject System = new JObject
            {
                //Properties on Source System
                ["SystemId"] = (Int32)this.SourceSystemId,
                ["SystemServer"] = this.SourceSystemServer,
                ["AuthenticationType"] = this.SourceSystemAuthType,
                ["Type"] = this.SourceSystemType,
                ["Username"] = this.SourceSystemUserName

            };

            //Validate SourceSystemJson based on JSON Schema
            string sourceSystemSchema = schemaProvider.GetBySystemType(this.SourceSystemType).JsonSchema;
            TaskIsValid = JsonHelpers.ValidateJsonUsingSchema(_logging, sourceSystemSchema, SourceSystemJson,
                "Failed to validate SourceSystem JSON for System Type: " + this.SourceSystemType + ". ");

            ProcessSourceSystem_Default(ref System);
            Source["System"] = System;
            _jsonObjectForAdf["Source"] = Source;

        }


        public void ProcessSourceSystem_Default(ref JObject Source)
        {          
            Source.Merge(_sourceSystemJson, new JsonMergeSettings
            {
                // union array values together to avoid duplicates
                MergeArrayHandling = MergeArrayHandling.Union
            });                      
        }


        public void ProcessTargetSystem(SourceAndTargetSystemJsonSchemasProvider schemaProvider)
        {
            JObject Target = ((JObject)_jsonObjectForAdf["Target"]) == null ? new JObject() : (JObject)_jsonObjectForAdf["Target"];

            JObject System = new JObject
            {
                //Properties on Target System
                ["SystemId"] = (Int32)this.TargetSystemId,
                ["SystemServer"] = this.TargetSystemServer,
                ["AuthenticationType"] = this.TargetSystemAuthType,
                ["Type"] = this.TargetSystemType,
                ["Username"] = this.SourceSystemUserName

            };

            //Validate TargetSystemJson based on JSON Schema
            string targetSystemSchema = schemaProvider.GetBySystemType(this.TargetSystemType).JsonSchema;
            TaskIsValid = JsonHelpers.ValidateJsonUsingSchema(_logging, targetSystemSchema, this.TargetSystemJson, "Failed to validate TargetSystem JSON for System Type: " + this.TargetSystemType + ". ");

            ProcessTargetSystem_Default(ref System);
            Target["System"] = System;

            _jsonObjectForAdf["Target"] = Target;

        }

        public void ProcessTargetSystem_Default(ref JObject Target)
        {
            Target.Merge(_targetSystemJson, new JsonMergeSettings
            {
                // union array values together to avoid duplicates
                MergeArrayHandling = MergeArrayHandling.Union
            });
        }
    }
}
