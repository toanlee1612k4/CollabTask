# Deep check for Alice

$baseUrl = "http://localhost:5131"
$loginBody = '{"email":"alice@example.com","password":"Password123"}'

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "=== Alice's Suggested Tasks ==="
$suggested = Invoke-RestMethod -Uri "$baseUrl/api/productivity/suggested-tasks?limit=10" -Method GET -Headers $headers
Write-Host "Total: $($suggested.totalCount)"
Write-Host ""

foreach ($task in $suggested.suggestedTasks) {
    Write-Host "Task: $($task.title)"
    Write-Host "  Status: $($task.status)"
    Write-Host "  Priority: $($task.priority)"
    Write-Host "  AssignmentStatus: $($task.assignmentStatus)"
    Write-Host "  Deadline: $($task.deadline)"
    Write-Host "  Score: $($task.suggestionScore)"
    Write-Host "  Reason: $($task.reason)"
    Write-Host "  AssigneeUserIds: $($task.assigneeUserIds -join ', ')"
    Write-Host ""
}
