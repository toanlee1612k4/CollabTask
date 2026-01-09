# Check database state

$baseUrl = "http://localhost:5131"
$loginBody = '{"email":"alice@example.com","password":"Password123"}'

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.token
$headers = @{ "Authorization" = "Bearer $token" }

# Get workspaces
$workspaces = Invoke-RestMethod -Uri "$baseUrl/api/workspaces" -Method GET -Headers $headers
Write-Host "Workspaces count: $($workspaces.Count)"

foreach ($ws in $workspaces) {
    Write-Host "`nWorkspace: $($ws.name) (ID: $($ws.workspaceId))"
    
    # Get tasks in workspace
    $tasks = Invoke-RestMethod -Uri "$baseUrl/api/tasks?workspaceId=$($ws.workspaceId)" -Method GET -Headers $headers
    Write-Host "  Tasks in this workspace: $($tasks.Count)"
    
    # Show sample tasks
    $tasks | Select-Object -First 5 | ForEach-Object {
        Write-Host "    - [$($_.status)] $($_.title)"
    }
}

# Check Alice's task assignments directly
Write-Host "`n--- Alice's assigned tasks via productivity endpoint ---"
$suggested = Invoke-RestMethod -Uri "$baseUrl/api/productivity/suggested-tasks?limit=100" -Method GET -Headers $headers
Write-Host "Total suggested: $($suggested.totalCount)"
