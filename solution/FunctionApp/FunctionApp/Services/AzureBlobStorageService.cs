using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Blob;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using FunctionApp.Authentication;
using FunctionApp.Models.Options;
using Microsoft.Extensions.Options;

namespace FunctionApp.Services
{
    public class AzureBlobStorageService
    {
        private readonly IAzureAuthenticationProvider _authProvider;
        private readonly IOptions<ApplicationOptions> _options;

        public AzureBlobStorageService(IAzureAuthenticationProvider authProvider, IOptions<ApplicationOptions> options)
        {
            _authProvider = authProvider;
            _options = options;
        }
        public static async Task DeleteBlobFolder(string BlobStorageAccountName, string BlobStorageContainerName, string BlobStorageFolderPath, TokenCredential TokenCredential, Logging.Logging logging)
        {
            try
            {
                StorageCredentials storageCredentials = new StorageCredentials(TokenCredential);
                CloudStorageAccount sourceStorageAccount = new CloudStorageAccount(storageCredentials, BlobStorageAccountName, "core.windows.net", true);

                CloudBlobClient blobClient = sourceStorageAccount.CreateCloudBlobClient();
                CloudBlobContainer container = blobClient.GetContainerReference(BlobStorageContainerName);

                CloudBlobDirectory directory = container.GetDirectoryReference(BlobStorageFolderPath);

                BlobContinuationToken continuationToken = null;
                List<IListBlobItem> files = new List<IListBlobItem>();
                do
                {
                    BlobResultSegment response = await directory.ListBlobsSegmentedAsync(continuationToken);
                    continuationToken = response.ContinuationToken;
                    files.AddRange(response.Results);
                }
                while (continuationToken != null);


                foreach (IListBlobItem f in files)
                {
                    CloudBlockBlob sourceBlob = (CloudBlockBlob)f;
                    await sourceBlob.DeleteIfExistsAsync();
                }
            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                logging.LogErrors(new Exception("Initiation of Delete Failed:"));
                throw;

            }
        }

        public static void UploadContentToBlob(string content, string BlobStorageAccountName, string BlobStorageContainerName, string BlobStorageFolderPath, string TargetFileName, TokenCredential tokenCredential)
        {
            StorageCredentials storageCredentials = new StorageCredentials(tokenCredential);
            CloudStorageAccount storageAccount = new CloudStorageAccount(storageCredentials, BlobStorageAccountName, "core.windows.net", true);

            CloudBlobClient blobClient = storageAccount.CreateCloudBlobClient();
            CloudBlobContainer container = blobClient.GetContainerReference(BlobStorageContainerName);

            CloudBlobDirectory directory = container.GetDirectoryReference(BlobStorageFolderPath);
            CloudBlockBlob blob = directory.GetBlockBlobReference(TargetFileName);

            blob.UploadTextAsync(content).Wait();
        }

        public static string ReadFile(string BlobStorageAccountName, string BlobStorageContainerName, string BlobStorageFolderPath, string TargetFileName, TokenCredential tokenCredential)
        {

            StorageCredentials storageCredentials = new StorageCredentials(tokenCredential);
            CloudStorageAccount storageAccount = new CloudStorageAccount(storageCredentials, BlobStorageAccountName, "core.windows.net", true);

            CloudBlobClient blobClient = storageAccount.CreateCloudBlobClient();
            CloudBlobContainer container = blobClient.GetContainerReference(BlobStorageContainerName);

            CloudBlobDirectory directory = container.GetDirectoryReference(BlobStorageFolderPath);
            CloudBlockBlob blob = directory.GetBlockBlobReference(TargetFileName);
            return blob.DownloadTextAsync().Result;
        }


        //public string JsonBlobCore(HttpRequest req, Logging.Logging logging)
        //{
        //    string reqbody = new StreamReader(req.Body).ReadToEndAsync().Result;
        //    string BlobStorageAccountName;
        //    string BlobStorageContainerName;
        //    string BlobStorageFolderPath;

        //    BlobStorageAccountName = GetStringRequestParam("BlobStorageAccountName", req, reqbody).ToString();
        //    BlobStorageContainerName = GetStringRequestParam("BlobStorageContainerName", req, reqbody).ToString();
        //    BlobStorageFolderPath = GetStringRequestParam("BlobStorageFolderPath", req, reqbody).ToString();

        //    TokenCredential StorageToken = new TokenCredential(_authProvider.GetAzureRestApiToken(string.Format("https://storage.azure.com/", BlobStorageAccountName), _options.Value.UseMSI));

        //    string TargetFileName = GetStringRequestParam("TargetFileName", req, reqbody).ToString();
        //    string DownloadResult = ReadFile(BlobStorageAccountName, BlobStorageContainerName, BlobStorageFolderPath, TargetFileName, StorageToken);
        //    return DownloadResult;
        //}

        //private static string GetStringRequestParam(string Name, HttpRequest req, string reqbody)
        //{
        //    string ret;

        //    if (req.Method == HttpMethod.Get.ToString())
        //    {
        //        ret = req.Query[Name].ToString();
        //    }
        //    else
        //    {
        //        dynamic parsed = JsonConvert.DeserializeObject(reqbody);
        //        ret = parsed[Name].Value.ToString();
        //    }

        //    return ret;
        //}
    }
}
