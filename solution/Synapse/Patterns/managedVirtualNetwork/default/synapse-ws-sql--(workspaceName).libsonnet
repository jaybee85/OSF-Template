function(tout={synapse_workspace_name: ""})
{
	"name": "synapse-ws-sql--arkstgsynwadslfl9",
	"properties": {
		"privateLinkResourceId": "/subscriptions/" & tout.subscription_id + "/resourceGroups/" + tout.resource_group_name + "/providers/Microsoft.Synapse/workspaces/" + tout.synapse_workspace_name,
		"groupId": "sql",
		"fqdns": [
			tout.synapse_workspace_name + ".1e7afd3c-47db-4647-8ee0-be6197386800.sql.azuresynapse.net"
		]
	}
}