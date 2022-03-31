
$Body = @{      "TaskMasterId"= 1000                
}

Invoke-RestMethod -Uri "http://localhost:7071/api/DisableTaskMaster" -ContentType 'application/json' -Method "POST" -Body ($Body | ConvertTo-Json) | ConvertTo-Json -depth 100

