using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SharedZone.Client.Model;

namespace WebApplication.Services
{
    public class EmailService : IEmailService
    {
        private readonly IMicrosoftGraphService _graphService;
        private readonly ISharedZoneService _sharedZoneService;

        public EmailService(IMicrosoftGraphService graphService, ISharedZoneService sharedZoneService)
        {
            _graphService = graphService;
            _sharedZoneService = sharedZoneService;
        }

        public async Task SendDatasetAccessApprovalNotification(string requestor, SubjectArea subjectArea)
        {
            var sendToEmail = await _graphService.GetUserMailIdentity(requestor);
            await _sharedZoneService.PostEmailToQueue(Guid.NewGuid().ToString(), default, sendToEmail, "DataSetAccessRequestAccepted", new
            {
                RequestorName = sendToEmail.name,
                SubjectAreaName = subjectArea.SubjectAreaName,
            });
        }

        public async Task SendDatasetAccessRejectionNotification(string requestor, SubjectArea subjectArea)
        {
            var sendToEmail = await _graphService.GetUserMailIdentity(requestor);
            await _sharedZoneService.PostEmailToQueue(Guid.NewGuid().ToString(), default, sendToEmail, "DataSetAccessRequestRejected", new
            {
                RequestorName = sendToEmail.name,
                SubjectAreaName = subjectArea.SubjectAreaName,
            });
        }

        public async Task SendDatasetAccessRequestNotification(string recipient, string requestor, SubjectArea subjectArea)
        {
            var sendToEmail = await _graphService.GetUserMailIdentity(recipient);
            var requestingUser = await _graphService.GetUserMailIdentity(requestor);

            await _sharedZoneService.PostEmailToQueue(Guid.NewGuid().ToString(), default, sendToEmail, "DataSetAccessRequestCreated", new
            {
                RequestorName = requestingUser.name,
                RecipientName = sendToEmail.name,
                dataSetName = subjectArea.SubjectAreaName
            });
        }

        public async Task SendNotificationToPHNUsers(string owner, string custodian, string[] stewards)
        {
            //todo: this doesnt' do anything, but where it's being called doesn't actually calculate the delta
            //we should change this to send out the email when syncing teh AD groups - so if you are added to the AD group you 
            //get an email.
        }

    }
}
