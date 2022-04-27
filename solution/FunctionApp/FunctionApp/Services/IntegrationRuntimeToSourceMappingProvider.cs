using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FunctionApp.DataAccess;
using FunctionApp.Models;

namespace FunctionApp.Services
{
    public class IntegrationRuntimeMappingProvider
    {
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;

        public IntegrationRuntimeMappingProvider(TaskMetaDataDatabase taskMetaDataDatabase)
        {
            _taskMetaDataDatabase = taskMetaDataDatabase;
        }

        public async Task<List<IntegrationRuntimeMapping>> GetAllActive()
        {
            using var con = await _taskMetaDataDatabase.GetSqlConnection();
            return con.QueryWithRetry<IntegrationRuntimeMapping>("select * from [dbo].[IntegrationRuntimeMapping] Where ActiveYN = 1").ToList();
        }

        
        public static void CheckValidTaskMasterMapping(List<IntegrationRuntimeMapping> all, string SourceSystemId, string IntegrationRuntime)
        {
            var filtered = all.Where(x =>
                (x.SystemId.ToString() == SourceSystemId) && x.IntegrationRuntimeName == IntegrationRuntime).ToList();
            if (filtered.Count >= 1)
            {
            }
            else
            {
                throw (new Exception(
                $"Failed to find IntegrationRuntimeMapping record for SourceSystemId: {SourceSystemId}, IntegrationRuntimeName {IntegrationRuntime}"));
            }


        }
    }
}