/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/

using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Data;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Dapper;
using FormatWith;
using FunctionApp.Authentication;
using FunctionApp.DataAccess;
using FunctionApp.Helpers;
using FunctionApp.Models;
using FunctionApp.Models.GetTaskInstanceJSON;
using FunctionApp.Models.Options;
using FunctionApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Management.DataFactory.Models;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json.Linq;
using SendGrid;
using SendGrid.Helpers.Mail;
using System.Data.SqlClient;
using System.IO;

namespace FunctionApp.Functions
{

    // ReSharper disable once UnusedMember.Global
    public class AzureStorageTrigger
    {
        private const string SqlInsertTaskInstanceExecution = @"
                                            INSERT INTO TaskInstanceExecution (
	                                                        [ExecutionUid]
	                                                        ,[TaskInstanceId]
	                                                        ,[EngineId]
	                                                        ,[PipelineName]
	                                                        ,[AdfRunUid]
	                                                        ,[StartDateTime]
	                                                        ,[Status]
	                                                        ,[Comment]
	                                                        )
                                                        VALUES (
	                                                            @ExecutionUid
	                                                        ,@TaskInstanceId
	                                                        ,@EngineId
	                                                        ,@PipelineName
	                                                        ,@AdfRunUid
	                                                        ,@StartDateTime
	                                                        ,@Status
	                                                        ,@Comment
	                                        )";
        private readonly ISecurityAccessProvider _sap;
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;
        private readonly IOptions<ApplicationOptions> _options;
        private readonly IAzureAuthenticationProvider _authProvider;
        private readonly DataFactoryClientFactory _dataFactoryClientFactory;
        private readonly AzureSynapseService _azureSynapseService;
        public string HeartBeatFolder { get; set; }

        /*
        public AzureStorageTrigger(ISecurityAccessProvider sap,
            TaskMetaDataDatabase taskMetaDataDatabase,
            IOptions<ApplicationOptions> options,
            IAzureAuthenticationProvider authProvider,
            DataFactoryClientFactory dataFactoryClientFactory,
            AzureSynapseService azureSynapseService)
        {
            _sap = sap;
            _taskMetaDataDatabase = taskMetaDataDatabase;
            _options = options;
            _authProvider = authProvider;
            _dataFactoryClientFactory = dataFactoryClientFactory;
            _azureSynapseService = azureSynapseService;
        }

        [FunctionName("AzureStorageTrigger")]
        public async Task<IActionResult> Run(
        [BlobTrigger("functionstest/{name}", Connection = "AzureWebJobsStorage")] Stream blobStream, string blobName, ILogger log, ExecutionContext context)
        {
            log.LogInformation($"Full blob path: {blobName}");
            return new BadRequestObjectResult(new { Error = "Execution Failed...." });

        }
        */
    }

}