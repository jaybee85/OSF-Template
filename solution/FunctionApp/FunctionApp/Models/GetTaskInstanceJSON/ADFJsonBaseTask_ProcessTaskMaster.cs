/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/

using System;
using FunctionApp.Helpers;
using FunctionApp.Services;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Models.GetTaskInstanceJSON
{
    public partial class AdfJsonBaseTask
    {
        public void ProcessTaskMaster(TaskTypeMappingProvider ttm)
        {
            //Validate TaskmasterJson based on JSON Schema
            var mappings = ttm.GetAllActive();
            var mapping = TaskTypeMappingProvider.LookupMappingForTaskMaster(mappings,SourceSystemType, TargetSystemType, _taskMasterJsonSource["Type"].ToString(), _taskMasterJsonTarget["Type"].ToString(), TaskTypeId, TaskExecutionType);            
            string mappingSchema = mapping.TaskMasterJsonSchema;
            TaskIsValid = JsonHelpers.ValidateJsonUsingSchema(_logging, mappingSchema, TaskMasterJson, "Failed to validate TaskMaster JSON for TaskTypeMapping: " + mapping.MappingName + ". ");
            
            if (TaskIsValid)
            {
                if (TaskType == "SQL Database to Azure Storage")
                {
                    ProcessTaskMaster_Mapping_XX_SQL_AZ_Storage_Parquet();
                    goto ProcessTaskMasterEnd;
                }

                if (TaskType == "Execute SQL Statement")
                {
                    ProcessTaskMaster_Mapping_AZ_SQL_StoredProcedure();
                    goto ProcessTaskMasterEnd;
                }

                if (TaskType == "Azure Storage to SQL Database")
                {
                    ProcessTaskMaster_Default();
                    goto ProcessTaskMasterEnd;
                }

                if (TaskType == "SQL Database CDC to Azure Storage")
                {
                    ProcessTaskMaster_Mapping_SQL_CDC_AZ_Storage_Parquet();
                    goto ProcessTaskMasterEnd;
                }

                /*if (TaskType == "Execute Synapse Notebook")
                {
                    ProcessTaskMaster_SynapseNotebookExecution();
                    ProcessTaskMaster_Default();
                    goto ProcessTaskMasterEnd;
                }*/
                
                //Default Processing Branch              
                {
                    ProcessTaskMaster_Default();
                    goto ProcessTaskMasterEnd;
                }


                ProcessTaskMasterEnd:
                _logging.LogInformation("ProcessTaskMasterJson Finished");

            }
        }

        public void ProcessTaskMaster_Mapping_SQL_CDC_AZ_Storage_Parquet()
        {
            JObject source = ((JObject)_jsonObjectForAdf["Source"]) == null ? new JObject() : (JObject)_jsonObjectForAdf["Source"];
            JObject target = ((JObject)_jsonObjectForAdf["Target"]) == null ? new JObject() : (JObject)_jsonObjectForAdf["Target"];

            source.Merge(_taskMasterJson["Source"], new JsonMergeSettings
            {
                // union array values together to avoid duplicates
                MergeArrayHandling = MergeArrayHandling.Union
            });

            target.Merge(_taskMasterJson["Target"], new JsonMergeSettings
            {
                // union array values together to avoid duplicates
                MergeArrayHandling = MergeArrayHandling.Union
            });

            source["IncrementalType"] = "CDC";
            if (source["IncrementalValue"].ToString().ToLower() == "no_watermark_string" && source["IncrementalColumnType"].ToString().ToLower() == "lsn")
            {
                source["SQLStatement"] = @$"
                    DECLARE @from_lsn binary(10), @to_lsn binary(10);
                    SET @from_lsn = sys.fn_cdc_get_min_lsn('{source["TableSchema"]}_{source["TableName"]}');
                    SET @to_lsn = sys.fn_cdc_map_time_to_lsn('largest less than or equal', GETDATE()); 
                    SELECT * FROM cdc.fn_cdc_get_net_changes_{source["TableSchema"]}_{source["TableName"]}(@from_lsn, @to_lsn, 'all')
                    ";
            }
            else if (source["IncrementalValue"].ToString().ToLower() != "no_watermark_string" && source["IncrementalColumnType"].ToString().ToLower() == "lsn")
            {
                source["SQLStatement"] = @$"
                    DECLARE @from_lsn binary(10), @to_lsn binary(10);
                    SET @from_lsn = {source["IncrementalValue"]};
                    SET @to_lsn = sys.fn_cdc_map_time_to_lsn('largest less than or equal',GETDATE()); 
                    SELECT * FROM cdc.fn_cdc_get_net_changes_{source["TableSchema"]}_{source["TableName"]}(@from_lsn, @to_lsn, 'all')
                    ";
            }

            _jsonObjectForAdf["Source"] = source;
            _jsonObjectForAdf["Target"] = target;

        }

        public void ProcessTaskMaster_Mapping_XX_SQL_AZ_Storage_Parquet()
        {
            JObject source = ((JObject)_jsonObjectForAdf["Source"]) == null ? new JObject() : (JObject)_jsonObjectForAdf["Source"];
            JObject target = ((JObject)_jsonObjectForAdf["Target"]) == null ? new JObject() : (JObject)_jsonObjectForAdf["Target"];

            source.Merge(_taskMasterJson["Source"], new JsonMergeSettings
            {
                // union array values together to avoid duplicates
                MergeArrayHandling = MergeArrayHandling.Union
            });

            target.Merge(_taskMasterJson["Target"], new JsonMergeSettings
            {
                // union array values together to avoid duplicates
                MergeArrayHandling = MergeArrayHandling.Union
            });

            source["IncrementalType"] = ProcessTaskMaster_Mapping_XX_SQL_AZ_Storage_Parquet_IncrementalType();
            source["IncrementalSQLStatement"] = ProcessTaskMaster_Mapping_XX_SQL_AZ_Storage_Parquet_CreateIncrementalSQLStatement(source);
            source["SQLStatement"] = ProcessTaskMaster_Mapping_XX_SQL_AZ_Storage_Parquet_CreateSQLStatement(source);


            JObject execute = new JObject();
            if (JsonHelpers.CheckForJsonProperty("StoredProcedure", _taskMasterJsonSource))
            {
                string storedProcedure = _taskMasterJsonSource["StoredProcedure"].ToString();
                if (storedProcedure.Length > 0)
                {
                    string spParameters = string.Empty;
                    if (JsonHelpers.CheckForJsonProperty("Parameters", _taskMasterJsonSource))
                    {
                        spParameters = _taskMasterJsonSource["Parameters"].ToString();
                    }
                    storedProcedure = string.Format("Exec {0} {1} {2} {3}", storedProcedure, spParameters, Environment.NewLine, " Select 1");

                }
                execute["StoredProcedure"] = storedProcedure;
            }
            source["Execute"] = execute;

            _jsonObjectForAdf["Source"] = source;
            _jsonObjectForAdf["Target"] = target;


        }

        public string ProcessTaskMaster_Mapping_XX_SQL_AZ_Storage_Parquet_IncrementalType()
        {
            string type = JsonHelpers.GetStringValueFromJson(_logging, "Type", _taskMasterJsonSource, "", true);
            if (!string.IsNullOrWhiteSpace(type))
            {
                JToken incrementalType = JsonHelpers.GetStringValueFromJson(_logging, "IncrementalType", _taskMasterJsonSource, "", true);
                int chunkSize = Convert.ToInt32(JsonHelpers.GetDynamicValueFromJson(_logging, "ChunkSize", _taskMasterJsonSource, "0", false));
                if (incrementalType.ToString() == "Full" && chunkSize == 0)
                {
                    type = "Full";
                }
                else if (incrementalType.ToString() == "Full" && chunkSize > 0)
                {
                    type = "Full_Chunk";
                }
                else if (incrementalType.ToString() == "Watermark" && chunkSize == 0)
                {
                    type = "Watermark";
                }
                else if (incrementalType.ToString() == "Watermark" && chunkSize > 0)
                {
                    type = "Watermark_Chunk";
                }
            }

            return type;
        }

        public string ProcessTaskMaster_Mapping_XX_SQL_AZ_Storage_Parquet_CreateIncrementalSQLStatement(JObject Extraction)
        {
            string sqlStatement = "";

            if (Extraction["IncrementalType"] != null)
            {

                if (Extraction["IncrementalType"].ToString().ToLower() == "full")
                {
                    sqlStatement = "";
                }

                if (Extraction["IncrementalType"].ToString().ToLower() == "full_chunk")
                {
                    sqlStatement = @$"
                       SELECT 
		                    CAST(CEILING(count(*)/{Extraction["ChunkSize"]} + 0.00001) as int) as  batchcount
	                    FROM [{Extraction["TableSchema"]}].[{Extraction["TableName"]}] 
                    ";
                }

                if (Extraction["IncrementalType"].ToString().ToLower() == "watermark" && Extraction["IncrementalColumnType"].ToString().ToLower() == "datetime")
                {
                    sqlStatement = @$"
                        SELECT 
	                        MAX([{Extraction["IncrementalField"]}]) AS newWatermark
                        FROM 
	                        [{Extraction["TableSchema"]}].[{Extraction["TableName"]}] 
                        WHERE [{Extraction["IncrementalField"]}] > CAST('{Extraction["IncrementalValue"]}' as datetime)
                    ";
                }

                if (Extraction["IncrementalType"].ToString().ToLower() == "watermark" && Extraction["IncrementalColumnType"].ToString().ToLower() != "datetime")
                {
                    sqlStatement = @$"
                        SELECT 
	                        MAX([{Extraction["IncrementalField"]}]) AS newWatermark
                        FROM 
	                        [{Extraction["TableSchema"]}].[{Extraction["TableName"]}] 
                        WHERE [{Extraction["IncrementalField"]}] > {Extraction["IncrementalValue"]}
                    ";
                }

                if (Extraction["IncrementalType"].ToString().ToLower() == "watermark_chunk" && Extraction["IncrementalColumnType"].ToString().ToLower() == "datetime")
                {
                    sqlStatement = @$"
                        SELECT MAX([{Extraction["IncrementalField"]}]) AS newWatermark, 
		                       CAST(CASE when count(*) = 0 then 0 else CEILING(count(*)/{Extraction["ChunkSize"]} + 0.00001) end as int) as  batchcount
	                    FROM  [{Extraction["TableSchema"]}].[{Extraction["TableName"]}] 
	                    WHERE [{Extraction["IncrementalField"]}] > CAST('{Extraction["IncrementalValue"]}' as datetime)
                    ";
                }

                if (Extraction["IncrementalType"].ToString().ToLower() == "watermark_chunk" && Extraction["IncrementalColumnType"].ToString().ToLower() != "datetime")
                {
                    sqlStatement = @$"
                        SELECT MAX([{Extraction["IncrementalField"]}]) AS newWatermark, 
		                       CAST(CASE when count(*) = 0 then 0 else CEILING(count(*)/{Extraction["ChunkSize"]} + 0.00001) end as int) as  batchcount
	                    FROM  [{Extraction["TableSchema"]}].[{Extraction["TableName"]}] 
	                    WHERE [{Extraction["IncrementalField"]}] > {Extraction["IncrementalValue"]}
                    ";
                }


            }

            return sqlStatement;
        }

        public string ProcessTaskMaster_Mapping_XX_SQL_AZ_Storage_Parquet_CreateSQLStatement(JObject Extraction)
        {
            string sqlStatement = "";
            
            if (Extraction["IncrementalType"] != null)
            {
                string incrementalType = (string)Extraction["IncrementalType"];
                Int32 chunkSize = (Int32)Extraction["ChunkSize"];
                JToken incrementalField = JsonHelpers.GetStringValueFromJson(_logging, "IncrementalField", _taskMasterJsonSource, "", true);
                JToken incrementalColumnType = JsonHelpers.GetStringValueFromJson(_logging, "IncrementalColumnType", _taskMasterJsonSource, "", true);
                JToken chunkField = (string)Extraction["ChunkField"];
                JToken tableSchema = Extraction["TableSchema"];
                JToken tableName = Extraction["TableName"];
                string extractionSql = JsonHelpers.GetStringValueFromJson(_logging, "ExtractionSQL", Extraction, "", false);

                //If Extraction SQL Explicitly set then overide _SQLStatement with that explicit value
                if (!string.IsNullOrWhiteSpace(extractionSql))
                {
                    sqlStatement = extractionSql;
                    goto EndOfSQLStatementSet;
                }

                //Chunk branch
                if (chunkSize > 0)
                {
                    if (incrementalType == "Full")
                    {
                        sqlStatement = $"SELECT * FROM {tableSchema}.{tableName}";
                    }
                    else if (incrementalType == "Full")
                    {
                        sqlStatement =  $"SELECT * FROM {tableSchema}.{tableName} WHERE CAST({chunkField} AS BIGINT) %  <batchcount> = <item> -1. ";
                    }
                    else if (incrementalType == "Watermark")
                    {
                        if (incrementalColumnType.ToString() == "DateTime")
                        {
                            DateTime incrementalValueDateTime = (DateTime)_taskInstanceJson["IncrementalValue"];
                            sqlStatement = string.Format("SELECT * FROM {0}.{1} WHERE {2} > Cast('{3}' as datetime) AND {2} <= Cast('<newWatermark>' as datetime)", tableSchema, tableName, incrementalField, incrementalValueDateTime.ToString("yyyy-MM-dd HH:mm:ss.fff"));
                        }
                        else if (incrementalColumnType.ToString() == "BigInt")
                        {
                            int incrementalValueBigInt = (int)_taskInstanceJson["IncrementalValue"];
                            sqlStatement = string.Format("SELECT * FROM {0}.{1} WHERE {2} > Cast('{3}' as bigint) AND {2} <= cast('<newWatermark>' as bigint)", tableSchema, tableName, incrementalField, incrementalValueBigInt);
                        }
                    }
                    else if (incrementalType == "Watermark" && !string.IsNullOrWhiteSpace(_taskMasterJsonSource["Source"]["ChunkSize"].ToString()))
                    {
                        if (incrementalColumnType.ToString() == "DateTime")
                        {
                            DateTime incrementalValueDateTime = (DateTime)_taskInstanceJson["IncrementalValue"];
                            sqlStatement = string.Format("SELECT * FROM {0}.{1} WHERE {2} > Cast('{3}' as datetime) AND {2} <= Cast('<newWatermark>' as datetime) AND CAST({4} AS BIGINT) %  <batchcount> = <item> -1.", tableSchema, tableName, incrementalField, incrementalValueDateTime.ToString("yyyy-MM-dd HH:mm:ss.fff"), chunkField);
                        }
                        else if (incrementalColumnType.ToString() == "BigInt")
                        {
                            int incrementalValueBigInt = (int)_taskInstanceJson["IncrementalValue"];
                            sqlStatement = string.Format("SELECT * FROM {0}.{1} WHERE {2} > Cast('{3}' as bigint) AND {2} <= Cast('<newWatermark>' as bigint) AND CAST({4} AS BIGINT) %  <batchcount> = <item> -1.", tableSchema, tableName, incrementalField, incrementalValueBigInt, chunkField);
                        }
                    }
                }
                else
                //Non Chunk
                {
                    if (incrementalType == "Full")
                    {
                        sqlStatement = string.Format("SELECT * FROM {0}.{1}", tableSchema, tableName);
                    }
                    else if (incrementalType == "Watermark")
                    {
                        if (incrementalColumnType.ToString() == "DateTime")
                        {
                            DateTime incrementalValueDateTime = (DateTime)_taskInstanceJson["IncrementalValue"];
                            sqlStatement = string.Format("SELECT * FROM {0}.{1} WHERE {2} > Cast('{3}' as datetime) AND {2} <= Cast('<newWatermark>' as datetime)", tableSchema, tableName, incrementalField, incrementalValueDateTime.ToString("yyyy-MM-dd HH:mm:ss.fff"));
                        }
                        else if (incrementalColumnType.ToString() == "BigInt")
                        {
                            int incrementalValueBigInt = (int)_taskInstanceJson["IncrementalValue"];
                            sqlStatement = string.Format("SELECT * FROM {0}.{1} WHERE {2} > Cast('{3}' as bigint) AND {2} <= cast('<newWatermark>' as bigint)", tableSchema, tableName, incrementalField, incrementalValueBigInt);
                        }
                    }
                }

            }

            EndOfSQLStatementSet:
            return sqlStatement;
        }



        public void ProcessTaskMaster_Mapping_AZ_SQL_StoredProcedure()
        {
            JObject source = (JObject)_jsonObjectForAdf["Source"];
            JObject execute = new JObject();
            execute["StoredProcedure"] =
                $"Exec {_taskMasterJsonSource["Source"]["StoredProcedure"]} {_taskMasterJsonSource["Source"]["Parameters"]} {Environment.NewLine}  Select 1";

            source["Execute"] = execute;
            _jsonObjectForAdf["Source"] = source;

        }


        /// <summary>
        /// Default Method which merges Source & Target attributes on TaskMasterJson with existing Source and Target Attributes on TaskObject payload.
        /// </summary>

        public void ProcessTaskMaster_Default()
        {            
            var source = (JObject)_jsonObjectForAdf["Source"] ?? new JObject();
            var target = (JObject)_jsonObjectForAdf["Target"] ?? new JObject();
           
            


            source.Merge(_taskMasterJson["Source"], new JsonMergeSettings
            {
                // union array values together to avoid duplicates
                MergeArrayHandling = MergeArrayHandling.Union
            });

            target.Merge(_taskMasterJson["Target"], new JsonMergeSettings
            {
                // union array values together to avoid duplicates
                MergeArrayHandling = MergeArrayHandling.Union
            });



            _jsonObjectForAdf["Source"] = source;
            _jsonObjectForAdf["Target"] = target;

            var rootAttributes = _taskMasterJson;
            rootAttributes.Remove("Source");
            rootAttributes.Remove("Target");

            _jsonObjectForAdf["TMOptionals"] = rootAttributes;
        }
    }
}
