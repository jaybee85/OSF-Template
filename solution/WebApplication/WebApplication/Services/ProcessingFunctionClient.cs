using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Azure.Storage.Queues;
using Azure.Storage.Queues.Specialized;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using Microsoft.Identity.Client;
using WebApplication.Models.Options;

namespace WebApplication.Services
{
    public class ProcessingFunctionClient
    {
        private readonly IConfiguration _config;
        private readonly string QueueName = "subjectareaprocessing";

        public ProcessingFunctionClient(HttpClient httpClient, IConfiguration config)
        {
            _config = config;

        }

        public async Task QueueSubjectAreaProvisioning(int subjectAreaId)
        {
            var connectionString = GetConnectionStringOrSetting(_config, "AzureWebJobsStorage");
            QueueClient queue = new QueueClient(connectionString, QueueName, new QueueClientOptions()
            {
                MessageEncoding = QueueMessageEncoding.Base64,
            });

            await queue.CreateIfNotExistsAsync();
            await queue.SendMessageAsync(subjectAreaId.ToString());
        }


        //todo: figure out where this acctually lives it should be an extension method...
        string GetConnectionStringOrSetting(IConfiguration configuration, string connectionName) =>
            configuration.GetConnectionString(connectionName) ?? configuration[connectionName];
    }


}
