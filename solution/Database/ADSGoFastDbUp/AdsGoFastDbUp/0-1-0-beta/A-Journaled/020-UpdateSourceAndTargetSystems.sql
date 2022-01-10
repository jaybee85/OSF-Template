/* Adding a column called "IsExternal" to the [SourceAndTargetSystems] Table */

ALTER TABLE [dbo].[SourceAndTargetSystems] ADD IsExternal BIT NOT NULL default 0
GO