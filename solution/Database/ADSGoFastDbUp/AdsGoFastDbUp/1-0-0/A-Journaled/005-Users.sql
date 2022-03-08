/****** Object:  User [ark-stg-adf-ads-bcar]    Script Date: 3/03/2022 12:58:09 PM ******/
CREATE USER [ark-stg-adf-ads-bcar] FROM  EXTERNAL PROVIDER  WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [ark-stg-app-ads-bcar]    Script Date: 3/03/2022 12:58:09 PM ******/
CREATE USER [ark-stg-app-ads-bcar] FROM  EXTERNAL PROVIDER  WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [ark-stg-func-ads-bcar]    Script Date: 3/03/2022 12:58:09 PM ******/
CREATE USER [ark-stg-func-ads-bcar] FROM  EXTERNAL PROVIDER  WITH DEFAULT_SCHEMA=[dbo]
GO
sys.sp_addrolemember @rolename = N'db_ddladmin', @membername = N'ark-stg-adf-ads-bcar'
GO
sys.sp_addrolemember @rolename = N'db_datareader', @membername = N'ark-stg-adf-ads-bcar'
GO
sys.sp_addrolemember @rolename = N'db_datawriter', @membername = N'ark-stg-adf-ads-bcar'
GO
sys.sp_addrolemember @rolename = N'db_datareader', @membername = N'ark-stg-app-ads-bcar'
GO
sys.sp_addrolemember @rolename = N'db_datawriter', @membername = N'ark-stg-app-ads-bcar'
GO
sys.sp_addrolemember @rolename = N'db_ddladmin', @membername = N'ark-stg-func-ads-bcar'
GO
sys.sp_addrolemember @rolename = N'db_datareader', @membername = N'ark-stg-func-ads-bcar'
GO
sys.sp_addrolemember @rolename = N'db_datawriter', @membername = N'ark-stg-func-ads-bcar'
GO
