using System;
using System.IO;
using System.Threading.Tasks;
using FunctionApp.Models;
using FunctionApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Functions
{
    // ReSharper disable once UnusedMember.Global
    public class AdfGetInformationSchemaSql
    {
        /// <summary>
        /// The purpose of this function is to provide a SQL query that the Data Factory can use
        /// to retrieve the schema information for a table. 
        /// </summary>
        /// <param name="req"></param>
        /// <param name="log"></param>
        /// <param name="context"></param>
        /// <returns></returns>
        [FunctionName("GetInformationSchemaSQL")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log, ExecutionContext context)
        {
            Guid executionId = context.InvocationId;
            FrameworkRunner frp = new FrameworkRunner(log, executionId);

            FrameworkRunnerWorkerWithHttpRequest worker = GetInformationSchemaSqlCore;
            FrameworkRunnerResult result = await frp.Invoke(req, "GetInformationSchemaSQL", worker);
            if (result.Succeeded)
            {
                return new OkObjectResult(JObject.Parse(result.ReturnObject));
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed...." });
            }
        }

        public async Task<JObject> GetInformationSchemaSqlCore(HttpRequest req, Logging.Logging logging)
        {
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);

            string tableSchema = JObject.Parse(data.ToString())["TableSchema"];
            string tableName = JObject.Parse(data.ToString())["TableName"];
            string sourceType = JObject.Parse(data.ToString())["SourceType"];
            string informationSchemaSql = "";
            if (sourceType == "OracleServerTable")
            {
                informationSchemaSql = $@"
                    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;
                    SELECT DISTINCT
	                    c.ORDINAL_POSITION,
	                    c.COLUMN_NAME, 
	                    c.DATA_TYPE,
	                    IS_NULLABLE = cast(case when c.IS_NULLABLE = 'Yes' then 1 else 0 END as bit), 
	                    c.NUMERIC_PRECISION, 
	                    c.CHARACTER_MAXIMUM_LENGTH, 
	                    c.NUMERIC_SCALE,  
	                    ac.is_identity IS_IDENTITY,
	                    ac.is_computed IS_COMPUTED,
	                    KEY_COLUMN = cast(CASE WHEN kcu.TABLE_NAME IS NULL THEN 0 ELSE 1 END as bit),
	                    PKEY_COLUMN = cast(CASE WHEN tc.TABLE_NAME IS NULL THEN 0 ELSE 1 END as bit)
                    FROM INFORMATION_SCHEMA.COLUMNS c
                    INNER JOIN sys.all_tab_columns ac ON object_id(QUOTENAME(c.TABLE_SCHEMA)+'.'+QUOTENAME(c.TABLE_NAME)) = ac.object_id and ac.name = c.COLUMN_NAME
                    LEFT OUTER join INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu ON c.TABLE_CATALOG = kcu.TABLE_CATALOG and c.TABLE_SCHEMA = kcu.TABLE_SCHEMA AND c.TABLE_NAME = kcu.TABLE_NAME and c.COLUMN_NAME = kcu.COLUMN_NAME 
                    LEFT OUTER join 
	                    (SELECT Col.TABLE_CATALOG, Col.TABLE_SCHEMA, Col.TABLE_NAME, Col.COLUMN_NAME
	                    from 
		                    INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, 
		                    INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE Col  
	                    WHERE 
		                    Col.Constraint_Name = Tab.Constraint_Name
		                    AND Col.Table_Name = Tab.Table_Name
		                    AND Tab.Constraint_Type = 'PRIMARY KEY') tc
                    ON c.TABLE_CATALOG = tc.TABLE_CATALOG and c.TABLE_SCHEMA = tc.TABLE_SCHEMA and c.TABLE_NAME = tc.TABLE_NAME and c.COLUMN_NAME = tc.COLUMN_NAME
                    WHERE c.TABLE_NAME = '{tableName}' AND c.TABLE_SCHEMA = '{tableSchema}'     
                    COMMIT ;
                ";
            }
            else
            {
                informationSchemaSql = $@"
                    SELECT DISTINCT
	                    c.ORDINAL_POSITION,
	                    c.COLUMN_NAME, 
	                    c.DATA_TYPE,
	                    IS_NULLABLE = cast(case when c.IS_NULLABLE = 'Yes' then 1 else 0 END as bit), 
	                    c.NUMERIC_PRECISION, 
	                    c.CHARACTER_MAXIMUM_LENGTH, 
	                    c.NUMERIC_SCALE,  
	                    ac.is_identity IS_IDENTITY,
	                    ac.is_computed IS_COMPUTED,
	                    KEY_COLUMN = cast(CASE WHEN kcu.TABLE_NAME IS NULL THEN 0 ELSE 1 END as bit),
	                    PKEY_COLUMN = cast(CASE WHEN tc.TABLE_NAME IS NULL THEN 0 ELSE 1 END as bit)
                    FROM INFORMATION_SCHEMA.COLUMNS c with (NOLOCK)
                    INNER JOIN sys.all_columns ac with (NOLOCK) ON object_id(QUOTENAME(c.TABLE_SCHEMA)+'.'+QUOTENAME(c.TABLE_NAME)) = ac.object_id and ac.name = c.COLUMN_NAME
                    LEFT OUTER join INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu with (NOLOCK) ON c.TABLE_CATALOG = kcu.TABLE_CATALOG and c.TABLE_SCHEMA = kcu.TABLE_SCHEMA AND c.TABLE_NAME = kcu.TABLE_NAME and c.COLUMN_NAME = kcu.COLUMN_NAME 
                    LEFT OUTER join 
	                    (SELECT Col.TABLE_CATALOG, Col.TABLE_SCHEMA, Col.TABLE_NAME, Col.COLUMN_NAME
	                    from 
		                    INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab with (NOLOCK), 
		                    INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE Col with (NOLOCK) 
	                    WHERE 
		                    Col.Constraint_Name = Tab.Constraint_Name
		                    AND Col.Table_Name = Tab.Table_Name
		                    AND Tab.Constraint_Type = 'PRIMARY KEY') tc
	                    ON c.TABLE_CATALOG = tc.TABLE_CATALOG and c.TABLE_SCHEMA = tc.TABLE_SCHEMA and c.TABLE_NAME = tc.TABLE_NAME and c.COLUMN_NAME = tc.COLUMN_NAME
                    WHERE c.TABLE_NAME = '{tableName}' AND c.TABLE_SCHEMA = '{tableSchema}'                                    
                ";
            }


            JObject root = new JObject
            {
                ["InformationSchemaSQL"] = informationSchemaSql
            };

            return root;
        }

    }
}