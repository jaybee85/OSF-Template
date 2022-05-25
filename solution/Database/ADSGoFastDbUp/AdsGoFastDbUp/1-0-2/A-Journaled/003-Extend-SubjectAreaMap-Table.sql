-- DROP and recreate should be fine for these because they shouldn't have been used by any customers yet.
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EntityRoleMapHistory](
	[EntityRoleMapId] [int] IDENTITY,
	[EntityId] [int] NOT NULL,
	[EntityTypeName] [varchar](255) NOT NULL,
	[AadGroupUid] [uniqueidentifier] NOT NULL,
	[ApplicationRoleName] [varchar](255) NOT NULL,
	[ExpiryDate] [date] NOT NULL,
	[ActiveYN] [bit] NOT NULL,
	[UpdatedBy] [varchar](255) NULL,
	[ValidFrom] [datetime2](0) NOT NULL,
	[ValidTo] [datetime2](0) NOT NULL
) ON [PRIMARY]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EntityRoleMap](
	[EntityRoleMapId] [int] IDENTITY,
	[EntityId] [int] NOT NULL,
	[EntityTypeName] [varchar](255) NOT NULL,
	[AadGroupUid] [uniqueidentifier] NOT NULL,
	[ApplicationRoleName] [varchar](255) NOT NULL,
	[ExpiryDate] [date] NOT NULL,
	[ActiveYN] [bit] NOT NULL,
	[UpdatedBy] [varchar](255) NULL,
	[ValidFrom] [datetime2](0) NOT NULL,
	[ValidTo] [datetime2](0) NOT NULL
CONSTRAINT [EntityRoleMap_PK] PRIMARY KEY CLUSTERED
(
	[EntityRoleMapId]
)
CONSTRAINT [EntityRoleMap_UK] UNIQUE CLUSTERED 
(
	[EntityTypeName] ASC,
	[EntityId] ASC,
	[AadGroupUid] ASC,
	[ApplicationRoleName] ASC
) 
WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
	PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
) ON [PRIMARY]
WITH
(
SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [dbo].[EntityRoleMapHistory] )
)
GO