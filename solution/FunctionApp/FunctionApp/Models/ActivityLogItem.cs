using System;
using System.Collections.Generic;

namespace FunctionApp.Models
{
    public class ActivityLogItem
    {
        public DateTimeOffset LogDateTimeOffset { get; set; }
        public DateTimeOffset LogDateUtc { get; set; }
        public DateTimeOffset StartDateTimeOffset { get; set; }
        public DateTimeOffset EndDateTimeOffset { get; set; }

        public short? LogTypeId { get; set; }
        public Guid? ExecutionUid { get; set; }
        public string LogSource { get; set; }
        public long? TaskMasterId { get; set; }
        public long? TaskGroupId { get; set; }
        public long? TaskInstanceId { get; set; }
        public Guid? AdfRunUid { get; set; }
        public long? ScheduleInstanceId { get; set; }

        public string ActivityType { get; set; }

        public string Comment { get; set; }

        public string Status { get; set; }

        /// <summary>
        /// Constructor of setting the DefaultActivityItem
        /// </summary>
        public ActivityLogItem()
        {
            LogSource = "AF";
            LogDateTimeOffset = DateTimeOffset.UtcNow;
            LogDateUtc = LogDateTimeOffset.Date;
        }

        /// <summary>
        /// Constructor for all non DefaultActivityItems
        /// </summary>
        /// <param name="defaultActivityLogItem"></param>
        public ActivityLogItem(ActivityLogItem defaultActivityLogItem)
        {
            LogSource = "AF";
            LogDateTimeOffset = DateTimeOffset.UtcNow;
            LogDateUtc = LogDateTimeOffset.Date;

            //If the default has the values below then use these 
            if (defaultActivityLogItem != null)
            {
                if (defaultActivityLogItem.ExecutionUid != null) { ExecutionUid = defaultActivityLogItem.ExecutionUid; }
                if (defaultActivityLogItem.TaskInstanceId != null) { TaskInstanceId = defaultActivityLogItem.TaskInstanceId; }
                if (defaultActivityLogItem.AdfRunUid != null) { AdfRunUid = defaultActivityLogItem.AdfRunUid; }
                if (defaultActivityLogItem.TaskMasterId != null) { TaskMasterId = defaultActivityLogItem.TaskMasterId; }
                if (defaultActivityLogItem.ActivityType != null) { ActivityType = defaultActivityLogItem.ActivityType; }

            }


        }

        public LogParamsAndTemplate WriteToStandardLog()
        {
            LogParamsAndTemplate ret = new LogParamsAndTemplate();
            ret.Template = @"";

            ret.Template += "LogSource={LogSource}"; ret.Params.Add(LogSource);
            ret.Template += ",LogDateTimeOffset={LogDateTimeOffset}"; ret.Params.Add(LogDateTimeOffset);
            ret.Template += ",LogDateUTC={LogDateUTC}"; ret.Params.Add(LogDateUtc);

            if (AdfRunUid != null) { ret.Template += ",AdfRunUid={AdfRunUid}"; ret.Params.Add(AdfRunUid); }
            if (ActivityType != null) { ret.Template += ",ActivityType={ActivityType}"; ret.Params.Add(ActivityType); }
            if (Comment != null) { ret.Template += ",Comment={Comment}"; ret.Params.Add(Comment); }
            if (ExecutionUid != null) { ret.Template += ",ExecutionUid={ExecutionUid}"; ret.Params.Add(ExecutionUid); }
            if (ScheduleInstanceId != null) { ret.Template += ",ScheduleInstanceId={ScheduleInstanceId}"; ret.Params.Add(ScheduleInstanceId); }
            if (Status != null) { ret.Template += ",Status={Status}"; ret.Params.Add(Status); }
            if (TaskInstanceId != null) { ret.Template += ",TaskInstanceId={TaskInstanceId}"; ret.Params.Add(TaskInstanceId); }
            if (TaskMasterId != null) { ret.Template += ",TaskMasterId={TaskMasterId}"; ret.Params.Add(TaskMasterId); }


            return ret;
        }
    }
    public class LogParamsAndTemplate
    {
        public List<object> Params { get; } = new();
        public string Template { get; set; }
    }
}
