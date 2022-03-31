using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FunctionApp.DataAccess;
using FunctionApp.Models;

namespace FunctionApp.Services
{
    public class TaskTypeMappingProvider
    {
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;

        public TaskTypeMappingProvider(TaskMetaDataDatabase taskMetaDataDatabase)
        {
            _taskMetaDataDatabase = taskMetaDataDatabase;
        }

        public async Task<List<TaskTypeMapping>> GetAllActive()
        {
            using var con = await _taskMetaDataDatabase.GetSqlConnection();
            return con.QueryWithRetry<TaskTypeMapping>("select * from [dbo].[TaskTypeMapping] Where ActiveYN = 1").ToList();
        }

        
        public static TaskTypeMapping LookupMappingForTaskMaster(List<TaskTypeMapping> all, string SourceSystemType, string TargetSystemType, string SourceType, string TargetType, long TaskTypeId, string mappingType)
        {
            var filtered = all.Where(x =>
                (x.SourceSystemType == "*" || x.SourceSystemType == SourceSystemType) && x.SourceType == SourceType &&
                (x.TargetSystemType == "*" || x.TargetSystemType == TargetSystemType) && x.TargetType == TargetType &&
                x.MappingType == mappingType &&
                x.TaskTypeId == TaskTypeId).ToList();
            if (filtered.Count == 1)
            {
                return filtered[0];
            }

            throw (new Exception(
                $"Failed to find TaskTypeMapping record for SourceSystemType: {SourceSystemType}, TargetSystemType {TargetSystemType},  SourceType: {SourceType}, TargetType: {TargetType}, TaskTypeId: {TaskTypeId}"));
        }
    }
}