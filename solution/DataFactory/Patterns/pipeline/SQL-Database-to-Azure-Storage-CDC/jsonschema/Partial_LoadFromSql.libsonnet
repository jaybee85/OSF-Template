function() 
{
  
            "type": "object",
            "properties": {
                "Type": {
                    "type": "string",                    
                    "enum": [
                        "Table"
                    ],
                    "options": {
                        "hidden":true,
                    },
                    "default":"Table"

                },
                "IncrementalType": {
                    "type": "string",
                    "description": "Full Extraction or Incremental based on a Watermark Column",
                    "enum": [
                        "Watermark"
                    ],
                    "options": {
                        "hidden":true,
                    },
                    "default":"Watermark"
                },
                "TableSchema": {
                    "type": "string",
                    "options": {
                        "inputAttributes": {
                            "placeholder": "eg. dbo"
                        }, 
                        "infoText": "The schema of the table to extract."
                    },
                    "default":""

                },
                "TableName": {
                    "type": "string",
                    "options": {                        
                        "inputAttributes": {
                            "placeholder": "eg. Customer"
                        }, 
                        "infoText": "The name of the table to extract."
                    },
                    "default":""
                },
            },
            "required": [
                "Type",
                "IncrementalType"
            ]
 
}