function(shortIRName = "", fullIRName = "") 
{
	"name": "GDS_OracleServerTable_NA_" + shortIRName,
    "properties": {
        "linkedServiceName": {
            "referenceName": "GLS_OracleDatabase_" + shortIRName,
            "type": "LinkedServiceReference",
            "parameters": {
                "Host": {
                    "value": "@dataset().Host",
                    "type": "Expression"
                },
                "Port": {
                    "value": "@dataset().Port",
                    "type": "Expression"
                },
                "SID": {
                    "value": "@dataset().SID",
                    "type": "Expression"
                },
                "UserName": {
                    "value": "@dataset().UserName",
                    "type": "Expression"
                },
                "KeyVaultBaseUrl": {
                    "value": "@dataset().KeyVaultBaseUrl",
                    "type": "Expression"
                },
                "Secret": {
                    "value": "@dataset().Secret",
                    "type": "Expression"
                }
            }
        },
        "parameters": {
            "Host": {
                "type": "string"
            },
            "Port": {
                "type": "string"
            },
            "SID": {
                "type": "string"
            },
            "UserName": {
                "type": "string"
            },
            "KeyVaultBaseUrl": {
                "type": "string"
            },
            "Secret": {
                "type": "string"
            },
            "TableSchema": {
                "type": "string"
            },
            "TableName": {
                "type": "string"
            }
        },
        "folder": {
			"name": "ADS Go Fast/Generic/" + fullIRName
        },
        "annotations": [],
        "type": "OracleTable",
        "schema": [],
        "typeProperties": {
            "schema": {
                "value": "@dataset().TableSchema",
                "type": "Expression"
            },
            "table": {
                "value": "@dataset().TableName",
                "type": "Expression"
            }
        }
    }
}