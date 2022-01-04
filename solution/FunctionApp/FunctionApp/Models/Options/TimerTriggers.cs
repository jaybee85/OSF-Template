namespace FunctionApp.Models.Options
{
    public class TimerTriggers
    {
        public bool EnablePrepareFrameworkTasks { get; set; }
        public bool EnableRunFrameworkTasks { get; set; }
        public bool EnableGetADFStats { get; set; }
        public bool EnableGetActivityLevelLogs { get; set; }
    }
}