using System.Collections.Generic;
using System.Threading.Tasks;
using WebApplication.Forms.PIAWizard;
using WebApplication.Models;
using WebApplication.Models.Forms;

namespace WebApplication.Services
{
    public interface IMicrosoftGraphService
    {
        Task<IEnumerable<UserReference>> GetMembers();
        Task<(string name, string email)> GetUserMailIdentity(string upn);
    }
}