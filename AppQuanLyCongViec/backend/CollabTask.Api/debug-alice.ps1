# Debug script for Alice suggested tasks

$baseUrl = "http://localhost:5131"

Write-Host "🔐 Logging in as Alice..." -ForegroundColor Cyan
$loginBody = @{
    email = "alice@example.com"
    password = "Password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "   Token: $($token.Substring(0, 50))..." -ForegroundColor DarkGray
    
    # Prepare headers
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    # Test suggested-tasks endpoint
    Write-Host ""
    Write-Host "📋 Getting suggested tasks for Alice..." -ForegroundColor Cyan
    $suggestedResponse = Invoke-RestMethod -Uri "$baseUrl/api/productivity/suggested-tasks?limit=10" -Method GET -Headers $headers
    
    Write-Host "Message: $($suggestedResponse.message)" -ForegroundColor Yellow
    Write-Host "Total Count: $($suggestedResponse.totalCount)" -ForegroundColor Yellow
    Write-Host ""
    
    if ($suggestedResponse.suggestedTasks.Count -eq 0) {
        Write-Host "❌ NO TASKS RETURNED!" -ForegroundColor Red
        
        # Debug - check raw task assignments
        Write-Host ""
        Write-Host "🔍 Checking task data directly..." -ForegroundColor Cyan
        
        # Get all tasks in workspace
        $workspacesResponse = Invoke-RestMethod -Uri "$baseUrl/api/workspaces" -Method GET -Headers $headers
        Write-Host "Workspaces: $($workspacesResponse.Count)" -ForegroundColor Gray
        
        if ($workspacesResponse.Count -gt 0) {
            $wsId = $workspacesResponse[0].workspaceId
            Write-Host "First workspace ID: $wsId" -ForegroundColor Gray
            
            # Get tasks in this workspace
            $tasksResponse = Invoke-RestMethod -Uri "$baseUrl/api/tasks?workspaceId=$wsId" -Method GET -Headers $headers
            Write-Host "Tasks in workspace: $($tasksResponse.Count)" -ForegroundColor Gray
            
            foreach ($task in $tasksResponse) {
                Write-Host "   - [$($task.status)] $($task.title) | Priority: $($task.priority) | AssigneeIds: $($task.assigneeUserIds -join ', ')" -ForegroundColor DarkGray
            }
        }
    } else {
        Write-Host "✅ Tasks found:" -ForegroundColor Green
        foreach ($task in $suggestedResponse.suggestedTasks) {
            Write-Host "   - [$($task.status)] $($task.title)" -ForegroundColor White
            Write-Host "     Score: $($task.suggestionScore) | Reason: $($task.reason)" -ForegroundColor DarkGray
            Write-Host "     AssigneeIds: $($task.assigneeUserIds -join ', ')" -ForegroundColor DarkGray
        }
    }
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
