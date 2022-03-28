/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/


using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace FunctionApp.Services
{    
    public interface ISecurityAccessProvider
    {
        public Task<bool> IsAuthorised(HttpRequest req, ILogger log);
    }
  
}
