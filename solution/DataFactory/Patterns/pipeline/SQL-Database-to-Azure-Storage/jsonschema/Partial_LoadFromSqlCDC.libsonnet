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
                        "infoText": "Select TABLE."
                    }
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
                }
            },
            "required": [
                "Type"
            ]
 
}