using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Reflection;
using FunctionApp.Models;
using FunctionApp.Models.GetTaskInstanceJSON;
using FunctionApp.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.TestHarness
{
    public class Program
    {        

        static void Main(string[] args)
        {
            IServiceCollection services = new ServiceCollection();

            var config = new ConfigurationBuilder()
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .AddUserSecrets(Assembly.GetExecutingAssembly(), true)
                .AddEnvironmentVariables()
                .Build();

            Startup.ConfigureServices(services, config);
            services.AddTransient<App>();

            services.AddLogging(builder => builder.AddConsole().AddFilter(level => level >= LogLevel.Information));
            using ServiceProvider serviceProvider = services.BuildServiceProvider();
            var app = serviceProvider.GetService<App>();
            app.Run();
        }
        
    }

    public class App
    {
        private readonly ILogger<App> _logger;
        private readonly TaskTypeMappingProvider _taskTypeMappingProvider;
        private readonly SourceAndTargetSystemJsonSchemasProvider _schemasProvider;

        public App(ILogger<App> logger,
            TaskTypeMappingProvider taskTypeMappingProvider,
            SourceAndTargetSystemJsonSchemasProvider schemasProvider)
        {
            _logger = logger;
            _taskTypeMappingProvider = taskTypeMappingProvider;
            _schemasProvider = schemasProvider;
        }

        public void Run()
        {
            var executionId = Guid.NewGuid();
            var logger = new Logging.Logging();
            ActivityLogItem activityLogItem = new ActivityLogItem
            {
                LogSource = "AF",
                ExecutionUid = executionId
            };
            logger.InitializeLog(_logger, activityLogItem);
            
            var testTaskInstances = GetTests();

            //Set up table to Store Invalid Task Instance Objects
            DataTable InvalidTIs = new DataTable();
            InvalidTIs.Columns.Add("ExecutionUid", typeof(Guid));
            InvalidTIs.Columns.Add("TaskInstanceId", typeof(long));
            InvalidTIs.Columns.Add("LastExecutionComment", typeof(string));

            foreach (var testTaskInstance in testTaskInstances)
            {
                JObject processedTaskObject = null;
                try
                {
                    var T = new AdfJsonBaseTask(testTaskInstance, logger);
                    T.CreateJsonObjectForAdf(executionId);
                    processedTaskObject = T.ProcessRoot(_taskTypeMappingProvider, _schemasProvider);
                }
                catch (Exception e) {
                    logger.LogErrors(e);
                } 
                string FileFullPath = "../../../UnitTestResults/Todo/";
                // Determine whether the directory exists.
                if (!Directory.Exists(FileFullPath))
                {
                    // Try to create the directory.
                    var di = Directory.CreateDirectory(FileFullPath);
                }

                if (processedTaskObject != null)
                {
                    JObject obj = new JObject();
                    obj["TaskObject"] = processedTaskObject;

                    FileFullPath =  $"{FileFullPath}{testTaskInstance.TaskType}_{testTaskInstance.AdfPipeline}_{testTaskInstance.TaskMasterId}.json";
                    File.WriteAllText(FileFullPath, JsonConvert.SerializeObject(obj, Formatting.Indented, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore }));
                }
            }
           
        }



        public IEnumerable<GetTaskInstanceJsonResult> GetTests()
        {
            string filePath = Path.GetDirectoryName(AppDomain.CurrentDomain.BaseDirectory) + "..\\..\\..\\..\\UnitTests\\tests.json";
            string tests;
            using (var r = new StreamReader(filePath))
            {
                tests = r.ReadToEnd();
            }
            
            var ts = JsonConvert.DeserializeObject<List<GetTaskInstanceJsonResult>>(tests);
            return ts;
        }


        //public void Test_GetSQLCreateStatementFromSchema(Logging.Logging _logging)
        //{
        //    string _filePath = Path.GetDirectoryName(System.AppDomain.CurrentDomain.BaseDirectory) + "..\\..\\..\\..\\UnitTests\\GetSQLCreateStatementFromSchema.json";
        //    string tests = "";
        //    using (var r = new StreamReader(_filePath))
        //    {
        //        tests = r.ReadToEnd();
        //    }
            
        //    AdsGoFast.GetSQLCreateStatementFromSchemaCore.Execute(JObject.Parse(tests),_logging);

        //}
  
    }
}
