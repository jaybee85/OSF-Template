namespace FunctionApp.Models.Options
{
    public class TestingOptions
    {
        public string TaskObjectTestFileLocation { get; set; }
        public bool GenerateTaskObjectTestFiles { get; set; }
        public string TaskMetaDataStorageAccount { get; set; }
        public string TaskMetaDataStorageContainer { get; set; }
        public string TaskMetaDataStorageFolder { get; set; }
    }
}