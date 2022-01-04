using System.Collections.Generic;

namespace FunctionApp.Models.Options
{
    public class ServiceConnections
    {
        public string AppInsightsWorkspaceId { get; set; }
        public System.Int16 AppInsightsMaxNumberOfDaysToRequest { get; set; }
        public System.Int16 AppInsightsMinutesOverlap { get; set; }
        public string CoreFunctionsURL { get; set; }
        public List<string> CoreFunctionsAllowedRoles { get; set; }
        public string AdsGoFastTaskMetaDataDatabaseServer { get; set; }
        public string AdsGoFastTaskMetaDataDatabaseName { get; set; }
        public bool AdsGoFastTaskMetaDataDatabaseUseTrustedConnection { get; set; }
    }
}