ALTER TABLE [dbo].[TaskMaster]
    ADD InsertIntoCurrentSchedule [bit] NOT NULL
    CONSTRAINT DF_InsertIntoCurrentSchedule DEFAULT 0;

