using System.Threading.Tasks;
using SharedZone.Client.Model;

namespace WebApplication.Services
{
    public interface IEmailService
    {
        Task SendDatasetAccessRejectionNotification(string requestor, SubjectArea subjectArea);
        Task SendDatasetAccessApprovalNotification(string requestor, SubjectArea subjectArea);
        Task SendDatasetAccessRequestNotification(string recipient, string requestor, SubjectArea subjectArea);
        Task SendNotificationToPHNUsers(string owner, string custodian, string[] stewards);
    }
}