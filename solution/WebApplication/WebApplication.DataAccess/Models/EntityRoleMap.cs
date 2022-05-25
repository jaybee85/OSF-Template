using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebApplication.Models
{
    public partial class EntityRoleMap
    {
        public const string SubjectAreaTypeName = "SubjectArea";

        public string EntityTypeName { get; set; }
        public int EntityId { get; set; }
        public Guid AadGroupUid { get; set; }
        public string ApplicationRoleName { get; set; }
        public DateTime ExpiryDate { get; set; }
        public bool ActiveYn { get; set; }
        public string UpdatedBy { get; set; }
        [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
        public DateTime ValidFrom { get; set; }
        [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
        public DateTime ValidTo { get; set; }
    }
}
