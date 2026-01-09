# Reseed with persona data and verify

$baseUrl = "http://localhost:5131"

Write-Host "=== Step 1: Reseed with 6 personas (small dataset) ==="
try {
    $reseedResponse = Invoke-RestMethod -Uri "$baseUrl/api/seed/reseed" -Method POST -ContentType "application/json"
    Write-Host "Reseed response: $($reseedResponse | ConvertTo-Json -Depth 1)"
} catch {
    Write-Host "Reseed error: $($_.Exception.Message)"
}

Write-Host "`n=== Step 2: Login as Alice ==="
$loginBody = '{"email":"alice@example.com","password":"Password123"}'
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.token
$headers = @{ "Authorization" = "Bearer $token" }
Write-Host "Logged in as Alice"

Write-Host "`n=== Step 3: Get Alice user info ==="
$me = Invoke-RestMethod -Uri "$baseUrl/api/users/me" -Method GET -Headers $headers
Write-Host "Alice ID: $($me.userID)"
Write-Host "Expected: 11111111-1111-1111-1111-111111111111"

Write-Host "`n=== Step 4: Get suggested tasks ==="
$suggested = Invoke-RestMethod -Uri "$baseUrl/api/productivity/suggested-tasks?limit=20" -Method GET -Headers $headers
Write-Host "Total: $($suggested.totalCount)"

if ($suggested.totalCount -eq 0) {
    Write-Host "NO TASKS! Checking what went wrong..."
} else {
    Write-Host "Tasks found:"
    foreach ($task in $suggested.suggestedTasks) {
        Write-Host "  - [$($task.status)] $($task.title)"
        Write-Host "    Priority: $($task.priority), Score: $($task.suggestionScore)"
        Write-Host "    AssignmentStatus: $($task.assignmentStatus)"
    }
}
