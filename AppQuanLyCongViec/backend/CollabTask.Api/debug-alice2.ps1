# Debug script for Alice suggested tasks

$baseUrl = "http://localhost:5131"

Write-Host "Logging in as Alice..."
$loginBody = '{"email":"alice@example.com","password":"Password123"}'

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    Write-Host "Login successful!"
    
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    Write-Host "Getting suggested tasks..."
    $suggestedResponse = Invoke-RestMethod -Uri "$baseUrl/api/productivity/suggested-tasks?limit=10" -Method GET -Headers $headers
    
    Write-Host "Message: $($suggestedResponse.message)"
    Write-Host "Total Count: $($suggestedResponse.totalCount)"
    
    $suggestedResponse.suggestedTasks | Format-Table taskId, title, status, priority, suggestionScore -AutoSize
    
} catch {
    Write-Host "Error occurred"
    Write-Host $_.Exception.Message
    Write-Host $_.Exception.Response.StatusCode
}
