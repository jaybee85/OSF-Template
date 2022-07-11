SET IDENTITY_INSERT [dbo].[TaskType] ON 
GO
INSERT [dbo].[TaskType] ([TaskTypeId], [TaskTypeName], [TaskExecutionType], [TaskTypeJson], [ActiveYN]) VALUES (-10, N'Synpase Stop Idle Spark Sessions', N'DLL', NULL, 1)
GO
SET IDENTITY_INSERT [dbo].[TaskType] OFF