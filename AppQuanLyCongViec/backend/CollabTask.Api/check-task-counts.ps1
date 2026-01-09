# Check task counts per user
$baseUrl = "http://localhost:5131"

$users = @(
    @{ email = "alice@example.com"; name = "Alice" },
    @{ email = "bob@example.com"; name = "Bob" },
    @{ email = "charlie@example.com"; name = "Charlie" },
    @{ email = "diana@example.com"; name = "Diana" },
    @{ email = "eve@example.com"; name = "Eve" },
    @{ email = "frank@example.com"; name = "Frank" }
)

Write-Host "=== Task Count Per User ===" -ForegroundColor Cyan
Write-Host ""

$totalAll = 0

foreach ($user in $users) {
    $loginBody = "{`"email`":`"$($user.email)`",`"password`":`"Password123`"}"
    try {
        $login = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
        $headers = @{ "Authorization" = "Bearer $($login.token)" }
        
        # Get suggested tasks count (active tasks)
        $suggested = Invoke-RestMethod -Uri "$baseUrl/api/productivity/suggested-tasks?limit=2000" -Method GET -Headers $headers
        
        Write-Host "$($user.name): $($suggested.totalCount) active tasks" -ForegroundColor Green
        $totalAll += $suggested.totalCount
    } catch {
        Write-Host "$($user.name): ERROR - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== TOTAL: $totalAll active tasks ===" -ForegroundColor Yellow
