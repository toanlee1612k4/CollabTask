# Check Alice's actual user ID

$baseUrl = "http://localhost:5131"
$loginBody = '{"email":"alice@example.com","password":"Password123"}'

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "=== Alice User Info ==="
$me = Invoke-RestMethod -Uri "$baseUrl/api/users/me" -Method GET -Headers $headers
$me | ConvertTo-Json -Depth 3

Write-Host "`n=== Expected Alice ID (from seeder) ==="
Write-Host "AliceId constant: 11111111-1111-1111-1111-111111111111"

Write-Host "`n=== AssigneeUserIds from suggested tasks ==="
$suggested = Invoke-RestMethod -Uri "$baseUrl/api/productivity/suggested-tasks?limit=3" -Method GET -Headers $headers
foreach ($task in $suggested.suggestedTasks) {
    Write-Host "Task: $($task.title)"
    Write-Host "  Assignees: $($task.assigneeUserIds -join ', ')"
}
